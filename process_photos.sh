#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="input"
OUTPUT_DIR="output"
W=1080
H=1920

mkdir -p "$OUTPUT_DIR"

landscape_files=()

process_portrait() {
  local src="$1"
  local stem
  stem=$(basename "$src" | sed 's/\.[^.]*$//' | cut -c1-120)
  local out="$OUTPUT_DIR/${stem}.jpg"
  echo "  [portrait] $src"
  # Scale so height = 1080, pad left/right with black
  magick "$src" \
    -resize "x${H}" \
    -background black \
    -gravity center \
    -extent "${W}x${H}" \
    "$out"
}

make_collage() {
  local top="$1" bot="$2"
  local stem_top stem_bot
  stem_top=$(basename "$top" | sed 's/\.[^.]*$//' | cut -c1-60)
  stem_bot=$(basename "$bot" | sed 's/\.[^.]*$//' | cut -c1-60)
  local out="$OUTPUT_DIR/${stem_top}+${stem_bot}.jpg"
  echo "  [collage]  $top + $bot"

  local tmp_top="/tmp/frame_top_$$.jpg"
  local tmp_bot="/tmp/frame_bot_$$.jpg"

  # Scale each photo to canvas width
  magick "$top" -resize "${W}x" "$tmp_top"
  magick "$bot" -resize "${W}x" "$tmp_bot"

  # Get actual heights after resize
  local th bh
  read -r th < <(magick identify -format "%h\n" "$tmp_top")
  read -r bh < <(magick identify -format "%h\n" "$tmp_bot")
  local total_photo_h=$(( th + bh ))

  # If combined photos exceed canvas, scale both down proportionally
  if (( total_photo_h > H )); then
    local new_th=$(( th * H * 90 / (total_photo_h * 100) ))
    local new_bh=$(( bh * H * 90 / (total_photo_h * 100) ))
    magick "$tmp_top" -resize "x${new_th}" "$tmp_top"
    magick "$tmp_bot" -resize "x${new_bh}" "$tmp_bot"
    th=$new_th; bh=$new_bh
    total_photo_h=$(( th + bh ))
  fi

  # Equal gaps: top, between photos, bottom
  local gap=$(( (H - total_photo_h) / 3 ))
  local y_top=$gap
  local y_bot=$(( gap + th + gap ))

  magick -size "${W}x${H}" xc:black \
    \( "$tmp_top" \) -geometry "+0+${y_top}" -composite \
    \( "$tmp_bot" \) -geometry "+0+${y_bot}" -composite \
    "$out"

  rm -f "$tmp_top" "$tmp_bot"
}

# Sort into portrait / landscape
for f in "$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg "$INPUT_DIR"/*.png "$INPUT_DIR"/*.heic "$INPUT_DIR"/*.HEIC "$INPUT_DIR"/*.JPG "$INPUT_DIR"/*.PNG; do
  [[ -f "$f" ]] || continue
  read -r iw ih < <(magick identify -format "%w %h\n" "$f")
  if (( iw >= ih )); then
    echo "  [landscape queued] $f (${iw}x${ih})"
    landscape_files+=("$f")
  else
    process_portrait "$f"
  fi
done

# Pair up landscape photos into collages
i=0
while (( i < ${#landscape_files[@]} )); do
  if (( i + 1 < ${#landscape_files[@]} )); then
    make_collage "${landscape_files[$i]}" "${landscape_files[$((i+1))]}"
    (( i += 2 ))
  else
    # Odd one out — treat like portrait (center with black bars)
    echo "  [landscape solo] ${landscape_files[$i]}"
    process_portrait "${landscape_files[$i]}"
    (( i += 1 ))
  fi
done

echo ""
echo "Done. Output in $OUTPUT_DIR/"
ls -1 "$OUTPUT_DIR/"
