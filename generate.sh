#!/bin/bash
# ============================================================================
#  rCoon App Store Screenshot Generator
#  Target: iPhone 15/16 Pro Max — 1290 x 2796px
#  Tool:   ImageMagick 7+
#  Config: screenshots.conf (iphone_file|headline|subtitle)
#  Usage:  ./generate.sh                          (generate all from screenshots.conf)
#          ./generate.sh -c bright                 (use screenshots_bright.conf)
#          ./generate.sh -c bright 1 3 7           (specific screenshots from bright config)
# ============================================================================

set -e

# ── Dimensions ───────────────────────────────────────────────────────────────
W=1290
H=2796

# ── Layout ──────────────────────────────────────────────────────────────────
PHONE_SCALE=82            # % of screenshot width
TOP_PAD=60                # Top margin for headline
HEADLINE_SIZE=90          # Headline font size
SUBTITLE_SIZE=64          # Subtitle font size
SUBTITLE_GAP=25           # Gap between headline bottom and subtitle
PHONE_Y=460               # Phone Y offset

# ── Background ──────────────────────────────────────────────────────────────
BG_FILE="warm_blobs_light.png"

# ── Fonts ────────────────────────────────────────────────────────────────────
FONT_HEADLINE="/tmp/poppins-font/Poppins-Bold.ttf"
FONT_SUBTITLE="/tmp/poppins-font/Poppins-Bold.ttf"

# ── Colors ───────────────────────────────────────────────────────────────────
HEADLINE_COLOR='#1A1A1A'
SUBTITLE_COLOR='#555555'

# ── Directories ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Parse -c flag for config variant ────────────────────────────────────────
CONF_VARIANT=""
if [ "$1" = "-c" ]; then
  CONF_VARIANT="$2"
  shift 2
fi
if [ -n "$CONF_VARIANT" ]; then
  CONF_FILE="${SCRIPT_DIR}/screenshots_${CONF_VARIANT}.conf"
else
  CONF_FILE="${SCRIPT_DIR}/screenshots.conf"
fi
IPHONE_DIR="${SCRIPT_DIR}/iphones"
BG_DIR="${SCRIPT_DIR}/backgrounds"
OUTPUT_DIR="${SCRIPT_DIR}/output"
TMP_DIR="/tmp/rcoon-screenshots"

mkdir -p "$OUTPUT_DIR" "$TMP_DIR" "$BG_DIR"

# ── Read config ──────────────────────────────────────────────────────────────
SCREENSHOTS=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  SCREENSHOTS+=("$line")
done < "$CONF_FILE"

# ============================================================================
#  BACKGROUND — load from cache or generate
# ============================================================================

load_background() {
  local bg_cached="${BG_DIR}/${BG_FILE}"
  if [ -f "$bg_cached" ]; then
    cp "$bg_cached" "${TMP_DIR}/bg.png"
    return
  fi
  echo "  Generating background → $bg_cached"
  magick -size ${W}x${H} xc:'#FAFAFA' \
    \( -size ${W}x${H} xc:none \
       -fill 'rgba(255,140,0,0.25)' -draw "circle 150,400 150,900" \
       -fill 'rgba(0,140,255,0.15)' -draw "circle 1100,600 1100,1000" \
       -fill 'rgba(255,80,120,0.12)' -draw "circle 400,2200 400,2600" \
       -blur 0x150 \) \
    -compose over -composite "${TMP_DIR}/bg.png"
  cp "${TMP_DIR}/bg.png" "$bg_cached"
}

# ============================================================================
#  GENERATION FUNCTION
# ============================================================================

generate_screenshot() {
  local idx=$1
  local num=$((idx + 1))

  IFS='|' read -r iphone_file headline subtitle <<< "${SCREENSHOTS[$idx]}"

  local mockup_path="${IPHONE_DIR}/${iphone_file}.png"
  local bg_name="${BG_FILE%.png}"
  local output_path="${OUTPUT_DIR}/${bg_name}_${iphone_file}.png"

  # ── Measure headline height to position subtitle dynamically ────────────
  local hl_height
  hl_height=$(magick -size ${W}x -font "$FONT_HEADLINE" -pointsize $HEADLINE_SIZE \
    -gravity North caption:"$(echo -e "$headline")" -format "%h" info:)
  local line_count=$(echo -e "$headline" | wc -l | tr -d ' ')
  local top_pad=$TOP_PAD
  if [ "$line_count" -eq 1 ]; then
    top_pad=160
  fi
  local subtitle_y=$(( top_pad + hl_height + SUBTITLE_GAP ))

  echo ""
  echo "━━━ Screenshot #${num} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Headline:   $(echo -e "$headline" | tr '\n' ' ') (${hl_height}px)"
  echo "  Subtitle:   $subtitle (Y=${subtitle_y})"
  echo "  iPhone:     ${iphone_file}.png"
  echo "  Output:     $(basename "$output_path")"

  # ── Check if iPhone screenshot exists ────────────────────────────────────
  if [ ! -f "$mockup_path" ]; then
    echo "  ⚠️  SKIPPED — not found: $mockup_path"

    magick "${TMP_DIR}/bg.png" \
      -gravity North -font "$FONT_HEADLINE" -pointsize $HEADLINE_SIZE \
      -fill "$HEADLINE_COLOR" -annotate +0+${top_pad} "$headline" \
      -font "$FONT_SUBTITLE" -pointsize $SUBTITLE_SIZE \
      -fill "$SUBTITLE_COLOR" -annotate +0+${subtitle_y} "$subtitle" \
      -gravity Center \
      -font "/tmp/poppins-font/Poppins-Medium.ttf" -pointsize 36 \
      -fill 'rgba(0,0,0,0.2)' -annotate +0+200 "[ ${iphone_file}.png ]" \
      -background white -alpha remove \
      "$output_path"

    echo "  ✅ Placeholder → $output_path"
    return
  fi

  # ── Phone with shadow ───────────────────────────────────────────────────
  local phone_target_w=$(( W * PHONE_SCALE / 100 ))

  magick "$mockup_path" -resize ${phone_target_w}x \
    \( +clone -background 'rgba(0,0,0,0.45)' -shadow 80x30+0+20 \) \
    +swap -background none -layers merge +repage \
    "${TMP_DIR}/phone.png"

  local phone_w=$(magick identify -format "%w" "${TMP_DIR}/phone.png")
  local phone_x=$(( (W - phone_w) / 2 ))

  # ── Composite ───────────────────────────────────────────────────────────
  magick "${TMP_DIR}/bg.png" \
    "${TMP_DIR}/phone.png" -geometry +${phone_x}+${PHONE_Y} -composite \
    -gravity North -font "$FONT_HEADLINE" -pointsize $HEADLINE_SIZE \
    -fill "$HEADLINE_COLOR" -annotate +0+${top_pad} "$headline" \
    -gravity North -font "$FONT_SUBTITLE" -pointsize $SUBTITLE_SIZE \
    -fill "$SUBTITLE_COLOR" -annotate +0+${subtitle_y} "$subtitle" \
    -background white -alpha remove \
    "$output_path"

  echo "  ✅ Generated → $output_path"
}

# ============================================================================
#  MAIN
# ============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        rCoon App Store Screenshot Generator                 ║"
echo "║        Target: 1290 × 2796 (iPhone 15/16 Pro Max)          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Config:      $CONF_FILE (${#SCREENSHOTS[@]} entries)"
echo "📁 iPhones:     $IPHONE_DIR"
echo "📁 Background:  $BG_FILE"
echo "📁 Output:      $OUTPUT_DIR"

# Load background once
load_background

if [ $# -eq 0 ]; then
  echo ""
  echo "🔄 Generating all ${#SCREENSHOTS[@]} screenshots..."
  for i in "${!SCREENSHOTS[@]}"; do
    generate_screenshot "$i"
  done
else
  echo ""
  echo "🔄 Generating screenshots: $@"
  for num in "$@"; do
    idx=$((num - 1))
    if [ $idx -ge 0 ] && [ $idx -lt ${#SCREENSHOTS[@]} ]; then
      generate_screenshot "$idx"
    else
      echo "⚠️  Invalid screenshot number: $num (valid: 1-${#SCREENSHOTS[@]})"
    fi
  done
fi

echo ""
echo "━━━ Summary ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null || echo "No screenshots generated."
echo ""
echo "💡 iPhone status:"
for i in "${!SCREENSHOTS[@]}"; do
  IFS='|' read -r iphone_file _ _ <<< "${SCREENSHOTS[$i]}"
  status="❌"
  [ -f "${IPHONE_DIR}/${iphone_file}.png" ] && status="✅"
  echo "   ${status} $(printf '%2d' $((i+1))). ${iphone_file}.png"
done
echo ""
