import os
import sys
import fsspec
import xarray as xr
import requests
import netrc  # <-- ADD THIS IMPORT
import aiohttp # <-- ADD THIS IMPORT
from dask.diagnostics import ProgressBar

# --- CONFIGURATION ---
URL_LIST_FILE = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'source', 'merra2links.txt')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'data', 'source')
OUTPUT_FILENAME = os.path.join(OUTPUT_DIR, 'MERRA2_combined.nc')

# --- AUTHENTICATION CHECK FUNCTION (Stays the same) ---
def check_authentication(test_url, netrc_path):
    """
    Tests authentication using the modern approach where the requests.Session
    object automatically handles the .netrc file. Returns the session on success.
    """
    print("--- Running Authentication Check ---")
    if not os.path.exists(netrc_path):
        print(f"❌ Error: Your credentials file was not found at {netrc_path}")
        print("   Please ensure the file exists and is correctly named ('_netrc' on Windows).")
        sys.exit(1)
    try:
        print("Attempting to authenticate automatically with .netrc file...")
        session = requests.Session()
        response = session.head(test_url, timeout=15)
        if response.status_code == 200:
            print("✅ Authentication Successful (HTTP Status 200).")
            print("------------------------------------")
            return session
        elif response.status_code == 401:
            print("❌ Authentication Failed (HTTP Status 401: Unauthorized).")
            print("   The username or password in your .netrc file is incorrect.")
            sys.exit(1)
        else:
            print(f"❌ Received unexpected HTTP Status: {response.status_code}.")
            print("   There might be an issue with the server or your network.")
            sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"An error occurred during the authentication check: {e}")
        print("Please check your network connection.")
        sys.exit(1)

# --- MAIN DATA PREPARATION FUNCTION (Final fsspec Version) ---
def prepare_local_dataset_from_urls():
    """
    Reads a list of MERRA-2 URLs, opens them using fsspec and an authenticated
    session, and saves the combined data to a local NetCDF file.
    """
    print("Starting dataset preparation...")
    print(f"Reading URLs from '{URL_LIST_FILE}'...")
    try:
        with open(URL_LIST_FILE, 'r') as f:
            urls = [url.strip() for url in f.readlines()]
    except FileNotFoundError:
        print(f"Error: The file '{URL_LIST_FILE}' was not found.")
        return
    if not urls:
        print("Error: No URLs found in the file.")
        return

    home_dir = os.path.expanduser("~")
    netrc_file = os.path.join(home_dir, '_netrc' if sys.platform == 'win32' else '.netrc')
    
    # Run the authentication check, but we won't use its returned session object
    check_authentication(urls[0], netrc_file)

    # --- Manually parse .netrc to get credentials for aiohttp ---
    try:
        info = netrc.netrc(netrc_file)
        username, _, password = info.authenticators("urs.earthdata.nasa.gov")
    except (FileNotFoundError, netrc.NetrcParseError, TypeError):
        print("❌ Error: Could not parse credentials from .netrc file.")
        sys.exit(1)

    # --- Create a virtual filesystem with the correct authentication for aiohttp ---
    print("Creating virtual filesystem with fsspec...")
    fs = fsspec.filesystem(
        "http", 
        client_kwargs={'auth': aiohttp.BasicAuth(login=username, password=password)}
    )
    
    # Create a list of file-like objects that xarray can open
    file_objects = [fs.open(url) for url in urls]

    # --- Open the remote files using the file objects ---
    print(f"Opening {len(urls)} remote files as a virtual dataset...")
    ds = xr.open_mfdataset(
        file_objects,
        engine='h5netcdf',
        combine='by_coords'
    )
    
    print("\nVirtual dataset created successfully.")
    print("Now processing and saving data to a local file. This will take a long time.")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with ProgressBar():
        ds.to_netcdf(OUTPUT_FILENAME)
        
    print(f"\n✅ Success! Combined dataset saved to: {OUTPUT_FILENAME}")

if __name__ == '__main__':
    prepare_local_dataset_from_urls()