#!/usr/bin/env python3
"""
Fix target membership: Remove watchOS files from legacy iOS target
"""
import re

PROJECT_FILE = "Stoic_Companion.xcodeproj/project.pbxproj"

# UUIDs of the new SwiftUI files that should NOT be in legacy target
FILES_TO_REMOVE = [
    "C285B914D1A14A2E8A8FB16F",  # MementoMoriDisplayView.swift
    "D9FCF92013AA4F43BA8B7098",  # TodaysPrioritiesView.swift
    "ACB525ED88BF4693B1F93FDC",  # QuoteDisplayCardView.swift
    "5A62B714A50D419EBFDABE47",  # FavoritesMenuView.swift
    "B3F748C095FD464EB0057FF5",  # AffirmationDisplayView.swift
    "633F0AB9DAC7491995980C33",  # BoxBreathingDisplayView.swift
]

print("🔧 Fixing target membership...")
print(f"   Removing {len(FILES_TO_REMOVE)} files from legacy iOS target")

# Read project file
with open(PROJECT_FILE, 'r') as f:
    content = f.read()

# Backup
with open(PROJECT_FILE + ".before_fix", 'w') as f:
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

# Remove lines containing the file UUIDs
for file_uuid in FILES_TO_REMOVE:
    # Match lines like: \t\t\t\tUUID /* filename in Sources */,
    pattern = rf'\s+{file_uuid} /\* .+ in Sources \*/,\n'
    legacy_section = re.sub(pattern, '', legacy_section)

# Replace in content
content = content.replace(original_legacy, legacy_section)

# Write updated file
with open(PROJECT_FILE, 'w') as f:
    f.write(content)

print("✅ Fixed target membership")
print("   Files removed from legacy iOS target:")
for uuid in FILES_TO_REMOVE:
    print(f"      • {uuid}")
print("")
print("💡 Backup saved to: project.pbxproj.before_fix")
