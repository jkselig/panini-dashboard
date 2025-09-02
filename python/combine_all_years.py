"""
Combine yearly master CSVs (from processed_sample) into one all-years master file.
- Input: {year}_master.csv files in data/processed_sample/
- Output: data/processed_sample/panini_master.csv
"""

import pandas as pd
import os


def combine_all(years: list, processed_folder: str, output_file: str):
    dfs = []
    for year in years:
        path = os.path.join(processed_folder, f"{year}_master.csv")
        if os.path.exists(path):
            print(f"Loading {path}...")
            df = pd.read_csv(path)
            dfs.append(df)
        else:
            print(f"⚠️ Missing {path}, skipping...")

    if dfs:
        combined_df = pd.concat(dfs, ignore_index=True)
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        combined_df.to_csv(output_file, index=False)
        print(f"✅ Combined {len(dfs)} yearly files into {output_file}")
        print(f"Total rows: {len(combined_df)}")
    else:
        print("❌ No yearly master files found.")


if __name__ == "__main__":
    years = ["2020", "2021", "2022", "2023", "2024"]  # adjust as needed
    processed_folder = "data/processed_sample/"
    output_file = os.path.join(processed_folder, "panini_master.csv")
    combine_all(years, processed_folder, output_file)
