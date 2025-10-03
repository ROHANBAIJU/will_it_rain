# Phase 2 Implementation - NASA POWER API Integration

## ✅ Completed Tasks

### 1. Rewrote `nasa_data_handler.py`
**Location**: `BACKEND/app/core/nasa_data_handler.py`

**Key Features**:
- ✅ Integrated with **NASA POWER API** instead of MERRA-2 dataset
- ✅ Handles **dynamic location** input (latitude & longitude)
- ✅ Fetches data from **1986 to 2024**
- ✅ Implements **chunked requests** (7 chunks) to handle API rate limits
- ✅ **Graceful error handling** for invalid locations
- ✅ Filters historical data for specific dates across all available years

**Function Signature**:
```python
get_historical_data(lat: float, lon: float, date_str: str) -> pd.DataFrame
```

**API Parameters Used**:
- `WS10M` - Wind Speed at 10 meters (m/s)
- `RH2M` - Relative Humidity at 2 meters (%)
- `T2M_MAX` - Maximum Temperature at 2 meters (°C)
- `T2M_MIN` - Minimum Temperature at 2 meters (°C)
- `PRECTOTCORR` - Corrected Precipitation (mm/day)

---

### 2. Updated `statistical_engine.py`
**Location**: `BACKEND/app/core/statistical_engine.py`

**Key Changes**:
- ✅ Adapted to work with **pandas DataFrame** instead of xarray
- ✅ Updated to handle NASA POWER API data format
- ✅ Enhanced statistics output with more metrics

**Statistics Calculated**:
1. `data_years_count` - Number of historical years analyzed
2. `precipitation_probability_percent` - Probability of rain (%)
3. `average_precipitation_mm` - Average precipitation (mm/day)
4. `average_temperature_celsius` - Average temperature (°C)
5. `max_temperature_celsius` - Average max temperature (°C)
6. `min_temperature_celsius` - Average min temperature (°C)
7. `average_wind_speed_mps` - Average wind speed (m/s)
8. `average_humidity_percent` - Average relative humidity (%)
9. `years_analyzed` - Range of years analyzed (e.g., "1986-2024")

---

### 3. Updated Dependencies
**Location**: `BACKEND/requirements.txt`

**Removed** (no longer needed):
- xarray
- netcdf4
- h5netcdf
- dask
- pydap

**Kept/Added**:
- fastapi
- uvicorn[standard]
- pandas
- numpy
- python-dotenv
- requests
- Jinja2

---

## 🚀 How It Works

### API Flow:
```
Frontend Request
    ↓
GET /predict?lat=12.9716&lon=77.5946&date=2024-06-15
    ↓
nasa_data_handler.get_historical_data(lat, lon, date)
    ↓
Loops through year ranges (1986-1991, 1992-1997, ..., 2022-2024)
    ↓
Fetches data from NASA POWER API for each chunk
    ↓
Filters for specific date (month-day) across all years
    ↓
Returns combined DataFrame with historical data
    ↓
statistical_engine.calculate_statistics(dataframe)
    ↓
Returns JSON response with statistics
```

---

## 🧪 Testing

### Start the Server:
```bash
cd BACKEND
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Access Documentation:
Open browser: `http://localhost:8000/docs`

### Test Endpoints:

#### 1. Health Check:
```bash
curl http://localhost:8000/
```

**Expected Response**:
```json
{
  "status": "ok",
  "message": "Will It Rain API is running!"
}
```

#### 2. Weather Prediction (Bangalore):
```bash
curl "http://localhost:8000/predict?lat=12.9716&lon=77.5946&date=2024-06-15"
```

**Expected Response**:
```json
{
  "query": {
    "lat": 12.9716,
    "lon": 77.5946,
    "date": "2024-06-15"
  },
  "statistics": {
    "data_years_count": 39,
    "precipitation_probability_percent": 65.5,
    "average_precipitation_mm": 5.23,
    "average_temperature_celsius": 24.5,
    "max_temperature_celsius": 28.1,
    "min_temperature_celsius": 20.9,
    "average_wind_speed_mps": 3.2,
    "average_humidity_percent": 72.5,
    "years_analyzed": "1986-2024"
  }
}
```

#### 3. Error Handling (Invalid Location):
```bash
curl "http://localhost:8000/predict?lat=91.0&lon=181.0&date=2024-06-15"
```

**Expected Response**:
```json
{
  "detail": "Invalid latitude: 91.0. Must be between -90 and 90."
}
```

---

## 🎯 Key Improvements Over Original Plan

1. **No Local Storage Required**: Data is fetched on-demand from NASA POWER API
2. **Faster Response**: No need to download/process large NetCDF files
3. **Global Coverage**: Works for any location worldwide (lat/lon)
4. **Always Up-to-Date**: Gets latest available data from NASA
5. **Lightweight**: Removed heavy dependencies (xarray, dask, netcdf4)
6. **Better Error Messages**: Clear feedback for invalid inputs

---

## 📝 Next Steps (Phase 3)

Ready to implement:
1. **Firestore Caching** (`firestore_service.py`)
   - `get_prediction_from_cache(lat, lon, date)`
   - `save_prediction_to_cache(lat, lon, date, data)`
   - Cache key format: `{lat}_{lon}_{date}`

2. **Update `/predict` endpoint** to check cache before API call

---

## 🐛 Known Limitations

1. **API Rate Limits**: NASA POWER API has usage limits
   - Mitigation: Implemented 0.5s delay between chunk requests
   - Future: Add Firestore caching (Phase 3)

2. **Data Availability**: Limited to 1986-2024
   - Cannot predict for dates outside this range

3. **Location Precision**: NASA POWER API provides gridded data
   - Resolution: ~0.5° x 0.625° (approximately 55km x 70km)
   - Not precise for very small localities

---

## 📊 Sample Locations for Testing

| City | Latitude | Longitude |
|------|----------|-----------|
| Bangalore | 12.9716 | 77.5946 |
| Mumbai | 19.0760 | 72.8777 |
| Delhi | 28.7041 | 77.1025 |
| London | 51.5074 | -0.1278 |
| New York | 40.7128 | -74.0060 |
| Tokyo | 35.6762 | 139.6503 |

---

**Status**: Phase 2 Complete ✅  
**Next**: Phase 3 - Firestore Caching 🚀
