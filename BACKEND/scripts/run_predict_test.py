import sys
import asyncio
sys.path.append(r'D:\will_it_rain\BACKEND')

from app.api import routes
from app.api.routes import PredictRequest

async def run_test(payload_dict):
    payload = PredictRequest(**payload_dict)
    try:
        # Provide a dummy current_user dict to satisfy dependency
        current_user = {"email": "dev@example.com", "name": "Dev"}
        print(f"\n--- Running test payload: {payload_dict}\n")
        resp = await routes.predict_weather_post(payload, current_user=current_user)
        print("Response (truncated):")
        # Print top-level keys to avoid huge dumps
        if isinstance(resp, dict):
            keys = list(resp.keys())
            print(keys)
        else:
            print(type(resp))
    except Exception as e:
        print(f"Exception while running test: {e}")

if __name__ == '__main__':
    tests = [
        {
            'lat': 13.009,
            'lon': 77.614,
            'date': '2025-10-06',
            'timezone': 'Asia/Kolkata',
            'part_of_day': 'morning',
            'already_passed': False,
            'activity': 'picnic'
        },
        {
            'lat': 13.009,
            'lon': 77.614,
            'date': '2026-01-15',
            'timezone': 'UTC',
            'part_of_day': 'all_day',
            'already_passed': False,
            'activity': 'wedding'
        },
        # Intentionally wrong client already_passed to force disagreement log
        {
            'lat': 13.009,
            'lon': 77.614,
            'date': '2025-10-06',
            'timezone': 'America/New_York',
            'part_of_day': 'night',
            'already_passed': True,  # may disagree with server
            'activity': 'picnic'
        }
    ]

    async def main():
        for t in tests:
            await run_test(t)

    asyncio.run(main())
