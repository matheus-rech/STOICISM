# 🔐 Fix Signing Configuration - Visual Step-by-Step Guide

**Issue**: No provisioning profiles found for archiving
**Solution**: Configure automatic signing for App Store distribution

---

## 🎯 The Problem (From Your Screenshot)

```
❌ Communication with Apple failed: Your team has no devices
❌ No profiles for 'Test.Stoic-Companion' were found
❌ No profiles for 'com.stoic.camarade.watchkitapp' were found
```

**Root Cause**:
- No physical devices registered in your Apple Developer account
- Xcode trying to use Development profiles (requires devices)
- Need to use Distribution profiles instead (no devices needed)

---

## ✅ The Solution (5 Minutes)

### Step 1: Close Xcode Completely

**Action**: Quit Xcode
- Menu: Xcode → Quit Xcode
- OR: Press ⌘Q

**Why**: Need fresh start with new configuration

---

### Step 2: Reopen Project

**Action**: Reopen the project

```bash
open /Users/matheusrech/Desktop/STOICISM-main/Stoic_Camarade.xcodeproj
```

Wait for Xcode to fully load...

---

### Step 3: Configure Watch App Target Signing

**Location**: Xcode → Left Sidebar → Signing & Capabilities

**Detailed Steps**:

1. **Click Project in Navigator** (left sidebar)
   - Look for "Stoic_Camarade" with blue icon
   - Click it

2. **Select Watch App Target**
   - In main area, under "TARGETS"
   - Click "**Stoic_Camarade Watch App**"
   - (NOT "Stoic_Camarade" without "Watch App")

3. **Go to Signing & Capabilities Tab**
   - Click tab at top of main area
   - Should see signing options

4. **Enable Automatic Signing**
   - Find checkbox: "**Automatically manage signing**"
   - Make sure it's ✅ **CHECKED**

5. **Verify Team**
   - Team dropdown should show: **Z2U6JRPZ53**
   - If not, select it from dropdown

6. **Check Both Debug AND Release**
   - Look for two sections:
     - "Signing (Debug)"
     - "Signing (Release)"
   - **BOTH** should have:
     - ✅ Automatically manage signing: CHECKED
     - Team: Z2U6JRPZ53

---

### Step 4: Fix Legacy Container Target (IMPORTANT!)

**The legacy "Stoic_Camarade" target causes the error!**

**Option A: Exclude from Archive (RECOMMENDED)**

1. **Menu**: Product → Scheme → Edit Scheme
2. **Select "Archive"** in left sidebar
3. **Look at "Build" section**
4. **Find "Stoic_Camarade" (without "Watch App")**
5. **UNCHECK** the box next to it
6. **Keep ONLY "Stoic_Camarade Watch App" checked**
7. **Click "Close"**

**This tells Xcode to ONLY archive the Watch App, ignoring the legacy target!**

---

**Option B: Disable Signing on Legacy Target**

If you want to keep it in the scheme:

1. **Select "Stoic_Camarade" target** (NOT Watch App)
2. **Go to "Signing & Capabilities"**
3. **UNCHECK "Automatically manage signing"**
4. **Leave signing identity empty/unconfigured**

---

### Step 5: Clean Build Folder

**Action**: Clean before archiving

- **Menu**: Product → Clean Build Folder
- **OR**: Press ⇧⌘K
- Wait for "Clean Finished" message

---

### Step 6: Select Device Destination

**Action**: Choose correct build destination

**Location**: Top-left of Xcode toolbar

1. **Click the dropdown** (next to scheme name)
2. **Select**: "**Any watchOS Device (arm64)**"
3. **Verify it shows** "Any watchOS Device" (not simulator!)

---

### Step 7: Archive!

**Action**: Create archive for App Store

- **Menu**: Product → Archive
- **OR**: Press ⌘B then select Archive

**What to Expect**:
- Build progress bar appears
- Takes 2-5 minutes
- Organizer window opens automatically
- Your archive appears in the list

---

### Step 8: Upload to App Store Connect

**Location**: Organizer window (opens automatically after archive)

1. **Select your archive** (today's date)
2. **Click "Distribute App"** (right side)
3. **Select "App Store Connect"**
4. **Click "Next"**
5. **Select "Upload"**
6. **Click "Next"**
7. **Keep default options** → **Next**
8. **Automatic signing** → **Next**
9. **Review summary** → **"Upload"**
10. **Wait for upload** (5-15 minutes)
11. **"Upload Successful"** → **Done!** ✅

---

## 🆘 If Archive Still Fails

### Check These:

1. **Automatic signing is ENABLED**
   - Both Debug and Release
   - For "Stoic_Camarade Watch App" target

2. **Legacy target is EXCLUDED from Archive**
   - Edit Scheme → Archive → Unchecked

3. **Correct Team ID**
   - Should be: Z2U6JRPZ53

4. **Correct destination**
   - "Any watchOS Device (arm64)"
   - NOT a simulator

---

### Still Having Issues?

**Try Manual Provisioning**:

1. Go to: https://developer.apple.com/account

2. **Create App Store Provisioning Profile**:
   - Resources → Profiles → "+"
   - Type: **App Store**
   - App ID: Select "com.stoic.camarade.watchkitapp"
   - Certificate: Select your Distribution certificate
   - Name: "Stoic Camarade App Store"
   - Download

3. **Double-click downloaded profile** to install

4. **In Xcode**:
   - Signing & Capabilities
   - UNCHECK "Automatically manage signing"
   - Manually select the profile you just created

5. **Try archiving again**

---

## ✅ Success Checklist

- [ ] Xcode closed and reopened
- [ ] "Stoic_Camarade Watch App" target selected
- [ ] "Automatically manage signing" is CHECKED
- [ ] Team: Z2U6JRPZ53
- [ ] Legacy target excluded from Archive scheme
- [ ] Build folder cleaned
- [ ] "Any watchOS Device (arm64)" selected
- [ ] Product → Archive clicked
- [ ] Organizer opens with archive
- [ ] Archive uploaded successfully

---

## 📸 Visual Reference

**What Your Signing & Capabilities Should Look Like**:

```
┌─────────────────────────────────────────────┐
│ Signing & Capabilities                      │
├─────────────────────────────────────────────┤
│                                             │
│ ✅ Automatically manage signing             │
│                                             │
│ Team: Z2U6JRPZ53                           │
│                                             │
│ Signing Certificate: Apple Distribution    │
│ Provisioning Profile: Xcode Managed        │
│                                             │
│ ── Signing (Release) ──                    │
│                                             │
│ ✅ Automatically manage signing             │
│                                             │
│ Team: Z2U6JRPZ53                           │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎉 After Successful Upload

1. **Go to App Store Connect**:
   https://appstoreconnect.apple.com

2. **Check Build Status**:
   - My Apps → Stoic Camarade → Activity
   - Status: "Processing" (10-60 minutes)

3. **When Ready**:
   - Upload screenshots
   - Fill app information
   - Submit for review

---

**Time Estimate**: 5-10 minutes to fix signing and archive

**Next**: Follow this guide step-by-step in Xcode!

---

**Created**: January 22, 2026
**Issue**: Provisioning profile errors
**Solution**: Automatic signing + exclude legacy target
