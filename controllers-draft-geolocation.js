// ============================================
// controllers/draft.controller.js
// Draft Management & Auto-save Functionality
// ============================================

const pool = require("../config/database");

// Auto-save draft (triggered every 30 seconds from frontend)
exports.autoSaveDraft = async (req, res) => {
  try {
    const { user_id, title, description, category_id, location_id, latitude, longitude, address, image_url, priority } = req.body;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: "User ID is required"
      });
    }

    const connection = await pool.getConnection();

    // Check if draft exists for this user
    const [existingDraft] = await connection.query(
      "SELECT id FROM complaint_drafts WHERE user_id = ? ORDER BY last_saved_at DESC LIMIT 1",
      [user_id]
    );

    let result;
    if (existingDraft.length > 0) {
      // Update existing draft
      await connection.query(
        `UPDATE complaint_drafts 
         SET title = ?, description = ?, category_id = ?, location_id = ?, 
             latitude = ?, longitude = ?, address = ?, image_url = ?, priority = ?,
             status = 'auto_saved', last_saved_at = NOW()
         WHERE id = ?`,
        [title, description, category_id, location_id, latitude, longitude, address, image_url, priority, existingDraft[0].id]
      );
      result = { id: existingDraft[0].id };
    } else {
      // Create new draft
      const [insertResult] = await connection.query(
        `INSERT INTO complaint_drafts (user_id, title, description, category_id, location_id, latitude, longitude, address, image_url, priority, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'auto_saved')`,
        [user_id, title, description, category_id, location_id, latitude, longitude, address, image_url, priority]
      );
      result = insertResult;
    }

    connection.release();

    res.json({
      success: true,
      message: "Draft auto-saved successfully",
      draftId: result.id || existingDraft[0].id
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to auto-save draft",
      error: error.message
    });
  }
};

// Get user's draft
exports.getUserDraft = async (req, res) => {
  try {
    const { user_id } = req.params;
    const connection = await pool.getConnection();

    const [draft] = await connection.query(
      `SELECT d.*, c.name as category_name
       FROM complaint_drafts d
       LEFT JOIN categories c ON d.category_id = c.id
       WHERE d.user_id = ? AND d.status IN ('draft', 'auto_saved')
       ORDER BY d.last_saved_at DESC
       LIMIT 1`,
      [user_id]
    );

    connection.release();

    if (draft.length === 0) {
      return res.json({
        success: true,
        data: null,
        message: "No draft found"
      });
    }

    res.json({
      success: true,
      data: draft[0]
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch draft",
      error: error.message
    });
  }
};

// Submit draft as complaint (Citizen Dashboard → Admin Dashboard)
exports.submitDraftAsComplaint = async (req, res) => {
  try {
    const { draft_id, user_id } = req.body;

    if (!draft_id || !user_id) {
      return res.status(400).json({
        success: false,
        message: "Draft ID and User ID are required"
      });
    }

    const connection = await pool.getConnection();

    // Get draft details
    const [draft] = await connection.query(
      "SELECT * FROM complaint_drafts WHERE id = ? AND user_id = ?",
      [draft_id, user_id]
    );

    if (draft.length === 0) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: "Draft not found"
      });
    }

    const draftData = draft[0];

    // Create complaint from draft
    const [complaintResult] = await connection.query(
      `INSERT INTO complaints 
       (user_id, category_id, location_id, title, description, image_url, priority, latitude, longitude, is_draft_submission, synced_to_admin, sync_timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE, TRUE, NOW())`,
      [
        user_id,
        draftData.category_id,
        draftData.location_id,
        draftData.title,
        draftData.description,
        draftData.image_url,
        draftData.priority,
        draftData.latitude,
        draftData.longitude
      ]
    );

    const complaintId = complaintResult.insertId;

    // Delete draft
    await connection.query("DELETE FROM complaint_drafts WHERE id = ?", [draft_id]);

    connection.release();

    res.status(201).json({
      success: true,
      message: "Draft submitted successfully! Admin dashboard notified.",
      complaintId: complaintId,
      synced_to_admin: true
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to submit draft",
      error: error.message
    });
  }
};

// Delete draft
exports.deleteDraft = async (req, res) => {
  try {
    const { draft_id } = req.params;
    const { user_id } = req.body;

    const connection = await pool.getConnection();
    const [result] = await connection.query(
      "DELETE FROM complaint_drafts WHERE id = ? AND user_id = ?",
      [draft_id, user_id]
    );

    connection.release();

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "Draft not found"
      });
    }

    res.json({
      success: true,
      message: "Draft deleted successfully"
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to delete draft",
      error: error.message
    });
  }
};

// ============================================
// controllers/geolocation.controller.js
// Location Detection & Map Integration
// ============================================

// Detect location from coordinates
exports.detectLocationFromCoordinates = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: "Latitude and longitude are required"
      });
    }

    const connection = await pool.getConnection();

    // Find nearest location based on coordinates
    const [locations] = await connection.query(
      `SELECT *,
              SQRT(
                (coordinates_latitude - ?) * (coordinates_latitude - ?) +
                (coordinates_longitude - ?) * (coordinates_longitude - ?)
              ) as distance
       FROM locations
       WHERE is_active = TRUE
       ORDER BY distance ASC
       LIMIT 1`,
      [latitude, latitude, longitude, longitude]
    );

    connection.release();

    if (locations.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No location found for these coordinates"
      });
    }

    res.json({
      success: true,
      data: locations[0],
      message: "Location detected successfully"
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to detect location",
      error: error.message
    });
  }
};

// Get all locations for map display
exports.getAllLocations = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [locations] = await connection.query(
      `SELECT id, city, district, coordinates_latitude as lat, coordinates_longitude as lng, pin_code
       FROM locations
       WHERE is_active = TRUE`
    );

    connection.release();

    res.json({
      success: true,
      data: locations
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch locations",
      error: error.message
    });
  }
};

// Get location by ID
exports.getLocationById = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    const [location] = await connection.query(
      "SELECT * FROM locations WHERE id = ? AND is_active = TRUE",
      [id]
    );

    connection.release();

    if (location.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Location not found"
      });
    }

    res.json({
      success: true,
      data: location[0]
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch location",
      error: error.message
    });
  }
};

// ============================================
// controllers/admin-dashboard.controller.js
// Real-time Admin Dashboard Data
// ============================================

// Get all complaints with real-time sync status
exports.getDashboardComplaints = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [complaints] = await connection.query(
      `SELECT * FROM admin_dashboard_complaints
       WHERE synced_to_admin = TRUE
       ORDER BY sync_timestamp DESC`
    );

    // Get statistics
    const [stats] = await connection.query(
      `SELECT 
        COUNT(*) as total_complaints,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved
       FROM complaints
       WHERE synced_to_admin = TRUE`
    );

    // Get recent complaints (last 10)
    const [recent] = await connection.query(
      `SELECT * FROM admin_dashboard_complaints
       WHERE synced_to_admin = TRUE
       ORDER BY sync_timestamp DESC
       LIMIT 10`
    );

    connection.release();

    res.json({
      success: true,
      data: {
        total_complaints: complaints.length,
        statistics: stats[0],
        recent_complaints: recent,
        all_complaints: complaints
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch dashboard data",
      error: error.message
    });
  }
};

// Get complaint details with all related info
exports.getComplaintDetailsForAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    // Main complaint details
    const [complaint] = await connection.query(
      `SELECT c.*, 
              u.name as citizen_name, u.email as citizen_email, u.phone as citizen_phone,
              cat.name as category_name, cat.color as category_color,
              loc.city, loc.district, loc.state,
              a.name as assigned_admin_name
       FROM complaints c
       LEFT JOIN users u ON c.user_id = u.id
       LEFT JOIN categories cat ON c.category_id = cat.id
       LEFT JOIN locations loc ON c.location_id = loc.id
       LEFT JOIN admins a ON c.assigned_to = a.id
       WHERE c.id = ?`,
      [id]
    );

    // Get all updates
    const [updates] = await connection.query(
      `SELECT cu.*, a.name as admin_name
       FROM complaint_updates cu
       LEFT JOIN admins a ON cu.updated_by = a.id
       WHERE cu.complaint_id = ?
       ORDER BY cu.created_at DESC`,
      [id]
    );

    // Get ratings
    const [ratings] = await connection.query(
      `SELECT rr.*, u.name as user_name
       FROM ratings_reviews rr
       LEFT JOIN users u ON rr.user_id = u.id
       WHERE rr.complaint_id = ?`,
      [id]
    );

    // Get attachments
    const [attachments] = await connection.query(
      `SELECT * FROM attachments WHERE complaint_id = ?`,
      [id]
    );

    connection.release();

    if (complaint.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found"
      });
    }

    res.json({
      success: true,
      data: {
        complaint: complaint[0],
        updates: updates,
        ratings: ratings,
        attachments: attachments,
        sync_status: {
          synced: complaint[0].synced_to_admin,
          synced_at: complaint[0].sync_timestamp,
          is_draft_submission: complaint[0].is_draft_submission
        }
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch complaint details",
      error: error.message
    });
  }
};

// Get complaints by status (for filtering)
exports.getComplaintsByStatus = async (req, res) => {
  try {
    const { status } = req.params;
    const connection = await pool.getConnection();

    const [complaints] = await connection.query(
      `SELECT * FROM admin_dashboard_complaints
       WHERE status = ? AND synced_to_admin = TRUE
       ORDER BY sync_timestamp DESC`,
      [status]
    );

    connection.release();

    res.json({
      success: true,
      data: complaints,
      total: complaints.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch complaints",
      error: error.message
    });
  }
};

// Get complaints by category
exports.getComplaintsByCategory = async (req, res) => {
  try {
    const { category_id } = req.params;
    const connection = await pool.getConnection();

    const [complaints] = await connection.query(
      `SELECT * FROM admin_dashboard_complaints
       WHERE category_id = ? AND synced_to_admin = TRUE
       ORDER BY sync_timestamp DESC`,
      [category_id]
    );

    connection.release();

    res.json({
      success: true,
      data: complaints,
      total: complaints.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch complaints",
      error: error.message
    });
  }
};

// Get map data for admin dashboard
exports.getMapData = async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [complaints] = await connection.query(
      `SELECT 
        id, complaint_number, title, latitude, longitude, 
        status, priority, category_id, citizen_name
       FROM admin_dashboard_complaints
       WHERE synced_to_admin = TRUE 
       AND latitude IS NOT NULL 
       AND longitude IS NOT NULL`
    );

    connection.release();

    res.json({
      success: true,
      data: complaints,
      total: complaints.length
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch map data",
      error: error.message
    });
  }
};
