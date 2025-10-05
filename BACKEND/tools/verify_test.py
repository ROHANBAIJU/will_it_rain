from app.core.verification_agent import get_verification_agent

# Small CLI to exercise verification agent locally
if __name__ == '__main__':
    agent = get_verification_agent()
    stats = {
        'data_years_count': 39,
        'precipitation_probability_percent': 28.21,
        'average_precipitation_mm': 4.1,
        'average_temperature_celsius': 14.83,
        'max_temperature_celsius': 17.55,
        'min_temperature_celsius': 12.12,
        'average_wind_speed_mps': 5.27,
        'average_humidity_percent': 76.54,
        'years_analyzed': '1986-2024'
    }
    location = {'lat': 40.7128, 'lon': -74.006}
    result = agent.verify_statistics(stats, location, '2025-10-12')
    print('Verification result:')
    print(result)
