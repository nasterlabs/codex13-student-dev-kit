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
  local rendered="$tmp/social-signet-rendered-${size}.png"
  local mask="$tmp/social-signet-mask-${size}.png"

  render_svg "$signet_src" "$size" "$rendered"
  "${im[@]}" "$(im_path "$rendered")" -alpha extract "$(im_path "$mask")"
  "${im[@]}" \
    -size "${size}x${size}" xc:"$color" \
    "$(im_path "$mask")" \
    -compose copy_opacity -composite \
    "$(im_path "$target")"
}

make_watermark() {
  local source="$1"
  local opacity="$2"
  local target="$3"

  "${im[@]}" \
    "$(im_path "$source")" \
    -alpha set -channel A -evaluate multiply "$opacity" +channel \
    "$(im_path "$target")"
}

render_signet 132 "#f8fafc" "$tmp/social-signet-white-132.png"
render_signet 144 "#f8fafc" "$tmp/social-signet-white-144.png"
render_signet 168 "#f8fafc" "$tmp/social-signet-white-168.png"
render_signet 188 "#f8fafc" "$tmp/social-signet-white-188.png"
render_signet 420 "#f8fafc" "$tmp/social-signet-white-420.png"
render_signet 460 "#f8fafc" "$tmp/social-signet-white-460.png"

make_watermark "$tmp/social-signet-white-420.png" 0.08 "$tmp/social-signet-watermark-420.png"
make_watermark "$tmp/social-signet-white-460.png" 0.07 "$tmp/social-signet-watermark-460.png"

# Conservative: keeps the current product-card idea, removes accidental chrome,
# strengthens text hierarchy, and makes the footer readable after scaling.
"${im[@]}" \
  -size 1280x640 xc:"#0b1020" \
  \( -size 1280x640 gradient:"#172033-#0b1020" \) -compose overlay -composite \
  -compose over \
  "$(im_path "$tmp/social-signet-watermark-420.png")" -geometry 420x420+790+80 -composite \
  -fill "#f8fafc" -draw "roundrectangle 88,78 1192,562 36,36" \
  -fill "#111827" -draw "roundrectangle 96,86 1184,554 30,30" \
  -fill "#243044" -draw "roundrectangle 97,87 1183,553 29,29" \
  -fill "#121a2a" -draw "roundrectangle 99,89 1181,551 27,27" \
  "$(im_path "$tmp/social-signet-white-144.png")" -geometry 144x144+150+154 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 78 \
  -fill "#fbbf24" \
  -gravity northwest \
  -annotate +338+138 "Codex 13" \
  -font "Segoe-UI-Semibold" \
  -pointsize 48 \
  -fill "#f8fafc" \
  -annotate +342+232 "Student Dev Kit" \
  -size 236x3 xc:"#f59e0b" -geometry 236x3+344+306 -composite \
  -font "Segoe-UI" \
  -pointsize 35 \
  -fill "#dbeafe" \
  -annotate +344+348 "Portable Windows development environments" \
  -annotate +344+392 "for classrooms, workshops and projects." \
  -font "Segoe-UI-Semibold" \
  -pointsize 25 \
  -fill "#93c5fd" \
  -annotate +152+494 "codex13.dev" \
  -font "Segoe-UI-Semibold" \
  -pointsize 25 \
  -fill "#cbd5e1" \
  -annotate +928+494 "Classroom-ready" \
  "$(im_path "$out/social-preview-conservative.png")"

# Branding: the default OpenGraph image. It combines the stronger card layout
# with the clearer product message used by the conservative variant.
"${im[@]}" \
  -size 1280x640 xc:"#070d1a" \
  \( -size 1280x640 gradient:"#1b2940-#070d1a" \) -compose overlay -composite \
  -compose over \
  "$(im_path "$tmp/social-signet-watermark-460.png")" -geometry 460x460+756+72 -composite \
  -fill "#fbbf24" -draw "roundrectangle 88,82 1192,558 34,34" \
  -fill "#f8fafc" -draw "roundrectangle 94,88 1186,552 30,30" \
  -fill "#101827" -draw "roundrectangle 100,94 1180,546 26,26" \
  "$(im_path "$tmp/social-signet-white-188.png")" -geometry 188x188+140+144 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 84 \
  -fill "#fbbf24" \
  -gravity northwest \
  -annotate +376+132 "Codex 13" \
  -font "Segoe-UI-Semibold" \
  -pointsize 52 \
  -fill "#f8fafc" \
  -annotate +380+234 "Student Dev Kit" \
  -size 300x4 xc:"#f59e0b" -geometry 300x4+382+316 -composite \
  -font "Segoe-UI" \
  -pointsize 34 \
  -fill "#dbeafe" \
  -annotate +382+358 "Portable Windows development environments" \
  -annotate +382+402 "for classrooms, workshops and projects." \
  -font "Segoe-UI-Semibold" \
  -pointsize 27 \
  -fill "#93c5fd" \
  -annotate +154+494 "codex13.dev" \
  -font "Segoe-UI-Semibold" \
  -pointsize 27 \
  -fill "#e5e7eb" \
  -annotate +944+494 "DevEx tooling" \
  "$(im_path "$out/social-preview-branding.png")"

# Minimal: fewer elements and bigger type for small social embeds.
"${im[@]}" \
  -size 1280x640 xc:"#090f1f" \
  \( -size 1280x640 gradient:"#162033-#090f1f" \) -compose overlay -composite \
  -compose over \
  "$(im_path "$tmp/social-signet-watermark-420.png")" -geometry 420x420+810+112 -composite \
  "$(im_path "$tmp/social-signet-white-188.png")" -geometry 188x188+116+166 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 92 \
  -fill "#fbbf24" \
  -gravity northwest \
  -annotate +356+146 "Codex 13" \
  -font "Segoe-UI-Semibold" \
  -pointsize 58 \
  -fill "#f8fafc" \
  -annotate +360+260 "Student Dev Kit" \
  -size 300x4 xc:"#f59e0b" -geometry 300x4+362+342 -composite \
  -font "Segoe-UI" \
  -pointsize 37 \
  -fill "#dbeafe" \
  -annotate +360+392 "Portable Windows development environments" \
  -font "Segoe-UI-Semibold" \
  -pointsize 28 \
  -fill "#93c5fd" \
  -annotate +360+488 "codex13.dev" \
  "$(im_path "$out/social-preview-minimal.png")"

# Product landing page: a little more editorial, still restrained and readable.
"${im[@]}" \
  -size 1280x640 xc:"#0b1020" \
  \( -size 1280x640 gradient:"#172033-#0b1020" \) -compose overlay -composite \
  -compose over \
  -fill "#f8fafc" -draw "roundrectangle 760,86 1178,554 32,32" \
  -fill "#101827" -draw "roundrectangle 768,94 1170,546 26,26" \
  "$(im_path "$tmp/social-signet-watermark-420.png")" -geometry 420x420+766+110 -composite \
  "$(im_path "$tmp/social-signet-white-144.png")" -geometry 144x144+832+166 -composite \
  -font "Segoe-UI-Semibold" \
  -pointsize 78 \
  -fill "#fbbf24" \
  -gravity northwest \
  -annotate +104+136 "Codex 13" \
  -font "Segoe-UI-Semibold" \
  -pointsize 50 \
  -fill "#f8fafc" \
  -annotate +108+232 "Student Dev Kit" \
  -size 250x4 xc:"#f59e0b" -geometry 250x4+110+312 -composite \
  -font "Segoe-UI" \
  -pointsize 35 \
  -fill "#dbeafe" \
  -annotate +110+356 "Portable Windows development" \
  -annotate +110+400 "environments for classrooms." \
  -font "Segoe-UI-Semibold" \
  -pointsize 28 \
  -fill "#93c5fd" \
  -annotate +110+502 "codex13.dev" \
  -font "Segoe-UI-Semibold" \
  -pointsize 28 \
  -fill "#f8fafc" \
  -annotate +832+352 "Setup" \
  -fill "#cbd5e1" \
  -annotate +832+402 "Launcher" \
  -annotate +832+452 "Manager" \
  "$(im_path "$out/social-preview-landing.png")"

cp "$out/social-preview-branding.png" "$out/social-preview.png"

echo "Generated social preview variants in $out"
