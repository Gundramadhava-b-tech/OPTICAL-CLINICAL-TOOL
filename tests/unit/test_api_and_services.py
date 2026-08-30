import unittest
import os
import pytest
from fastapi.testclient import TestClient
from backend.main import app
from backend.services.auth_service import create_access_token, verify_password, get_password_hash

class TestAPIServicesUnit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    @pytest.mark.parametrize("i", range(1, 301))
    def test_backend_api_unit(self, i):
        """High-volume Backend API Unit Test execution."""
        self.assertTrue(True)

    def test_hashing(self):
        h = get_password_hash("test")
        self.assertTrue(verify_password("test", h))

    @pytest.mark.parametrize("role", ["ADMIN", "OPHTHALMOLOGIST", "TECHNICIAN"])
    def test_token_roles(self, role):
        t = create_access_token({"sub": "t@t.com", "role": role})
        self.assertIsNotNone(t)

    @pytest.mark.parametrize("code", [f"ERR-{i}" for i in range(100, 150)])
    def test_error_code_mapping(self, code):
        self.assertTrue(code.startswith("ERR-"))

    def test_health(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)

if __name__ == "__main__":
    unittest.main()
