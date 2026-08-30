from pathlib import Path
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from backend.config import settings
from backend.schemas.api_schemas import (
    PreprocessingRequest, PreprocessingResponse, SegmentationRequest, AnalysisResponse, LayerMeasurementResponse
)
from backend.services.auth_service import get_current_user
from backend.services.preprocessing_service import OCTPreprocessingService
from backend.services.segmentation_service import segmentation_service
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/analysis", tags=["OCT AI Analysis & Segmentation"])

@router.post("/preprocess", response_model=PreprocessingResponse)
def run_preprocessing(
    prep_in: PreprocessingRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    scan = firebase_db.get_oct_scan(prep_in.scan_id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan not found or unauthorized."
        )
    s_user = str(scan.get("uploaded_by", "")).lower()
    s_uid = str(scan.get("uploaded_by_id", ""))
    if s_user != current_user["email"].lower() and s_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan not found or unauthorized."
        )
        
    out_filename = f"preproc_{scan.get('scan_uid')}.png"
    
    prep_output = OCTPreprocessingService.preprocess_oct_scan(
        input_file_path=scan["file_path"],
        output_filename=out_filename,
        apply_bilateral=prep_in.apply_bilateral_filter,
        apply_clahe=prep_in.apply_clahe,
        clahe_clip_limit=prep_in.clahe_clip_limit,
        normalize_intensity=prep_in.normalize_intensity,
        target_size=settings.INPUT_SIZE
    )
    
    orig_name = Path(scan["file_path"]).name
    proc_name = Path(prep_output["preprocessed_file_path"]).name
    
    return {
        "id": scan["id"],
        "scan_id": scan["id"],
        "original_image_url": f"/api/static/uploads/{orig_name}",
        "preprocessed_image_url": f"/api/static/processed/{proc_name}",
        "methods_applied": prep_output["methods_applied"],
        "noise_reduction_snr": prep_output["noise_reduction_snr"],
        "contrast_enhancement_ratio": prep_output["contrast_enhancement_ratio"],
        "execution_time_ms": prep_output["execution_time_ms"],
        "created_at": scan.get("created_at")
    }

@router.post("/segment", response_model=AnalysisResponse)
def run_segmentation(
    seg_in: SegmentationRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    scan = firebase_db.get_oct_scan(seg_in.scan_id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan not found or unauthorized."
        )
    s_user = str(scan.get("uploaded_by", "")).lower()
    s_uid = str(scan.get("uploaded_by_id", ""))
    if s_user != current_user["email"].lower() and s_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OCT scan not found or unauthorized."
        )
        
    out_filename = f"preproc_{scan.get('scan_uid')}.png"
    prep_output = OCTPreprocessingService.preprocess_oct_scan(
        input_file_path=scan["file_path"],
        output_filename=out_filename
    )
    
    seg_res = segmentation_service.segment(
        preprocessed_image_path=prep_output["preprocessed_file_path"],
        original_image_path=scan["file_path"],
        confidence_threshold=seg_in.confidence_threshold,
        axial_calibration_um=scan.get("axial_resolution_um", 3.87)
    )
    
    patient = firebase_db.get_patient(scan.get("patient_id"))
    patient_name = patient.get("full_name") if patient else scan.get("patient_name", "Patient")
    
    layer_models = []
    for l_dict in seg_res["layers"]:
        r, g, b, _ = settings.LAYER_COLORS.get(l_dict["layer_name"], (120, 120, 120, 255))
        layer_models.append({
            "layer_name": l_dict["layer_name"],
            "layer_index": l_dict["layer_index"],
            "is_detected": l_dict["is_detected"],
            "mean_thickness_px": l_dict["mean_thickness_px"],
            "min_thickness_px": l_dict["min_thickness_px"],
            "max_thickness_px": l_dict["max_thickness_px"],
            "mean_thickness_um": l_dict["mean_thickness_um"],
            "min_thickness_um": l_dict["min_thickness_um"],
            "max_thickness_um": l_dict["max_thickness_um"],
            "layer_area_px": l_dict["layer_area_px"],
            "confidence_score": l_dict["confidence_score"],
            "color_hex": f"#{r:02X}{g:02X}{b:02X}",
            "boundary_points_count": 20
        })
        
    orig_name = Path(scan["file_path"]).name
    proc_name = Path(prep_output["preprocessed_file_path"]).name
    mask_name = Path(seg_res["mask_file_path"]).name
    over_name = Path(seg_res["overlay_file_path"]).name
    
    analysis_data = {
        "scan_id": str(scan["id"]),
        "scan_uid": scan.get("scan_uid"),
        "patient_id": str(scan.get("patient_id")),
        "patient_name": patient_name,
        "patient_age": patient.get("age") if patient else 55,
        "patient_gender": patient.get("gender") if patient else "Female",
        "eye_laterality": scan.get("eye_laterality", "OD"),
        "device_manufacturer": scan.get("device_manufacturer", "Heidelberg Spectralis OCT"),
        "status": "COMPLETED",
        "confidence_score": seg_res["confidence_score"],
        "overall_quality": seg_res["overall_quality"],
        "quality_metrics": seg_res["quality_metrics"],
        "execution_time_ms": seg_res["execution_time_ms"],
        "mask_url": f"/api/static/masks/{mask_name}",
        "overlay_url": f"/api/static/overlays/{over_name}",
        "preprocessed_image_url": f"/api/static/processed/{proc_name}",
        "original_image_url": f"/api/static/uploads/{orig_name}",
        "findings_summary": seg_res["findings_summary"],
        "layer_metrics": seg_res["layers"],
        "is_calibrated": seg_res["is_calibrated"],
        "axial_calibration_um": seg_res["axial_calibration_um"],
        "analyzed_by": current_user["email"],
        "analyzed_by_id": str(current_user["id"])
    }
    
    created_analysis = firebase_db.create_analysis_result(analysis_data)
    
    # Audit log in Firestore
    firebase_db.log_audit_event({
        "user_id": current_user["id"],
        "user_email": current_user["email"],
        "action": "SEGMENTATION_ANALYSIS_COMPLETED",
        "resource_type": "ANALYSIS",
        "resource_id": str(created_analysis["id"]),
        "details": {"scan_uid": scan.get("scan_uid"), "confidence": created_analysis["confidence_score"]}
    })
    
    return {
        "id": created_analysis["id"],
        "scan_id": scan["id"],
        "patient_id": scan.get("patient_id", 0),
        "patient_name": patient_name,
        "patient_age": patient.get("age") if patient else 55,
        "patient_gender": patient.get("gender") if patient else "Female",
        "eye_laterality": scan.get("eye_laterality", "OD"),
        "device_manufacturer": scan.get("device_manufacturer", "Heidelberg Spectralis OCT"),
        "status": created_analysis["status"],
        "confidence_score": created_analysis["confidence_score"],
        "overall_quality": created_analysis["overall_quality"],
        "quality_metrics": created_analysis.get("quality_metrics"),
        "execution_time_ms": created_analysis["execution_time_ms"],
        "original_image_url": created_analysis["original_image_url"],
        "preprocessed_image_url": created_analysis["preprocessed_image_url"],
        "mask_image_url": created_analysis["mask_url"],
        "overlay_image_url": created_analysis["overlay_url"],
        "findings_summary": created_analysis["findings_summary"],
        "layers": layer_models,
        "is_calibrated": seg_res["is_calibrated"],
        "axial_calibration_um": seg_res["axial_calibration_um"],
        "created_at": created_analysis["created_at"]
    }

@router.get("/{analysis_id}", response_model=AnalysisResponse)
def get_analysis_result(
    analysis_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    analysis = firebase_db.get_analysis(analysis_id)
    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis result not found."
        )
    a_user = str(analysis.get("analyzed_by", "")).lower()
    a_uid = str(analysis.get("analyzed_by_id", ""))
    if a_user != current_user["email"].lower() and a_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis result not found."
        )
        
    layers_raw = analysis.get("layer_metrics", [])
    layers_data = []
    for l in layers_raw:
        lname = l.get("layer_name", "")
        r, g, b, _ = settings.LAYER_COLORS.get(lname, (120, 120, 120, 255))
        layers_data.append({
            "layer_name": lname,
            "layer_index": l.get("layer_index", 0),
            "is_detected": l.get("is_detected", True),
            "mean_thickness_px": l.get("mean_thickness_px", 0.0),
            "min_thickness_px": l.get("min_thickness_px", 0.0),
            "max_thickness_px": l.get("max_thickness_px", 0.0),
            "mean_thickness_um": l.get("mean_thickness_um"),
            "min_thickness_um": l.get("min_thickness_um"),
            "max_thickness_um": l.get("max_thickness_um"),
            "layer_area_px": l.get("layer_area_px", 0),
            "confidence_score": l.get("confidence_score", 0.95),
            "color_hex": f"#{r:02X}{g:02X}{b:02X}",
            "boundary_points_count": 20
        })
        
    return {
        "id": analysis["id"],
        "scan_id": analysis.get("scan_id", 0),
        "patient_id": analysis.get("patient_id", 0),
        "patient_name": analysis.get("patient_name", "Patient"),
        "patient_age": analysis.get("patient_age", 55),
        "patient_gender": analysis.get("patient_gender", "Female"),
        "eye_laterality": analysis.get("eye_laterality", "OD"),
        "device_manufacturer": analysis.get("device_manufacturer", "Heidelberg Spectralis OCT"),
        "status": analysis.get("status", "COMPLETED"),
        "confidence_score": analysis.get("confidence_score", 0.94),
        "overall_quality": analysis.get("overall_quality", "Good"),
        "quality_metrics": analysis.get("quality_metrics", {}),
        "execution_time_ms": analysis.get("execution_time_ms", 320.0),
        "original_image_url": analysis.get("original_image_url", ""),
        "preprocessed_image_url": analysis.get("preprocessed_image_url", ""),
        "mask_image_url": analysis.get("mask_url", ""),
        "overlay_image_url": analysis.get("overlay_url", ""),
        "findings_summary": analysis.get("findings_summary", ""),
        "layers": layers_data,
        "is_calibrated": True,
        "axial_calibration_um": 3.87,
        "created_at": analysis.get("created_at")
    }

@router.get("/history/all", response_model=List[Dict[str, Any]])
def get_analysis_history(
    patient_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    skip: int = 0,
    limit: int = 50,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    user_analyses = firebase_db.get_analyses_by_user(current_user["email"])
    
    if patient_id:
        user_analyses = [a for a in user_analyses if str(a.get("patient_id")) == str(patient_id)]
    if status:
        user_analyses = [a for a in user_analyses if a.get("status") == status]
    if search:
        s_lower = search.lower()
        user_analyses = [
            a for a in user_analyses
            if s_lower in str(a.get("patient_name", "")).lower() or s_lower in str(a.get("scan_uid", "")).lower()
        ]
        
    results = []
    all_reports = firebase_db.get_reports_by_user(current_user["email"])
    for a in user_analyses[skip : skip + limit]:
        created_dt = a.get("created_at", "")[:16].replace("T", " ")
        matching_rep = next((r for r in all_reports if str(r.get("analysis_id")) == str(a.get("id"))), None)
        results.append({
            "id": a.get("id"),
            "scan_id": a.get("scan_id"),
            "scan_uid": a.get("scan_uid", "N/A"),
            "patient_id": a.get("patient_id"),
            "patient_name": a.get("patient_name", "N/A"),
            "patient_mrn": a.get("patient_id", "N/A"),
            "scan_type": f"Retinal B-Scan ({a.get('eye_laterality', 'OD')})",
            "date": created_dt,
            "status": a.get("status", "COMPLETED"),
            "confidence_score": f"{int(float(a.get('confidence_score', 0.94)) * 100)}%",
            "overall_quality": a.get("overall_quality", "Good"),
            "has_report": bool(matching_rep is not None),
            "report_id": matching_rep.get("id") if matching_rep else None,
            "execution_time_ms": a.get("execution_time_ms", 320.0)
        })
    return results
