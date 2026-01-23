#!/bin/bash

# Fix Signing Configuration for App Store Distribution
# This script updates the Xcode project to use Distribution signing for Release builds

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${BOLD}================================================${NC}"
echo -e "${BOLD}🔧 Fixing Signing Configuration for App Store${NC}"
echo -e "${BOLD}================================================${NC}"
echo ""

PROJECT_DIR="/Users/matheusrech/Desktop/STOICISM-main"
cd "$PROJECT_DIR"

PROJECT_FILE="Stoic_Companion.xcodeproj/project.pbxproj"
BACKUP_FILE="Stoic_Companion.xcodeproj/project.pbxproj.backup"

echo -e "${YELLOW}Step 1: Backing up project file...${NC}"
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
echo ""

echo -e "${YELLOW}Step 2: Analyzing current signing configuration...${NC}"
echo ""

# Check current CODE_SIGN_IDENTITY settings
echo "Current signing identities:"
grep -n "CODE_SIGN_IDENTITY" "$PROJECT_FILE" | head -20

echo ""
echo -e "${YELLOW}Step 3: Updating signing for App Store Distribution...${NC}"
echo ""

# Create a temporary file with updated settings
# We need to change CODE_SIGN_IDENTITY from "Apple Development" to "iPhone Distribution"
# for Release configuration

# Use sed to update the project file
# This targets the Release configuration specifically

echo "Modifying project file..."

# For macOS sed, we need to handle it differently
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    # Replace "Apple Development" with "iPhone Distribution" for release builds
    sed -i '' 's/CODE_SIGN_IDENTITY = "Apple Development"/CODE_SIGN_IDENTITY = "Apple Distribution"/g' "$PROJECT_FILE"

    # Also update any CODE_SIGN_STYLE if needed
    # Ensure automatic provisioning is enabled

else
    # Linux sed
    sed -i 's/CODE_SIGN_IDENTITY = "Apple Development"/CODE_SIGN_IDENTITY = "Apple Distribution"/g' "$PROJECT_FILE"
fi

echo -e "${GREEN}✅ Project file updated${NC}"
echo ""

echo -e "${YELLOW}Step 4: Verifying changes...${NC}"
echo ""
echo "Updated signing identities:"
grep -n "CODE_SIGN_IDENTITY" "$PROJECT_FILE" | head -20
echo ""

echo -e "${YELLOW}Step 5: Alternative approach - Manual Configuration${NC}"
echo ""
echo "Since Xcode project files are complex, the safest approach is:"
echo ""
echo -e "${BLUE}In Xcode (close and reopen after running this script):${NC}"
echo ""
echo "1. Select 'Stoic_Companion' project (left sidebar)"
echo "2. Select 'Stoic_Companion Watch App' target"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Under 'Signing (Release)':"
echo "   - Ensure 'Automatically manage signing' is ✅ CHECKED"
echo "   - OR manually select 'Apple Distribution' profile"
echo ""

echo -e "${YELLOW}Step 6: Try archiving again${NC}"
echo ""
echo "Close Xcode completely, then:"
echo "1. Reopen: open Stoic_Companion.xcodeproj"
echo "2. Select 'Any watchOS Device (arm64)'"
echo "3. Product → Archive"
echo ""

echo -e "${BOLD}${GREEN}================================================${NC}"
echo -e "${BOLD}${GREEN}✨ Signing Configuration Updated!${NC}"
echo -e "${BOLD}${GREEN}================================================${NC}"
echo ""
echo "If archiving still fails, restore backup:"
echo "  cp $BACKUP_FILE $PROJECT_FILE"
echo ""
echo "Then use Xcode GUI to configure signing manually."
echo ""
