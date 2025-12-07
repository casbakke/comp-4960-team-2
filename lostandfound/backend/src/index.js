import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import meRoutes from "./routes/meRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
///mount API routes.
dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: "10mb" }));

app.get("/", (_req, res) => {
  res.send("Lost & Found API running");
});

app.use("/api/me", meRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/admin", adminRoutes);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
});
