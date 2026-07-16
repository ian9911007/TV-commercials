#!/bin/bash
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORK="$PROJECT_DIR/.work"
ASSETS="$PROJECT_DIR/assets"
SOURCE="/Users/ianchen/Desktop/Timeline 2.mov"
NAME="city-flight"
FPS=30

mkdir -p "$WORK" "$ASSETS/vid"

if [ ! -s "$WORK/source-$NAME.mov" ]; then
  cp "$SOURCE" "$WORK/source-$NAME.mov"
fi

if [ ! -s "$WORK/clip-$NAME.mp4" ]; then
  ffmpeg -v error -y -i "$WORK/source-$NAME.mov" \
    -r "$FPS" -fps_mode cfr \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
    -an "$WORK/clip-$NAME.mp4"
fi

if [ ! -s "$ASSETS/vid/$NAME.mp4" ]; then
  ffmpeg -v error -y -i "$WORK/clip-$NAME.mp4" -an \
    -vf "unsharp=5:5:0.8:5:5:0.0" \
    -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
    -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart \
    "$ASSETS/vid/$NAME.mp4"
fi

if [ ! -s "$ASSETS/vid/$NAME-m.mp4" ]; then
  ffmpeg -v error -y -i "$WORK/clip-$NAME.mp4" -an \
    -vf "scale=-2:720,unsharp=5:5:0.6:5:5:0.0" \
    -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p \
    -g 4 -keyint_min 4 -sc_threshold 0 -movflags +faststart \
    "$ASSETS/vid/$NAME-m.mp4"
fi

if [ ! -s "$WORK/poster-$NAME.png" ]; then
  ffmpeg -v error -y -ss 0 -i "$ASSETS/vid/$NAME.mp4" \
    -frames:v 1 -q:v 2 "$WORK/poster-$NAME.png"
fi

if [ ! -s "$WORK/poster-$NAME-m.png" ]; then
  ffmpeg -v error -y -ss 0 -i "$ASSETS/vid/$NAME-m.mp4" \
    -frames:v 1 -q:v 2 "$WORK/poster-$NAME-m.png"
fi

if [ ! -s "$ASSETS/$NAME-poster.webp" ]; then
  cwebp -quiet -q 84 "$WORK/poster-$NAME.png" \
    -o "$ASSETS/$NAME-poster.webp"
fi

if [ ! -s "$ASSETS/$NAME-poster-m.webp" ]; then
  cwebp -quiet -q 84 "$WORK/poster-$NAME-m.png" \
    -o "$ASSETS/$NAME-poster-m.webp"
fi

if [ ! -s "$ASSETS/$NAME-still.webp" ]; then
  cwebp -quiet -q 90 "$WORK/poster-$NAME.png" \
    -o "$ASSETS/$NAME-still.webp"
fi

echo "Asset build complete: $PROJECT_DIR"
