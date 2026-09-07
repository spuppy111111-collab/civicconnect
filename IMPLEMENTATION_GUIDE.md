# 🚀 CivicConnect Complete Implementation Guide

## Part 1: Set Up MySQL Database Schema

### Step 1: Open MySQL Workbench

1. Launch **MySQL Workbench**
2. Click on your **MySQL connection**
3. Enter your password if prompted

### Step 2: Execute the Database Schema

1. Open a new query window: **File → New Query Tab**
2. Copy the entire content from `civicconnect-database-schema.sql`
3. Paste into the query editor
4. Click **Execute All** (or press `Ctrl + Shift + Enter`)

✅ You should see all tables created successfully!

---

## Part 2: Update Your Node.js Backend

### Step 1: Update `.env` File

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=civicconnect
DB_PORT=3306

# Server Configuration
PORT=8000
NODE_ENV=development

# JWT Secret (for authentication)
JWT_SECRET=your_super_secret_jwt_key_here_change_this

# CORS Settings
CORS_ORIGIN=http://localhost:3000
```

---

## Part 2: Create Backend Structure

### Create folders in your `backend` directory:

```
backend/
├── .env
├── .gitignore
├── package.json
├── server.js
│
├── config/
│   └── database.js
│
├── routes/
│   ├── auth.routes.js
│   ├── complaints.routes.js
│   ├── admin.routes.js
│   └── users.routes.js
│
├── controllers/
│   ├── auth.controller.js
│   ├── complaints.controller.js
│   ├── admin.controller.js
│   └── users.controller.js
│
├── middleware/
│   ├── auth.middleware.js
│   └── errorHandler.js
│
└── utils/
    └── responseFormatter.js
```

### Create `config/database.js`:

```javascript
const mysql = require("mysql2/promise");
require("dotenv").config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
```

### Update `server.js` with CORS fix:

```javascript
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();

// CORS Configuration - Fix the error you're seeing
app.use(cors({
  origin: process.env.CORS_ORIGIN || "http://localhost:3000",
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  credentials: true,
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const authRoutes = require("./routes/auth.routes");
const complaintRoutes = require("./routes/complaints.routes");
const adminRoutes = require("./routes/admin.routes");
const userRoutes = require("./routes/users.routes");

// Use routes
app.use("/api/auth", authRoutes);
app.use("/api/complaints", complaintRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/users", userRoutes);

// Test route
app.get("/", (req, res) => {
  res.json({ message: "🚀 CivicConnect API is running!" });
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "✅ Server healthy" });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error: process.env.NODE_ENV === "development" ? err.message : null
  });
});

// Start server
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`🚀 CivicConnect API running on port ${PORT}`);
  console.log(`✅ CORS enabled for: ${process.env.CORS_ORIGIN}`);
});
```

---

## Part 3: Create API Controllers & Routes

### `controllers/complaints.controller.js`:

```javascript
const pool = require("../config/database");

// Get all complaints
exports.getAllComplaints = async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [complaints] = await connection.query(
      `SELECT c.*, u.name, u.email, cat.name as category, loc.city
       FROM complaints c
       JOIN users u ON c.user_id = u.id
       JOIN categories cat ON c.category_id = cat.id
       JOIN locations loc ON c.location_id = loc.id
       ORDER BY c.created_at DESC`
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

// Create complaint
exports.createComplaint = async (req, res) => {
  try {
    const { user_id, category_id, location_id, title, description, priority } = req.body;

    if (!user_id || !category_id || !location_id || !title || !description) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields"
      });
    }

    const connection = await pool.getConnection();
    const [result] = await connection.query(
      `INSERT INTO complaints (user_id, category_id, location_id, title, description, priority)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [user_id, category_id, location_id, title, description, priority || "medium"]
    );
    connection.release();

    res.status(201).json({
      success: true,
      message: "Complaint created successfully",
      complaintId: result.insertId
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to create complaint",
      error: error.message
    });
  }
};

// Get complaint by ID
exports.getComplaintById = async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    const [complaints] = await connection.query(
      `SELECT c.*, u.name, u.email, cat.name as category, loc.city
       FROM complaints c
       JOIN users u ON c.user_id = u.id
       JOIN categories cat ON c.category_id = cat.id
       JOIN locations loc ON c.location_id = loc.id
       WHERE c.id = ?`,
      [id]
    );

    // Get updates for this complaint
    const [updates] = await connection.query(
      `SELECT * FROM complaint_updates WHERE complaint_id = ? ORDER BY created_at DESC`,
      [id]
    );

    connection.release();

    if (complaints.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found"
      });
    }

    res.json({
      success: true,
      data: complaints[0],
      updates: updates
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch complaint",
      error: error.message
    });
  }
};

// Update complaint status
exports.updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_id, message } = req.body;

    if (!status || !admin_id) {
      return res.status(400).json({
        success: false,
        message: "Status and admin_id are required"
      });
    }

    const connection = await pool.getConnection();

    // Get old status
    const [oldComplaint] = await connection.query(
      "SELECT status FROM complaints WHERE id = ?",
      [id]
    );

    // Update complaint
    await connection.query(
      "UPDATE complaints SET status = ?, assigned_to = ? WHERE id = ?",
      [status, admin_id, id]
    );

    // Add update record
    await connection.query(
      `INSERT INTO complaint_updates (complaint_id, updated_by, update_type, message, old_status, new_status)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, admin_id, "status_change", message || "", oldComplaint[0].status, status]
    );

    connection.release();

    res.json({
      success: true,
      message: "Complaint status updated successfully"
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to update complaint",
      error: error.message
    });
  }
};

// Get complaints by user
exports.getUserComplaints = async (req, res) => {
  try {
    const { user_id } = req.params;
    const connection = await pool.getConnection();
    
    const [complaints] = await connection.query(
      `SELECT c.*, cat.name as category, loc.city
       FROM complaints c
       JOIN categories cat ON c.category_id = cat.id
       JOIN locations loc ON c.location_id = loc.id
       WHERE c.user_id = ?
       ORDER BY c.created_at DESC`,
      [user_id]
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
      message: "Failed to fetch user complaints",
      error: error.message
    });
  }
};
```

### `routes/complaints.routes.js`:

```javascript
const express = require("express");
const router = express.Router();
const complaintController = require("../controllers/complaints.controller");

// Public routes
router.get("/", complaintController.getAllComplaints);
router.post("/", complaintController.createComplaint);
router.get("/:id", complaintController.getComplaintById);

// User routes
router.get("/user/:user_id", complaintController.getUserComplaints);

// Admin routes
router.put("/:id/status", complaintController.updateComplaintStatus);

module.exports = router;
```

---

## Part 4: Install Updated Dependencies

```bash
npm install bcryptjs jsonwebtoken
```

---

## Part 5: Test Your API

### Using Thunder Client (VS Code Extension):

1. Create new request
2. Method: **POST**
3. URL: `http://localhost:8000/api/complaints`
4. Headers:
   ```
   Content-Type: application/json
   ```
5. Body:
   ```json
   {
     "user_id": 1,
     "category_id": 1,
     "location_id": 1,
     "title": "Road Damage on Main Street",
     "description": "There's a large pothole causing traffic issues",
     "priority": "high"
   }
   ```

6. Click **Send**

✅ You should get a success response!

---

## Part 6: Start Your Backend

```bash
node server.js
```

You should see:
```
🚀 CivicConnect API running on port 8000
✅ CORS enabled for: http://localhost:3000
```

---

## Part 7: Update Frontend API Calls

In your React frontend, change all API calls from `localhost:8000` to use the correct endpoint:

```javascript
const API_BASE_URL = "http://localhost:8000/api";

// Get all complaints
const getComplaints = async () => {
  const response = await fetch(`${API_BASE_URL}/complaints`);
  const data = await response.json();
  return data.data;
};

// Create complaint
const createComplaint = async (complaintData) => {
  const response = await fetch(`${API_BASE_URL}/complaints`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(complaintData)
  });
  return await response.json();
};

// Get complaint by ID
const getComplaintById = async (id) => {
  const response = await fetch(`${API_BASE_URL}/complaints/${id}`);
  return await response.json();
};
```

---

## ✅ Next Steps

1. ✅ Create database schema in MySQL Workbench
2. ✅ Set up backend folder structure
3. ✅ Update `.env` file with correct credentials
4. ✅ Run `node server.js` in backend folder
5. ✅ Test API endpoints with Thunder Client
6. ✅ Update React frontend API calls
7. ⏭️ Create authentication system (login/signup)
8. ⏭️ Implement admin dashboard
9. ⏭️ Add user notifications
10. ⏭️ Deploy to production

---

## 📊 Database Diagram

```
┌─────────────────────────────────────────┐
│           CIVICCONNECT DB               │
└─────────────────────────────────────────┘
          │
    ┌─────┼─────┬──────────┐
    │     │     │          │
 USERS ADMINS CATEGORIES LOCATIONS
    │     │     │          │
    └─────┼─────┴──────────┘
          │
      COMPLAINTS
        │   │
        ├───┴─────────────────┐
        │                     │
  COMPLAINT_UPDATES   RATINGS_REVIEWS
        │
   NOTIFICATIONS
        │
   ACTIVITY_LOG
        │
   ATTACHMENTS
```

---

## 🎯 Key Tables

| Table | Purpose |
|-------|---------|
| `users` | Store citizen information |
| `admins` | Store admin/staff information |
| `complaints` | Main complaints data |
| `categories` | Complaint types (Road, Water, etc) |
| `locations` | Cities and areas |
| `complaint_updates` | Track status changes |
| `ratings_reviews` | User feedback |
| `notifications` | Send alerts to users/admins |
| `activity_log` | Audit trail |
| `statistics` | Dashboard metrics |

---

**🚀 Your CivicConnect application is now ready to handle real citizen complaints!**
