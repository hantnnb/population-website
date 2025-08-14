const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const connectDB = require("./config/db");
const usersRoutes = require("./routes/users");
const populationRoutes = require("./routes/population");
require("dotenv").config();

const app = express();

// Middleware
//app.use(cors()); // ❌ Không giới hạn CORS (chỉ dùng khi debug)
app.use(cors({ origin: "*" }));
//app.use(cors({
//    origin: "https://pplt-dev.vitlab.site", // Cho phép Flask frontend truy cập
//    credentials: true,  // Cho phép gửi cookies & headers
//}));

app.use(bodyParser.json());
app.use(express.json());

// Kết nối MongoDB
connectDB();

// Kiểm tra kết nối MongoDB
const mongoose = require("mongoose");
mongoose.connection.once("open", () => console.log("✅ MongoDB Connected"));
mongoose.connection.on("error", (err) =>
  console.error("❌ MongoDB Error:", err)
);

// Routes
app.use("/api/users", usersRoutes);
app.use("/api/populations", populationRoutes);

// Test API status
app.get("/", (req, res) => {
  res.send("🚀 Server is running in DEBUG mode...");
});

// Khởi động server
const PORT = process.env.PORT || 5001;
app.listen(PORT, "0.0.0.0", () =>
  console.log(`🚀 Server running on port ${PORT} (Debug Mode)`)
);
