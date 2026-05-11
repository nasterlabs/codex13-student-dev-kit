#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
signet_src="$root/assets/brand/codex13-signet-digital.svg"
out="$root/docs/assets"
tmp="$root/.build/assets"

if command -v magick >/dev/null 2>&1; then
  im=(magick)
elif command -v convert >/dev/null 2>&1; then
  im=(convert)
else
  echo "ImageMagick is required. Install it and rerun this script." >&2
  exit 1
fi

mkdir -p "$out" "$tmp"

if [[ ! -f "$signet_src" ]]; then
  echo "Missing source asset: $signet_src" >&2
  exit 1
fi

im_path() {
  local path="$1"

  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$path"
  else
    printf '%s' "$path"
  fi
}

render_svg() {
  local source="$1"
  local width="$2"
  local target="$3"

  "${im[@]}" -background none "$(im_path "$source")" -resize "${width}x${width}" "$(im_path "$target")"
}

render_signet() {
  local size="$1"
  local color="$2"
  local target="$3"
  local rendered="$tmp/readme-signet-rendered-${size}.png"
  local mask="$tmp/readme-signet-mask-${size}.png"

  render_svg "$signet_src" "$size" "$rendered"
  "${im[@]}" "$(im_path "$rendered")" -alpha extract "$(im_path "$mask")"
  "${im[@]}" \
    -size "${size}x${size}" xc:"$color" \
    "$(im_path "$mask")" \
    -compose copy_opacity -composite \
    "$(im_path "$target")"
}

render_signet 132 "#f8fafc" "$tmp/readme-signet-white-132.png"
render_signet 132 "#111827" "$tmp/readme-signet-dark-132.png"

"${im[@]}" \
  -size 1200x360 xc:"#111827" \
  \( -size 1200x360 gradient:"#162033-#111827" \) -compose overlay -composite \
  -compose over \
  "$(im_path "$tmp/readme-signet-white-132.png")" -geometry 132x132+112+76 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 58 \
  -fill "#fbbf24" \
  -gravity northwest \
  -annotate +292+86 "Codex 13" \
  -size 170x2 xc:"#f59e0b" -geometry 170x2+296+166 -composite \
  -font "Segoe-UI" \
  -pointsize 34 \
  -fill "#f8fafc" \
  -annotate +294+190 "Student Dev Kit" \
  -font "Segoe-UI" \
  -pointsize 24 \
  -fill "#cbd5e1" \
  -annotate +294+244 "Portable Windows development environments for classrooms and workshops" \
  "$(im_path "$out/readme-header-dark.png")"

"${im[@]}" \
  -size 1200x360 xc:"#f8fafc" \
  \( -size 1200x360 gradient:"#ffffff-#e5e7eb" \) -compose multiply -composite \
  -compose over \
  "$(im_path "$tmp/readme-signet-dark-132.png")" -geometry 132x132+112+76 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 58 \
  -fill "#b45309" \
  -gravity northwest \
  -annotate +292+86 "Codex 13" \
  -size 170x2 xc:"#d97706" -geometry 170x2+296+166 -composite \
  -font "Segoe-UI" \
  -pointsize 34 \
  -fill "#111827" \
  -annotate +294+190 "Student Dev Kit" \
  -font "Segoe-UI" \
  -pointsize 24 \
  -fill "#475569" \
  -annotate +294+244 "Portable Windows development environments for classrooms and workshops" \
  "$(im_path "$out/readme-header-light.png")"

echo "Generated README header assets in $out"
