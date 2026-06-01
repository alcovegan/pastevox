#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="VoiceDock"
SRC_APP="$ROOT_DIR/dist/$APP_NAME.app"
DEST_APP="/Applications/$APP_NAME.app"

if [ ! -d "$SRC_APP" ]; then
  "$ROOT_DIR/scripts/build-app.sh"
fi

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill "$APP_NAME" || true
  sleep 0.5
fi

rm -rf "$DEST_APP"
cp -R "$SRC_APP" "$DEST_APP"
codesign --force --deep --sign - "$DEST_APP" >/dev/null

echo "Installed: $DEST_APP"
echo "Tip: if auto-paste stops working, re-add /Applications/$APP_NAME.app in System Settings → Privacy & Security → Accessibility."
