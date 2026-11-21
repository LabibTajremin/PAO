#!/usr/bin/env bash
# Writes the native splash of both apps: the ink PAO tile on #F6F4EC in light mode and the
# inverse tile on #0E1322 in dark mode, on Android (before and since Android 12) and iOS.
# The first Flutter frame shows the same colour, so the hand-over doesn't flash.
#   tools/brand/splash.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
svg="$root/design/brand/svg"
light_bg='#F6F4EC' dark_bg='#0E1322'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rsvg-convert -w 1024 -h 1024 "$svg/logo-tile-light.svg" -o "$tmp/light.png"
rsvg-convert -w 1024 -h 1024 "$svg/logo-tile-dark.svg" -o "$tmp/dark.png"

# Tile 96 dp before Android 12; on 12+ a 288 dp icon whose middle 192 dp circle is visible,
# so the tile is 120 dp to keep its corners inside the circle.
densities=(mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4)

android() {
  local res="$1/android/app/src/main/res" d name scale tile icon pad mode src
  for d in "${densities[@]}"; do
    IFS=: read -r name scale <<<"$d"
    tile=$(awk "BEGIN{print int(96*$scale)}")
    icon=$(awk "BEGIN{print int(288*$scale)}")
    pad=$(awk "BEGIN{print int(120*$scale)}")
    for mode in "" "-night"; do
      src="$tmp/light.png"; [[ -n "$mode" ]] && src="$tmp/dark.png"
      mkdir -p "$res/drawable$mode-$name"
      convert "$src" -resize "${tile}x${tile}" "$res/drawable$mode-$name/splash_tile.png"
      convert "$src" -resize "${pad}x${pad}" -background none -gravity center \
        -extent "${icon}x${icon}" "$res/drawable$mode-$name/splash_icon.png"
    done
  done
  for dir in drawable drawable-v21; do
    cat >"$res/$dir/launch_background.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<!-- Written by tools/brand/splash.sh. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash_tile" />
    </item>
</layer-list>
XML
  done
  for mode in "" "-night"; do
    local bg=$light_bg; [[ -n "$mode" ]] && bg=$dark_bg
    mkdir -p "$res/values$mode" "$res/values$mode-v31"
    cat >"$res/values$mode/splash_colors.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_background">$bg</color>
</resources>
XML
    local parent="Theme.Light.NoTitleBar"; [[ -n "$mode" ]] && parent="Theme.Black.NoTitleBar"
    cat >"$res/values$mode-v31/styles.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<!-- Written by tools/brand/splash.sh: Android 12+ draws this splash itself. -->
<resources>
    <style name="LaunchTheme" parent="@android:style/$parent">
        <item name="android:windowSplashScreenBackground">@color/splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/$parent">
        <item name="android:windowBackground">@color/splash_background</item>
    </style>
</resources>
XML
  done
}

ios() {
  local assets="$1/ios/Runner/Assets.xcassets" set color
  set="$assets/LaunchImage.imageset"
  rm -f "$set"/*.png
  for s in 1 2 3; do
    convert "$tmp/light.png" -resize "$((120 * s))x$((120 * s))" "$set/LaunchImage@${s}x.png"
    convert "$tmp/dark.png" -resize "$((120 * s))x$((120 * s))" "$set/LaunchImageDark@${s}x.png"
  done
  mv "$set/LaunchImage@1x.png" "$set/LaunchImage.png"
  mv "$set/LaunchImageDark@1x.png" "$set/LaunchImageDark.png"
  cat >"$set/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "LaunchImage.png", "idiom" : "universal", "scale" : "1x" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "LaunchImageDark.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "LaunchImage@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "LaunchImageDark@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "LaunchImage@3x.png", "idiom" : "universal", "scale" : "3x" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "LaunchImageDark@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  color="$assets/LaunchBackground.colorset"
  mkdir -p "$color"
  cat >"$color/Contents.json" <<'JSON'
{
  "colors" : [
    { "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0xF6", "green" : "0xF4", "blue" : "0xEC" } }, "idiom" : "universal" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x0E", "green" : "0x13", "blue" : "0x22" } }, "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

for app in customer partner; do
  android "$root/Frontend/apps/$app"
  ios "$root/Frontend/apps/$app"
done
echo "splash written"
