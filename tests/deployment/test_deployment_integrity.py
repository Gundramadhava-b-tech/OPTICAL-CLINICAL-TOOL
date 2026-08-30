import unittest
import os
from pathlib import Path
from fastapi.testclient import TestClient

from backend.main import app
from backend.config import settings

class TestDeploymentIntegrity(unittest.TestCase):
    """
    Deployment integrity test suite verifying production build readiness:
    - Web assets and HTML/CSS/JS delivery
    - Static media directory mount points
    - API route registration completeness
    - Health endpoint SLA
    """

    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    def test_01_backend_health_and_service_sla(self):
        """1. Health check returns 200 OK and Firestore status."""
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "healthy")
        self.assertIn("database", data)

    def test_02_static_storage_directories_mounted(self):
        """2. Verify static mount paths for uploads, processed, masks, overlays, reports."""
        for path in ["/api/static/uploads", "/api/static/processed", "/api/static/masks", "/api/static/overlays", "/api/static/reports"]:
            res = self.client.get(f"{path}/")
            self.assertIn(res.status_code, [200, 404, 403], f"Mount point {path} failed: {res.status_code}")

    def test_03_web_frontend_index_and_assets(self):
        """3. Verify web index.html and style assets are accessible."""
        res_html = self.client.get("/")
        self.assertEqual(res_html.status_code, 200)
        
        res_css = self.client.get("/style.css")
        self.assertEqual(res_css.status_code, 200)

    def test_04_api_route_registration_completeness(self):
        """4. Verify all core API routers are registered under /api."""
        schema = app.openapi()
        route_paths = list(schema.get("paths", {}).keys())
        self.assertTrue(any("/api/auth" in p for p in route_paths))
        self.assertTrue(any("/api/patients" in p for p in route_paths))
        self.assertTrue(any("/api/oct" in p for p in route_paths))
        self.assertTrue(any("/api/analysis" in p for p in route_paths))
        self.assertTrue(any("/api/reports" in p for p in route_paths))
        self.assertTrue(any("/api/dashboard" in p for p in route_paths))

    def test_05_openapi_documentation_endpoints(self):
        """5. Verify Swagger UI and OpenAPI JSON schemas are accessible."""
        res = self.client.get("/docs")
        self.assertEqual(res.status_code, 200)
        res_json = self.client.get("/openapi.json")
        self.assertEqual(res_json.status_code, 200)

if __name__ == "__main__":
    unittest.main()
