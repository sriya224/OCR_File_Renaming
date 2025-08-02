#!/bin/bash

# Activate conda
# --------------
eval "$(/Users/minimac/miniconda3/bin/conda shell.bash hook)"  # adjust this path if needed
conda activate ocrenv

# Can remove
# ----------
# Debug: Check active env
# echo "Active Conda environment: $CONDA_DEFAULT_ENV"
# which python
# python --version
# Debug: Check openslide
# python -c "import openslide; print('Openslide is available:', openslide.__version__)" || echo "Openslide not found"

# EDIT PATHS HERE
# ---------------
EXTRACT_IMAGES="/Users/minimac/Downloads/Slide_Renaming/open_label_images.py"
RUN_OCR="/Users/minimac/Downloads/VisionOCRDemo/.build/release/VisionOCRDemo"
RENAME_FILES="/Users/minimac/Downloads/Slide_Renaming/file_renaming_outliers_excel.py"
TEMP_PATH="/Users/minimac/tmp/"

# Main script starts here
# -----------------------
mkdir -p $TEMP_PATH

# Temp list of folders to run script on
folders_to_process=()

# Store ungrouped files separately
ungrouped_files=()

# Loop through input items
for item in "$@"; do
   if [ -d "$item" ]; then
      folders_to_process+=("$(realpath "$item")")
   elif [ -f "$item" ]; then
      ungrouped_files+=("$(realpath "$item")")
   fi
done

# If there are floating files, group them into a subfolder
if [ "${#ungrouped_files[@]}" -gt 0 ]; then
    parent_dir=$(dirname "${ungrouped_files[0]}")
    timestamp=$(date +"%Y%m%d_%H%M")
    new_folder="$parent_dir/OCR_Input_$timestamp"
    mkdir -p "$new_folder"

    for file in "${ungrouped_files[@]}"; do
        mv "$file" "$new_folder/"
    done

    folders_to_process+=("$new_folder")
fi

for folder in "${folders_to_process[@]}"; do
	# Store label pngs in tmp folder
    echo "Extracting label images from: [$folder]..."
    python "$EXTRACT_IMAGES" "$folder" -o "$TEMP_PATH$(basename "$folder")"

	# create folder for output files
	timestamp=$(date +"%m.%d.%Y_%H-%M")
    output_name="outputs_$timestamp"
	output_folder="$folder/$output_name"
    mkdir -p "$output_folder"

	# Extract label text fields from pngs in tmp folder
	echo "Reading text from label images..."
	"$RUN_OCR" "$TEMP_PATH$(basename "$folder")" "$output_folder" 

	# Rename files using extracted label text
	echo "Renaming mrxs files based on label text"
	python "$RENAME_FILES" --ocr "${output_folder}/ocr_results.txt" --folder "$folder" --labels "$TEMP_PATH$(basename "$folder")" -o "$output_folder"

	rm -r "$TEMP_PATH" 
done

# Print path to image folder after processing
for folder in "${folders_to_process[@]}"; do
    echo $(basename "$folder")
done
