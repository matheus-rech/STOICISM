#!/bin/bash
# Archive and Deploy to TestFlight
# Usage: ./archive_testflight.sh

set -e  # Exit on error

echo "🏗️  Starting archive process for Stoic Camarade..."

PROJECT_PATH="/Users/matheusrech/Downloads/deploy/STOICISM-main/Stoic_Camarade.xcodeproj"
SCHEME="Stoic_Camarade Watch App"
ARCHIVE_PATH="$HOME/Desktop/StoicCamarade.xcarchive"
EXPORT_PATH="$HOME/Desktop/StoicCamarade_Export"

# Step 1: Clean
echo "🧹 Cleaning build folder..."
xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME"

# Step 2: Archive
echo "📦 Creating archive..."
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=watchOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=Z2U6JRPZ53

# Step 3: Create export options
echo "⚙️  Creating export options..."
cat > /tmp/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>Z2U6JRPZ53</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

# Step 4: Export for App Store
echo "📤 Exporting for App Store..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -allowProvisioningUpdates

# Step 5: Upload to App Store Connect
echo "☁️  Uploading to TestFlight..."
echo "⚠️  You'll need to upload manually using:"
echo "   1. Open Xcode → Window → Organizer"
echo "   2. Select Archives tab"
echo "   3. Select the archive and click 'Distribute App'"
echo "   OR use: xcrun altool --upload-app -f '$EXPORT_PATH/*.ipa' -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD"

echo ""
echo "✅ Archive created at: $ARCHIVE_PATH"
echo "✅ Exported to: $EXPORT_PATH"
echo "✅ Build version: 1.0 (2)"
echo ""
echo "📱 Next steps:"
echo "   1. Upload to App Store Connect (see above)"
echo "   2. Wait for processing (~10 mins)"
echo "   3. Add to Internal Testing in App Store Connect"
echo "   4. Share with testers!"
