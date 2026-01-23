#!/usr/bin/env python3
"""
Remove new SwiftUI files from legacy iOS target Sources build phase (v2)
"""
import re

PROJECT_FILE = "Stoic_Companion.xcodeproj/project.pbxproj"

# Match ANY line that references these view names in the legacy target
VIEW_NAMES = [
    "TodaysPrioritiesView",
    "AffirmationDisplayView",
    "BoxBreathingDisplayView",
    "FavoritesMenuView",
    "QuoteDisplayCardView",
    "MementoMoriDisplayView",
]

print("🔧 Removing new SwiftUI views from legacy iOS target...")

# Read project file
with open(PROJECT_FILE, 'r') as f:
    content = f.read()

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

# Remove ALL lines containing ANY of the view names
for view_name in VIEW_NAMES:
    # Match lines like: \t\t\t\t<UUID> /* ViewName.swift in Sources */,
    pattern = rf'\s+[A-F0-9]{{24}} /\* {view_name}\.swift in Sources \*/,\n'
    matches = re.findall(pattern, legacy_section)
    removed_count += len(matches)
    legacy_section = re.sub(pattern, '', legacy_section)
    if matches:
        print(f"   Removed {len(matches)}x {view_name}")

# Replace in content
content = content.replace(original_legacy, legacy_section)

# Write updated file
with open(PROJECT_FILE, 'w') as f:
    f.write(content)

print(f"\n✅ Removed {removed_count} total entries from legacy iOS target")
print("   Files are now ONLY in Watch App target")
