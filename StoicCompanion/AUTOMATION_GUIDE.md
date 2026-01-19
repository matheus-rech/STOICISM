# 🤖 Automation Scripts Guide

Your Stoic Companion now includes **automated setup scripts** to make testing super easy for your friends!

## 📦 Available Scripts

### 1. **setup.sh** - Interactive Setup Assistant
🎯 **Purpose**: Helps your friends set up the app with guided instructions

**What it does**:
- ✅ Checks system requirements (macOS, Xcode)
- ✅ Validates all required files are present
- ✅ Creates backup of existing project
- ✅ Opens Xcode with step-by-step instructions
- ✅ Shows file locations in Finder
- ✅ Optionally builds from command line

**How to use**:
```bash
# Method 1: Double-click in Finder
Double-click: setup.sh

# Method 2: Terminal
cd /path/to/StoicCompanion
./setup.sh
```

**Interactive Options**:
1. Open Xcode + show manual instructions (Recommended)
2. Just open Xcode project
3. Show file locations and exit
4. Build from command line (Advanced)

---

### 2. **create_distribution.sh** - Package for Friends
🎯 **Purpose**: Creates a ready-to-share ZIP file for your testers

**What it does**:
- ✅ Bundles all project files
- ✅ Includes all Swift source code
- ✅ Copies documentation
- ✅ Includes setup scripts
- ✅ Creates START_HERE.txt guide
- ✅ Saves ZIP to Desktop

**How to use**:
```bash
# Run from project directory
./create_distribution.sh
```

**Output**:
- 📦 `~/Desktop/StoicCompanion_TestBuild_YYYYMMDD.zip`
- Ready to email or AirDrop to friends!

---

### 3. **verify_setup.sh** - Verification Tool
🎯 **Purpose**: Checks if everything is configured correctly

**What it does**:
- ✅ Verifies system requirements
- ✅ Checks all files are present
- ✅ Validates API key configuration
- ✅ Tests Xcode project readability
- ✅ Provides detailed report

**How to use**:
```bash
# Run verification
./verify_setup.sh
```

**Sample Output**:
```
🔧 System Requirements
macOS detected ... ✅ PASS
Xcode installed ... ✅ PASS

📄 Required New Files
LLMService.swift present ... ✅ PASS
OpenAIService.swift present ... ✅ PASS
...

📊 VERIFICATION SUMMARY
✅ Passed:  20
⚠️  Warnings: 2
❌ Failed:  0

🎉 Perfect! Everything is set up correctly!
```

---

## 🚀 Quick Start for You (Developer)

### Creating a Distribution Package

1. **Run the distribution script**:
   ```bash
   cd /path/to/StoicCompanion
   ./create_distribution.sh
   ```

2. **Find the ZIP on your Desktop**:
   - `StoicCompanion_TestBuild_YYYYMMDD.zip`

3. **Share with friends**:
   - Email, AirDrop, or cloud storage
   - No sensitive data exposed (API key is in Config.swift which is in .gitignore)

### Verification Before Sharing

```bash
# Make sure everything is ready
./verify_setup.sh

# Should show all green checkmarks
```

---

## 🎯 Quick Start for Testers (Your Friends)

### Option 1: Automated Setup (Recommended)

1. **Extract the ZIP** you received
2. **Double-click** `setup.sh`
3. **Follow the instructions** in Terminal
4. **Add files in Xcode** as shown
5. **Build and run** (⌘R)

### Option 2: Manual Setup

1. Open `README_FOR_TESTERS.md`
2. Follow step-by-step instructions
3. Use `verify_setup.sh` to check setup

---

## 🛠️ Script Details

### Setup Script Flow

```
┌─────────────────────────────────────┐
│  Run setup.sh                       │
└───────────┬─────────────────────────┘
            │
            ├─► Check macOS ✓
            ├─► Check Xcode ✓
            ├─► Find project files ✓
            ├─► Verify new files ✓
            ├─► Create backup ✓
            │
            ├─► Choose option:
            │   1. Open Xcode + Instructions
            │   2. Just open Xcode
            │   3. Show files
            │   4. Build from CLI
            │
            └─► Done! 🎉
```

### Distribution Script Flow

```
┌─────────────────────────────────────┐
│  Run create_distribution.sh         │
└───────────┬─────────────────────────┘
            │
            ├─► Create temp directory
            ├─► Copy Xcode project
            ├─► Copy Swift files
            ├─► Copy documentation
            ├─► Copy scripts
            ├─► Create START_HERE.txt
            ├─► Create ZIP archive
            ├─► Save to Desktop
            │
            └─► Open Desktop folder 🎉
```

### Verification Script Flow

```
┌─────────────────────────────────────┐
│  Run verify_setup.sh                │
└───────────┬─────────────────────────┘
            │
            ├─► Check system ✓
            ├─► Check project ✓
            ├─► Check files ✓
            ├─► Check API config ✓
            ├─► Check documentation ✓
            │
            ├─► Generate report:
            │   • Passed: X
            │   • Warnings: Y
            │   • Failed: Z
            │
            └─► Show verdict 🎉
```

---

## 🔧 Customization

### Modify Setup Instructions

Edit `setup.sh` around line 150:
```bash
echo "1️⃣  In the left sidebar (Project Navigator):"
echo "   • Find the 'Stoic_Companion Watch App' folder"
# ... add your custom instructions
```

### Change Distribution Contents

Edit `create_distribution.sh` around line 50:
```bash
SWIFT_FILES=(
    "LLMService.swift"
    # ... add more files
)
```

### Add Custom Checks

Edit `verify_setup.sh`:
```bash
check_item "My custom check" "[ -f \"my_file.txt\" ]"
```

---

## 🐛 Troubleshooting

### "Permission denied" Error

**Solution**:
```bash
chmod +x setup.sh
chmod +x create_distribution.sh
chmod +x verify_setup.sh
```

### Scripts Won't Run from Finder

**Solution**:
Right-click → Open With → Terminal
Or use Terminal: `./setup.sh`

### "Command not found" Error

**Solution**:
Make sure you're in the correct directory:
```bash
cd /path/to/StoicCompanion
pwd  # Should show StoicCompanion directory
```

### Xcode Not Opening

**Solution**:
1. Check Xcode is installed
2. Try opening manually: `open Stoic_Companion.xcodeproj`
3. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

---

## 📋 Checklist for Distribution

Before sharing with friends:

- [ ] Run `./verify_setup.sh` - all checks pass
- [ ] Run `./create_distribution.sh` - ZIP created
- [ ] Test ZIP on different Mac (optional but recommended)
- [ ] Include these files in distribution:
  - [ ] setup.sh
  - [ ] verify_setup.sh
  - [ ] README_FOR_TESTERS.md
  - [ ] SETUP_CHECKLIST.md
  - [ ] All Swift files
  - [ ] Xcode project

---

## 💡 Pro Tips

### For You (Developer)

1. **Test scripts before sharing**:
   ```bash
   ./verify_setup.sh  # Should be all green
   ```

2. **Keep backups**:
   - Scripts automatically create backups
   - Check `backup_YYYYMMDD_HHMMSS/` folders

3. **Monitor API usage**:
   - https://platform.openai.com/usage
   - Set spending limits for safety

### For Your Friends (Testers)

1. **Always run setup.sh first**:
   - It checks everything before you start
   - Saves time debugging later

2. **Read START_HERE.txt**:
   - Quick overview in plain text
   - No need to open multiple files

3. **Use verify_setup.sh if stuck**:
   - Shows exactly what's missing
   - Easy to fix issues

---

## 🎓 Script Anatomy

### Why Bash Scripts?

- ✅ Native to macOS - no installation needed
- ✅ Can automate Xcode operations
- ✅ Easy for non-technical users (double-click)
- ✅ Provides colored output and progress
- ✅ Can create backups and verify setup

### Key Features

**Color-coded output**:
- 🟢 Green = Success
- 🟡 Yellow = Warning
- 🔴 Red = Error
- 🔵 Blue = Info

**Error handling**:
- `set -e` - Exit on error
- Validation checks before operations
- User-friendly error messages

**User experience**:
- Progress indicators
- Clear instructions
- Interactive choices
- File location helpers

---

## 📚 Additional Resources

**For detailed setup**:
- `README_FOR_TESTERS.md` - Friend testing guide
- `SETUP_CHECKLIST.md` - Step-by-step setup
- `MULTI_PROVIDER_GUIDE.md` - AI provider info

**For security**:
- `SECURITY_NOTE.md` - Cost and security info
- `.gitignore` - Protects API keys

**For development**:
- `ARCHITECTURE.md` - Technical details
- `README.md` - Full documentation

---

## ✨ Summary

You now have **three powerful scripts**:

1. **setup.sh** → Helps friends set up
2. **create_distribution.sh** → Packages for sharing
3. **verify_setup.sh** → Checks everything works

**Workflow**:
```
You: ./create_distribution.sh → Share ZIP
Friend: Extract → ./setup.sh → Build → Test
Friend: (if issues) ./verify_setup.sh → Fix → Success!
```

**That's it! Automation makes testing easy for everyone.** 🚀

---

🏛️ **"The impediment to action advances action. What stands in the way becomes the way."** — Marcus Aurelius
