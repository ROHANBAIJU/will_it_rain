# 🐳 Docker Rebuild Guide - Phase 3 Updates

## ✅ Why You Need to Rebuild

We made changes that require a Docker rebuild:
1. **New dependency**: `firebase-admin` added to `requirements.txt`
2. **Code changes**: Updated multiple Python files
3. **Environment variables**: Need to pass `.env` to container

---

## 🚀 Quick Rebuild (Easiest Way)

### **Step 1: Make Sure You're in BACKEND Directory**
```powershell
cd D:\will_it_rain\BACKEND
```

### **Step 2: Run the Nuke Script**
```powershell
.\nuke_all.ps1 -Action nuke
```

**What it does**:
- ✅ Stops old container
- ✅ Removes old container
- ✅ Deletes old image
- ✅ Builds new image with `firebase-admin`
- ✅ Starts new container with .env file
- ✅ Mounts code for hot-reload

### **Step 3: Verify It's Running**
```powershell
# Check container status
docker ps

# View logs
docker logs -f willitrain-container
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

---

## 🧪 Test Your Container

### **Test 1: Health Check**
```powershell
curl http://localhost:8000/
```

Expected:
```json
{"status": "ok", "message": "Will It Rain API is running!"}
```

### **Test 2: Prediction**
```powershell
curl "http://localhost:8000/predict?lat=13.009&lon=77.614&date=2028-10-05"
```

Expected: JSON response with weather statistics

### **Test 3: Check Firebase Status**
Look at the logs:
```powershell
docker logs willitrain-container
```

**With Firebase configured**:
```
✅ Firebase initialized successfully with credentials file
```

**Without Firebase**:
```
⚠️ Firebase credentials not found.
   Running without caching (direct API mode)
```

---

## 📝 What Changed in the Script

### **Before**:
```powershell
docker run -d -p 8000:8000 --name $containerName -v "${PSScriptRoot}:/app" $imageName
```

### **After**:
```powershell
# Now automatically includes .env file if it exists
if (Test-Path "${PSScriptRoot}\.env") {
    docker run -d -p 8000:8000 --name $containerName `
        -v "${PSScriptRoot}:/app" `
        --env-file "${PSScriptRoot}\.env" `
        $imageName
}
```

**Benefits**:
- ✅ Automatically passes environment variables
- ✅ Works with or without `.env` file
- ✅ No manual configuration needed

---

## 🔧 Manual Rebuild (If Script Fails)

If the PowerShell script doesn't work:

```powershell
cd D:\will_it_rain\BACKEND

# 1. Stop and remove old container
docker stop willitrain-container
docker rm willitrain-container

# 2. Remove old image
docker rmi willitrain-backend -f

# 3. Rebuild image
docker build -t willitrain-backend .

# 4. Start new container (with .env)
docker run -d -p 8000:8000 --name willitrain-container `
    -v "${PWD}:/app" `
    --env-file .env `
    willitrain-backend

# 5. View logs
docker logs -f willitrain-container
```

---

## 📊 Docker + Firebase Options

### **Option A: With Firebase Credentials File**

**Requirements**:
- `firebase-credentials.json` in BACKEND folder
- `.env` file with `FIREBASE_CREDENTIALS=/app/firebase-credentials.json`

**Docker command**:
```powershell
docker run -d -p 8000:8000 --name willitrain-container `
    -v "${PWD}:/app" `
    --env-file .env `
    willitrain-backend
```

**Result**: Full caching enabled ⚡

---

### **Option B: Without Firebase**

**Requirements**: None

**Docker command**:
```powershell
docker run -d -p 8000:8000 --name willitrain-container `
    -v "${PWD}:/app" `
    willitrain-backend
```

**Result**: Works in direct API mode (no caching)

---

## 🎯 Recommended Flow

### **For Development (Hot-Reload)**:
```powershell
cd BACKEND
.\nuke_all.ps1 -Action nuke
# Code changes will auto-reload!
```

### **For Production**:
```powershell
cd BACKEND
docker build -t willitrain-backend .
docker run -d -p 8000:8000 --name willitrain-container `
    --env-file .env `
    willitrain-backend
```

---

## 🐛 Troubleshooting

### **Issue: "docker: command not found"**
**Solution**: Make sure Docker Desktop is running

### **Issue: "Cannot remove container"**
```powershell
# Force remove
docker rm -f willitrain-container
```

### **Issue: "Port already in use"**
```powershell
# Find what's using port 8000
netstat -ano | findstr :8000

# Kill the process or use different port
docker run -d -p 8001:8000 ...
```

### **Issue: "Build fails"**
```powershell
# Check if requirements.txt is correct
cat requirements.txt

# Try building without cache
docker build --no-cache -t willitrain-backend .
```

### **Issue: Container starts but crashes**
```powershell
# View full logs
docker logs willitrain-container

# Run interactively to see errors
docker run -it --rm -p 8000:8000 willitrain-backend
```

---

## 📋 Checklist Before Rebuild

- [ ] You're in the BACKEND directory
- [ ] Docker Desktop is running
- [ ] `.env` file exists (optional but recommended)
- [ ] Old container stopped: `docker stop willitrain-container`
- [ ] Ready to run nuke script

---

## ✅ After Rebuild

**Verify everything works**:
1. Container is running: `docker ps`
2. Health check passes: `curl http://localhost:8000/`
3. Predictions work: Test with a sample request
4. Check logs: `docker logs willitrain-container`

---

## 🎉 Summary

**YES, rebuild your Docker container!**

**Easiest way**:
```powershell
cd BACKEND
.\nuke_all.ps1 -Action nuke
```

**Time required**: ~2-3 minutes  
**Risk**: None (nuke script is safe)  
**Benefit**: Latest code + new dependencies + .env support

---

**Ready to rebuild? Just run the command above!** 🚀
