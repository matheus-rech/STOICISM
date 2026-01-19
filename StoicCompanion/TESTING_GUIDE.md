# 🧪 Testing Guide - Before Distribution

## Pre-Distribution Testing Checklist

Before sharing with friends, test these key features to ensure everything works.

## 🚀 Step 1: Add New Files to Xcode

### Open Project
```bash
cd /Users/matheusrech/Pictures/StoicCompanion/Stoic_Companion
open Stoic_Companion.xcodeproj
```

### Add These 4 Files to Watch App Target

**CRITICAL**: These files must be added to the **Watch App target**, not iOS target!

1. **In Xcode Project Navigator** (left sidebar):
   - Right-click on `Stoic_Companion Watch App` folder
   - Select **"Add Files to 'Stoic_Companion'..."**

2. **Navigate to parent directory** and select these 4 files:
   - ☑️ `LLMService.swift`
   - ☑️ `OpenAIService.swift`
   - ☑️ `GeminiService.swift`
   - ☑️ `LLMServiceFactory.swift`

3. **IMPORTANT - Check these options**:
   - ☑️ "Copy items if needed"
   - ☑️ "Create groups"
   - ☑️ **Add to targets: "Stoic_Companion Watch App"** ← CRITICAL!

4. **Click "Add"**

### Update Existing Files

Replace these 3 files with the updated versions from parent directory:

1. **Config.swift** - Now has multi-provider support + your API key
2. **ContentView.swift** - Now uses LLMServiceFactory
3. **ClaudeService.swift** - Now conforms to LLMService protocol

**How to replace**:
- Delete old files from Xcode (right-click → Delete)
- Add new versions (drag from Finder to Xcode)
- Ensure they're in **Watch App target**

---

## 🔨 Step 2: Build the Project

### First Build (Check for Errors)

1. **Select destination**: Apple Watch (or Simulator)
2. **Press ⌘B** (Product → Build)

### Expected Results

✅ **Should see**: "Build Succeeded" ✅

❌ **If you see errors**:

#### Common Error 1: "Cannot find type 'LLMService'"
**Solution**: Make sure `LLMService.swift` is added to Watch App target
- Select file → File Inspector → Target Membership → Check "Stoic_Companion Watch App"

#### Common Error 2: "Cannot find 'LLMServiceFactory'"
**Solution**: Make sure `LLMServiceFactory.swift` is added to Watch App target

#### Common Error 3: Type conflicts
**Solution**: Clean build folder (⌘⇧K) then rebuild (⌘B)

---

## 🧪 Step 3: Test Features

### Test 1: Basic Launch ✅

1. **Run app**: Press ⌘R
2. **Grant HealthKit permissions** when prompted
3. **App should launch** showing:
   - Laurel leaf icon (🏛️)
   - "Tap to receive wisdom" message
   - "New Wisdom" button

**Pass/Fail**: _______

### Test 2: Quote Generation ✅

1. **Tap "New Wisdom" button**
2. **Loading spinner** should appear
3. **Quote should appear** within 2-3 seconds
4. **Check console** for debug output:
   ```
   ✅ OpenAI GPT selected: quote_id
   ```

**Pass/Fail**: _______

**If it fails**:
- Check console for error messages
- Verify API key in Config.swift
- Check network connection

### Test 3: Multiple Quotes ✅

1. **Tap "New Wisdom" 3-5 times**
2. **Different quotes** should appear
3. **Context info** should update (heart rate, time)

**Pass/Fail**: _______

### Test 4: Health Context ✅

1. **Check the context info** at bottom of quote
2. **Should show**:
   - Heart rate (if available)
   - Time of day (morning/afternoon/evening)

**Pass/Fail**: _______

### Test 5: Siri Integration ✅

1. **On Apple Watch**, say:
   - "Hey Siri, get stoic wisdom"

2. **Siri should**:
   - Launch the app
   - Show a quote
   - Display confirmation

**Pass/Fail**: _______

**Note**: Siri may take a few minutes after first install to register shortcuts.

### Test 6: Watch Complications ✅

1. **Long-press watch face**
2. **Tap "Edit"**
3. **Select a complication slot**
4. **Find "Stoic Companion"**
5. **Tap to open app**

**Pass/Fail**: _______

### Test 7: Provider Verification ✅

**In Xcode Console** (⌘⇧Y to show), you should see:
```
✅ OpenAI GPT selected: ma_001
```

**Pass/Fail**: _______

### Test 8: Fallback Mechanism ✅

**Test offline fallback**:

1. **In Config.swift**, temporarily set:
   ```swift
   static let useLLMAPI = false
   ```

2. **Rebuild and run**

3. **Tap "New Wisdom"**

4. **Should still get quotes** (local selection)

5. **Console should show**:
   ```
   Using local fallback selection
   ```

6. **Restore**:
   ```swift
   static let useLLMAPI = true
   ```

**Pass/Fail**: _______

---

## 🔍 Step 4: Debug Mode Testing

### Enable Debug Output

In `Config.swift`:
```swift
static let debugMode = true
```

### Watch Console Output (⌘⇧Y)

You should see detailed logs:
```
✅ OpenAI GPT selected: ma_001
⚠️  LLM API failed: [error message]
Using local fallback selection
```

---

## 📊 Step 5: Performance Check

### Response Time Test

**Tap "New Wisdom" 10 times** and measure:

| Attempt | Time (seconds) | Success? | Provider |
|---------|----------------|----------|----------|
| 1       |                |          |          |
| 2       |                |          |          |
| 3       |                |          |          |
| 4       |                |          |          |
| 5       |                |          |          |
| 6       |                |          |          |
| 7       |                |          |          |
| 8       |                |          |          |
| 9       |                |          |          |
| 10      |                |          |          |

**Expected**:
- GPT-4o Mini: 1-3 seconds
- Success rate: 90%+

---

## 🎯 Step 6: Context-Aware Testing

### Morning Test
**Time**: 6 AM - 11 AM

1. Get quote
2. Should suggest **morning/motivation** themes
3. Example: "First say to yourself what you would be; and then do what you have to do."

**Pass/Fail**: _______

### Stress Test
**Simulate elevated heart rate**:

1. Do 30 jumping jacks
2. Wait for heart rate to elevate
3. Get quote
4. Should suggest **calming/control** themes
5. Example: "You have power over your mind - not outside events."

**Pass/Fail**: _______

### Evening Test
**Time**: 8 PM - 11 PM

1. Get quote
2. Should suggest **reflection/contentment** themes
3. Example: "Very little is needed to make a happy life."

**Pass/Fail**: _______

---

## 🔐 Step 7: Security Check

### Verify API Key Protection

```bash
cd /Users/matheusrech/Pictures/StoicCompanion
grep -n "Config.swift" .gitignore
```

**Should show**: Line 64 has `Config.swift`

**Pass/Fail**: _______

### Check API Key Format

In Config.swift, verify:
```swift
static let openAIKey = "sk-proj-lqQo375r..."  // Starts with sk-proj-
```

**Pass/Fail**: _______

---

## 💰 Step 8: Cost Monitoring

### Check OpenAI Usage

1. Go to: https://platform.openai.com/usage
2. Check today's usage
3. Should see ~10-20 requests if you tested 10 times
4. Cost should be < $0.01

**Pass/Fail**: _______

---

## ✅ Final Checklist Before Distribution

- [ ] All 4 new files added to Watch App target
- [ ] 3 existing files updated
- [ ] Build succeeds with no errors
- [ ] App launches successfully
- [ ] Quotes appear (OpenAI provider)
- [ ] Multiple quotes work
- [ ] Siri commands work
- [ ] Watch complications work
- [ ] Fallback mechanism works
- [ ] Debug output looks correct
- [ ] Response times acceptable (1-3 sec)
- [ ] Context-aware quotes appropriate
- [ ] API key protected in .gitignore
- [ ] OpenAI usage dashboard accessible
- [ ] All tests passed ✅

---

## 🐛 Common Issues & Solutions

### Issue: "Cannot find type 'LLMService'"
**Solution**:
- Verify LLMService.swift is in Watch App target
- File Inspector → Target Membership → Check the box

### Issue: No quotes appear
**Solution**:
- Check console for errors
- Verify API key in Config.swift
- Test network connection
- Try fallback mode (useLLMAPI = false)

### Issue: Build fails with "duplicate symbols"
**Solution**:
- Clean build folder (⌘⇧K)
- Rebuild (⌘B)

### Issue: Siri doesn't work
**Solution**:
- Wait 5-10 minutes after first install
- Restart Apple Watch
- Check Shortcuts app has registered the intents

### Issue: Wrong provider used
**Solution**:
- Check Config.swift: `llmProvider = .openai`
- Check console output for provider name

---

## 📝 Test Results Summary

**Date**: __________
**Xcode Version**: __________
**watchOS Version**: __________

**Overall Result**: ⭐ ____ / 8 tests passed

**Issues Found**:
-
-
-

**Ready for Distribution**: YES / NO

---

## 🚀 After Testing

If all tests pass:

```bash
# Create distribution package
./create_distribution.sh

# The ZIP will be on your Desktop
# Ready to share with friends!
```

---

**Good luck with testing!** 🏛️✨

If you find any issues, check the console output first - it usually tells you exactly what's wrong.
