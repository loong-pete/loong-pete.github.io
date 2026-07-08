#!/bin/bash
# Compress all product images in-place
# - Resizes to max 1400px on the longest side
# - Keeps originals in _originals/ folder as backup
# - Skips already-processed files

REPO="/Users/pete2026/Desktop/WOODWORKS/loong-pete.github.io"
BACKUP="$REPO/_originals"
MAX_SIZE=1400
count=0
skipped=0

echo "Starting image compression..."
echo "Backup folder: $BACKUP"
echo ""

find "$REPO" \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.JPG" -o -name "*.JPEG" -o -name "*.png" -o -name "*.PNG" \) \
  ! -path "*/_originals/*" \
  ! -name "loong-pete-logo*" \
  ! -name "Black-Walnut-Wood*" | while read -r file; do

  # Get relative path for backup
  rel="${file#$REPO/}"
  backup_file="$BACKUP/$rel"
  backup_dir="$(dirname "$backup_file")"

  # Skip if already backed up (already processed)
  if [ -f "$backup_file" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  # Get current dimensions
  width=$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/{print $2}')
  height=$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/{print $2}')

  if [ -z "$width" ] || [ -z "$height" ]; then
    echo "  SKIP (unreadable): $rel"
    continue
  fi

  # Back up original
  mkdir -p "$backup_dir"
  cp "$file" "$backup_file"

  # Resize if larger than MAX_SIZE
  if [ "$width" -gt "$MAX_SIZE" ] || [ "$height" -gt "$MAX_SIZE" ]; then
    sips --resampleHeightWidthMax $MAX_SIZE "$file" --out "$file" > /dev/null 2>&1
  fi

  # Re-save at reduced quality (85)
  sips -s format jpeg -s formatOptions 85 "$file" --out "$file" > /dev/null 2>&1

  new_size=$(du -sh "$file" | awk '{print $1}')
  echo "  ✓ $rel → $new_size"
  count=$((count + 1))
done

echo ""
echo "Done! Originals backed up to _originals/"
