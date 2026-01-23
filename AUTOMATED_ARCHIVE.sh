#!/bin/bash

# Automated Archive Script for Stoic Companion
# This script attempts to create an archive for App Store Connect

set -e  # Exit on error

echo "========================================"
echo "📦 Automated Archive for Stoic Companion"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project settings
PROJECT_DIR="/Users/matheusrech/Desktop/STOICISM-main"
cd "$PROJECT_DIR"

SCHEME="Stoic_Companion Watch App"
ARCHIVE_PATH="./build/StoicCompanion.xcarchive"
EXPORT_PATH="./build/export"

echo "Project: $PROJECT_DIR"
echo "Scheme: $SCHEME"
echo ""

# Step 1: Clean
echo "🧹 Step 1: Cleaning build artifacts..."
xcodebuild -scheme "$SCHEME" clean
echo -e "${GREEN}✅ Clean completed${NC}"
echo ""

# Step 2: Archive (THE PROBLEM)
echo "📦 Step 2: Creating archive..."
echo ""
echo -e "${YELLOW}⚠️  ISSUE DETECTED:${NC}"
echo "The scheme is configured to archive BOTH:"
echo "  - Stoic_Companion (legacy iOS target)"
echo "  - Stoic_Companion Watch App (watchOS target)"
echo ""
echo "The legacy target needs provisioning profiles."
echo ""
echo -e "${YELLOW}RECOMMENDED SOLUTION:${NC}"
echo "Use Xcode GUI to archive (handles provisioning automatically)"
echo ""
echo "Steps:"
echo "1. Open Xcode (already open)"
echo "2. Product → Scheme → Edit Scheme"
echo "3. Select 'Archive' in left sidebar"
echo "4. Uncheck 'Stoic_Companion' target"
echo "5. Keep only 'Stoic_Companion Watch App' checked"
echo "6. Save and try archiving again"
echo ""
echo -e "${GREEN}OR${NC}"
echo ""
echo "Use Xcode GUI directly:"
echo "1. Select 'Any watchOS Device (arm64)'"
echo "2. Product → Archive"
echo "3. Xcode handles all signing automatically"
echo ""
read -p "Do you want to try command-line archive anyway? (y/n): " choice

if [[ $choice != "y" && $choice != "Y" ]]; then
    echo ""
    echo -e "${YELLOW}Exiting. Please use Xcode GUI method.${NC}"
    echo ""
    echo "Quick steps:"
    echo "1. In Xcode: Select 'Any watchOS Device (arm64)'"
    echo "2. Product → Archive"
    echo "3. Click 'Distribute App'"
    echo ""
    exit 0
fi

echo ""
echo "Attempting archive..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=watchOS' \
    -allowProvisioningUpdates \
    2>&1 | tee archive_log.txt

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ Archive created successfully!${NC}"
    echo "Archive location: $ARCHIVE_PATH"
    echo ""

    # Step 3: Export
    echo "📤 Step 3: Exporting for App Store..."
    echo ""
    echo "Note: Export requires ExportOptions.plist"
    echo "This is easier to do in Xcode GUI:"
    echo "  Organizer → Distribute App → Upload"
    echo ""
else
    echo -e "${RED}❌ Archive failed${NC}"
    echo ""
    echo "See archive_log.txt for details"
    echo ""
    echo -e "${YELLOW}SOLUTION:${NC}"
    echo "1. Open QUICK_TESTFLIGHT_STEPS.md"
    echo "2. Follow the 'Alternative: Quick Fix for Command-Line' section"
    echo "3. OR use Xcode GUI (Product → Archive)"
    echo ""
    exit 1
fi
