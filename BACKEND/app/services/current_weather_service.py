"""
Current Weather Service
Fetches real-time weather data from NASA POWER API
"""

import requests
from datetime import datetime
from typing import Dict, Any, Optional

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
            # Get today's date
            today = datetime.now()
            yesterday = datetime.now().replace(day=today.day - 1)
            
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
            
            # Get latest values
            latest_date = end_date
            
            temperature = temp_data.get(latest_date, 0)
            precipitation = precip_data.get(latest_date, 0)
            humidity = humidity_data.get(latest_date, 0)
            wind_speed = wind_data.get(latest_date, 0)
            cloud_cover = cloud_data.get(latest_date, 0)
            pressure = pressure_data.get(latest_date, 0)
            
            # Determine weather condition
            condition = CurrentWeatherService._determine_condition(
                precipitation, cloud_cover, temperature
            )
            
            return {
                "location": {
                    "lat": lat,
                    "lon": lon
                },
                "timestamp": today.isoformat(),
                "temperature": {
                    "celsius": round(temperature, 1),
                    "fahrenheit": round((temperature * 9/5) + 32, 1)
                },
                "condition": condition,
                "precipitation": round(precipitation, 2),
                "humidity": round(humidity, 1),
                "wind_speed": round(wind_speed, 1),
                "cloud_cover": round(cloud_cover, 1),
                "pressure": round(pressure, 1),
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
