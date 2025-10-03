"""
Authentication Routes
Handles user registration and login
"""

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


# Request Models
class RegisterEmailPassword(BaseModel):
    email: EmailStr
    password: str
    name: str


class LoginEmailPassword(BaseModel):
    email: EmailStr
    password: str


class LoginGoogleOAuth(BaseModel):
    google_id_token: str


# Dependency to get current user from token
async def get_current_user(authorization: Optional[str] = Header(None)):
    """
    Dependency to extract and verify user from Authorization header
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(status_code=401, detail="Invalid authentication scheme")
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    
    # Verify token and get user
    user = auth_service.get_current_user_from_token(token)
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    return user


@router.post("/register", summary="Register with Email/Password")
async def register_email_password(data: RegisterEmailPassword):
    """
    Register a new user with email and password.
    
    - **email**: User's email address
    - **password**: User's password (will be hashed)
    - **name**: User's display name
    
    Returns access token for immediate login.
    """
    if len(data.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    
    result = auth_service.create_user_email_password(
        email=data.email,
        password=data.password,
        name=data.name
    )
    
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    
    return {
        "message": "User registered successfully",
        "user": {
            "user_id": result["user_id"],
            "email": result["email"],
            "name": result["name"]
        },
        "access_token": result["access_token"],
        "token_type": result["token_type"]
    }


@router.post("/login", summary="Login with Email/Password")
async def login_email_password(data: LoginEmailPassword):
    """
    Login with email and password.
    
    - **email**: User's email address
    - **password**: User's password
    
    Returns access token.
    """
    result = auth_service.login_user_email_password(
        email=data.email,
        password=data.password
    )
    
    if "error" in result:
        raise HTTPException(status_code=401, detail=result["error"])
    
    return {
        "message": "Login successful",
        "user": {
            "user_id": result["user_id"],
            "email": result["email"],
            "name": result["name"]
        },
        "access_token": result["access_token"],
        "token_type": result["token_type"]
    }


@router.post("/login/google", summary="Login with Google OAuth")
async def login_google_oauth(data: LoginGoogleOAuth):
    """
    Login or register with Google OAuth.
    
    - **google_id_token**: ID token from Firebase Auth Google sign-in
    
    Returns access token.
    """
    result = auth_service.login_user_google_oauth(data.google_id_token)
    
    if "error" in result:
        raise HTTPException(status_code=401, detail=result["error"])
    
    return {
        "message": "Login successful",
        "user": {
            "user_id": result["user_id"],
            "email": result["email"],
            "name": result["name"]
        },
        "access_token": result["access_token"],
        "token_type": result["token_type"]
    }


@router.get("/me", summary="Get Current User")
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """
    Get information about the currently authenticated user.
    
    Requires: Authorization header with Bearer token
    """
    return {
        "user": current_user
    }
