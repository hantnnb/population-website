const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema(
  {
    full_name: { type: String, required: true },
    email: { type: String, unique: true, required: true },
    password: { type: String, required: true },
    type: { type: String, enum: ["free", "premium", "admin"], default: "free" },
    count: { type: Number, default: 1000 },
    // 🔹 Thêm token và thời gian hết hạn
    token: { type: String, default: null },
    expiresAt: { type: Date, default: null },
  },
  { collection: "users" }
); // Đảm bảo sử dụng đúng collection

const User = mongoose.model("User", UserSchema);
module.exports = User;
