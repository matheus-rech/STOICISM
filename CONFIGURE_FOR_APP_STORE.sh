#!/bin/bash

# Complete App Store Configuration Script
# Handles signing, provisioning, and prepares for archive

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}🔐 App Store Configuration Wizard${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

PROJECT_DIR="/Users/matheusrech/Desktop/STOICISM-main"
cd "$PROJECT_DIR"

SCHEME="Stoic_Companion Watch App"
TEAM_ID="Z2U6JRPZ53"
BUNDLE_ID="com.stoic.companion.watchkitapp"

echo -e "${BLUE}Project:${NC} $PROJECT_DIR"
echo -e "${BLUE}Scheme:${NC} $SCHEME"
echo -e "${BLUE}Team ID:${NC} $TEAM_ID"
echo -e "${BLUE}Bundle ID:${NC} $BUNDLE_ID"
echo ""

echo -e "${YELLOW}📋 Current Issue:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "No provisioning profiles found because:"
echo "  1. No physical devices registered in Apple Developer account"
echo "  2. Project trying to use Development profiles for Release"
echo ""

echo -e "${GREEN}✅ Solution:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configure Xcode to use AUTOMATIC signing with Distribution profiles"
echo ""

echo -e "${YELLOW}🔧 Option 1: Automatic Fix in Xcode (RECOMMENDED)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Close Xcode completely, then I'll guide you:"
read -p "Have you closed Xcode? (y/n): " closed

if [[ $closed != "y" && $closed != "Y" ]]; then
    echo ""
    echo -e "${RED}Please close Xcode first, then run this script again.${NC}"
    exit 1
fi

echo ""
echo "Opening Xcode..."
open "Stoic_Companion.xcodeproj"
sleep 3

echo ""
echo -e "${BOLD}${BLUE}Follow these steps in Xcode:${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Step 1: Configure Signing${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Click 'Stoic_Companion' in left sidebar (blue icon)"
echo "2. Select 'Stoic_Companion Watch App' target"
echo "3. Click 'Signing & Capabilities' tab"
echo ""
echo "4. Check the 'Automatically manage signing' box"
echo "   ✅ This should be CHECKED"
echo ""
echo "5. Under 'Team', select: Z2U6JRPZ53"
echo ""
echo "6. Xcode will automatically generate Distribution profiles"
echo ""

read -p "Press Enter when you've completed Step 1..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Step 2: Configure Legacy Target (Optional)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If you see 'Stoic_Companion' target with errors:"
echo ""
echo "1. Select 'Stoic_Companion' target (not Watch App)"
echo "2. Go to 'Signing & Capabilities'"
echo "3. UNCHECK 'Automatically manage signing'"
echo "4. Leave it unconfigured (we won't archive this target)"
echo ""
echo "OR better yet:"
echo ""
echo "5. Edit Scheme to exclude legacy target:"
echo "   - Product → Scheme → Edit Scheme"
echo "   - Select 'Archive' in left sidebar"
echo "   - UNCHECK 'Stoic_Companion' target"
echo "   - Keep only 'Stoic_Companion Watch App' checked"
echo "   - Click 'Close'"
echo ""

read -p "Press Enter when ready..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Step 3: Try Archive${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Select 'Any watchOS Device (arm64)' (top-left)"
echo "2. Product → Clean Build Folder (⇧⌘K)"
echo "3. Product → Archive"
echo ""

read -p "Ready to proceed? (y/n): " proceed

if [[ $proceed == "y" || $proceed == "Y" ]]; then
    echo ""
    echo -e "${GREEN}✅ Perfect! Try archiving now.${NC}"
    echo ""
    echo "If it works:"
    echo "  - Organizer opens with your archive"
    echo "  - Click 'Distribute App' → Upload"
    echo ""
    echo "If it still fails:"
    echo "  - Take a screenshot of the error"
    echo "  - Check that you completed all steps above"
    echo ""
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔧 Option 2: Command-Line with Manual Signing${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "If automatic signing doesn't work, we can try:"
echo ""
echo "1. Create Distribution certificate manually:"
echo "   https://developer.apple.com/account/resources/certificates/add"
echo ""
echo "2. Create App Store provisioning profile:"
echo "   https://developer.apple.com/account/resources/profiles/add"
echo "   - Type: App Store"
echo "   - App ID: com.stoic.companion.watchkitapp"
echo ""
echo "3. Download and install profiles in Xcode"
echo ""
echo "4. Try archiving again"
echo ""

echo -e "${BOLD}${GREEN}========================================${NC}"
echo -e "${BOLD}${GREEN}✨ Configuration Guide Complete!${NC}"
echo -e "${BOLD}${GREEN}========================================${NC}"
echo ""
echo "Next: Try archiving in Xcode!"
echo ""
