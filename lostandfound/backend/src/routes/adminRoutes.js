import express from "express";
import admin from "../firebaseAdmin.js";
import { requireAuth, requireAdmin } from "../authMiddleware.js";
const router = express.Router();
const db = admin.firestore();
const reportsRef = db.collection("reports");
///admin report and manage views as well as stats
///all routes   
function mapReportDoc(doc) {
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
}

// all admin actions require auth + admin
router.use(requireAuth, requireAdmin);

// admin/reports/pending
router.get("/reports/pending", async (_req, res) => {
  try {
    const snapshot = await reportsRef
      .where("status", "==", "pending")
      .orderBy("createdAt", "desc")
      .get();

    res.json(snapshot.docs.map(mapReportDoc));
  } catch (err) {
    console.error("Pending reports error:", err);
    res.status(500).json({ error: "Failed to load pending reports" });
  }
});

// admin/reports/:id/approve
router.post("/reports/:id/approve", async (req, res) => {
  try {
    const docRef = reportsRef.doc(req.params.id);
    await docRef.update({
      status: "approved",
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: req.user.email,
    });
    const doc = await docRef.get();
    res.json(mapReportDoc(doc));
  } catch (err) {
    console.error("Approve report error:", err);
    res.status(500).json({ error: "Failed to approve report" });
  }
});

// admin/reports/:id/deny
router.post("/reports/:id/deny", async (req, res) => {
  try {
    const docRef = reportsRef.doc(req.params.id);
    await docRef.update({
      status: "denied",
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: req.user.email,
    });
    const doc = await docRef.get();
    res.json(mapReportDoc(doc));
  } catch (err) {
    console.error("Deny report error:", err);
    res.status(500).json({ error: "Failed to deny report" });
  }
});


// admin/stats
router.get("/stats", async (_req, res) => {
  try {
    const snapshot = await reportsRef
      .where("status", "in", ["approved", "resolved"])
      .get();

    const byCategory = {};
    const byLocation = {};

    snapshot.forEach((doc) => {
      const data = doc.data();
      const cat = data.category || "Unspecified";
      const loc = data.locationBuilding || "Unspecified";
      byCategory[cat] = (byCategory[cat] || 0) + 1;
      byLocation[loc] = (byLocation[loc] || 0) + 1;
    });

    res.json({ byCategory, byLocation });
  } catch (err) {
    console.error("Stats error:", err);
    res.status(500).json({ error: "Failed to load statistics" });
  }
});


///get approved reports
router.get("/reports/approved", async (req, res) => {
  try {
    const snapshot = await reportsRef
      .where("status", "==", "approved")
      .orderBy("createdAt", "desc")
      .get();

    const items = snapshot.docs.map(mapReportDoc);
    res.json(items);
  } catch (err) {
    console.error("Approved reports error:", err);
    res.status(500).json({ error: "Failed to load approved reports" });
  }
});



///mark resolved
router.post("/reports/:id/resolve", async (req, res) => {
  try {
    const docRef = reportsRef.doc(req.params.id);

    await docRef.update({
      status: "resolved",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const updated = await docRef.get();
    res.json(mapReportDoc(updated));
  } catch (err) {
    console.error("Resolve report error:", err);
    res.status(500).json({ error: "Failed to resolve report" });
  }
});



///delete rport
router.delete("/reports/:id", async (req, res) => {
  try {
    const docRef = reportsRef.doc(req.params.id);
    await docRef.delete();

    res.json({ success: true });
  } catch (err) {
    console.error("Delete report error:", err);
    res.status(500).json({ error: "Failed to delete report" });
  }
});

export default router;