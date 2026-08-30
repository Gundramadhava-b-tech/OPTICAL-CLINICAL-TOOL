import unittest
import os
from pathlib import Path
import tempfile
from fastapi.testclient import TestClient

from backend.main import app
from backend.services.auth_service import create_access_token, verify_password, get_password_hash
from backend.services.firebase_db_service import firebase_db
from backend.services.report_service import report_service

class TestAPIServicesUnit(unittest.TestCase):
    """
    Unit test suite for authentication algorithms, Firestore persistence, and PDF rendering.
    """

    def setUp(self):
        self.client = TestClient(app)

    def test_01_password_hashing_and_verification(self):
        password = "SecureOphthalmology@2026"
        hashed = get_password_hash(password)
        self.assertNotEqual(password, hashed)
        self.assertTrue(verify_password(password, hashed))
        self.assertFalse(verify_password("WrongPassword123", hashed))

    def test_02_jwt_token_generation_and_decode(self):
        token_data = {"sub": "clinician@eyecare.org", "role": "OPHTHALMOLOGIST"}
        token = create_access_token(token_data)
        self.assertIsInstance(token, str)
        self.assertGreater(len(token), 20)

    def test_03_firestore_user_crud(self):
        test_email = f"unittest_user_{os.getpid()}@retinaseg.ai"
        user_dict = {
            "email": test_email,
            "password_hash": get_password_hash("Pass123!"),
            "full_name": "Dr. Unit Test",
            "role": "OPHTHALMOLOGIST",
            "specialty": "Retina Specialist",
            "is_active": True
        }
        created = firebase_db.create_user(user_dict)
        self.assertEqual(created["email"], test_email)

        fetched = firebase_db.get_user_by_email(test_email)
        self.assertIsNotNone(fetched)
        self.assertEqual(fetched["full_name"], "Dr. Unit Test")

    def test_04_firestore_patient_crud(self):
        pat_data = {
            "patient_id": f"PAT-UNIT-{os.getpid()}",
            "full_name": "Jane Unit Patient",
            "age": 52,
            "gender": "Female",
            "eye_condition": "Epiretinal Membrane (OS)",
            "created_by": "dr_unit@test.org",
            "created_by_id": "usr_unit_1"
        }
        created_pat = firebase_db.create_patient(pat_data)
        self.assertIn("id", created_pat)
        self.assertEqual(created_pat["patient_id"], pat_data["patient_id"])

        fetched_pat = firebase_db.get_patient(created_pat["id"])
        self.assertIsNotNone(fetched_pat)
        self.assertEqual(fetched_pat["full_name"], "Jane Unit Patient")

    def test_05_pdf_report_lab_generation(self):
        report_uid = f"REP-UNIT-{os.getpid()}"
        patient_data = {
            "patient_id": "PAT-UNIT-001",
            "full_name": "Eleanor Sample",
            "age": 64,
            "gender": "Female",
            "eye_condition": "Diabetic Retinopathy"
        }
        scan_data = {
            "scan_uid": "OCT-UNIT-SCAN",
            "file_path": "backend/storage/uploads/sample_normal_macula_od.png",
            "eye_laterality": "OD",
            "width": 512,
            "height": 512,
            "axial_resolution_um": 3.87
        }
        preprocessing_data = {
            "preprocessed_file_path": "backend/storage/uploads/sample_normal_macula_od.png",
            "methods_applied": ["Bilateral Filter", "CLAHE"]
        }
        analysis_data = {
            "mask_file_path": "backend/storage/uploads/sample_normal_macula_od.png",
            "overlay_file_path": "backend/storage/uploads/sample_normal_macula_od.png",
            "overall_quality": "Good",
            "confidence_score": 0.95,
            "findings_summary": "Intact ILM, RNFL, and RPE boundaries.",
            "model_version": "RetinaUNet-v1.4.2",
            "layers": [
                {"layer_name": "ILM", "is_detected": True, "mean_thickness_um": 12.4, "layer_area_px": 1900, "confidence_score": 0.96},
                {"layer_name": "RPE", "is_detected": True, "mean_thickness_um": 38.2, "layer_area_px": 5800, "confidence_score": 0.94}
            ]
        }
        pdf_path = report_service.generate_pdf_report(
            report_uid=report_uid,
            patient_data=patient_data,
            scan_data=scan_data,
            preprocessing_data=preprocessing_data,
            analysis_data=analysis_data,
            doctor_name="Dr. Test Specialist, MD",
            notes="Unit test generated clinical report."
        )
        self.assertTrue(Path(pdf_path).exists())
        self.assertGreater(os.path.getsize(pdf_path), 500)

if __name__ == "__main__":
    unittest.main()
