# 🚀 CivicConnect - Draft Saving & Real-time Admin Sync Guide

## 📋 Overview

This guide implements:
- ✅ **Draft Saving** - Auto-save complaint reports every 30 seconds
- ✅ **Automatic Location Detection** - Detect coordinates on map
- ✅ **Real-time Sync** - Auto-sync from citizen dashboard to admin dashboard
- ✅ **Admin Display** - Show all complaint details in real-time
- ✅ **Map View** - Visual representation of complaints on map

---

## 🗄️ Part 1: Database Setup

### Step 1: Update Database Schema

Run the following SQL in MySQL Workbench:

```sql
-- File: draft-realtime-schema.sql
```

This creates:
- `complaint_drafts` table - Stores draft complaints
- `admin_dashboard_complaints` view - Real-time synced complaints
- Auto-sync triggers
- Sample location data with coordinates

### Step 2: Execute in MySQL

1. Open MySQL Workbench
2. Copy content from `draft-realtime-schema.sql`
3. Click **Execute All** (`Ctrl + Shift + Enter`)

✅ Database is now ready!

---

## 💾 Part 2: Backend Setup

### Step 1: Update Backend Routes

Add to your `server.js`:

```javascript
const express = require("express");
const app = express();

// ... existing code ...

// Import new routes
const draftRoutes = require("./routes/draft.routes");
const geolocationRoutes = require("./routes/geolocation.routes");
const adminDashboardRoutes = require("./routes/admin-dashboard.routes");

// Register routes
app.use("/api/drafts", draftRoutes);
app.use("/api/geolocation", geolocationRoutes);
app.use("/api/admin-dashboard", adminDashboardRoutes);

// ... rest of server.js ...
```

### Step 2: Copy Controller Files

1. Create folder: `backend/controllers/`
2. Copy these files:
   - `draft.controller.js`
   - `geolocation.controller.js`
   - `admin-dashboard.controller.js`

From the file: `controllers-draft-geolocation.js`

### Step 3: Copy Route Files

1. Create folder: `backend/routes/`
2. Create these files:
   - `draft.routes.js`
   - `geolocation.routes.js`
   - `admin-dashboard.routes.js`

From the file: `backend-routes.js`

### Step 4: Start Backend

```bash
cd backend
node server.js
```

Output:
```
🚀 CivicConnect API running on port 8000
✅ CORS enabled for: http://localhost:3000
```

---

## ⚛️ Part 3: Frontend Setup (React)

### Step 1: Install Required Packages

```bash
npm install axios leaflet react-leaflet
```

### Step 2: Create Components Folder

```
src/
├── components/
│   ├── ReportProblem/
│   │   ├── ReportForm.jsx
│   │   └── ReportForm.css
│   │
│   └── AdminDashboard/
│       ├── ComplaintsDashboard.jsx
│       └── ComplaintsDashboard.css
```

### Step 3: Copy Component Files

1. Copy `ReportForm.jsx` → `src/components/ReportProblem/`
2. Copy `ComplaintsAdminDashboard.jsx` → `src/components/AdminDashboard/`
3. Copy `dashboard-styles.css` → Use styles in respective components

### Step 4: Update React Routing

In your `App.jsx`:

```javascript
import ReportForm from "./components/ReportProblem/ReportForm";
import ComplaintsDashboard from "./components/AdminDashboard/ComplaintsDashboard";

function App() {
  return (
    <Routes>
      {/* Citizen Routes */}
      <Route path="/report" element={<ReportForm userId={1} />} />
      
      {/* Admin Routes */}
      <Route path="/admin" element={<ComplaintsDashboard />} />
    </Routes>
  );
}
```

### Step 5: Start React App

```bash
npm start
```

---

## 🔄 How It Works

### Citizen Workflow (Report Problem)

```
1️⃣ User fills report form
   ↓
2️⃣ Auto-save every 30 seconds
   ↓
3️⃣ Draft saved in DB
   ↓
4️⃣ User selects location (auto-detect or map)
   ↓
5️⃣ User clicks "Submit"
   ↓
6️⃣ Complaint submitted & synced to admin
```

### Admin Workflow (View Complaints)

```
1️⃣ Admin visits admin dashboard
   ↓
2️⃣ Fetches all synced complaints
   ↓
3️⃣ Shows real-time statistics
   ↓
4️⃣ Displays complaint list & map view
   ↓
5️⃣ Admin clicks complaint → View full details
   ↓
6️⃣ Details show citizen info, updates, ratings
```

### Real-time Sync Flow

```
Citizen Dashboard              Backend                Admin Dashboard
     │                            │                          │
     ├─ Fill Form ────────────────>│                          │
     │                            │                          │
     ├─ Auto-save Draft ────────>│                          │
     │ (every 30 sec)            │                          │
     │                            │                          │
     ├─ Select Location ────────>│                          │
     │                            │                          │
     ├─ Submit Complaint ───────>│                          │
     │                            ├─ Save to DB              │
     │                            │                          │
     │                            ├─ Mark Synced=TRUE ──────>│
     │                            │                          │
     │                            ├─ Create Notification     │
     │                            │                          │
     │ ✅ Success Message          │                          │
     │<──────────────────────────│                          │
     │                            │                          │
     │                            ├─ Poll Every 10 sec ──────>
     │                            │                          │
     │                            │<─ Fetch Dashboard Data ───
     │                            │                          │
     │                            │<─ Show Complaint ────────>
     │                            │                          │
```

---

## 🎯 Key Features Implemented

### 1. Draft Auto-saving

- **Frequency:** Every 30 seconds
- **Storage:** `complaint_drafts` table
- **Status:** Auto-save indicator shows in UI
- **API Endpoint:** `POST /api/drafts/auto-save`

```javascript
// Automatically called every 30 seconds
const autoSaveDraft = async () => {
  await axios.post("/api/drafts/auto-save", {
    user_id: userId,
    title: formData.title,
    description: formData.description,
    // ... other fields
  });
};
```

### 2. Location Auto-detection

- **Method 1:** Click "📍 Auto-Detect" → Uses browser geolocation
- **Method 2:** Click "🗺️ Select on Map" → Choose from predefined locations
- **API Endpoint:** `POST /api/geolocation/detect`

```javascript
// Detect nearest location from coordinates
const response = await axios.post("/api/geolocation/detect", {
  latitude: 12.9698,
  longitude: 77.7499
});
```

### 3. Real-time Admin Sync

- **Trigger:** When complaint is submitted
- **Action:** Set `synced_to_admin = TRUE`
- **Timestamp:** Record `sync_timestamp`
- **View:** `admin_dashboard_complaints` VIEW
- **Polling:** Admin dashboard polls every 10 seconds

```javascript
// Auto-sync trigger in MySQL
CREATE TRIGGER sync_complaint_to_admin
AFTER INSERT ON complaints
FOR EACH ROW
BEGIN
  UPDATE complaints 
  SET synced_to_admin = TRUE, sync_timestamp = NOW() 
  WHERE id = NEW.id;
END;
```

### 4. Admin Dashboard Display

- **Statistics:** Total, pending, in-progress, resolved
- **List View:** Table with filtering by status & category
- **Map View:** Visual markers of complaints
- **Details Panel:** Click any complaint to see full details
- **Real-time Updates:** Polls every 10 seconds

### 5. Location Services

- **Geolocation API:** Get user's GPS coordinates
- **Location Database:** Predefined locations with coordinates
- **Distance Calculation:** Find nearest location to user
- **Map Display:** Show complaints as markers

---

## 📊 API Endpoints Reference

### Draft Management
```
POST   /api/drafts/auto-save              - Auto-save draft
GET    /api/drafts/:user_id               - Get user's draft
POST   /api/drafts/submit                 - Submit draft as complaint
DELETE /api/drafts/:draft_id              - Delete draft
```

### Geolocation
```
POST   /api/geolocation/detect            - Detect location from coordinates
GET    /api/geolocation/all               - Get all locations
GET    /api/geolocation/:id               - Get specific location
```

### Admin Dashboard
```
GET    /api/admin-dashboard               - Get dashboard data
GET    /api/admin-dashboard/complaint/:id/details  - Get complaint details
GET    /api/admin-dashboard/complaints/status/:status  - Filter by status
GET    /api/admin-dashboard/complaints/category/:id  - Filter by category
GET    /api/admin-dashboard/map-data      - Get map data
```

---

## 🧪 Testing the Complete Flow

### Test 1: Draft Auto-saving
1. Go to `/report` page
2. Fill in title and description
3. Wait 30 seconds
4. Open browser DevTools → Network
5. See POST to `/api/drafts/auto-save` ✅

### Test 2: Location Detection
1. Click "📍 Auto-Detect" button
2. Allow location permission
3. Should show nearest location ✅

### Test 3: Map Selection
1. Click "🗺️ Select on Map"
2. Click any location card
3. Address should be filled ✅

### Test 4: Submit & Sync
1. Fill form completely
2. Click "🚀 Submit Complaint"
3. Note the complaint ID
4. Open admin dashboard at `/admin`
5. New complaint should appear in list within 10 seconds ✅
6. Click complaint to see details ✅

### Test 5: Real-time Admin Updates
1. Admin opens dashboard
2. Citizen submits new complaint
3. Admin dashboard should update within 10 seconds ✅
4. Statistics should increment ✅

---

## 🐛 Troubleshooting

### Problem: Drafts not saving
**Solution:**
1. Check browser console for errors
2. Verify backend is running (`node server.js`)
3. Check CORS settings in `server.js`
4. Ensure database connection is active

### Problem: Location detection not working
**Solution:**
1. Check browser geolocation permission
2. Enable location services on your device
3. Ensure coordinates are within India bounds
4. Check if locations table has sample data

### Problem: Admin dashboard not showing complaints
**Solution:**
1. Verify complaint was actually synced (`synced_to_admin = TRUE`)
2. Check admin dashboard polling (should poll every 10 sec)
3. Open browser DevTools → Network to see API calls
4. Verify complaint in MySQL: `SELECT * FROM complaints;`

### Problem: CORS error on API calls
**Solution:**
1. Verify backend has CORS enabled
2. Check `CORS_ORIGIN` in `.env`
3. Ensure frontend URL matches CORS settings
4. Restart backend server

---

## 📱 Features Summary

| Feature | Citizen Dashboard | Admin Dashboard |
|---------|------------------|-----------------|
| **Auto-save Draft** | ✅ Every 30 sec | - |
| **Location Selection** | ✅ Map + Auto-detect | ✅ View on Map |
| **Real-time Sync** | ✅ On submit | ✅ Polls every 10s |
| **Complaint Filtering** | - | ✅ By status/category |
| **Map View** | ✅ Select location | ✅ See all complaints |
| **Details Panel** | - | ✅ Full complaint view |
| **Notifications** | ✅ Status updates | ✅ New complaints |

---

## 🚀 Next Steps

1. ✅ Database schema updated
2. ✅ Backend API created
3. ✅ Frontend components built
4. 🔄 **Test the complete flow**
5. 📝 Add authentication (login/signup)
6. 🔔 Implement WebSocket for real-time updates (instead of polling)
7. 📊 Add more admin features (assign, status update, notes)
8. 📸 Implement file upload to cloud storage
9. 🎯 Add email notifications
10. 📦 Deploy to production

---

## 💡 Pro Tips

### For Better Performance:
- Replace polling with WebSocket for real-time updates
- Use database indexing on frequently queried fields
- Cache complaint data on frontend
- Implement pagination for large datasets

### For Better UX:
- Add loading spinners while saving
- Show toast notifications for success/error
- Use debouncing for auto-save
- Show visual confirmation of location selection

### For Better Security:
- Add authentication to all endpoints
- Validate file uploads
- Sanitize user input
- Use prepared statements (already done!)

---

**✨ Your CivicConnect application is now fully functional with draft saving and real-time admin sync!**
