#!/bin/bash

# Script to create MomentumBar Focus Mode shortcuts
# Run this once to set up the shortcuts for distribution

set -e

echo "🚀 Creating MomentumBar Focus Mode Shortcuts"
echo "=============================================="
echo ""

# Check if Shortcuts CLI is available
if ! command -v shortcuts &> /dev/null; then
    echo "❌ Error: 'shortcuts' command not found"
    echo "   The Shortcuts CLI is only available on macOS 12 (Monterey) or later"
    exit 1
fi

echo "✅ Shortcuts CLI found"
echo ""

# Function to create a shortcut programmatically
create_focus_shortcut() {
    local shortcut_name="$1"
    local focus_mode="$2"
    local output_file="$3"

    echo "📝 Creating: $shortcut_name"

    # Create temporary shortcut definition
    # Note: This requires manual creation in Shortcuts app first
    # This script helps verify they exist

    if shortcuts list | grep -q "^$shortcut_name$"; then
        echo "   ✅ Found: $shortcut_name"

        # Try to export (requires manual creation first)
        echo "   📤 Please manually export this shortcut:"
        echo "      1. Open Shortcuts app"
        echo "      2. Right-click '$shortcut_name'"
        echo "      3. Click 'Export...'"
        echo "      4. Save as: $output_file"
        echo ""
    else
        echo "   ⚠️  Not found: $shortcut_name"
        echo "      Please create this shortcut manually first"
        echo ""
    fi
}

echo "Checking for shortcuts..."
echo ""

# Check and guide creation of each shortcut
create_focus_shortcut \
    "MomentumBar Do Not Disturb" \
    "Do Not Disturb" \
    "MomentumBar-Do-Not-Disturb.shortcut"

create_focus_shortcut \
    "MomentumBar Work" \
    "Work" \
    "MomentumBar-Work.shortcut"

create_focus_shortcut \
    "MomentumBar Personal" \
    "Personal" \
    "MomentumBar-Personal.shortcut"

create_focus_shortcut \
    "MomentumBar Sleep" \
    "Sleep" \
    "MomentumBar-Sleep.shortcut"

create_focus_shortcut \
    "MomentumBar Focus Off" \
    "Off" \
    "MomentumBar-Focus-Off.shortcut"

echo "=============================================="
echo ""
echo "📖 Next Steps:"
echo ""
echo "If shortcuts don't exist, create them manually:"
echo ""
echo "1. Open Shortcuts app (⌘+Space → 'Shortcuts')"
echo ""
echo "2. Create shortcuts for each Focus mode:"
echo ""
echo "   A. MomentumBar Do Not Disturb:"
echo "      - Click '+' → Name: 'MomentumBar Do Not Disturb'"
echo "      - Add action: 'Set Focus' → Focus: 'Do Not Disturb' → Duration: 'Until Turned Off'"
echo ""
echo "   B. MomentumBar Work:"
echo "      - Click '+' → Name: 'MomentumBar Work'"
echo "      - Add action: 'Set Focus' → Focus: 'Work' → Duration: 'Until Turned Off'"
echo ""
echo "   C. MomentumBar Personal:"
echo "      - Click '+' → Name: 'MomentumBar Personal'"
echo "      - Add action: 'Set Focus' → Focus: 'Personal' → Duration: 'Until Turned Off'"
echo ""
echo "   D. MomentumBar Sleep:"
echo "      - Click '+' → Name: 'MomentumBar Sleep'"
echo "      - Add action: 'Set Focus' → Focus: 'Sleep' → Duration: 'Until Turned Off'"
echo ""
echo "   E. MomentumBar Focus Off:"
echo "      - Click '+' → Name: 'MomentumBar Focus Off'"
echo "      - Add action: 'Set Focus' → Turn Focus: 'Off'"
echo ""
echo "3. Export all shortcuts:"
echo "   - Right-click each → Export"
echo "   - Save to: $(pwd)"
echo "   - Files: MomentumBar-Do-Not-Disturb.shortcut, MomentumBar-Work.shortcut,"
echo "            MomentumBar-Personal.shortcut, MomentumBar-Sleep.shortcut,"
echo "            MomentumBar-Focus-Off.shortcut"
echo ""
echo "4. Commit and push to GitHub:"
echo "   git add Shortcuts/*.shortcut"
echo "   git commit -m 'Add pre-built Focus Mode shortcuts (DND, Work, Personal, Sleep)'"
echo "   git push origin main"
echo ""
echo "Done! 🎉"
