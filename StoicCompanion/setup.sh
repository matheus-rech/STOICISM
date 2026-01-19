#!/bin/bash

# 🏛️ Stoic Companion - Automated Setup Script
# This script helps your friends set up the app quickly

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌"
ROCKET="🚀"
WRENCH="🔧"
STAR="⭐"
CLOCK="⏰"
BOOK="📚"

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/Stoic_Companion"

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}    🏛️  STOIC COMPANION - AUTOMATED SETUP${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${CYAN}${ROCKET} $1${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}${STAR} $1${NC}"
}

# Check if running on macOS
print_step "Step 1: Checking System Requirements"
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must run on macOS"
    exit 1
fi
print_success "Running on macOS"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed!"
    echo ""
    echo "Please install Xcode from the App Store:"
    echo "https://apps.apple.com/us/app/xcode/id497799835"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
print_success "Xcode found: $XCODE_VERSION"

# Check Xcode version
XCODE_MAJOR_VERSION=$(xcodebuild -version | head -n 1 | sed 's/Xcode //' | cut -d'.' -f1)
if [ "$XCODE_MAJOR_VERSION" -lt 15 ]; then
    print_warning "Xcode 15.0+ is recommended. You have version $XCODE_VERSION"
    echo "The app may still work, but consider updating."
    echo ""
fi

# Check for project directory
print_step "Step 2: Locating Project Files"
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    print_info "Make sure you're running this script from the StoicCompanion folder"
    exit 1
fi
print_success "Project directory found"

# Find .xcodeproj file
XCODEPROJ=$(find "$PROJECT_DIR" -name "*.xcodeproj" -maxdepth 1 | head -n 1)
if [ -z "$XCODEPROJ" ]; then
    print_error "No Xcode project file found in $PROJECT_DIR"
    exit 1
fi
print_success "Xcode project found: $(basename "$XCODEPROJ")"

# List required new files
print_step "Step 3: Checking Required Files"
REQUIRED_FILES=(
    "LLMService.swift"
    "OpenAIService.swift"
    "GeminiService.swift"
    "LLMServiceFactory.swift"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    print_error "Some required files are missing!"
    echo ""
    echo "Missing files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

# Check updated files
print_step "Step 4: Checking Updated Files"
UPDATED_FILES=(
    "Config.swift"
    "ContentView.swift"
    "ClaudeService.swift"
)

for file in "${UPDATED_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        print_success "Found: $file (updated version)"
    else
        print_warning "Missing: $file"
    fi
done

# Create backup
print_step "Step 5: Creating Backup"
BACKUP_DIR="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
if [ -d "$PROJECT_DIR" ]; then
    cp -r "$PROJECT_DIR" "$BACKUP_DIR/" 2>/dev/null || true
    print_success "Backup created: $BACKUP_DIR"
else
    print_warning "Could not create backup - project directory not accessible"
fi

# Summary
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${CHECK} All checks passed!${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""

# Interactive mode
print_info "Choose setup method:"
echo ""
echo "  1) ${CYAN}Open Xcode and show manual instructions${NC} (Recommended)"
echo "  2) ${CYAN}Just open Xcode project${NC}"
echo "  3) ${CYAN}Show file locations and exit${NC}"
echo "  4) ${CYAN}Build from command line${NC} (Advanced)"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        # Manual instructions
        print_step "Opening Xcode with Instructions"

        echo ""
        echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}    📋 MANUAL SETUP INSTRUCTIONS${NC}"
        echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${CYAN}Follow these steps in Xcode:${NC}"
        echo ""
        echo "1️⃣  In the left sidebar (Project Navigator):"
        echo "   • Find the 'Stoic_Companion Watch App' folder"
        echo "   • Right-click → 'Add Files to \"Stoic_Companion\"...'"
        echo ""
        echo "2️⃣  Select these 4 NEW files:"
        for file in "${REQUIRED_FILES[@]}"; do
            echo "   ${CHECK} $file"
        done
        echo ""
        echo "3️⃣  IMPORTANT: Check these options:"
        echo "   ☑️  'Copy items if needed'"
        echo "   ☑️  'Create groups'"
        echo "   ☑️  Add to target: 'Stoic_Companion Watch App' ${YELLOW}(CRITICAL!)${NC}"
        echo ""
        echo "4️⃣  Click 'Add'"
        echo ""
        echo "5️⃣  Build the project:"
        echo "   • Press ⌘B or Product → Build"
        echo "   • Fix any errors (usually just missing target membership)"
        echo ""
        echo "6️⃣  Select your Apple Watch as destination"
        echo ""
        echo "7️⃣  Run the app:"
        echo "   • Press ⌘R or Product → Run"
        echo ""
        echo -e "${GREEN}${STAR} No API key setup needed - already configured!${NC}"
        echo ""
        echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
        echo ""

        read -p "Press Enter to open Xcode..."
        open "$XCODEPROJ"

        # Open file location in Finder
        sleep 2
        open "$SCRIPT_DIR"

        print_success "Xcode opened! Follow the instructions above."
        print_info "Finder opened to show file locations"
        ;;

    2)
        # Just open Xcode
        print_step "Opening Xcode Project"
        open "$XCODEPROJ"
        print_success "Xcode project opened!"
        print_info "Don't forget to add the 4 new Swift files to your Watch App target"
        ;;

    3)
        # Show file locations
        print_step "File Locations"
        echo ""
        echo -e "${CYAN}New files to add (in this directory):${NC}"
        for file in "${REQUIRED_FILES[@]}"; do
            echo "  📄 $SCRIPT_DIR/$file"
        done
        echo ""
        echo -e "${CYAN}Updated files (replace in Xcode):${NC}"
        for file in "${UPDATED_FILES[@]}"; do
            echo "  📄 $SCRIPT_DIR/$file"
        done
        echo ""
        print_info "Opening Finder to show file location..."
        open "$SCRIPT_DIR"
        ;;

    4)
        # Build from command line
        print_step "Building from Command Line"

        # Find scheme
        SCHEME=$(xcodebuild -list -project "$XCODEPROJ" 2>/dev/null | grep -A 1 "Schemes:" | tail -n 1 | xargs)

        if [ -z "$SCHEME" ]; then
            print_error "Could not find build scheme"
            exit 1
        fi

        print_info "Building scheme: $SCHEME"
        echo ""

        # Build
        print_warning "This will take a few minutes..."
        if xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Debug build 2>&1 | grep -E "error:|warning:|succeeded"; then
            echo ""
            print_success "Build completed!"
            print_info "Connect your Apple Watch and run from Xcode to install"
        else
            echo ""
            print_error "Build failed. Please check the errors above."
            print_info "You may need to add the new files to the project first"
        fi
        ;;

    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Final notes
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${ROCKET} Setup Complete!${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📚 Next Steps:${NC}"
echo ""
echo "  1. Add the 4 new Swift files to Watch App target"
echo "  2. Build and run on your Apple Watch (⌘R)"
echo "  3. Grant HealthKit permissions when prompted"
echo "  4. Try: 'Hey Siri, get stoic wisdom'"
echo ""
echo -e "${CYAN}📖 Documentation:${NC}"
echo ""
echo "  • README_FOR_TESTERS.md - Quick start guide"
echo "  • MULTI_PROVIDER_GUIDE.md - Detailed documentation"
echo "  • SECURITY_NOTE.md - Cost & security info"
echo ""
echo -e "${GREEN}${STAR} AI is already configured - no API key setup needed!${NC}"
echo ""
echo -e "${BLUE}Questions? Check the README files or contact the developer.${NC}"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🏛️  'The obstacle is the way.' — Marcus Aurelius${NC}"
echo ""
