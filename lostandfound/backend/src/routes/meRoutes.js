import express from "express";
import { requireAuth } from "../authMiddleware.js";
import admin from "../firebaseAdmin.js";
/// regular user info and their reports
const router = express.Router();
const db = admin.firestore();
const reportsRef = db.collection("reports");

router.get("/", requireAuth, (req, res) => {
  res.json({
    email: req.user.email,
    displayName: req.user.displayName,
    isAdmin: req.user.isAdmin,
  });
});

router.get("/reports", requireAuth, async (req, res) => {
  try {
    const snapshot = await reportsRef
      .where("createdByEmail", "==", req.user.email)
      .orderBy("createdAt", "desc")
      .get();

    const items = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toMillis() ?? null,
        reviewedAt: data.reviewedAt?.toMillis() ?? null,
        locationCoordinates: data.locationCoordinates
          ? {
              lat: data.locationCoordinates.latitude,
              lng: data.locationCoordinates.longitude,
            }
          : null,
      };
    });

    res.json(items);
  } catch (err) {
    console.error("My reports error:", err);
    res.status(500).json({ error: "Failed to load my reports" });
  }
});

export default router;
