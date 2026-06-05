# Aviator App - API Integration Test Guide

## ✅ API & App Status

Both the **Django backend** and **Flutter app** are running and communicating properly.

### Backend
- **Status**: Running on http://127.0.0.1:8000
- **Access Key Management**: http://127.0.0.1:8000/access-keys/
- **Endpoints**:
  - `POST /api/access-keys/generate/` ✅ Working
  - `POST /api/access-keys/validate/` ✅ Working
  - `GET /api/prediction/` ✅ Working (monitor-aware)

### Frontend
- **Status**: Running on Linux desktop
- **API Base URL**: http://127.0.0.1:8000
- **Communication**: ✅ Verified working

---

## 🧪 Step-by-Step Testing

### Step 1: Generate an Access Key

**Via Web UI** (recommended):
1. Open http://127.0.0.1:8000/access-keys/
2. Click "Generate Key"
3. **NEW**: The page now shows:
   - ✅ Access key
   - ✅ Generated timestamp
   - ✅ Expiry date & time
   - ✅ Days until expiration

**Via API**:
```bash
curl -X POST http://127.0.0.1:8000/api/access-keys/generate/ \
  -H "Content-Type: application/json" \
  -d '{"valid_days": 30}'
```

Response:
```json
{
  "access_key": "96C6B5",
  "expires_at": "2026-06-01T07:25:59.233Z"
}
```

### Step 2: Enter Key in Flutter App

1. The Flutter app displays an access key entry screen
2. Enter the key (e.g., `96C6B5`) - one character per field
3. Press "Unlock"

**What happens**:
- App sends: `POST /api/access-keys/validate/` with your key
- Backend validates and returns: `{"success": true, "valid": true}`
- App unlocks and saves your access status

### Step 3: Generate Prediction

Once unlocked:
1. Click the "Generate" button
2. The app:
   - Checks network connection ✅
   - Connects to API ✅
   - Fetches prediction (odds + time) ✅
   - Displays results

---

## 🔍 Verification Checklist

### Test Valid Key
```bash
curl -X POST http://127.0.0.1:8000/api/access-keys/validate/ \
  -H "Content-Type: application/json" \
  -d '{"access_key": "96C6B5"}'
```

Expected response:
```json
{
  "success": true,
  "valid": true,
  "data": {"expires_at": "2026-06-01T07:25:59.233Z"}
}
```

### Test Invalid Key
```bash
curl -X POST http://127.0.0.1:8000/api/access-keys/validate/ \
  -H "Content-Type: application/json" \
  -d '{"access_key": "WRONG99"}'
```

Expected response:
```json
{
  "success": true,
  "valid": false,
  "message": "Invalid or expired access key."
}
```

### Check Backend Logs
The Django terminal shows all requests:
```
[02/May/2026 02:25:59] "POST /api/access-keys/generate/ HTTP/1.1" 200 66
[02/May/2026 02:25:59] "POST /api/access-keys/validate/ HTTP/1.1" 200 84
```

---

## 🎯 Features Implemented

✅ **API Configuration**
- Auto-detect local API on Android (10.0.2.2:8000)
- Auto-detect local API on iOS/Desktop (127.0.0.1:8000)
- Override via `--dart-define=AVIATOR_API_BASE_URL=http://your-host:8000`

✅ **Fallback Routing**
- Try Django endpoints first (`/api/access-keys/validate/`, `/api/prediction/`)
- Fall back to legacy PHP paths if needed
- Handles 404/405 gracefully

✅ **Access Key Display**
- Web UI now shows expiry date/time
- Shows days until expiration
- Clear call-to-action for mobile app

✅ **Error Handling**
- App shows "API unavailable" if backend is down
- Validates key format before submitting
- Handles network timeouts gracefully

---

## 🚀 Ready for Testing

The integration is complete! Try this flow:

1. **Generate a key**: Visit http://127.0.0.1:8000/access-keys/
2. **Copy the key**: It now shows when it expires
3. **Enter in app**: Paste the key into the Flutter app
4. **Unlock**: Press Unlock button
5. **Generate prediction**: Click Generate to fetch odds & time

All API calls are logged on the backend terminal for debugging.
