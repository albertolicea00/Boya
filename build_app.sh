#!/bin/bash
# Builds Boya and wraps the executable into a minimal, launchable .app bundle.
# Signs ad-hoc so Gatekeeper/AMFI allow local execution. Not notarized —
# fine for personal use, would need a Developer ID + notarization to share.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-debug}"
swift build -c "$CONFIG"

BIN_PATH=$(swift build -c "$CONFIG" --show-bin-path)
APP="Boya.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN_PATH/Boya" "$APP/Contents/MacOS/Boya"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP"

echo "Built $APP"
