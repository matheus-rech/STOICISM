# Quick TestFlight Archive Steps

## ⚠️ Current Issue
Command-line archive failed because the legacy "Stoic_Companion" target needs provisioning.

## ✅ Best Solution: Use Xcode GUI

### 3-Step Process:

**1. Open in Xcode**
```bash
open Stoic_Companion.xcodeproj
```

**2. Select Device**
- Top-left dropdown → Select **"Any watchOS Device (arm64)"**

**3. Archive**
- Menu: **Product → Archive**
- Wait for completion
- Click **"Distribute App"**
- Choose **"App Store Connect"** → **Upload**

That's it! Xcode handles all provisioning automatically.

## Alternative: Quick Fix for Command-Line

If you want to fix command-line archiving:

**Fix the scheme** (in Xcode):
1. Product → Scheme → Edit Scheme
2. Select "Stoic_Companion Watch App"
3. Archive (left sidebar)
4. Uncheck "Stoic_Companion" target
5. Keep only "Stoic_Companion Watch App" checked
6. Save

Then retry:
```bash
xcodebuild archive \
  -scheme "Stoic_Companion Watch App" \
  -archivePath "./build/StoicCompanion.xcarchive" \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates
```

## What You Need

✅ Apple Developer Program ($99/year)
✅ App ID created (Bundle: com.stoic.companion.watchkitapp)
✅ Team ID: Z2U6JRPZ53 (already configured)

**See TESTFLIGHT_DISTRIBUTION_GUIDE.md for complete details.**
