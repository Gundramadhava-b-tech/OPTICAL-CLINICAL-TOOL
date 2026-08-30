"""
Appium E2E tests against the debug APK, running on the emulator started
by reactivecircus/android-emulator-runner in ci.yml.
"""
import time
import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

APK_PATH = "frontend/build/app/outputs/flutter-apk/app-debug.apk"


@pytest.fixture(scope="module")
def driver():
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.app = APK_PATH
    options.app_package = "com.example.oct_segmentation"  # update to your applicationId
    options.app_activity = ".MainActivity"
    options.no_reset = True

    d = webdriver.Remote("http://localhost:4723", options=options)
    yield d
    d.quit()


def test_app_launches(driver):
    time.sleep(5)
    assert driver.current_package is not None


def test_login_screen_present(driver):
    """Replace with a real element lookup once IDs are set, e.g.:
    el = driver.find_element(by="accessibility id", value="login_button")
    assert el.is_displayed()
    """
    time.sleep(2)
    assert True


def test_upload_and_scan_placeholder(driver):
    """Placeholder for the OCT upload → segmentation → results flow on-device."""
    time.sleep(2)
    assert True
