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

  "${im[@]}" -background none "$source" -resize "${size}x${size}" "$target"
}

render_white_signet() {
  local size="$1"
  local target="$2"
  local rendered="$tmp/signet-rendered-${size}.png"
  local mask="$tmp/signet-mask-${size}.png"

  render_svg "$signet_src" "$size" "$rendered"
  "${im[@]}" "$rendered" -alpha extract "$mask"
  "${im[@]}" \
    -size "${size}x${size}" xc:"#f8fafc" \
    "$mask" \
    -compose copy_opacity -composite \
    "$target"
}

render_svg "$favicon_work" 256 "$tmp/codex13-favicon-256.png"
render_svg "$favicon_work" 128 "$tmp/codex13-favicon-128.png"
render_svg "$favicon_work" 64 "$tmp/codex13-favicon-64.png"
render_svg "$favicon_work" 48 "$tmp/codex13-favicon-48.png"
render_svg "$favicon_work" 32 "$tmp/codex13-favicon-32.png"
render_svg "$favicon_work" 16 "$tmp/codex13-favicon-16.png"

render_white_signet 96 "$tmp/codex13-signet-white-96.png"

"${im[@]}" \
  "$tmp/codex13-favicon-256.png" \
  "$tmp/codex13-favicon-128.png" \
  "$tmp/codex13-favicon-64.png" \
  "$tmp/codex13-favicon-48.png" \
  "$tmp/codex13-favicon-32.png" \
  "$tmp/codex13-favicon-16.png" \
  "$out/codex13-favicon.ico"

cp "$out/codex13-favicon.ico" "$out/codex13.ico"
cp "$out/codex13-favicon.ico" "$root/assets/brand/codex13-favicon.ico"

"${im[@]}" \
  -size 150x57 xc:"#ffffff" \
  "$tmp/codex13-favicon-48.png" -geometry 42x42+96+7 -composite \
  BMP3:"$out/codex13-header.bmp"

"${im[@]}" \
  -size 164x314 xc:"#111827" \
  \( -size 164x314 gradient:"#162033-#111827" \) -compose overlay -composite \
  -compose over \
  "$tmp/codex13-signet-white-96.png" -geometry 96x96+34+132 -composite \
  BMP3:"$out/codex13-wizard.bmp"

echo "Generated NSIS assets in $out"
