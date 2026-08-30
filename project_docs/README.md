# 📁 RetinaSeg AI — Technical Documentation & Architecture Manual

Welcome to the complete technical documentation repository for **RetinaSeg AI: Automated Retinal Layer Segmentation in Optical Coherence Tomography (OCT) Images**.

---

## 📑 Documentation Index

| File | Document Title | Topics Covered |
|---|---|---|
| **[01_ALGORITHMS_AND_IMAGE_PROCESSING.md](./01_ALGORITHMS_AND_IMAGE_PROCESSING.md)** | **Algorithms & Image Processing** | Bilateral Filtering, CLAHE, Multi-Class U-Net Deep Learning, 8 Retinal Layers, Mathematical Thickness Formulas, Contour Tracing |
| **[02_DATABASE_ARCHITECTURE.md](./02_DATABASE_ARCHITECTURE.md)** | **Database Specifications** | Firebase Cloud Firestore NoSQL, PostgreSQL & SQLite Relational Models, Strict User Data Isolation, Cloud Storage Buckets |
| **[03_PACKAGES_AND_CONFIGURATIONS.md](./03_PACKAGES_AND_CONFIGURATIONS.md)** | **Package & Configuration Reference** | Android `applicationId`, Flutter `pubspec.yaml`, Firebase project `oct-medical-application`, API Endpoints & Ports |
| **[04_USER_MANUAL_AND_WORKFLOW.md](./04_USER_MANUAL_AND_WORKFLOW.md)** | **Clinical User Manual & Workflow** | Clinician Registration, Authentication, Patient Onboarding, Scan Upload, AI Segmentation, Pure White Clinical Report Preview & PDF Export |

---

## 🚀 Quick Overview

- **Frontend**: Flutter Web & Mobile (`frontend/lib/`) + Vanilla HTML5/CSS3/ES6 Web App (`frontend/web/`)
- **Backend API**: Python FastAPI with Uvicorn (`backend/`)
- **Cloud Database & Storage**: Google Firebase Cloud Firestore & Firebase Storage (`oct-medical-application`)
- **Relational Database**: PostgreSQL / SQLite (`backend/models/db_models.py`)
- **AI / Deep Learning Engine**: U-Net 4-Depth Residual Neural Network (`backend/services/segmentation_service.py`)
- **Image Processing**: OpenCV (`cv2`), NumPy, Scipy (`backend/services/preprocessing_service.py`)
