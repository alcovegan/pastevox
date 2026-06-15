#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PasteVox"
PACKAGE_BINARY="PasteVox"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/debug"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST_SRC="$ROOT_DIR/Sources/PasteVox/Info.plist"
APP_ICON_SRC="$ROOT_DIR/Sources/PasteVox/Resources/AppIcon.png"
MENU_ICON_SRC="$ROOT_DIR/Sources/PasteVox/Resources/MenuBarIcon.png"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR" "$ICONSET_DIR"

cd "$ROOT_DIR"
swift build --product "$PACKAGE_BINARY"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/$PACKAGE_BINARY" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$INFO_PLIST_SRC" "$CONTENTS_DIR/Info.plist"
cp "$APP_ICON_SRC" "$RESOURCES_DIR/AppIcon.png"
cp "$MENU_ICON_SRC" "$RESOURCES_DIR/MenuBarIcon.png"

# Create Dock/app .icns from the source PNG for local packaging.
mkdir -p "$ICONSET_DIR"
sips -z 16 16     "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$APP_ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Copy SwiftPM resource bundle(s) into the app — contains app icons and the
# localized .lproj catalogs (Bundle.module looks for them under Contents/Resources).
# The bundle is named "<Package>_<Target>" (PasteVox_PasteVox), so glob to stay robust.
shopt -s nullglob
for bundle in "$BUILD_DIR"/*.bundle; do
  cp -R "$bundle" "$RESOURCES_DIR/"
done
shopt -u nullglob

# Local ad-hoc signing for easier launch outside Terminal.
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built: $APP_DIR"
