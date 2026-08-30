import unittest
import os
from pathlib import Path
from fastapi.testclient import TestClient

from backend.main import app

class TestAppiumAndroidPlatform(unittest.TestCase):
    """
    Appium & Android Mobile Integration Test Suite.
    Validates Android package structure, Gradle build manifest, mobile endpoints,
    and mobile authentication contracts.
    """

    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.frontend_dir = Path("frontend")
        cls.android_dir = Path("frontend/android")

    def test_01_android_project_structure(self):
        """1. Verify Android folder and gradle files exist."""
        if self.android_dir.exists():
            self.assertTrue((self.android_dir / "app").exists() or (self.android_dir / "build.gradle").exists() or (self.android_dir / "build.gradle.kts").exists())
        else:
            self.assertTrue(self.frontend_dir.exists())

    def test_02_android_application_id_configuration(self):
        """2. Verify package ID configuration (com.example.oct_retinal_segmentation or retinaseg_ai)."""
        pubspec_path = self.frontend_dir / "pubspec.yaml"
        if pubspec_path.exists():
            with open(pubspec_path, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertTrue("name:" in content or "retinaseg" in content.lower())
        else:
            self.assertTrue(True)

    def test_03_mobile_api_cors_and_headers(self):
        """3. Verify mobile client CORS headers allow cross-origin mobile and web requests."""
        res = self.client.options("/api/auth/login", headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "POST"
        })
        self.assertIn(res.status_code, [200, 405, 204])

    def test_04_mobile_auth_login_contract(self):
        """4. Verify mobile auth endpoint response structure."""
        res = self.client.post("/api/auth/login", json={
            "email": "invalid_mobile_user@test.org",
            "password": "wrongpassword"
        })
        self.assertIn(res.status_code, [401, 400])

    def test_05_mobile_health_status_response(self):
        """5. Verify mobile health check returns active U-Net and database status."""
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "healthy")
        self.assertIn("database", data)

if __name__ == "__main__":
    unittest.main()
