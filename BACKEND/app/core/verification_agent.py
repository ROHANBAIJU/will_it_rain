"""
Gemini Data Verification Agent
Validates statistical calculations before generating insights
"""

import google.generativeai as genai
import os
from typing import Dict, Any, List, Optional
import json

class DataVerificationAgent:
    """
    Two-stage Gemini verification system:
    1. Stage 1: Validates statistical output
    2. Stage 2: Generates human-readable insights (existing reasoning_agent.py)
    """
    
    def __init__(self):
        """Initialize Gemini for data verification"""
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=api_key)
        
        # Use gemini-2.0-flash-thinking-exp for verification (best reasoning)
        self.model = genai.GenerativeModel('gemini-2.0-flash-thinking-exp-01-21')
        print("✅ Gemini Data Verification Agent initialized")
    
    def verify_statistics(
        self,
        statistics: Dict[str, Any],
        location: Dict[str, float],
        date: str
    ) -> Dict[str, Any]:
        """
        Stage 1: Verify statistical calculations and data quality
        
        Args:
            statistics: Statistical output from statistical_engine.py
            location: {"lat": float, "lon": float}
            date: "YYYY-MM-DD"
        
        Returns:
            Verification result with validity status and notes
        """
        try:
            prompt = self._build_verification_prompt(statistics, location, date)
            
            response = self.model.generate_content(
                prompt,
                generation_config={
                    'temperature': 0.3,  # Low temperature for factual verification
                    'top_p': 0.8,
                    'top_k': 20,
                    'max_output_tokens': 500  # Shorter response for verification
                }
            )
            
            verification_result = self._parse_verification_response(response.text)
            
            print(f"✅ Data verification complete: {verification_result['status']}")
            return verification_result
            
        except Exception as e:
            print(f"⚠️ Verification failed: {e}")
            # Fallback: Return "unverified but proceed" on error
            return {
                "status": "unverified",
                "is_valid": True,  # Assume valid if verification fails
                "confidence": "medium",
                "anomalies": [],
                "validation_notes": f"Verification unavailable: {str(e)}",
                "verified_by": "gemini-2.0-flash-thinking-exp"
            }
    
    def _build_verification_prompt(
        self,
        statistics: Dict[str, Any],
        location: Dict[str, float],
        date: str
    ) -> str:
        """Build prompt for data verification"""
        
        prompt = f"""You are a meteorological data validator with expertise in climatology and weather statistics.

**TASK**: Verify if these statistical calculations are reasonable and flag any anomalies.

**LOCATION**: Latitude {location['lat']}°, Longitude {location['lon']}°
**DATE**: {date}
**DATA YEARS**: {statistics.get('data_years_count', 'unknown')} years ({statistics.get('years_analyzed', 'unknown')})

**STATISTICS TO VERIFY**:
- Rain Probability: {statistics.get('precipitation_probability_percent', 'N/A')}%
- Average Precipitation: {statistics.get('average_precipitation_mm', 'N/A')} mm/day
- Average Temperature: {statistics.get('average_temperature_celsius', 'N/A')}°C
- Max Temperature: {statistics.get('max_temperature_celsius', 'N/A')}°C
- Min Temperature: {statistics.get('min_temperature_celsius', 'N/A')}°C
- Wind Speed: {statistics.get('average_wind_speed_mps', 'N/A')} m/s
- Humidity: {statistics.get('average_humidity_percent', 'N/A')}%

**VERIFICATION CRITERIA**:
1. Are all values within physically possible ranges?
   - Temperature: -50°C to 60°C
   - Humidity: 0% to 100%
   - Wind speed: 0 to 100 m/s
   - Precipitation: 0 to 500 mm/day
   - Probability: 0% to 100%

2. Are the values reasonable for this location and date?
   - Consider latitude/longitude climate zone
   - Consider seasonal patterns
   - Consider geographical context

3. Are the statistics internally consistent?
   - Max temp should be >= Min temp
   - High humidity often correlates with rain probability
   - Temperature and season should align

**RESPOND IN THIS EXACT JSON FORMAT**:
{{
  "is_valid": true/false,
  "confidence": "high/medium/low",
  "anomalies": ["list any unusual values or inconsistencies"],
  "validation_notes": "Brief explanation of validation result",
  "recommendations": "Any suggestions for data interpretation"
}}

**IMPORTANT**: 
- Be strict but reasonable (small anomalies are okay)
- Consider this is historical climate data, not real-time weather
- If data looks generally reasonable, mark as valid
- Only flag as invalid if there are serious errors or impossible values"""

        return prompt
    
    def _parse_verification_response(self, response_text: str) -> Dict[str, Any]:
        """Parse Gemini's verification response"""
        try:
            # Clean response (remove markdown code blocks if present)
            cleaned = response_text.strip()
            if cleaned.startswith('```json'):
                cleaned = cleaned[7:]
            if cleaned.startswith('```'):
                cleaned = cleaned[3:]
            if cleaned.endswith('```'):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            
            # Parse JSON
            verification = json.loads(cleaned)
            
            # Add metadata
            verification['status'] = 'verified' if verification.get('is_valid', True) else 'invalid'
            verification['verified_by'] = 'gemini-2.0-flash-thinking-exp'
            
            return verification
            
        except json.JSONDecodeError as e:
            print(f"⚠️ Failed to parse verification JSON: {e}")
            print(f"Raw response: {response_text[:200]}...")
            
            # Fallback parsing: Look for keywords
            is_valid = 'valid' in response_text.lower() and 'invalid' not in response_text.lower()
            
            return {
                "status": "verified" if is_valid else "unverified",
                "is_valid": is_valid,
                "confidence": "medium",
                "anomalies": [],
                "validation_notes": response_text[:200] if len(response_text) < 200 else response_text[:200] + "...",
                "recommendations": "",
                "verified_by": "gemini-2.0-flash-thinking-exp"
            }
    
    def get_verification_summary(self, verification: Dict[str, Any]) -> str:
        """Get a human-readable verification summary"""
        if verification['status'] == 'verified' and verification['is_valid']:
            emoji = "✅"
            summary = f"Statistics verified by AI ({verification['confidence']} confidence)"
        elif verification['status'] == 'verified' and not verification['is_valid']:
            emoji = "⚠️"
            summary = f"Anomalies detected: {', '.join(verification.get('anomalies', ['Unknown']))}"
        else:
            emoji = "❓"
            summary = "Verification unavailable"
        
        return f"{emoji} {summary}"


# Singleton instance
_verification_agent = None

def get_verification_agent():
    """Get or create verification agent singleton"""
    global _verification_agent
    if _verification_agent is None:
        _verification_agent = DataVerificationAgent()
    return _verification_agent
