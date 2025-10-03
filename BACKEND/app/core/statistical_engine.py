import pandas as pd
import numpy as np

# Define a threshold for what we consider a "rainy day" in mm/day
# 1.0 mm/day is a common threshold.
RAIN_THRESHOLD_MM_DAY = 1.0

def calculate_statistics(df: pd.DataFrame):
    """
    Calculates weather statistics from historical data returned by NASA POWER API.
    
    Args:
        df (pd.DataFrame): Historical weather data with columns:
                          - YEAR, DOY, WS10M, RH2M, T2M_MAX, T2M_MIN, PRECTOTCORR
    
    Returns:
        dict: Dictionary containing calculated statistics
    """
    if df is None or df.empty:
        return {"error": "No data available for this location/date."}
    
    total_years = len(df)
    
    if total_years == 0:
        return {"error": "No data available for this location/date."}
    
    # NASA POWER API data format:
    # - WS10M: Wind speed at 10m (m/s) - already in correct units
    # - RH2M: Relative humidity at 2m (%)
    # - T2M_MAX: Maximum temperature at 2m (°C) - already in Celsius
    # - T2M_MIN: Minimum temperature at 2m (°C) - already in Celsius
    # - PRECTOTCORR: Corrected precipitation (mm/day) - already in mm/day
    
    # Calculate precipitation probability
    rainy_days = (df['PRECTOTCORR'] > RAIN_THRESHOLD_MM_DAY).sum()
    rain_probability = (rainy_days / total_years) * 100 if total_years > 0 else 0
    
    # Calculate average temperature (mean of max and min)
    avg_temp = (df['T2M_MAX'] + df['T2M_MIN']) / 2
    
    # Calculate statistics
    stats = {
        "data_years_count": total_years,
        "precipitation_probability_percent": round(rain_probability, 2),
        "average_precipitation_mm": round(df['PRECTOTCORR'].mean(), 2),
        "average_temperature_celsius": round(avg_temp.mean(), 2),
        "max_temperature_celsius": round(df['T2M_MAX'].mean(), 2),
        "min_temperature_celsius": round(df['T2M_MIN'].mean(), 2),
        "average_wind_speed_mps": round(df['WS10M'].mean(), 2),
        "average_humidity_percent": round(df['RH2M'].mean(), 2),
        "years_analyzed": f"{int(df['YEAR'].min())}-{int(df['YEAR'].max())}"
    }
    
    return stats