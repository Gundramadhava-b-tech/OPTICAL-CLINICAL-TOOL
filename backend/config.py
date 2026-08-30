import os
from pathlib import Path
from pydantic import BaseModel

BASE_DIR = Path(__file__).resolve().parent
STORAGE_DIR = BASE_DIR / "storage"
UPLOADS_DIR = STORAGE_DIR / "uploads"
PROCESSED_DIR = STORAGE_DIR / "processed"
MASKS_DIR = STORAGE_DIR / "masks"
OVERLAYS_DIR = STORAGE_DIR / "overlays"
REPORTS_DIR = STORAGE_DIR / "reports"
MODELS_DIR = BASE_DIR / "ai_model" / "weights"

for folder in [STORAGE_DIR, UPLOADS_DIR, PROCESSED_DIR, MASKS_DIR, OVERLAYS_DIR, REPORTS_DIR, MODELS_DIR]:
    folder.mkdir(parents=True, exist_ok=True)

class Settings(BaseModel):
    PROJECT_NAME: str = "RetinaSeg AI - Automated Retinal Layer Segmentation"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "retina-seg-ai-secure-secret-key-ophthalmology-2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    
    # Primary Database: Google Firebase Cloud Firestore & Cloud Storage
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "oct-medical-application")
    FIREBASE_DATABASE_URL: str = os.getenv("FIREBASE_DATABASE_URL", "https://oct-medical-application.firebaseio.com")
    FIREBASE_STORAGE_BUCKET: str = os.getenv("FIREBASE_STORAGE_BUCKET", "oct-medical-application.firebasestorage.app")
    
    # Model Configuration
    MODEL_PATH: str = str(MODELS_DIR / "retina_unet_v1.onnx")
    MODEL_VERSION: str = "RetinaUNet-v1.4.2-MultiLayer"
    INPUT_SIZE: tuple = (512, 512)
    NUM_CLASSES: int = 9  # Background + 8 Retinal Layers
    CONFIDENCE_THRESHOLD: float = 0.5
    
    # Retinal Layer Classes
    LAYER_CLASSES: list[str] = [
        "Background",
        "ILM",       # Inner Limiting Membrane / Vitreoretinal Interface
        "RNFL",      # Retinal Nerve Fiber Layer
        "GCL",       # Ganglion Cell Layer
        "IPL",       # Inner Plexiform Layer
        "INL",       # Inner Nuclear Layer
        "OPL",       # Outer Plexiform Layer
        "ONL",       # Outer Nuclear Layer / Inner Segments
        "RPE",       # Retinal Pigment Epithelium / Outer Segments
    ]
    
    LAYER_COLORS: dict[str, tuple] = {
        "ILM": (255, 23, 68, 255),       # Crimson Red
        "RNFL": (255, 145, 0, 255),      # Amber Orange
        "GCL": (255, 234, 0, 255),       # Gold Yellow
        "IPL": (0, 230, 118, 255),       # Mint Green
        "INL": (0, 176, 255, 255),       # Sky Blue
        "OPL": (101, 31, 255, 255),      # Indigo
        "ONL": (213, 0, 249, 255),       # Violet
        "RPE": (245, 0, 87, 255),        # Deep Magenta
    }
    
    # File limits
    MAX_UPLOAD_SIZE_BYTES: int = 25 * 1024 * 1024  # 25 MB
    ALLOWED_EXTENSIONS: set = {"png", "jpg", "jpeg", "tif", "tiff", "dcm", "bmp"}
    
    # Pixel-to-micron calibration
    DEFAULT_AXIAL_CALIBRATION_UM: float = 3.87

settings = Settings()
