import os
from dotenv import load_dotenv

# Tải biến môi trường từ file .env
load_dotenv()


class Config:
    # Cấu hình Flask
    # Mặc định nếu không có trong .env
    SECRET_KEY = os.getenv("SECRET_KEY", "mysecretkey")
    DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "1", "t")

    # Cấu hình MongoDB
    MONGO_URI = os.getenv("MONGO_URI")
    DATABASE_NAME = "vietnam"
    POPULATION_COLLECTION = "population"
    # Kết nối MongoDB
    NEWS_COLLECTION = "news"
    # Sửa SESSION_TYPE từ null thành một giá trị hợp lệ
    # Các giá trị hợp lệ: 'filesystem', 'redis', 'memcached', 'mongodb'
    SESSION_TYPE = 'filesystem'

    SESSION_PERMANENT = False
    SESSION_USE_SIGNER = True
    SESSION_KEY_PREFIX = 'session:'
