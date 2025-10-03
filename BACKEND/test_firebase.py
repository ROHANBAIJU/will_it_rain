import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

print("=" * 50)
print("🔥 FIREBASE CONNECTION TEST")
print("=" * 50)

# Check if credentials file is set
cred_path = os.getenv('FIREBASE_CREDENTIALS')
print(f"\n1. Checking environment variable...")
print(f"   FIREBASE_CREDENTIALS = {cred_path}")

if not cred_path:
    print(f"   ❌ FIREBASE_CREDENTIALS not set in .env file")
    print(f"\n   Please set it in .env:")
    print(f"   FIREBASE_CREDENTIALS=D:\\will_it_rain\\BACKEND\\firebase-credentials.json")
    sys.exit(1)

if not os.path.exists(cred_path):
    print(f"   ❌ Credentials file NOT FOUND at: {cred_path}")
    print(f"\n   Please download firebase-credentials.json from Firebase Console")
    print(f"   See FIREBASE_FIX.md for instructions")
    sys.exit(1)

print(f"   ✅ Credentials file exists!")

# Try to initialize Firebase
print(f"\n2. Initializing Firebase...")
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    
    # Check if already initialized
    try:
        firebase_admin.get_app()
        firebase_admin.delete_app(firebase_admin.get_app())
        print(f"   Cleaned up existing Firebase instance")
    except ValueError:
        pass
    
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    print(f"   ✅ Firebase initialized successfully!")
except Exception as e:
    print(f"   ❌ Firebase initialization failed: {e}")
    sys.exit(1)

# Get Firestore client
print(f"\n3. Connecting to Firestore...")
try:
    db = firestore.client()
    print(f"   ✅ Firestore client connected!")
except Exception as e:
    print(f"   ❌ Firestore connection failed: {e}")
    sys.exit(1)

# Test write
print(f"\n4. Testing write operation...")
try:
    doc_ref = db.collection('test').document('test_doc')
    doc_ref.set({
        'message': 'Hello from Will It Rain!',
        'test': True,
        'timestamp': firestore.SERVER_TIMESTAMP
    })
    print(f"   ✅ Write successful!")
except Exception as e:
    print(f"   ❌ Write failed: {e}")
    print(f"\n   Check Firestore security rules!")
    sys.exit(1)

# Test read
print(f"\n5. Testing read operation...")
try:
    doc = doc_ref.get()
    if doc.exists:
        print(f"   ✅ Read successful!")
        print(f"   Data: {doc.to_dict()}")
    else:
        print(f"   ❌ Document not found")
        sys.exit(1)
except Exception as e:
    print(f"   ❌ Read failed: {e}")
    sys.exit(1)

# Clean up test data
print(f"\n6. Cleaning up test data...")
try:
    doc_ref.delete()
    print(f"   ✅ Cleanup complete!")
except Exception as e:
    print(f"   ⚠️ Cleanup warning: {e}")

print(f"\n" + "=" * 50)
print(f"🎉 ALL TESTS PASSED!")
print(f"Firebase is configured correctly!")
print(f"Your caching system will work perfectly!")
print(f"=" * 50)
print(f"\nYou can now start your server:")
print(f"   cd BACKEND")
print(f"   python -m uvicorn app.main:app --reload")