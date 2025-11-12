#!/bin/bash
# for size in 16 32 64 128 256 512 1024; do
#     #inkscape -z -o $size.png -w $size -h $size icon.svg >/dev/null 2>/dev/null
#     convert icon.png -resize ${size}x${size} app_icon_$size.png
# done
# # from ImageMagick
# convert 16.png 32.png 48.png 128.png 256.png -colors 256 icon.ico
# #/bin/rm 16.png 32.png 48.png 128.png 256.png

#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

SRC="flutter/assets/small_logo.png"
DEST="windows/runner/resources/app_icon.ico"

# 檢查 ImageMagick
if ! command -v magick >/dev/null 2>&1; then
  echo "❌ 找不到 'magick' 指令，請先安裝並加入 PATH。"
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

# 直接產生含 256,128,64,48,32,16 的多尺寸 ICO
magick "$SRC" -define icon:auto-resize=256,128,64,48,32,16 "$DEST"

echo "✅ 已輸出：$DEST"
echo "➡ 接著：flutter clean && flutter pub get && flutter build windows --release"


