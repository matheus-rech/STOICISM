# 🧪 Stoic Camarade - Testing Guide

## Quick Test in Xcode Simulator

### 1. Open Project
```bash
cd /Users/matheusrech/Pictures/StoicCompanion/Stoic_Camarade
open Stoic_Camarade.xcodeproj
```

### 2. Select Watch Simulator
- In Xcode toolbar, click the destination dropdown
- Select: **Apple Watch Series 11 (42mm)** or similar

### 3. Run the App
- Press **⌘R** (Command + R)
- Or click the **▶ Play** button
- Wait for build and simulator to launch

### 4. Expected Results ✅

**App Should Display:**
```
🌿 Laurel icon at top
━━━━━━━━━━━━━━━━━━━━
   [Stoic Quote Text]

   — Marcus Aurelius
   Meditations, Book IV
━━━━━━━━━━━━━━━━━━━━
📊 Context Indicators:
   ❤️ Heart Rate: -- bpm
   🕐 Time: morning/afternoon/evening
   😌 Stress: normal
━━━━━━━━━━━━━━━━━━━━
   [↻ Refresh Button]
```

**What to Check:**
- ✅ App launches without crashing
- ✅ UI elements render correctly
- ✅ Quote text is readable
- ✅ Refresh button is visible

## Detailed Testing Checklist

### Test 2: UI Elements
- [ ] Laurel icon displays at top
- [ ] Quote text is in serif font
- [ ] Author name in orange color
- [ ] Book reference in gray
- [ ] Context indicators show icons
- [ ] Refresh button is at bottom

### Test 3: Health Context (Simulator Limitations)
**Note**: In simulator, HealthKit data will be mock/empty

Expected behavior:
- Heart Rate: Shows "-- bpm" (no data available)
- Time: Shows current time of day correctly
- Stress Level: Shows "normal" (default)
- App should NOT crash due to missing health data

### Test 4: Quote Loading
1. App opens → Should show a quote immediately (from JSON)
2. Tap refresh button → Should show loading indicator
3. After loading → Should show a different quote (or same if AI unavailable)

**Expected without API key:**
- Fallback to local selection algorithm
- No error messages visible to user
- Quote still displays correctly

### Test 5: Error Handling
**Without API Key (Normal):**
- ✅ App should work fine
- ✅ Uses local quote selection
- ✅ No crashes or error dialogs

**With Invalid API Key:**
- ✅ App should fallback gracefully
- ✅ Quote still displays
- ✅ No user-facing errors

### Test 6: Performance
- [ ] App launches in < 3 seconds
- [ ] Quote refresh is < 1 second (local) or < 3 seconds (API)
- [ ] No lag when scrolling
- [ ] No memory warnings in console

### Test 7: Siri Integration (Optional - Requires Device)
**Note**: Siri shortcuts only work on physical Apple Watch

On actual watch:
1. Install app
2. Wait 5-10 minutes for Siri indexing
3. Try: "Hey Siri, get Stoic Camarade wisdom"

Expected: Siri speaks a stoic quote

## Console Output Review

### What to Look For in Xcode Console

**Good Signs ✅:**
```
HealthKit authorization requested
Loaded 30+ quotes from JSON
Quote selected: ma_001
ContentView appeared
```

**Expected Warnings (Normal) ⚠️:**
```
HealthKit authorization failed (simulator)
Failed to get heart rate (no data)
Using fallback quote selection
```

**Bad Signs ❌ (Should NOT See):**
```
Fatal error: ...
Unexpectedly found nil ...
Index out of range
Cannot find 'StoicQuote' ...
```

## Testing Without API Keys

The app is **designed to work without API keys**:

1. No API key set → Uses local selection
2. Invalid API key → Falls back to local selection
3. API rate limit → Falls back to local selection
4. Network error → Falls back to local selection

**This is intentional** - the app should never fail due to AI unavailability.

## Testing With API Keys (Optional)

### Setup:
1. In Xcode: **Product → Scheme → Edit Scheme**
2. **Run → Arguments → Environment Variables**
3. Add one of:
   - `OPENAI_API_KEY` = `sk-...`
   - `CLAUDE_API_KEY` = `sk-ant-...`
   - `GEMINI_API_KEY` = `AIza...`

### Expected Behavior:
- First quote load takes 2-5 seconds (API call)
- Console shows: "Using [Provider] for quote selection"
- Quotes should be more contextually relevant
- Still falls back if API fails

## Common Issues & Solutions

### Issue: App Won't Build
**Solution**:
```bash
cd /Users/matheusrech/Pictures/StoicCompanion/Stoic_Camarade
xcodebuild -scheme "Stoic_Camarade Watch App" clean
open Stoic_Camarade.xcodeproj
# Product → Clean Build Folder (⇧⌘K)
# Product → Build (⌘B)
```

### Issue: "No such module 'HealthKit'"
**Solution**: Build target is set to iOS instead of watchOS
- Change destination to **Apple Watch** simulator

### Issue: Blank Screen
**Check**:
1. Console for errors
2. Quote JSON loaded correctly
3. ContentView initialized

### Issue: No Quotes Display
**Debug**:
1. Check `StoicQuotes.json` exists in bundle
2. Verify JSON is valid
3. Check console for parse errors

### Issue: Siri Not Working
**Remember**:
- Siri shortcuts don't work in simulator
- Requires physical Apple Watch
- Need to wait 5-10 min after install for indexing

## Success Criteria ✅

The app is working correctly if:

1. **✅ Launches without crashing**
2. **✅ Displays a stoic quote**
3. **✅ Shows author and book**
4. **✅ Context indicators present** (even if showing default values)
5. **✅ Refresh button works**
6. **✅ No fatal errors in console**
7. **✅ Handles missing HealthKit data gracefully**
8. **✅ Handles missing API keys gracefully**

## Automated Test Script

If you want to test via command line:

```bash
#!/bin/bash
cd /Users/matheusrech/Pictures/StoicCompanion/Stoic_Camarade

echo "Building watchOS app..."
xcodebuild -scheme "Stoic_Camarade Watch App" \
  -configuration Debug \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -allowProvisioningUpdates \
  build

echo "Installing on simulator..."
xcrun simctl boot "Apple Watch Series 11 (42mm)"
xcrun simctl install "Apple Watch Series 11 (42mm)" \
  "./Build/Products/Debug-watchsimulator/Stoic_Camarade Watch App.app"

echo "Launching app..."
xcrun simctl launch "Apple Watch Series 11 (42mm)" \
  "Test.Stoic-Companion.watchkitapp"

echo "✅ App launched! Check simulator."
```

## Next Steps After Testing

Once basic testing passes:

1. **Test on actual Apple Watch** (real HealthKit data)
2. **Configure API key** for AI-powered selection
3. **Test Siri commands** on physical device
4. **Add to watch face** as complication
5. **Daily usage** to verify context selection quality

---

**"First say to yourself what you would be; and then do what you have to do."** — Epictetus
