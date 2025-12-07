import admin from "./firebaseAdmin.js";
import dotenv from "dotenv";
/// firebase id token authentication, admin account check, wit.edy email requirement
dotenv.config();

const auth = admin.auth();
const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || "")
  .split(",")
  .map(e => e.trim().toLowerCase())
  .filter(Boolean);

export async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7)
      : null;

    if (!token) {
      return res.status(401).json({ error: "Missing Authorization header" });
    }

    const decoded = await auth.verifyIdToken(token);

    if (!decoded.email || !decoded.email.endsWith("@wit.edu")) {
      return res.status(403).json({ error: "Must use @wit.edu account" });
    }

    const email = decoded.email.toLowerCase();

    req.user = {
      uid: decoded.uid,
      email,
      displayName: decoded.name || "",
      isAdmin: ADMIN_EMAILS.includes(decoded.email.toLowerCase()),  
    };

    next();
  } catch (err) {
    console.error("Auth error:", err);
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function requireAdmin(req, res, next) {
  if (!req.user?.isAdmin) {
    return res.status(403).json({ error: "Admin access required" });
  }
  next();
}
