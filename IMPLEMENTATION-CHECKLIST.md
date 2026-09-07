# ✅ CivicConnect Implementation Checklist

## 🗄️ DATABASE (MySQL Workbench)

- [ ] Execute `draft-realtime-schema.sql`
- [ ] Verify tables created:
  - [ ] `complaint_drafts`
  - [ ] `complaints` (updated columns)
  - [ ] `admin_dashboard_complaints` (VIEW)
- [ ] Verify triggers created:
  - [ ] `sync_complaint_to_admin`
  - [ ] `notify_on_status_change`
- [ ] Insert sample data:
  - [ ] Categories (8 categories)
  - [ ] Locations (8 locations with coordinates)

**Verification SQL:**
```sql
SHOW TABLES;
SELECT COUNT(*) FROM complaint_drafts;
SELECT COUNT(*) FROM locations;
SELECT * FROM admin_dashboard_complaints LIMIT 1;
```

---

## 🔧 BACKEND SETUP

### Controllers
- [ ] Create `backend/controllers/draft.controller.js`
- [ ] Create `backend/controllers/geolocation.controller.js`
- [ ] Create `backend/controllers/admin-dashboard.controller.js`

### Routes
- [ ] Create `backend/routes/draft.routes.js`
- [ ] Create `backend/routes/geolocation.routes.js`
- [ ] Create `backend/routes/admin-dashboard.routes.js`

### Server Configuration
- [ ] Update `backend/server.js`:
  ```javascript
  app.use("/api/drafts", require("./routes/draft.routes"));
  app.use("/api/geolocation", require("./routes/geolocation.routes"));
  app.use("/api/admin-dashboard", require("./routes/admin-dashboard.routes"));
  ```

- [ ] Verify CORS settings:
  ```javascript
  app.use(cors({
    origin: "http://localhost:3000",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    credentials: true
  }));
  ```

### Dependencies
- [ ] Check `package.json` includes:
  - [ ] `express`
  - [ ] `mysql2`
  - [ ] `cors`
  - [ ] `dotenv`

### Environment Variables (`.env`)
- [ ] DB_HOST=localhost
- [ ] DB_USER=root
- [ ] DB_PASSWORD=your_password
- [ ] DB_NAME=civicconnect
- [ ] DB_PORT=3306
- [ ] PORT=8000
- [ ] CORS_ORIGIN=http://localhost:3000

### Start Backend
- [ ] Run: `node server.js`
- [ ] Verify output:
  ```
  🚀 CivicConnect API running on port 8000
  ✅ CORS enabled for: http://localhost:3000
  ```

---

## ⚛️ FRONTEND SETUP (React)

### Install Dependencies
- [ ] Run: `npm install axios leaflet react-leaflet`
- [ ] Run: `npm install -g serve` (optional, for testing build)

### Component Structure
- [ ] Create `src/components/ReportProblem/`
  - [ ] ReportForm.jsx
  - [ ] ReportForm.css

- [ ] Create `src/components/AdminDashboard/`
  - [ ] ComplaintsDashboard.jsx
  - [ ] ComplaintsDashboard.css

### Styles
- [ ] Copy CSS from `dashboard-styles.css`:
  - [ ] `.report-form-container` styles
  - [ ] `.admin-dashboard` styles
  - [ ] Responsive media queries

### Routing (App.jsx)
- [ ] Update routes:
  ```javascript
  <Route path="/report" element={<ReportForm userId={1} />} />
  <Route path="/admin" element={<ComplaintsDashboard />} />
  ```

### API Constants
- [ ] Verify API_BASE_URL in components:
  ```javascript
  const API_BASE_URL = "http://localhost:8000/api";
  ```

### Start Frontend
- [ ] Run: `npm start`
- [ ] Verify app opens at `http://localhost:3000`

---

## 🧪 TESTING CHECKLIST

### Test 1: Auto-save Draft
- [ ] Go to `http://localhost:3000/report`
- [ ] Fill title: "Road Damage"
- [ ] Fill description: "Pothole on Main Street"
- [ ] Wait 30 seconds
- [ ] Check browser Network tab for POST to `/api/drafts/auto-save`
- [ ] See "✅ Auto-saved" status
- [ ] Refresh page
- [ ] Verify draft is still there

**Expected Result:** Draft saved and reloaded ✅

---

### Test 2: Location Detection
- [ ] Still on report form
- [ ] Click "📍 Auto-Detect" button
- [ ] Allow browser location permission
- [ ] Should see alert with detected location
- [ ] Address field should be filled

**Expected Result:** Location auto-detected ✅

---

### Test 3: Map Selection
- [ ] Click "🗺️ Select on Map"
- [ ] Map should show location cards
- [ ] Click on "Whitefield" card
- [ ] Should show "✅ Location selected: Whitefield, Bangalore"
- [ ] Address field updated

**Expected Result:** Location selected from map ✅

---

### Test 4: Image Upload
- [ ] Click "Choose File" in photo upload
- [ ] Select any image from your computer
- [ ] Should see image preview
- [ ] Click "🚀 Submit Complaint"

**Expected Result:** Image uploaded and complaint submitted ✅

---

### Test 5: Submit Complaint
- [ ] Fill all required fields:
  - [ ] Title: "Road Damage on Main Street"
  - [ ] Description: "Large pothole causing traffic issues"
  - [ ] Category: Select "Road Damage"
  - [ ] Priority: Select "High"
  - [ ] Location: Auto-detect or select from map
- [ ] Click "🚀 Submit Complaint"
- [ ] Should see success alert with complaint ID

**Expected Result:** Complaint submitted successfully ✅

---

### Test 6: Admin Dashboard Display
- [ ] Open new tab: `http://localhost:3000/admin`
- [ ] Should see "Admin Dashboard - Complaints Management"
- [ ] Should see statistics cards:
  - [ ] Total Complaints: 1
  - [ ] Pending: 1
  - [ ] In Progress: 0
  - [ ] Resolved: 0
- [ ] Should see your complaint in table

**Expected Result:** Complaint visible in admin dashboard ✅

---

### Test 7: Filter Complaints
- [ ] Filter by Status: Select "Pending"
- [ ] Should show only pending complaints
- [ ] Filter by Category: Select "Road Damage"
- [ ] Should show only road damage complaints

**Expected Result:** Filtering works correctly ✅

---

### Test 8: View Complaint Details
- [ ] Click on any complaint row
- [ ] Right panel should open with details:
  - [ ] Complaint number
  - [ ] Title & Description
  - [ ] Citizen name & contact
  - [ ] Category & Location
  - [ ] Status & Priority
  - [ ] Coordinates
  - [ ] "✅ Synced from Citizen Dashboard"

**Expected Result:** Full complaint details shown ✅

---

### Test 9: Map View
- [ ] Still in admin dashboard
- [ ] Click "🗺️ Map View" button
- [ ] Should show map grid with complaint markers
- [ ] Each marker shows complaint info
- [ ] Click marker to see details

**Expected Result:** Map view displays complaints ✅

---

### Test 10: Real-time Sync
- [ ] Open admin dashboard
- [ ] In new tab, go to report form
- [ ] Fill and submit new complaint
- [ ] Return to admin dashboard
- [ ] Wait max 10 seconds
- [ ] New complaint should appear

**Expected Result:** Real-time sync working ✅

---

## 🐛 DEBUGGING TIPS

### If drafts don't save:
```javascript
// Check browser console for errors
console.log("Saving draft...", formData);

// Check Network tab:
// POST http://localhost:8000/api/drafts/auto-save
// Response should be: { success: true, draftId: X }
```

### If admin dashboard doesn't load:
```javascript
// Check if backend is running
// Terminal: node server.js should show port 8000

// Check API call in Network tab:
// GET http://localhost:8000/api/admin-dashboard
// Should return all complaints
```

### If location detection fails:
```javascript
// Enable location in browser settings
// Chrome → Settings → Privacy → Site Settings → Location
// Allow localhost:3000

// Check coordinates are valid
// Must be between: lat -90 to 90, lng -180 to 180
```

---

## 📊 DATABASE VERIFICATION

Run these queries in MySQL Workbench:

```sql
-- Check draft exists
SELECT * FROM complaint_drafts WHERE user_id = 1;

-- Check complaint is synced
SELECT complaint_number, title, synced_to_admin, sync_timestamp 
FROM complaints 
WHERE synced_to_admin = TRUE
ORDER BY sync_timestamp DESC;

-- Check admin dashboard view
SELECT * FROM admin_dashboard_complaints LIMIT 5;

-- Check notifications created
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;

-- Check locations
SELECT * FROM locations WHERE city = 'Bangalore';
```

---

## 🎉 SUCCESS CRITERIA

Your implementation is successful when:

✅ Draft auto-saves every 30 seconds  
✅ Location detection works with browser GPS  
✅ Location selection works from map  
✅ Complaint submits successfully  
✅ Complaint appears in admin dashboard within 10 seconds  
✅ All complaint details are displayed correctly  
✅ Filtering works (by status and category)  
✅ Map view shows complaint locations  
✅ Real-time sync is working  
✅ No CORS errors in console  

---

## 📞 COMMON ISSUES & SOLUTIONS

| Issue | Solution |
|-------|----------|
| CORS Error | Check CORS settings in server.js, restart backend |
| Drafts not saving | Verify API endpoint, check database connection |
| Location detection fails | Enable location permission, check coordinates |
| Admin dashboard empty | Poll interval running? Check Network tab |
| Image upload doesn't work | Implement cloud storage (AWS S3, GCS) |
| Slow performance | Add pagination, implement caching |

---

## 🚀 You're Ready!

Once all checkboxes are complete:

1. ✅ Database fully set up
2. ✅ Backend APIs running
3. ✅ Frontend components working
4. ✅ All tests passing
5. ✅ No errors in console

**Your CivicConnect application is production-ready!**

Next steps:
- Add user authentication
- Implement email notifications
- Set up file storage (AWS S3)
- Deploy to cloud (AWS/Azure/GCP)
- Monitor with analytics

---

**Questions? Check the detailed guide in `DRAFT-REALTIME-IMPLEMENTATION.md`**
