# 🔧 Quick Fix Guide - Firebase Setup Issues

## ✅ Issues Fixed

1. **Multiple Firebase initialization** - Fixed by checking if app already exists
2. **Environment variables not loading** - Added `load_dotenv()` to main.py
3. **Extra space in .env file** - Removed space after `=`

---

## 🔥 Setting Up Firebase Credentials

You have **two options**:

### **Option 1: Run WITHOUT Firebase (Quick Test)**

If you just want to test the API without caching:

1. **Comment out or remove the FIREBASE_CREDENTIALS line** in `.env`:
   ```
   # FIREBASE_CREDENTIALS=D:\will_it_rain\BACKEND\firebase-credentials.json
   ```

2. **Restart the server**:
   ```bash
   cd BACKEND
   python -m uvicorn app.main:app --reload
   ```

3. The system will run in **direct API mode** (no caching, but fully functional)

---

### **Option 2: Set Up Firebase (Full Features)**

Follow these steps to enable caching:

#### **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter name: `will-it-rain`
4. Click **"Continue"**
5. Disable Google Analytics (optional)
6. Click **"Create project"**

#### **Step 2: Enable Firestore**

1. In left menu, click **"Firestore Database"**
2. Click **"Create database"**
3. Choose **"Start in production mode"**
4. Select location: **`asia-south1`** (for India) or closest to you
5. Click **"Enable"**

#### **Step 3: Get Service Account Credentials**

1. Click the **gear icon** ⚙️ next to "Project Overview"
2. Select **"Project settings"**
3. Go to **"Service accounts"** tab
4. Click **"Generate new private key"**
5. Click **"Generate key"** to confirm
6. A JSON file will download - **KEEP IT SECURE!**

#### **Step 4: Save Credentials**

1. **Rename the downloaded file** to `firebase-credentials.json`

2. **Move it** to your BACKEND folder:
   ```
   D:\will_it_rain\BACKEND\firebase-credentials.json
   ```

3. **Verify the .env file** has the correct path:
   ```
   FIREBASE_CREDENTIALS=D:\will_it_rain\BACKEND\firebase-credentials.json
   ```
   ⚠️ **No spaces around the `=` sign!**

#### **Step 5: Update Firestore Rules**

1. In Firebase Console, go to **Firestore Database**
2. Click the **"Rules"** tab
3. Replace with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /weather_predictions/{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
4. Click **"Publish"**

#### **Step 6: Test Firebase Connection**

Create a test file `BACKEND/test_firebase.py`:

```python
import os
from dotenv import load_dotenv
from app.services import firestore_service

# Load environment variables
load_dotenv()

print("Testing Firebase connection...")
print(f"Credentials path: {os.getenv('FIREBASE_CREDENTIALS')}")

# Try to initialize
db = firestore_service.initialize_firebase()

if db:
    print("✅ Firebase connected successfully!")
    
    # Test write
    doc_ref = db.collection('test').document('test_doc')
    doc_ref.set({'message': 'Hello from Will It Rain!', 'test': True})
    print("✅ Test write successful!")
    
    # Test read
    doc = doc_ref.get()
    if doc.exists:
        print(f"✅ Test read successful! Data: {doc.to_dict()}")
    
    # Clean up
    doc_ref.delete()
    print("✅ Test cleanup complete!")
else:
    print("❌ Firebase connection failed")
```

Run the test:
```bash
cd BACKEND
python test_firebase.py
```

#### **Step 7: Restart Your Server**

```bash
cd BACKEND
python -m uvicorn app.main:app --reload
```

You should see:
```
✅ Firebase initialized successfully with credentials file
```

---

## 🧪 Verify It's Working

### **Test 1: Make a request**
```bash
curl "http://localhost:8000/predict?lat=13.009&lon=77.614&date=2028-10-05"
```

**First time** (Cache MISS):
```json
{
  "cache_status": "miss",
  ...
}
```

### **Test 2: Same request again**
```bash
curl "http://localhost:8000/predict?lat=13.009&lon=77.614&date=2028-10-05"
```

**Second time** (Cache HIT):
```json
{
  "cache_status": "hit",
  ...
}
```

If you see `"cache_status": "hit"`, **Firebase caching is working!** 🎉

---

## ❓ Troubleshooting

### **Issue: "Your default credentials were not found"**
**Solution**: 
- Make sure `firebase-credentials.json` exists in `BACKEND/` folder
- Check `.env` has the correct path (no extra spaces)
- Restart the server after changes

### **Issue: "Firebase app already exists"**
**Solution**: 
- ✅ Already fixed in the code update
- Just restart the server

### **Issue: "Permission denied" in Firestore**
**Solution**: 
- Update Firestore security rules (see Step 5 above)

### **Issue: Still not working**
**Checklist**:
- [ ] `firebase-credentials.json` exists in `BACKEND/` folder
- [ ] `.env` file has `FIREBASE_CREDENTIALS=D:\will_it_rain\BACKEND\firebase-credentials.json`
- [ ] No extra spaces in `.env` file
- [ ] Server restarted after changes
- [ ] Firestore security rules published

---

## 🚀 Current Status

**System is working in direct API mode** ✅
- All predictions work
- No caching (but that's okay for testing)
- To enable caching, follow Option 2 above

---

**Need help? Let me know which option you want to use!** 🎯
