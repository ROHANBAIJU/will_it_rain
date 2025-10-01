import requests
import os
import pandas as pd
import time

# NASA POWER API endpoint 
base_url = "https://power.larc.nasa.gov/api/temporal/daily/point"

# Save directory
download_dir = r"baiju give your path"
os.makedirs(download_dir, exist_ok=True)


years_ranges = [
    ("1980", "1985"), ("1986", "1990"), ("1991", "1995"), ("1996", "2000"),
    ("2001", "2005"), ("2006", "2010"), ("2011", "2015"), ("2016", "2020"),
    ("2021", "2023")
]

all_files = []
print("🚀 Starting download of Bangalore weather data (1980-2023)...")

for start_year, end_year in years_ranges:
    print(f"📥 Downloading {start_year}-{end_year}...")
    
    params = {
        "parameters": "WS10M,RH2M,T2M_MAX,T2M_MIN,PRECTOTCORR",
        "community": "AG",
        "format": "CSV",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "start": f"{start_year}0101",
        "end": f"{end_year}1231"
    }
    
    try:
        response = requests.get(base_url, params=params)
        response.raise_for_status()
        
        # Save chunk file
        chunk_filename = os.path.join(download_dir, f"bangalore_{start_year}_{end_year}.csv")
        with open(chunk_filename, "wb") as f:
            f.write(response.content)
        
        all_files.append(chunk_filename)
        print(f"✅ {start_year}-{end_year} downloaded successfully")
        time.sleep(1)  # Be nice to the API
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ Error downloading {start_year}-{end_year}: {e}")
        continue

# Combine all CSV files into one
print("\n🔗 Combining all data files...")
combined_data = []

for file in all_files:
    try:
        # Skip header lines and read data
        with open(file, 'r') as f:
            lines = f.readlines()
        
        # Find where actual CSV data starts (after header)
        csv_start = 0
        for i, line in enumerate(lines):
            if line.startswith('YEAR,'):
                csv_start = i
                break
        
        # Read the CSV data part
        df = pd.read_csv(file, skiprows=csv_start)
        combined_data.append(df)
        print(f"✅ Processed {file}")
        
    except Exception as e:
        print(f"❌ Error processing {file}: {e}")

# Combine and save
if combined_data:
    final_df = pd.concat(combined_data, ignore_index=True)
    final_filename = os.path.join(download_dir, "bangalore_1980_2023_weather.csv")
    final_df.to_csv(final_filename, index=False)
    
    print(f"\n🎉 SUCCESS! Complete dataset saved to:")
    print(f"📁 {final_filename}")
    print(f"📊 Total records: {len(final_df)}")
    print(f"📅 Date range: {final_df['YEAR'].min()}-{final_df['YEAR'].max()}")
    
    # Clean up chunk files
    for file in all_files:
        try:
            os.remove(file)
        except:
            pass
    print("🧹 Cleaned up temporary files")
    
else:
    print("❌ No data was successfully downloaded")

