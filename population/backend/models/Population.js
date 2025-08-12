const mongoose = require("mongoose");
const ProvinceSchema = new mongoose.Schema(
  {
    province: { type: String, required: true }, // Tỉnh thành
    populationDensity: { type: Number, required: true }, // populationDensity (người/km²)
    averagePopulation: { type: Number, required: true }, // averagePopulation (nghìn người)
    genderRatio: { type: Number, required: true }, // genderRatio (nữ/100 nam)
    populationGrowthRate: { type: Number, required: true }, // populationGrowthRate (%)
    laborForce: { type: Number, required: true }, // Lực lượng lao động từ 15 tuổi trở lên (nghìn người)
    region: { type: String, required: true }, // region địa lý
    year: { type: Number, required: true }, // Năm thống kê
  },
  { collection: "population" }
);

const Province = mongoose.model("Province", ProvinceSchema);

module.exports = Province;
