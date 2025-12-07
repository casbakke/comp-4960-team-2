import React, { useEffect, useState } from "react";
import {
  getPendingReports,
  approveReport,
  denyReport,
  resolveReport,
} from "../apiClient";
import { useNavigate } from "react-router-dom";
/// admin - approve or deny new reports
function AdminApprovePage() {
  const [pending, setPending] = useState([]);
  const [error, setError] = useState("");
  const [busyId, setBusyId] = useState("");
  const navigate = useNavigate();

  async function load() {
    try {
      setError("");
      const data = await getPendingReports();
      setPending(data);
    } catch (err) {
      console.error(err);
      setError(err.message || "Failed to load pending reports");
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleAction(id, action) {
    try {
      setBusyId(id);
      if (action === "approve") await approveReport(id);
      else if (action === "deny") await denyReport(id);
      else if (action === "resolve") await resolveReport(id);
      await load();
    } catch (err) {
      console.error(err);
      setError(err.message || "Failed to update report");
    } finally {
      setBusyId("");
    }
  }

  return (
    <div>
      <h1>Approval Needed</h1>
      <p>Approve or deny new reports submitted by students.</p>
      {error && <div className="error-text">{error}</div>}

      <div className="items-grid">
        {pending.map((r) => (
          <div key={r.id} className="report-card card-lost">
            <div className="report-card-header">
              <strong>{r.title}</strong>
              <span className="report-chip">{r.type}</span>
            </div>
            {r.imageUrl && (
              <img
                src={r.imageUrl}
                alt={r.title}
                style={{
                  width: "100%",
                  maxHeight: 140,
                  objectFit: "cover",
                  borderRadius: 6,
                  marginBottom: 6,
                }}
              />
            )}
            <div style={{ fontSize: 13, marginBottom: 8 }}>
              <div>
                <strong>From:</strong> {r.createdByEmail}
              </div>
              <div>
                <strong>Location:</strong>{" "}
                {r.locationBuilding || "Not specified"}
              </div>
              <div>
                <strong>Category:</strong> {r.category}
              </div>
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <button
                className="btn"
                disabled={busyId === r.id}
                onClick={() => handleAction(r.id, "approve")}
              >
                Approve
              </button>
              <button
                className="btn-outline"
                disabled={busyId === r.id}
                onClick={() => handleAction(r.id, "deny")}
              >
                Deny
              </button>
              <button
                className="btn-outline"
                disabled={busyId === r.id}
                onClick={() => navigate(`/reports/${r.id}`)}
              >
                View details
              </button>
            </div>
          </div>
        ))}
        {!pending.length && <p>No pending reports 🎉</p>}
      </div>
    </div>
  );
}

export default AdminApprovePage;
