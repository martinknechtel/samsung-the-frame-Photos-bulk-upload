#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="input"
OUTPUT_DIR="output"
W=1080
H=1920
GAP=30

mkdir -p "$OUTPUT_DIR"

portrait_files=()
landscape_files=()

process_portrait() {
  local src="$1"
  local stem
  stem=$(basename "$src" | sed 's/\.[^.]*$//' | cut -c1-120)
  local out="$OUTPUT_DIR/${stem}.jpg"
  echo "  [portrait] $src"
  magick "$src" \
    -resize "x${H}" \
    -background black \
    -gravity center \
    -extent "${W}x${H}" \
    "$out"
}

make_portrait_collage() {
  local p1="$1" p2="$2" p3="$3" p4="$4"
  local CW=$(( (W - GAP) / 2 ))
  local CH=$(( (H - GAP) / 2 ))
  local s1 s2 s3 s4
  s1=$(basename "$p1" | sed 's/\.[^.]*$//' | cut -c1-30)
  s2=$(basename "$p2" | sed 's/\.[^.]*$//' | cut -c1-30)
  s3=$(basename "$p3" | sed 's/\.[^.]*$//' | cut -c1-30)
  s4=$(basename "$p4" | sed 's/\.[^.]*$//' | cut -c1-30)
  local out="$OUTPUT_DIR/${s1}+${s2}+${s3}+${s4}.jpg"
  echo "  [4-collage] $p1 + $p2 + $p3 + $p4"

  local tmp1="/tmp/frame_p1_$$.jpg" tmp2="/tmp/frame_p2_$$.jpg"
  local tmp3="/tmp/frame_p3_$$.jpg" tmp4="/tmp/frame_p4_$$.jpg"

  local cell_args="-resize ${CW}x${CH}^ -gravity center -extent ${CW}x${CH}"
  magick "$p1" $cell_args "$tmp1"
  magick "$p2" $cell_args "$tmp2"
  magick "$p3" $cell_args "$tmp3"
  magick "$p4" $cell_args "$tmp4"

  local x2=$(( CW + GAP ))
  local y3=$(( CH + GAP ))

  magick -size "${W}x${H}" xc:black \
    \( "$tmp1" \) -geometry "+0+0"       -composite \
    \( "$tmp2" \) -geometry "+${x2}+0"   -composite \
    \( "$tmp3" \) -geometry "+0+${y3}"   -composite \
    \( "$tmp4" \) -geometry "+${x2}+${y3}" -composite \
    "$out"

  rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"
}

make_landscape_collage() {
  local top="$1" bot="$2"
  local stem_top stem_bot
  stem_top=$(basename "$top" | sed 's/\.[^.]*$//' | cut -c1-60)
  stem_bot=$(basename "$bot" | sed 's/\.[^.]*$//' | cut -c1-60)
  local out="$OUTPUT_DIR/${stem_top}+${stem_bot}.jpg"
  echo "  [collage]  $top + $bot"

  local tmp_top="/tmp/frame_top_$$.jpg"
  local tmp_bot="/tmp/frame_bot_$$.jpg"

  magick "$top" -resize "${W}x" "$tmp_top"
  magick "$bot" -resize "${W}x" "$tmp_bot"

  local th bh
  read -r th < <(magick identify -format "%h\n" "$tmp_top")
  read -r bh < <(magick identify -format "%h\n" "$tmp_bot")
  local total_photo_h=$(( th + bh ))

  if (( total_photo_h > H )); then
    local new_th=$(( th * H * 90 / (total_photo_h * 100) ))
    local new_bh=$(( bh * H * 90 / (total_photo_h * 100) ))
    magick "$tmp_top" -resize "x${new_th}" "$tmp_top"
    magick "$tmp_bot" -resize "x${new_bh}" "$tmp_bot"
    th=$new_th; bh=$new_bh
    total_photo_h=$(( th + bh ))
  fi

  local gap=$(( (H - total_photo_h) / 3 ))
  local y_top=$gap
  local y_bot=$(( gap + th + gap ))

  magick -size "${W}x${H}" xc:black \
    \( "$tmp_top" \) -geometry "+0+${y_top}" -composite \
    \( "$tmp_bot" \) -geometry "+0+${y_bot}" -composite \
    "$out"

  rm -f "$tmp_top" "$tmp_bot"
}

# Classify all input photos
for f in "$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg "$INPUT_DIR"/*.png "$INPUT_DIR"/*.heic "$INPUT_DIR"/*.HEIC "$INPUT_DIR"/*.JPG "$INPUT_DIR"/*.PNG; do
  [[ -f "$f" ]] || continue
  read -r iw ih < <(magick identify -format "%w %h\n" "$f")
  if (( iw >= ih )); then
    echo "  [landscape queued] $f (${iw}x${ih})"
    landscape_files+=("$f")
  else
    echo "  [portrait queued]  $f (${iw}x${ih})"
    portrait_files+=("$f")
  fi
done

# Portrait: groups of 4 → 2×2 collage; remainder → full screen
i=0
while (( i < ${#portrait_files[@]} )); do
  if (( i + 3 < ${#portrait_files[@]} )); then
    make_portrait_collage \
      "${portrait_files[$i]}" "${portrait_files[$((i+1))]}" \
      "${portrait_files[$((i+2))]}" "${portrait_files[$((i+3))]}"
    (( i += 4 ))
  else
    process_portrait "${portrait_files[$i]}"
    (( i += 1 ))
  fi
done

# Landscape: pairs → stacked collage; odd one out → full screen
i=0
while (( i < ${#landscape_files[@]} )); do
  if (( i + 1 < ${#landscape_files[@]} )); then
    make_landscape_collage "${landscape_files[$i]}" "${landscape_files[$((i+1))]}"
    (( i += 2 ))
  else
    echo "  [landscape solo] ${landscape_files[$i]}"
    process_portrait "${landscape_files[$i]}"
    (( i += 1 ))
  fi
done

echo ""
echo "Done. Output in $OUTPUT_DIR/"
ls -1 "$OUTPUT_DIR/"
