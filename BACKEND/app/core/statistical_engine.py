import numpy as np

# Define a threshold for what we consider a "rainy day" in mm/day
# 1.0 mm/day is a common threshold.
RAIN_THRESHOLD_MM_DAY = 1.0

def calculate_statistics(point_data):
    """
    Calculates weather statistics from a time-series of historical data.
    """
    # Important: MERRA-2 precipitation is often in kg m-2 s-1.
    # 1 kg m-2 s-1 = 86400 mm/day. We must convert it.
    # Check your file's metadata for the correct units and variable names!
    # These variable names ('PRECTOTCORR', 'T2M', 'U10M', 'V10M') are examples.
    
    precip_kg_m2_s1 = point_data.get('PRECTOTCORR', np.array([0]))
    precip_mm_day = precip_kg_m2_s1 * 86400

    # Temperature is often in Kelvin. Convert to Celsius.
    temp_kelvin = point_data.get('T2M', np.array([273.15]))
    temp_celsius = temp_kelvin - 273.15

    # Wind speed from U and V components (m/s)
    u_wind = point_data.get('U10M', np.array([0]))
    v_wind = point_data.get('V10M', np.array([0]))
    wind_speed_ms = np.sqrt(u_wind**2 + v_wind**2)

    total_years = len(point_data.time)
    if total_years == 0:
        return {"error": "No data available for this location/date."}

    rainy_days = np.sum(precip_mm_day.values > RAIN_THRESHOLD_MM_DAY)
    rain_probability = (rainy_days / total_years) * 100 if total_years > 0 else 0

    stats = {
        "data_years_count": total_years,
        "precipitation_probability_percent": round(rain_probability, 2),
        "average_temperature_celsius": round(float(temp_celsius.mean()), 2),
        "average_wind_speed_mps": round(float(wind_speed_ms.mean()), 2),
    }
    
    return stats