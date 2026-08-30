from typing import Dict, Any
from fastapi import APIRouter, Depends
from backend.schemas.api_schemas import DashboardStatsResponse
from backend.services.auth_service import get_current_user
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/dashboard", tags=["Dashboard Statistics"])

@router.get("/stats", response_model=DashboardStatsResponse)
def get_dashboard_stats(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    stats = firebase_db.get_user_dashboard_stats(current_user["email"])
    return stats
