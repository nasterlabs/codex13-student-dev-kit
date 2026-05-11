#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_dir="$root/docs/screenshots"
out="$root/docs/screenshots/framed"
tmp="$root/.build/assets/screenshots"

if command -v magick >/dev/null 2>&1; then
  im=(magick)
elif command -v convert >/dev/null 2>&1; then
  im=(convert)
else
  echo "ImageMagick is required. Install it and rerun this script." >&2
  exit 1
fi

mkdir -p "$out" "$tmp"

im_path() {
  local path="$1"

  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$path"
  else
    printf '%s' "$path"
  fi
}

shopt -s nullglob

sources=(
  "$source_dir"/*.png
  "$source_dir"/*.jpg
  "$source_dir"/*.jpeg
)

if [[ ${#sources[@]} -eq 0 ]]; then
  echo "No screenshots found in $source_dir" >&2
  exit 1
fi

for source in "${sources[@]}"; do
  stem="$(basename "${source%.*}")"
  resized="$tmp/$stem.resized.png"
  bordered="$tmp/$stem.bordered.png"
  mask="$tmp/$stem.mask.png"
  rounded="$tmp/$stem.rounded.png"
  shadow="$tmp/$stem.shadow.png"
  target="$out/$stem.png"

  "${im[@]}" \
    "$(im_path "$source")" \
    -resize "1120x680" \
    "$(im_path "$resized")"

  "${im[@]}" \
    "$(im_path "$resized")" \
    -bordercolor "#f8fafc" \
    -border 8 \
    "$(im_path "$bordered")"

  dimensions="$("${im[@]}" identify -format "%w %h" "$(im_path "$bordered")")"
  read -r width height <<< "$dimensions"

  "${im[@]}" \
    -size "${width}x${height}" xc:none \
    -fill white \
    -draw "roundrectangle 0,0 $((width - 1)),$((height - 1)) 22,22" \
    "$(im_path "$mask")"

  "${im[@]}" \
    "$(im_path "$bordered")" \
    "$(im_path "$mask")" \
    -alpha off \
    -compose copy_opacity -composite \
    "$(im_path "$rounded")"

  "${im[@]}" \
    \( "$(im_path "$rounded")" -background "#020617" -shadow 38x18+0+28 \) \
    "$(im_path "$rounded")" \
    -background none \
    -compose over \
    -layers merge +repage \
    "$(im_path "$shadow")"

  "${im[@]}" \
    -size 1400x900 xc:"#dbe7ee" \
    \( -size 1400x900 gradient:"#f8fafc-#cbd5e1" \) -compose multiply -composite \
    -fill "#fbbf24" -draw "rectangle 0,0 1400,10" \
    -fill "#1d4ed8" -draw "rectangle 0,10 196,18" \
    -fill "#4f46e5" -draw "rectangle 196,10 420,18" \
    "$(im_path "$shadow")" \
    -gravity center \
    -geometry +0+8 \
    -compose over -composite \
    "$(im_path "$target")"

  echo "Generated $target"
done
