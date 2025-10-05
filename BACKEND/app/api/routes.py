from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from typing import Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from app.core import nasa_data_handler, statistical_engine
from app.core.reasoning_agent import get_reasoning_agent
from app.core.verification_agent import get_verification_agent
from app.services import firestore_service
from app.services.current_weather_service import CurrentWeatherService
from app.api.auth_routes import get_current_user
from datetime import datetime, timedelta
import re

router = APIRouter()

# Initialize AI agents
reasoning_agent = get_reasoning_agent()
verification_agent_instance = get_verification_agent()

@router.get("/", tags=["Health Check"])
async def health_check():
    """
    Checks if the API is running.
    """
    return {"status": "ok", "message": "Will It Rain API is running!"}


@router.get("/weather/current", tags=["Weather"])
async def get_current_weather(
    lat: float = Query(..., description="Latitude of the location"),
    lon: float = Query(..., description="Longitude of the location"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get current weather conditions for a location using NASA POWER API.
    
    **Requires Authentication**: Include `Authorization: Bearer <token>` header
    
    Returns real-time weather data including:
    - Temperature (Celsius and Fahrenheit)
    - Weather condition (sunny, cloudy, rainy, snowy, etc.)
    - Precipitation
    - Humidity
    - Wind speed
    - Cloud cover
    - Atmospheric pressure
    """
    print(f"🌤️ Current weather request from user: {current_user['email']} for ({lat}, {lon})")
    
    try:
        weather_data = CurrentWeatherService.get_current_weather(lat, lon)
        return weather_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch current weather: {str(e)}")


@router.get("/predict", tags=["Prediction"])
async def predict_weather(
    lat: float = Query(..., description="Latitude of the location"),
    lon: float = Query(..., description="Longitude of the location"),
    date: str = Query(..., description="Date in YYYY-MM-DD format", regex=r"\d{4}-\d{2}-\d{2}"),
    activity: str = Query(None, description="Planned activity (e.g., 'picnic', 'trekking', 'wedding')"),
    current_user: dict = Depends(get_current_user)
):
    """
    Predicts weather conditions based on historical NASA data with intelligent caching.
    
    **Requires Authentication**: Include `Authorization: Bearer <token>` header
    
    Features:
    - Smart caching: Retrieves from Firestore if available
    - Incremental updates: Only fetches new years when needed
    - Missing data alerts: Warns when recent data is unavailable
    - Confidence scoring: Indicates prediction reliability
    - AI-powered insights: Natural language recommendations tailored to your activity
    
    The weather_predictions cache is universal (shared by all users).
    """
    
    # Log the authenticated user making the request
    activity_text = f" for activity: {activity}" if activity else ""
    print(f"📊 Prediction request from user: {current_user['email']} ({current_user['name']}){activity_text}")
    try:
        # ============================================================
        # PHASE 3: SMART CACHING LOGIC
        # ============================================================
        
        # Step 1: Check if we have cached data
        cached_data = firestore_service.get_prediction_from_cache(lat, lon, date)
        
        if cached_data:
            # We have cached data! Now check if it needs updating
            needs_update, years_to_fetch = firestore_service.should_update_cache(cached_data, date)
            
            if needs_update:
                # ============================================================
                # INCREMENTAL UPDATE: Fetch only new years
                # ============================================================
                print(f"🔄 Incremental update needed. Fetching {len(years_to_fetch)} new year(s): {years_to_fetch}")
                
                try:
                    # Fetch only the new years
                    new_data = nasa_data_handler.get_historical_data(lat, lon, date, specific_years=years_to_fetch)
                    
                    # Combine with existing cached data (we'll recalculate statistics)
                    # For now, we'll do a full recalculation since we need all data
                    # In a more advanced version, we could store raw data and append
                    all_historical_data = nasa_data_handler.get_historical_data(lat, lon, date)
                    
                    # Recalculate statistics with updated data
                    statistics = statistical_engine.calculate_statistics(all_historical_data)
                    
                    if "error" in statistics:
                        raise HTTPException(status_code=404, detail=statistics["error"])
                    
                    # STAGE 1: Verify updated statistics
                    print("🔍 Stage 1: Verifying updated statistical calculations...")
                    verification_result = verification_agent_instance.verify_statistics(
                        statistics=statistics,
                        location={"lat": lat, "lon": lon},
                        date=date
                    )
                    
                    # Calculate metadata
                    current_year = datetime.now().year
                    target_year = datetime.strptime(date, "%Y-%m-%d").year
                    latest_year = int(statistics['years_analyzed'].split('-')[1])
                    
                    # Determine missing years between latest available data and target year
                    if target_year > latest_year:
                        # Future prediction - calculate all missing years up to target year
                        missing_years = list(range(latest_year + 1, target_year + 1))
                    else:
                        # Past or current year prediction
                        missing_years = []
                    
                    # Calculate confidence score
                    confidence_score = firestore_service.calculate_confidence_score(
                        statistics['data_years_count'], 
                        len(missing_years)
                    )
                    
                    # Update cache
                    firestore_service.update_cache_with_new_data(
                        lat, lon, date,
                        statistics,
                        statistics['years_analyzed'],
                        statistics['data_years_count'],
                        latest_year,
                        missing_years,
                        confidence_score
                    )
                    
                    # Generate missing data alert if needed
                    missing_data_alert = firestore_service.get_missing_data_alert(
                        missing_years, 
                        statistics['data_years_count']
                    )
                    
                    # STAGE 2: Generate AI reasoning with verified data
                    print("🤖 Stage 2: Generating insight with verified updated data...")
                    ai_insight = reasoning_agent.generate_insight(
                        lat, lon, date,
                        statistics,
                        confidence_score,
                        missing_data_alert,
                        activity
                    )
                    
                    response = {
                        "query": {"lat": lat, "lon": lon, "date": date},
                        "statistics": statistics,
                        "confidence_score": round(confidence_score, 2),
                        "cache_status": "updated",
                        "missing_data_alert": missing_data_alert,
                        "verification": {
                            "status": verification_result['status'],
                            "confidence": verification_result['confidence'],
                            "summary": verification_agent_instance.get_verification_summary(verification_result)
                        }
                    }
                    
                    if verification_result.get('anomalies'):
                        response["verification"]["anomalies"] = verification_result['anomalies']
                    
                    if ai_insight:
                        response["ai_insight"] = ai_insight
                    
                    return response
                    
                except Exception as e:
                    print(f"⚠️ Incremental update failed: {e}. Returning cached data.")
                    # If update fails, return cached data with warning
                    missing_data_alert = firestore_service.get_missing_data_alert(
                        cached_data['metadata']['missing_years'],
                        cached_data['metadata']['total_years']
                    )
                    
                    return {
                        "query": {"lat": lat, "lon": lon, "date": date},
                        "statistics": cached_data['statistics'],
                        "confidence_score": round(cached_data['confidence_score'], 2),
                        "cache_status": "hit_stale",
                        "missing_data_alert": missing_data_alert,
                        "warning": "Could not update with latest data. Returning cached version."
                    }
            
            else:
                # ============================================================
                # CACHE HIT: Data is up-to-date, return from cache
                # ============================================================
                print(f"✅ Cache hit! Data is current. No update needed.")
                
                missing_data_alert = firestore_service.get_missing_data_alert(
                    cached_data['metadata']['missing_years'],
                    cached_data['metadata']['total_years']
                )
                
                # Check if AI insight is cached
                ai_insight = cached_data.get('ai_insight')
                
                # If no cached AI insight, generate a new one
                if not ai_insight and reasoning_agent.enabled:
                    ai_insight = reasoning_agent.generate_insight(
                        lat, lon, date,
                        cached_data['statistics'],
                        cached_data['confidence_score'],
                        missing_data_alert,
                        activity
                    )
                    
                    # Update cache with AI insight
                    if ai_insight:
                        firestore_service.update_cache_with_ai_insight(lat, lon, date, ai_insight)
                
                response = {
                    "query": {"lat": lat, "lon": lon, "date": date},
                    "statistics": cached_data['statistics'],
                    "confidence_score": round(cached_data['confidence_score'], 2),
                    "cache_status": "hit",
                    "missing_data_alert": missing_data_alert
                }
                
                if ai_insight:
                    response["ai_insight"] = ai_insight
                
                return response
        
        # ============================================================
        # CACHE MISS: Fetch all data and create cache entry
        # ============================================================
        print(f"❌ Cache miss. Fetching full historical data...")
        
        # Fetch all historical data
        historical_data = nasa_data_handler.get_historical_data(lat, lon, date)
        
        # Calculate statistics
        statistics = statistical_engine.calculate_statistics(historical_data)
        
        if "error" in statistics:
            raise HTTPException(status_code=404, detail=statistics["error"])
        
        # ============================================================
        # STAGE 1: AI VERIFICATION OF STATISTICS
        # ============================================================
        print("🔍 Stage 1: Verifying statistical calculations with AI...")
        verification_result = verification_agent_instance.verify_statistics(
            statistics=statistics,
            location={"lat": lat, "lon": lon},
            date=date
        )
        
        # Check if verification flagged any issues
        if not verification_result.get('is_valid', True):
            print(f"⚠️ Verification flagged anomalies: {verification_result.get('anomalies', [])}")
            # Log warning but proceed (you can change this to raise exception if desired)
        
        # Calculate metadata for caching
        current_year = datetime.now().year
        target_year = datetime.strptime(date, "%Y-%m-%d").year
        latest_year = int(statistics['years_analyzed'].split('-')[1])
        
        # Determine missing years between latest available data and target year
        # For future predictions: missing years = years between latest_year and target_year
        # For past predictions: no missing years if target_year <= latest_year
        if target_year > latest_year:
            # Future prediction - calculate all missing years up to target year
            # But only count years that could have happened (up to current year)
            missing_years = list(range(latest_year + 1, target_year + 1))
        else:
            # Past or current year prediction - data should exist
            missing_years = []
        
        # Calculate confidence score
        confidence_score = firestore_service.calculate_confidence_score(
            statistics['data_years_count'],
            len(missing_years)
        )
        
        # Generate missing data alert if needed
        missing_data_alert = firestore_service.get_missing_data_alert(
            missing_years,
            statistics['data_years_count']
        )
        
        # ============================================================
        # STAGE 2: AI INSIGHT GENERATION (with verified data)
        # ============================================================
        print("🤖 Stage 2: Generating human-readable insight with verified data...")
        ai_insight = reasoning_agent.generate_insight(
            lat, lon, date,
            statistics,
            confidence_score,
            missing_data_alert,
            activity
        )
        
        # Save to cache with AI insight and verification status
        firestore_service.save_prediction_to_cache(
            lat, lon, date,
            statistics,
            statistics['years_analyzed'],
            statistics['data_years_count'],
            latest_year,
            missing_years,
            confidence_score,
            ai_insight=ai_insight,
            verification_result=verification_result  # Save verification metadata
        )
        
        response = {
            "query": {"lat": lat, "lon": lon, "date": date},
            "statistics": statistics,
            "confidence_score": round(confidence_score, 2),
            "cache_status": "miss",
            "missing_data_alert": missing_data_alert,
            "verification": {
                "status": verification_result['status'],
                "confidence": verification_result['confidence'],
                "summary": verification_agent_instance.get_verification_summary(verification_result)
            }
        }
        
        # Add detailed verification info if there are anomalies
        if verification_result.get('anomalies'):
            response["verification"]["anomalies"] = verification_result['anomalies']
            response["verification"]["notes"] = verification_result.get('validation_notes', '')
        
        if ai_insight:
            response["ai_insight"] = ai_insight
        
        return response

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Server configuration error: Data file not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")



class PredictRequest(BaseModel):
    lat: float
    lon: float
    date: str
    activity: Optional[str] = None
    timezone: Optional[str] = None
    part_of_day: Optional[str] = None
    already_passed: Optional[bool] = None


async def _predict_core(
    current_user: dict,
    lat: float,
    lon: float,
    date: str,
    activity: Optional[str] = None,
    part_of_day: Optional[str] = None,
    already_passed: Optional[bool] = None,
):
    """
    Core predict logic factored out so both GET and POST endpoints can reuse it.
    """
    try:
        # Log the authenticated user making the request
        activity_text = f" for activity: {activity}" if activity else ""
        print(f"📊 Prediction request from user: {current_user['email']} ({current_user['name']}){activity_text}")

        # Fetch all historical data
        historical_data = nasa_data_handler.get_historical_data(lat, lon, date)

        # Calculate statistics
        statistics = statistical_engine.calculate_statistics(historical_data)

        if "error" in statistics:
            raise HTTPException(status_code=404, detail=statistics["error"])

        # ============================================================
        # STAGE 1: AI VERIFICATION OF STATISTICS
        # ============================================================
        print("🔍 Stage 1: Verifying statistical calculations with AI...")
        verification_result = verification_agent_instance.verify_statistics(
            statistics=statistics,
            location={"lat": lat, "lon": lon},
            date=date
        )

        # Check if verification flagged any issues
        if not verification_result.get('is_valid', True):
            print(f"⚠️ Verification flagged anomalies: {verification_result.get('anomalies', [])}")

        # Calculate metadata for caching
        current_year = datetime.now().year
        target_year = datetime.strptime(date, "%Y-%m-%d").year
        latest_year = int(statistics['years_analyzed'].split('-')[1])

        # Determine missing years between latest available data and target year
        if target_year > latest_year:
            missing_years = list(range(latest_year + 1, target_year + 1))
        else:
            missing_years = []

        # Calculate confidence score
        confidence_score = firestore_service.calculate_confidence_score(
            statistics['data_years_count'],
            len(missing_years)
        )

        # Generate missing data alert if needed
        missing_data_alert = firestore_service.get_missing_data_alert(
            missing_years,
            statistics['data_years_count']
        )

        # ============================================================
        # STAGE 2: AI INSIGHT GENERATION (with verified data)
        # ============================================================
        print("🤖 Stage 2: Generating human-readable insight with verified data...")
        ai_insight = reasoning_agent.generate_insight(
            lat, lon, date,
            statistics,
            confidence_score,
            missing_data_alert,
            activity,
            part_of_day=part_of_day,
            already_passed=already_passed
        )

        # Save to cache with AI insight and verification status
        firestore_service.save_prediction_to_cache(
            lat, lon, date,
            statistics,
            statistics['years_analyzed'],
            statistics['data_years_count'],
            latest_year,
            missing_years,
            confidence_score,
            ai_insight=ai_insight,
            verification_result=verification_result  # Save verification metadata
        )

        response = {
            "query": {"lat": lat, "lon": lon, "date": date},
            "statistics": statistics,
            "confidence_score": round(confidence_score, 2),
            "cache_status": "miss",
            "missing_data_alert": missing_data_alert,
            "verification": {
                "status": verification_result['status'],
                "confidence": verification_result['confidence'],
                "summary": verification_agent_instance.get_verification_summary(verification_result)
            }
        }

        # Add detailed verification info if there are anomalies
        if verification_result.get('anomalies'):
            response["verification"]["anomalies"] = verification_result['anomalies']
            response["verification"]["notes"] = verification_result.get('validation_notes', '')

        if ai_insight:
            response["ai_insight"] = ai_insight

        return response

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Server configuration error: Data file not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")


@router.post('/predict', tags=["Prediction"])
async def predict_weather_post(payload: PredictRequest, current_user: dict = Depends(get_current_user)):
    """
    Accepts a JSON body for prediction requests. Server will recompute 'already_passed'
    using the provided IANA timezone (if any) and will use that authoritative value
    when generating the AI insight.
    """
    # Compute authoritative already_passed using server timezone data
    tz_name = payload.timezone or 'UTC'
    server_already_passed = None
    try:
        tzinfo = ZoneInfo(tz_name)
        now = datetime.now(tzinfo)

        # Determine end time for the requested part_of_day
        part = payload.part_of_day or 'all_day'
        # parse date parts once
        year, month, day = [int(p) for p in payload.date.split('-')]
        if part == 'morning':
            part_end = datetime(year, month, day, 12, 0, tzinfo=tzinfo)
        elif part == 'noon':
            part_end = datetime(year, month, day, 16, 0, tzinfo=tzinfo)
        elif part == 'evening':
            part_end = datetime(year, month, day, 19, 0, tzinfo=tzinfo)
        elif part == 'night':
            # night: 19:00 selected day to 04:00 next day
            base = datetime(year, month, day, 19, 0, tzinfo=tzinfo)
            part_end = base + timedelta(hours=9)
        else:
            part_end = datetime(year, month, day, 23, 59, 59, tzinfo=tzinfo)

        # Compare dates (day-based) first
        today = datetime(now.year, now.month, now.day, tzinfo=tzinfo)
        selected_day = datetime(int(payload.date.split('-')[0]), int(payload.date.split('-')[1]), int(payload.date.split('-')[2]), tzinfo=tzinfo)

        if selected_day < today:
            server_already_passed = True
        elif selected_day > today:
            server_already_passed = False
        else:
            server_already_passed = part_end < now

    except ZoneInfoNotFoundError:
        print(f"⚠️ Timezone not found on server: {tz_name}. Falling back to UTC for already_passed computation.")
        try:
            now = datetime.utcnow()
            # simple fallback: similar to previous logic but naive
            part = payload.part_of_day or 'all_day'
            year, month, day = [int(p) for p in payload.date.split('-')]
            if part == 'morning':
                part_end = datetime(year, month, day, 12, 0)
            elif part == 'noon':
                part_end = datetime(year, month, day, 16, 0)
            elif part == 'evening':
                part_end = datetime(year, month, day, 19, 0)
            elif part == 'night':
                part_end = datetime(year, month, day, 19, 0) + timedelta(hours=9)
            else:
                part_end = datetime(year, month, day, 23, 59, 59)

            today = datetime(now.year, now.month, now.day)
            selected_day = datetime(year, month, day)
            if selected_day < today:
                server_already_passed = True
            elif selected_day > today:
                server_already_passed = False
            else:
                server_already_passed = part_end < now
        except Exception:
            server_already_passed = payload.already_passed if payload.already_passed is not None else False

    # Log if client and server disagree
    if payload.already_passed is not None and payload.already_passed != server_already_passed:
        print(f"⚠️ Client sent already_passed={payload.already_passed} but server computed {server_already_passed}. Using server value.")

    # Call core predict logic with authoritative already_passed and part_of_day
    return await _predict_core(
        current_user=current_user,
        lat=payload.lat,
        lon=payload.lon,
        date=payload.date,
        activity=payload.activity,
        part_of_day=payload.part_of_day,
        already_passed=server_already_passed
    )