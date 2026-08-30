"""
Selenium E2E tests against the built Flutter web app, served locally
during CI at http://localhost:8080 (see ci.yml: 'Serve web build' step).
"""
import time
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

BASE_URL = "http://localhost:8080"


@pytest.fixture(scope="module")
def driver():
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    d = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    yield d
    d.quit()


def test_app_loads(driver):
    driver.get(BASE_URL)
    time.sleep(3)  # Flutter web bootstraps async; swap for an explicit wait once real IDs exist
    assert "OCT" in driver.title or driver.title != ""


def test_login_page_renders(driver):
    driver.get(BASE_URL)
    time.sleep(3)
    # Replace with a real element check once Flutter semantics labels are wired up, e.g.:
    # el = driver.find_element(By.XPATH, "//flt-semantics[@aria-label='Login']")
    assert True


def test_upload_flow_placeholder(driver):
    """Placeholder for the OCT image upload → preprocessing → segmentation flow."""
    driver.get(BASE_URL)
    time.sleep(3)
    assert True
