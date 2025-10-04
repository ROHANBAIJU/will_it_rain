"""
Firebase Authentication Service
Handles user registration, login, and token management
Supports both Email/Password and Google OAuth
"""

import os
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.services import firestore_service

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "default-secret-key-change-in-production")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))  # 7 days default


def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create a JWT access token
    
    Args:
        data: Payload to encode in the token
        expires_delta: Token expiration time
    
    Returns:
        Encoded JWT token
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Decode and verify a JWT token
    
    Args:
        token: JWT token to decode
    
    Returns:
        Decoded token payload or None if invalid
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


def create_user_email_password(email: str, password: str, name: str) -> Dict[str, Any]:
    """
    Create a new user with email/password authentication
    
    Args:
        email: User's email
        password: User's password (will be hashed)
        name: User's display name
    
    Returns:
        User data with access token or error
    """
    db = firestore_service.get_db()
    if db is None:
        return {"error": "Database connection failed"}
    
    try:
        # Check if user already exists
        users_ref = db.collection('users')
        existing_user = users_ref.where('email', '==', email).limit(1).get()
        
        if len(list(existing_user)) > 0:
            return {"error": "User with this email already exists"}
        
        # Hash password
        hashed_password = hash_password(password)
        
        # Create user document
        user_data = {
            "email": email,
            "name": name,
            "password_hash": hashed_password,
            "auth_provider": "email",
            "created_at": datetime.utcnow().isoformat(),
            "last_login": datetime.utcnow().isoformat(),
            "is_active": True
        }
        
        # Add to Firestore
        user_ref = users_ref.document()
        user_ref.set(user_data)
        
        # Generate access token
        access_token = create_access_token(
            data={"sub": user_ref.id, "email": email, "name": name}
        )
        
        print(f"✅ User registered: {email} (ID: {user_ref.id})")
        
        return {
            "user_id": user_ref.id,
            "email": email,
            "name": name,
            "access_token": access_token,
            "token_type": "bearer"
        }
        
    except Exception as e:
        print(f"❌ User registration failed: {e}")
        return {"error": str(e)}


def login_user_email_password(email: str, password: str) -> Dict[str, Any]:
    """
    Login user with email/password
    
    Args:
        email: User's email
        password: User's password
    
    Returns:
        User data with access token or error
    """
    db = firestore_service.get_db()
    if db is None:
        return {"error": "Database connection failed"}
    
    try:
        # Find user by email
        users_ref = db.collection('users')
        user_query = users_ref.where('email', '==', email).limit(1).get()
        
        users_list = list(user_query)
        if len(users_list) == 0:
            return {"error": "Invalid email or password"}
        
        user_doc = users_list[0]
        user_data = user_doc.to_dict()
        
        # Verify password
        if not verify_password(password, user_data.get('password_hash', '')):
            return {"error": "Invalid email or password"}
        
        # Update last login
        user_doc.reference.update({"last_login": datetime.utcnow().isoformat()})
        
        # Generate access token
        access_token = create_access_token(
            data={"sub": user_doc.id, "email": email, "name": user_data.get('name', '')}
        )
        
        print(f"✅ User logged in: {email}")
        
        return {
            "user_id": user_doc.id,
            "email": email,
            "name": user_data.get('name', ''),
            "access_token": access_token,
            "token_type": "bearer"
        }
        
    except Exception as e:
        print(f"❌ Login failed: {e}")
        return {"error": str(e)}


def login_user_google_oauth(google_id_token: str) -> Dict[str, Any]:
    """
    Login or register user with Google OAuth
    
    Args:
        google_id_token: Google ID token from Firebase Auth
    
    Returns:
        User data with access token or error
    """
    db = firestore_service.get_db()
    if db is None:
        return {"error": "Database connection failed"}
    
    try:
        # Verify Google ID token using Firebase Admin
        from firebase_admin import auth as firebase_auth
        
        decoded_token = firebase_auth.verify_id_token(google_id_token)
        email = decoded_token.get('email')
        name = decoded_token.get('name', email.split('@')[0])
        uid = decoded_token.get('uid')
        
        # Check if user exists
        users_ref = db.collection('users')
        existing_user = users_ref.where('email', '==', email).limit(1).get()
        
        users_list = list(existing_user)
        
        if len(users_list) > 0:
            # Existing user - login
            user_doc = users_list[0]
            user_doc.reference.update({"last_login": datetime.utcnow().isoformat()})
            
            access_token = create_access_token(
                data={"sub": user_doc.id, "email": email, "name": name}
            )
            
            print(f"✅ User logged in via Google: {email}")
            
            return {
                "user_id": user_doc.id,
                "email": email,
                "name": name,
                "access_token": access_token,
                "token_type": "bearer"
            }
        else:
            # New user - register
            user_data = {
                "email": email,
                "name": name,
                "auth_provider": "google",
                "google_uid": uid,
                "created_at": datetime.utcnow().isoformat(),
                "last_login": datetime.utcnow().isoformat(),
                "is_active": True
            }
            
            user_ref = users_ref.document()
            user_ref.set(user_data)
            
            access_token = create_access_token(
                data={"sub": user_ref.id, "email": email, "name": name}
            )
            
            print(f"✅ User registered via Google: {email} (ID: {user_ref.id})")
            
            return {
                "user_id": user_ref.id,
                "email": email,
                "name": name,
                "access_token": access_token,
                "token_type": "bearer"
            }
        
    except Exception as e:
        print(f"❌ Google OAuth login failed: {e}")
        return {"error": str(e)}


def get_current_user_from_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Get user information from JWT token
    
    Args:
        token: JWT access token
    
    Returns:
        User data or None if invalid
    """
    payload = decode_access_token(token)
    if payload is None:
        return None
    
    user_id = payload.get("sub")
    email = payload.get("email")
    name = payload.get("name")
    
    if user_id is None:
        return None
    
    return {
        "user_id": user_id,
        "email": email,
        "name": name
    }


def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """
    Get user by email address
    
    Args:
        email: User's email
    
    Returns:
        User data or None if not found
    """
    db = firestore_service.get_db()
    if db is None:
        return None
    
    try:
        users_ref = db.collection('users')
        user_query = users_ref.where('email', '==', email).limit(1).get()
        
        users_list = list(user_query)
        if len(users_list) == 0:
            return None
        
        user_doc = users_list[0]
        user_data = user_doc.to_dict()
        user_data['user_id'] = user_doc.id
        
        return user_data
    except Exception as e:
        print(f"❌ Get user by email failed: {e}")
        return None


def generate_access_token(user_id: str, email: str) -> Dict[str, str]:
    """
    Generate a new access token for a user
    
    Args:
        user_id: User's ID
        email: User's email
    
    Returns:
        Access token data
    """
    # Get user name from database
    db = firestore_service.get_db()
    name = ""
    
    if db:
        try:
            user_ref = db.collection('users').document(user_id)
            user_doc = user_ref.get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                name = user_data.get('name', '')
        except Exception:
            pass
    
    access_token = create_access_token(
        data={"sub": user_id, "email": email, "name": name}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
