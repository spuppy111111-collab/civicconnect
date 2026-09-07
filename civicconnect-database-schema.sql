-- ============================================
-- CivicConnect Complete Database Schema
-- ============================================

-- Create Database
CREATE DATABASE IF NOT EXISTS civicconnect;
USE civicconnect;

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  zip_code VARCHAR(10),
  profile_picture VARCHAR(255),
  role ENUM('citizen', 'admin') DEFAULT 'citizen',
  is_verified BOOLEAN DEFAULT FALSE,
  verification_token VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login TIMESTAMP NULL,
  is_active BOOLEAN DEFAULT TRUE,
  INDEX idx_email (email),
  INDEX idx_role (role)
);

-- ============================================
-- 2. ADMINS TABLE
-- ============================================
CREATE TABLE admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  department VARCHAR(100),
  role ENUM('super_admin', 'department_admin', 'moderator') DEFAULT 'department_admin',
  permissions JSON,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by INT,
  INDEX idx_email (email),
  INDEX idx_role (role)
);

-- ============================================
-- 3. CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(255),
  color VARCHAR(7),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name)
);

-- ============================================
-- 4. LOCATIONS TABLE
-- ============================================
CREATE TABLE locations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  district VARCHAR(100),
  pin_code VARCHAR(10),
  coordinates_latitude DECIMAL(10, 8),
  coordinates_longitude DECIMAL(11, 8),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_city (city),
  INDEX idx_state (state),
  UNIQUE KEY unique_location (city, state, district)
);

-- ============================================
-- 5. COMPLAINTS TABLE
-- ============================================
CREATE TABLE complaints (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_number VARCHAR(20) UNIQUE NOT NULL,
  user_id INT NOT NULL,
  category_id INT NOT NULL,
  location_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  image_url VARCHAR(255),
  status ENUM('pending', 'assigned', 'in_progress', 'resolved', 'rejected', 'closed') DEFAULT 'pending',
  priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
  assigned_to INT,
  severity_level ENUM('minor', 'major', 'critical') DEFAULT 'minor',
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  view_count INT DEFAULT 0,
  is_anonymous BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (location_id) REFERENCES locations(id),
  FOREIGN KEY (assigned_to) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_category_id (category_id),
  INDEX idx_location_id (location_id),
  INDEX idx_created_at (created_at),
  INDEX idx_complaint_number (complaint_number)
);

-- ============================================
-- 6. COMPLAINT_UPDATES TABLE
-- ============================================
CREATE TABLE complaint_updates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id INT NOT NULL,
  updated_by INT,
  update_type ENUM('status_change', 'assignment', 'comment', 'resolution') DEFAULT 'comment',
  message TEXT NOT NULL,
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  image_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (updated_by) REFERENCES admins(id) ON DELETE SET NULL,
  INDEX idx_complaint_id (complaint_id),
  INDEX idx_created_at (created_at)
);

-- ============================================
-- 7. RATINGS_REVIEWS TABLE
-- ============================================
CREATE TABLE ratings_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id INT NOT NULL,
  user_id INT NOT NULL,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  is_helpful BOOLEAN DEFAULT FALSE,
  helpful_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_review (complaint_id, user_id),
  INDEX idx_complaint_id (complaint_id),
  INDEX idx_rating (rating)
);

-- ============================================
-- 8. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  admin_id INT,
  complaint_id INT,
  notification_type ENUM('status_update', 'new_comment', 'complaint_assigned', 'system_alert') DEFAULT 'status_update',
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_admin_id (admin_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at)
);

-- ============================================
-- 9. ACTIVITY_LOG TABLE
-- ============================================
CREATE TABLE activity_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  admin_id INT,
  action_type VARCHAR(100) NOT NULL,
  action_description TEXT,
  complaint_id INT,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE SET NULL,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_admin_id (admin_id),
  INDEX idx_created_at (created_at)
);

-- ============================================
-- 10. STATISTICS TABLE
-- ============================================
CREATE TABLE statistics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date_recorded DATE NOT NULL UNIQUE,
  total_complaints INT DEFAULT 0,
  pending_complaints INT DEFAULT 0,
  resolved_complaints INT DEFAULT 0,
  average_resolution_time INT,
  total_users INT DEFAULT 0,
  active_users INT DEFAULT 0,
  new_complaints_today INT DEFAULT 0,
  category_breakdown JSON,
  status_breakdown JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_date_recorded (date_recorded)
);

-- ============================================
-- 11. ATTACHMENTS TABLE
-- ============================================
CREATE TABLE attachments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id INT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(255) NOT NULL,
  file_type VARCHAR(50),
  file_size INT,
  uploaded_by INT,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_complaint_id (complaint_id)
);

-- ============================================
-- 12. PERFORMANCE_METRICS TABLE
-- ============================================
CREATE TABLE performance_metrics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  month_year DATE NOT NULL,
  complaints_handled INT DEFAULT 0,
  complaints_resolved INT DEFAULT 0,
  average_resolution_time INT,
  user_satisfaction_score DECIMAL(3, 2),
  efficiency_rating DECIMAL(3, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
  UNIQUE KEY unique_metric (admin_id, month_year),
  INDEX idx_admin_id (admin_id)
);

-- ============================================
-- INSERT SAMPLE DATA
-- ============================================

-- Sample Categories
INSERT INTO categories (name, description, color) VALUES
('Road Damage', 'Issues related to damaged roads and potholes', '#FF6B6B'),
('Street Light', 'Problems with street lighting and maintenance', '#FFD93D'),
('Water Supply', 'Water pipeline and supply issues', '#6BCB77'),
('Sanitation', 'Cleanliness and waste management complaints', '#4D96FF'),
('Public Safety', 'Safety and security concerns', '#FF7C7C'),
('Traffic', 'Traffic management and signage issues', '#95E1D3'),
('Park Maintenance', 'Issues with public parks and gardens', '#FFBE9F'),
('Noise Pollution', 'Noise-related complaints', '#FFC0CB');

-- Sample Locations
INSERT INTO locations (city, state, district, pin_code) VALUES
('Bangalore', 'Karnataka', 'Central', '560001'),
('Bangalore', 'Karnataka', 'North', '560009'),
('Bangalore', 'Karnataka', 'South', '560004'),
('Bangalore', 'Karnataka', 'East', '560001'),
('Bangalore', 'Karnataka', 'West', '560015');

-- Sample Admin User
INSERT INTO admins (name, email, password, phone, department, role) VALUES
('Admin User', 'admin@civicconnect.com', '$2a$10$encryptedpasswordhere', '9876543210', 'Public Works', 'super_admin');

-- ============================================
-- CREATE TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================

DELIMITER $$

-- Trigger to update complaint_number automatically
CREATE TRIGGER set_complaint_number
BEFORE INSERT ON complaints
FOR EACH ROW
BEGIN
  SET NEW.complaint_number = CONCAT('CC', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(NEW.id + 10000, 6, '0'));
END$$

-- Trigger to update statistics when complaint is created
CREATE TRIGGER update_stats_on_complaint_insert
AFTER INSERT ON complaints
FOR EACH ROW
BEGIN
  INSERT INTO statistics (date_recorded, total_complaints, new_complaints_today)
  VALUES (CURDATE(), 1, 1)
  ON DUPLICATE KEY UPDATE
    total_complaints = total_complaints + 1,
    new_complaints_today = new_complaints_today + 1;
END$$

-- Trigger to update statistics when complaint status changes
CREATE TRIGGER update_stats_on_complaint_update
AFTER UPDATE ON complaints
FOR EACH ROW
BEGIN
  IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
    INSERT INTO statistics (date_recorded, resolved_complaints)
    VALUES (CURDATE(), 1)
    ON DUPLICATE KEY UPDATE
      resolved_complaints = resolved_complaints + 1;
  END IF;
END$$

DELIMITER ;

-- ============================================
-- CREATE VIEWS FOR REPORTING
-- ============================================

-- View: Complaints Summary
CREATE VIEW complaints_summary AS
SELECT
  c.id,
  c.complaint_number,
  c.title,
  u.name as submitted_by,
  cat.name as category,
  loc.city,
  c.status,
  c.priority,
  c.created_at,
  DATEDIFF(NOW(), c.created_at) as days_open
FROM complaints c
JOIN users u ON c.user_id = u.id
JOIN categories cat ON c.category_id = cat.id
JOIN locations loc ON c.location_id = loc.id;

-- View: Admin Performance
CREATE VIEW admin_performance AS
SELECT
  a.id,
  a.name,
  a.email,
  a.department,
  COUNT(c.id) as total_complaints_handled,
  SUM(CASE WHEN c.status = 'resolved' THEN 1 ELSE 0 END) as resolved_complaints,
  AVG(DATEDIFF(IFNULL(c.resolved_at, NOW()), c.created_at)) as avg_resolution_days,
  AVG(r.rating) as average_rating
FROM admins a
LEFT JOIN complaints c ON a.id = c.assigned_to
LEFT JOIN ratings_reviews r ON c.id = r.complaint_id
GROUP BY a.id, a.name, a.email, a.department;

-- View: Category Statistics
CREATE VIEW category_statistics AS
SELECT
  cat.name as category,
  COUNT(c.id) as total_complaints,
  SUM(CASE WHEN c.status = 'pending' THEN 1 ELSE 0 END) as pending,
  SUM(CASE WHEN c.status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
  SUM(CASE WHEN c.status = 'resolved' THEN 1 ELSE 0 END) as resolved,
  AVG(DATEDIFF(IFNULL(c.resolved_at, NOW()), c.created_at)) as avg_resolution_days
FROM categories cat
LEFT JOIN complaints c ON cat.id = c.category_id
GROUP BY cat.id, cat.name;

SHOW TABLES;
SHOW DATABASES;

-- ============================================
-- END OF CIVICCONNECT DATABASE SCHEMA
-- ============================================
