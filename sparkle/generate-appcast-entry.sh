#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./generate-appcast-entry.sh /path/to/MomentumBar.zip 1.2.3 123 https://momentumbar.app/downloads/MomentumBar-1.2.3.zip

ZIP_PATH="${1:-}"
SHORT_VERSION="${2:-}"
BUILD_VERSION="${3:-}"
DOWNLOAD_URL="${4:-}"
SPARKLE_BIN="${SPARKLE_BIN:-}" # optional env var pointing to Sparkle bin directory

if [[ -z "$ZIP_PATH" || -z "$SHORT_VERSION" || -z "$BUILD_VERSION" || -z "$DOWNLOAD_URL" ]]; then
  echo "Usage: $0 /path/to/MomentumBar.zip 1.2.3 123 https://.../MomentumBar-1.2.3.zip"
  exit 1
fi

if [[ -z "$SPARKLE_BIN" ]]; then
  echo "Set SPARKLE_BIN to the directory containing Sparkle tools (generate_keys, sign_update)."
  exit 1
fi

SIGNATURE=$("$SPARKLE_BIN/sign_update" "$ZIP_PATH" | awk -F'"' '/sparkle:edSignature/ {print $2}')
FILE_SIZE=$(stat -f%z "$ZIP_PATH")
PUB_DATE=$(date -R)

cat <<ENTRY
<item>
  <title>Version $SHORT_VERSION</title>
  <sparkle:releaseNotesLink>https://momentumbar.app/release-notes/$SHORT_VERSION</sparkle:releaseNotesLink>
  <pubDate>$PUB_DATE</pubDate>
  <enclosure
    url="$DOWNLOAD_URL"
    sparkle:version="$BUILD_VERSION"
    sparkle:shortVersionString="$SHORT_VERSION"
    length="$FILE_SIZE"
    type="application/octet-stream"
    sparkle:edSignature="$SIGNATURE"
  />
</item>
ENTRY
