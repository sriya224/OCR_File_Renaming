# Image Renaming Quick Action
This project aims to automate the process of naming computerized slide image files in a histopathology lab setting, leveraging macOS Quick Actions and Apple Vision OCR to provide an accurate and user-friendly renaming workflow.

## Pipeline Overview
[insert workflow diagram]

## Input Files
The following files are required to execute our image renaming pipeline:
- *quick_action_driver.sh*: 
- *open_label_images.py*:
- *VisionOCRDemo/*:
- *file_renaming_outliers_excel.py*:

## Output Files
- *ocr_results.txt*
- *rename_log.txt*
- *expanded_ocr_results.xlsx*

## Installation
1. [Optional] Replicate team's environment
   Follow the instructions below to ensure necessary packages are installed.
   > Download miniconda
   > Create a new conda environment
     > 'conda create -n ocrenv python=3.11 notebook ipykernel'
   > Pip install the following packages
     > 'pip install openslide-python openslide-bin pandas openpyxl'
   
2. Download files from this repository to an accessible location
   
3. Build the binary executable for *VisionOCRDemo/*
   > Navigate to the parent directory of *VisionOCRDemo/*
   > Run the following command
     > swift build -c release
   > If issues arise, the following commands can be helpful to restart
     > swift package clean
     > rm -rf .build

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

## Requirements

## Debug
