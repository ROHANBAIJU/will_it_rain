from fastapi import APIRouter, HTTPException, Query, Depends
from app.core import nasa_data_handler, statistical_engine
from app.core.reasoning_agent import get_reasoning_agent
from app.services import firestore_service
from app.api.auth_routes import get_current_user
from datetime import datetime
import re

router = APIRouter()

# Initialize AI reasoning agent
reasoning_agent = get_reasoning_agent()

@router.get("/", tags=["Health Check"])
async def health_check():
    """
    Checks if the API is running.
    """
    return {"status": "ok", "message": "Will It Rain API is running!"}


@router.get("/predict", tags=["Prediction"])
async def predict_weather(
    lat: float = Query(..., description="Latitude of the location"),
    lon: float = Query(..., description="Longitude of the location"),
    date: str = Query(..., description="Date in YYYY-MM-DD format", regex=r"\d{4}-\d{2}-\d{2}"),
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
    - AI-powered insights: Natural language recommendations
    
    The weather_predictions cache is universal (shared by all users).
    """
    
    # Log the authenticated user making the request
    print(f"📊 Prediction request from user: {current_user['email']} ({current_user['name']})")
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
                    
                    # Generate AI reasoning
                    ai_insight = reasoning_agent.generate_insight(
                        lat, lon, date,
                        statistics,
                        confidence_score,
                        missing_data_alert
                    )
                    
                    response = {
                        "query": {"lat": lat, "lon": lon, "date": date},
                        "statistics": statistics,
                        "confidence_score": round(confidence_score, 2),
                        "cache_status": "updated",
                        "missing_data_alert": missing_data_alert
                    }
                    
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
                        missing_data_alert
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
        
        # Generate AI reasoning
        ai_insight = reasoning_agent.generate_insight(
            lat, lon, date,
            statistics,
            confidence_score,
            missing_data_alert
        )
        
        # Save to cache with AI insight
        firestore_service.save_prediction_to_cache(
            lat, lon, date,
            statistics,
            statistics['years_analyzed'],
            statistics['data_years_count'],
            latest_year,
            missing_years,
            confidence_score,
            ai_insight=ai_insight
        )
        
        response = {
            "query": {"lat": lat, "lon": lon, "date": date},
            "statistics": statistics,
            "confidence_score": round(confidence_score, 2),
            "cache_status": "miss",
            "missing_data_alert": missing_data_alert
        }
        
        if ai_insight:
            response["ai_insight"] = ai_insight
        
        return response

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Server configuration error: Data file not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")