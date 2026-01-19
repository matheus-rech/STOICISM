#!/bin/bash

# 🏛️ Stoic Companion - Verify Setup
# This script checks if everything is configured correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}    🔍 STOIC COMPANION - SETUP VERIFICATION${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/Stoic_Companion"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to check item
check_item() {
    local description="$1"
    local condition="$2"

    echo -n "$description ... "

    if eval "$condition"; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Function to check warning
check_warning() {
    local description="$1"
    local condition="$2"

    echo -n "$description ... "

    if eval "$condition"; then
        echo -e "${GREEN}✅ OK${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${YELLOW}⚠️  WARNING${NC}"
        ((WARN_COUNT++))
        return 1
    fi
}

echo -e "${CYAN}🔧 System Requirements${NC}"
echo ""

check_item "macOS detected" "[[ \"\$OSTYPE\" == \"darwin\"* ]]"
check_item "Xcode installed" "command -v xcodebuild &> /dev/null"

if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1 | sed 's/Xcode //')
    echo "   ℹ️  Version: $XCODE_VERSION"
fi

echo ""
echo -e "${CYAN}📁 Project Structure${NC}"
echo ""

check_item "Project directory exists" "[ -d \"$PROJECT_DIR\" ]"
check_item "Xcode project file exists" "[ -f \"$PROJECT_DIR/Stoic_Companion.xcodeproj/project.pbxproj\" ]"

echo ""
echo -e "${CYAN}📄 Required New Files${NC}"
echo ""

REQUIRED_FILES=(
    "LLMService.swift"
    "OpenAIService.swift"
    "GeminiService.swift"
    "LLMServiceFactory.swift"
)

for file in "${REQUIRED_FILES[@]}"; do
    check_item "$file present" "[ -f \"$SCRIPT_DIR/$file\" ]"
done

echo ""
echo -e "${CYAN}📝 Updated Core Files${NC}"
echo ""

CORE_FILES=(
    "Config.swift"
    "ContentView.swift"
    "ClaudeService.swift"
)

for file in "${CORE_FILES[@]}"; do
    check_item "$file present" "[ -f \"$SCRIPT_DIR/$file\" ]"
done

echo ""
echo -e "${CYAN}📦 Resources${NC}"
echo ""

check_warning "StoicQuotes.json present" "[ -f \"$SCRIPT_DIR/StoicQuotes.json\" ]"

echo ""
echo -e "${CYAN}🔑 API Configuration${NC}"
echo ""

# Check Config.swift for API key
if [ -f "$SCRIPT_DIR/Config.swift" ]; then
    if grep -q "sk-proj-" "$SCRIPT_DIR/Config.swift" 2>/dev/null; then
        echo -e "OpenAI API key configured ... ${GREEN}✅ OK${NC}"
        ((PASS_COUNT++))

        # Check if it's the placeholder
        if grep -q "YOUR_OPENAI_API_KEY_HERE" "$SCRIPT_DIR/Config.swift" 2>/dev/null; then
            echo -e "   ${YELLOW}⚠️  Warning: Placeholder key still present${NC}"
            ((WARN_COUNT++))
        fi
    else
        echo -e "OpenAI API key configured ... ${RED}❌ FAIL${NC}"
        echo "   (No valid OpenAI key found in Config.swift)"
        ((FAIL_COUNT++))
    fi

    # Check provider selection
    if grep -q "llmProvider: LLMProvider = .openai" "$SCRIPT_DIR/Config.swift" 2>/dev/null; then
        echo -e "Provider set to OpenAI ... ${GREEN}✅ OK${NC}"
        ((PASS_COUNT++))
    else
        echo -e "Provider set to OpenAI ... ${YELLOW}⚠️  WARNING${NC}"
        echo "   (Provider may be set to different option)"
        ((WARN_COUNT++))
    fi
else
    echo -e "Config.swift check ... ${RED}❌ FAIL${NC}"
    ((FAIL_COUNT++))
fi

echo ""
echo -e "${CYAN}📚 Documentation${NC}"
echo ""

DOC_FILES=(
    "README_FOR_TESTERS.md"
    "SETUP_CHECKLIST.md"
)

for file in "${DOC_FILES[@]}"; do
    check_warning "$file present" "[ -f \"$SCRIPT_DIR/$file\" ]"
done

echo ""
echo -e "${CYAN}🛠️  Build Configuration${NC}"
echo ""

# Check if project can be read
XCODEPROJ="$PROJECT_DIR/Stoic_Companion.xcodeproj"
if [ -f "$XCODEPROJ/project.pbxproj" ]; then
    # Try to get scheme
    if xcodebuild -list -project "$XCODEPROJ" &> /dev/null; then
        echo -e "Xcode project readable ... ${GREEN}✅ OK${NC}"
        ((PASS_COUNT++))

        SCHEME=$(xcodebuild -list -project "$XCODEPROJ" 2>/dev/null | grep -A 1 "Schemes:" | tail -n 1 | xargs)
        if [ -n "$SCHEME" ]; then
            echo "   ℹ️  Scheme: $SCHEME"
        fi
    else
        echo -e "Xcode project readable ... ${YELLOW}⚠️  WARNING${NC}"
        echo "   (Could not read project schemes)"
        ((WARN_COUNT++))
    fi
fi

# Summary
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}    📊 VERIFICATION SUMMARY${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}✅ Passed:  $PASS_COUNT${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARN_COUNT${NC}"
echo -e "${RED}❌ Failed:  $FAIL_COUNT${NC}"
echo ""

# Final verdict
if [ $FAIL_COUNT -eq 0 ]; then
    if [ $WARN_COUNT -eq 0 ]; then
        echo -e "${GREEN}🎉 Perfect! Everything is set up correctly!${NC}"
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  1. Open Xcode project"
        echo "  2. Add the 4 new Swift files to Watch App target"
        echo "  3. Build and run (⌘R)"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Setup is mostly correct, but has warnings${NC}"
        echo ""
        echo "Review the warnings above. The app should still work."
        echo ""
    fi
else
    echo -e "${RED}❌ Setup has errors that need to be fixed${NC}"
    echo ""
    echo "Please fix the failed checks above before proceeding."
    echo ""
fi

# Additional checks
echo -e "${CYAN}💡 Quick Checks:${NC}"
echo ""

if [ -f "$SCRIPT_DIR/setup.sh" ]; then
    echo -e "${GREEN}✅${NC} Setup script available (./setup.sh)"
else
    echo -e "${YELLOW}⚠️${NC}  Setup script missing"
fi

if [ -f "$SCRIPT_DIR/create_distribution.sh" ]; then
    echo -e "${GREEN}✅${NC} Distribution script available (./create_distribution.sh)"
else
    echo -e "${YELLOW}⚠️${NC}  Distribution script missing"
fi

echo ""
echo -e "${CYAN}🔗 Useful Commands:${NC}"
echo ""
echo "  ./setup.sh              - Interactive setup"
echo "  ./verify_setup.sh       - Run this verification again"
echo "  ./create_distribution.sh - Create ZIP for friends"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

# Exit with appropriate code
if [ $FAIL_COUNT -eq 0 ]; then
    exit 0
else
    exit 1
fi
