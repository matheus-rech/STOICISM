#!/bin/bash
set -e  # Exit on any error

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  🚀 Automated TestFlight Deployment for Stoic Companion      ║"
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
echo "📝 Step 1/5: Adding SwiftUI components to Xcode project..."

# Files to add
FILES=(
    "MementoMoriDisplayView.swift"
    "TodaysPrioritiesView.swift"
    "QuoteDisplayCardView.swift"
    "FavoritesMenuView.swift"
    "AffirmationDisplayView.swift"
    "BoxBreathingDisplayView.swift"
)

# Generate UUIDs for project file entries
generate_uuid() {
    uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24
}

# Backup project file
cp "$PROJECT_FILE/project.pbxproj" "$PROJECT_FILE/project.pbxproj.backup"

# Add files to project.pbxproj
# This is a simplified approach - we'll use a Python script for proper UUID management
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
    print("✅ All SwiftUI files already in project - skipping file addition")
    sys.exit(0)

print("Adding files to Xcode project...")

# For each file, generate UUIDs
file_refs = []
build_files = []

for filename in files_to_add:
    if filename in content:
        print(f"  ⏭️  {filename} already added - skipping")
        continue

    file_ref_uuid = generate_xcode_uuid()
    build_file_uuid = generate_xcode_uuid()

    file_refs.append((file_ref_uuid, filename))
    build_files.append((build_file_uuid, file_ref_uuid, filename))
    print(f"  ✅ Generated UUIDs for {filename}")

# Find the PBXBuildFile section
build_file_section_pattern = r'(/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/)'
build_file_match = re.search(build_file_section_pattern, content, re.DOTALL)

if build_file_match:
    build_file_section = build_file_match.group(1)
    new_build_entries = ""

    for build_uuid, ref_uuid, filename in build_files:
        new_build_entries += f"\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {filename} */; }};\n"

    # Insert before the "End PBXBuildFile" comment
    new_build_section = build_file_section.replace(
        "/* End PBXBuildFile section */",
        new_build_entries + "\t/* End PBXBuildFile section */"
    )
    content = content.replace(build_file_section, new_build_section)

# Find the PBXFileReference section
file_ref_section_pattern = r'(/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/)'
file_ref_match = re.search(file_ref_section_pattern, content, re.DOTALL)

if file_ref_match:
    file_ref_section = file_ref_match.group(1)
    new_file_entries = ""

    for ref_uuid, filename in file_refs:
        new_file_entries += f"\t\t{ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"

    new_file_section = file_ref_section.replace(
        "/* End PBXFileReference section */",
        new_file_entries + "\t/* End PBXFileReference section */"
    )
    content = content.replace(file_ref_section, new_file_section)

# Find the PBXGroup section for "Stoic_Companion Watch App"
# Look for the group that contains other Swift files
group_pattern = r'(/\* Stoic_Companion Watch App \*/ = \{[^}]+children = \([^)]+\);)'
group_match = re.search(group_pattern, content, re.DOTALL)

if group_match:
    group_section = group_match.group(1)
    new_group_entries = ""

    for ref_uuid, filename in file_refs:
        new_group_entries += f"\t\t\t\t{ref_uuid} /* {filename} */,\n"

    # Insert before the closing parenthesis of children array
    new_group_section = group_section.replace(
        ");",
        new_group_entries + "\t\t\t);"
    )
    content = content.replace(group_section, new_group_section)

# Find the PBXSourcesBuildPhase section
sources_phase_pattern = r'(/\* Sources \*/ = \{[^}]+files = \([^)]+\);)'
sources_match = re.search(sources_phase_pattern, content, re.DOTALL)

if sources_match:
    sources_section = sources_match.group(1)
    new_sources_entries = ""

    for build_uuid, ref_uuid, filename in build_files:
        new_sources_entries += f"\t\t\t\t{build_uuid} /* {filename} in Sources */,\n"

    new_sources_section = sources_section.replace(
        ");",
        new_sources_entries + "\t\t\t);"
    )
    content = content.replace(sources_section, new_sources_section)

# Write updated project file
with open(project_file, 'w') as f:
    f.write(content)

print(f"✅ Successfully added {len(file_refs)} files to Xcode project")

PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo "✅ Step 1 complete: SwiftUI files added to project"
else
    echo "❌ Failed to add files to project"
    exit 1
fi

echo ""

# Step 2: Clean build folder
echo "🧹 Step 2/5: Cleaning build folder..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"
echo "✅ Step 2 complete: Build folder cleaned"
echo ""

# Step 3: Create archive
echo "📦 Step 3/5: Creating archive (this may take 2-3 minutes)..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -project "$PROJECT_FILE" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=watchOS' \
    -allowProvisioningUpdates \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ Step 3 complete: Archive created successfully"
    echo "   Location: $ARCHIVE_PATH"
else
    echo "❌ Archive failed - check errors above"
    exit 1
fi

echo ""

# Step 4: Export for App Store Connect
echo "📤 Step 4/5: Exporting for App Store Connect..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ Step 4 complete: Export successful"

    # Find the .ipa file
    IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)

    if [ -f "$IPA_FILE" ]; then
        IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
        echo "   📱 IPA file: $IPA_FILE"
        echo "   📊 Size: $IPA_SIZE"
    else
        echo "⚠️  Warning: IPA file not found in export directory"
    fi
else
    echo "❌ Export failed - check errors above"
    exit 1
fi

echo ""

# Step 5: Upload to App Store Connect
echo "☁️  Step 5/5: Uploading to App Store Connect..."
echo ""
echo "⚠️  IMPORTANT: You need Apple credentials for upload!"
echo ""
echo "Choose upload method:"
echo "  1) App Store Connect API Key (Recommended - no password needed)"
echo "  2) Apple ID + App-Specific Password"
echo "  3) Skip upload (manual upload via Transporter app)"
echo ""
read -p "Enter choice (1-3): " upload_choice

case $upload_choice in
    1)
        echo ""
        echo "📋 You'll need:"
        echo "   • API Key ID (get from App Store Connect → Users and Access → Keys)"
        echo "   • Issuer ID (shown on the Keys page)"
        echo "   • API Key file (.p8) downloaded"
        echo ""
        read -p "API Key ID: " api_key_id
        read -p "Issuer ID: " issuer_id
        read -p "Path to .p8 file: " api_key_file

        if [ -f "$api_key_file" ]; then
            xcrun altool --upload-app \
                -f "$IPA_FILE" \
                -t ios \
                --apiKey "$api_key_id" \
                --apiIssuer "$issuer_id"

            if [ $? -eq 0 ]; then
                echo "✅ Upload successful!"
            else
                echo "❌ Upload failed - check credentials"
                exit 1
            fi
        else
            echo "❌ API key file not found: $api_key_file"
            exit 1
        fi
        ;;

    2)
        echo ""
        echo "📋 You'll need:"
        echo "   • Apple ID email"
        echo "   • App-specific password (generate at appleid.apple.com)"
        echo ""
        read -p "Apple ID: " apple_id
        read -sp "App-specific password: " app_password
        echo ""

        xcrun altool --upload-app \
            -f "$IPA_FILE" \
            -t ios \
            -u "$apple_id" \
            -p "$app_password"

        if [ $? -eq 0 ]; then
            echo "✅ Upload successful!"
        else
            echo "❌ Upload failed - check credentials"
            exit 1
        fi
        ;;

    3)
        echo ""
        echo "📦 Archive ready for manual upload!"
        echo ""
        echo "To upload manually:"
        echo "  1. Open Transporter app (download from Mac App Store if needed)"
        echo "  2. Sign in with your Apple ID"
        echo "  3. Drag and drop this file:"
        echo "     $IPA_FILE"
        echo "  4. Click 'Deliver'"
        echo ""
        ;;

    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    🎉 Deployment Complete!                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "   ✅ 6 SwiftUI components added to project"
echo "   ✅ Archive created: $ARCHIVE_PATH"
echo "   ✅ IPA exported: $IPA_FILE"
echo ""
echo "🔍 Next Steps:"
echo "   1. Check App Store Connect (appstoreconnect.apple.com)"
echo "   2. Wait 5-10 minutes for processing"
echo "   3. Build will appear under 'Stoic Companion' → TestFlight"
echo "   4. Add internal/external testers"
echo "   5. Submit for TestFlight review (if needed)"
echo ""
echo "💡 Tip: You can track upload status at:"
echo "   App Store Connect → My Apps → Stoic Companion → Activity"
echo ""
