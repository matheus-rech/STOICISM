import re

# Read project file
with open("Stoic_Companion.xcodeproj/project.pbxproj", 'r') as f:
    content = f.read()

# All the specific UUIDs to remove from legacy target
uuids_to_remove = [
    "FFF9C9A22F230CA20055D4F5",  # MementoMoriDisplayView
    "FFF9C9A32F230CA20055D4F5",  # TodaysPrioritiesView
    "FFF9C9A42F230CA20055D4F5",  # QuoteDisplayCardView
    "FFF9C9A52F230CA20055D4F5",  # FavoritesMenuView
    "FFF9C9A62F230CA20055D4F5",  # AffirmationDisplayView
    "FFF9C9A72F230CA20055D4F5",  # BoxBreathingDisplayView
    "FFF9C9A82F230CA20055D4F5",  # MementoMoriDisplayView (dup)
    "FFF9C9A92F230CA20055D4F5",  # TodaysPrioritiesView (dup)
    "FFF9C9AA2F230CA20055D4F5",  # QuoteDisplayCardView (dup)
    "FFF9C9AB2F230CA20055D4F5",  # FavoritesMenuView (dup)
    "FFF9C9AC2F230CA20055D4F5",  # AffirmationDisplayView (dup)
    "FFF9C9AD2F230CA20055D4F5",  # BoxBreathingDisplayView (dup)
    "FFF9C9AE2F230CA20055D4F5",  # MementoMoriDisplayView (dup)
    "FFF9C9AF2F230CA20055D4F5",  # TodaysPrioritiesView (dup)
    "FFF9C9B02F230CA20055D4F5",  # QuoteDisplayCardView (dup)
    "FFF9C9B12F230CA20055D4F5",  # FavoritesMenuView (dup)
    "FFF9C9B22F230CA20055D4F5",  # AffirmationDisplayView (dup)
    "FFF9C9B32F230CA20055D4F5",  # BoxBreathingDisplayView (dup)
]

# Find and clean the legacy Sources section
pattern = r'(FF8525452F186FDB008BD212 /\* Sources \*/ = \{.*?files = \()(.*?)(\);)'
match = re.search(pattern, content, re.DOTALL)

if match:
    prefix, files_section, suffix = match.groups()
    original_section = files_section
    
    # Remove each UUID
    removed = 0
    for uuid in uuids_to_remove:
        # Match the full line with this UUID
        line_pattern = rf'[^\n]*{uuid}[^\n]*\n'
        if re.search(line_pattern, files_section):
            files_section = re.sub(line_pattern, '', files_section)
            removed += 1
    
    # Reconstruct the section
    new_section = prefix + files_section + suffix
    content = content.replace(match.group(0), new_section)
    
    # Write back
    with open("Stoic_Companion.xcodeproj/project.pbxproj", 'w') as f:
        f.write(content)
    
    print(f"✅ Removed {removed} entries from legacy iOS target")
else:
    print("❌ Could not find legacy Sources section")
