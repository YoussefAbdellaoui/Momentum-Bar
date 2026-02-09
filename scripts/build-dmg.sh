#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <version> <path-to-MomentumBar.app>"
  echo "Example: $0 1.0.3 /Users/you/Library/Developer/Xcode/DerivedData/.../Release/MomentumBar.app"
  exit 1
fi

VERSION="$1"
APP_PATH="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BG_PATH="$SCRIPT_DIR/dmg-background.png"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-"$SCRIPT_DIR/../MomentumBar/MomentumBar.entitlements"}"

VOLUME_NAME="MomentumBar Installer ${VERSION}"
DMG_RW="/tmp/MomentumBar-${VERSION}-rw.dmg"
DMG_FINAL_BASE="/tmp/MomentumBar-${VERSION}"
DMG_FINAL="/tmp/MomentumBar-${VERSION}.dmg"
MOUNT_DIR="/tmp/MomentumBarMount"
STAGING_DIR="/tmp/MomentumBarDmgRoot"

rm -rf "$STAGING_DIR" "$MOUNT_DIR" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$STAGING_DIR"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  # Re-sign Sparkle nested binaries with hardened runtime + timestamp
  SPARKLE_ROOT="$APP_PATH/Contents/Frameworks/Sparkle.framework/Versions/B"
  if [[ -d "$SPARKLE_ROOT" ]]; then
    for BIN in \
      "$SPARKLE_ROOT/Autoupdate" \
      "$SPARKLE_ROOT/Updater.app" \
      "$SPARKLE_ROOT/XPCServices/Downloader.xpc" \
      "$SPARKLE_ROOT/XPCServices/Installer.xpc" \
      "$SPARKLE_ROOT/Sparkle"
    do
      if [[ -e "$BIN" ]]; then
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$BIN"
      fi
    done
  fi

  # Re-sign the app with entitlements (required for calendar access)
  if [[ -f "$ENTITLEMENTS_PATH" ]]; then
    codesign --force --options runtime --timestamp \
      --entitlements "$ENTITLEMENTS_PATH" \
      --sign "$SIGN_IDENTITY" \
      "$APP_PATH"
  else
    echo "Entitlements not found at $ENTITLEMENTS_PATH"
    exit 1
  fi
fi

ditto --noqtn --norsrc --noextattr "$APP_PATH" "$STAGING_DIR/MomentumBar.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$DMG_RW"

ATTACH_OUTPUT="$(hdiutil attach "$DMG_RW" -nobrowse)"
MOUNT_DIR="$(echo "$ATTACH_OUTPUT" | awk 'NF>=3 && $3 ~ /^\/Volumes\// {for (i=3; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : ""); print ""}' | tail -n 1)"
if [[ -z "$MOUNT_DIR" || ! -d "$MOUNT_DIR" ]]; then
  echo "Failed to determine mount point for $DMG_RW"
  exit 1
fi

mkdir -p "$MOUNT_DIR/.background"
cp "$BG_PATH" "$MOUNT_DIR/.background/background.png"

osascript <<EOF || true
delay 1
tell application "Finder"
  tell disk "${VOLUME_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 200, 800, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set background picture of viewOptions to file ".background:background.png"
    set position of item "MomentumBar.app" of container window to {180, 220}
    set position of item "Applications" of container window to {520, 220}
    close
  end tell
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR"

hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL_BASE"

if [[ -f "${DMG_FINAL_BASE}.dmg" ]]; then
  DMG_FINAL="${DMG_FINAL_BASE}.dmg"
elif [[ -f "$DMG_FINAL_BASE" ]]; then
  DMG_FINAL="$DMG_FINAL_BASE"
fi

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_FINAL"
fi

if [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_FINAL" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait
  xcrun stapler staple "$DMG_FINAL"
fi

echo "DMG ready at: $DMG_FINAL"
