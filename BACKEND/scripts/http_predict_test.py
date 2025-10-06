import os
import sys
import json
import asyncio
import requests
sys.path.append(r'D:\will_it_rain\BACKEND')
from app.services import auth_service


def make_token():
    # Use a deterministic test payload (sub must exist)
    payload = {"sub": "test-user-1", "email": "dev@example.com", "name": "Dev"}
    token = auth_service.create_access_token(payload)
    return token


def post_predict(date_str, token, tz='Asia/Kolkata'):
    url = 'http://127.0.0.1:8000/predict'
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    body = {
        'date': date_str,
        'timezone': tz,
        'part_of_day': 'all_day',
        'location': {'lat': 13.008896, 'lon': 77.6699904},
        'activity': 'picnic'
    }
    r = requests.post(url, headers=headers, json=body, timeout=60)
    print(f'POST {date_str} -> {r.status_code}')
    try:
        return r.json()
    except Exception:
        print('Non-JSON response:', r.text)
        return None


def main():
    token = make_token()
    # Past
    resp1 = post_predict('2025-10-05', token)
    # Future
    resp2 = post_predict('2025-10-20', token)

    print('\n=== Past AI Insight ===')
    if resp1 and 'ai_insight' in resp1 and resp1['ai_insight']:
        print(resp1['ai_insight']['reasoning'])
    else:
        print('No AI insight or request failed', resp1)

    print('\n=== Future AI Insight ===')
    if resp2 and 'ai_insight' in resp2 and resp2['ai_insight']:
        print(resp2['ai_insight']['reasoning'])
    else:
        print('No AI insight or request failed', resp2)


if __name__ == '__main__':
    main()
