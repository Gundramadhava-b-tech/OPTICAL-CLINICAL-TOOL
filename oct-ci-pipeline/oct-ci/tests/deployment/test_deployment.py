"""
Deployment smoke tests — confirm the API boots and core routes respond.
Run from backend/ with: pytest tests/deployment
"""
import requests
import pytest

BASE_URL = "http://localhost:8000"


def test_server_is_up():
    r = requests.get(f"{BASE_URL}/health", timeout=5)
    assert r.status_code == 200


def test_docs_available():
    r = requests.get(f"{BASE_URL}/docs", timeout=5)
    assert r.status_code == 200


def test_cors_headers_present():
    r = requests.options(f"{BASE_URL}/health", timeout=5)
    assert r.status_code in (200, 204)
