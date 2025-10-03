# 🔐 PHASE 4.5: FIREBASE AUTHENTICATION - COMPLETE IMPLEMENTATION

## 🎯 Overview

Added **Firebase Authentication** with support for:
- ✅ **Email/Password Registration & Login**
- ✅ **Google OAuth Login**
- ✅ **JWT Token-based Authentication**
- ✅ **Secured `/predict` Endpoint**
- ✅ **Universal Weather Cache** (shared by all users)
- ✅ **Individual User Profiles** in `users` collection

---

## 📁 Files Created/Modified

### **NEW**: `app/services/auth_service.py`
**Purpose**: Core authentication logic

**Functions**:
- `hash_password()` - Bcrypt password hashing
- `verify_password()` - Password verification
- `create_access_token()` - Generate JWT tokens
- `decode_access_token()` - Verify JWT tokens
- `create_user_email_password()` - Register new user
- `login_user_email_password()` - Login with email/password
- `login_user_google_oauth()` - Login/register with Google
- `get_current_user_from_token()` - Extract user from JWT

---

### **NEW**: `app/api/auth_routes.py`
**Purpose**: Authentication API endpoints

**Endpoints**:
- `POST /auth/register` - Register with email/password
- `POST /auth/login` - Login with email/password
- `POST /auth/login/google` - Login with Google OAuth
- `GET /auth/me` - Get current user info

---

### **UPDATED**: `app/api/routes.py`
**Changes**:
- Added `get_current_user` dependency
- `/predict` endpoint now requires authentication
- Logs which user makes each prediction request
- Weather predictions cache remains universal (not per-user)

---

### **UPDATED**: `app/main.py`
**Changes**:
- Added CORS middleware for Flutter frontend
- Included `auth_routes` router
- Updated API description and version

---

### **UPDATED**: `requirements.txt`
**Added**:
```
python-jose[cryptography]  # JWT token handling
passlib[bcrypt]            # Password hashing
python-multipart           # Form data parsing
```

---

### **UPDATED**: `.env`
**Added**:
```env
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production-willitrain2025
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7 days
```

---

## 🗄️ Firestore Database Structure

### **Collection: `users`** (Individual User Profiles)
```json
{
  "user_id": "auto-generated-id",
  "email": "user@example.com",
  "name": "John Doe",
  "password_hash": "$2b$12$...",  // Only for email/password users
  "auth_provider": "email",        // "email" or "google"
  "google_uid": "...",             // Only for Google OAuth users
  "created_at": "2025-10-03T05:30:00Z",
  "last_login": "2025-10-03T05:30:00Z",
  "is_active": true
}
```

### **Collection: `weather_predictions`** (Universal Cache)
```json
{
  "cache_key": "13.0_77.61_12-15",
  "location": { "lat": 13.0, "lon": 77.61 },
  "statistics": { ... },
  "ai_insight": { ... },
  "confidence_score": 0.98,
  "metadata": { ... }
}
```

**Note**: Weather predictions are **NOT stored per user** - they're universal and shared by all authenticated users for efficiency.

---

## 🔐 Authentication Flow

### **1. Email/Password Registration**

**Request:**
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user": {
    "user_id": "abc123xyz",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

---

### **2. Email/Password Login**

**Request:**
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "user_id": "abc123xyz",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

---

### **3. Google OAuth Login**

**Flutter Frontend Flow:**
```dart
// 1. User clicks "Sign in with Google"
// 2. Firebase Auth handles Google sign-in
// 3. Get ID token from Firebase
final user = await FirebaseAuth.instance.signInWithGoogle();
final idToken = await user.getIdToken();

// 4. Send to backend
final response = await http.post(
  'http://localhost:8000/auth/login/google',
  body: json.encode({'google_id_token': idToken}),
);
```

**Request:**
```http
POST /auth/login/google
Content-Type: application/json

{
  "google_id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "user_id": "xyz789abc",
    "email": "user@gmail.com",
    "name": "Jane Smith"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

---

### **4. Get Current User Info**

**Request:**
```http
GET /auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "user": {
    "user_id": "abc123xyz",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

---

### **5. Make Authenticated Prediction**

**Request:**
```http
GET /predict?lat=13.00&lon=77.61&date=2025-12-15
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "query": {...},
  "statistics": {...},
  "ai_insight": {
    "reasoning": "Based on 39 years of data...",
    "generated_by": "gemini-2.0-flash"
  },
  "confidence_score": 0.98,
  "cache_status": "hit"
}
```

**Backend Log:**
```
📊 Prediction request from user: user@example.com (John Doe)
🎯 Cache HIT for 13.0_77.61_12-15
✅ Cache hit! Data is current. No update needed.
```

---

## 🔒 Security Features

### **1. Password Security**
- ✅ **Bcrypt hashing** with automatic salt
- ✅ **Minimum 6 characters** enforced
- ✅ **Never stored in plain text**
- ✅ **Secure verification** with timing attack protection

### **2. JWT Tokens**
- ✅ **HS256 algorithm** (HMAC with SHA-256)
- ✅ **7-day expiration** (configurable)
- ✅ **Signed with secret key** (not reversible)
- ✅ **Includes user ID, email, name**

### **3. Google OAuth**
- ✅ **Verified via Firebase Admin SDK**
- ✅ **Token validation** before accepting
- ✅ **Automatic user creation** on first login
- ✅ **Secure UID tracking**

### **4. API Protection**
- ✅ **Authorization header required** for `/predict`
- ✅ **Token validation** on every request
- ✅ **401 Unauthorized** for invalid/missing tokens
- ✅ **Public health check** endpoint remains open

---

## 🧪 Testing Authentication

### **Test 1: Register New User**
```powershell
$body = @{
    email = "test@example.com"
    password = "password123"
    name = "Test User"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8000/auth/register" -Method Post -Body $body -ContentType "application/json"
$response | ConvertTo-Json
```

**Expected Output:**
```json
{
  "message": "User registered successfully",
  "user": {...},
  "access_token": "eyJ..."
}
```

---

### **Test 2: Login with Email/Password**
```powershell
$body = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8000/auth/login" -Method Post -Body $body -ContentType "application/json"
$token = $response.access_token
```

---

### **Test 3: Get Current User**
```powershell
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:8000/auth/me" -Headers $headers | ConvertTo-Json
```

---

### **Test 4: Make Authenticated Prediction**
```powershell
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:8000/predict?lat=13.00&lon=77.61&date=2025-12-15" -Headers $headers | ConvertTo-Json
```

---

### **Test 5: Try Unauthenticated Request (Should Fail)**
```powershell
# No Authorization header - should get 401
Invoke-RestMethod -Uri "http://localhost:8000/predict?lat=13.00&lon=77.61&date=2025-12-15"
```

**Expected Error:**
```json
{
  "detail": "Authorization header missing"
}
```

---

## 📱 Flutter Frontend Integration

### **Setup Firebase Auth in Flutter:**

1. **Add dependencies to `pubspec.yaml`:**
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  google_sign_in: ^6.1.6
  http: ^1.1.0
```

2. **Initialize Firebase:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

3. **Email/Password Registration:**
```dart
Future<String> registerWithEmail(String email, String password, String name) async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
      'name': name,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['access_token'];  // Store this securely!
  } else {
    throw Exception('Registration failed');
  }
}
```

4. **Email/Password Login:**
```dart
Future<String> loginWithEmail(String email, String password) async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'password': password,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['access_token'];
  } else {
    throw Exception('Login failed');
  }
}
```

5. **Google Sign-In:**
```dart
Future<String> signInWithGoogle() async {
  // Step 1: Google Sign-In
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
  
  // Step 2: Get Firebase credential
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );
  
  // Step 3: Sign in to Firebase
  final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
  
  // Step 4: Get ID token
  final idToken = await userCredential.user?.getIdToken();
  
  // Step 5: Send to backend
  final response = await http.post(
    Uri.parse('http://localhost:8000/auth/login/google'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'google_id_token': idToken}),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['access_token'];
  } else {
    throw Exception('Google sign-in failed');
  }
}
```

6. **Make Authenticated API Calls:**
```dart
Future<Map<String, dynamic>> getWeatherPrediction(
  double lat, 
  double lon, 
  String date,
  String accessToken
) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/predict?lat=$lat&lon=$lon&date=$date'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized - please login again');
  } else {
    throw Exception('API call failed');
  }
}
```

---

## 🚀 Deployment Considerations

### **Environment Variables (Production):**
```env
# Generate a strong secret key!
JWT_SECRET_KEY=$(openssl rand -hex 32)
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=10080

FIREBASE_CREDENTIALS=/app/firebase-credentials.json
GEMINI_API_KEY=your-production-key
```

### **CORS Configuration (Production):**
Update `main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://your-flutter-web-app.web.app",
        "https://your-custom-domain.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## ✅ Phase 4.5 Complete Checklist

- ✅ JWT token authentication implemented
- ✅ Email/password registration endpoint
- ✅ Email/password login endpoint
- ✅ Google OAuth login endpoint
- ✅ Current user info endpoint
- ✅ Secured `/predict` endpoint
- ✅ Password hashing with bcrypt
- ✅ Token generation and verification
- ✅ CORS middleware for Flutter
- ✅ Individual `users` collection in Firestore
- ✅ Universal `weather_predictions` cache
- ✅ User logging on prediction requests
- ✅ Comprehensive documentation

---

## 🎉 **PHASE 4.5 COMPLETE!**

Your API now has:
- ✅ **Phase 1**: FastAPI server
- ✅ **Phase 2**: NASA POWER data integration
- ✅ **Phase 3**: Smart caching with Firestore
- ✅ **Phase 4**: AI reasoning with Gemini
- ✅ **Phase 4.5**: **Firebase Authentication** 🔐

**Next**: Rebuild Docker container and test! 🚀
