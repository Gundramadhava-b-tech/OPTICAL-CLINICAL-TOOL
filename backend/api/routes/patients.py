from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from backend.schemas.api_schemas import (
    PatientCreateRequest, PatientUpdateRequest, PatientResponse
)
from backend.services.auth_service import get_current_user
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/patients", tags=["Patient Management"])

@router.post("", response_model=PatientResponse)
def create_patient(
    patient_in: PatientCreateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    pid = patient_in.patient_id or f"PAT-{int(datetime.utcnow().timestamp() * 1000) % 100000}"
    
    # Check if patient exists for this user in Firestore
    existing = firebase_db.get_patient(pid)
    if existing and (str(existing.get("created_by", "")).lower() == current_user["email"].lower() or str(existing.get("created_by_id", "")) == str(current_user["id"])):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Patient with ID '{pid}' is already registered."
        )
        
    patient_data = {
        "patient_id": pid,
        "full_name": patient_in.full_name,
        "age": patient_in.age,
        "gender": patient_in.gender,
        "contact": patient_in.contact,
        "email": patient_in.email,
        "medical_history": patient_in.medical_history,
        "eye_condition": patient_in.eye_condition,
        "created_by": current_user["email"],
        "created_by_id": str(current_user["id"])
    }
    
    created = firebase_db.create_patient(patient_data)
    
    # Audit log in Firestore
    firebase_db.log_audit_event({
        "user_id": current_user["id"],
        "user_email": current_user["email"],
        "action": "PATIENT_CREATED",
        "resource_type": "PATIENT",
        "resource_id": str(created["id"]),
        "details": {"patient_id": created["patient_id"], "name": created["full_name"]}
    })
    
    res = PatientResponse.model_validate(created)
    res.scans_count = 0
    return res

@router.get("", response_model=List[PatientResponse])
def list_patients(
    search: Optional[str] = Query(None, description="Search by name, ID, or eye condition"),
    gender: Optional[str] = Query(None, description="Filter by gender"),
    skip: int = 0,
    limit: int = 50,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    user_patients = firebase_db.get_patients_by_user(
        user_identifier=current_user["email"],
        search=search,
        gender=gender,
        skip=skip,
        limit=limit
    )
    
    results = []
    for p in user_patients:
        p_res = PatientResponse.model_validate(p)
        # Count scans from firestore
        all_scans = firebase_db.get_scans_by_user(current_user["email"])
        p_scans = [s for s in all_scans if str(s.get("patient_id")) == str(p.get("id")) or str(s.get("patient_id")) == str(p.get("patient_id"))]
        p_res.scans_count = len(p_scans)
        results.append(p_res)
        
    return results

@router.get("/{patient_id}", response_model=PatientResponse)
def get_patient(
    patient_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    patient = firebase_db.get_patient(patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
    p_user = str(patient.get("created_by", "")).lower()
    p_uid = str(patient.get("created_by_id", ""))
    if p_user != current_user["email"].lower() and p_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
        
    p_res = PatientResponse.model_validate(patient)
    all_scans = firebase_db.get_scans_by_user(current_user["email"])
    p_scans = [s for s in all_scans if str(s.get("patient_id")) == str(patient.get("id")) or str(s.get("patient_id")) == str(patient.get("patient_id"))]
    p_res.scans_count = len(p_scans)
    return p_res

@router.put("/{patient_id}", response_model=PatientResponse)
def update_patient(
    patient_id: str,
    update_in: PatientUpdateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    patient = firebase_db.get_patient(patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
    p_user = str(patient.get("created_by", "")).lower()
    p_uid = str(patient.get("created_by_id", ""))
    if p_user != current_user["email"].lower() and p_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
        
    updates = {k: v for k, v in update_in.dict(exclude_unset=True).items() if v is not None}
    updated = firebase_db.update_patient(patient["id"], updates)
    
    p_res = PatientResponse.model_validate(updated)
    return p_res

@router.delete("/{patient_id}")
def delete_patient(
    patient_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    patient = firebase_db.get_patient(patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
    p_user = str(patient.get("created_by", "")).lower()
    p_uid = str(patient.get("created_by_id", ""))
    if p_user != current_user["email"].lower() and p_uid != str(current_user["id"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient record not found."
        )
        
    firebase_db.delete_patient(patient["id"])
    return {"message": f"Patient {patient.get('patient_id')} deleted successfully from Firestore."}
