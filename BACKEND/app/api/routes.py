from fastapi import APIRouter, HTTPException, Query
from app.core import nasa_data_handler, statistical_engine
import re

router = APIRouter()

@router.get("/", tags=["Health Check"])
async def health_check():
    """
    Checks if the API is running.
    """
    return {"status": "ok", "message": "Will It Rain API is running!"}


@router.get("/predict", tags=["Prediction"])
async def predict_weather(
    lat: float = Query(..., description="Latitude of the location"),
    lon: float = Query(..., description="Longitude of the location"),
    date: str = Query(..., description="Date in YYYY-MM-DD format", regex=r"\d{4}-\d{2}-\d{2}")
):
    """
    Predicts weather conditions based on historical NASA data.
    """
    try:
        # Phase 2, Step 1: Get historical data for the point
        historical_data = nasa_data_handler.get_historical_data(lat, lon, date)

        # Phase 2, Step 2: Calculate statistics from that data
        statistics = statistical_engine.calculate_statistics(historical_data)
        
        if "error" in statistics:
            raise HTTPException(status_code=404, detail=statistics["error"])
            
        return {
            "query": {"lat": lat, "lon": lon, "date": date},
            "statistics": statistics
        }

    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Server configuration error: Data file not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")