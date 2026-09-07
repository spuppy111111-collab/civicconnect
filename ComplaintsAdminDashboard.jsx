// ============================================
// Components/AdminDashboard/ComplaintsDashboard.jsx
// Admin Dashboard - Real-time Complaint Display
// ============================================

import React, { useState, useEffect } from "react";
import axios from "axios";
import "./ComplaintsDashboard.css";

const API_BASE_URL = "http://localhost:8000/api";

const ComplaintsDashboard = () => {
  const [complaints, setComplaints] = useState([]);
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [filterStatus, setFilterStatus] = useState("all");
  const [filterCategory, setFilterCategory] = useState("all");
  const [statistics, setStatistics] = useState(null);
  const [mapComplaints, setMapComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showMapView, setShowMapView] = useState(false);

  // Fetch dashboard data on component mount and set up polling
  useEffect(() => {
    fetchDashboardData();
    
    // Poll for new complaints every 10 seconds
    const interval = setInterval(fetchDashboardData, 10000);
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin-dashboard`);
      
      if (response.data.success) {
        setComplaints(response.data.data.all_complaints);
        setStatistics(response.data.data.statistics);
        
        // Get map data
        fetchMapData();
      }
    } catch (error) {
      console.error("Error fetching dashboard data:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchMapData = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/admin-dashboard/map-data`);
      if (response.data.success) {
        setMapComplaints(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching map data:", error);
    }
  };

  const fetchComplaintDetails = async (complaintId) => {
    try {
      const response = await axios.get(
        `${API_BASE_URL}/admin-dashboard/complaint/${complaintId}/details`
      );
      if (response.data.success) {
        setSelectedComplaint(response.data.data);
      }
    } catch (error) {
      console.error("Error fetching complaint details:", error);
    }
  };

  // Handle complaint row click
  const handleComplaintClick = (complaint) => {
    fetchComplaintDetails(complaint.id);
  };

  // Filter complaints based on status and category
  const filteredComplaints = complaints.filter(complaint => {
    const statusMatch = filterStatus === "all" || complaint.status === filterStatus;
    const categoryMatch = filterCategory === "all" || complaint.category_id === parseInt(filterCategory);
    return statusMatch && categoryMatch;
  });

  // Get status badge color
  const getStatusBadge = (status) => {
    const statusColors = {
      pending: "🟡 Pending",
      assigned: "🔵 Assigned",
      in_progress: "🟠 In Progress",
      resolved: "🟢 Resolved",
      rejected: "🔴 Rejected",
      closed: "⚪ Closed"
    };
    return statusColors[status] || status;
  };

  // Get priority badge
  const getPriorityBadge = (priority) => {
    const priorityColors = {
      low: "🟢",
      medium: "🟡",
      high: "🔴",
      urgent: "🔴🔴"
    };
    return `${priorityColors[priority] || ""} ${priority}`;
  };

  if (loading) {
    return <div className="admin-dashboard loading">Loading complaints...</div>;
  }

  return (
    <div className="admin-dashboard">
      {/* Header */}
      <div className="dashboard-header">
        <h1>📊 Admin Dashboard - Complaints Management</h1>
        <div className="view-toggle">
          <button
            className={`toggle-btn ${!showMapView ? 'active' : ''}`}
            onClick={() => setShowMapView(false)}
          >
            📋 List View
          </button>
          <button
            className={`toggle-btn ${showMapView ? 'active' : ''}`}
            onClick={() => setShowMapView(true)}
          >
            🗺️ Map View
          </button>
        </div>
      </div>

      {/* Statistics Cards */}
      {statistics && (
        <div className="statistics-container">
          <div className="stat-card">
            <h3>Total Complaints</h3>
            <p className="stat-number">{statistics.total_complaints}</p>
          </div>
          <div className="stat-card pending">
            <h3>Pending</h3>
            <p className="stat-number">{statistics.pending}</p>
          </div>
          <div className="stat-card progress">
            <h3>In Progress</h3>
            <p className="stat-number">{statistics.in_progress}</p>
          </div>
          <div className="stat-card resolved">
            <h3>Resolved</h3>
            <p className="stat-number">{statistics.resolved}</p>
          </div>
        </div>
      )}

      <div className="dashboard-content">
        {!showMapView ? (
          <>
            {/* Filters */}
            <div className="filters-section">
              <div className="filter-group">
                <label>Filter by Status:</label>
                <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
                  <option value="all">All Status</option>
                  <option value="pending">Pending</option>
                  <option value="assigned">Assigned</option>
                  <option value="in_progress">In Progress</option>
                  <option value="resolved">Resolved</option>
                  <option value="rejected">Rejected</option>
                </select>
              </div>

              <div className="filter-group">
                <label>Filter by Category:</label>
                <select value={filterCategory} onChange={(e) => setFilterCategory(e.target.value)}>
                  <option value="all">All Categories</option>
                  <option value="1">Road Damage</option>
                  <option value="2">Street Light</option>
                  <option value="3">Water Supply</option>
                  <option value="4">Sanitation</option>
                </select>
              </div>

              <div className="filter-count">
                Showing {filteredComplaints.length} complaints
              </div>
            </div>

            {/* Complaints Table */}
            <div className="complaints-list">
              <table className="complaints-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Citizen</th>
                    <th>Category</th>
                    <th>Location</th>
                    <th>Status</th>
                    <th>Priority</th>
                    <th>Date</th>
                    <th>Assigned to</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredComplaints.map(complaint => (
                    <tr
                      key={complaint.id}
                      onClick={() => handleComplaintClick(complaint)}
                      className="complaint-row clickable"
                    >
                      <td className="complaint-id">{complaint.complaint_number}</td>
                      <td className="complaint-title">{complaint.title}</td>
                      <td>{complaint.citizen_name}</td>
                      <td>{complaint.category_name}</td>
                      <td>{complaint.city}</td>
                      <td>
                        <span className="status-badge">
                          {getStatusBadge(complaint.status)}
                        </span>
                      </td>
                      <td>{getPriorityBadge(complaint.priority)}</td>
                      <td>{new Date(complaint.created_at).toLocaleDateString()}</td>
                      <td>{complaint.assigned_admin_name || "Unassigned"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        ) : (
          /* Map View */
          <div className="map-view-container">
            <div className="map-legend">
              <h3>📍 Complaints on Map</h3>
              <div className="legend-items">
                <div className="legend-item"><span className="dot pending"></span> Pending</div>
                <div className="legend-item"><span className="dot progress"></span> In Progress</div>
                <div className="legend-item"><span className="dot resolved"></span> Resolved</div>
              </div>
            </div>

            <div className="map-grid">
              {mapComplaints.map(complaint => (
                <div
                  key={complaint.id}
                  className="map-marker"
                  onClick={() => handleComplaintClick(complaint)}
                  title={complaint.title}
                >
                  <div className={`marker-icon ${complaint.status}`}>
                    📍
                  </div>
                  <div className="marker-info">
                    <small>{complaint.complaint_number}</small>
                    <p>{complaint.title}</p>
                    <small>{complaint.citizen_name}</small>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Complaint Details Panel */}
      {selectedComplaint && (
        <div className="details-panel">
          <button className="close-btn" onClick={() => setSelectedComplaint(null)}>✕</button>

          <div className="details-header">
            <h2>{selectedComplaint.complaint.complaint_number}</h2>
            <span className="sync-status">
              {selectedComplaint.sync_status.synced && (
                <span className="synced">✅ Synced from Citizen Dashboard</span>
              )}
            </span>
          </div>

          {/* Complaint Details */}
          <div className="details-content">
            <section className="detail-section">
              <h3>📋 Complaint Details</h3>
              <div className="detail-grid">
                <div className="detail-item">
                  <label>Title</label>
                  <p>{selectedComplaint.complaint.title}</p>
                </div>
                <div className="detail-item">
                  <label>Category</label>
                  <p>{selectedComplaint.complaint.category_name}</p>
                </div>
                <div className="detail-item">
                  <label>Status</label>
                  <p>{getStatusBadge(selectedComplaint.complaint.status)}</p>
                </div>
                <div className="detail-item">
                  <label>Priority</label>
                  <p>{getPriorityBadge(selectedComplaint.complaint.priority)}</p>
                </div>
                <div className="detail-item">
                  <label>Location</label>
                  <p>{selectedComplaint.complaint.city}, {selectedComplaint.complaint.district}</p>
                </div>
                <div className="detail-item">
                  <label>Coordinates</label>
                  <p>
                    {selectedComplaint.complaint.latitude}, {selectedComplaint.complaint.longitude}
                  </p>
                </div>
              </div>

              <div className="detail-item full-width">
                <label>Description</label>
                <p>{selectedComplaint.complaint.description}</p>
              </div>
            </section>

            {/* Citizen Information */}
            <section className="detail-section">
              <h3>👤 Citizen Information</h3>
              <div className="detail-grid">
                <div className="detail-item">
                  <label>Name</label>
                  <p>{selectedComplaint.complaint.citizen_name}</p>
                </div>
                <div className="detail-item">
                  <label>Email</label>
                  <p>{selectedComplaint.complaint.citizen_email}</p>
                </div>
                <div className="detail-item">
                  <label>Phone</label>
                  <p>{selectedComplaint.complaint.citizen_phone}</p>
                </div>
              </div>
            </section>

            {/* Updates */}
            {selectedComplaint.updates.length > 0 && (
              <section className="detail-section">
                <h3>📝 Updates</h3>
                <div className="updates-list">
                  {selectedComplaint.updates.map(update => (
                    <div key={update.id} className="update-item">
                      <small>{new Date(update.created_at).toLocaleString()}</small>
                      <p><strong>{update.admin_name}</strong>: {update.message}</p>
                      {update.old_status && (
                        <small>Status: {update.old_status} → {update.new_status}</small>
                      )}
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Ratings */}
            {selectedComplaint.ratings.length > 0 && (
              <section className="detail-section">
                <h3>⭐ Ratings & Reviews</h3>
                <div className="ratings-list">
                  {selectedComplaint.ratings.map(rating => (
                    <div key={rating.id} className="rating-item">
                      <p><strong>{rating.user_name}</strong> - Rating: ⭐ {rating.rating}/5</p>
                      <p>{rating.review_text}</p>
                    </div>
                  ))}
                </div>
              </section>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default ComplaintsDashboard;
