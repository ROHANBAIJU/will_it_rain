import os
import sys
import time
import xarray as xr
import fsspec
import netrc
import aiohttp

# --- CONFIGURATION ---

# 1. PASTE 5 URLs FROM YOUR TEXT FILE HERE
test_urls = [
    "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/1980/01/MERRA2_100.tavg1_2d_slv_Nx.19800101.nc4",
    "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/1980/01/MERRA2_100.tavg1_2d_slv_Nx.19800102.nc4",
    "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/1980/01/MERRA2_100.tavg1_2d_slv_Nx.19800103.nc4",
    "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/1980/01/MERRA2_100.tavg1_2d_slv_Nx.19800104.nc4",
    "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/1980/01/MERRA2_100.tavg1_2d_slv_Nx.19800105.nc4"
]

# 2. DEFINE THE OUTPUT PATH
# This will save the file to BACKEND/data/processed/
OUTPUT_FILE = os.path.join("..", "data", "processed", "merra2_regional_test.nc4")

# --- MAIN EXECUTION ---

if __name__ == "__main__":
    start_time = time.time()
    
    # --- Authentication Setup using fsspec ---
    try:
        home_dir = os.path.expanduser("~")
        netrc_file_path = os.path.join(home_dir, '_netrc' if sys.platform == 'win32' else '.netrc')
        info = netrc.netrc(netrc_file_path)
        username, _, password = info.authenticators("urs.earthdata.nasa.gov")
    except (FileNotFoundError, netrc.NetrcParseError, TypeError) as e:
        print(f"❌ Error: Could not read credentials from your .netrc file. Please ensure it is set up correctly.\n   Details: {e}")
        sys.exit(1)

    print("Authentication credentials found. Creating virtual filesystem...")
    fs = fsspec.filesystem(
        "http", 
        client_kwargs={'auth': aiohttp.BasicAuth(login=username, password=password)}
    )
    
    # Create file-like objects for xarray
    file_objects = [fs.open(url) for url in test_urls]
    
    # --- Data Processing ---
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    print(f"Opening {len(file_objects)} remote files as a virtual dataset...")
    # Use the file objects and the h5netcdf engine
    ds = xr.open_mfdataset(file_objects, combine='by_coords', engine='h5netcdf')

    print("Selecting the geographical region (lat: 12-14, lon: 77-78)...")
    regional_subset = ds.sel(lat=slice(12, 14), lon=slice(77, 78))

    print("\n>>> Loading ONLY the selected subset... (This should be much faster!) <<<\n")
    regional_subset.load()
    
    print(f"Saving the final aggregated file to {OUTPUT_FILE}...")
    regional_subset.to_netcdf(OUTPUT_FILE)
    
    end_time = time.time()
    
    print("\n✅ Test complete!")
    print(f"The processed file is ready at: {OUTPUT_FILE}")
    print(f"Total time taken: {end_time - start_time:.2f} seconds")
