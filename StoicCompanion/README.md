# 🏛️ Stoic Companion for Apple Watch

A context-aware stoic wisdom companion that delivers personalized quotes from Marcus Aurelius, Epictetus, and Seneca based on your real-time health data and daily rhythms.

## ✨ Features

### 🎯 Context-Aware Wisdom
- **Heart Rate Monitoring**: Detects stress and provides calming quotes
- **Time-Based Selection**: Morning motivation, evening reflection
- **Activity Awareness**: Encourages action or celebrates discipline
- **HRV Analysis**: Understands your stress levels
- **Smart Context**: Combines multiple signals for perfect quote selection

### 🗣️ Siri Integration
Say any of these phrases:
- *"Hey Siri, get Stoic wisdom"*
- *"Hey Siri, I need stoic advice"*
- *"Hey Siri, good morning Stoic"* (morning-specific)
- *"Hey Siri, I'm stressed"* (calming quotes)
- *"Hey Siri, evening Stoic reflection"*

### ⌚ Watch Complications
Add Stoic Companion to your watch face for instant access:
- Tap to open app
- Supports all complication families
- Beautiful laurel icon

### 🤖 Claude-Powered Selection
Uses Claude AI to intelligently match quotes to your exact situation by analyzing:
- Current heart rate & HRV
- Time of day
- Activity level
- Stress indicators
- Historical patterns

## 📱 Setup Instructions

### Prerequisites
- Apple Developer Account
- Xcode 15.0+
- watchOS 10.0+
- iOS 17.0+ (for phone companion)
- Claude API Key from Anthropic

### Step 1: Create Xcode Project

1. Open Xcode
2. Create new **Watch App** project
3. Name it "StoicCompanion"
4. Choose SwiftUI for interface
5. Enable HealthKit capability

### Step 2: Project Structure

```
StoicCompanion/
├── StoicCompanion Watch App/
│   ├── ContentView.swift          (Main interface)
│   ├── StoicIntents.swift         (Siri integration)
│   ├── ClaudeService.swift        (API integration)
│   ├── ComplicationController.swift
│   ├── StoicQuotes.json           (Quote database)
│   └── Info.plist
└── StoicCompanion iOS/
    └── (Companion app - optional)
```

### Step 3: Add Files to Xcode

1. Drag all `.swift` files into your project
2. Add `StoicQuotes.json` to Resources
3. Ensure files are added to Watch App target

### Step 4: Configure Capabilities

#### HealthKit
1. Select your Watch App target
2. Go to "Signing & Capabilities"
3. Click "+ Capability" → Add "HealthKit"
4. In `Info.plist`, add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Stoic Companion reads your heart rate and activity to provide personalized wisdom.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app does not write health data.</string>
```

#### App Intents
Already configured in `StoicIntents.swift` - no additional setup needed!

### Step 5: Add Claude API Key

**Option A: Environment Variable (Recommended)**

1. Create `Config.swift`:

```swift
struct Config {
    static let claudeAPIKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
}
```

2. In Xcode scheme:
   - Product → Scheme → Edit Scheme
   - Run → Arguments → Environment Variables
   - Add `CLAUDE_API_KEY` = `your-key-here`

**Option B: Configuration File**

1. Create `Secrets.plist` (add to `.gitignore`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ClaudeAPIKey</key>
    <string>YOUR_API_KEY_HERE</string>
</dict>
</plist>
```

2. Load in `ClaudeService.swift`:

```swift
private func loadAPIKey() -> String {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let key = dict["ClaudeAPIKey"] as? String else {
        fatalError("Claude API key not found")
    }
    return key
}
```

### Step 6: Update QuoteManager

In `ContentView.swift`, update `QuoteManager` to load quotes:

```swift
private func loadQuotes() {
    guard let url = Bundle.main.url(forResource: "StoicQuotes", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode(QuoteDatabase.self, from: data) else {
        return
    }
    allQuotes = decoded.quotes
}

// Add this struct
struct QuoteDatabase: Codable {
    let quotes: [StoicQuote]
}
```

And update `getContextualQuote` to use `ClaudeService`:

```swift
func getContextualQuote(context: HealthContext) async -> StoicQuote {
    let claudeService = ClaudeService(apiKey: Config.claudeAPIKey)
    
    do {
        let quote = try await claudeService.selectQuote(
            context: context, 
            availableQuotes: allQuotes
        )
        return quote
    } catch {
        print("Claude API failed, using fallback: \(error)")
        // Fallback to local selection
        return selectLocalQuote(for: context)
    }
}

private func selectLocalQuote(for context: HealthContext) -> StoicQuote {
    let filtered = allQuotes.filter { quote in
        if let time = quote.timeOfDay, time == context.timeOfDay || time == "any" {
            return true
        }
        return quote.contexts.contains(context.primaryContext)
    }
    return filtered.randomElement() ?? allQuotes[0]
}
```

### Step 7: Build & Deploy

1. **Select Watch Destination**: Choose your Apple Watch in Xcode
2. **Build**: ⌘B to build
3. **Run**: ⌘R to deploy to watch
4. **Grant Permissions**: Accept HealthKit permissions on watch

### Step 8: Configure Siri Shortcuts

1. After first launch, shortcuts are auto-registered
2. Open Shortcuts app on iPhone
3. Find "Stoic Companion" shortcuts
4. Test: "Hey Siri, get stoic wisdom"

### Step 9: Add Watch Complication

1. Long-press on watch face
2. Tap "Edit"
3. Select a complication slot
4. Scroll to "Stoic Companion"
5. Choose your preferred style

## 🎨 Customization

### Adding More Quotes

Edit `StoicQuotes.json`:

```json
{
  "id": "your_unique_id",
  "text": "Your stoic quote here",
  "author": "Marcus Aurelius | Epictetus | Seneca",
  "book": "Source book name",
  "contexts": ["stress", "morning", "action", etc.],
  "heartRateContext": "elevated | resting | any",
  "timeOfDay": "morning | afternoon | evening | night | any",
  "activityContext": "active | sedentary | any"
}
```

### Customizing Context Logic

In `HealthDataManager.swift`, adjust:
- `determineStressLevel()`: Change heart rate thresholds
- `determinePrimaryContext()`: Modify priority logic
- Add new health metrics (sleep, mindfulness minutes, etc.)

### Styling the Interface

In `ContentView.swift`:
- Change colors (`.foregroundColor(.orange)`)
- Modify fonts (`.font(.system(size: 14, weight: .regular, design: .serif))`)
- Adjust layout spacing

## 🧪 Testing

### Test Health Context

Use Xcode's Health data simulation:
1. Debug → Simulate Location → (choose activity)
2. Manually set heart rate in Health app
3. Watch app will update context

### Test Siri Commands

1. Use Siri on watch: "Get stoic wisdom"
2. Check Console for API calls
3. Verify quote selection logic

### Test Without Claude API

Comment out Claude API call and use fallback:

```swift
// For testing without API
return selectLocalQuote(for: context)
```

## 🚀 Advanced Features

### Morning/Evening Automation

Create shortcuts that auto-trigger:
1. Open Shortcuts app
2. Create automation
3. Trigger: Time of Day (7 AM / 9 PM)
4. Action: Run "Morning Stoic Wisdom" intent
5. Disable "Ask Before Running"

### Custom Notifications

Add to `ContentView.swift`:

```swift
func scheduleQuoteNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Stoic Wisdom"
    content.body = currentQuote?.text ?? ""
    content.sound = .default
    
    var dateComponents = DateComponents()
    dateComponents.hour = 8
    
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents, 
        repeats: true
    )
    
    let request = UNNotificationRequest(
        identifier: "dailyQuote",
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
```

### Widget Support (iOS)

Create an iOS widget showing today's quote:
1. Add Widget Extension to project
2. Use same `QuoteManager` logic
3. Update on timeline refresh

## 📊 Analytics & Insights

Track which quotes help most:

```swift
struct QuoteStats {
    var quoteId: String
    var contextWhenShown: HealthContext
    var timestamp: Date
    var heartRateAfter: Double?  // Measure calm effect
}
```

## 🔒 Privacy

- All health data stays on device
- Only quote selection context sent to Claude API
- No personal identifiers transmitted
- HealthKit data never stored externally

## 🐛 Troubleshooting

### HealthKit Not Authorized
- Check Privacy settings on Watch
- Re-request permissions: Delete app and reinstall

### Siri Commands Not Working
- Check App Intents are registered
- Rebuild and reinstall app
- Wait a few minutes for Siri indexing

### Claude API Errors
- Verify API key is correct
- Check network connectivity
- Monitor API rate limits
- Use fallback selection during testing

### Complications Not Appearing
- Rebuild app completely
- Restart Apple Watch
- Check all complication families are implemented

## 📚 Resources

- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [ClockKit Complications](https://developer.apple.com/documentation/clockkit)
- [Claude API Docs](https://docs.anthropic.com/)
- [Stoicism Resources](https://dailystoic.com/)

## 🎯 Next Steps

1. **Personalization**: Learn user's favorite philosophers
2. **Journaling**: Add reflection notes to quotes
3. **Sharing**: Share quotes to Messages/Social
4. **Streaks**: Track consecutive days of wisdom
5. **Apple Health Integration**: Log "mindful minutes"
6. **iPad/Mac Support**: Sync across devices

## 📄 License

Built with Claude & Stoic Philosophy
Free to use and modify

---

**"You have power over your mind - not outside events. Realize this, and you will find strength."**
*— Marcus Aurelius*
