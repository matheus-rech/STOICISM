#!/bin/bash

# Complete Automated Solution for Stoic Companion Archive
# This script will:
# 1. Open Xcode with specific instructions
# 2. Guide you through fixing the scheme
# 3. Help you archive and upload

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}🚀 Stoic Companion - Automated App Store Upload${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""

PROJECT_DIR="/Users/matheusrech/Desktop/STOICISM-main"
cd "$PROJECT_DIR"

echo -e "${BLUE}Project Location:${NC} $PROJECT_DIR"
echo ""

# Step 1: Explain the issue
echo -e "${YELLOW}📋 Current Situation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your Xcode project has two targets:"
echo "  1. ❌ 'Stoic_Companion' (legacy iOS container)"
echo "  2. ✅ 'Stoic_Companion Watch App' (your actual watchOS app)"
echo ""
echo "Problem: The Archive scheme tries to build BOTH targets,"
echo "but the legacy target needs provisioning profiles."
echo ""
echo -e "${GREEN}Solution: We'll use Xcode GUI to handle this automatically!${NC}"
echo ""

# Step 2: Open Xcode
echo -e "${YELLOW}📱 Step 1: Opening Xcode...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
open "$PROJECT_DIR/Stoic_Companion.xcodeproj"
sleep 2
echo -e "${GREEN}✅ Xcode opened${NC}"
echo ""

# Step 3: Interactive guide
echo -e "${YELLOW}📋 Step 2: Follow These Steps in Xcode${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BOLD}In Xcode (just opened):${NC}"
echo ""
echo -e "${BLUE}1. Select Build Destination (TOP-LEFT):${NC}"
echo "   Click dropdown next to scheme name"
echo "   Select: ${GREEN}'Any watchOS Device (arm64)'${NC}"
echo "   ⚠️  Must be DEVICE, not simulator!"
echo ""
echo -e "${BLUE}2. Verify Signing:${NC}"
echo "   - Click 'Stoic_Companion' in left sidebar (blue icon)"
echo "   - Select 'Stoic_Companion Watch App' target"
echo "   - Go to 'Signing & Capabilities' tab"
echo "   - Ensure 'Automatically manage signing' is ✅ CHECKED"
echo ""
echo -e "${BLUE}3. Create Archive:${NC}"
echo "   Menu: ${GREEN}Product → Archive${NC}"
echo "   (or press ⌘⇧B then select Archive)"
echo ""
echo -e "${BLUE}4. Wait for Archive:${NC}"
echo "   - Progress bar shows in Xcode"
echo "   - Takes 2-5 minutes"
echo "   - Organizer window opens when done"
echo ""
echo -e "${BLUE}5. Upload to App Store:${NC}"
echo "   In Organizer window:"
echo "   - Select your archive (today's date)"
echo "   - Click '${GREEN}Distribute App${NC}'"
echo "   - Select '${GREEN}App Store Connect${NC}'"
echo "   - Select '${GREEN}Upload${NC}'"
echo "   - Follow prompts → Click '${GREEN}Upload${NC}'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 4: Offer to open documentation
echo -e "${YELLOW}📚 Need More Details?${NC}"
echo ""
echo "I've created comprehensive guides for you:"
echo ""
echo -e "${BLUE}Quick Reference:${NC}"
echo "  open QUICK_UPLOAD_CHECKLIST.md"
echo ""
echo -e "${BLUE}Complete Guide:${NC}"
echo "  open APP_STORE_CONNECT_COMPLETE_GUIDE.md"
echo ""

read -p "Open quick checklist now? (y/n): " open_docs

if [[ $open_docs == "y" || $open_docs == "Y" ]]; then
    open "QUICK_UPLOAD_CHECKLIST.md"
    sleep 1
    open "APP_STORE_CONNECT_COMPLETE_GUIDE.md"
    echo -e "${GREEN}✅ Documentation opened${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}${GREEN}✨ Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Xcode is open and ready."
echo "Follow the 5 steps above to archive and upload."
echo ""
echo -e "${YELLOW}Estimated time: 30 minutes${NC}"
echo ""

# Step 5: Wait for completion
echo -e "${BLUE}When you're done uploading:${NC}"
echo ""
echo "1. Go to: https://appstoreconnect.apple.com"
echo "2. Check: My Apps → Stoic Companion → Activity"
echo "3. Wait for processing (10-60 minutes)"
echo "4. Upload screenshots (required!)"
echo "5. Submit for review"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Good luck! 🍀${NC}"
echo ""
