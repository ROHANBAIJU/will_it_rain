import sys
sys.path.append(r'D:\will_it_rain\BACKEND')
from app.services import auth_service

# Create a short-lived token for testing purposes
payload = {'sub': 'test-user', 'email': 'test@example.com', 'name': 'Test User'}
print(auth_service.create_access_token(payload))
