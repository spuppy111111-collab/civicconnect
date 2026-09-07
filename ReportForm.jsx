// ============================================
// Components/ReportProblem/ReportForm.jsx
// Citizen Dashboard - Report Problem with Auto-save
// ============================================

import React, { useState, useEffect, useCallback } from "react";
import axios from "axios";
import "./ReportForm.css";

const API_BASE_URL = "http://localhost:8000/api";

const ReportForm = ({ userId }) => {
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    category_id: null,
    location_id: null,
    latitude: null,
    longitude: null,
    address: "",
    image_url: "",
    priority: "medium"
  });

  const [categories, setCategories] = useState([]);
  const [locations, setLocations] = useState([]);
  const [draftId, setDraftId] = useState(null);
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState(null);
  const [showMap, setShowMap] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Fetch categories
  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/categories`);
        setCategories(response.data.data);
      } catch (error) {
        console.error("Error fetching categories:", error);
      }
    };
    fetchCategories();
  }, []);

  // Fetch locations
  useEffect(() => {
    const fetchLocations = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/geolocation/all`);
        setLocations(response.data.data);
      } catch (error) {
        console.error("Error fetching locations:", error);
      }
    };
    fetchLocations();
  }, []);

  // Load draft on component mount
  useEffect(() => {
    const loadDraft = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/drafts/${userId}`);
        if (response.data.data) {
          setFormData(response.data.data);
          setDraftId(response.data.data.id);
        }
      } catch (error) {
        console.error("Error loading draft:", error);
      }
    };
    loadDraft();
  }, [userId]);

  // Auto-save draft every 30 seconds
  useEffect(() => {
    const autoSaveInterval = setInterval(() => {
      if (formData.title || formData.description) {
        autoSaveDraft();
      }
    }, 30000); // Auto-save every 30 seconds

    return () => clearInterval(autoSaveInterval);
  }, [formData]);

  // Auto-save draft function
  const autoSaveDraft = useCallback(async () => {
    if (!userId) return;

    setIsSaving(true);
    try {
      const response = await axios.post(`${API_BASE_URL}/drafts/auto-save`, {
        user_id: userId,
        ...formData
      });

      if (response.data.data) {
        setDraftId(response.data.data.draftId);
      }
      setLastSaved(new Date());
    } catch (error) {
      console.error("Error auto-saving draft:", error);
    } finally {
      setIsSaving(false);
    }
  }, [formData, userId]);

  // Handle form input change
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // Handle location selection from map
  const handleLocationSelect = (location) => {
    setFormData(prev => ({
      ...prev,
      location_id: location.id,
      latitude: location.coordinates_latitude,
      longitude: location.coordinates_longitude,
      address: `${location.district}, ${location.city} - ${location.pin_code}`
    }));
    setSelectedLocation(location);
    setShowMap(false);
  };

  // Detect location from current coordinates
  const handleDetectLocation = async () => {
    try {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          async (position) => {
            const { latitude, longitude } = position.coords;
            
            try {
              const response = await axios.post(`${API_BASE_URL}/geolocation/detect`, {
                latitude,
                longitude
              });

              if (response.data.success) {
                const location = response.data.data;
                handleLocationSelect(location);
                alert(`✅ Location detected: ${location.district}, ${location.city}`);
              }
            } catch (error) {
              console.error("Error detecting location:", error);
              alert("❌ Could not detect your exact location. Please select from map.");
            }
          },
          (error) => {
            console.error("Geolocation error:", error);
            alert("Please enable location services");
          }
        );
      }
    } catch (error) {
      console.error("Error:", error);
    }
  };

  // Handle image upload
  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (file) {
      // In production, upload to cloud storage (AWS S3, GCS, etc.)
      const reader = new FileReader();
      reader.onload = (event) => {
        setFormData(prev => ({
          ...prev,
          image_url: event.target.result
        }));
      };
      reader.readAsDataURL(file);
    }
  };

  // Submit complaint
  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.title || !formData.description || !formData.category_id) {
      alert("Please fill in all required fields");
      return;
    }

    setIsSubmitting(true);
    try {
      // First, submit draft as complaint
      const response = await axios.post(`${API_BASE_URL}/drafts/submit`, {
        draft_id: draftId,
        user_id: userId
      });

      if (response.data.success) {
        alert(`✅ Complaint submitted successfully!
        
Complaint ID: ${response.data.complaintId}
Your complaint has been sent to the admin dashboard.`);

        // Reset form
        setFormData({
          title: "",
          description: "",
          category_id: null,
          location_id: null,
          latitude: null,
          longitude: null,
          address: "",
          image_url: "",
          priority: "medium"
        });
        setDraftId(null);
        setLastSaved(null);
      }
    } catch (error) {
      console.error("Error submitting complaint:", error);
      alert("❌ Error submitting complaint. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle save as draft
  const handleSaveDraft = () => {
    autoSaveDraft();
    alert("✅ Draft saved successfully!");
  };

  return (
    <div className="report-form-container">
      <div className="form-header">
        <h2>📝 Report a Problem</h2>
        <div className="auto-save-status">
          {isSaving && <span className="saving">💾 Saving...</span>}
          {lastSaved && !isSaving && (
            <span className="saved">✅ Last saved: {lastSaved.toLocaleTimeString()}</span>
          )}
        </div>
      </div>

      <form onSubmit={handleSubmit} className="report-form">
        {/* Problem Title */}
        <div className="form-group">
          <label htmlFor="title">Problem Title *</label>
          <input
            type="text"
            id="title"
            name="title"
            value={formData.title}
            onChange={handleInputChange}
            placeholder="e.g., Road Damage, Water Leak"
            required
          />
        </div>

        {/* Problem Description */}
        <div className="form-group">
          <label htmlFor="description">Detailed Description *</label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            placeholder="Describe the problem in detail..."
            rows="4"
            required
          />
        </div>

        {/* Category Selection */}
        <div className="form-group">
          <label htmlFor="category_id">Category *</label>
          <select
            id="category_id"
            name="category_id"
            value={formData.category_id || ""}
            onChange={handleInputChange}
            required
          >
            <option value="">Select a category</option>
            {categories.map(cat => (
              <option key={cat.id} value={cat.id}>{cat.name}</option>
            ))}
          </select>
        </div>

        {/* Priority Level */}
        <div className="form-group">
          <label htmlFor="priority">Priority Level</label>
          <select
            id="priority"
            name="priority"
            value={formData.priority}
            onChange={handleInputChange}
          >
            <option value="low">🟢 Low</option>
            <option value="medium">🟡 Medium</option>
            <option value="high">🔴 High</option>
            <option value="urgent">🔴🔴 Urgent</option>
          </select>
        </div>

        {/* Location Selection */}
        <div className="form-group">
          <label htmlFor="location">Location *</label>
          <div className="location-input-group">
            <input
              type="text"
              id="location"
              value={formData.address || ""}
              placeholder="Selected location will appear here"
              readOnly
              className="location-input"
            />
            <button
              type="button"
              className="btn btn-secondary"
              onClick={handleDetectLocation}
              title="Auto-detect your current location"
            >
              📍 Auto-Detect
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => setShowMap(!showMap)}
            >
              🗺️ Select on Map
            </button>
          </div>
        </div>

        {/* Map Location Selector */}
        {showMap && (
          <div className="location-map-container">
            <div className="location-grid">
              {locations.map(location => (
                <div
                  key={location.id}
                  className={`location-card ${selectedLocation?.id === location.id ? 'selected' : ''}`}
                  onClick={() => handleLocationSelect(location)}
                >
                  <h4>{location.district}</h4>
                  <p>{location.city}</p>
                  <small>📍 {location.pin_code}</small>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Image Upload */}
        <div className="form-group">
          <label htmlFor="image">Upload Photo</label>
          <input
            type="file"
            id="image"
            accept="image/*"
            onChange={handleImageUpload}
            className="file-input"
          />
          {formData.image_url && (
            <div className="image-preview">
              <img src={formData.image_url} alt="Preview" />
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="form-actions">
          <button
            type="button"
            className="btn btn-draft"
            onClick={handleSaveDraft}
            disabled={isSaving}
          >
            💾 Save Draft
          </button>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={isSubmitting}
          >
            {isSubmitting ? "Submitting..." : "🚀 Submit Complaint"}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ReportForm;
