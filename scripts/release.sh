#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MomentumBar"
SCHEME="MomentumBar"

SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Youssef Abdellaoui (3CAJN6L683)}"
APPLE_ID="${APPLE_ID:-kenicastrocantabria@gmail.com}"
TEAM_ID="${TEAM_ID:-3CAJN6L683}"
APP_PASSWORD="${APP_PASSWORD:-}"
SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"
SPARKLE_BIN="${SPARKLE_BIN:-/tmp/sparkle/bin}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$ROOT_DIR/MomentumBar/MomentumBar.entitlements}"

VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ "$VERIFY_ONLY" == false ]]; then
  if [[ -z "$APP_PASSWORD" ]]; then
    echo "APP_PASSWORD is required."
    exit 1
  fi
  if [[ -z "$SPARKLE_PRIVATE_KEY" ]]; then
    echo "SPARKLE_PRIVATE_KEY is required."
    exit 1
  fi
fi

APP_PATH="$(ls -d /Users/$USER/Library/Developer/Xcode/DerivedData/${APP_NAME}-*/Build/Products/Release/${APP_NAME}.app 2>/dev/null | head -n 1)"
if [[ ! -d "$APP_PATH" && "$VERIFY_ONLY" == false ]]; then
  echo "Building Release..."
  xcodebuild -scheme "$SCHEME" -configuration Release -destination "platform=macOS" CODE_SIGNING_ALLOWED=NO build
  APP_PATH="$(ls -d /Users/$USER/Library/Developer/Xcode/DerivedData/${APP_NAME}-*/Build/Products/Release/${APP_NAME}.app | head -n 1)"
fi
if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at: $APP_PATH"
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"

echo "Version: $VERSION ($BUILD)"

ZIP_PATH="$ROOT_DIR/dist/${APP_NAME}-${VERSION}.zip"
DMG_PATH="/private/tmp/${APP_NAME}-${VERSION}.dmg"
APPCAST_PATH="$ROOT_DIR/website/public/appcast.xml"
ZIP_URL="https://momentumbar.app/downloads/${APP_NAME}-${VERSION}.zip"

mkdir -p "$ROOT_DIR/dist"

if [[ "$VERIFY_ONLY" == false ]]; then
  echo "Signing app for notarization..."
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

  if [[ -f "$ENTITLEMENTS_PATH" ]]; then
    codesign --force --options runtime --timestamp \
      --entitlements "$ENTITLEMENTS_PATH" \
      --sign "$SIGN_IDENTITY" \
      "$APP_PATH"
  else
    echo "Entitlements not found at $ENTITLEMENTS_PATH"
    exit 1
  fi

  echo "Creating ZIP..."
  ditto -c -k --keepParent --norsrc --noextattr "$APP_PATH" "$ZIP_PATH"

  echo "Notarizing ZIP..."
  xcrun notarytool submit "$ZIP_PATH" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait

  echo "Updating appcast..."
  SPARKLE_BIN="$SPARKLE_BIN" SPARKLE_PRIVATE_KEY="$SPARKLE_PRIVATE_KEY" \
    "$ROOT_DIR/sparkle/update-appcast.sh" "$ZIP_PATH" "$VERSION" "$BUILD" "$ZIP_URL" "$APPCAST_PATH"

  echo "Building DMG..."
  SIGN_IDENTITY="$SIGN_IDENTITY" \
  APPLE_ID="$APPLE_ID" \
  TEAM_ID="$TEAM_ID" \
  APP_PASSWORD="$APP_PASSWORD" \
  ENTITLEMENTS_PATH="$ROOT_DIR/MomentumBar/MomentumBar.entitlements" \
  "$ROOT_DIR/scripts/build-dmg.sh" "$VERSION" "$APP_PATH"
fi

echo "Verifying DMG..."
xcrun stapler validate "$DMG_PATH"
hdiutil attach "$DMG_PATH" -nobrowse >/tmp/momentumbar-mount.log
MOUNT_DIR="$(awk 'NF>=3 && $3 ~ /^\/Volumes\// {for (i=3; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : ""); print ""}' /tmp/momentumbar-mount.log | tail -n 1)"
spctl -a -vv "$MOUNT_DIR/${APP_NAME}.app"
xcrun stapler validate "$MOUNT_DIR/${APP_NAME}.app"
hdiutil detach "$MOUNT_DIR"

echo "Release artifacts:"
echo "- ZIP: $ZIP_PATH"
echo "- DMG: $DMG_PATH"
echo "- Appcast: $APPCAST_PATH"
