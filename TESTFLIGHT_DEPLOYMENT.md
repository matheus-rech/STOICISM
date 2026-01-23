# 🚀 TestFlight Deployment Guide - Stoic Camarade

## Current Build Status
- ✅ **Version**: 1.0
- ✅ **Build**: 2
- ✅ **All Tests**: Passing
- ✅ **Security**: API keys secured
- ✅ **AI Services**: Claude, Gemini, OpenAI working
- ✅ **Railway KB API**: Functioning correctly

---

## 📋 Pre-Deployment Checklist

### ✅ Code Quality (COMPLETE)
- [x] No force unwraps in production code
- [x] API keys secured in Secrets.plist (gitignored)
- [x] Error handling with user feedback
- [x] Build succeeds with 0 errors
- [x] All LLM services tested
- [x] Railway RAG API verified working

### ⚠️ Required Before Upload
- [ ] Revoke old exposed Gemini API key: [Google AI Studio](https://aistudio.google.com/app/apikey)
- [ ] Generate fresh Gemini API key
- [ ] Update Secrets.plist with new key
- [ ] Test app one final time on device/simulator

---

## 🎯 Deployment Method (Choose One)

### **Option 1: Xcode GUI (Recommended)**

**Most reliable for first-time TestFlight deployment**

#### Steps:
1. **Open Project**
   ```bash
   open /Users/matheusrech/Downloads/deploy/STOICISM-main/Stoic_Camarade.xcodeproj
   ```

2. **Select Device**
   - Scheme: **"Stoic_Camarade Watch App"**
   - Destination: **"Any watchOS Device"** (top toolbar)

3. **Create Archive**
   - Menu: **Product → Archive**
   - Wait ~3-5 minutes for build

4. **Distribute to TestFlight**
   - Organizer opens automatically
   - Click **"Distribute App"**
   - Choose: **App Store Connect → Upload**
   - Signing: **Automatically manage signing**
   - Click **"Upload"**

5. **Wait for Processing**
   - ~10 minutes in App Store Connect
   - Check status: [App Store Connect](https://appstoreconnect.apple.com/)

6. **Enable Internal Testing**
   - Go to TestFlight tab
   - Add build to "Internal Testing"
   - Invite testers (up to 100 internal testers)

---

### **Option 2: Command Line Script**

**For automated builds or CI/CD**

#### Run Script:
```bash
cd /Users/matheusrech/Downloads/deploy/STOICISM-main
./archive_testflight.sh
```

This will:
- ✅ Clean build folder
- ✅ Create archive at `~/Desktop/StoicCamarade.xcarchive`
- ✅ Export for App Store
- ⚠️ You'll need to upload manually (see script output)

#### Manual Upload (after script):
```bash
# Option A: Using altool (requires app-specific password)
xcrun altool --upload-app \
  -f ~/Desktop/StoicCamarade_Export/*.ipa \
  -u your_apple_id@email.com \
  -p your-app-specific-password

# Option B: Using Transporter app (GUI)
open ~/Desktop/StoicCamarade_Export
# Drag .ipa file into Transporter app
```

---

## 📱 App Store Connect Configuration

### Required Information

**App Information:**
- Name: **Stoic Camarade**
- Bundle ID: **com.stoic.camarade.watchkitapp**
- Category: **Health & Fitness / Lifestyle**
- Age Rating: **4+** (no objectionable content)

**watchOS Requirements:**
- Minimum: **watchOS 10.0**
- Devices: All Apple Watch models (Series 4+)
- Features: HealthKit integration

**Privacy:**
- HealthKit Data: Heart rate, HRV, activity
- Purpose: "Personalized stoic wisdom based on your current state"

**What's New (Version 1.0 Build 2):**
```
Initial release of Stoic Camarade - your personal philosophical companion.

Features:
• AI-powered quote selection based on heart rate and activity
• Multiple LLM models (Claude, Gemini, OpenAI)
• Semantic search with 2,160 curated Stoic passages
• Health-contextual wisdom delivery
• Watch face complications
• Daily stoic practices and tools

Improvements in Build 2:
• Enhanced security (API key management)
• Improved error handling
• Optimized LLM integration
• Fixed crash prevention issues
```

---

## 🖼️ Screenshots Requirements

### Required Sizes:
- **Apple Watch 45mm**: 396 × 484 pixels (3-10 images)
- **Apple Watch 41mm**: 368 × 448 pixels (3-10 images)

### Recommended Screenshots:
1. Main quote view (show health context)
2. Quote with AI-generated background
3. Stoic tools grid
4. Settings/customization
5. Watch face complication

### Generate Screenshots:
```bash
# Run app in simulator
# Cmd+S to save screenshot
# Or use: xcrun simctl io booted screenshot screenshot.png
```

---

## ⚠️ Troubleshooting

### Archive Failed - Missing Provisioning Profile
**Solution**: In Xcode, select target → Signing & Capabilities → Enable "Automatically manage signing"

### Upload Failed - Invalid Binary
**Solution**: Ensure you selected "Any watchOS Device" (not simulator) before archiving

### Processing Taking Too Long (>30 mins)
**Solution**: Check App Store Connect status page for outages: https://developer.apple.com/system-status/

### "Your session has expired"
**Solution**:
1. Xcode → Preferences → Accounts
2. Remove and re-add Apple ID
3. Try upload again

---

## 📊 Post-Upload Checklist

### Immediate (Within 1 hour)
- [ ] Verify build appears in App Store Connect
- [ ] Check "Processing" status (should complete in ~10 mins)
- [ ] Review build details (version, size, supported devices)

### TestFlight Setup (After processing)
- [ ] Add build to Internal Testing group
- [ ] Write test notes for testers
- [ ] Invite internal testers (email addresses)
- [ ] Monitor crash reports and feedback

### Before Public Beta
- [ ] Collect feedback from internal testers (5-10 people)
- [ ] Fix critical bugs reported
- [ ] Add build to External Testing (public beta)
- [ ] Submit for Beta App Review if needed

---

## 🎉 Success Criteria

✅ **Build uploaded successfully**
✅ **Processing completed (green checkmark)**
✅ **No processing errors in App Store Connect**
✅ **Build available in TestFlight within 10 minutes**
✅ **Internal testers receive invitation email**
✅ **App installs on test devices**
✅ **All features working (quotes, health data, AI)**

---

## 📞 Support Resources

**App Store Connect**: https://appstoreconnect.apple.com/
**TestFlight Help**: https://developer.apple.com/testflight/
**Developer Forums**: https://developer.apple.com/forums/
**Status Page**: https://developer.apple.com/system-status/

**API Management:**
- Google AI Studio: https://aistudio.google.com/app/apikey
- Railway Dashboard: https://railway.app/dashboard
- OpenAI Platform: https://platform.openai.com/
- OpenRouter: https://openrouter.ai/

---

## 🔄 Future Updates

When releasing updates:
1. Increment build number: `xcrun agvtool next-version -all`
2. Update "What's New" in App Store Connect
3. Follow same archive process
4. Add to TestFlight
5. After testing, submit for App Review

**Build History:**
- Build 1: Initial implementation
- Build 2: Security fixes, error handling, LLM optimization (CURRENT)

---

**Created**: January 23, 2026
**Status**: ✅ Ready for TestFlight Deployment
**Next Step**: Choose deployment method above and begin archive process
