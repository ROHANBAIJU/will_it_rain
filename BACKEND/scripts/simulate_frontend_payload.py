import sys
import asyncio
sys.path.append(r'D:\will_it_rain\BACKEND')
from app.api.routes import PredictRequest, predict_weather_post

async def main():
    payload = {
        'date': '2025-10-05',
        'timezone': 'Asia/Kolkata',
        'part_of_day': 'all_day',
        'already_passed': True,
        'location': {'lat': 13.008896, 'lon': 77.6699904},
        'activity': 'picnic'
    }
    req = PredictRequest(**payload)
    current_user = {'email': 'dev@example.com','name':'Dev'}
    resp = await predict_weather_post(req, current_user=current_user)
    print('Response keys:', list(resp.keys()))

if __name__ == '__main__':
    asyncio.run(main())
