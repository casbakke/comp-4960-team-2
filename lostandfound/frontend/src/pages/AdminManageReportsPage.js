import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getApprovedReports, markResolved, deleteReport } from "../apiClient";
///manage all approved reports in the system
export default function AdminManageReportsPage() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  async function loadReports() {
    setLoading(true);
    const items = await getApprovedReports();
    setReports(items);
    setLoading(false);
  }

  useEffect(() => {
    loadReports();
  }, []);

  async function handleResolve(id) {
    await markResolved(id);
    loadReports();
  }

  async function handleDelete(id) {
    if (!window.confirm("Are you sure you want to delete this report?")) return;
    await deleteReport(id);
    loadReports();
  }

  if (loading) return <div>Loading...</div>;

  return (
    <div className="page-container">
      <h1 className="page-title">Manage Reports</h1>

      <p>These are all approved reports currently visible in the system.</p>

      <div className="report-grid">
        {reports.map((r) => (
          <div
            key={r.id}
            className="report-card"
            style={{ background: "#d9ecff" }}
          >
            <h3>{r.title}</h3>

            {r.imageUrl && (
              <img
                src={r.imageUrl}
                alt="uploaded"
                className="report-image"
                onClick={() => navigate(`/reports/${r.id}`)}
              />
            )}

            <p>
              <strong>Type:</strong> {r.type}
            </p>
            <p>
              <strong>Location:</strong> {r.locationBuilding || "Not specified"}
            </p>
            <p>
              <strong>Category:</strong> {r.category}
            </p>

            <div className="admin-actions">
              <button onClick={() => handleResolve(r.id)} className="btn green">
                Mark Resolved
              </button>
              <button onClick={() => handleDelete(r.id)} className="btn red">
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
