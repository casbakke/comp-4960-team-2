// backend/src/routes/reportRoutes.js
import express from "express";
import admin from "../firebaseAdmin.js";
import { requireAuth } from "../authMiddleware.js";
/// api endpoints for creating and searching reports
const router = express.Router();
const db = admin.firestore();
const reportsRef = db.collection("reports");

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

// create report
router.post("/", requireAuth, async (req, res) => {
  try {
    const {
      type,
      title,
      description,
      category,
      locationBuilding,
      createdByPhone,
      imageUrl,
      locationCoordinates, 
    } = req.body;

    if (!type || !["lost", "found"].includes(type)) {
      return res.status(400).json({ error: "Invalid or missing type" });
    }
    if (!title || !category) {
      return res
        .status(400)
        .json({ error: "Title and category are required" });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    let geoPoint = null;
    if (
      locationCoordinates &&
      typeof locationCoordinates.lat === "number" &&
      typeof locationCoordinates.lng === "number"
    ) {
      geoPoint = new admin.firestore.GeoPoint(
        locationCoordinates.lat,
        locationCoordinates.lng
      );
    }

    const docData = {
      category,
      createdByName: req.user.displayName || "",
      createdByEmail: req.user.email,
      createdByPhone: createdByPhone || "",
      createdAt: now,
      description: description || "",
      imageUrl: imageUrl || "",
      locationBuilding: locationBuilding || "",
      locationCoordinates: geoPoint,
      reviewedAt: null,
      reviewedBy: "",
      status: "pending",
      title,
      type,
    };

    const docRef = await reportsRef.add(docData);
    const doc = await docRef.get();
    res.status(201).json(mapReportDoc(doc));
  } catch (err) {
    console.error("Create report error:", err);
    res.status(500).json({ error: "Failed to create report" });
  }
});

// get reports search
//only approved and resolved reports are visible
router.get("/search", requireAuth, async (req, res) => {
  try {
    const queryText = (req.query.query || "").toLowerCase();

    const snapshot = await reportsRef
      .where("status", "in", ["approved", "resolved"])
      .orderBy("createdAt", "desc")
      .get();

    const results = [];
    snapshot.forEach((doc) => {
      const report = mapReportDoc(doc);
      const haystack = (
        `${report.title} ${report.description} ${report.category} ${report.locationBuilding}`
      ).toLowerCase();
      if (!queryText || haystack.includes(queryText)) results.push(report);
    });

    res.json(results);
  } catch (err) {
    console.error("Search reports error:", err);
    res.status(500).json({ error: "Failed to load items" });
  }
});

router.get("/:id", requireAuth, async (req, res) => {
  try {
    const doc = await reportsRef.doc(req.params.id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: "Report not found" });
    }
    res.json(mapReportDoc(doc));
  } catch (err) {
    console.error("Get report error:", err);
    res.status(500).json({ error: "Failed to load report" });
  }
});



export default router;
