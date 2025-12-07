import React, { useEffect, useState, useContext } from "react";
import { useNavigate } from "react-router-dom";
import { getMyReports } from "../apiClient";
import { AuthContext } from "../App";
///list all user reports  
function statusClass(report) {
  if (report.status === "resolved") return "card-resolved";
  if (report.type === "lost") return "card-lost";
  if (report.type === "found") return "card-found";
  return "";
}

function ProfilePage() {
  const { user } = useContext(AuthContext);
  const [reports, setReports] = useState([]);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    (async () => {
      try {
        const data = await getMyReports();
        setReports(data);
      } catch (err) {
        console.error(err);
        setError(err.message || "Failed to load your reports");
      }
    })();
  }, []);

  return (
    <div>
      <h1>Profile</h1>
      <p>Your Wentworth account: {user?.email}</p>

      {error && <div className="error-text">{error}</div>}

      <h3>Your reports</h3>
      <div className="items-grid">
        {reports.map((r) => (
          <div
            key={r.id}
            className={`report-card ${statusClass(r)}`}
            onClick={() => navigate(`/reports/${r.id}`)}
          >
            <div className="report-card-header">
              <strong>{r.title}</strong>
              <span className="report-chip">
                {r.type} · {r.status}
              </span>
            </div>
            <div style={{ fontSize: 13 }}>
              <div>
                <strong>Location:</strong>{" "}
                {r.locationBuilding || "Not specified"}
              </div>
              <div>
                <strong>Category:</strong> {r.category}
              </div>
            </div>
          </div>
        ))}
        {!reports.length && <p>You haven't created any reports yet.</p>}
      </div>
    </div>
  );
}

export default ProfilePage;
