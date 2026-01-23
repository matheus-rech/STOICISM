# 🏛️ Stoic Camarade - Testing Version

Welcome, tester! This Apple Watch app delivers personalized stoic wisdom based on your health data and daily rhythms.

## 🚀 Quick Setup (5 Minutes)

### What You Need
- ✅ Mac with Xcode 15.0+
- ✅ Apple Watch (watchOS 10.0+)
- ✅ Apple Developer Account (free tier is fine)
- ✅ That's it! **No API keys needed** - already configured!

### Installation Steps

1. **Open the project**
   - Open `Stoic_Camarade.xcodeproj` in Xcode

2. **Add new Swift files to project**
   - Drag these files into your Watch App target:
     - `LLMService.swift`
     - `OpenAIService.swift`
     - `GeminiService.swift`
     - `LLMServiceFactory.swift`

3. **Build & Run**
   - Connect your Apple Watch
   - Select Watch as destination in Xcode
   - Press ⌘R to build and run

4. **Grant Permissions**
   - Allow HealthKit access on your watch
   - That's it!

## 🎯 How It Works

The app reads your:
- ❤️ Heart rate (stress detection)
- 🏃 Activity level
- ⏰ Time of day

Then uses **GPT-4o Mini AI** to select the perfect stoic quote for your current moment!

## 🗣️ Try These Commands

Say to your watch:
- "Hey Siri, get stoic wisdom"
- "Hey Siri, I need stoic advice"
- "Hey Siri, good morning Stoic"
- "Hey Siri, I'm stressed"

## 💡 What to Test

### Basic Functionality
- [ ] App launches without errors
- [ ] "New Wisdom" button shows a quote
- [ ] Quotes change when you tap the button
- [ ] Heart rate and context info appears

### Siri Integration
- [ ] Siri commands work
- [ ] Quotes are contextually appropriate
- [ ] Response time is reasonable (2-3 seconds)

### Watch Complications
- [ ] Add complication to watch face
- [ ] Tapping it opens the app

### Different Contexts
- [ ] Try in the morning → Should get motivational quotes
- [ ] Try when stressed (elevated HR) → Should get calming quotes
- [ ] Try in the evening → Should get reflective quotes
- [ ] Try after exercise → Should get discipline quotes

## 🐛 If Something Goes Wrong

### App Won't Build
- Make sure all new `.swift` files are added to Watch App target
- Clean build folder (⌘⇧K) and rebuild

### No Quotes Appear
- Check console for error messages
- Make sure HealthKit permissions are granted
- Try again after a few seconds

### Siri Not Working
- Wait a few minutes after first install
- Restart Apple Watch
- Make sure Siri is enabled on Watch

## 📊 Current Configuration

**AI Model**: GPT-4o Mini (fast, cost-effective)
**Provider**: OpenAI
**Fallback**: Local quote selection if API fails

## 💬 Feedback Needed

Please test and report:

1. **Performance**
   - How fast do quotes appear?
   - Any lag or delays?

2. **Quality**
   - Are quotes contextually appropriate?
   - Do they match your current state/mood?

3. **Siri**
   - Do voice commands work reliably?
   - Any issues with Siri responses?

4. **Battery**
   - Notice any significant battery drain?

5. **User Experience**
   - Is the interface clear?
   - Any confusing parts?
   - What would make it better?

## 🔒 Privacy Note

- All health data stays on your device
- Only generic context sent to AI (e.g., "elevated heart rate", "morning")
- No personal information transmitted
- No tracking or analytics

## 🎓 About Stoicism

The quotes come from three ancient philosophers:
- **Marcus Aurelius** - Roman Emperor, wrote *Meditations*
- **Epictetus** - Former slave, taught about freedom and control
- **Seneca** - Statesman, wrote *Letters from a Stoic*

## 💡 Pro Tips

1. **Use in different contexts** - morning routine, stressful moments, evening reflection
2. **Read slowly** - these quotes are dense with wisdom
3. **Apply one principle** - don't try to absorb everything at once
4. **Share favorites** - screenshot and share quotes that resonate

## ⚡ Known Limitations (Testing Version)

- Requires internet for AI-powered selection
- Falls back to local selection if offline
- Quote database has 30+ quotes (can be expanded)
- US English only currently

## 📧 Report Issues

Found a bug or have feedback? Let me know:
- Screenshot any errors
- Note what you were doing when it happened
- Describe expected vs actual behavior

## 🙏 Thank You!

Thanks for testing! Your feedback helps make this app better for everyone who wants to practice stoic philosophy daily.

---

**"The obstacle is the way."** — Marcus Aurelius

Enjoy your stoic journey! 🏛️✨
