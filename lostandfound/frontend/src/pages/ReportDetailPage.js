import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { getReportById } from "../apiClient";
///detailed view for reports in main screen and admin view 
function formatDate(ms) {
  if (!ms) return "—";
  return new Date(ms).toLocaleString();
}

function ReportDetailPage() {
  const { id } = useParams();
  const [report, setReport] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    (async () => {
      try {
        const data = await getReportById(id);
        setReport(data);
      } catch (err) {
        console.error(err);
        setError(err.message || "Failed to load report");
      }
    })();
  }, [id]);

  if (error) return <div className="error-text">{error}</div>;
  if (!report) return <div>Loading report...</div>;

  return (
    <div className="form-card">
      <h2 className="section-title">{report.title}</h2>
      {report.imageUrl && (
        <img
          src={report.imageUrl}
          alt={report.title}
          style={{
            width: "100%",
            maxHeight: 260,
            objectFit: "cover",
            borderRadius: 8,
            marginBottom: 12,
          }}
        />
      )}

      <p>
        <strong>Type:</strong> {report.type === "lost" ? "Lost" : "Found"}
      </p>
      <p>
        <strong>Status:</strong> {report.status}
      </p>
      <p>
        <strong>Category:</strong> {report.category}
      </p>
      <p>
        <strong>Location:</strong>{" "}
        {report.locationBuilding || "Not specified"}
      </p>
      {report.locationCoordinates && (
        <p>
          <strong>Coordinates:</strong>{" "}
          {report.locationCoordinates.lat}, {report.locationCoordinates.lng}
        </p>
      )}
      {report.description && (
        <p>
          <strong>Description:</strong> {report.description}
        </p>
      )}
      <p>
        <strong>Reported by:</strong>{" "}
        {report.createdByName || report.createdByEmail}
      </p>
      <p>
        <strong>Contact email:</strong> {report.createdByEmail}
      </p>
      {report.createdByPhone && (
        <p>
          <strong>Phone:</strong> {report.createdByPhone}
        </p>
      )}
      <p>
        <strong>Created:</strong> {formatDate(report.createdAt)}
      </p>
      {report.reviewedAt && (
        <p>
          <strong>Reviewed:</strong> {formatDate(report.reviewedAt)} by{" "}
          {report.reviewedBy || "admin"}
        </p>
      )}
    </div>
  );
}

export default ReportDetailPage;
