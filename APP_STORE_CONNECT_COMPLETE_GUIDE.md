# Complete Guide: Publishing Stoic Companion to App Store Connect

**watchOS App - Stoic Companion**
**Date**: January 22, 2026
**Status**: Ready for Archive & Upload

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] ✅ **Apple Developer Program** membership ($99/year)
- [ ] ✅ **Team ID**: Z2U6JRPZ53 (already configured in project)
- [ ] ✅ **Bundle ID**: com.stoic.companion.watchkitapp
- [ ] ✅ **Xcode 26.2** installed
- [ ] ✅ **Project opened** in Xcode (just opened for you!)

---

## 🎯 Quick Path to App Store Connect (Recommended)

### Step 1: Verify Project Settings in Xcode

**Xcode is now open. Follow these steps:**

1. **Select the Project** (top of left sidebar)
   - Click "Stoic_Companion" (blue icon)

2. **Select the Watch App Target**
   - In the main area, under "TARGETS"
   - Click "Stoic_Companion Watch App"

3. **Go to "Signing & Capabilities" Tab**
   - Verify these settings:
     - ✅ **Team**: Your Apple Developer Team (Z2U6JRPZ53)
     - ✅ **Bundle Identifier**: com.stoic.companion.watchkitapp
     - ✅ **Signing**: "Automatically manage signing" should be CHECKED

4. **Check watchOS Deployment Target**
   - Go to "General" tab
   - Under "Deployment Info"
   - **Minimum Deployments**: Should be watchOS 11.0 or later

---

### Step 2: Select Build Destination

**In Xcode toolbar (top-left):**

1. Click the device/simulator dropdown (next to the scheme)
2. Select **"Any watchOS Device (arm64)"**
   - This is CRITICAL - you MUST select a physical device target for archiving
   - If you see "iPhone", you're on the wrong target!

**Correct Selection Looks Like:**
```
Stoic_Companion Watch App > Any watchOS Device (arm64)
```

---

### Step 3: Build and Test (Optional but Recommended)

Before archiving, test that the project builds:

1. **Build the Project**
   - Menu: **Product → Build** (⌘B)
   - Wait for compilation
   - Check for any errors in the Issues navigator (left sidebar, ⚠️ icon)

2. **Fix Any Build Errors**
   - Common issues:
     - Missing API keys in Config.swift
     - Code signing issues
     - Swift version mismatches

---

### Step 4: Create Archive for App Store

**This is the main step to get your app ready for upload:**

1. **Clean Build Folder** (recommended)
   - Menu: **Product → Clean Build Folder** (⇧⌘K)
   - Ensures fresh build

2. **Create Archive**
   - Menu: **Product → Archive**
   - This will:
     - Build your app for release
     - Create an .xcarchive file
     - Open the Organizer window automatically

3. **Wait for Archive to Complete**
   - Progress bar will show in Xcode
   - Can take 2-5 minutes
   - Don't interrupt the process!

**If Archive Fails:**
- Check that "Any watchOS Device (arm64)" is selected
- Verify signing is configured correctly
- Look at error messages in the build log
- See troubleshooting section below

---

### Step 5: Upload to App Store Connect

**After archive completes, the Organizer window will open:**

1. **Select Your Archive**
   - Should see "Stoic_Companion Watch App" with today's date
   - Click to select it

2. **Click "Distribute App"**
   - Button on the right side

3. **Choose Distribution Method**
   - Select **"App Store Connect"**
   - Click **"Next"**

4. **Upload Options**
   - Select **"Upload"** (not "Export")
   - Click **"Next"**

5. **Distribution Options**
   - Keep defaults:
     - ✅ Include bitcode for watchOS content: YES
     - ✅ Upload your app's symbols: YES
     - ✅ Manage Version and Build Number: Xcode Managed
   - Click **"Next"**

6. **Automatic Signing**
   - Xcode will automatically sign your app
   - Click **"Next"**

7. **Review Summary**
   - Check all details are correct:
     - App name
     - Version
     - Bundle ID
     - Team
   - Click **"Upload"**

8. **Wait for Upload**
   - Progress bar will show
   - Can take 5-15 minutes depending on app size
   - Don't close Xcode!

9. **Success!**
   - You'll see "Upload Successful" message
   - Click **"Done"**

---

## 📱 What Happens Next in App Store Connect

### Immediate (Within Minutes)

1. **Processing Begins**
   - Apple's servers receive your build
   - Processing can take 10-60 minutes

2. **Check Status**
   - Go to: https://appstoreconnect.apple.com
   - Navigate to: **My Apps → Stoic Companion → Activity**
   - You'll see your build processing

### Within 1 Hour

3. **Build Ready for Testing**
   - Status changes to "Ready to Submit" or "Ready for Testing"
   - You can now:
     - Test via TestFlight
     - Submit for App Store Review

---

## 🧪 Testing via TestFlight (Recommended Before Submission)

### Internal Testing (Free, Immediate)

1. **Go to App Store Connect**
   - https://appstoreconnect.apple.com
   - Select your app

2. **Go to TestFlight Tab**
   - Click "TestFlight" in the left sidebar

3. **Add Internal Testers**
   - Under "Internal Testing"
   - Click "+" to add testers
   - Add email addresses of your Apple Developer team

4. **Select Build**
   - Choose the build you just uploaded
   - Click "Enable Testing"

5. **Test on Your Watch**
   - Testers receive email with TestFlight link
   - Install TestFlight app on paired iPhone
   - Install Stoic Companion from TestFlight
   - Test on actual Apple Watch!

### External Testing (Requires Beta App Review)

- For testing with users outside your team
- Requires Apple's beta review (1-2 days)
- Can have up to 10,000 external testers

---

## 🚀 Submit for App Store Review

### When You're Ready

1. **Go to App Store Connect**
   - https://appstoreconnect.apple.com
   - Select "Stoic Companion"

2. **Create New Version (if needed)**
   - Click "+" next to "iOS App" or "watchOS App"
   - Enter version number (e.g., 1.0)

3. **Fill Out App Information**
   - App name: Stoic Companion
   - Subtitle: Daily Stoic Wisdom for Apple Watch
   - Description: (Write compelling description)
   - Keywords: stoic, philosophy, quotes, mindfulness, watch
   - Screenshots: **REQUIRED** (see screenshot guide below)
   - App icon: Must be 1024x1024px

4. **Select Build**
   - Click "Build" section
   - Click "+" to add build
   - Select the build you uploaded

5. **App Review Information**
   - Contact information
   - Demo account (if app requires login)
   - Notes for reviewer (optional)

6. **Submit for Review**
   - Review all information
   - Click "Submit for Review"
   - Wait 1-3 days for review

---

## 📸 Screenshot Requirements

**watchOS Screenshots Required:**

Apple requires screenshots for each watch size you support:

### Apple Watch Series 9/10 (45mm)
- **Resolution**: 396 x 484 pixels
- **Count**: 3-10 screenshots

### Apple Watch Series 9 (41mm)
- **Resolution**: 368 x 448 pixels
- **Count**: 3-10 screenshots

### How to Capture Screenshots

**Method 1: Using Xcode Simulator**
```bash
# Boot simulator
xcrun simctl boot "Apple Watch Series 9"

# Run your app
# Press: Control + Command + Shift + 3 (to capture window)
# Or: Control + Command + Shift + 4 (to select area)
```

**Method 2: Using Physical Device**
- Press side button + Digital Crown simultaneously
- Screenshots save to paired iPhone's Photos app

**Method 3: Let Xcode Generate**
- When you upload, you can add screenshots later in App Store Connect
- Use UI testing to auto-generate screenshots

---

## 🔧 Troubleshooting

### Archive Button is Greyed Out

**Problem**: Can't click "Product → Archive"

**Solution**:
1. Ensure "Any watchOS Device (arm64)" is selected
2. NOT a simulator
3. Clean build folder (⇧⌘K)
4. Restart Xcode

---

### "No Provisioning Profiles Found"

**Problem**: Error during archive about provisioning

**Solution**:
1. Go to Xcode → Settings → Accounts
2. Select your Apple ID
3. Select your team (Z2U6JRPZ53)
4. Click "Download Manual Profiles"
5. Try archiving again

---

### "Build Failed" During Archive

**Problem**: Archive fails with compilation errors

**Solution**:
1. Check the issue navigator (⚠️ icon)
2. Common fixes:
   - Missing API keys in Config.swift
   - Update Swift version to 6.0
   - Fix any code warnings/errors
3. Build for simulator first (⌘B) to catch errors
4. Then archive for device

---

### Upload Fails with "Invalid Binary"

**Problem**: Archive uploads but gets rejected

**Common Causes**:
- Missing required entitlements
- Wrong bundle identifier
- Missing watchOS deployment target
- Missing App Icon

**Solution**:
1. Check all entitlements are properly configured
2. Verify bundle ID matches App Store Connect
3. Ensure Info.plist has all required keys
4. Check App Icon is 1024x1024px and included

---

### "Missing Compliance" Warning

**Problem**: Upload succeeds but shows export compliance warning

**Solution**:
1. Go to App Store Connect
2. Select your build
3. Answer encryption questions:
   - "Does your app use encryption?" → Depends on your app
   - For most apps: NO (unless you have custom crypto)
4. Submit answers

---

## 🎯 Quick Command Reference

### Build Commands (if you prefer command line)

```bash
# Navigate to project
cd /Users/matheusrech/Desktop/STOICISM-main

# Clean build
xcodebuild -scheme "Stoic_Companion Watch App" clean

# Build for simulator (testing)
xcodebuild -scheme "Stoic_Companion Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9' \
  -allowProvisioningUpdates \
  build

# Archive for App Store (RECOMMENDED: use Xcode GUI instead)
xcodebuild archive \
  -scheme "Stoic_Companion Watch App" \
  -archivePath "./build/StoicCompanion.xcarchive" \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates

# Export for App Store (after archive)
xcodebuild -exportArchive \
  -archivePath "./build/StoicCompanion.xcarchive" \
  -exportPath "./build/export" \
  -exportOptionsPlist ExportOptions.plist
```

**Note**: GUI method is MUCH easier and handles all signing automatically!

---

## ✅ Success Checklist

### Pre-Archive
- [ ] Project opens in Xcode without errors
- [ ] "Any watchOS Device (arm64)" selected
- [ ] Signing configured (Automatically manage signing checked)
- [ ] Build succeeds (⌘B)

### Archive
- [ ] Archive created successfully (Product → Archive)
- [ ] Archive appears in Organizer window

### Upload
- [ ] "Distribute App" clicked
- [ ] "App Store Connect" selected
- [ ] Upload completed successfully
- [ ] Received "Upload Successful" message

### Post-Upload
- [ ] Build appears in App Store Connect
- [ ] Build status: "Processing" → "Ready"
- [ ] TestFlight testing completed (optional)
- [ ] Screenshots uploaded
- [ ] App information filled out
- [ ] Submitted for review

---

## 📚 Additional Resources

### Apple Documentation
- **App Store Connect Guide**: https://developer.apple.com/app-store-connect/
- **watchOS Distribution**: https://developer.apple.com/watchos/submit/
- **TestFlight Beta Testing**: https://developer.apple.com/testflight/

### Project Files
- **Quick Steps**: QUICK_TESTFLIGHT_STEPS.md
- **TestFlight Guide**: TESTFLIGHT_DISTRIBUTION_GUIDE.md
- **Testing Guide**: TESTING.md
- **Project Context**: CLAUDE.md

---

## 🎊 You're Ready!

**Current Status:**
✅ Xcode is open with your project
✅ All documentation is ready
✅ Project structure is confirmed

**Next Step:**
1. **Follow Step 2 above**: Select "Any watchOS Device (arm64)"
2. **Then Step 4**: Product → Archive
3. **Then Step 5**: Distribute App → Upload

**Estimated Time:** 30-45 minutes from archive to successful upload

---

**Good luck with your App Store submission!** 🚀

If you encounter any issues, refer to the troubleshooting section above, or check the error messages in Xcode carefully.

---

**Guide Created**: January 22, 2026
**Project**: Stoic Companion (watchOS)
**Team ID**: Z2U6JRPZ53
**Bundle ID**: com.stoic.companion.watchkitapp
