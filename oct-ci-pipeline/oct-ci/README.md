# CI/CD Pipeline — Retinal OCT Segmentation

Mirrors the AeroDiag pipeline: Unit → Validation → Selenium (web) → Appium
(Android) → Load (k6) → Deployment check → a compiled Excel + dark-mode
HTML dashboard deployed to GitHub Pages.

## 1. Drop these into your repo

```
your-repo/
├── .github/workflows/ci.yml        ← copy as-is
├── scripts/generate_master_report.py
├── tests/
│   ├── selenium/test_web_e2e.py
│   ├── appium/test_android_e2e.py
│   └── load/loadtest.js
└── backend/
    ├── tests/unit/test_unit.py        ← from tests/api/
    ├── tests/validation/test_validation.py
    └── tests/deployment/test_deployment.py
```

`backend/` and `frontend/` are assumed as your FastAPI and Flutter folder
names — rename the `working-directory:` and `flutter build` paths in
`ci.yml` if yours differ.

## 2. Fill in the placeholders

- `backend/app/main.py` must expose a `/health` route returning 200.
- `backend/requirements.txt` needs `fastapi`, `uvicorn`, plus whatever your
  U-Net/preprocessing code imports.
- In `tests/appium/test_android_e2e.py`, set `app_package` to your real
  Flutter `applicationId` (check `frontend/android/app/build.gradle`).
- The unit/validation test bodies are stubs with example code in
  docstrings — swap the `assert True` lines for real imports once your
  `app/` modules exist.

## 3. Enable GitHub Pages

Repo → Settings → Pages → Source: **GitHub Actions**. The `deploy-pages`
job then publishes `build/reports/dashboard.html` (aliased to `index.html`)
on every push to `main`.

## 4. What the final job does

`compile-master-report` downloads every suite's JSON artifact, then runs
`generate_master_report.py`, which produces:
- `master_report.xlsx` — pass/fail counts + metadata per suite
- `dashboard.html` — the dark dashboard, same structure as the AeroDiag one
  (overall status card, per-suite table, commit SHA, run number)

Both get uploaded as artifacts and the HTML gets pushed to Pages.
