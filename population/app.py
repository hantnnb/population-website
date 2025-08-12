from flask import Flask, render_template, request
from pymongo import MongoClient
from dashboards.map_utils import load_shapefile, generate_map
from dashboards.population import get_population_data
from config.config import Config
from routes.auth import auth_bp  # ✅ Import Blueprint từ auth.py
from flask_cors import CORS


# Khởi tạo Flask
app = Flask(__name__)
CORS(app)
# Đăng ký Blueprint cho routes/auth.py
app.register_blueprint(auth_bp, url_prefix='/auth')

# Kết nối MongoDB
client = MongoClient(Config.MONGO_URI)
db = client[Config.DATABASE_NAME]
NEWS_COLLECTION = db[Config.NEWS_COLLECTION]
POPULATION_COLLECTION = db[Config.POPULATION_COLLECTION]
# 📌 Route Trang chủ (Bản đồ dân số)


@app.route("/")
def home():
    selected_year = request.args.get("year", default=2011, type=int)
    gadm_gdf = load_shapefile()
    population_df = get_population_data()

    years = sorted(population_df["year"].unique()
                   ) if not population_df.empty else []
    if not population_df.empty:
        population_df = population_df[population_df["year"] == selected_year]
        gadm_gdf = gadm_gdf.merge(
            population_df, left_on="NAME_1", right_on="province", how="left")

    map_html = generate_map(gadm_gdf, selected_year)
    return render_template("home.html", map_html=map_html, years=years, selected_year=selected_year)

# 📌 Route Trang Tin tức


@app.route("/news")
def news():
    news_list = list(NEWS_COLLECTION.find({}, {"_id": 0}))
    return render_template("news.html", news=news_list)

# 📌 Route Trang Giới thiệu


@app.route("/about")
def about():
    return render_template("about.html")

# 📌 Route Trang Đăng ký (GET)


@app.route("/register")
def register():
    return render_template("register.html")

# 📌 Route Trang Đăng nhập (GET)


@app.route("/login")
def login():
    return render_template("login.html")

# 📌 Route Trang Profile (GET)


@app.route("/profile")
def profile():
    return render_template("profile.html")

# 📌 Route Trang Update Profile


@app.route("/updateprofile")
def updateProfile():
    return render_template("updateprofile.html")

# 📌 Route Trang Api Docs


@app.route("/api/docs")
def api_docs():
    return render_template("api_docs.html")
# 📌 Route Trang Api Admin


@app.route("/population")
def population():
    population = list(POPULATION_COLLECTION.find({}, {"_id": 0}))
    return render_template("population-list.html", populationas=population)


# Chạy server
if __name__ == "__main__":
    app.run(debug=False)
