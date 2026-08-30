import os
import logging
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse, FileResponse
from backend.config import settings, STORAGE_DIR, UPLOADS_DIR, PROCESSED_DIR, MASKS_DIR, OVERLAYS_DIR, REPORTS_DIR, BASE_DIR
from backend.services.firebase_db_service import firebase_db
from backend.api.routes import auth, patients, oct, analysis, reports, dashboard, admin

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Medical-grade ophthalmic AI platform for automated retinal layer segmentation in Optical Coherence Tomography (OCT) images backed by Google Firebase Cloud Firestore.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Configuration for Flutter Web and Android
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Web Client Directory
WEB_DIR = BASE_DIR.parent / "frontend" / "web"

# Mount Static Storage Directories for direct image and PDF downloads
app.mount("/api/static/uploads", StaticFiles(directory=str(UPLOADS_DIR)), name="uploads")
app.mount("/api/static/processed", StaticFiles(directory=str(PROCESSED_DIR)), name="processed")
app.mount("/api/static/masks", StaticFiles(directory=str(MASKS_DIR)), name="masks")
app.mount("/api/static/overlays", StaticFiles(directory=str(OVERLAYS_DIR)), name="overlays")
app.mount("/api/static/reports", StaticFiles(directory=str(REPORTS_DIR)), name="reports")

# Include API Routers first
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(patients.router, prefix=settings.API_V1_STR)
app.include_router(oct.router, prefix=settings.API_V1_STR)
app.include_router(analysis.router, prefix=settings.API_V1_STR)
app.include_router(reports.router, prefix=settings.API_V1_STR)
app.include_router(dashboard.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)

@app.on_event("startup")
def startup_event():
    """Initializes Firebase Cloud Firestore connections on startup."""
    logging.info(f"RetinaSeg AI online. Primary Database: Firebase Cloud Firestore ({settings.FIREBASE_PROJECT_ID}).")

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "database": "Google Firebase Cloud Firestore",
        "firebase_project": settings.FIREBASE_PROJECT_ID,
        "firebase_connected": firebase_db.is_connected,
        "unet_model": settings.MODEL_VERSION,
        "layers_supported": len(settings.LAYER_CLASSES) - 1,
        "storage": "Firebase Cloud Storage & Local Binary Cache"
    }

# Mount static web frontend at root (after API routes so API is prioritized)
if WEB_DIR.exists():
    app.mount("/", StaticFiles(directory=str(WEB_DIR), html=True), name="static_web")
