import os
import json
from datetime import datetime
from typing import Optional, Dict, Any, List
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin (only once)
_firebase_initialized = False
_db = None


def initialize_firebase():
    """
    Initializes Firebase Admin SDK.
    Expects FIREBASE_CREDENTIALS environment variable with path to service account JSON.
    """
    global _firebase_initialized, _db
    
    if _firebase_initialized:
        return _db
    
    try:
        # Check if Firebase app is already initialized
        try:
            # If app already exists, just get the client
            firebase_admin.get_app()
            _db = firestore.client()
            _firebase_initialized = True
            print("✅ Firebase already initialized, reusing connection")
            return _db
        except ValueError:
            # App doesn't exist yet, initialize it
            pass
        
        # Option 1: Use service account JSON file path from environment
        cred_path = os.getenv('FIREBASE_CREDENTIALS')
        
        # Check if Firebase credentials are configured
        if not cred_path:
            # No credentials configured - silent mode
            return None
        
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _db = firestore.client()
            _firebase_initialized = True
            print("✅ Firebase initialized successfully with credentials file")
            return _db
        else:
            # Credentials path set but file doesn't exist
            print(f"⚠️ Firebase credentials file not found at: {cred_path}")
            print(f"   To enable caching:")
            print(f"   1. Create Firebase project at https://console.firebase.google.com/")
            print(f"   2. Download service account JSON")
            print(f"   3. Save as: {cred_path}")
            print(f"   Running without caching (direct API mode)")
            return None
        
    except Exception as e:
        print(f"⚠️ Firebase initialization failed: {e}")
        print("   Running without caching (direct API mode)")
        return None


def get_db():
    """Get Firestore database instance"""
    global _db
    if _db is None:
        _db = initialize_firebase()
    return _db


def generate_cache_key(lat: float, lon: float, month: int, day: int) -> str:
    """
    Generates a unique cache key for a location and date.
    Format: lat_lon_MM-DD (rounded to 2 decimals for nearby locations)
    """
    lat_rounded = round(lat, 2)
    lon_rounded = round(lon, 2)
    return f"{lat_rounded}_{lon_rounded}_{month:02d}-{day:02d}"


def extract_month_day(date_str: str) -> tuple:
    """Extract month and day from YYYY-MM-DD format"""
    date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    return date_obj.month, date_obj.day


def get_prediction_from_cache(lat: float, lon: float, date_str: str) -> Optional[Dict[str, Any]]:
    """
    Retrieves a cached prediction from Firestore.
    
    Args:
        lat (float): Latitude
        lon (float): Longitude
        date_str (str): Date in YYYY-MM-DD format
    
    Returns:
        Dict with cached data or None if not found
    """
    db = get_db()
    if db is None:
        return None
    
    try:
        month, day = extract_month_day(date_str)
        cache_key = generate_cache_key(lat, lon, month, day)
        
        # Query Firestore
        doc_ref = db.collection('weather_predictions').document(cache_key)
        doc = doc_ref.get()
        
        if doc.exists:
            data = doc.to_dict()
            print(f"🎯 Cache HIT for {cache_key}")
            return data
        else:
            print(f"❌ Cache MISS for {cache_key}")
            return None
            
    except Exception as e:
        print(f"⚠️ Error reading from cache: {e}")
        return None


def save_prediction_to_cache(
    lat: float, 
    lon: float, 
    date_str: str, 
    statistics: Dict[str, Any],
    years_analyzed: str,
    total_years: int,
    latest_year: int,
    missing_years: List[int],
    confidence_score: float,
    ai_insight: Optional[Dict[str, Any]] = None
) -> bool:
    """
    Saves a prediction to Firestore cache.
    
    Args:
        lat (float): Latitude
        lon (float): Longitude
        date_str (str): Date in YYYY-MM-DD format
        statistics (dict): Calculated weather statistics
        years_analyzed (str): Range of years analyzed
        total_years (int): Total number of years in dataset
        latest_year (int): Latest year available in data
        missing_years (list): Years that haven't happened yet
        confidence_score (float): Confidence score (0-1)
        ai_insight (dict, optional): AI-generated insight from Gemini
    
    Returns:
        bool: True if saved successfully
    """
    db = get_db()
    if db is None:
        return False
    
    try:
        month, day = extract_month_day(date_str)
        cache_key = generate_cache_key(lat, lon, month, day)
        
        cache_data = {
            "cache_key": cache_key,
            "location": {
                "lat": lat,
                "lon": lon
            },
            "target_date": f"{month:02d}-{day:02d}",
            "statistics": statistics,
            "metadata": {
                "years_analyzed": years_analyzed,
                "total_years": total_years,
                "latest_available_year": latest_year,
                "missing_years": missing_years,
                "last_updated": datetime.utcnow().isoformat(),
                "data_complete_until": f"{latest_year}-12-31"
            },
            "confidence_score": confidence_score,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Add AI insight if available
        if ai_insight:
            cache_data["ai_insight"] = ai_insight
        
        # Save to Firestore
        doc_ref = db.collection('weather_predictions').document(cache_key)
        doc_ref.set(cache_data)
        
        print(f"💾 Saved prediction to cache: {cache_key}")
        return True
        
    except Exception as e:
        print(f"⚠️ Error saving to cache: {e}")
        return False


def update_cache_with_new_data(
    lat: float,
    lon: float, 
    date_str: str,
    new_statistics: Dict[str, Any],
    years_analyzed: str,
    total_years: int,
    latest_year: int,
    missing_years: List[int],
    confidence_score: float
) -> bool:
    """
    Updates an existing cache entry with new data (incremental update).
    """
    db = get_db()
    if db is None:
        return False
    
    try:
        month, day = extract_month_day(date_str)
        cache_key = generate_cache_key(lat, lon, month, day)
        
        doc_ref = db.collection('weather_predictions').document(cache_key)
        
        # Update specific fields
        doc_ref.update({
            "statistics": new_statistics,
            "metadata.years_analyzed": years_analyzed,
            "metadata.total_years": total_years,
            "metadata.latest_available_year": latest_year,
            "metadata.missing_years": missing_years,
            "metadata.last_updated": datetime.utcnow().isoformat(),
            "metadata.data_complete_until": f"{latest_year}-12-31",
            "confidence_score": confidence_score
        })
        
        print(f"🔄 Updated cache: {cache_key} (now includes data up to {latest_year})")
        return True
        
    except Exception as e:
        print(f"⚠️ Error updating cache: {e}")
        return False


def should_update_cache(cached_data: Dict[str, Any], target_date_str: str) -> tuple:
    """
    Determines if cached data needs updating with new years.
    
    Returns:
        (needs_update: bool, years_to_fetch: List[int])
    """
    try:
        # Get the latest year we have in cache
        latest_cached_year = cached_data['metadata']['latest_available_year']
        
        # Get current year and date
        current_datetime = datetime.now()
        current_year = current_datetime.year
        
        # Extract month and day from target date
        target_date = datetime.strptime(target_date_str, "%Y-%m-%d")
        target_month = target_date.month
        target_day = target_date.day
        
        # Check which years have passed since cache was created
        years_to_fetch = []
        
        for year in range(latest_cached_year + 1, current_year + 1):
            # Create the specific date for this year
            check_date = datetime(year, target_month, target_day)
            
            # Has this date already passed?
            if current_datetime > check_date:
                years_to_fetch.append(year)
        
        needs_update = len(years_to_fetch) > 0
        
        return needs_update, years_to_fetch
        
    except Exception as e:
        print(f"⚠️ Error checking cache update need: {e}")
        return False, []


def calculate_confidence_score(total_years: int, missing_years_count: int) -> float:
    """
    Calculates confidence score based on data completeness.
    
    Args:
        total_years (int): Total years of data available
        missing_years_count (int): Number of years not yet happened
    
    Returns:
        float: Confidence score between 0 and 1
    """
    # Base confidence: More years = higher confidence (cap at 40 years)
    base_confidence = min(total_years / 40.0, 1.0)
    
    # Penalty for missing recent years (2% per missing year)
    recency_penalty = missing_years_count * 0.02
    
    # Calculate final confidence
    confidence = base_confidence - recency_penalty
    
    # Ensure confidence stays between 0.5 and 1.0
    return max(min(confidence, 1.0), 0.5)


def get_missing_data_alert(missing_years: List[int], total_years: int) -> Optional[Dict[str, Any]]:
    """
    Generates a missing data alert if applicable.
    
    Returns:
        Dict with alert info or None if no alert needed
    """
    if not missing_years or len(missing_years) == 0:
        return None
    
    current_year = datetime.now().year
    missing_count = len(missing_years)
    
    # Separate years into "not happened yet" vs "should exist but don't"
    future_years = [year for year in missing_years if year > current_year]
    past_years = [year for year in missing_years if year <= current_year]
    
    # Build appropriate message
    if len(future_years) == missing_count:
        # All missing years are in the future
        years_str = ', '.join(map(str, missing_years))
        message = (f"⚠️ Data for {missing_count} year(s) ({years_str}) is not yet available "
                  f"because these years haven't occurred yet. Analysis based on {total_years} years "
                  f"of historical data (up to {max(missing_years) - missing_count}). "
                  f"This is a future prediction with {total_years} years of historical patterns.")
    elif len(past_years) == missing_count:
        # All missing years are in the past (NASA hasn't published data yet)
        years_str = ', '.join(map(str, missing_years))
        message = (f"⚠️ Data for {missing_count} year(s) ({years_str}) is not yet available "
                  f"from NASA POWER API. Analysis based on {total_years} years of historical data. "
                  f"Data for recent years may be published soon.")
    else:
        # Mix of past and future years
        years_str = ', '.join(map(str, missing_years))
        message = (f"⚠️ Data for {missing_count} year(s) ({years_str}) is not available. "
                  f"Analysis based on {total_years} years of historical data. "
                  f"Prediction accuracy will improve as more data becomes available.")
    
    return {
        "alert": True,
        "missing_years_count": missing_count,
        "missing_years": missing_years,
        "future_years": future_years,
        "past_years": past_years,
        "message": message,
        "severity": "low" if missing_count <= 1 else "moderate" if missing_count <= 3 else "high"
    }


def update_cache_with_ai_insight(
    lat: float,
    lon: float,
    date_str: str,
    ai_insight: Dict[str, Any]
) -> bool:
    """
    Updates an existing cache entry with AI insight.
    
    Args:
        lat (float): Latitude
        lon (float): Longitude
        date_str (str): Date in YYYY-MM-DD format
        ai_insight (dict): AI-generated insight from Gemini
    
    Returns:
        bool: True if updated successfully
    """
    db = get_db()
    if db is None:
        return False
    
    try:
        month, day = extract_month_day(date_str)
        cache_key = generate_cache_key(lat, lon, month, day)
        
        doc_ref = db.collection('weather_predictions').document(cache_key)
        
        # Update AI insight field
        doc_ref.update({
            "ai_insight": ai_insight
        })
        
        print(f"🤖 Updated cache with AI insight: {cache_key}")
        return True
        
    except Exception as e:
        print(f"⚠️ Error updating cache with AI insight: {e}")
        return False