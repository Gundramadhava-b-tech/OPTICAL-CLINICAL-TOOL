import hashlib
import uuid
from pathlib import Path
from typing import Dict, Any
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from PIL import Image
from backend.config import settings, UPLOADS_DIR
from backend.schemas.api_schemas import OCTScanResponse, OCTValidationResponse
from backend.services.auth_service import get_current_user
from backend.services.validation_service import OCTValidationService
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/oct", tags=["OCT Image Management"])

@router.post("/validate-only", response_model=OCTValidationResponse)
async def validate_standalone(
    file: UploadFile = File(...),
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "png"
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file format '{ext}'. Supported formats: {list(settings.ALLOWED_EXTENSIONS)}"
        )
        
    temp_filename = f"temp_val_{uuid.uuid4().hex}.{ext}"
    temp_path = UPLOADS_DIR / temp_filename
    
    contents = await file.read()
    if len(contents) > settings.MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File exceeds maximum upload limit of {settings.MAX_UPLOAD_SIZE_BYTES / (1024*1024)} MB."
        )
        
    with open(temp_path, "wb") as f:
        f.write(contents)
        
    val_result = OCTValidationService.validate_image_file(temp_path)
    
    if temp_path.exists():
        temp_path.unlink()
        
    return val_result

@router.post("/upload", response_model=OCTScanResponse)
async def upload_oct_scan(
    patient_id: str = Form(...),
    eye_laterality: str = Form("OD"),
    device_manufacturer: str = Form("Spectralis/Cirrus Compatible"),
    axial_resolution_um: float = Form(settings.DEFAULT_AXIAL_CALIBRATION_UM),
    file: UploadFile = File(...),
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    patient = firebase_db.get_patient(patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found or unauthorized."
        )
    p_user = str(patient.get("created_by", "")).lower()
    p_uid = str(patient.get("created_by_id", ""))
    if p_user != current_user["email"].lower() and p_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found or unauthorized."
        )
        
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "png"
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image file format '{ext}'. Allowed formats: {list(settings.ALLOWED_EXTENSIONS)}"
        )
        
    contents = await file.read()
    if len(contents) > settings.MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds the 25 MB limit."
        )
        
    sha256_hash = hashlib.sha256(contents).hexdigest()
    scan_uid = f"OCT-{uuid.uuid4().hex[:8].upper()}"
    saved_filename = f"{scan_uid}_{file.filename}"
    file_path = UPLOADS_DIR / saved_filename
    
    with open(file_path, "wb") as f:
        f.write(contents)
        
    try:
        with Image.open(file_path) as pil_img:
            width, height = pil_img.size
    except Exception:
        if file_path.exists():
            file_path.unlink()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is not a valid decodable image."
        )
        
    val_result = OCTValidationService.validate_image_file(file_path)
    val_status = "VALID" if val_result["is_valid_oct"] else "INVALID"
    if not val_result["is_valid_oct"] and val_result["status"] == "WARNING":
        val_status = "WARNING"
        
    if val_status == "INVALID":
        if file_path.exists():
            file_path.unlink()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": "Invalid Image",
                "message": "Please upload a valid retinal OCT image suitable for retinal layer segmentation.",
                "reasons": val_result.get("reasons", ["Uploaded file does not match retinal OCT B-scan tissue characteristics."]),
                "metrics": val_result.get("image_metrics", {})
            }
        )
        
    lat = eye_laterality.upper() if eye_laterality.upper() in ("OD", "OS", "OU") else "OD"
    
    scan_data = {
        "scan_uid": scan_uid,
        "patient_id": str(patient["id"]),
        "patient_name": patient.get("full_name", ""),
        "file_path": str(file_path),
        "original_filename": file.filename,
        "file_url": f"/api/static/uploads/{file_path.name}",
        "file_size_bytes": len(contents),
        "width": width,
        "height": height,
        "sha256_hash": sha256_hash,
        "eye_laterality": lat,
        "device_manufacturer": device_manufacturer,
        "axial_resolution_um": axial_resolution_um,
        "validation_status": val_status,
        "validation_score": val_result.get("confidence_score", 0.95),
        "validation_details": val_result,
        "uploaded_by": current_user["email"],
        "uploaded_by_id": str(current_user["id"])
    }
    
    created_scan = firebase_db.create_oct_scan(scan_data)
    
    # Audit log in Firestore
    firebase_db.log_audit_event({
        "user_id": current_user["id"],
        "user_email": current_user["email"],
        "action": "OCT_SCAN_UPLOADED",
        "resource_type": "OCT_SCAN",
        "resource_id": str(created_scan["id"]),
        "details": {"scan_uid": created_scan["scan_uid"], "filename": created_scan["original_filename"]}
    })
    
    return {
        "id": created_scan["id"],
        "scan_uid": created_scan["scan_uid"],
        "patient_id": created_scan["patient_id"],
        "patient_name": patient.get("full_name", ""),
        "original_filename": created_scan["original_filename"],
        "file_url": created_scan["file_url"],
        "file_size_bytes": created_scan["file_size_bytes"],
        "width": created_scan["width"],
        "height": created_scan["height"],
        "eye_laterality": created_scan["eye_laterality"],
        "device_manufacturer": created_scan["device_manufacturer"],
        "axial_resolution_um": created_scan["axial_resolution_um"],
        "validation_status": created_scan["validation_status"],
        "validation_score": created_scan["validation_score"],
        "validation_details": created_scan["validation_details"],
        "created_at": created_scan["created_at"]
    }

@router.get("/{scan_id}", response_model=OCTScanResponse)
def get_scan_details(
    scan_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    scan = firebase_db.get_oct_scan(scan_id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan record not found."
        )
    s_user = str(scan.get("uploaded_by", "")).lower()
    s_uid = str(scan.get("uploaded_by_id", ""))
    if s_user != current_user["email"].lower() and s_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan record not found."
        )
        
    return {
        "id": scan["id"],
        "scan_uid": scan["scan_uid"],
        "patient_id": scan["patient_id"],
        "patient_name": scan.get("patient_name", "Patient"),
        "original_filename": scan["original_filename"],
        "file_url": scan["file_url"],
        "file_size_bytes": scan["file_size_bytes"],
        "width": scan["width"],
        "height": scan["height"],
        "eye_laterality": scan["eye_laterality"],
        "device_manufacturer": scan["device_manufacturer"],
        "axial_resolution_um": scan["axial_resolution_um"],
        "validation_status": scan["validation_status"],
        "validation_score": scan.get("validation_score", 0.95),
        "validation_details": scan.get("validation_details", {}),
        "created_at": scan["created_at"]
    }
