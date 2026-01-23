#!/usr/bin/env python3
"""
Remove new SwiftUI files from legacy iOS target Sources build phase
"""
import re

PROJECT_FILE = "Stoic_Companion.xcodeproj/project.pbxproj"

# All UUIDs for the new files that should NOT be in legacy target
FILES_TO_REMOVE = [
    # Original UUIDs from first script
    "C285B914D1A14A2E8A8FB16F",  # MementoMoriDisplayView
    "D9FCF92013AA4F43BA8B7098",  # TodaysPrioritiesView
    "ACB525ED88BF4693B1F93FDC",  # QuoteDisplayCardView
    "5A62B714A50D419EBFDABE47",  # FavoritesMenuView
    "B3F748C095FD464EB0057FF5",  # AffirmationDisplayView
    "633F0AB9DAC7491995980C33",  # BoxBreathingDisplayView
    # Additional UUIDs found in legacy target
    "FFF9C9A3",  # TodaysPrioritiesView (duplicate)
    "FFF9C9A5",  # FavoritesMenuView (duplicate)
    "FFF9C9A6",  # AffirmationDisplayView (duplicate)
    "FFF9C9A7",  # BoxBreathingDisplayView (duplicate)
    "FFF9C9A9",  # TodaysPrioritiesView (duplicate)
    "FFF9C9AB",  # FavoritesMenuView (duplicate)
    "FFF9C9AC",  # AffirmationDisplayView (duplicate)
    "FFF9C9AD",  # BoxBreathingDisplayView (duplicate)
    "FFF9C9AF",  # TodaysPrioritiesView (duplicate)
    "FFF9C9B1",  # FavoritesMenuView (duplicate)
    "FFF9C9B2",  # AffirmationDisplayView (duplicate)
    "FFF9C9B3",  # BoxBreathingDisplayView (duplicate)
]

print("🔧 Removing duplicates from legacy iOS target...")

# Read project file
with open(PROJECT_FILE, 'r') as f:
    content = f.read()

# Backup
with open(PROJECT_FILE + ".backup_clean", 'w') as f:
    f.write(content)

# Find the legacy Stoic_Companion Sources build phase
# FF8525452F186FDB008BD212 /* Sources */
legacy_sources_pattern = r'(FF8525452F186FDB008BD212 /\* Sources \*/ = \{[^}]+files = \([^)]+\);)'

match = re.search(legacy_sources_pattern, content, re.DOTALL)
if not match:
    print("❌ Could not find legacy Sources build phase")
    exit(1)

legacy_section = match.group(1)
original_legacy = legacy_section
removed_count = 0

# Remove ALL lines containing ANY of the file UUIDs
for file_uuid in FILES_TO_REMOVE:
    # Match lines like: \t\t\t\tUUID... /* filename in Sources */,
    pattern = rf'\s+{file_uuid}[A-F0-9]* /\* .+ in Sources \*/,\n'
    matches = re.findall(pattern, legacy_section)
    removed_count += len(matches)
    legacy_section = re.sub(pattern, '', legacy_section)

# Replace in content
content = content.replace(original_legacy, legacy_section)

# Write updated file
with open(PROJECT_FILE, 'w') as f:
    f.write(content)

print(f"✅ Removed {removed_count} duplicate entries from legacy iOS target")
print("")
print("💡 Backup saved to: project.pbxproj.backup_clean")
