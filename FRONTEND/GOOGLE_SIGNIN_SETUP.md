# 🔐 Google Sign-In Setup Guide

## 📋 Prerequisites
- Google Cloud Console account
- Project created in Google Cloud Console

---

## 🚀 Step-by-Step Setup

### **1. Go to Google Cloud Console**
Visit: https://console.cloud.google.com/

### **2. Create/Select Project**
- Create a new project or select existing "AeroNimbus" project
- Note your Project ID

### **3. Enable Google Sign-In API**
1. Navigate to **APIs & Services** → **Library**
2. Search for "Google+ API" or "Google Sign-In API"
3. Click **Enable**

### **4. Create OAuth 2.0 Credentials**

#### **For Web (Chrome/Firefox/Edge)**:
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Web application**
4. Configure:
   - **Name**: `AeroNimbus Web Client`
   - **Authorized JavaScript origins**:
     ```
     http://localhost
     http://localhost:63064
     http://localhost:8080
     ```
   - **Authorized redirect URIs**:
     ```
     http://localhost:63064/auth.html
     http://localhost:8080/auth.html
     ```
5. Click **CREATE**
6. **Copy the Client ID** (looks like: `123456789-abc123def456.apps.googleusercontent.com`)

#### **For Android** (Optional):
1. Create another OAuth client ID
2. Select **Android**
3. Provide:
   - Package name: `com.aeronimbus.app`
   - SHA-1 certificate fingerprint (get from `keytool`)

#### **For iOS** (Optional):
1. Create another OAuth client ID
2. Select **iOS**
3. Provide Bundle ID: `com.aeronimbus.app`

---

## 📝 Configure Your App

### **1. Update `web/index.html`**

Replace the placeholder in `web/index.html`:

```html
<!-- BEFORE -->
<meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com">

<!-- AFTER (with your actual Client ID) -->
<meta name="google-signin-client_id" content="123456789-abc123def456.apps.googleusercontent.com">
```

### **2. For Android (Optional)**

Create `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID</string>
</resources>
```

### **3. For iOS (Optional)**

Update `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 🧪 Testing

### **Local Development**:

1. **Stop the current Flutter app**
2. **Update `web/index.html`** with your Client ID
3. **Restart the app**:
   ```bash
   flutter run -d chrome
   ```
4. Click "Sign in with Google"
5. Google account picker should appear
6. Select account and authenticate

### **Verify Configuration**:

Check browser console for errors:
- ✅ No "clientId not set" errors
- ✅ Google Sign-In popup opens
- ✅ Can select account

---

## 🔧 Troubleshooting

### **Error: "clientId not set"**
**Solution**: Update `web/index.html` with your actual Google Client ID

### **Error: "redirect_uri_mismatch"**
**Solution**: 
1. Go to Google Cloud Console → Credentials
2. Edit your OAuth 2.0 Client ID
3. Add your redirect URI to **Authorized redirect URIs**

### **Error: "origin_mismatch"**
**Solution**:
1. Go to Google Cloud Console → Credentials
2. Edit your OAuth 2.0 Client ID
3. Add your origin to **Authorized JavaScript origins**

### **Google Sign-In popup blocked**
**Solution**: Allow popups for localhost in browser settings

---

## 🌐 Production Deployment

### **For Render.com / Your Domain**:

1. Get your production URL (e.g., `https://aeronimbus.onrender.com`)
2. Update OAuth 2.0 Client ID in Google Cloud Console:
   - **Authorized JavaScript origins**:
     ```
     https://aeronimbus.onrender.com
     ```
   - **Authorized redirect URIs**:
     ```
     https://aeronimbus.onrender.com/auth.html
     ```
3. Update `web/index.html` if needed
4. Deploy!

---

## 📚 Alternative: Use Email Authentication

If you don't want to set up Google Sign-In right now:
- ✅ Email authentication works without any setup
- ✅ Users can create accounts with email + password
- ✅ Fully functional and secure

Just hide or disable the Google Sign-In button in `auth.dart`.

---

## 🔗 Useful Links

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/web/sign-in)
- [Flutter google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [OAuth 2.0 Setup Guide](https://support.google.com/cloud/answer/6158849)

---

## ✅ Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google Sign-In API
- [ ] Created OAuth 2.0 Web Client ID
- [ ] Copied Client ID
- [ ] Updated `web/index.html` with Client ID
- [ ] Added localhost origins to OAuth config
- [ ] Tested Google Sign-In locally
- [ ] (Optional) Set up Android credentials
- [ ] (Optional) Set up iOS credentials
- [ ] (Production) Added production domain to OAuth config

---

## 🎯 Quick Start (For Development)

**Don't have time to set up Google Sign-In?**

**Option 1**: Use email authentication (works immediately)

**Option 2**: Comment out Google Sign-In button temporarily:

In `auth.dart`, find and comment out the Google Sign-In button:

```dart
// Temporarily disabled - awaiting Google OAuth setup
// SizedBox(
//   width: double.infinity,
//   height: 54,
//   child: ElevatedButton(...),
// ),
```

---

**Need help?** Check the error messages - they'll guide you! 🎉
