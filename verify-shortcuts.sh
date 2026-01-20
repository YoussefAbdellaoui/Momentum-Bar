#!/bin/bash

# Script to verify Focus Mode shortcuts are ready for deployment
# Run this after creating and pushing shortcuts to GitHub

set -e

echo "🔍 MomentumBar Focus Mode Shortcuts Verification"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SHORTCUTS_DIR="Shortcuts"
REPO_URL="https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts"

# Array of shortcuts
SHORTCUTS=(
    "MomentumBar-Do-Not-Disturb"
    "MomentumBar-Work"
    "MomentumBar-Personal"
    "MomentumBar-Sleep"
    "MomentumBar-Focus-Off"
)

# Track results
ALL_PASSED=true

echo "📁 Step 1: Checking local files..."
echo ""

for shortcut in "${SHORTCUTS[@]}"; do
    FILE="$SHORTCUTS_DIR/${shortcut}.shortcut"

    if [ -f "$FILE" ]; then
        SIZE=$(ls -lh "$FILE" | awk '{print $5}')
        echo -e "${GREEN}✅${NC} Found: ${shortcut}.shortcut (${SIZE})"
    else
        echo -e "${RED}❌${NC} Missing: ${shortcut}.shortcut"
        ALL_PASSED=false
    fi
done

echo ""
echo "🌐 Step 2: Checking GitHub URLs..."
echo ""

for shortcut in "${SHORTCUTS[@]}"; do
    URL="${REPO_URL}/${shortcut}.shortcut"

    # Check if URL returns 200
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅${NC} Accessible: ${shortcut}.shortcut"
    else
        echo -e "${RED}❌${NC} Not found (HTTP ${HTTP_CODE}): ${shortcut}.shortcut"
        echo "    URL: $URL"
        ALL_PASSED=false
    fi
done

echo ""
echo "🔧 Step 3: Checking Shortcuts app..."
echo ""

if command -v shortcuts &> /dev/null; then
    echo "Found Shortcuts CLI ✅"
    echo ""
    echo "Installed MomentumBar shortcuts:"

    INSTALLED=$(shortcuts list 2>/dev/null | grep "MomentumBar" || echo "")

    if [ -z "$INSTALLED" ]; then
        echo -e "${YELLOW}⚠️${NC}  No MomentumBar shortcuts found in Shortcuts app"
        echo "    (This is OK - users will install them via the app)"
    else
        echo "$INSTALLED" | while read -r line; do
            echo -e "${GREEN}✅${NC} $line"
        done
    fi
else
    echo -e "${YELLOW}⚠️${NC}  Shortcuts CLI not available (macOS 12+ required)"
fi

echo ""
echo "=================================================="
echo ""

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}🎉 All checks passed!${NC}"
    echo ""
    echo "✅ All shortcut files exist locally"
    echo "✅ All shortcuts are accessible on GitHub"
    echo ""
    echo "Your Focus Mode shortcuts are ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Continue with DEPLOYMENT_CHECKLIST.md"
    echo "2. Create app icons"
    echo "3. Sign up for Apple Developer account"
    echo ""
else
    echo -e "${RED}❌ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
    echo ""
    echo "Common fixes:"
    echo "- Missing local files: Create shortcuts in Shortcuts app and export"
    echo "- GitHub 404 errors: Push files to GitHub (git push origin main)"
    echo "- Wait 1-2 minutes after pushing for GitHub to make files available"
    echo ""
    exit 1
fi
