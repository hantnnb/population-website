from dash import html
import dash_bootstrap_components as dbc
from pymongo import MongoClient
from config.config import Config  # ✅ Import Config

# Kết nối MongoDB
client = MongoClient(Config.MONGO_URI)
db = client[Config.DATABASE_NAME]
news_collection = db[Config.NEWS_COLLECTION]

def create_news_page():
    news_data = list(news_collection.find({}, {"_id": 0}))  # Lấy dữ liệu từ MongoDB

    news_list = html.Div([
        dbc.Card(
            dbc.CardBody([
                html.H4(news["title"], className="card-title"),
                html.P(news["date"], className="text-muted"),
                html.P(news["description"], className="card-text"),
            ]),
            className="mb-3",
        ) for news in news_data
    ])

    return html.Div([
        html.H2("Tin tức về Dân số", className="text-center my-4"),
        news_list
    ], className="container")
