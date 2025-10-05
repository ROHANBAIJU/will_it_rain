import sys
import os
import types

# Ensure BACKEND is on sys.path so we can import app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

try:
    from app.core.verification_agent import DataVerificationAgent, get_verification_agent
except Exception:
    DataVerificationAgent = None
    get_verification_agent = None


def test_programmatic_fallback():
    if DataVerificationAgent is None:
        import pytest
        pytest.skip('verification_agent module not present')
    agent = DataVerificationAgent()
    # force Gemini disabled
    agent.enabled = False
    agent.model = None

    stats = {
        'precipitation_probability_percent': 40.0,
        'average_precipitation_mm': 1.2,
        'average_temperature_celsius': 22.0,
        'max_temperature_celsius': 25.0,
        'min_temperature_celsius': 18.0,
        'average_wind_speed_mps': 3.5,
        'average_humidity_percent': 70.0,
    }
    loc = {'lat': 12.97, 'lon': 77.59}
    res = agent.verify_statistics(stats, loc, '2025-10-05')

    assert res['verified_by'] == 'programmatic'
    assert 'verification_prediction' in res
    assert res['comparison_score'] == 100.0
    assert res['preferred_source'] == 'statistical'


class DummyModel:
    def __init__(self, response_text):
        self._response = response_text

    def generate(self, prompt):
        # emulate an SDK returning a dict with 'content' or simple string
        return self._response


def test_gemini_mocked_response():
    # create an agent and inject a dummy model and enable it
    if DataVerificationAgent is None:
        import pytest
        pytest.skip('verification_agent module not present')
    agent = DataVerificationAgent()
    agent.enabled = True

    # Gemini returns a JSON object embedded in text
    gemini_json = '''{
        "is_valid": true,
        "confidence": "medium",
        "anomalies": [],
        "validation_notes": "Checked by Gemini",
        "source": "verification",
        "verified_by": "gemini",
        "gemini_verification": {
            "precipitation_probability_percent": 35.0,
            "expected_precipitation_mm": 0.5,
            "average_temperature_celsius": 21.5,
            "max_temperature_celsius": 24.0,
            "min_temperature_celsius": 19.0,
            "average_wind_speed_mps": 3.0,
            "average_humidity_percent": 68.0,
            "source": "gemini"
        }
    }'''

    agent.model = DummyModel(gemini_json)

    stats = {
        'precipitation_probability_percent': 40.0,
        'average_precipitation_mm': 1.2,
        'average_temperature_celsius': 22.0,
        'max_temperature_celsius': 25.0,
        'min_temperature_celsius': 18.0,
        'average_wind_speed_mps': 3.5,
        'average_humidity_percent': 70.0,
    }
    loc = {'lat': 12.97, 'lon': 77.59}
    res = agent.verify_statistics(stats, loc, '2025-10-05')

    # When Gemini returns verification JSON, agent should mark verified_by 'gemini'
    assert res['verified_by'] == 'gemini'
    assert 'verification_prediction' in res
    assert 'comparison_score' in res
    assert res['preferred_source'] in ('statistical', 'verification')
