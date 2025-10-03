# API Reference - Will It Rain

## Base URL
```
http://localhost:8000
```

## Endpoints

### 1. Health Check
**GET** `/`

Checks if the API is running.

**Response**:
```json
{
  "status": "ok",
  "message": "Will It Rain API is running!"
}
```

---

### 2. Weather Prediction
**GET** `/predict`

Predicts weather conditions based on historical NASA data.

**Query Parameters**:
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `lat` | float | Yes | Latitude (-90 to 90) | 12.9716 |
| `lon` | float | Yes | Longitude (-180 to 180) | 77.5946 |
| `date` | string | Yes | Date in YYYY-MM-DD format | 2024-06-15 |

**Example Request**:
```bash
curl "http://localhost:8000/predict?lat=12.9716&lon=77.5946&date=2024-06-15"
```

**Success Response** (200 OK):
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

**Error Responses**:

**400 Bad Request** - Invalid coordinates:
```json
{
  "detail": "Invalid latitude: 91.0. Must be between -90 and 90."
}
```

**400 Bad Request** - Invalid date format:
```json
{
  "detail": "Invalid date format: 2024/06/15. Expected YYYY-MM-DD."
}
```

**404 Not Found** - No data available:
```json
{
  "detail": "No data available for location (12.9716, 77.5946). Please try a different location."
}
```

**500 Internal Server Error** - API failure:
```json
{
  "detail": "An unexpected error occurred: Connection timeout"
}
```

---

## Data Fields Explained

| Field | Description | Unit |
|-------|-------------|------|
| `data_years_count` | Number of historical years analyzed | count |
| `precipitation_probability_percent` | Probability of rain (>1mm) on this date | % |
| `average_precipitation_mm` | Average rainfall amount | mm/day |
| `average_temperature_celsius` | Mean temperature (avg of max/min) | °C |
| `max_temperature_celsius` | Average maximum temperature | °C |
| `min_temperature_celsius` | Average minimum temperature | °C |
| `average_wind_speed_mps` | Average wind speed at 10 meters | m/s |
| `average_humidity_percent` | Average relative humidity | % |
| `years_analyzed` | Range of years in the dataset | string |

---

## Interactive Documentation

FastAPI provides interactive API documentation:

**Swagger UI**: http://localhost:8000/docs  
**ReDoc**: http://localhost:8000/redoc

---

## Rate Limiting

The NASA POWER API has usage limits. Current implementation:
- 7 API calls per prediction request (for year chunks)
- 0.5s delay between calls
- **Future**: Implement caching to reduce API calls

---

## Sample cURL Commands

### Bangalore, India
```bash
curl "http://localhost:8000/predict?lat=12.9716&lon=77.5946&date=2024-06-15"
```

### Mumbai, India
```bash
curl "http://localhost:8000/predict?lat=19.0760&lon=72.8777&date=2024-07-20"
```

### New York, USA
```bash
curl "http://localhost:8000/predict?lat=40.7128&lon=-74.0060&date=2024-12-25"
```

### London, UK
```bash
curl "http://localhost:8000/predict?lat=51.5074&lon=-0.1278&date=2024-08-10"
```

---

## Testing with Python

```python
import requests

# Example request
response = requests.get(
    "http://localhost:8000/predict",
    params={
        "lat": 12.9716,
        "lon": 77.5946,
        "date": "2024-06-15"
    }
)

if response.status_code == 200:
    data = response.json()
    print(f"Rain probability: {data['statistics']['precipitation_probability_percent']}%")
else:
    print(f"Error: {response.json()['detail']}")
```

---

## Testing with JavaScript (Frontend)

```javascript
async function getPrediction(lat, lon, date) {
  try {
    const response = await fetch(
      `http://localhost:8000/predict?lat=${lat}&lon=${lon}&date=${date}`
    );
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail);
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Prediction failed:', error.message);
    throw error;
  }
}

// Usage
getPrediction(12.9716, 77.5946, '2024-06-15')
  .then(data => console.log(data))
  .catch(error => console.error(error));
```
