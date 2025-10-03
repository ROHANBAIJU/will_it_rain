import requests
import pandas as pd
import time
from datetime import datetime
from io import StringIO

# --- CONFIGURATION ---
NASA_POWER_API_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"

# NASA POWER API has data from 1986 to 2024
START_YEAR = 1986
END_YEAR = 2024

# Split into chunks to handle API rate limits (max ~6 years per request)
YEAR_RANGES = [
    (1986, 1991), (1992, 1997), (1998, 2003), 
    (2004, 2009), (2010, 2015), (2016, 2021), 
    (2022, 2024)
]

# Parameters to fetch from NASA POWER API
PARAMETERS = "WS10M,RH2M,T2M_MAX,T2M_MIN,PRECTOTCORR"


def _create_year_ranges_from_list(years: list) -> list:
    """
    Creates year ranges from a list of years for API fetching.
    Groups consecutive years together, splits non-consecutive into separate ranges.
    
    Args:
        years (list): List of years to fetch
    
    Returns:
        list: List of tuples (start_year, end_year)
    """
    if not years:
        return []
    
    years_sorted = sorted(years)
    ranges = []
    start = years_sorted[0]
    end = years_sorted[0]
    
    for i in range(1, len(years_sorted)):
        if years_sorted[i] == end + 1:
            # Consecutive year
            end = years_sorted[i]
        else:
            # Gap found, save current range and start new one
            ranges.append((start, end))
            start = years_sorted[i]
            end = years_sorted[i]
    
    # Add the last range
    ranges.append((start, end))
    
    return ranges


def get_historical_data(lat: float, lon: float, date_str: str, specific_years: list = None):
    """
    Fetches historical weather data for a specific location and date from NASA POWER API.
    
    Args:
        lat (float): Latitude of the location (-90 to 90)
        lon (float): Longitude of the location (-180 to 180)
        date_str (str): Target date in YYYY-MM-DD format
        specific_years (list, optional): List of specific years to fetch. If None, fetches all available years.
    
    Returns:
        pd.DataFrame: Historical data for the specified date across all available years
        
    Raises:
        ValueError: If coordinates are invalid or date format is incorrect
        requests.exceptions.HTTPError: If API request fails
    """
    # Validate coordinates
    if not (-90 <= lat <= 90):
        raise ValueError(f"Invalid latitude: {lat}. Must be between -90 and 90.")
    if not (-180 <= lon <= 180):
        raise ValueError(f"Invalid longitude: {lon}. Must be between -180 and 180.")
    
    # Parse the target date to extract month and day
    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d")
        target_month = target_date.month
        target_day = target_date.day
    except ValueError:
        raise ValueError(f"Invalid date format: {date_str}. Expected YYYY-MM-DD.")
    
    # Determine which years to fetch
    if specific_years:
        # Incremental update: fetch only specific years
        print(f"📡 Fetching incremental data for years: {specific_years}")
        year_ranges_to_fetch = _create_year_ranges_from_list(specific_years)
    else:
        # Full fetch: use default year ranges
        year_ranges_to_fetch = YEAR_RANGES
    
    print(f"📡 Fetching historical data for ({lat}, {lon}) on {target_month:02d}-{target_day:02d}...")
    
    all_data = []
    
    # Loop through year ranges to fetch data in chunks
    for start_year, end_year in year_ranges_to_fetch:
        print(f"  📥 Downloading {start_year}-{end_year}...")
        
        params = {
            "parameters": PARAMETERS,
            "community": "AG",  # Agricultural community
            "format": "CSV",
            "latitude": lat,
            "longitude": lon,
            "start": f"{start_year}0101",
            "end": f"{end_year}1231"
        }
        
        try:
            response = requests.get(NASA_POWER_API_URL, params=params, timeout=30)
            response.raise_for_status()
            
            # Parse the CSV response
            # NASA POWER API returns CSV with metadata headers, skip to actual data
            csv_content = response.text
            
            # Find where the CSV data starts (after the header lines)
            lines = csv_content.split('\n')
            csv_start_index = 0
            for i, line in enumerate(lines):
                if line.startswith('YEAR,'):
                    csv_start_index = i
                    break
            
            # Read the CSV data
            csv_data = '\n'.join(lines[csv_start_index:])
            df_chunk = pd.read_csv(StringIO(csv_data))
            
            # Filter for the specific month and day
            df_chunk['MONTH'] = df_chunk['DOY'].apply(
                lambda doy: datetime.strptime(f"{int(df_chunk.loc[df_chunk['DOY'] == doy, 'YEAR'].iloc[0])}-{int(doy)}", "%Y-%j").month
            )
            df_chunk['DAY'] = df_chunk['DOY'].apply(
                lambda doy: datetime.strptime(f"{int(df_chunk.loc[df_chunk['DOY'] == doy, 'YEAR'].iloc[0])}-{int(doy)}", "%Y-%j").day
            )
            
            # Filter for the target date
            filtered_data = df_chunk[(df_chunk['MONTH'] == target_month) & (df_chunk['DAY'] == target_day)]
            all_data.append(filtered_data)
            
            print(f"  ✅ {start_year}-{end_year} downloaded successfully")
            
            # Be nice to the API - add a small delay between requests
            time.sleep(0.5)
            
        except requests.exceptions.Timeout:
            print(f"  ⚠️ Timeout error for {start_year}-{end_year}. Skipping this range.")
            continue
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 400:
                # Bad request - possibly invalid location
                raise ValueError(
                    f"Invalid location coordinates ({lat}, {lon}). "
                    "The NASA POWER API could not find data for this location. "
                    "Please try a nearby location or use broader coordinates."
                )
            elif e.response.status_code == 404:
                raise ValueError(
                    f"No data available for location ({lat}, {lon}). "
                    "Please try a different location."
                )
            else:
                print(f"  ❌ HTTP Error {e.response.status_code} for {start_year}-{end_year}: {e}")
                raise
        except Exception as e:
            print(f"  ❌ Unexpected error for {start_year}-{end_year}: {str(e)}")
            raise
    
    # Combine all data chunks
    if not all_data:
        raise ValueError(f"No historical data found for ({lat}, {lon}) on {date_str}")
    
    combined_df = pd.concat(all_data, ignore_index=True)
    
    print(f"✅ Successfully retrieved {len(combined_df)} years of historical data")
    
    # Return the dataframe with all historical data for this specific date
    return combined_df