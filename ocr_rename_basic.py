import os
import re
import json
import argparse
from collections import defaultdict, Counter

def parse_ocr_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    grouped = defaultdict(list)
    current_file = None
    header_pattern = re.compile(r"--- (.+?) ---")

    for line in lines:
        match = header_pattern.match(line.strip())
        if match:
            current_file = match.group(1).replace("_label.png", "")
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
    grouped = parse_ocr_file(ocr_txt_path)

    # Generate cleaned filenames
    rename_map = {}
    for fname, lines in grouped.items():
        study_id, cleaned_name = extract_study_id_and_clean(lines)
        rename_map[fname] = cleaned_name

    # Rename matching .mrxs files
    renamed = []
    for old_name, new_name in rename_map.items():
        old_path = os.path.join(mrxs_folder, old_name + "_label.png")
        new_path = os.path.join(mrxs_folder, new_name + ".mrxs")
        if os.path.exists(old_path):
            if not os.path.exists(new_path):  # avoid overwrite
                os.rename(old_path, new_path)
                renamed.append((old_name, new_name))
            else:
                print(f"Skipped: {new_name}.png already exists.")
        else:
            print(f"File not found: {old_path}")

    print(f"\nRenamed {len(renamed)} file(s).")
    for old, new in renamed:
        print(f" - {old}.png → {new}.png")

    # Optional save mapping
    with open("renamed_files.json", "w", encoding="utf-8") as f:
        json.dump(rename_map, f, indent=2)
    print("Saved mapping to renamed_files.json")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rename .mrxs files using OCR results.")
    parser.add_argument("--ocr", required=True, help="Path to vision_ocr_results.txt")
    parser.add_argument("--folder", required=True, help="Path to folder containing .mrxs files")
    args = parser.parse_args()

    rename_mrxs_files(args.ocr, args.folder)
