#!/bin/bash

# 🏛️ Stoic Companion - Create Distribution Package
# This script creates a ZIP file to share with friends

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  📦 Creating Distribution Package${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Package name
DATE=$(date +%Y%m%d)
PACKAGE_NAME="StoicCompanion_TestBuild_$DATE"
PACKAGE_DIR="/tmp/$PACKAGE_NAME"
ZIP_FILE="$HOME/Desktop/${PACKAGE_NAME}.zip"

echo -e "${CYAN}🔧 Step 1: Creating package directory...${NC}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"
echo -e "${GREEN}✅ Created: $PACKAGE_DIR${NC}"
echo ""

echo -e "${CYAN}🔧 Step 2: Copying project files...${NC}"

# Copy Xcode project
if [ -d "Stoic_Companion" ]; then
    cp -r "Stoic_Companion" "$PACKAGE_DIR/"
    echo -e "${GREEN}✅ Copied Xcode project${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Stoic_Companion directory not found${NC}"
fi

# Copy new Swift files
SWIFT_FILES=(
    "LLMService.swift"
    "OpenAIService.swift"
    "GeminiService.swift"
    "LLMServiceFactory.swift"
    "Config.swift"
    "ContentView.swift"
    "ClaudeService.swift"
)

for file in "${SWIFT_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$PACKAGE_DIR/"
        echo -e "${GREEN}✅ Copied: $file${NC}"
    fi
done

# Copy resources
if [ -f "StoicQuotes.json" ]; then
    cp "StoicQuotes.json" "$PACKAGE_DIR/"
    echo -e "${GREEN}✅ Copied: StoicQuotes.json${NC}"
fi

# Copy documentation
DOC_FILES=(
    "README_FOR_TESTERS.md"
    "MULTI_PROVIDER_GUIDE.md"
    "SECURITY_NOTE.md"
    "SETUP_CHECKLIST.md"
    "README.md"
    "QUICKSTART.md"
)

echo ""
echo -e "${CYAN}🔧 Step 3: Copying documentation...${NC}"
for file in "${DOC_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$PACKAGE_DIR/"
        echo -e "${GREEN}✅ Copied: $file${NC}"
    fi
done

# Copy setup script
if [ -f "setup.sh" ]; then
    cp "setup.sh" "$PACKAGE_DIR/"
    chmod +x "$PACKAGE_DIR/setup.sh"
    echo -e "${GREEN}✅ Copied: setup.sh (executable)${NC}"
fi

# Copy .gitignore
if [ -f ".gitignore" ]; then
    cp ".gitignore" "$PACKAGE_DIR/"
    echo -e "${GREEN}✅ Copied: .gitignore${NC}"
fi

echo ""
echo -e "${CYAN}🔧 Step 4: Creating quick start guide...${NC}"

cat > "$PACKAGE_DIR/START_HERE.txt" << 'EOF'
🏛️ STOIC COMPANION - TESTER VERSION
═══════════════════════════════════════════════════

Welcome! Thanks for testing this app.

🚀 QUICK START (5 minutes):

1. Run the setup script:
   - Double-click: setup.sh
   - Or in Terminal: ./setup.sh

2. Follow the instructions in Xcode

3. Build and run on your Apple Watch

4. That's it! No API key needed.

📚 DOCUMENTATION:

• READ ME FIRST → README_FOR_TESTERS.md
• Detailed Guide → MULTI_PROVIDER_GUIDE.md
• Setup Steps → SETUP_CHECKLIST.md
• Security Info → SECURITY_NOTE.md

💡 WHAT IT DOES:

Delivers personalized stoic quotes based on:
- ❤️  Your heart rate (stress detection)
- 🏃 Your activity level
- ⏰ Time of day
- 🤖 AI-powered contextual matching

🗣️ TRY THESE:

"Hey Siri, get stoic wisdom"
"Hey Siri, I'm stressed"
"Hey Siri, good morning Stoic"

🐛 PROBLEMS?

Check README_FOR_TESTERS.md troubleshooting section.

═══════════════════════════════════════════════════
"The obstacle is the way." — Marcus Aurelius
═══════════════════════════════════════════════════
EOF

echo -e "${GREEN}✅ Created: START_HERE.txt${NC}"

echo ""
echo -e "${CYAN}🔧 Step 5: Creating ZIP archive...${NC}"

# Remove old ZIP if exists
rm -f "$ZIP_FILE"

# Create ZIP
cd /tmp
zip -r "$ZIP_FILE" "$PACKAGE_NAME" > /dev/null

if [ -f "$ZIP_FILE" ]; then
    echo -e "${GREEN}✅ Created: $ZIP_FILE${NC}"

    # Get file size
    SIZE=$(du -h "$ZIP_FILE" | cut -f1)
    echo -e "${GREEN}   Size: $SIZE${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to create ZIP${NC}"
    exit 1
fi

# Clean up temp directory
rm -rf "$PACKAGE_DIR"

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Package Created Successfully!${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📦 Package Location:${NC}"
echo "   $ZIP_FILE"
echo ""
echo -e "${CYAN}📧 How to Share:${NC}"
echo ""
echo "  1. Email the ZIP file to your friends"
echo "  2. Or use AirDrop"
echo "  3. Or upload to cloud storage"
echo ""
echo -e "${CYAN}📋 What's Included:${NC}"
echo ""
echo "  ✅ Complete Xcode project"
echo "  ✅ All Swift source files"
echo "  ✅ Setup automation script"
echo "  ✅ Testing documentation"
echo "  ✅ Security & cost info"
echo "  ✅ API key pre-configured"
echo ""
echo -e "${GREEN}🎉 Ready to share with your friends!${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: Tell them to read START_HERE.txt first${NC}"
echo ""

# Open Finder to show the ZIP
echo -e "${CYAN}Opening Desktop folder...${NC}"
open "$HOME/Desktop"

echo ""
