const express = require("express");
const router = express.Router();
const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Province = require("../models/Population");
const axios = require("axios");

require("dotenv").config(); // Đảm bảo load .env

const SECRET_KEY = process.env.JWT_SECRET || "your_secret_key";
console.log("✅ JWT_SECRET từ .env:", SECRET_KEY);

// 📌 API Lấy danh sách người dùng
router.get("/", async (req, res) => {
  try {
    const users = await User.find().select("-password"); // Không trả password
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 📌 Hàm tạo token + thời gian hết hạn
const generateToken = (userId) => {
  console.log("🔍 JWT_SECRET tại generateToken:", SECRET_KEY);
  const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000); // 8 giờ
  const token = jwt.sign(
    { userId, exp: Math.floor(expiresAt.getTime() / 1000) },
    SECRET_KEY
  );
  return { token, expiresAt };
};


// 📌 API Đăng ký người dùng
router.post("/register", async (req, res) => {
  const { full_name, email, password, recaptchaResponse } = req.body;

  if (!recaptchaResponse) {
    return res.status(400).json({ message: "Vui lòng xác minh reCAPTCHA!" });
  }

  try {
    // Xác minh reCAPTCHA với Google
    const secretKey = process.env.RECAPTCHA_SECRET_KEY;
    const recaptchaVerifyUrl = "https://www.google.com/recaptcha/api/siteverify";
    
    const recaptchaRes = await axios.post(recaptchaVerifyUrl, null, {
      params: {
        secret: secretKey,
        response: recaptchaResponse
      }
    });

    if (!recaptchaRes.data.success || recaptchaRes.data.score < 0.5) {
      return res.status(400).json({ message: "Xác minh reCAPTCHA thất bại!" });
    }

    // Kiểm tra user đã tồn tại chưa
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: "Email đã tồn tại!" });
    }

    // Băm mật khẩu
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 🔹 Tạo token + thời gian hết hạn
    const { token, expiresAt } = generateToken(email);

    // 🔹 Tạo user mới
    user = new User({
      full_name,
      email,
      password: hashedPassword,
      type: "free",
      count: 1000,
      token,
      expiresAt,
    });

    // Lưu vào MongoDB
    await user.save();

    res.status(201).json({
      message: "Đăng ký thành công!",
      token,
      expiresAt,
      userId: user._id,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi máy chủ!" });
  }
});

// 📌 API Đăng nhập người dùng (Login)
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user)
      return res.status(400).json({ message: "Tài khoản không tồn tại" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ message: "Mật khẩu không đúng" });

    // ✅ Kiểm tra SECRET_KEY
    console.log("🔍 JWT_SECRET tại login:", SECRET_KEY);

    // ✅ Tạo Token JWT
    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.type },
      SECRET_KEY,
      { expiresIn: "8h" }
    );

    console.log("✅ Token được tạo:", token);

    const expiresAt = new Date(Date.now() + 8 * 3600000);
    user.token = token;
    user.expiresAt = expiresAt;
    role = user.type;
    await user.save();

    res.json({ token, expiresAt, role });
  } catch (error) {
    res.status(500).json({ message: "Lỗi server" });
  }
});

// 📌 Middleware xác thực JWT với database
const verifyToken = (req, res, next) => {
  try {
    const authHeader = req.header("Authorization");
    console.log("🔹 Auth Header Received:", authHeader);

    if (!authHeader) {
      console.log("❌ Missing Authorization Header");
      return res
        .status(401)
        .json({ message: "Access Denied. No Authorization Header" });
    }

    const parts = authHeader.split(" ");
    if (parts.length !== 2 || parts[0].toLowerCase() !== "bearer") {
      console.log("❌ Invalid Token Format:", authHeader);
      return res
        .status(401)
        .json({ message: "Invalid Token Format. Expected 'Bearer <token>'" });
    }

    const token = parts[1].trim();
    console.log("✅ Extracted Token:", token);

    // 📌 Kiểm tra SECRET_KEY
    console.log("🔍 JWT_SECRET tại verifyToken:", SECRET_KEY);

    // 📌 Xác thực token với JWT_SECRET
    const decoded = jwt.verify(token, SECRET_KEY);
    console.log("✅ Decoded Token:", decoded);

    req.user = decoded;
    next();
  } catch (err) {
    console.log("❌ Token Verification Error:", err.message);
    return res.status(400).json({ message: "Invalid Token" });
  }
};

// 📌 API lấy thông tin user (Profile)
router.get("/profile", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });

    res.json({
      full_name: user.full_name,
      email: user.email,
      type: user.type,
      count: user.count,
      token: user.token,
      expiresAt: user.expiresAt,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// 📌 Cập nhật thông tin user
router.put("/update", verifyToken, async (req, res) => {
  const { full_name, password } = req.body;
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    if (full_name) user.full_name = full_name;
    if (password) user.password = await bcrypt.hash(password, 10);

    await user.save();
    res.json({ message: "Cập nhật thông tin thành công!" });
  } catch (error) {
    res.status(500).json({ message: "Lỗi server!" });
  }
});

// 📌 API LẤY DỮ LIỆU DÂN SỐ (Bắt buộc có Token)
router.get("/population", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(401).json({ message: "User not found" });

    if (new Date() > user.expiresAt) {
      return res.status(401).json({ message: "Token đã hết hạn, vui lòng đăng nhập lại!" });
    }

    if (user.count <= 0) {
      return res.status(403).json({ message: "Bạn đã hết lượt sử dụng API!" });
    }

    // 📌 Lấy dữ liệu từ collection 'population'
    const { year, province } = req.query;
    let query = {};
    if (year) query.year = parseInt(year);
    if (province) query.province = province;

    const populationData = await Province.find(query);
    if (!populationData.length) {
      return res.status(404).json({ message: "Không tìm thấy dữ liệu dân số!" });
    }

    // 📌 Trừ lượt sử dụng API
    user.count -= 1;
    await user.save();

    res.json({ data: populationData, remainingCount: user.count });
  } catch (error) {
    console.error("Lỗi lấy dữ liệu dân số:", error);
    res.status(500).json({ message: "Lỗi server" });
  }
});

module.exports = router;
