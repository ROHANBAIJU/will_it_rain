"""
AI Reasoning Agent using Google Gemini
Generates human-readable weather insights and recommendations
"""

import os
from typing import Dict, Any, Optional
import google.generativeai as genai
from datetime import datetime


class ReasoningAgent:
    """
    AI agent that provides natural language weather insights using Gemini LLM.
    """
    
    def __init__(self):
        """Initialize Gemini API with configuration"""
        self.api_key = os.getenv('GEMINI_API_KEY')
        self.model = None
        self.enabled = False
        
        if self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel('gemini-2.0-flash')
                self.enabled = True
                print("✅ Gemini AI reasoning agent initialized successfully")
            except Exception as e:
                print(f"⚠️ Failed to initialize Gemini: {e}")
                print("   Running without AI reasoning")
        else:
            print("⚠️ GEMINI_API_KEY not found. Running without AI reasoning")
    
    
    def _build_prompt(
        self,
        lat: float,
        lon: float,
        date_str: str,
        statistics: Dict[str, Any],
        confidence_score: float,
        missing_data_alert: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Build a comprehensive prompt for Gemini with all weather context.
        """
        
        # Extract statistics
        rain_prob = statistics.get('precipitation_probability_percent', 0)
        avg_precip = statistics.get('average_precipitation_mm', 0)
        avg_temp = statistics.get('average_temperature_celsius', 0)
        max_temp = statistics.get('max_temperature_celsius', 0)
        min_temp = statistics.get('min_temperature_celsius', 0)
        wind_speed = statistics.get('average_wind_speed_ms', 0)
        humidity = statistics.get('average_humidity_percent', 0)
        data_years = statistics.get('data_years_count', 0)
        
        # Parse date for context
        try:
            date_obj = datetime.strptime(date_str, '%Y-%m-%d')
            month_name = date_obj.strftime('%B')
            day = date_obj.day
        except:
            month_name = "the specified month"
            day = "this day"
        
        # Build missing data context
        missing_context = ""
        if missing_data_alert:
            severity = missing_data_alert.get('severity', 'low')
            missing_years = missing_data_alert.get('missing_years_count', 0)
            if missing_years > 0:
                missing_context = f"\n\n⚠️ Note: This prediction is for a future date. We're missing {missing_years} years of data (confidence: {confidence_score:.0%}). The prediction is based on historical patterns, but actual conditions may vary."
        
        prompt = f"""You are a friendly and knowledgeable weather assistant helping someone plan their day.

**Location**: Latitude {lat}, Longitude {lon}
**Date**: {month_name} {day}
**Historical Data**: Based on {data_years} years of weather records

**Weather Statistics:**
- Precipitation Probability: {rain_prob:.1f}%
- Average Rainfall: {avg_precip:.1f}mm
- Temperature Range: {min_temp:.1f}°C to {max_temp:.1f}°C (avg: {avg_temp:.1f}°C)
- Wind Speed: {wind_speed:.1f} m/s
- Humidity: {humidity:.1f}%
- Prediction Confidence: {confidence_score:.0%}
{missing_context}

**Your Task:**
Provide a natural, conversational weather insight in 3-4 sentences that includes:
1. Rain likelihood in simple terms (e.g., "unlikely to rain", "high chance of showers")
2. Temperature description (e.g., "pleasant weather", "hot day", "cool evening")
3. Practical recommendation for the day (clothing, activities, precautions)
4. Also mention the location of the coordinates in a friendly way.
Keep it friendly, concise, and actionable. Speak directly to the user (use "you" and "your").
"""
        
        return prompt
    
    
    def generate_insight(
        self,
        lat: float,
        lon: float,
        date_str: str,
        statistics: Dict[str, Any],
        confidence_score: float,
        missing_data_alert: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Generate AI-powered weather insight using Gemini.
        
        Returns:
            Dict with 'reasoning' (str) and 'generated_by' (str)
            Or None if AI is disabled
        """
        
        if not self.enabled or not self.model:
            return None
        
        try:
            # Build prompt
            prompt = self._build_prompt(
                lat=lat,
                lon=lon,
                date_str=date_str,
                statistics=statistics,
                confidence_score=confidence_score,
                missing_data_alert=missing_data_alert
            )
            
            # Generate response
            print("🤖 Generating AI insight with Gemini...")
            response = self.model.generate_content(prompt)
            
            insight_text = response.text.strip()
            
            print(f"✅ AI insight generated ({len(insight_text)} characters)")
            
            return {
                "reasoning": insight_text,
                "generated_by": "gemini-2.0-flash",
                "generated_at": datetime.utcnow().isoformat() + "Z"
            }
            
        except Exception as e:
            print(f"❌ Failed to generate AI insight: {e}")
            return None
    
    
    def generate_insight_streaming(
        self,
        lat: float,
        lon: float,
        date_str: str,
        statistics: Dict[str, Any],
        confidence_score: float,
        missing_data_alert: Optional[Dict[str, Any]] = None
    ):
        """
        Generate AI insight with streaming response (for future use).
        Yields text chunks as they're generated.
        """
        
        if not self.enabled or not self.model:
            yield None
            return
        
        try:
            prompt = self._build_prompt(
                lat=lat,
                lon=lon,
                date_str=date_str,
                statistics=statistics,
                confidence_score=confidence_score,
                missing_data_alert=missing_data_alert
            )
            
            print("🤖 Generating AI insight with streaming...")
            
            response = self.model.generate_content(prompt, stream=True)
            
            for chunk in response:
                if chunk.text:
                    yield chunk.text
            
            print("✅ AI insight streaming complete")
            
        except Exception as e:
            print(f"❌ Failed to stream AI insight: {e}")
            yield None


# Global instance (initialized once)
_reasoning_agent = None


def get_reasoning_agent() -> ReasoningAgent:
    """
    Get or create the global reasoning agent instance.
    """
    global _reasoning_agent
    
    if _reasoning_agent is None:
        _reasoning_agent = ReasoningAgent()
    
    return _reasoning_agent
