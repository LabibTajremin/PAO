#!/usr/bin/env bash
# Builds the PAO Partner app icons: the PAO icons with a small tool badge in the corner, so
# the merchant app never looks like the customer app on a phone (06-update-2026-11.md §4).
# Needs rsvg-convert and ImageMagick. Run from anywhere; writes next to this script.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
src="$here/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rsvg-convert -w 1024 -h 1024 "$here/badge.svg" -o "$tmp/badge.png"
rsvg-convert -w 1024 -h 1024 "$here/badge-mono.svg" -o "$tmp/badge-mono.png"
# Tinted iOS icons are greyscale; Android's monochrome layer is one colour on transparent.
convert "$tmp/badge.png" -colorspace Gray "$tmp/badge-grey.png"
# The wrench becomes a hole in the white disc: alpha follows the brightness.
convert "$tmp/badge-mono.png" -channel A -fx 'a*intensity' +channel -fill white -colorize 100 "$tmp/badge-white.png"
compose() { convert "$1" "$2" -composite "$here/$3"; }
compose "$src/ios/icon-light-1024.png" "$tmp/badge.png" icon-light-1024.png
compose "$src/ios/icon-dark-1024.png" "$tmp/badge.png" icon-dark-1024.png
compose "$src/ios/icon-tinted-1024.png" "$tmp/badge-grey.png" icon-tinted-1024.png
compose "$src/android/ic_launcher_foreground.png" "$tmp/badge.png" ic_launcher_foreground.png
compose "$src/android/ic_launcher_monochrome.png" "$tmp/badge-white.png" ic_launcher_monochrome.png
compose "$src/android/icon-legacy-1024.png" "$tmp/badge.png" icon-legacy-1024.png
