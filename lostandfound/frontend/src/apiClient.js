import {
  loginWithMicrosoft as fbLogin,
  logout as fbLogout,
  getIdToken,
} from "./firebaseClient";

const API_BASE = "https://backend--wit-campus-lost-and-found.us-east4.hosted.app/api";


async function authFetch(path, options = {}) {
  const token = await getIdToken();
  if (!token) throw new Error("Not authenticated");

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });

  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = null;
  }

  if (!res.ok) {
    const msg = data?.error || res.statusText;
    throw new Error(msg);
  }

  return data;
}

export async function loginWithMicrosoft() {
  const user = await fbLogin();
  const me = await authFetch("/me");
  return { user, me };
}

export async function logout() {
  await fbLogout();
}

export async function getCurrentUser() {
  try {
    return await authFetch("/me");
  } catch {
    return null;
  }
}

// Reports
export function searchItems(query) {
  const q = query ? `?query=${encodeURIComponent(query)}` : "";
  return authFetch(`/reports/search${q}`);
}

export function createReport(payload) {
  return authFetch("/reports", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function getReportById(id) {
  return authFetch(`/reports/${id}`);
}

export function getMyReports() {
  return authFetch("/me/reports");
}

// Admin
export function getPendingReports() {
  return authFetch("/admin/reports/pending");
}

export function approveReport(id) {
  return authFetch(`/admin/reports/${id}/approve`, { method: "POST" });
}

export function denyReport(id) {
  return authFetch(`/admin/reports/${id}/deny`, { method: "POST" });
}

export function resolveReport(id) {
  return authFetch(`/admin/reports/${id}/resolve`, { method: "POST" });
}

export function getStats() {
  return authFetch("/admin/stats");
}

// Get all approved reports
export function getApprovedReports() {
  return authFetch("/admin/reports/approved");
}

// Mark report as resolved
export function markResolved(id) {
  return authFetch(`/admin/reports/${id}/resolve`, { method: "POST" });
}

// Delete report
export function deleteReport(id) {
  return authFetch(`/admin/reports/${id}`, { method: "DELETE" });
}