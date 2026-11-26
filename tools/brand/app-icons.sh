#!/usr/bin/env bash
# Writes the launcher icons of both apps and the admin web icons from design/brand/app-icons.
# The partner app uses design/brand/app-icons/partner (the same mark with a tool badge).
# flutter_launcher_icons would do this, but it cannot share a workspace with melos (cli_util),
# so this script does the same with ImageMagick. Run it after changing the artwork; commit what
# it writes.
#   tools/brand/app-icons.sh
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
icons="$root/design/brand/app-icons"
apps="$root/Frontend/apps"

# Android densities: legacy launcher size and adaptive layer size (108 dp).
densities=(mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432)

android() { # app, source folder
  local res="$apps/$1/android/app/src/main/res" src="$2" d name legacy layer
  for d in "${densities[@]}"; do
    IFS=: read -r name legacy layer <<<"$d"
    mkdir -p "$res/mipmap-$name"
    convert "$src/icon-legacy-1024.png" -resize "${legacy}x${legacy}" "$res/mipmap-$name/ic_launcher.png"
    convert "$src/ic_launcher_foreground.png" -resize "${layer}x${layer}" "$res/mipmap-$name/ic_launcher_foreground.png"
    convert "$src/ic_launcher_monochrome.png" -resize "${layer}x${layer}" "$res/mipmap-$name/ic_launcher_monochrome.png"
  done
  cat >"$res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
XML
  cat >"$res/values/ic_launcher_background.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B0B0C</color>
</resources>
XML
}

ios() { # app, source folder with icon-light/dark/tinted-1024.png
  local set="$apps/$1/ios/Runner/Assets.xcassets/AppIcon.appiconset" src="$2"
  rm -f "$set"/*.png
  # The App Store rejects an icon with an alpha channel.
  convert "$src/icon-light-1024.png" -background '#0B0B0C' -alpha remove -alpha off "$set/Icon-App-1024x1024@1x.png"
  cp "$src/icon-dark-1024.png" "$set/Icon-App-Dark-1024x1024@1x.png"
  convert "$src/icon-tinted-1024.png" -colorspace Gray "$set/Icon-App-Tinted-1024x1024@1x.png"
  cat >"$set/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "Icon-App-1024x1024@1x.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "filename" : "Icon-App-Dark-1024x1024@1x.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ],
      "filename" : "Icon-App-Tinted-1024x1024@1x.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

web() { # the admin panel
  local web="$apps/admin/web" src="$icons/web"
  cp "$src/favicon.svg" "$web/favicon.svg"
  cp "$src/favicon-32.png" "$web/favicon.png"
  cp "$src/icon-192.png" "$web/icons/Icon-192.png"
  cp "$src/icon-512.png" "$web/icons/Icon-512.png"
  convert "$src/icon-maskable-512.png" -resize 192x192 "$web/icons/Icon-maskable-192.png"
  cp "$src/icon-maskable-512.png" "$web/icons/Icon-maskable-512.png"
}

android customer "$icons/android"
android partner "$icons/partner"
# The partner set keeps the Android names; its iOS files sit beside them.
ios customer "$icons/ios"
ios partner "$icons/partner"
web
echo "app icons written"
