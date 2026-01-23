# TestFlight Distribution Guide for Stoic Camarade

## Current Issue

The command-line archive failed due to provisioning profile requirements. The **legacy "Stoic_Camarade" target** (which we archived earlier) is causing conflicts.

**Error Summary:**
```
- Legacy target needs provisioning profile for "Test.Stoic-Companion" ❌
- Watch App target needs provisioning profile for "com.stoic.camarade.watchkitapp" ✅
- Your team has no registered devices for automatic provisioning
```

## ✅ Solution: Use Xcode Archive (Recommended)

Xcode's GUI handles provisioning automatically and is the most reliable way to create TestFlight archives.

### Step-by-Step Instructions

#### 1. Prepare Your Apple Developer Account

Before archiving, ensure you have:

- ✅ Active Apple Developer Program membership ($99/year)
- ✅ App ID created in https://developer.apple.com/account/
  - Bundle ID: `com.stoic.camarade.watchkitapp`
  - Capabilities: HealthKit enabled
- ✅ At least one Apple Watch registered (for testing)

#### 2. Open Project in Xcode

```bash
cd /Users/matheusrech/Desktop/STOICISM-main
open Stoic_Camarade.xcodeproj
```

#### 3. Configure Signing (One-time Setup)

1. Select **Stoic_Camarade.xcodeproj** in Project Navigator
2. Select **"Stoic_Camarade Watch App" target**
3. Go to **"Signing & Capabilities"** tab
4. Ensure settings:
   - ✅ **Automatically manage signing** is CHECKED
   - ✅ **Team:** Your team (Z2U6JRPZ53)
   - ✅ **Bundle Identifier:** com.stoic.camarade.watchkitapp

5. **IMPORTANT:** Also check the legacy "Stoic_Camarade" target:
   - Either set a valid bundle ID or disable it for archiving
   - Or set it to "Automatically manage signing" with your team

#### 4. Select Generic watchOS Device

In Xcode toolbar (top left):
- Click the device/destination dropdown
- Select: **"Any watchOS Device (arm64)"**
- Do NOT use a simulator

#### 5. Create Archive

1. Menu: **Product → Archive**
2. Xcode will:
   - Build the app in Release configuration
   - Sign with Distribution certificate (automatic)
   - Create an .xcarchive file
3. Wait for "Archive succeeded" notification

#### 6. Distribute to App Store Connect

When the Organizer window opens:

1. Your archive appears in the list
2. Click **"Distribute App"** button
3. Choose **"App Store Connect"** → **Next**
4. Choose **"Upload"** → **Next**
5. **Distribution options:**
   - ✅ Upload symbols (for crash reports)
   - ✅ Manage version and build number
6. Click **"Automatically manage signing"** → **Next**
7. Review summary → **Upload**

Xcode will upload to App Store Connect.

#### 7. Configure TestFlight in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Navigate to your app
3. Go to **TestFlight** tab
4. Your build will appear (processing takes 10-30 minutes)
5. Once processed:
   - Add test information (What to Test)
   - Add internal testers (your email)
   - Submit for Beta App Review (for external testers)

## Alternative: Fix Command-Line Archive

If you prefer command-line archiving:

### Option A: Disable Legacy Target in Scheme

1. Open Xcode
2. **Product → Scheme → Edit Scheme**
3. Select **"Stoic_Camarade Watch App"** scheme
4. Go to **Archive** (left sidebar)
5. Under **"Archive"**, uncheck **"Stoic_Camarade"** target
6. Keep only **"Stoic_Camarade Watch App"** checked
7. Save and try archiving again

### Option B: Fix Legacy Target Bundle ID

Edit the legacy target to have a proper bundle ID:

1. Select "Stoic_Camarade" target
2. Change Bundle Identifier from `Test.Stoic-Companion` to something valid
3. Or match it to your actual app

### Option C: Register Device for Automatic Provisioning

1. Connect your Apple Watch (via iPhone)
2. Xcode will detect it
3. Automatic provisioning will create profiles
4. Try archiving again

Then retry the command-line archive:

```bash
xcodebuild archive \
  -scheme "Stoic_Camarade Watch App" \
  -project Stoic_Camarade.xcodeproj \
  -archivePath "./build/StoicCompanion.xcarchive" \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates
```

## Troubleshooting

### "No profiles were found"
**Solution:** Use Xcode GUI with "Automatically manage signing"

### "Your team has no devices"
**Solution:**
- Connect Apple Watch to Mac via iPhone
- Or manually add device UDIDs in developer.apple.com

### "Archive Failed" for legacy target
**Solution:** Remove legacy target from Archive scheme (Option A above)

### "Export compliance missing"
**Solution:** In App Store Connect, answer export compliance questions

## Post-Upload Checklist

After uploading to TestFlight:

1. ✅ Check App Store Connect → Activity tab
2. ✅ Wait for processing (10-30 min)
3. ✅ Add "What to Test" notes
4. ✅ Add internal testers
5. ✅ Submit for Beta App Review (external testing)
6. ✅ Test on real Apple Watch
7. ✅ Collect feedback
8. ✅ Iterate and upload new builds

## Current Configuration Summary

**Your Project:**
- Team ID: Z2U6JRPZ53
- Bundle ID: com.stoic.camarade.watchkitapp ✅
- Signing: Automatic ✅
- Capabilities: HealthKit ✅
- Platform: watchOS only ✅

**What Works:**
- ✅ Project builds successfully
- ✅ App runs in Simulator
- ✅ Signing configuration exists

**What Needs Attention:**
- ⚠️ Legacy "Stoic_Camarade" target (archived but still in project)
- ⚠️ Need to register devices OR use Xcode GUI for provisioning
- ⚠️ Need to create App ID in App Store Connect (if not done)

## Recommended Next Steps

**Easiest path to TestFlight:**

1. **Open Xcode** → Use GUI for archive (most reliable)
2. **Fix legacy target** → Edit scheme to exclude it from archive
3. **Register device** → Connect Apple Watch for auto-provisioning
4. **Create archive** → Product → Archive
5. **Distribute** → Upload to App Store Connect
6. **Configure TestFlight** → Add testers, submit for review

This approach handles all provisioning automatically and is the standard industry practice for iOS/watchOS distribution.

---

**Need Help?** Check Apple's guides:
- https://developer.apple.com/testflight/
- https://help.apple.com/xcode/mac/current/#/dev8b4250b57
