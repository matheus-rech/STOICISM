#!/bin/bash

# Screenshot Generator for Stoic Companion watchOS App
# Generates screenshots required for App Store Connect submission

echo "================================================"
echo "📸 Screenshot Generator for App Store Connect"
echo "================================================"
echo ""
echo "This script will help you generate required screenshots for your watchOS app."
echo ""
echo "Requirements:"
echo "  - Xcode installed"
echo "  - Watch simulator available"
echo "  - App built and ready to run"
echo ""

# Check if Xcode is installed
if ! command -v xcrun &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    exit 1
fi

echo "✅ Xcode found"
echo ""

# List available watch simulators
echo "📱 Available Watch Simulators:"
echo "================================"
xcrun simctl list devices available | grep -i watch
echo ""

# Ask user which simulator to use
echo "Which simulator would you like to use?"
echo "1. Apple Watch Series 9 (45mm) - 396 x 484 pixels"
echo "2. Apple Watch Series 9 (41mm) - 368 x 448 pixels"
echo ""
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        DEVICE_NAME="Apple Watch Series 9"
        RESOLUTION="396x484"
        echo "Selected: $DEVICE_NAME ($RESOLUTION)"
        ;;
    2)
        DEVICE_NAME="Apple Watch Series 9 (41mm)"
        RESOLUTION="368x448"
        echo "Selected: $DEVICE_NAME ($RESOLUTION)"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "📋 Screenshot Capture Instructions"
echo "================================================"
echo ""
echo "STEPS:"
echo ""
echo "1. Boot the simulator:"
echo "   xcrun simctl boot \"$DEVICE_NAME\""
echo ""
echo "2. Run your app in Xcode on this simulator"
echo ""
echo "3. To capture screenshots:"
echo "   - Press: Control + Command + Shift + 3 (full window)"
echo "   - OR: Control + Command + Shift + 4 (select area)"
echo ""
echo "4. Screenshots save to Desktop automatically"
echo ""
echo "5. You need 3-10 screenshots showing:"
echo "   - Main screen with quote"
echo "   - Philosopher selection"
echo "   - Tools/exercises menu"
echo "   - At least one tool in action (breathing, journal, etc.)"
echo "   - Settings screen (optional)"
echo ""

# Offer to boot simulator
echo ""
read -p "Do you want to boot the simulator now? (y/n): " boot_choice

if [[ $boot_choice == "y" || $boot_choice == "Y" ]]; then
    echo ""
    echo "Booting simulator..."
    xcrun simctl boot "$DEVICE_NAME" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Simulator booted successfully!"
        echo ""
        echo "Now:"
        echo "1. Open Xcode"
        echo "2. Select \"$DEVICE_NAME\" as destination"
        echo "3. Run your app (⌘R)"
        echo "4. Navigate through your app and capture screenshots"
        echo ""
        echo "Screenshot folder will be created at:"
        mkdir -p ~/Desktop/StoicCompanion_Screenshots
        echo "   ~/Desktop/StoicCompanion_Screenshots/"
        echo ""
        echo "Move your screenshots there after capturing!"
    else
        echo "⚠️  Simulator may already be running or unavailable"
        echo "Check Simulator app or try manually"
    fi
else
    echo ""
    echo "To boot manually later:"
    echo "   xcrun simctl boot \"$DEVICE_NAME\""
fi

echo ""
echo "================================================"
echo "📝 Screenshot Requirements Summary"
echo "================================================"
echo ""
echo "For $DEVICE_NAME:"
echo "  - Resolution: $RESOLUTION pixels"
echo "  - Format: PNG or JPEG"
echo "  - Count: 3-10 screenshots"
echo "  - Orientation: Portrait"
echo ""
echo "Where to upload:"
echo "  1. Go to: https://appstoreconnect.apple.com"
echo "  2. Select: My Apps → Stoic Companion"
echo "  3. Click: App Store tab"
echo "  4. Under \"App Store Information\" → Add screenshots"
echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Happy screenshotting! 📸"
echo ""
