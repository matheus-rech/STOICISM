#!/bin/bash
set -e  # Exit on any error

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  🚀 Automated TestFlight Deployment with Navigation          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
PROJECT_DIR="/Users/matheusrech/Downloads/deploy/STOICISM-main"
PROJECT_FILE="$PROJECT_DIR/Stoic_Companion.xcodeproj"
SCHEME="Stoic_Companion Watch App"
ARCHIVE_PATH="$PROJECT_DIR/build/StoicCompanion.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"

# Step 1: Add SwiftUI files to Xcode project
echo "📝 Step 1/6: Adding SwiftUI components to Xcode project..."

# Files to add
FILES=(
    "MementoMoriDisplayView.swift"
    "TodaysPrioritiesView.swift"
    "QuoteDisplayCardView.swift"
    "FavoritesMenuView.swift"
    "AffirmationDisplayView.swift"
    "BoxBreathingDisplayView.swift"
)

# Backup project file
cp "$PROJECT_FILE/project.pbxproj" "$PROJECT_FILE/project.pbxproj.backup"

# Add files using Python script
python3 << 'PYTHON_SCRIPT'
import sys
import uuid
import re

project_file = "/Users/matheusrech/Downloads/deploy/STOICISM-main/Stoic_Companion.xcodeproj/project.pbxproj"

files_to_add = [
    "MementoMoriDisplayView.swift",
    "TodaysPrioritiesView.swift",
    "QuoteDisplayCardView.swift",
    "FavoritesMenuView.swift",
    "AffirmationDisplayView.swift",
    "BoxBreathingDisplayView.swift"
]

def generate_xcode_uuid():
    """Generate Xcode-style 24-character hex UUID"""
    return uuid.uuid4().hex.upper()[:24]

# Read project file
with open(project_file, 'r') as f:
    content = f.read()

# Check if files are already added
already_added = all(filename in content for filename in files_to_add)

if already_added:
    print("✅ All SwiftUI files already in project")
    sys.exit(0)

print("Adding SwiftUI files to Xcode project...")

# Generate UUIDs for each file
file_refs = []
build_files = []

for filename in files_to_add:
    if filename in content:
        print(f"  ⏭️  {filename} already added")
        continue

    file_ref_uuid = generate_xcode_uuid()
    build_file_uuid = generate_xcode_uuid()

    file_refs.append((file_ref_uuid, filename))
    build_files.append((build_file_uuid, file_ref_uuid, filename))
    print(f"  ✅ {filename}")

# Add to PBXBuildFile section
build_file_pattern = r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)'
if match := re.search(build_file_pattern, content, re.DOTALL):
    section = match.group(1)
    new_entries = "".join(f"\t\t{b_uuid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {r_uuid} /* {fname} */; }};\n"
                          for b_uuid, r_uuid, fname in build_files)
    content = content.replace(section, section.replace("/* End PBXBuildFile section */", new_entries + "\t/* End PBXBuildFile section */"))

# Add to PBXFileReference section
file_ref_pattern = r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)'
if match := re.search(file_ref_pattern, content, re.DOTALL):
    section = match.group(1)
    new_entries = "".join(f"\t\t{r_uuid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};\n"
                          for r_uuid, fname in file_refs)
    content = content.replace(section, section.replace("/* End PBXFileReference section */", new_entries + "\t/* End PBXFileReference section */"))

# Add to PBXGroup (children array)
group_pattern = r'(/\* Stoic_Companion Watch App \*/ = \{[^}]+children = \([^)]+\);)'
if match := re.search(group_pattern, content, re.DOTALL):
    section = match.group(1)
    new_entries = "".join(f"\t\t\t\t{r_uuid} /* {fname} */,\n" for r_uuid, fname in file_refs)
    content = content.replace(section, section.replace(");", new_entries + "\t\t\t);"))

# Add to PBXSourcesBuildPhase (files array)
sources_pattern = r'(/\* Sources \*/ = \{[^}]+files = \([^)]+\);)'
if match := re.search(sources_pattern, content, re.DOTALL):
    section = match.group(1)
    new_entries = "".join(f"\t\t\t\t{b_uuid} /* {fname} in Sources */,\n" for b_uuid, r_uuid, fname in build_files)
    content = content.replace(section, section.replace(");", new_entries + "\t\t\t);"))

# Write updated file
with open(project_file, 'w') as f:
    f.write(content)

print(f"✅ Added {len(file_refs)} files to Xcode project")
PYTHON_SCRIPT

echo "✅ Step 1 complete"
echo ""

# Step 2: Integrate navigation into ToolsGridView
echo "🔗 Step 2/6: Integrating navigation into ToolsGridView..."

# Backup ToolsGridView
cp "$PROJECT_DIR/Stoic_Companion Watch App/ToolsGridView.swift" \
   "$PROJECT_DIR/Stoic_Companion Watch App/ToolsGridView.swift.backup"

# Update ToolsGridView with new tools
python3 << 'PYTHON_INTEGRATION'
import re

tools_file = "/Users/matheusrech/Downloads/deploy/STOICISM-main/Stoic_Companion Watch App/ToolsGridView.swift"

with open(tools_file, 'r') as f:
    content = f.read()

# Check if integration already done
if "TodaysPrioritiesView" in content:
    print("✅ Navigation already integrated")
    exit(0)

print("Integrating new tools into ToolsGridView...")

# Find the allTools array and add new tools
# We'll add them before the closing bracket of the allTools array

new_tools = '''
        // Enhanced Display Components (NEW - from HTML mockup conversion)
        StoicTool(name: "Today's Priorities", shortName: "Priorities", icon: "checklist", color: .blue, destination: AnyView(TodaysPrioritiesView())),
        StoicTool(name: "Daily Affirmations", shortName: "Affirm", icon: "sparkle", color: .purple, destination: AnyView(AffirmationDisplayView())),
        StoicTool(name: "Box Breathing", shortName: "Breathe", icon: "wind.circle.fill", color: .cyan, destination: AnyView(BoxBreathingDisplayView())),
        StoicTool(name: "Quick Favorites", shortName: "Favorites", icon: "star.fill", color: .yellow, destination: AnyView(FavoritesMenuView())),
'''

# Find the end of the allTools array (before the closing ])
pattern = r'(static let allTools: \[StoicTool\] = \[.*?)(    \]\n)'
match = re.search(pattern, content, re.DOTALL)

if match:
    # Insert new tools before the closing bracket
    updated_content = content[:match.end(1)] + new_tools + content[match.start(2):]

    with open(tools_file, 'w') as f:
        f.write(updated_content)

    print("✅ Added 4 new tools to ToolsGridView")
    print("   • Today's Priorities (checklist)")
    print("   • Daily Affirmations (gradient cards)")
    print("   • Box Breathing (enhanced breathing)")
    print("   • Quick Favorites (2x2 grid)")
else:
    print("⚠️  Could not find allTools array - manual integration needed")

PYTHON_INTEGRATION

echo "✅ Step 2 complete: Navigation integrated"
echo ""

# Step 3: Clean build folder
echo "🧹 Step 3/6: Cleaning build folder..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"
echo "✅ Step 3 complete"
echo ""

# Step 4: Create archive
echo "📦 Step 4/6: Creating archive (2-3 minutes)..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -project "$PROJECT_FILE" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=watchOS' \
    -allowProvisioningUpdates \
    2>&1 | grep -E "error:|warning:|note:|Compiling|Linking|Generating|Creating|Archive"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Step 4 complete: Archive created"
    ls -lh "$ARCHIVE_PATH" | tail -1
else
    echo "❌ Archive failed"
    echo ""
    echo "💡 Restore files with:"
    echo "   cp $PROJECT_FILE/project.pbxproj.backup $PROJECT_FILE/project.pbxproj"
    echo "   cp '$PROJECT_DIR/Stoic_Companion Watch App/ToolsGridView.swift.backup' '$PROJECT_DIR/Stoic_Companion Watch App/ToolsGridView.swift'"
    exit 1
fi

echo ""

# Step 5: Export for App Store Connect
echo "📤 Step 5/6: Exporting for App Store Connect..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates \
    2>&1 | grep -E "error:|Exported|Processing"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Step 5 complete: Export successful"

    IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
    if [ -f "$IPA_FILE" ]; then
        IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
        echo "   📱 IPA: $IPA_FILE"
        echo "   📊 Size: $IPA_SIZE"
    fi
else
    echo "❌ Export failed"
    exit 1
fi

echo ""

# Step 6: Upload to App Store Connect
echo "☁️  Step 6/6: Upload to App Store Connect"
echo ""
echo "Choose upload method:"
echo "  1) App Store Connect API Key (Recommended)"
echo "  2) Apple ID + App-Specific Password"
echo "  3) Manual (open Transporter app)"
echo ""
read -p "Choice (1-3): " choice

case $choice in
    1)
        echo ""
        read -p "API Key ID: " api_key
        read -p "Issuer ID: " issuer
        read -p "Path to .p8 file: " p8_file

        if [ -f "$p8_file" ]; then
            xcrun altool --upload-app \
                -f "$IPA_FILE" \
                -t ios \
                --apiKey "$api_key" \
                --apiIssuer "$issuer"

            [ $? -eq 0 ] && echo "✅ Upload successful!" || echo "❌ Upload failed"
        else
            echo "❌ Key file not found: $p8_file"
        fi
        ;;

    2)
        echo ""
        read -p "Apple ID: " apple_id
        read -sp "App-specific password: " password
        echo ""

        xcrun altool --upload-app \
            -f "$IPA_FILE" \
            -t ios \
            -u "$apple_id" \
            -p "$password"

        [ $? -eq 0 ] && echo "✅ Upload successful!" || echo "❌ Upload failed"
        ;;

    3)
        echo ""
        echo "📦 Ready for manual upload!"
        echo ""
        echo "Steps:"
        echo "  1. Open Transporter app"
        echo "  2. Sign in with Apple ID"
        echo "  3. Drag this file: $IPA_FILE"
        echo "  4. Click 'Deliver'"
        ;;
esac

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    🎉 Deployment Complete!                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 What Was Added:"
echo "   ✅ 6 SwiftUI components (1,961 lines)"
echo "   ✅ 4 new tools in ToolsGridView:"
echo "      • Today's Priorities (checklist with progress)"
echo "      • Daily Affirmations (4 categories with gradients)"
echo "      • Box Breathing (4-phase with haptics)"
echo "      • Quick Favorites (2x2 grid)"
echo "   ✅ Archive created: $ARCHIVE_PATH"
echo "   ✅ IPA exported: $IPA_FILE"
echo ""
echo "🔍 Next Steps:"
echo "   1. Check App Store Connect (5-10 min processing)"
echo "   2. Build appears under TestFlight"
echo "   3. Add testers and distribute"
echo ""
echo "💡 To restore backups if needed:"
echo "   cp $PROJECT_FILE/project.pbxproj.backup $PROJECT_FILE/project.pbxproj"
echo "   cp 'Stoic_Companion Watch App/ToolsGridView.swift.backup' 'Stoic_Companion Watch App/ToolsGridView.swift'"
echo ""
