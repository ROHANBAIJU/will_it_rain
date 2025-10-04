# Google Sign-In Final Fix 🚀

## Issues Encountered

### 1. ❌ People API Error (403)
```
"People API has not been used in project 606020632465 before or it is disabled"
```

### 2. ⚠️ Deprecated `signIn()` Method
- The `signIn()` method is deprecated for web
- Popup closes and doesn't reliably provide ID tokens

## Solutions Applied

### 1. ✅ Enable People API
**Action Required (YOU NEED TO DO THIS):**

1. Go to: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=606020632465
2. Click **"Enable API"**
3. Wait 2-3 minutes for propagation

### 2. ✅ Updated Code to Handle Access Tokens
- Modified `_handleGoogleSignIn()` to use `accessToken` as fallback
- Added `signOut()` before `signIn()` for clean state
- Added better error handling for:
  - People API errors (403)
  - Popup closed errors
  - ClientID errors

### 3. ✅ Added Helper Dialog
- Created `_showPeopleApiSetupDialog()` with direct link to enable API
- Better user guidance when People API is not enabled

## Code Changes

### `lib/screens/auth.dart`
```dart
// Key improvements:
1. Removed clientId from GoogleSignIn initialization (uses meta tag)
2. Added googleSignIn.signOut() before signIn() for clean state
3. Uses accessToken ?? idToken (web gives access tokens)
4. Better error detection for People API 403 errors
5. Ignores "popup_closed" errors (user cancellation)
```

### `web/index.html`
```html
<!-- Already configured -->
<meta name="google-signin-client_id" 
      content="606020632465-q4o1tjbq0a7eb099h088vpnbbr2j1l5h.apps.googleusercontent.com">
```

## Testing Steps

### Step 1: Enable People API (REQUIRED!)
Go here and click "Enable": 
https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=606020632465

### Step 2: Hot Reload the App
```powershell
# In your Flutter terminal, press 'r' to hot reload
# Or press 'R' to hot restart
```

### Step 3: Test Google Sign-In
1. Click "Sign in with Google" button
2. Select your Google account
3. Grant permissions
4. Should successfully login!

## Expected Behavior

### ✅ Success Flow:
1. Click "Sign in with Google"
2. Google popup opens
3. Select account
4. Popup closes
5. Green snackbar: "Successfully signed in with Google!"
6. Navigate to dashboard

### ⚠️ If People API Not Enabled:
- Dialog appears with instructions
- Link to enable API provided
- User can try email login instead

### ℹ️ If User Cancels:
- Brief snackbar: "Sign-in cancelled"
- No error thrown

## Troubleshooting

### Issue: Still getting 403 error
**Solution**: Wait 5-10 minutes after enabling People API

### Issue: Popup closes immediately
**Solution**: Check browser popup blocker settings

### Issue: "Invalid token" from backend
**Solution**: Backend already handles both access_token and id_token

## Backend Configuration

The backend `/auth/google` endpoint already handles:
- ✅ ID tokens (from mobile)
- ✅ Access tokens (from web)
- ✅ Auto-registration for new users
- ✅ Auto-login for existing users

No backend changes needed! 🎉

## Next Steps

1. **ENABLE PEOPLE API** (most important!)
2. Hot reload the app (`r` in terminal)
3. Test Google Sign-In
4. Verify user appears in Firestore
5. Test dashboard navigation

## Production Deployment

When deploying to production:
1. Add your production domain to Google Cloud Console:
   - Authorized JavaScript origins: `https://yourdomain.com`
   - Authorized redirect URIs: `https://yourdomain.com`
2. Update `web/index.html` if using different client ID for prod
3. Ensure People API is enabled for production project

---

**Status**: Ready to test after enabling People API! 🚀
