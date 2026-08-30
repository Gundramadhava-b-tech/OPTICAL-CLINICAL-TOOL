import uuid
from pathlib import Path
from typing import Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from backend.schemas.api_schemas import ReportGenerateRequest, ReportResponse
from backend.services.auth_service import get_current_user
from backend.services.report_service import report_service
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/reports", tags=["Clinical PDF Reports"])

@router.post("/generate", response_model=ReportResponse)
def generate_report(
    rep_in: ReportGenerateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    analysis = firebase_db.get_analysis(rep_in.analysis_id)
    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis result not found or unauthorized."
        )
    a_user = str(analysis.get("analyzed_by", "")).lower()
    a_uid = str(analysis.get("analyzed_by_id", ""))
    if a_user != current_user["email"].lower() and a_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis result not found or unauthorized."
        )
        
    scan = firebase_db.get_oct_scan(analysis.get("scan_id"))
    patient = firebase_db.get_patient(analysis.get("patient_id"))
    
    # Check if a report already exists in Firestore
    user_reports = firebase_db.get_reports_by_user(current_user["email"])
    existing_rep = next((r for r in user_reports if str(r.get("analysis_id")) == str(analysis.get("id"))), None)
    if existing_rep and Path(existing_rep.get("pdf_path", "")).exists():
        return {
            "id": existing_rep["id"],
            "analysis_id": analysis["id"],
            "patient_id": patient.get("id") if patient else 0,
            "patient_name": patient.get("full_name") if patient else "Patient",
            "report_uid": existing_rep["report_uid"],
            "pdf_url": f"/api/reports/download/{existing_rep['id']}",
            "generated_at": existing_rep.get("created_at"),
            "notes": existing_rep.get("clinical_notes"),
            "disclaimer": "AI assistance only — results should be reviewed by a qualified eye-care professional."
        }
        
    report_uid = f"REP-{uuid.uuid4().hex[:8].upper()}"
    
    patient_data = {
        "patient_id": patient.get("patient_id") if patient else "PAT-001",
        "full_name": patient.get("full_name") if patient else "Patient",
        "age": patient.get("age") if patient else 55,
        "gender": patient.get("gender") if patient else "Female",
        "eye_condition": patient.get("eye_condition") if patient else "Routine Evaluation"
    }
    
    scan_data = {
        "scan_uid": scan.get("scan_uid") if scan else "OCT-SCAN",
        "file_path": scan.get("file_path") if scan else "",
        "eye_laterality": scan.get("eye_laterality", "OD") if scan else "OD",
        "width": scan.get("width", 512) if scan else 512,
        "height": scan.get("height", 512) if scan else 512,
        "axial_resolution_um": scan.get("axial_resolution_um", 3.87) if scan else 3.87
    }
    
    prep_data = {
        "preprocessed_file_path": analysis.get("preprocessed_image_url", ""),
        "methods_applied": ["Grayscale Standardisation", "Bilateral Edge-Preserving Filter", "CLAHE"]
    }
    
    layers_data = analysis.get("layer_metrics", [])
    
    analysis_data = {
        "mask_file_path": analysis.get("mask_url", ""),
        "overlay_file_path": analysis.get("overlay_url", ""),
        "overall_quality": analysis.get("overall_quality", "Good"),
        "confidence_score": analysis.get("confidence_score", 0.94),
        "findings_summary": analysis.get("findings_summary", "Retinal layer segmentation verified."),
        "model_version": "RetinaUNet-v1.4.2-MultiLayer",
        "layers": layers_data
    }
    
    pdf_path = report_service.generate_pdf_report(
        report_uid=report_uid,
        patient_data=patient_data,
        scan_data=scan_data,
        preprocessing_data=prep_data,
        analysis_data=analysis_data,
        doctor_name=current_user.get("full_name", "Dr. S. Reynolds, MD"),
        notes=rep_in.notes
    )
    
    report_dict = {
        "report_uid": report_uid,
        "analysis_id": str(analysis["id"]),
        "patient_id": str(patient.get("id")) if patient else "0",
        "patient_name": patient_data["full_name"],
        "scan_id": str(scan.get("id")) if scan else "0",
        "pdf_path": pdf_path,
        "pdf_url": f"/api/reports/download/{report_uid}",
        "doctor_name": current_user.get("full_name", "Dr. S. Reynolds, MD"),
        "clinical_notes": rep_in.notes or "",
        "findings_summary": analysis_data["findings_summary"],
        "generated_by": current_user["email"],
        "generated_by_id": str(current_user["id"])
    }
    
    created_report = firebase_db.create_report(report_dict)
    
    # Audit log in Firestore
    firebase_db.log_audit_event({
        "user_id": current_user["id"],
        "user_email": current_user["email"],
        "action": "REPORT_GENERATED",
        "resource_type": "REPORT",
        "resource_id": str(created_report["id"]),
        "details": {"report_uid": created_report["report_uid"], "patient_id": patient_data["patient_id"]}
    })
    
    return {
        "id": created_report["id"],
        "analysis_id": analysis["id"],
        "patient_id": patient.get("id") if patient else 0,
        "patient_name": patient_data["full_name"],
        "report_uid": created_report["report_uid"],
        "pdf_url": f"/api/reports/download/{created_report['id']}",
        "generated_at": created_report.get("created_at"),
        "notes": created_report.get("clinical_notes"),
        "disclaimer": "AI assistance only — results should be reviewed by a qualified eye-care professional."
    }

@router.get("/download/{report_id}")
def download_pdf_report(
    report_id: str,
    download: bool = False
):
    report = firebase_db.get_report(report_id)
    if not report or not Path(report.get("pdf_path", "")).exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report PDF file not found."
        )
    disposition = "attachment" if download else "inline"
    return FileResponse(
        path=report["pdf_path"],
        media_type="application/pdf",
        content_disposition_type=disposition,
        filename=f"RetinaSegAI_Report_{report.get('report_uid')}.pdf"
    )

@router.get("", response_model=List[Dict[str, Any]])
def list_reports(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    reports = firebase_db.get_reports_by_user(current_user["email"])
    return [
        {
            "id": r["id"],
            "analysis_id": r.get("analysis_id"),
            "patient_id": r.get("patient_id"),
            "patient_name": r.get("patient_name", "Patient"),
            "patient_mrn": r.get("patient_id", "N/A"),
            "report_uid": r.get("report_uid"),
            "pdf_url": f"/api/reports/download/{r['id']}",
            "generated_at": r.get("created_at", "")[:16].replace("T", " "),
            "notes": r.get("clinical_notes")
        }
        for r in reports
    ]
