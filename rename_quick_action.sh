#!/bin/bash

# Activate conda
eval "$(/Users/minimac/miniconda3/bin/conda shell.bash hook)"  # adjust this path if needed
conda activate ocrenv

# --- Validate input ---
# Check if it's a file
if [ ! -f "$1" ]; then
    osascript -e 'display alert "Invalid Selection" message "Please select a valid Excel file, not a folder."'
    exit 1
fi

# Check if it's an Excel file (by extension)
case "$1" in
    *.xlsx|*.xls)
        ;; # valid, do nothing
    *)
        osascript -e 'display alert "Invalid File" message "Please select a .xlsx or .xls file."'
        exit 1
        ;;
esac

EXTRACT_IMAGES="/Users/minimac/Downloads/Slide_Renaming/rename_from_excel.py"
LOG_FOLDER=$(dirname "${1}")
MRXS_FOLDER=$(dirname "${LOG_FOLDER}")

python "$EXTRACT_IMAGES" --excel "$1" --folder "$MRXS_FOLDER" --log "$LOG_FOLDER"
