#!/bin/bash
# ========================================================
# Recursively convert all JPG/JPEG/PNG images to WebP.
# - Preserves folder structure
# - Skips unchanged files (incremental build)
# - Deletes WebPs whose originals were removed
# ========================================================

INPUT_DIR="./images"
OUTPUT_DIR="./webp"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Starting WebP conversion..."
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo

# --- Step 1: Convert or update WebPs ---
find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r file; do
  # Relative and output path
  relative_path="${file#$INPUT_DIR/}"
  output_path="$OUTPUT_DIR/${relative_path%.*}.webp"

  # Ensure subfolder exists
  mkdir -p "$(dirname "$output_path")"

  # Skip unchanged
  if [ -f "$output_path" ] && [ "$output_path" -nt "$file" ]; then
    echo "Skipping (unchanged): $relative_path"
    continue
  fi

  # Convert to WebP (high quality)
  cwebp -q 85 -m 6 -mt "$file" -o "$output_path" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Converted: $relative_path → ${relative_path%.*}.webp"
  else
    echo "Error converting: $relative_path"
  fi
done

# --- Step 2: Remove stale WebPs ---
echo
echo "Cleaning up old WebP files..."
find "$OUTPUT_DIR" -type f -iname "*.webp" | while read -r webp_file; do
  relative_path="${webp_file#$OUTPUT_DIR/}"
  original_jpg="$INPUT_DIR/${relative_path%.webp}.jpg"
  original_jpeg="$INPUT_DIR/${relative_path%.webp}.jpeg"
  original_png="$INPUT_DIR/${relative_path%.webp}.png"

  # If no corresponding source image exists → delete
  if [ ! -f "$original_jpg" ] && [ ! -f "$original_jpeg" ] && [ ! -f "$original_png" ]; then
    echo "Deleting stale: $relative_path"
    rm -f "$webp_file"
  fi
done

echo
echo "Done! WebP images up-to-date in: $OUTPUT_DIR"