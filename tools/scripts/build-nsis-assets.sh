#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
signet_src="$root/assets/brand/codex13-signet-digital.svg"
favicon_src="$root/assets/brand/codex13-favicon.svg"
out="$root/apps/setup/assets/nsis"
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

im_path() {
  local path="$1"

  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$path"
  else
    printf '%s' "$path"
  fi
}

if [[ ! -f "$signet_src" ]]; then
  echo "Missing source asset: $signet_src" >&2
  exit 1
fi

if [[ ! -f "$favicon_src" ]]; then
  echo "Missing source asset: $favicon_src" >&2
  exit 1
fi

favicon_work="$tmp/codex13-favicon.render.svg"

# The exported favicon SVG can contain an inherited fill="url(#b)" without the
# matching gradient definition. Browsers tolerate it, ImageMagick does not.
# Keep the source untouched and render from a normalized copy.
sed 's/fill="url(#b)"/fill="#ffffff"/g' "$favicon_src" > "$favicon_work"

render_svg() {
  local source="$1"
  local size="$2"
  local target="$3"

  "${im[@]}" -background none "$(im_path "$source")" -resize "${size}x${size}" "$(im_path "$target")"
}

render_white_signet() {
  local size="$1"
  local target="$2"
  local rendered="$tmp/signet-rendered-${size}.png"
  local mask="$tmp/signet-mask-${size}.png"

  render_svg "$signet_src" "$size" "$rendered"
  "${im[@]}" "$(im_path "$rendered")" -alpha extract "$(im_path "$mask")"
  "${im[@]}" \
    -size "${size}x${size}" xc:"#f8fafc" \
    "$(im_path "$mask")" \
    -compose copy_opacity -composite \
    "$(im_path "$target")"
}

render_svg "$favicon_work" 256 "$tmp/codex13-favicon-256.png"
render_svg "$favicon_work" 128 "$tmp/codex13-favicon-128.png"
render_svg "$favicon_work" 64 "$tmp/codex13-favicon-64.png"
render_svg "$favicon_work" 48 "$tmp/codex13-favicon-48.png"
render_svg "$favicon_work" 32 "$tmp/codex13-favicon-32.png"
render_svg "$favicon_work" 16 "$tmp/codex13-favicon-16.png"

render_white_signet 96 "$tmp/codex13-signet-white-96.png"

"${im[@]}" \
  -size 164x32 xc:none \
  -font "Segoe-UI-Semibold" \
  -pointsize 20 \
  -gravity center \
  -fill "#fbbf24" \
  -annotate +0+0 "Codex 13" \
  "$(im_path "$tmp/codex13-wizard-brand.png")"

"${im[@]}" \
  -size 164x30 xc:none \
  -font "Segoe-UI-Semibold" \
  -pointsize 16 \
  -gravity center \
  -fill "#f8fafc" \
  -annotate +0+0 "Student Dev Kit" \
  "$(im_path "$tmp/codex13-wizard-title.png")"

"${im[@]}" \
  -size 64x1 xc:"#f59e0b" \
  "$(im_path "$tmp/codex13-wizard-rule.png")"

"${im[@]}" \
  "$(im_path "$tmp/codex13-favicon-256.png")" \
  "$(im_path "$tmp/codex13-favicon-128.png")" \
  "$(im_path "$tmp/codex13-favicon-64.png")" \
  "$(im_path "$tmp/codex13-favicon-48.png")" \
  "$(im_path "$tmp/codex13-favicon-32.png")" \
  "$(im_path "$tmp/codex13-favicon-16.png")" \
  "$(im_path "$out/codex13-favicon.ico")"

cp "$out/codex13-favicon.ico" "$out/codex13.ico"
cp "$out/codex13-favicon.ico" "$root/assets/brand/codex13-favicon.ico"

"${im[@]}" \
  -size 150x57 xc:"#ffffff" \
  "$(im_path "$tmp/codex13-favicon-48.png")" -geometry 42x42+96+7 -composite \
  BMP3:"$(im_path "$out/codex13-header.bmp")"

"${im[@]}" \
  -size 164x314 xc:"#111827" \
  \( -size 164x314 gradient:"#162033-#111827" \) -compose overlay -composite \
  -compose over \
  "$(im_path "$tmp/codex13-signet-white-96.png")" -geometry 96x96+34+68 -composite \
  "$(im_path "$tmp/codex13-wizard-brand.png")" -geometry 164x32+0+176 -composite \
  "$(im_path "$tmp/codex13-wizard-rule.png")" -geometry 64x1+50+205 -composite \
  "$(im_path "$tmp/codex13-wizard-title.png")" -geometry 164x30+0+214 -composite \
  BMP3:"$(im_path "$out/codex13-wizard.bmp")"

echo "Generated NSIS assets in $out"
