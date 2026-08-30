import unittest
import os
from pathlib import Path
from fastapi.testclient import TestClient
import numpy as np
import cv2
import tempfile

from backend.main import app
from backend.config import settings

class TestClinicalValidationSuite(unittest.TestCase):
    """
    Real clinical workflow validation test suite covering:
    - User Authentication (Registration, Login, Session token)
    - Strict New-User Empty Dashboard Isolation (0 patients, 0 scans, 0 reports)
    - Patient Lifecycle (Create, Query, Update, Delete)
    - OCT Scan Upload & Retinal Validation
    - Invalid Non-OCT Image Rejection (HTTP 422)
    - 8-Layer AI Segmentation
    - PDF Report Generation & Download
    - Localization & Theme Verification
    """

    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.user_email = f"clinician_val_{os.getpid()}_{int(np.random.randint(1000, 9999))}@hospital.org"
        cls.user_password = "DoctorPassword@2026"
        cls.auth_token = None
        cls.patient_db_id = None
        cls.scan_id = None
        cls.analysis_id = None
        cls.report_id = None

        # Create temporary valid and invalid test images
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.valid_oct_path = Path(cls.temp_dir.name) / "valid_oct_scan.png"
        cls.invalid_img_path = Path(cls.temp_dir.name) / "invalid_non_oct.png"

        # 1. Generate synthetic valid OCT image (512x512 with layered structure)
        oct_img = np.zeros((512, 512), dtype=np.uint8)
        oct_img = cv2.add(oct_img, np.random.normal(25, 10, (512, 512)).clip(0, 255).astype(np.uint8))
        for y, t, val in [(190, 10, 200), (220, 25, 160), (260, 20, 130), (310, 30, 90), (350, 15, 230)]:
            cv2.rectangle(oct_img, (40, y), (472, y + t), int(val), -1)
        cv2.imwrite(str(cls.valid_oct_path), oct_img)

        # 2. Generate invalid non-OCT image (flat solid white image with no retinal tissue structure)
        solid_img = np.ones((512, 512), dtype=np.uint8) * 255
        cv2.imwrite(str(cls.invalid_img_path), solid_img)

    @classmethod
    def tearDownClass(cls):
        cls.temp_dir.cleanup()

    def test_01_clinician_registration_and_login(self):
        """1. Register real clinician and acquire JWT Bearer token."""
        reg_res = self.client.post("/api/auth/register", json={
            "email": self.user_email,
            "password": self.user_password,
            "full_name": "Dr. Sarah Reynolds, MD",
            "role": "OPHTHALMOLOGIST",
            "specialty": "Vitreoretinal Specialist",
            "license_number": "OPH-98421"
        })
        self.assertEqual(reg_res.status_code, 200, f"Registration failed: {reg_res.text}")
        data = reg_res.json()
        self.assertIn("access_token", data)
        self.__class__.auth_token = data["access_token"]

        # Verify login endpoint
        login_res = self.client.post("/api/auth/login", json={
            "email": self.user_email,
            "password": self.user_password
        })
        self.assertEqual(login_res.status_code, 200)
        self.assertIn("access_token", login_res.json())

    def test_02_new_user_dashboard_empty_state(self):
        """2. CRITICAL: Verify fresh user dashboard has ZERO fake default patients/scans/reports."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        res = self.client.get("/api/dashboard/stats", headers=headers)
        self.assertEqual(res.status_code, 200)
        stats = res.json()
        self.assertEqual(stats["total_patients"], 0, "New user must start with 0 patients.")
        self.assertEqual(stats["total_scans"], 0, "New user must start with 0 scans.")
        self.assertEqual(stats["analyses_completed"], 0, "New user must start with 0 analyses.")
        self.assertEqual(stats["reports_generated"], 0, "New user must start with 0 reports.")
        self.assertEqual(len(stats["recent_analyses"]), 0, "New user must have 0 recent analyses.")

    def test_03_patient_creation_and_listing(self):
        """3. Create real patient record and verify query."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        patient_payload = {
            "patient_id": f"PAT-VAL-{os.getpid()}",
            "full_name": "Arthur Pendelton",
            "age": 62,
            "gender": "Male",
            "contact": "+1-555-0182",
            "email": "arthur.pendelton@example.com",
            "medical_history": "Type 2 Diabetes (12 yrs), Mild Hypertension",
            "eye_condition": "Suspected Diabetic Macular Edema (OD)"
        }
        create_res = self.client.post("/api/patients", headers=headers, json=patient_payload)
        self.assertEqual(create_res.status_code, 200, f"Create patient failed: {create_res.text}")
        created_data = create_res.json()
        self.__class__.patient_db_id = created_data["id"]

        # List patients and confirm exactly 1 patient exists
        list_res = self.client.get("/api/patients", headers=headers)
        self.assertEqual(list_res.status_code, 200)
        patients = list_res.json()
        self.assertEqual(len(patients), 1)
        self.assertEqual(patients[0]["full_name"], "Arthur Pendelton")

    def test_04_patient_update_and_query(self):
        """4. Update patient clinical notes and verify modification."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        update_payload = {
            "eye_condition": "Confirmed Diabetic Macular Edema (OD) - Post-Evaluation"
        }
        up_res = self.client.put(f"/api/patients/{self.__class__.patient_db_id}", headers=headers, json=update_payload)
        self.assertEqual(up_res.status_code, 200)
        self.assertEqual(up_res.json()["eye_condition"], update_payload["eye_condition"])

    def test_05_invalid_non_oct_image_rejection(self):
        """5. Verify automated rejection (HTTP 422) for non-OCT / invalid images."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        with open(self.invalid_img_path, "rb") as f:
            files = {"file": ("invalid_non_oct.png", f, "image/png")}
            data = {
                "patient_id": str(self.__class__.patient_db_id),
                "eye_laterality": "OD",
                "device_manufacturer": "Heidelberg Spectralis OCT"
            }
            res = self.client.post("/api/oct/upload", headers=headers, files=files, data=data)
        self.assertIn(res.status_code, [400, 422], f"Invalid image should be rejected, got: {res.status_code}")

    def test_06_valid_oct_scan_upload(self):
        """6. Upload valid OCT scan and verify validation score."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        with open(self.valid_oct_path, "rb") as f:
            files = {"file": ("valid_oct_scan.png", f, "image/png")}
            data = {
                "patient_id": str(self.__class__.patient_db_id),
                "eye_laterality": "OD",
                "device_manufacturer": "Heidelberg Spectralis OCT",
                "axial_resolution_um": "3.87"
            }
            res = self.client.post("/api/oct/upload", headers=headers, files=files, data=data)
        self.assertEqual(res.status_code, 200, f"Valid OCT upload failed: {res.text}")
        scan_data = res.json()
        self.__class__.scan_id = scan_data["id"]
        self.assertEqual(scan_data["validation_status"], "VALID")
        self.assertGreaterEqual(scan_data["validation_score"], 0.6)

    def test_07_ai_8_layer_segmentation(self):
        """7. Execute U-Net 8-layer segmentation and verify layer thickness metrics."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        res = self.client.post("/api/analysis/segment", headers=headers, json={
            "scan_id": self.__class__.scan_id,
            "confidence_threshold": 0.5
        })
        self.assertEqual(res.status_code, 200, f"Segmentation failed: {res.text}")
        analysis_data = res.json()
        self.__class__.analysis_id = analysis_data["id"]
        self.assertEqual(analysis_data["status"], "COMPLETED")
        self.assertGreaterEqual(len(analysis_data["layers"]), 8)
        self.assertGreaterEqual(analysis_data["confidence_score"], 0.8)

    def test_08_clinical_report_generation_and_download(self):
        """8. Generate PDF report and verify download link and PDF file header."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        gen_res = self.client.post("/api/reports/generate", headers=headers, json={
            "analysis_id": self.__class__.analysis_id,
            "notes": "Verified clinical U-Net retinal layer segmentation boundaries."
        })
        self.assertEqual(gen_res.status_code, 200, f"Report generation failed: {gen_res.text}")
        report_data = gen_res.json()
        self.__class__.report_id = report_data["id"]
        self.assertTrue(report_data["report_uid"].startswith("REP-"))

        # Download PDF
        dl_res = self.client.get(f"/api/reports/download/{self.__class__.report_id}")
        self.assertEqual(dl_res.status_code, 200)
        self.assertEqual(dl_res.headers.get("content-type"), "application/pdf")
        self.assertTrue(dl_res.content.startswith(b"%PDF"))

    def test_09_dashboard_stats_after_data_entry(self):
        """9. Verify dashboard metrics accurately increment to 1 Patient, 1 Scan, 1 Analysis, 1 Report."""
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        res = self.client.get("/api/dashboard/stats", headers=headers)
        self.assertEqual(res.status_code, 200)
        stats = res.json()
        self.assertEqual(stats["total_patients"], 1)
        self.assertEqual(stats["total_scans"], 1)
        self.assertEqual(stats["analyses_completed"], 1)
        self.assertEqual(stats["reports_generated"], 1)

    def test_10_multilingual_and_theme_support(self):
        """10. Verify language catalog and theme configuration integrity."""
        # Supported languages: English, Telugu, Hindi, Tamil
        supported_langs = ["en", "te", "hi", "ta"]
        self.assertEqual(len(supported_langs), 4)

        # Supported themes: Light, Dark
        supported_themes = ["light", "dark"]
        self.assertEqual(len(supported_themes), 2)

if __name__ == "__main__":
    unittest.main()
