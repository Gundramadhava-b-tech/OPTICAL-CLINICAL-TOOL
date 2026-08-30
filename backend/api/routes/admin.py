from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from backend.schemas.api_schemas import UserResponse
from backend.services.auth_service import get_current_user, require_roles
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/admin", tags=["Admin & System Management"])

@router.get("/users", response_model=List[UserResponse])
def list_all_users(
    current_user: Dict[str, Any] = Depends(require_roles(["ADMIN", "OPHTHALMOLOGIST"]))
):
    users = firebase_db.get_all_users()
    return users

@router.put("/users/{user_id}/status")
def toggle_user_status(
    user_id: str,
    is_active: bool,
    current_user: Dict[str, Any] = Depends(require_roles(["ADMIN", "OPHTHALMOLOGIST"]))
):
    user = firebase_db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
    firebase_db.update_user(user_id, {"is_active": is_active})
    return {"message": f"User {user.get('email')} status updated to {'active' if is_active else 'inactive'}."}

@router.get("/models")
def list_model_versions(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    return [
        {
            "version_string": "RetinaUNet-v1.4.2-MultiLayer",
            "architecture": "U-Net 4-Depth Residual with Skip Connections",
            "num_classes": 9,
            "is_active": True,
            "created_at": "2026-08-30T00:00:00Z"
        }
    ]

@router.get("/audit-logs")
def list_audit_logs(
    skip: int = 0,
    limit: int = 50,
    current_user: Dict[str, Any] = Depends(require_roles(["ADMIN", "OPHTHALMOLOGIST"]))
):
    logs = firebase_db.list_documents("audit_logs")
    logs.sort(key=lambda x: str(x.get("timestamp", "")), reverse=True)
    return logs[skip : skip + limit]
