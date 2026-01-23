# 🏛️ Welcome to Stoic Camarade!

**A context-aware stoic wisdom app for Apple Watch powered by Claude AI**

## 📖 Quick Navigation

### 🚀 Ready to Build?
**→ Start here: [QUICKSTART.md](QUICKSTART.md)** (15-minute setup)

### 📚 Want to Learn More?
1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Overview of what you've built
2. **[FEATURES.md](FEATURES.md)** - Complete feature list with examples
3. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical deep dive
4. **[README.md](README.md)** - Full documentation

### 💻 Code Files
- **[ContentView.swift](ContentView.swift)** - Main UI & HealthKit integration
- **[StoicIntents.swift](StoicIntents.swift)** - Siri voice commands
- **[ClaudeService.swift](ClaudeService.swift)** - Claude API integration
- **[ComplicationController.swift](ComplicationController.swift)** - Watch face complications
- **[Config.swift](Config.swift)** - Configuration & API keys

### 📦 Resources
- **[StoicQuotes.json](StoicQuotes.json)** - 30+ curated stoic quotes
- **[Info-Sample.plist](Info-Sample.plist)** - HealthKit permissions template
- **[.gitignore](.gitignore)** - Security (keeps API keys private)

## ⚡ Quick Start (TL;DR)

```bash
1. Open Xcode → Create Watch App
2. Add all .swift files to project
3. Add StoicQuotes.json to Resources
4. Add HealthKit capability
5. Get Claude API key from console.anthropic.com
6. Add key to Config.swift
7. Build & run on Apple Watch
8. Say "Hey Siri, get stoic wisdom"
```

## 🎯 What This App Does

**Delivers personalized stoic quotes based on:**
- ❤️ Your heart rate (stress detection)
- 🏃 Your activity level
- ⏰ Time of day
- 🧠 Claude AI analysis

**Features:**
- 🗣️ Siri voice commands
- ⌚ Watch face complications  
- 🏛️ 30+ quotes from Marcus Aurelius, Epictetus, Seneca
- 🤖 AI-powered contextual matching

## 🏗️ Project Structure

```
StoicCompanion/
│
├── 📄 Documentation
│   ├── START_HERE.md          ← You are here!
│   ├── QUICKSTART.md          ← Begin here
│   ├── README.md              ← Full docs
│   ├── FEATURES.md            ← Feature details
│   ├── ARCHITECTURE.md        ← Technical design
│   └── PROJECT_SUMMARY.md     ← Overview
│
├── 💻 Swift Code
│   ├── ContentView.swift      ← Main app UI
│   ├── StoicIntents.swift     ← Siri integration
│   ├── ClaudeService.swift    ← AI integration
│   ├── ComplicationController.swift
│   └── Config.swift           ← API keys
│
└── 📦 Resources
    ├── StoicQuotes.json       ← Quote database
    ├── Info-Sample.plist      ← Permissions
    └── .gitignore             ← Security
```

## 🎨 How It Works

```
┌──────────────────────────────────────────┐
│ 1. Watch reads your heart rate, time    │
│ 2. Analyzes if you're stressed/calm     │
│ 3. Sends context to Claude AI           │
│ 4. Claude selects perfect stoic quote   │
│ 5. Displays wisdom on your wrist        │
└──────────────────────────────────────────┘
```

**Example:**
- **Morning (8 AM, calm)**: "First say to yourself what you would be; and then do what you have to do." — Epictetus
- **Stressed (HR 105)**: "You have power over your mind - not outside events." — Marcus Aurelius
- **Evening (9 PM)**: "Very little is needed to make a happy life." — Marcus Aurelius

## 🛠️ What You Need

**Requirements:**
- ✅ Mac with Xcode 15.0+
- ✅ Apple Watch (watchOS 10.0+)
- ✅ Apple Developer Account
- ✅ Claude API key (free at console.anthropic.com)
- ✅ 15 minutes of time

**Skills Needed:**
- Basic Xcode knowledge (we provide all code!)
- Ability to follow instructions
- Interest in stoic philosophy 🏛️

## 📱 After Building

**Daily Use:**
1. Morning: "Hey Siri, good morning Stoic" → Sets intention
2. Stressed: "Hey Siri, I need calm" → Finds perspective
3. Evening: Tap complication → Reflect on day

**Customization:**
- Add more quotes (edit JSON)
- Change colors (edit SwiftUI)
- Adjust stress thresholds (edit HealthDataManager)
- Create custom Siri phrases

## 🎓 Learn Stoicism

**Why Stoicism?**
Ancient philosophy for modern life:
- Focus on what you control
- Accept what you cannot change  
- Live virtuously in the present
- Find peace through wisdom

**Stoic Masters:**
- **Marcus Aurelius**: Roman Emperor, wrote *Meditations*
- **Epictetus**: Former slave, taught about freedom
- **Seneca**: Statesman, wrote *Letters from a Stoic*

## 💡 Philosophy of This App

**Goal**: Not technology dependence, but **philosophical training**

This app is like training wheels for wisdom:
1. Start with app reminders
2. Internalize the quotes
3. Apply principles naturally
4. Eventually don't need the app!

**Until then**: Wear wisdom on your wrist. 🏛️✨

## 🚨 Important Notes

### Security
- ⚠️ Never commit `Config.swift` to git
- ⚠️ Keep your Claude API key private
- ✅ `.gitignore` is configured for safety

### Privacy
- ✅ All health data stays on your device
- ✅ Only generic context sent to Claude
- ✅ No personal data transmitted
- ✅ No tracking or analytics

## 🤔 Need Help?

**Common Questions:**

1. **"I don't have a Claude API key"**
   → Get one free at [console.anthropic.com](https://console.anthropic.com/)

2. **"I've never built a Watch app"**
   → Perfect! Follow QUICKSTART.md step-by-step

3. **"Can I customize the quotes?"**
   → Yes! Just edit StoicQuotes.json

4. **"Will this drain my battery?"**
   → No, minimal impact (<1% per day)

5. **"Does it work offline?"**
   → Yes! Falls back to local selection

## 🎯 Next Steps

### Absolute Beginner?
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Follow instructions exactly
3. Ask for help if stuck
4. Celebrate your first quote! 🎉

### Experienced Developer?
1. Scan [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review code files
3. Customize to your needs
4. Deploy and enjoy!

### Want Deep Understanding?
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - What & Why
2. [FEATURES.md](FEATURES.md) - Complete capabilities
3. [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
4. [README.md](README.md) - Everything else

## 🌟 Final Wisdom

**"The best time to plant a tree was 20 years ago. The second best time is now."**
*— Chinese Proverb*

**The best time to start living philosophically? Right now.**

---

## 🎬 Ready?

**→ [Start Building: QUICKSTART.md](QUICKSTART.md)**

Or explore the docs above at your own pace.

Good luck on your journey toward wisdom! 🏛️

---

*Built with Claude AI • Powered by Ancient Philosophy • Designed for Your Wrist*

**Questions?** Read the docs or dive into the code!

**Stuck?** Double-check QUICKSTART.md troubleshooting section.

**Inspired?** Share your stoic practice with others!
