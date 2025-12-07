import React, { useEffect, useState, useContext } from "react";
import { useNavigate } from "react-router-dom";
import { searchItems } from "../apiClient";
import { AuthContext } from "../App";

function statusClass(report) {
  if (report.status === "resolved") return "card-resolved";
  if (report.type === "lost") return "card-lost";
  if (report.type === "found") return "card-found";
  return "";
}
///Main items page for viewing found items and searching through them.
function ItemsPage() {
  const { me } = useContext(AuthContext);
  const [query, setQuery] = useState("");
  const [items, setItems] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  async function load(q = "") {
    try {
      setLoading(true);
      setError("");
      const data = await searchItems(q);
      setItems(data);
    } catch (err) {
      console.error(err);
      setError(err.message || "Failed to load items");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  function handleSearch(e) {
    e.preventDefault();
    load(query);
  }

  return (
    <div>
      <div className="items-header">
        <div className="items-header-left">
          <h1>Found Items</h1>
          <p style={{ margin: 0, fontSize: 13 }}>
            If you see your item, contact the reporter through their email or visit the place where Item is located; an
            ID and verification may be needed upon arrival.
          </p>
        </div>
        <div className="items-actions">
          {me?.isAdmin && (
            <>
              <button
                className="btn-outline"
                onClick={() => navigate("/admin/approve")}
              >
                Approve / Deny
              </button>
              <button
                className="btn-outline"
                onClick={() => navigate("/admin/stats")}
              >
                Statistics
              </button>
              <button
                className="btn-outline"
                onClick={() => navigate("/admin/manage")}   ///additional admin manage button  added after working product - used for turning approved items to resolved or deleting existing reports
              >
                Manage Search
              </button>
            </>
          )}
        </div>
      </div>

      <div className="items-actions" style={{ marginBottom: 8 }}>
        <button
          className="btn"
          onClick={() => navigate("/reports/new/lost")}
        >
          Report Lost Item
        </button>
        <button
          className="btn"
          onClick={() => navigate("/reports/new/found")}
        >
          Report Found Item
        </button>
      </div>

      <form className="items-search" onSubmit={handleSearch}>
        <input
          type="text"
          placeholder="Search by title or category"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <button className="btn-outline" type="submit">
          Search
        </button>
      </form>

      {error && <div className="error-text">{error}</div>}
      {loading ? (
        <div>Loading items...</div>
      ) : (
        <div className="items-grid">
          {items.map((item) => (
            <div
              key={item.id}
              className={`report-card ${statusClass(item)}`}
              onClick={() => navigate(`/reports/${item.id}`)}
            >
              <div className="report-card-header">
                <strong>{item.title}</strong>
                <span className="report-chip">
                  {item.type === "lost" ? "Lost" : "Found"} ·{" "}
                  {item.status === "resolved"
                    ? "Resolved"
                    : item.status === "approved"
                    ? "Approved"
                    : item.status}
                </span>
              </div>
              {item.imageUrl && (
                <img
                  src={item.imageUrl}
                  alt={item.title}
                  style={{
                    width: "100%",
                    maxHeight: 140,
                    objectFit: "cover",
                    borderRadius: 6,
                    marginBottom: 6,
                  }}
                />
              )}
              <div style={{ fontSize: 13 }}>
                <div>
                  <strong>Location:</strong>{" "}
                  {item.locationBuilding || "Not specified"}
                </div>
                <div>
                  <strong>Category:</strong> {item.category}
                </div>
                {item.description && (
                  <div style={{ marginTop: 4 }}>
                    {item.description.length > 100
                      ? item.description.slice(0, 100) + "..."
                      : item.description}
                  </div>
                )}
              </div>
            </div>
          ))}
          {!items.length && !loading && (
            <p>No approved items match your search.</p>
          )}
        </div>
      )}
    </div>
  );
}

export default ItemsPage;
