#!/usr/bin/env bash
# preview.sh — preview sheets of the generated app icons and splash screens for
# docs/guides/brand.md. Run after app-icons.sh and splash.sh. Needs ImageMagick.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="$root/docs/guides/images/brand"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"

# tile <icon> <background> <label> <file> — an icon on a home-screen colour.
tile() {
  convert -size 220x250 "xc:$2" \( "$1" -resize 144x144 \) -gravity north -geometry +0+30 -composite \
    -fill "$( [[ "$2" == '#F5F2EB' || "$2" == '#E8E1F5' ]] && echo '#0B0B0C' || echo '#F5F2EB')" \
    -font DejaVu-Sans -pointsize 15 -gravity south -annotate +0+22 "$3" "$4"
}

for app in customer partner; do
  res="$root/Frontend/apps/$app/android/app/src/main/res"
  ios="$root/Frontend/apps/$app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
  # Android rounds the adaptive icon and tints the monochrome layer with the wallpaper colour.
  convert -size 192x192 xc:'#D9CCF2' \( "$res/mipmap-xxxhdpi/ic_launcher_monochrome.png" \
    -resize 192x192 -fill '#4A3A75' -colorize 100 \) -composite "$tmp/themed.png"
  for f in "$res/mipmap-xxxhdpi/ic_launcher.png" "$tmp/themed.png"; do
    convert "$f" \( +clone -alpha extract -fill black -colorize 100 -fill white \
      -draw 'circle 96,96 96,0' \) -alpha off -compose copy_opacity -composite "$tmp/$(basename "$f" .png)-round.png"
  done
  for f in "$ios/Icon-App-1024x1024@1x.png" "$ios/Icon-App-Dark-1024x1024@1x.png" "$ios/Icon-App-Tinted-1024x1024@1x.png"; do
    convert "$f" -resize 192x192 -background black -flatten \( +clone -alpha extract -fill black -colorize 100 -fill white \
      -draw 'roundrectangle 0,0 191,191 43,43' \) -alpha off -compose copy_opacity -composite \
      "$tmp/$(basename "$f" .png)-round.png"
  done
  tile "$tmp/ic_launcher-round.png" '#F5F2EB' 'Android light' "$tmp/1.png"
  tile "$tmp/ic_launcher-round.png" '#14161A' 'Android dark' "$tmp/2.png"
  tile "$tmp/themed-round.png" '#E8E1F5' 'Android themed' "$tmp/3.png"
  tile "$tmp/Icon-App-1024x1024@1x-round.png" '#F5F2EB' 'iOS light' "$tmp/4.png"
  tile "$tmp/Icon-App-Dark-1024x1024@1x-round.png" '#14161A' 'iOS dark' "$tmp/5.png"
  tile "$tmp/Icon-App-Tinted-1024x1024@1x-round.png" '#14161A' 'iOS tinted' "$tmp/6.png"
  convert "$tmp"/[1-6].png +append "$out/icons-$app.png"
  for mode in light night; do
    dir="drawable-xxxhdpi" bg='#F5F2EB'
    [[ "$mode" == night ]] && dir="drawable-night-xxxhdpi" bg='#0B0B0C'
    convert -size 270x480 "xc:$bg" \( "$res/$dir/splash_tile.png" -resize 120x120 \) \
      -gravity center -composite "$tmp/splash-$mode.png"
  done
  convert "$tmp/splash-light.png" "$tmp/splash-night.png" -bordercolor '#9AA0A6' -border 1 +append "$out/splash-$app.png"
done
echo "previews in docs/guides/images/brand"
