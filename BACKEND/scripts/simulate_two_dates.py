import sys
import asyncio
sys.path.append(r'D:\will_it_rain\BACKEND')
from app.api.routes import PredictRequest, predict_weather_post


async def run_case(date_str, tz='Asia/Kolkata'):
    payload = {
        'date': date_str,
        'timezone': tz,
        'part_of_day': 'all_day',
        'location': {'lat': 13.008896, 'lon': 77.6699904},
        'activity': 'picnic'
    }
    req = PredictRequest(**payload)
    current_user = {'email': 'dev@example.com', 'name': 'Dev'}
    resp = await predict_weather_post(req, current_user=current_user)
    ai = resp.get('ai_insight')
    print('\n--- Request date:', date_str)
    print('server_already_passed:', resp.get('server_already_passed'))
    if ai:
        print('AI reasoning:')
        print(ai.get('reasoning', ''))
    else:
        print('No AI insight returned')


async def main():
    # Past date (Oct 5 2025)
    await run_case('2025-10-05')
    # Future date (Oct 20 2025)
    await run_case('2025-10-20')


if __name__ == '__main__':
    asyncio.run(main())
