# 🚀 Quick Start Guide

Get your Stoic Camarade running in 15 minutes!

## ⚡ Fast Track Setup

### 1. Get Your Claude API Key (2 min)
1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Create new key → Copy it

### 2. Create Xcode Project (3 min)
```bash
# Open Xcode → Create New Project
# Choose "Watch App"
# Name: "StoicCompanion"
# Interface: SwiftUI
# Language: Swift
```

### 3. Add Files (5 min)
Drag these files into Xcode (Watch App target):
- ✅ `ContentView.swift` → Replace default ContentView
- ✅ `StoicIntents.swift` → Add to project
- ✅ `ClaudeService.swift` → Add to project
- ✅ `ComplicationController.swift` → Add to project
- ✅ `StoicQuotes.json` → Add to Resources

### 4. Add HealthKit Capability (2 min)
1. Select Watch App target
2. Signing & Capabilities → + Capability
3. Add "HealthKit"
4. In Info.plist, add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We read your heart rate to provide personalized wisdom</string>
```

### 5. Configure API Key (2 min)
Create `Config.swift` in your project:

```swift
import Foundation

struct Config {
    static let claudeAPIKey = "YOUR_API_KEY_HERE"  // Replace this!
}
```

⚠️ **Important**: Add `Config.swift` to `.gitignore` to keep key private!

### 6. Update QuoteManager (1 min)
In `ContentView.swift`, find `loadQuotes()` and update:

```swift
private func loadQuotes() {
    guard let url = Bundle.main.url(forResource: "StoicQuotes", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let quoteDB = try? JSONDecoder().decode(QuoteDatabase.self, from: data) else {
        print("Failed to load quotes")
        return
    }
    allQuotes = quoteDB.quotes
}

struct QuoteDatabase: Codable {
    let quotes: [StoicQuote]
}
```

And update `getContextualQuote()`:

```swift
func getContextualQuote(context: HealthContext) async -> StoicQuote {
    // Load quotes if empty
    if allQuotes.isEmpty {
        loadQuotes()
    }
    
    let claudeService = ClaudeService(apiKey: Config.claudeAPIKey)
    
    do {
        return try await claudeService.selectQuote(
            context: context,
            availableQuotes: allQuotes
        )
    } catch {
        print("Claude error: \(error), using fallback")
        return allQuotes.filter { 
            $0.contexts.contains(context.primaryContext) 
        }.randomElement() ?? allQuotes[0]
    }
}
```

### 7. Build & Run! (30 sec)
1. Connect your Apple Watch
2. Select Watch destination in Xcode
3. Hit ⌘R (Run)
4. Accept HealthKit permissions on watch
5. Tap "New Wisdom" button!

## 🎉 You're Done!

### Try These Commands:
- "Hey Siri, get stoic wisdom"
- "Hey Siri, I need stoic advice"
- "Hey Siri, good morning Stoic"

### Add to Watch Face:
1. Long press watch face
2. Edit → Add complication
3. Choose "Stoic Camarade"

## 🐛 Common Issues

### "Failed to load quotes"
→ Make sure `StoicQuotes.json` is in project AND checked for Watch target

### "Claude API error"
→ Check your API key in `Config.swift`
→ Verify internet connection on watch

### Siri doesn't recognize commands
→ Wait 2-3 minutes after first install
→ Rebuild app (⌘⇧K then ⌘B)

### No heart rate data
→ Grant HealthKit permissions
→ Wear watch snugly
→ Wait a few minutes for reading

## 📱 What's Happening?

```
┌─────────────┐
│ Apple Watch │ Wakes up
└──────┬──────┘
       │ Reads heart rate, activity, time
       ▼
┌─────────────┐
│ HealthKit   │ Provides data
└──────┬──────┘
       │ Heart rate: 85 bpm, 3pm, low activity
       ▼
┌─────────────┐
│ Claude API  │ Analyzes context
└──────┬──────┘
       │ "This person is calm, afternoon, sedentary"
       │ → Quote about taking action
       ▼
┌─────────────┐
│ Your Watch  │ Displays wisdom
└─────────────┘
  "Waste no more time arguing 
   about what a good man should be.
   Be one."
   — Marcus Aurelius
```

## 🎨 Quick Customizations

### Change Color Scheme
In `ContentView.swift`, replace `.orange` with:
- `.blue` - Calm and trustworthy
- `.purple` - Wisdom and royalty  
- `.green` - Growth and nature
- `.red` - Passion and strength

### Change Font
Replace `.design(.serif)` with:
- `.design(.monospaced)` - Modern tech
- `.design(.rounded)` - Friendly and soft
- `.design(.default)` - Clean iOS style

### Add More Quotes
Just edit `StoicQuotes.json` and add entries!

## 🚀 Next Level

### Auto-Morning Quote
1. Open Shortcuts app (iPhone)
2. Automation → Time of Day → 7:00 AM
3. Add Action → "Morning Stoic Wisdom"
4. Disable "Ask Before Running"
5. Wake to wisdom! ☀️

### Track Your Calm
Monitor if quotes actually reduce stress:

```swift
// Add to ContentView
@State private var heartRateBeforeQuote: Double?
@State private var heartRateAfterQuote: Double?

// Track 2 minutes after showing quote
// See if HR decreased → quote helped!
```

## 💡 Pro Tips

1. **Best time to use**: Morning (intention), Evening (reflection), Stressed moments
2. **Favorite quotes**: Take screenshots for later
3. **Share wisdom**: Long-press quote → Share
4. **Battery life**: App is very efficient, minimal impact
5. **Offline mode**: Quotes work offline (uses local fallback)

## 🙏 Philosophy in Practice

This isn't just an app—it's a tool for **living philosophically**.

- Morning quotes → Set daily intention
- Stress quotes → Find calm in chaos  
- Evening quotes → Reflect on virtue
- Activity quotes → Inspire action

**The goal**: Internalize stoic wisdom until you don't need the app anymore. 🏛️

---

**"First say to yourself what you would be; and then do what you have to do."**
*— Epictetus*

Enjoy your journey toward wisdom! 🌟
