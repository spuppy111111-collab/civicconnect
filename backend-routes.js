// ============================================
// routes/draft.routes.js
// Draft Management Routes
// ============================================

const express = require("express");
const router = express.Router();
const draftController = require("../controllers/draft.controller");
const geolocationController = require("../controllers/geolocation.controller");

// Draft endpoints
router.post("/auto-save", draftController.autoSaveDraft);
router.get("/:user_id", draftController.getUserDraft);
router.post("/submit", draftController.submitDraftAsComplaint);
router.delete("/:draft_id", draftController.deleteDraft);

module.exports = router;

// ============================================
// routes/geolocation.routes.js
// Geolocation & Location Detection Routes
// ============================================

const express = require("express");
const router = express.Router();
const geolocationController = require("../controllers/geolocation.controller");

router.post("/detect", geolocationController.detectLocationFromCoordinates);
router.get("/all", geolocationController.getAllLocations);
router.get("/:id", geolocationController.getLocationById);

module.exports = router;

// ============================================
// routes/admin-dashboard.routes.js
// Admin Dashboard Real-time Routes
// ============================================

const express = require("express");
const router = express.Router();
const adminDashboardController = require("../controllers/admin-dashboard.controller");

// Dashboard endpoints
router.get("/", adminDashboardController.getDashboardComplaints);
router.get("/complaint/:id/details", adminDashboardController.getComplaintDetailsForAdmin);
router.get("/complaints/status/:status", adminDashboardController.getComplaintsByStatus);
router.get("/complaints/category/:category_id", adminDashboardController.getComplaintsByCategory);
router.get("/map-data", adminDashboardController.getMapData);

module.exports = router;
