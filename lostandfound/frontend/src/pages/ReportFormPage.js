import React, { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { createReport } from "../apiClient";
import { uploadReportImage } from "../firebaseClient";
///page for students to submit new lost or found item reports

const CATEGORY_OPTIONS = [
  "Wallet/ID/Keys",
  "Electronics",
  "Clothing & Apparel",
  "Academic Materials",
  "Bags",
  "Other",
];

function ReportFormPage() {
  const { type } = useParams(); 
  const navigate = useNavigate();

  const [form, setForm] = useState({
    title: "",
    description: "",
    category: "",
    locationBuilding: "",
    createdByPhone: "",
    lat: "",
    lng: "",
  });
  const [imageFile, setImageFile] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  const friendlyType = type === "found" ? "Found" : "Lost";

  function handleChange(e) {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");

    if (!form.title || !form.category) {
      setError("Title and category are required.");
      return;
    }

    if (!["lost", "found"].includes(type)) {
      setError("Invalid report type.");
      return;
    }

    try {
      setSubmitting(true);

      let imageUrl = "";
      if (imageFile) {
        imageUrl = await uploadReportImage(
          imageFile,
          `${Date.now()}-${imageFile.name}`
        );
      }

      const payload = {
        type,
        title: form.title,
        description: form.description,
        category: form.category,
        locationBuilding: form.locationBuilding,
        createdByPhone: form.createdByPhone,
        imageUrl,
      };

      if (form.lat && form.lng) {
        const lat = parseFloat(form.lat);
        const lng = parseFloat(form.lng);
        if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
          payload.locationCoordinates = { lat, lng };
        }
      }

      await createReport(payload);

      alert(
        "Report submitted! It will appear on the main page after an admin approves it."
      );
      navigate("/items");
    } catch (err) {
      console.error(err);
      setError(err.message || "Failed to submit report");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="form-card">
      <h2 className="section-title">Report {friendlyType} Item</h2>
      <form className="form-grid" onSubmit={handleSubmit}>
        <div className="form-row">
          <label>Item title *</label>
          <input
            name="title"
            value={form.title}
            onChange={handleChange}
            placeholder="E.g., Black Lenovo laptop"
          />
        </div>

        <div className="form-row">
          <label>Category *</label>
          <select
            name="category"
            value={form.category}
            onChange={handleChange}
          >
            <option value="">Select a category</option>
            {CATEGORY_OPTIONS.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>

        <div className="form-row">
          <label>Description (optional)</label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            placeholder="Extra details like color, stickers, etc."
          />
        </div>

        <div className="form-row">
          <label>Building / location (optional)</label>
          <input
            name="locationBuilding"
            value={form.locationBuilding}
            onChange={handleChange}
            placeholder="E.g., Dobbs Hall 2nd floor lobby"
          />
        </div>

        <div className="form-row">
          <label>Phone number (optional)</label>
          <input
            name="createdByPhone"
            value={form.createdByPhone}
            onChange={handleChange}
            placeholder="1234567890"
          />
        </div>

        <div className="form-row">
          <label>Map coordinates (optional)</label>
          <div style={{ display: "flex", gap: 8 }}>
            <input
              type="number"
              step="0.000001"
              name="lat"
              value={form.lat}
              onChange={handleChange}
              placeholder="Latitude"
            />
            <input
              type="number"
              step="0.000001"
              name="lng"
              value={form.lng}
              onChange={handleChange}
              placeholder="Longitude"
            />
          </div>
          <small style={{ fontSize: 11, color: "#555" }}>
            If you know it, paste a lat/lng pair from a map.
          </small>
        </div>

        <div className="form-row">
          <label>Item image (optional)</label>
          <input
            type="file"
            accept="image/*"
            onChange={(e) => setImageFile(e.target.files[0] || null)}
          />
        </div>

        {error && <div className="error-text">{error}</div>}

        <div style={{ marginTop: 8, display: "flex", gap: 8 }}>
          <button className="btn" type="submit" disabled={submitting}>
            {submitting ? "Submitting..." : "Submit report"}
          </button>
          <button
            type="button"
            className="btn-outline"
            onClick={() => navigate("/items")}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

export default ReportFormPage;
