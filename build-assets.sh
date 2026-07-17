#!/bin/bash
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORK="$PROJECT_DIR/.work"
ASSETS="$PROJECT_DIR/assets"
SOURCE="/Users/ianchen/Desktop/Veo1.mov"
NAME="city-flight"
FPS=30
SOURCE_COPY="$WORK/source-$NAME.mov"
BUILD_STATE="$WORK/build-signature.txt"

mkdir -p "$WORK" "$ASSETS/vid"

if [ ! -s "$SOURCE" ]; then
  echo "Missing source video: $SOURCE" >&2
  exit 1
fi

SOURCE_CKSUM=$(cksum "$SOURCE" | awk '{ print $1 "-" $2 }')
BUILD_SIGNATURE="$SOURCE_CKSUM|fps=$FPS|video-only|master=crf20-g8-no-sharpen|mobile=crf23-g4-no-sharpen"

if [ ! -s "$BUILD_STATE" ] || [ "$(sed -n '1p' "$BUILD_STATE")" != "$BUILD_SIGNATURE" ]; then
  cp "$SOURCE" "$SOURCE_COPY"
  rm -f \
    "$WORK/clip-$NAME.mp4" \
    "$WORK/poster-$NAME.png" \
    "$WORK/poster-$NAME-m.png" \
    "$ASSETS/vid/$NAME.mp4" \
    "$ASSETS/vid/$NAME-m.mp4" \
    "$ASSETS/$NAME-poster.webp" \
    "$ASSETS/$NAME-poster-m.webp" \
    "$ASSETS/$NAME-still.webp"
  printf '%s\n' "$BUILD_SIGNATURE" > "$BUILD_STATE"
fi

if [ ! -s "$WORK/clip-$NAME.mp4" ]; then
  ffmpeg -v error -y -i "$SOURCE_COPY" -map 0:v:0 -map_metadata -1 -dn -sn \
    -r "$FPS" -fps_mode cfr \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
    -an -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
    -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart \
    "$WORK/clip-$NAME.mp4"
fi

if [ ! -s "$ASSETS/vid/$NAME.mp4" ]; then
  cp "$WORK/clip-$NAME.mp4" "$ASSETS/vid/$NAME.mp4"
fi

if [ ! -s "$ASSETS/vid/$NAME-m.mp4" ]; then
  ffmpeg -v error -y -i "$WORK/clip-$NAME.mp4" -map 0:v:0 -map_metadata -1 -dn -sn -an \
    -vf "scale=-2:720" \
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
