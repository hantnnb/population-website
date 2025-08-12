const express = require("express");
const router = express.Router();
const Province = require("../models/Population");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
require("dotenv").config(); // Đảm bảo load .env

const SECRET_KEY = process.env.JWT_SECRET || "your_secret_key";
console.log("✅ JWT_SECRET từ .env:", SECRET_KEY);
// 📌 Hàm tạo token + thời gian hết hạn
/**
 * @route GET /
 * @description Get a list of provinces with pagination and search functionality
 * @access Public
 * @query {number} [page=1] - The page number for pagination
 * @query {number} [limit=10] - The number of results per page
 * @query {string} [search=""] - The search term for filtering provinces by name
 * @returns {Object} An object containing total records, current page, total pages, and the list of provinces
 */
router.get("/", async (req, res) => {
  try {
    const { page = 1, limit = 10, search = "" } = req.query;
    const pageNumber = parseInt(page, 10);
    const limitNumber = parseInt(limit, 10);
    const query = search ? { province: { $regex: search, $options: "i" } } : {};

    const total = await Province.countDocuments(query);
    const provinces = await Province.find(query)
      .skip((pageNumber - 1) * limitNumber)
      .limit(limitNumber);

    res.json({
      total,
      page: pageNumber,
      totalPages: Math.ceil(total / limitNumber),
      data: provinces,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

/**
 * @route POST /province
 * @description Create a new province record
 * @access Public
 * @body {string} province - Name of the province
 * @body {number} populationDensity - Population density of the province
 * @body {number} averagePopulation - Average population of the province
 * @body {string} genderRatio - Gender ratio in the province
 * @body {number} laborForce - Labor force in the province
 * @body {number} populationGrowthRate - Population growth rate
 * @body {string} region - Geographic region of the province
 * @body {number} year - Year of the data record
 * @returns {Object} Response message and created province name
 */
router.post("/province", async (req, res) => {
  const {
    province,
    populationDensity,
    averagePopulation,
    genderRatio,
    laborForce,
    populationGrowthRate,
    region,
    year,
  } = req.body;

  try {
    // 🔹 Tạo population mới
    data = new Province({
      province,
      populationDensity,
      averagePopulation,
      genderRatio,
      laborForce,
      populationGrowthRate,
      region,
      year,
    });

    // Lưu vào MongoDB
    await data.save();

    res.status(201).json({
      message: "Tạo mới thành công!",
      data: province,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi máy chủ!" });
  }
});

/**
 * @route PUT /province/:id
 * @description Update province data by ID
 * @access Public
 * @param {string} id - The ID of the province to update
 * @body {Object} updateData - The updated province data
 * @returns {Object} Response message and updated province data
 */
router.put("/province/:id", async (req, res) => {
  const { id } = req.params;
  const updateData = req.body; // Dữ liệu cần cập nhật

  try {
    // 🔹 Cập nhật dữ liệu trong MongoDB
    const updatedProvince = await Province.findByIdAndUpdate(id, updateData, {
      new: true, // Trả về dữ liệu sau khi cập nhật
      runValidators: true, // Kiểm tra validate schema
    });

    // Kiểm tra nếu không tìm thấy tỉnh thành
    if (!updatedProvince) {
      return res.status(404).json({ message: "Không tìm thấy dữ liệu!" });
    }

    res.status(200).json({
      message: "Cập nhật thành công!",
      data: updatedProvince,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi máy chủ!" });
  }
});

/**
 * @route DELETE /province/:id
 * @description Delete a province record by ID
 * @access Public
 * @param {string} id - The ID of the province to delete
 * @returns {Object} Response message and deleted province data
 */
router.delete("/province/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const deletedPopulation = await Province.findByIdAndDelete(id);

    if (!deletedPopulation) {
      return res.status(404).json({ message: "Không tìm thấy dữ liệu" });
    }

    res.json({ message: "Xoá thành công", data: deletedPopulation });
  } catch (error) {
    res.status(500).json({ message: "Lỗi server", error: error.message });
  }
});

/**
 * @route GET /province/:id
 * @description Get a province record by ID
 * @access Public
 * @param {string} id - The ID of the province to retrieve
 * @returns {Object} The province data if found
 */
router.get("/province/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const population = await Province.findById(id);

    if (!population) {
      return res.status(404).json({ message: "Không tìm thấy dữ liệu" });
    }

    res.json(population);
  } catch (error) {
    res.status(500).json({ message: "Lỗi server", error: error.message });
  }
});

module.exports = router;
