#!/usr/bin/env bash
set -euo pipefail

variant="${1:-B}"
appicon_dir="ios/GenesisWay/Assets.xcassets/AppIcon.appiconset"
source_png="$appicon_dir/Icon-AppStore-1024-${variant}.png"
target_png="$appicon_dir/Icon-AppStore-1024.png"

if [[ ! -f "$source_png" ]]; then
  echo "Variant $variant not found at $source_png"
  echo "Available variants:"
  ls -1 "$appicon_dir"/Icon-AppStore-1024-*.png 2>/dev/null | sed 's|.*/Icon-AppStore-1024-||; s|\.png$||' || true
  exit 1
fi

cp "$source_png" "$target_png"

sips -z 40 40 "$target_png" --out "$appicon_dir/Icon-20@2x.png" >/dev/null
sips -z 60 60 "$target_png" --out "$appicon_dir/Icon-20@3x.png" >/dev/null
sips -z 58 58 "$target_png" --out "$appicon_dir/Icon-29@2x.png" >/dev/null
sips -z 87 87 "$target_png" --out "$appicon_dir/Icon-29@3x.png" >/dev/null
sips -z 80 80 "$target_png" --out "$appicon_dir/Icon-40@2x.png" >/dev/null
sips -z 120 120 "$target_png" --out "$appicon_dir/Icon-40@3x.png" >/dev/null
sips -z 120 120 "$target_png" --out "$appicon_dir/Icon-60@2x.png" >/dev/null
sips -z 180 180 "$target_png" --out "$appicon_dir/Icon-60@3x.png" >/dev/null
sips -z 20 20 "$target_png" --out "$appicon_dir/Icon-iPad-20.png" >/dev/null
sips -z 40 40 "$target_png" --out "$appicon_dir/Icon-iPad-20@2x.png" >/dev/null
sips -z 29 29 "$target_png" --out "$appicon_dir/Icon-iPad-29.png" >/dev/null
sips -z 58 58 "$target_png" --out "$appicon_dir/Icon-iPad-29@2x.png" >/dev/null
sips -z 40 40 "$target_png" --out "$appicon_dir/Icon-iPad-40.png" >/dev/null
sips -z 80 80 "$target_png" --out "$appicon_dir/Icon-iPad-40@2x.png" >/dev/null
sips -z 76 76 "$target_png" --out "$appicon_dir/Icon-iPad-76.png" >/dev/null
sips -z 152 152 "$target_png" --out "$appicon_dir/Icon-iPad-76@2x.png" >/dev/null
sips -z 167 167 "$target_png" --out "$appicon_dir/Icon-iPad-Pro-83.5@2x.png" >/dev/null

echo "Set active app icon to variant $variant"
