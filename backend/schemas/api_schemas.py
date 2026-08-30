from datetime import datetime
from typing import Optional, Any, Union, List, Dict
from pydantic import BaseModel, Field

# Authentication Schemas
class UserRegisterRequest(BaseModel):
    email: str
    full_name: str
    password: str = Field(..., min_length=6)
    role: str = "OPHTHALMOLOGIST"  # ADMIN, OPHTHALMOLOGIST, TECHNICIAN
    specialty: Optional[str] = "Retina Specialist"
    license_number: Optional[str] = None

class UserLoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"

class UserResponse(BaseModel):
    id: Any
    email: str
    full_name: str
    role: str
    specialty: Optional[str] = None
    license_number: Optional[str] = None
    is_active: bool = True
    created_at: Optional[Any] = None
    last_login: Optional[Any] = None

    class Config:
        from_attributes = True

# Patient Schemas
class PatientCreateRequest(BaseModel):
    patient_id: Optional[str] = None
    full_name: str
    age: int
    gender: str
    contact: Optional[str] = None
    email: Optional[str] = None
    medical_history: Optional[str] = None
    eye_condition: Optional[str] = "Routine OCT Evaluation"

class PatientUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    contact: Optional[str] = None
    email: Optional[str] = None
    medical_history: Optional[str] = None
    eye_condition: Optional[str] = None

class PatientResponse(BaseModel):
    id: Any
    patient_id: str
    full_name: str
    age: int
    gender: str
    contact: Optional[str] = None
    email: Optional[str] = None
    medical_history: Optional[str] = None
    eye_condition: Optional[str] = None
    date_registered: Optional[Any] = None
    scans_count: int = 0

    class Config:
        from_attributes = True

# OCT Image Schemas
class OCTValidationResponse(BaseModel):
    is_valid_oct: bool
    status: str  # VALID, INVALID, WARNING
    confidence_score: float
    message: str
    reasons: List[str]
    image_metrics: Dict[str, Any]

class OCTScanResponse(BaseModel):
    id: Any
    scan_uid: str
    patient_id: Any
    patient_name: Optional[str] = None
    original_filename: str
    file_url: str
    file_size_bytes: int
    width: int
    height: int
    eye_laterality: str
    device_manufacturer: str
    axial_resolution_um: Optional[float] = None
    validation_status: str
    validation_score: Optional[float] = None
    validation_details: Optional[Dict[str, Any]] = None
    created_at: Optional[Any] = None

    class Config:
        from_attributes = True

# Preprocessing Schemas
class PreprocessingRequest(BaseModel):
    scan_id: Any
    apply_bilateral_filter: bool = True
    apply_clahe: bool = True
    clahe_clip_limit: float = 2.5
    normalize_intensity: bool = True

class PreprocessingResponse(BaseModel):
    id: Any
    scan_id: Any
    original_image_url: str
    preprocessed_image_url: str
    methods_applied: List[str]
    noise_reduction_snr: Optional[float] = None
    contrast_enhancement_ratio: Optional[float] = None
    execution_time_ms: float
    created_at: Optional[Any] = None

# Segmentation & Analysis Schemas
class SegmentationRequest(BaseModel):
    scan_id: Any
    model_version_id: Optional[Any] = None
    confidence_threshold: float = 0.5
    include_boundary_data: bool = True

class LayerMeasurementResponse(BaseModel):
    layer_name: str
    layer_index: int
    is_detected: bool
    mean_thickness_px: float
    min_thickness_px: float
    max_thickness_px: float
    mean_thickness_um: Optional[float] = None
    min_thickness_um: Optional[float] = None
    max_thickness_um: Optional[float] = None
    layer_area_px: int
    confidence_score: Optional[float] = None
    color_hex: Optional[str] = None
    boundary_points_count: int = 0

class AnalysisResponse(BaseModel):
    id: Any
    scan_id: Any
    patient_id: Any
    patient_name: str
    patient_age: Optional[int] = None
    patient_gender: Optional[str] = None
    eye_laterality: Optional[str] = None
    device_manufacturer: Optional[str] = None
    status: str
    confidence_score: Optional[float] = None
    overall_quality: str  # Good, Acceptable, Poor
    quality_metrics: Optional[Dict[str, Any]] = None
    execution_time_ms: float
    original_image_url: str
    preprocessed_image_url: Optional[str] = None
    mask_image_url: Optional[str] = None
    overlay_image_url: Optional[str] = None
    findings_summary: Optional[str] = None
    layers: List[LayerMeasurementResponse]
    is_calibrated: bool
    axial_calibration_um: Optional[float] = None
    created_at: Optional[Any] = None

# Report Schemas
class ReportGenerateRequest(BaseModel):
    analysis_id: Any
    notes: Optional[str] = None
    include_preprocessed: bool = True
    include_measurements_table: bool = True

class ReportResponse(BaseModel):
    id: Any
    analysis_id: Any
    patient_id: Any
    patient_name: str
    report_uid: str
    pdf_url: str
    generated_at: Optional[Any] = None
    notes: Optional[str] = None
    disclaimer: str

# Dashboard Statistics Schemas
class DashboardStatsResponse(BaseModel):
    total_patients: int
    total_scans: int
    analyses_completed: int
    analyses_pending: int
    reports_generated: int
    recent_analyses: List[Dict[str, Any]]
    quality_distribution: Dict[str, int]
    system_status: str
