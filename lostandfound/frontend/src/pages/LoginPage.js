import React, { useState } from "react";
import { loginWithMicrosoft } from "../apiClient";
///login screen 
function LoginPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleLogin() {
    setError("");
    setLoading(true);
    try {
      await loginWithMicrosoft();
    } catch (err) {
      console.error(err);
      setError(err.message || "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-card">
      <h2>WIT Lost and Found</h2>
      <p>
        Sign in with your Wentworth Microsoft account to report or view items.
      </p>
      <button className="btn" onClick={handleLogin} disabled={loading}>
        {loading ? "Signing in..." : "Log in with Microsoft (@wit.edu)"}
      </button>
      {error && <p className="error-text">{error}</p>}
      <p style={{ marginTop: 16, fontSize: 12 }}>
        *Items will only be held for up to 30 days.
      </p>
    </div>
  );
}

export default LoginPage;
