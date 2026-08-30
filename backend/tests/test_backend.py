import os
import sys
import unittest
from pathlib import Path
from fastapi.testclient import TestClient

root_dir = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(root_dir))

from backend.main import app, startup_event
from backend.config import settings

class RetinaSegBackendTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        startup_event()
        cls.client = TestClient(app)
        cls.auth_token = None
        cls.patient_id = None
        cls.scan_id = None
        cls.analysis_id = None

    def test_01_root_and_health(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["layers_supported"], 8)

    def test_02_register_and_login(self):
        # 1. Register a new user
        reg_payload = {
            "email": "test_doctor@retinaseg.ai",
            "password": "TestPassword123",
            "full_name": "Test Dr. Watson",
            "role": "OPHTHALMOLOGIST",
            "specialty": "Medical Retina",
            "license_number": "TEST-12345"
        }
        reg_res = self.client.post(f"{settings.API_V1_STR}/auth/register", json=reg_payload)
        self.assertIn(reg_res.status_code, [200, 400]) # 400 if already exists

        # 2. Login
        login_payload = {
            "email": "test_doctor@retinaseg.ai",
            "password": "TestPassword123"
        }
        res = self.client.post(f"{settings.API_V1_STR}/auth/login", json=login_payload)
        self.assertEqual(res.status_code, 200, f"Login failed: {res.text}")
        data = res.json()
        self.assertIn("access_token", data)
        self.__class__.auth_token = data["access_token"]
        self.assertEqual(data["user"]["role"], "OPHTHALMOLOGIST")

    def test_03_patient_list_and_create(self):
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}

        # 1. Create a patient
        patient_payload = {
            "patient_id": f"PAT-TEST-{os.getpid()}",
            "full_name": "Test Patient",
            "age": 45,
            "gender": "Male",
            "contact": "555-0199",
            "email": "patient@test.com",
            "medical_history": "None",
            "eye_condition": "Routine Check"
        }
        create_res = self.client.post(f"{settings.API_V1_STR}/patients", headers=headers, json=patient_payload)
        self.assertEqual(create_res.status_code, 200)

        # 2. List patients
        res = self.client.get(f"{settings.API_V1_STR}/patients", headers=headers)
        self.assertEqual(res.status_code, 200)
        patients = res.json()
        self.assertGreaterEqual(len(patients), 1)
        # Find our test patient
        test_p = next((p for p in patients if p["patient_id"].startswith("PAT-TEST-")), None)
        self.assertIsNotNone(test_p)
        self.__class__.patient_id = test_p["id"]

    def test_04_oct_upload_valid(self):
        sample_path = root_dir / "backend" / "sample_data" / "sample_scans" / "sample_normal_macula_od.png"
        self.assertTrue(sample_path.exists(), "Sample OCT scan must exist.")
        
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        with open(sample_path, "rb") as f:
            files = {"file": ("sample_normal_macula_od.png", f, "image/png")}
            data = {
                "patient_id": self.__class__.patient_id,
                "eye_laterality": "OD",
                "device_manufacturer": "Heidelberg Spectralis OCT",
                "axial_resolution_um": 3.87
            }
            res = self.client.post(f"{settings.API_V1_STR}/oct/upload", headers=headers, files=files, data=data)
            
        self.assertEqual(res.status_code, 200, f"OCT upload failed: {res.text}")
        scan_data = res.json()
        self.assertEqual(scan_data["validation_status"], "VALID")
        self.assertGreaterEqual(scan_data["validation_score"], 0.7)
        self.__class__.scan_id = scan_data["id"]

    def test_05_oct_upload_reject_invalid(self):
        invalid_path = root_dir / "backend" / "sample_data" / "sample_scans" / "sample_invalid_document.png"
        self.assertTrue(invalid_path.exists())
        
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        with open(invalid_path, "rb") as f:
            files = {"file": ("sample_invalid_document.png", f, "image/png")}
            data = {
                "patient_id": self.__class__.patient_id,
                "eye_laterality": "OD"
            }
            res = self.client.post(f"{settings.API_V1_STR}/oct/upload", headers=headers, files=files, data=data)
            
        # Must be rejected with 422 Unprocessable Entity
        self.assertEqual(res.status_code, 422, "Non-OCT images must be rejected.")
        self.assertIn("Invalid Image", str(res.json()))

    def test_06_preprocessing(self):
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        payload = {
            "scan_id": self.__class__.scan_id,
            "apply_bilateral_filter": True,
            "apply_clahe": True,
            "clahe_clip_limit": 2.5,
            "normalize_intensity": True
        }
        res = self.client.post(f"{settings.API_V1_STR}/analysis/preprocess", headers=headers, json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("preprocessed_image_url", data)
        self.assertGreater(data["contrast_enhancement_ratio"], 1.0)
        self.assertGreater(data["noise_reduction_snr"], 0.0)

    def test_07_unet_segmentation(self):
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        payload = {
            "scan_id": self.__class__.scan_id,
            "confidence_threshold": 0.5,
            "include_boundary_data": True
        }
        res = self.client.post(f"{settings.API_V1_STR}/analysis/segment", headers=headers, json=payload)
        self.assertEqual(res.status_code, 200, f"Segmentation failed: {res.text}")
        data = res.json()
        self.assertEqual(data["status"], "COMPLETED")
        self.assertEqual(len(data["layers"]), 8)  # 8 layers: ILM, RNFL, GCL, IPL, INL, OPL, ONL, RPE
        
        # Verify layer measurements have both pixels and micrometers
        for l in data["layers"]:
            self.assertTrue(l["is_detected"])
            self.assertGreater(l["mean_thickness_px"], 0)
            self.assertIsNotNone(l["mean_thickness_um"])
            self.assertGreater(l["layer_area_px"], 0)
            
        self.__class__.analysis_id = data["id"]

    def test_08_pdf_report_generation(self):
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        payload = {
            "analysis_id": self.__class__.analysis_id,
            "notes": "Verified normal foveal contour. Retinal layers intact with no subretinal fluid or CME.",
            "include_preprocessed": True,
            "include_measurements_table": True
        }
        res = self.client.post(f"{settings.API_V1_STR}/reports/generate", headers=headers, json=payload)
        self.assertEqual(res.status_code, 200, f"Report generation failed: {res.text}")
        data = res.json()
        self.assertIn("pdf_url", data)
        self.assertTrue(data["report_uid"].startswith("REP-"))
        
        # Download and verify PDF binary content
        dl_res = self.client.get(data["pdf_url"])
        self.assertEqual(dl_res.status_code, 200)
        self.assertEqual(dl_res.headers["content-type"], "application/pdf")
        self.assertGreater(len(dl_res.content), 1000)

    def test_09_dashboard_stats(self):
        headers = {"Authorization": f"Bearer {self.__class__.auth_token}"}
        res = self.client.get(f"{settings.API_V1_STR}/dashboard/stats", headers=headers)
        self.assertEqual(res.status_code, 200)
        stats = res.json()
        self.assertGreaterEqual(stats["total_patients"], 1)
        self.assertGreaterEqual(stats["total_scans"], 1)
        self.assertGreaterEqual(stats["analyses_completed"], 1)
        self.assertGreaterEqual(stats["reports_generated"], 1)

if __name__ == "__main__":
    unittest.main()
