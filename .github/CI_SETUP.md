# CI/CD Pipeline Setup — RetinaSeg AI

This project uses **GitHub Actions** for a multi-stage automated testing and reporting pipeline.

## 🚀 Workflow Overview
The pipeline consists of 6 parallel test jobs followed by a master report compilation and deployment to GitHub Pages.

1.  **🧪 Unit Tests**: Runs Flutter unit tests and Python (FastAPI/AI) tests using `pytest`.
2.  **✅ Validation Tests**: Verifies application logic, data isolation, and clinical rules.
3.  **🌐 Selenium Web Tests**: Builds the Flutter Web release and runs browser automation.
4.  **📱 Appium Android Tests**: Builds the Android APK and runs mobile UI tests.
5.  **⚡ Load Testing**: Executes high-throughput performance tests on API endpoints.
6.  **🚀 Deployment Status**: Final build integrity and configuration check.

## 📊 Master Report
After tests complete, a Python script (`scripts/generate_master_report.py`) parses all JUnit XML results and generates a professional HTML dashboard. 

**View the report**:
- Go to the **Actions** tab in GitHub.
- Click on the latest workflow run.
- Scroll down to the **Summary** to see the Executive Matrix.
- Or visit your **GitHub Pages** URL to see the full HTML dashboard.

## 🛠️ Configuration

### GitHub Secrets
To fully enable the pipeline, configure the following in **Settings > Secrets and variables > Actions**:

| Secret Name | Purpose |
| --- | --- |
| `FIREBASE_API_KEY` | Used for authenticating against the production Firebase project. |
| `DATABASE_URL` | Connection string for the test PostgreSQL database. |
| `TEST_USERNAME` | Valid credentials for the validation test suite. |
| `TEST_PASSWORD` | Password for the test account. |

### Enabling GitHub Pages
1. Go to **Settings > Pages**.
2. Under **Build and deployment > Source**, select **GitHub Actions**.
3. The pipeline will now automatically update your site on every push to `master`.

## 🧪 Running Locally
You can run the individual test components on your machine:

**Unit Tests (Python)**:
```bash
pytest backend/tests oct_ai_pipeline/tests --junitxml=results/unit-results.xml
```

**Flutter Tests**:
```bash
cd frontend
flutter test
```

**Generate Master Report**:
```bash
python scripts/generate_master_report.py --sha local --run-number 1 --results-dir results
```
