-- ============================================
-- ENHANCED CIVICCONNECT DATABASE SCHEMA
-- Draft Support + Real-time Sync
-- ============================================

-- Add DRAFT table for saving incomplete reports
CREATE TABLE IF NOT EXISTS complaint_drafts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255),
  description TEXT,
  category_id INT,
  location_id INT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address VARCHAR(255),
  image_url VARCHAR(255),
  priority ENUM('low', 'medium', 'high', 'urgent'),
  status ENUM('draft', 'auto_saved') DEFAULT 'draft',
  last_saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
);

-- Add column to track real-time sync
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS synced_to_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS sync_timestamp TIMESTAMP NULL;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS is_draft_submission BOOLEAN DEFAULT FALSE;

-- Create VIEW for Admin Dashboard - Real-time updates
CREATE OR REPLACE VIEW admin_dashboard_complaints AS
SELECT 
  c.id,
  c.complaint_number,
  c.title,
  c.description,
  u.name as citizen_name,
  u.email as citizen_email,
  u.phone as citizen_phone,
  cat.name as category,
  loc.city,
  loc.district,
  c.latitude,
  c.longitude,
  c.status,
  c.priority,
  c.created_at,
  c.sync_timestamp,
  a.name as assigned_admin,
  COUNT(cu.id) as total_updates,
  AVG(rr.rating) as avg_rating,
  c.view_count
FROM complaints c
LEFT JOIN users u ON c.user_id = u.id
LEFT JOIN categories cat ON c.category_id = cat.id
LEFT JOIN locations loc ON c.location_id = loc.id
LEFT JOIN admins a ON c.assigned_to = a.id
LEFT JOIN complaint_updates cu ON c.id = cu.complaint_id
LEFT JOIN ratings_reviews rr ON c.id = rr.complaint_id
GROUP BY c.id
ORDER BY c.sync_timestamp DESC;

-- Create trigger to sync complaint to admin when submitted
DELIMITER $$

CREATE TRIGGER sync_complaint_to_admin
AFTER INSERT ON complaints
FOR EACH ROW
BEGIN
  UPDATE complaints 
  SET synced_to_admin = TRUE, sync_timestamp = NOW() 
  WHERE id = NEW.id;
  
  -- Auto-create notification for admins
  INSERT INTO notifications (notification_type, title, message, complaint_id, created_at)
  VALUES (
    'status_update',
    CONCAT('New Complaint: ', NEW.title),
    CONCAT('A new complaint has been submitted - ', NEW.title),
    NEW.id,
    NOW()
  );
END$$

-- Trigger to create notification when status changes
CREATE TRIGGER notify_on_status_change
AFTER UPDATE ON complaints
FOR EACH ROW
BEGIN
  IF NEW.status != OLD.status THEN
    INSERT INTO notifications (user_id, complaint_id, notification_type, title, message)
    VALUES (
      NEW.user_id,
      NEW.id,
      'status_update',
      CONCAT('Complaint Status Updated - ', NEW.status),
      CONCAT('Your complaint (', NEW.complaint_number, ') status has been updated to: ', NEW.status)
    );
  END IF;
END$$

DELIMITER ;

-- ============================================
-- Sample Location Data with Coordinates
-- ============================================

INSERT IGNORE INTO locations (city, state, district, pin_code, coordinates_latitude, coordinates_longitude) VALUES
('Bangalore', 'Karnataka', 'Whitefield', '560066', 12.9698, 77.7499),
('Bangalore', 'Karnataka', 'Indiranagar', '560038', 13.0350, 77.6245),
('Bangalore', 'Karnataka', 'Koramangala', '560034', 12.9352, 77.6245),
('Bangalore', 'Karnataka', 'MG Road', '560001', 13.0350, 77.5905),
('Bangalore', 'Karnataka', 'Jayanagar', '560041', 13.0162, 77.5937),
('Bangalore', 'Karnataka', 'Marathahalli', '560037', 13.0211, 77.6461),
('Bangalore', 'Karnataka', 'Silk Board', '560047', 12.9352, 77.6804),
('Bangalore', 'Karnataka', 'Richmond Town', '560025', 13.0010, 77.5934);

SELECT 'Database schema updated successfully!' as status;
