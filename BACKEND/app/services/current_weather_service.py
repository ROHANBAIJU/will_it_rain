"""
Current Weather Service
Fetches real-time weather data from NASA POWER API
"""

import requests
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import urllib.parse

class CurrentWeatherService:
    """Service to fetch current weather conditions"""
    
    BASE_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"
    
    @staticmethod
    def get_current_weather(lat: float, lon: float) -> Dict[str, Any]:
        """
        Fetch current weather conditions for a location
        
        Args:
            lat: Latitude
            lon: Longitude
            
        Returns:
            Dictionary with current weather data
        """
        try:
            # Use safe date arithmetic to get yesterday and today
            today = datetime.utcnow()
            yesterday = today - timedelta(days=1)

            start_date = yesterday.strftime("%Y%m%d")
            end_date = today.strftime("%Y%m%d")
            
            # NASA POWER API parameters for current conditions
            params = {
                "parameters": "T2M,PRECTOTCORR,QV2M,WS2M,CLOUD_AMT,PS",
                "community": "RE",
                "longitude": lon,
                "latitude": lat,
                "start": start_date,
                "end": end_date,
                "format": "JSON"
            }
            
            response = requests.get(CurrentWeatherService.BASE_URL, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Extract latest day's data
            properties = data.get("properties", {}).get("parameter", {})
            
            # Get most recent data point
            temp_data = properties.get("T2M", {})
            precip_data = properties.get("PRECTOTCORR", {})
            humidity_data = properties.get("QV2M", {})
            wind_data = properties.get("WS2M", {})
            cloud_data = properties.get("CLOUD_AMT", {})
            pressure_data = properties.get("PS", {})
            
            # Get latest values (may be missing). Use dict.get safely.
            latest_date = end_date

            def _safe_get(d, key):
                try:
                    return d.get(key)
                except Exception:
                    return None

            temperature = _safe_get(temp_data, latest_date)
            precipitation = _safe_get(precip_data, latest_date)
            humidity = _safe_get(humidity_data, latest_date)
            wind_speed = _safe_get(wind_data, latest_date)
            cloud_cover = _safe_get(cloud_data, latest_date)
            pressure = _safe_get(pressure_data, latest_date)

            # If NASA returns sentinel values like -999 (or other unrealistic numbers), treat as missing
            def _is_unrealistic(v):
                if v is None:
                    return True
                try:
                    num = float(v)
                    # Anything below -500 is almost certainly a sentinel/error
                    return num <= -500
                except Exception:
                    return True

            if any(_is_unrealistic(x) for x in [temperature, precipitation, humidity, wind_speed, cloud_cover, pressure]):
                print("⚠️ CurrentWeatherService: API returned missing/unrealistic values, falling back to local defaults")
                return CurrentWeatherService._get_fallback_data(lat, lon)
            
            # Determine weather condition
            condition = CurrentWeatherService._determine_condition(
                precipitation, cloud_cover, temperature
            )
            
            return {
                "location": {"lat": lat, "lon": lon},
                "timestamp": today.isoformat(),
                "temperature": {
                    "celsius": round(float(temperature), 1),
                    "fahrenheit": round((float(temperature) * 9/5) + 32, 1)
                },
                "condition": condition,
                "precipitation": round(float(precipitation), 2),
                "humidity": round(float(humidity), 1),
                "wind_speed": round(float(wind_speed), 1),
                "cloud_cover": round(float(cloud_cover), 1),
                "pressure": round(float(pressure), 1),
                "description": CurrentWeatherService._get_description(condition)
            }
            
        except requests.exceptions.RequestException as e:
            print(f"Error fetching current weather: {e}")
            # Return fallback data
            return CurrentWeatherService._get_fallback_data(lat, lon)
        except Exception as e:
            print(f"Unexpected error in current weather: {e}")
            return CurrentWeatherService._get_fallback_data(lat, lon)
    
    @staticmethod
    def _determine_condition(precipitation: float, cloud_cover: float, temperature: float) -> str:
        """Determine weather condition from parameters"""
        if precipitation > 5:
            return "rainy"
        elif precipitation > 0.5 and temperature < 0:
            return "snowy"
        elif cloud_cover > 70:
            return "cloudy"
        elif cloud_cover > 40:
            return "partly_cloudy"
        else:
            return "sunny"
    
    @staticmethod
    def _get_description(condition: str) -> str:
        """Get human-readable description"""
        descriptions = {
            "sunny": "Clear skies with plenty of sunshine",
            "partly_cloudy": "Partly cloudy with some sun",
            "cloudy": "Overcast skies with cloud cover",
            "rainy": "Rainy conditions, bring an umbrella",
            "snowy": "Snow expected, bundle up!"
        }
        return descriptions.get(condition, "Current weather conditions")
    
    @staticmethod
    def _get_fallback_data(lat: float, lon: float) -> Dict[str, Any]:
        """Return fallback data when API fails"""
        return {
            "location": {"lat": lat, "lon": lon},
            "timestamp": datetime.now().isoformat(),
            "temperature": {"celsius": 22.0, "fahrenheit": 71.6},
            "condition": "partly_cloudy",
            "precipitation": 0.0,
            "humidity": 50.0,
            "wind_speed": 10.0,
            "cloud_cover": 40.0,
            "pressure": 101.3,
            "description": "Weather data temporarily unavailable"
        }

    @staticmethod
    def get_hourly_forecast(lat: float, lon: float, date_iso: str, timezone: str = 'Asia/Kolkata') -> Dict[str, Any]:
        """
        Fetch hourly forecast data from Open-Meteo (free, no key) and return hourly slots for the given date.
        Returns a dict with 'hourly' key containing a list of hourly dicts with timestamp, temperature_c, precipitation, cloud_cover, wind_speed.
        """
        try:
            base = 'https://api.open-meteo.com/v1/forecast'
            params = {
                'latitude': lat,
                'longitude': lon,
                'hourly': 'temperature_2m,precipitation,cloudcover,windspeed_10m',
                'start_date': date_iso,
                'end_date': date_iso,
                'timezone': timezone
            }
            url = f"{base}?{urllib.parse.urlencode(params)}"
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            j = resp.json()
            hourly = []
            times = j.get('hourly', {}).get('time', [])
            temps = j.get('hourly', {}).get('temperature_2m', [])
            precs = j.get('hourly', {}).get('precipitation', [])
            clouds = j.get('hourly', {}).get('cloudcover', [])
            winds = j.get('hourly', {}).get('windspeed_10m', [])

            for i, t in enumerate(times):
                hourly.append({
                    'timestamp': t,
                    'temperature_c': temps[i] if i < len(temps) else None,
                    'precipitation': precs[i] if i < len(precs) else None,
                    'cloud_cover': clouds[i] if i < len(clouds) else None,
                    'wind_speed': winds[i] if i < len(winds) else None,
                })

            return {'hourly': hourly}
        except Exception as e:
            print(f"⚠️ Open-Meteo hourly fetch failed: {e}")
            return {'hourly': []}
