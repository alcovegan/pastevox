#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="VoiceDock"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/debug"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SRC="$ROOT_DIR/Sources/VoiceDock/Info.plist"

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"

cd "$ROOT_DIR"
swift build

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$INFO_PLIST_SRC" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sources/VoiceDock/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
cp "$ROOT_DIR/Sources/VoiceDock/Resources/MenuBarIcon.png" "$RESOURCES_DIR/MenuBarIcon.png"

# Copy SwiftPM resource bundle if present.
if [ -d "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" ]; then
  cp -R "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" "$RESOURCES_DIR/"
fi

# Local ad-hoc signing for easier launch outside Terminal.
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built: $APP_DIR"
