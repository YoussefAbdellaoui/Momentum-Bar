#!/usr/bin/env bash
set -euo pipefail

ZIP_PATH="${1:-}"
SHORT_VERSION="${2:-}"
BUILD_VERSION="${3:-}"
DOWNLOAD_URL="${4:-}"
APPCAST_PATH="${5:-website/public/appcast.xml}"
SPARKLE_BIN="${SPARKLE_BIN:-}"
SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"

if [[ -z "$ZIP_PATH" || -z "$SHORT_VERSION" || -z "$BUILD_VERSION" || -z "$DOWNLOAD_URL" ]]; then
  echo "Usage: $0 /path/to/MomentumBar.zip 1.2.3 123 https://.../MomentumBar-1.2.3.zip [appcast_path]"
  exit 1
fi

if [[ -z "$SPARKLE_BIN" ]]; then
  echo "Set SPARKLE_BIN to the directory containing Sparkle tools (sign_update, generate_appcast)."
  exit 1
fi

if [[ -z "$SPARKLE_PRIVATE_KEY" ]]; then
  echo "Set SPARKLE_PRIVATE_KEY to the base64 EdDSA private key (from generate_keys -x)."
  exit 1
fi

SIGNATURE=$(echo "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_BIN/sign_update" --ed-key-file - -p "$ZIP_PATH")
FILE_SIZE=$(stat -f%z "$ZIP_PATH")
PUB_DATE=$(date -R)

ITEM=$(cat <<ENTRY
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
)

if [[ ! -f "$APPCAST_PATH" ]]; then
  echo "Appcast not found at $APPCAST_PATH"
  exit 1
fi

export ITEM
python3 - "$APPCAST_PATH" <<'PY'
import os
import sys
from pathlib import Path

appcast_path = Path(sys.argv[1])
item = os.environ.get("ITEM", "")

text = appcast_path.read_text()
needle = "</channel>"
if needle not in text:
    raise SystemExit("Appcast missing </channel> tag")

updated = text.replace(needle, f"{item}\n  {needle}", 1)
appcast_path.write_text(updated)
PY

echo "Updated appcast: $APPCAST_PATH"
