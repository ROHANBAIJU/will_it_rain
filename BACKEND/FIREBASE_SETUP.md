# Firebase Setup Guide

## 🔥 Setting Up Firebase for Will It Rain

Follow these steps to set up Firebase Firestore for caching:

---

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `will-it-rain` (or your preferred name)
4. Disable Google Analytics (optional for this project)
5. Click **"Create project"**

---

## Step 2: Enable Firestore Database

1. In your Firebase project, click **"Firestore Database"** in the left menu
2. Click **"Create database"**
3. Choose **"Start in production mode"** (we'll add rules later)
4. Select a Firestore location (choose closest to your users):
   - `us-central` for North America
   - `europe-west` for Europe
   - `asia-south1` for India
5. Click **"Enable"**

---

## Step 3: Create Service Account

1. Click the **gear icon** (⚙️) next to "Project Overview"
2. Select **"Project settings"**
3. Go to the **"Service accounts"** tab
4. Click **"Generate new private key"**
5. Click **"Generate key"** in the confirmation dialog
6. A JSON file will be downloaded - **KEEP THIS SECURE!**

---

## Step 4: Configure Your Backend

1. **Rename the downloaded file** to something simple like `firebase-credentials.json`

2. **Move it to a secure location**:
   ```
   D:\will_it_rain\BACKEND\firebase-credentials.json
   ```

3. **Create a `.env` file** in the BACKEND folder:
   ```bash
   cd D:\will_it_rain\BACKEND
   copy .env.example .env
   ```

4. **Edit `.env`** and add the path:
   ```
   FIREBASE_CREDENTIALS=D:\will_it_rain\BACKEND\firebase-credentials.json
   ```

---

## Step 5: Update Firestore Security Rules

1. In Firebase Console, go to **Firestore Database**
2. Click the **"Rules"** tab
3. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Weather predictions collection
    match /weather_predictions/{document=**} {
      // Allow read/write from backend only
      // In production, add proper authentication
      allow read, write: if true;
    }
  }
}
```

4. Click **"Publish"**

---

## Step 6: Install Firebase Admin SDK

```bash
cd D:\will_it_rain\BACKEND
pip install firebase-admin
```

---

## Step 7: Test the Connection

Create a test script `test_firebase.py`:

```python
import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

# Load environment variables
load_dotenv()

# Initialize Firebase
cred_path = os.getenv('FIREBASE_CREDENTIALS')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

# Test write
doc_ref = db.collection('test').document('test_doc')
doc_ref.set({'message': 'Hello from Will It Rain!'})

# Test read
doc = doc_ref.get()
if doc.exists:
    print(f"✅ Firebase connection successful!")
    print(f"Test data: {doc.to_dict()}")
else:
    print("❌ Firebase connection failed")

# Clean up test data
doc_ref.delete()
print("✅ Test completed and cleaned up")
```

Run the test:
```bash
python test_firebase.py
```

---

## Step 8: Update .gitignore

Make sure these are in your `.gitignore`:

```
# Firebase credentials
firebase-credentials.json
*-firebase-adminsdk-*.json

# Environment variables
.env
.env.local
```

---

## ⚠️ Security Notes

1. **NEVER commit** `firebase-credentials.json` to Git
2. **NEVER commit** `.env` file to Git
3. Keep your service account key **secure**
4. For production, implement proper **authentication rules**
5. Consider using **Firebase security rules** to restrict access

---

## 🚀 Production Deployment (Render/Heroku)

When deploying to production:

1. **Don't upload the JSON file directly**
2. Instead, use **environment variables**:
   - Copy the entire contents of `firebase-credentials.json`
   - In Render/Heroku, create an environment variable `FIREBASE_CREDENTIALS_JSON`
   - Paste the JSON content as the value

3. Update `firestore_service.py` to handle both:
   ```python
   # Check for JSON string in environment variable
   firebase_creds = os.getenv('FIREBASE_CREDENTIALS_JSON')
   if firebase_creds:
       cred_dict = json.loads(firebase_creds)
       cred = credentials.Certificate(cred_dict)
   else:
       # Fall back to file path
       cred = credentials.Certificate(os.getenv('FIREBASE_CREDENTIALS'))
   ```

---

## 📊 Monitoring

To monitor your Firestore usage:

1. Go to Firebase Console
2. Click **"Firestore Database"**
3. Click **"Usage"** tab
4. Monitor:
   - Document reads
   - Document writes
   - Storage used

**Free tier limits:**
- 50,000 reads/day
- 20,000 writes/day
- 1 GB storage

---

## 🎯 Collection Structure

Your Firestore will have this structure:

```
weather_predictions (collection)
  ├── 12.97_77.59_10-29 (document)
  │   ├── cache_key: "12.97_77.59_10-29"
  │   ├── location: {lat: 12.97, lon: 77.59}
  │   ├── target_date: "10-29"
  │   ├── statistics: {...}
  │   ├── metadata: {...}
  │   └── confidence_score: 0.87
  │
  ├── 19.08_72.88_07-15 (document)
  └── ...
```

---

## ✅ Verification Checklist

- [ ] Firebase project created
- [ ] Firestore database enabled
- [ ] Service account JSON downloaded
- [ ] `.env` file configured
- [ ] `firebase-admin` installed
- [ ] Test connection successful
- [ ] `.gitignore` updated
- [ ] Security rules published

---

**You're all set! Your caching system is ready to go!** 🎉
