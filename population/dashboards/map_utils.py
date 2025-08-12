import json
import geopandas as gpd
import plotly.express as px

# Load dữ liệu shapefile


def load_shapefile():
    shapefile_path = "mapvn/gadm41_VNM_1.shp"

    return gpd.read_file(shapefile_path)

# Hàm vẽ bản đồ


def generate_map(gadm_gdf, selected_year):
    gadm_gdf["geometry"] = gadm_gdf["geometry"].simplify(0.01)
    geojson_data = json.loads(gadm_gdf.to_json())

    fig = px.choropleth_mapbox(
        gadm_gdf,
        geojson=geojson_data,
        locations=gadm_gdf.index,
        color="populationDensity" if "populationDensity" in gadm_gdf.columns else None,
        mapbox_style="carto-positron",
        center={"lat": 16.0, "lon": 106.0},
        height=800,
        zoom=4.5,
        title=f"Dân số Việt Nam năm {selected_year}",
        hover_data=["province", "populationDensity", 'averagePopulation',
                    'genderRatio', 'laborForce',
                    'populationGrowthRate'],
        labels={
            "province": "Tỉnh/Thành phố",
            "populationDensity": "Mật độ dân số (người/km²)",
            "averagePopulation": "Dân số trung bình (nghìn người)",
            "genderRatio": "Tỷ lệ giới tính (nam/nữ)",
            "laborForce": "Lực lượng lao động trên 15 tuổi (nghìn người)",
            "populationGrowthRate": "Tỷ lệ gia tăng dân số (%)"
        }
    )

    fig.update_layout(margin={"r": 0, "t": 30, "l": 0, "b": 0})
    return fig.to_html(full_html=False)
