# 📦 Packages, Identifiers & Configuration Reference

This document provides a quick reference for all application packages, bundle IDs, environment variables, and API endpoints across Flutter, Android, Python, and Firebase.

---

## 1. 📱 Application Identifiers

| Platform / Framework | Configuration File | Identifier / Package Name |
|---|---|---|
| **Android Application** | `frontend/android/app/build.gradle` | `applicationId "com.example.oct_retinal_segmentation"` |
| **Android Namespace** | `frontend/android/app/build.gradle` | `namespace "com.example.oct_retinal_segmentation"` |
| **Flutter Project** | `frontend/pubspec.yaml` | `name: retinaseg_ai` (v1.0.0+1) |
| **Python Backend** | `backend/` | `backend` (FastAPI Service) |
| **Firebase Project** | `.firebaserc`, `firebase.json` | `oct-medical-application` |

---

## 2. ☁️ Firebase Project Configuration

- **Project ID**: `oct-medical-application`
- **Storage Bucket**: `oct-medical-application.firebasestorage.app`
- **Web App ID**: `1:460488188037:web:d90ffb9e3b841df9fd89ec`
- **Auth Domain**: `oct-medical-application.firebaseapp.com`

---

## 3. 🌐 API Endpoints & Port Configuration

- **Backend Base URL (Flutter Web / Browser)**: `http://127.0.0.1:8000`
- **Backend Base URL (Android Emulator)**: `http://10.0.2.2:8000`
- **Interactive OpenAPI Documentation**: `http://127.0.0.1:8000/docs`
- **Health Check Endpoint**: `http://127.0.0.1:8000/health`

### Key REST Endpoints:
| Route | Method | Description |
|---|---|---|
| `/api/auth/register` | `POST` | Registers new clinician & issues JWT session |
| `/api/auth/login` | `POST` | Authenticates clinician via bcrypt hash |
| `/api/auth/me` | `GET` | Validates JWT token & restores session |
| `/api/dashboard/stats` | `GET` | Retrieves user-isolated clinical dashboard statistics |
| `/api/patients` | `GET`, `POST` | Manages patient demographic records |
| `/api/oct/upload` | `POST` | Uploads OCT B-scan images |
| `/api/analysis/segment` | `POST` | Runs 8-layer U-Net AI segmentation |
| `/api/reports/generate` | `POST` | Generates diagnostic PDF reports |
