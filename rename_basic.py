import os
import re
import json
import argparse
import sys
from collections import defaultdict

def log(message):
    print(message)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(message + "\n")

def parse_ocr_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    grouped = defaultdict(list)
    current_file = None
    header_pattern = re.compile(r"--- (.+?) ---")

    for line in lines:
        match = header_pattern.match(line.strip())
        if match:
            current_file = match.group(1).replace(".png", "")
            grouped[current_file] = []
        elif current_file and line.strip():
            grouped[current_file].append(line.strip())

    return grouped

def extract_study_id_and_clean(lines):
    study_id_pattern = re.compile(r"\b\d{2}-\d{3}\b")
    date_pattern = re.compile(r"\d{1,2}/\d{1,2}/\d{2,4}")
    time_pattern = re.compile(r"\d{1,2}:\d{2} ?(AM|PM)?", re.IGNORECASE)
    noise_terms = {"glintlab"}

    study_id = None
    filename_tokens = []

    for line in lines:
        if date_pattern.search(line) or time_pattern.search(line):
            continue

        words = line.strip().split()
        for word in words:
            cleaned = word.strip(".,;:*+").replace("/", "-")
            if not cleaned or cleaned.lower() in noise_terms:
                continue

            if study_id is None and study_id_pattern.match(cleaned):
                study_id = cleaned

            filename_tokens.append(cleaned)

            if study_id_pattern.match(cleaned):
                break  # stop further tokens from this line

    filename = "_".join(filename_tokens)
    return study_id, filename

def rename_mrxs_files(ocr_txt_path, mrxs_folder):
    global LOG_PATH
    LOG_PATH = os.path.join(mrxs_folder, "rename_log.txt")
    log(f"Logging to: {LOG_PATH}")
    log(f"OCR input: {ocr_txt_path}")
    log(f"MRXS folder: {mrxs_folder}")

    grouped = parse_ocr_file(ocr_txt_path)

    # Generate cleaned filenames
    rename_map = {}
    for fname, lines in grouped.items():
        study_id, cleaned_name = extract_study_id_and_clean(lines)
        rename_map[fname] = cleaned_name

    # Rename matching .mrxs files and associated folders
    renamed = []
    for old_name, new_name in rename_map.items():
        old_folder = os.path.join(mrxs_folder, old_name)
        new_folder = os.path.join(mrxs_folder, new_name)
        old_path = old_folder + ".mrxs"
        new_path = new_folder + ".mrxs"

        if os.path.exists(old_path):
            if not os.path.exists(new_path):  # avoid overwrite
                os.rename(old_path, new_path)
                renamed.append((old_name, new_name))
                log(f"Renamed file: {old_name}.mrxs → {new_name}.mrxs")

                # Rename associated metadata folder
                if os.path.isdir(old_folder):
                    if not os.path.exists(new_folder):
                        os.rename(old_folder, new_folder)
                        log(f"Renamed folder: {old_name}/ → {new_name}/")
                    else:
                        log(f"Skipped folder rename: {new_name}/ already exists.")
            else:
                log(f"Skipped: {new_name}.mrxs already exists.")
        else:
            log(f"File not found: {old_path}")

    log(f"\nRenamed {len(renamed)} file(s).")
    for old, new in renamed:
        log(f" - {old}.mrxs → {new}.mrxs")

    # Optional save mapping
    mapping_path = os.path.join(mrxs_folder, "renamed_files.json")
    with open(mapping_path, "w", encoding="utf-8") as f:
        json.dump(rename_map, f, indent=2)
    log(f"Saved mapping to {mapping_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rename .mrxs files using OCR results.")
    parser.add_argument("--ocr", required=True, help="Path to vision_ocr_results.txt")
    parser.add_argument("--folder", required=True, help="Path to folder containing .mrxs files")
    args = parser.parse_args()

    rename_mrxs_files(args.ocr, args.folder)
