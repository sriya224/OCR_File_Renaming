# Image Renaming Quick Action
This project aims to automate the process of naming computerized slide image files in a histopathology lab setting, leveraging macOS Quick Actions and Apple Vision OCR to provide an accurate and user-friendly renaming workflow.

## Table of Contents
- Overview
- Installation/Requirements
- Usage
- Workflow Diagram
- Pipeline Components
- Input Files
- Output Files
- Script Details
- Future Directions

## Overview

## Installation/Requirements
1. [Optional] Replicate team's environment
   Follow the instructions below to ensure necessary packages are installed.
   > Download miniconda<br>
   Create a new conda environment<br>
   'conda create -n ocrenv python=3.11 notebook ipykernel'<br>
   Pip install the following packages<br>
   'pip install openslide-python openslide-bin pandas openpyxl'<br>
   
2. Download files from this repository to an accessible location
   
3. Build the binary executable for *VisionOCRDemo/*
   > Navigate to the parent directory of *VisionOCRDemo/*<br>
   Run the following command<br>
   swift build -c release<br>
   If issues arise, the following commands can be helpful to restart<br>
   swift package clean<br>
   rm -rf .build<br>

4. Customize file paths in *quick_action_driver.sh*
   [insert screenshot of shell script block]
   Replace the paths for EXTRACT_IMAGES, RUN_OCR,

## Usage
1. Navigate to your desired folder of .mrxs images
2. Left click on folder and select Quick Actions: Rename
3. Expected output should be included into a timestamped sub-folder containing versions of the following files:
   > Vision_OCR.txt
   
   > Log.txt
   
   > file_renaming_excel.xlsx

## Workflow Diagram
[workflow diagram to be inserted]

## Input Files
The following files are required to execute our image renaming pipeline:
- *quick_action_driver.sh*: main driver script in Automator which accesses the following scripts to generate an end-to-end workflow
- *open_label_images.py*: Python script which takes in a folder of mrxs images and extracts label images as pngs into a designated output folder 
- *VisionOCRDemo/*: Swift package which performs OCR on a folder of png images and reports the text and confidence scores of extracted fields for each image
- *file_renaming_outliers_excel.py*: Python script which takes a text file of OCR results and a folder of label images and parses it into a human-readable excel sheet with the following columns:

## Output Files
- *ocr_results.txt*: a text file containing the text and confidence scores of extracted fields for each image from OCR
- *rename_log.txt*: an output log which tracks the previous and new name of each file renamed in the folder
- *expanded_ocr_results.xlsx*: an excel spreadsheet of the following format:
   
## Script Details
Note: helpful to run scripts individually for debugging purposes

open_label_images.py
Usage:

python open_label_images.py --input /path/to/mrxs_folder --output /path/to/label_output
Arguments:

--input: Path to folder containing .mrxs images.
--output: Path to save extracted label images as .png

add other files

## Future Directions

