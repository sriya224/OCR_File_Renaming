import os
import argparse
import openslide

def extract_labels(input_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    mrxs_files = [f for f in os.listdir(input_dir) if f.lower().endswith('.mrxs')]

    if not mrxs_files:
        print("No .mrxs files found in the folder.")
        return

    for filename in mrxs_files:
        mrxs_path = os.path.join(input_dir, filename)
        try:
            slide = openslide.OpenSlide(mrxs_path)
            if 'label' in slide.associated_images:
                label_img = slide.associated_images['label']
                out_path = os.path.join(
                    output_dir, os.path.splitext(filename)[0] + '_label.png'
                )
                label_img.save(out_path)
                print(f"Saved label image for {filename} to {out_path}")
            else:
                print(f"No label image found in {filename}")
        except Exception as e:
            print(f"Failed to process {filename}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract label images from MRXS files in a folder.")
    parser.add_argument("input_dir", help="Path to folder containing .mrxs files")
    parser.add_argument("output_dir", help="Path to folder where PNG label images will be saved")
    args = parser.parse_args()

    extract_labels(args.input_dir, args.output_dir)
