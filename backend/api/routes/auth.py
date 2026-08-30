from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from backend.schemas.api_schemas import (
    UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse
)
from backend.services.auth_service import (
    verify_password, get_password_hash, create_access_token, get_current_user
)
from backend.services.firebase_db_service import firebase_db

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse)
def register(user_in: UserRegisterRequest):
    email_clean = user_in.email.strip().lower()
    existing_user = firebase_db.get_user_by_email(email_clean)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email address already exists. Please sign in."
        )
    
    role = "OPHTHALMOLOGIST"
    if user_in.role and user_in.role.upper() == "ADMIN":
        role = "ADMIN"
    elif user_in.role and user_in.role.upper() == "TECHNICIAN":
        role = "TECHNICIAN"
        
    user_data = {
        "email": email_clean,
        "full_name": user_in.full_name.strip(),
        "password_hash": get_password_hash(user_in.password),
        "role": role,
        "specialty": user_in.specialty or "Medical Retina Specialist",
        "license_number": user_in.license_number,
        "is_active": True
    }
    
    created_user = firebase_db.create_user(user_data)
    
    # Audit log in Firestore
    firebase_db.log_audit_event({
        "user_id": created_user["id"],
        "user_email": created_user["email"],
        "action": "USER_REGISTERED",
        "resource_type": "USER",
        "resource_id": str(created_user["id"]),
        "details": {"email": created_user["email"], "role": created_user["role"]}
    })
    
    access_token = create_access_token(data={
        "sub": created_user["email"],
        "role": created_user["role"],
        "id": created_user["id"]
    })
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": created_user
    }

@router.post("/login", response_model=TokenResponse)
def login(login_in: UserLoginRequest):
    email_clean = login_in.email.strip().lower()
    user = firebase_db.get_user_by_email(email_clean)
    if not user or not verify_password(login_in.password, user.get("password_hash", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )
    
    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive. Please contact administration."
        )
        
    firebase_db.update_user(user["id"], {"last_login": datetime.utcnow().isoformat() + "Z"})
    
    access_token = create_access_token(data={
        "sub": user["email"],
        "role": user["role"],
        "id": user["id"]
    })
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/logout")
def logout(current_user: dict = Depends(get_current_user)):
    return {"message": "Successfully logged out of RetinaSeg AI platform."}

@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    return current_user
