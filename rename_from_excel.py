
import os
import argparse
import pandas as pd

def rename_from_excel(excel_path, mrxs_folder, log_folder, log_path="rename_log_from_excel.txt"):
    df = pd.read_excel(excel_path)

    log_entries = []
    renamed_count = 0

    if "Original File Name" not in df.columns or "New File Name" not in df.columns:
        log_entries.append("Excel must contain 'Original File Name' and 'New File Name' columns.")
    
    for _, row in df.iterrows():
        original = row["Original File Name"]
        new = row["New File Name"]

        old_path = os.path.join(mrxs_folder, original)
        new_path = os.path.join(mrxs_folder, new)

        if os.path.exists(old_path):
            if not os.path.exists(new_path):  # avoid overwriting
                os.rename(old_path, new_path)
                log_entries.append(f"Renamed: {original} → {new}")
                renamed_count += 1
            else:
                log_entries.append(f"Skipped: {new} already exists.")
        else:
            log_entries.append(f"File not found: {original}")
    
    log_entries.append(f"✔ Renaming complete. {renamed_count} file(s) renamed. Log saved to {log_path}")
    with open(os.path.join(log_folder, log_path), "w", encoding="utf-8") as f:
        for entry in log_entries:
            f.write(entry + "\n")
        f.write(f"\nTotal files renamed: {renamed_count}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rename .mrxs files using Excel sheet mapping.")
    parser.add_argument("--excel", required=True, help="Path to Excel file with Original/New filenames")
    parser.add_argument("--folder", required=True, help="Path to folder containing .mrxs files")
    parser.add_argument("--log", required=True, help="Path to folder containing log files")
    args = parser.parse_args()

    rename_from_excel(args.excel, args.folder, args.log)
