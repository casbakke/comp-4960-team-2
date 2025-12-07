import React, { useEffect, useState } from "react";
import { getStats } from "../apiClient";
///stats , location, category ...
function AdminStatsPage() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    (async () => {
      try {
        const data = await getStats();
        setStats(data);
      } catch (err) {
        console.error(err);
        setError(err.message || "Failed to load statistics");
      }
    })();
  }, []);

  if (error) return <div className="error-text">{error}</div>;
  if (!stats) return <div>Loading statistics...</div>;

  return (
    <div>
      <h1>Statistics</h1>
      <p>Counts of approved / resolved reports.</p>
      <div className="stats-grid">
        <div className="stats-card">
          <h3>By Location</h3>
          <ul>
            {Object.entries(stats.byLocation).map(([loc, count]) => (
              <li key={loc}>
                {loc}: {count}
              </li>
            ))}
          </ul>
        </div>
        <div className="stats-card">
          <h3>By Category</h3>
          <ul>
            {Object.entries(stats.byCategory).map(([cat, count]) => (
              <li key={cat}>
                {cat}: {count}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

export default AdminStatsPage;
