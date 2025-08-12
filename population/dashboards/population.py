from pymongo import MongoClient
from config.config import Config  # ✅ Import class Config
import pandas as pd

# Kết nối MongoDB
client = MongoClient(Config.MONGO_URI)
db = client[Config.DATABASE_NAME]
population_collection = db[Config.POPULATION_COLLECTION]  # Lấy collection

# Lấy dữ liệu dân số từ MongoDB


def get_population_data():
    cursor = population_collection.find({}, {"_id": 0})  # ✅ Truy vấn đúng cách
    df = pd.DataFrame(list(cursor))

    if df.empty:
        print("⚠️ Không có dữ liệu dân số trong MongoDB!")
        return pd.DataFrame()

    df.rename(columns={
        'province': 'province',
        'year': 'year',
        'population_density': 'populationDensity',
        'average_population': 'averagePopulation',
        'gender_ratio': 'genderRatio',
        'population_growth_rate': 'populationGrowthRate',
        'labor_force': 'laborForce',
        'region': 'region'
    }, inplace=True)

    return df
