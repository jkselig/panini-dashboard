"""
Combine all raw Panini checklist CSVs for a given year into one master file.
- Adds SET_FILE_NAME and YEAR columns
- Saves to data/processed_sample/{year}_master.csv
"""

import pandas as pd
import os


def combine_year(year: str, input_folder: str, output_folder: str):
    all_data = []

    for file in os.listdir(input_folder):
        if file.lower().endswith(".csv"):
            file_path = os.path.join(input_folder, file)
            try:
                df = pd.read_csv(file_path)
                df["SET_FILE_NAME"] = file.replace(".csv", "")
                df["YEAR"] = year
                all_data.append(df)
            except Exception as e:
                print(f"⚠️ Error reading {file}: {e}")

    if all_data:
        combined_df = pd.concat(all_data, ignore_index=True)
        os.makedirs(output_folder, exist_ok=True)
        output_file = os.path.join(output_folder, f"{year}_master.csv")
        combined_df.to_csv(output_file, index=False)
        print(f"✅ Combined {len(all_data)} files for {year}")
        print(f"📄 Saved to: {output_file}")
        print(f"Total rows: {len(combined_df)}")
    else:
        print(f"No CSVs found in {input_folder}")


if __name__ == "__main__":
    # Example usage: combine all raw 2020 checklists
    year = "2020"
    input_folder = f"data/raw_sample/{year}/"
    output_folder = "data/processed_sample/"
    combine_year(year, input_folder, output_folder)
