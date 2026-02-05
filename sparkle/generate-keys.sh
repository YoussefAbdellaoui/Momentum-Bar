#!/usr/bin/env bash
set -euo pipefail

SPARKLE_BIN="${SPARKLE_BIN:-}"
ACCOUNT="${1:-ed25519}"

if [[ -z "$SPARKLE_BIN" ]]; then
  echo "Set SPARKLE_BIN to the directory containing Sparkle tools (generate_keys)."
  exit 1
fi

"$SPARKLE_BIN/generate_keys" --account "$ACCOUNT"
