#!/bin/bash

echo "🔧 Resetting MomentumBar app state..."

# Kill any running instances
echo "1. Stopping any running instances..."
killall MomentumBar 2>/dev/null || true

# Clear UserDefaults (app's preferences)
echo "2. Clearing UserDefaults..."
defaults delete com.momentumbar 2>/dev/null || echo "   No main app preferences found"
defaults delete group.com.momentumbar.shared 2>/dev/null || echo "   No shared preferences found"

# Clear derived data
echo "3. Clearing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MomentumBar-*

# Clear build folder
echo "4. Clearing build folder..."
rm -rf build/

echo ""
echo "✅ App state reset complete!"
echo ""
echo "Next steps:"
echo "1. Clean build folder in Xcode: Product → Clean Build Folder (⌘⇧K)"
echo "2. Rebuild the app: Product → Build (⌘B)"
echo "3. Run the app: Product → Run (⌘R)"
echo ""
