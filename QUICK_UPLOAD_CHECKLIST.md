o# ⚡ QUICK UPLOAD CHECKLIST - Stoic Companion to App Store

**Xcode is OPEN. Follow these steps in order.**

---

## ✅ Step-by-Step (30 minutes)

### 1️⃣ Select Build Destination (CRITICAL!)

**In Xcode toolbar (top-left):**
```
Click dropdown → Select: "Any watchOS Device (arm64)"
```

**Looks like:**
```
Stoic_Companion Watch App > Any watchOS Device (arm64)
```

⚠️ **MUST be device, NOT simulator!**

---

### 2️⃣ Verify Signing (1 minute)

1. Click "Stoic_Companion" (left sidebar, blue icon)
2. Select target: "Stoic_Companion Watch App"
3. Tab: "Signing & Capabilities"
4. Check:
   - ✅ Team: Z2U6JRPZ53
   - ✅ "Automatically manage signing" is CHECKED

---

### 3️⃣ Clean Build (30 seconds)

**Menu:**
```
Product → Clean Build Folder (⇧⌘K)
```

---

### 4️⃣ Create Archive (2-5 minutes)

**Menu:**
```
Product → Archive
```

**Wait for:**
- Progress bar to complete
- Organizer window to open automatically

**If fails:** See troubleshooting in main guide

---

### 5️⃣ Upload to App Store Connect (5-15 minutes)

**In Organizer window that just opened:**

1. Select your archive (today's date)
2. Click **"Distribute App"**
3. Select **"App Store Connect"** → Next
4. Select **"Upload"** → Next
5. Keep defaults → Next
6. Automatic signing → Next
7. Review → **"Upload"**
8. Wait for upload to complete
9. Click **"Done"**

**Success!** ✅

---

## 📱 Next: Go to App Store Connect

**URL:** https://appstoreconnect.apple.com

**Steps:**
1. Navigate to: **My Apps → Stoic Companion → Activity**
2. Wait 10-60 minutes for processing
3. When ready: Fill out app information
4. Upload screenshots (required!)
5. Submit for review

---

## 🆘 Common Issues

### Archive button greyed out?
→ Select "Any watchOS Device (arm64)" (not simulator!)

### Signing error?
→ Xcode → Settings → Accounts → Download Profiles

### Build fails?
→ Check errors in Issue Navigator (⚠️ icon)
→ Make sure Config.swift has valid API keys

---

## 📸 Screenshot Requirements

**Needed BEFORE submitting to review:**

- **45mm watch**: 396 x 484 pixels (3-10 screenshots)
- **41mm watch**: 368 x 448 pixels (3-10 screenshots)

**Capture:**
- Control + Command + Shift + 3 (full window)
- Or from physical watch: Side button + Digital Crown

---

## ✅ Today's Checklist

- [x] Xcode opened
- [ ] "Any watchOS Device (arm64)" selected
- [ ] Clean build folder
- [ ] Archive created
- [ ] Upload to App Store Connect
- [ ] Check App Store Connect for build
- [ ] (Later) Upload screenshots
- [ ] (Later) Fill app information
- [ ] (Later) Submit for review

---

**Time Estimate:** ~30 minutes from archive to upload complete

**Full Guide:** APP_STORE_CONNECT_COMPLETE_GUIDE.md

---

**Quick Reference - Keep This Open While Working!**
