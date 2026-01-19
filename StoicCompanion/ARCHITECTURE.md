# 🏗️ Stoic Companion - Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Apple Watch                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ContentView (Main UI)                   │   │
│  │  • Displays quotes with author/book                 │   │
│  │  • Shows health context indicators                  │   │
│  │  • Refresh button                                   │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼──────────────────────────────────┐   │
│  │           HealthDataManager                          │   │
│  │  • Queries HealthKit for metrics                    │   │
│  │  • Analyzes context (stress, time, activity)        │   │
│  │  • Returns HealthContext object                     │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼──────────────────────────────────┐   │
│  │              QuoteManager                            │   │
│  │  • Loads quotes from JSON                           │   │
│  │  • Calls ClaudeService for selection                │   │
│  │  • Returns selected StoicQuote                      │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      │ HTTPS API Call
                      │
          ┌───────────▼────────────┐
          │    Claude API          │
          │  (Anthropic Cloud)     │
          │  • Receives context    │
          │  • Analyzes situation  │
          │  • Selects quote ID    │
          └───────────┬────────────┘
                      │
                      │ Returns quote ID
                      │
          ┌───────────▼────────────┐
          │   Local Quote DB       │
          │  (StoicQuotes.json)    │
          │  • 30+ quotes          │
          │  • Metadata tags       │
          └────────────────────────┘
```

## Component Details

### 1. ContentView.swift
**Responsibility**: Main user interface

```swift
┌─────────────────────────────────────┐
│         ContentView                 │
├─────────────────────────────────────┤
│ Properties:                         │
│  • @StateObject healthManager       │
│  • @StateObject quoteManager        │
│  • @State currentQuote              │
│  • @State isLoading                 │
├─────────────────────────────────────┤
│ Methods:                            │
│  • fetchNewQuote() → async          │
│  • contextIcon(for:) → String       │
│  • contextDescription(for:) → String│
├─────────────────────────────────────┤
│ UI Components:                      │
│  • Laurel icon                      │
│  • Quote text (serif font)          │
│  • Author attribution               │
│  • Context indicators               │
│  • Refresh button                   │
└─────────────────────────────────────┘
```

### 2. HealthDataManager
**Responsibility**: Health data collection & analysis

```swift
┌─────────────────────────────────────┐
│      HealthDataManager              │
├─────────────────────────────────────┤
│ HealthKit Queries:                  │
│  • Heart Rate (BPM)                 │
│  • Heart Rate Variability (ms)      │
│  • Active Calories (kcal)           │
│  • Step Count                       │
├─────────────────────────────────────┤
│ Context Analysis:                   │
│  • Time of day detection            │
│  • Stress level calculation         │
│  • Activity state determination     │
│  • Primary context selection        │
├─────────────────────────────────────┤
│ Returns: HealthContext              │
│  {                                  │
│    heartRate: 75.0,                 │
│    timeOfDay: "morning",            │
│    stressLevel: .normal,            │
│    isActive: false,                 │
│    primaryContext: "morning"        │
│  }                                  │
└─────────────────────────────────────┘
```

### 3. QuoteManager
**Responsibility**: Quote database & selection

```swift
┌─────────────────────────────────────┐
│         QuoteManager                │
├─────────────────────────────────────┤
│ Data:                               │
│  • allQuotes: [StoicQuote]          │
│  • Loaded from StoicQuotes.json     │
├─────────────────────────────────────┤
│ Methods:                            │
│  • loadQuotes()                     │
│    - Parses JSON                    │
│    - Populates array                │
│                                     │
│  • getContextualQuote(context:)     │
│    - Calls ClaudeService            │
│    - Returns perfect match          │
│    - Fallback if API fails          │
├─────────────────────────────────────┤
│ Quote Selection Priority:           │
│  1. Try Claude API                  │
│  2. If fails, use local algorithm   │
│  3. Filter by context tags          │
│  4. Match time of day               │
│  5. Return best match or random     │
└─────────────────────────────────────┘
```

### 4. ClaudeService
**Responsibility**: AI-powered quote selection

```swift
┌─────────────────────────────────────┐
│        ClaudeService                │
├─────────────────────────────────────┤
│ API Configuration:                  │
│  • Model: claude-sonnet-4-5         │
│  • Endpoint: api.anthropic.com      │
│  • Max tokens: 50                   │
│  • Authentication: API key          │
├─────────────────────────────────────┤
│ Request Flow:                       │
│  1. Build prompt with:              │
│     - Current health context        │
│     - Available quote options       │
│     - Selection criteria            │
│                                     │
│  2. Make HTTPS POST request         │
│                                     │
│  3. Parse response (quote ID)       │
│                                     │
│  4. Return selected quote           │
├─────────────────────────────────────┤
│ Error Handling:                     │
│  • Network failures                 │
│  • API rate limits                  │
│  • Invalid responses                │
│  • Fallback to local selection      │
└─────────────────────────────────────┘
```

### 5. StoicIntents (Siri)
**Responsibility**: Voice command integration

```swift
┌─────────────────────────────────────┐
│        App Intents                  │
├─────────────────────────────────────┤
│ Intents:                            │
│                                     │
│  GetStoicWisdomIntent               │
│    • General wisdom request         │
│    • Uses current context           │
│                                     │
│  MorningStoicIntent                 │
│    • Forces morning context         │
│    • Intention-setting quotes       │
│                                     │
│  EveningStoicIntent                 │
│    • Forces evening context         │
│    • Reflection quotes              │
│                                     │
│  StressReliefIntent                 │
│    • Forces stress context          │
│    • Calming quotes                 │
├─────────────────────────────────────┤
│ Shortcuts Provider:                 │
│  • Registers phrases with Siri      │
│  • "Get stoic wisdom"               │
│  • "I need calm"                    │
│  • "Good morning Stoic"             │
└─────────────────────────────────────┘
```

### 6. ComplicationController
**Responsibility**: Watch face integration

```swift
┌─────────────────────────────────────┐
│    ComplicationController           │
├─────────────────────────────────────┤
│ Supported Families:                 │
│  • Modular (Small, Large)           │
│  • Utilitarian (Small, Large)       │
│  • Circular Small                   │
│  • Graphic (all types)              │
├─────────────────────────────────────┤
│ Templates:                          │
│  • Icon: Laurel wreath (🌿)         │
│  • Text: "Stoic" / "Wisdom"         │
│  • Action: Open app on tap          │
└─────────────────────────────────────┘
```

## Data Models

### StoicQuote
```swift
struct StoicQuote: Codable, Identifiable {
    let id: String              // "ma_001"
    let text: String            // Quote content
    let author: String          // "Marcus Aurelius"
    let book: String            // "Meditations"
    let contexts: [String]      // ["stress", "control"]
    let heartRateContext: String?  // "elevated"
    let timeOfDay: String?      // "morning"
    let activityContext: String?   // "active"
}
```

### HealthContext
```swift
struct HealthContext {
    var heartRate: Double?           // BPM
    var heartRateVariability: Double? // ms
    var activeCalories: Double?      // kcal
    var steps: Int?                  // count
    var timeOfDay: String?           // "morning"
    var isActive: Bool               // true/false
    var stressLevel: StressLevel     // enum
    var primaryContext: String       // "stress"
    
    enum StressLevel {
        case low, normal, elevated, high
    }
}
```

## Data Flow

### User Opens App Flow
```
1. User opens app / taps complication
         ↓
2. ContentView appears
         ↓
3. onAppear() triggers
         ↓
4. Request HealthKit authorization
         ↓
5. Fetch new quote
         ↓
6. HealthDataManager queries health metrics
         ↓
7. Builds HealthContext object
         ↓
8. QuoteManager receives context
         ↓
9. ClaudeService called with context + quotes
         ↓
10. API returns quote ID
         ↓
11. Quote displayed on watch
         ↓
12. User reads wisdom 🏛️
```

### Siri Command Flow
```
1. User: "Hey Siri, get stoic wisdom"
         ↓
2. Siri recognizes app intent
         ↓
3. GetStoicWisdomIntent.perform() executes
         ↓
4. HealthDataManager queries current state
         ↓
5. QuoteManager selects quote
         ↓
6. Siri speaks quote aloud
         ↓
7. Shows snippet view on watch
         ↓
8. User hears & sees wisdom
```

### Complication Tap Flow
```
1. User taps complication on watch face
         ↓
2. WatchKit activates app
         ↓
3. ContentView loads
         ↓
4. Automatic quote fetch
         ↓
5. Quote displayed
```

## API Communication

### Claude API Request
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "max_tokens": 50,
  "messages": [{
    "role": "user",
    "content": "You are selecting a stoic quote.
    
    Context:
    - Heart Rate: 85 bpm
    - Time: morning
    - Stress: normal
    - Active: false
    
    Quotes: [30 options with IDs]
    
    Select best quote ID only."
  }]
}
```

### Claude API Response
```json
{
  "id": "msg_01...",
  "content": [{
    "type": "text",
    "text": "ma_003"
  }],
  "model": "claude-sonnet-4-5-20250929",
  "stop_reason": "end_turn"
}
```

## Security Architecture

### API Key Management
```
Priority 1: Environment Variable
  ↓ (if not found)
Priority 2: Secrets.plist
  ↓ (if not found)
Priority 3: Config.swift
  ↓ (if not found)
ERROR: Requires API key
```

### Data Privacy
```
┌─────────────────┐
│  Raw Health     │  NEVER leaves device
│  (HR, steps)    │  
└─────────────────┘
        ↓
┌─────────────────┐
│  Context Only   │  Sent to Claude
│  (generic state)│  "stressed, afternoon"
└─────────────────┘
        ↓
┌─────────────────┐
│  Quote ID       │  Returns
│  "ma_001"       │  
└─────────────────┘
```

## Performance Optimizations

### Lazy Loading
- Quotes loaded once on first use
- Cached in memory
- No repeated file reads

### Debouncing
- Minimum 10s between quote refreshes
- Prevents API spam
- Reduces battery drain

### Health Query Optimization
- Latest sample queries (not historical)
- Minimal data fetch
- Background refresh disabled by default

### Error Handling
- Network failures → Local fallback
- API timeout → Instant local selection
- No blocking UI operations
- All async/await properly handled

## Testing Strategy

### Unit Tests
```swift
// HealthDataManager
- Test stress level calculation
- Test time of day detection
- Test context priority logic

// QuoteManager  
- Test quote filtering
- Test fallback selection
- Test JSON parsing

// ClaudeService
- Mock API responses
- Test error handling
- Test prompt building
```

### Integration Tests
```swift
// End-to-end flows
- App launch → quote display
- Siri command → quote spoken
- Complication tap → app opens
- Health change → context update
```

### Manual Testing
```
1. Simulate different times of day
2. Vary heart rate (rest vs exercise)
3. Test without internet
4. Test Siri commands
5. Test all complication types
```

## Deployment Architecture

```
┌─────────────────────────────────────┐
│        Development                  │
│  • Xcode project                    │
│  • Simulator testing                │
│  • HealthKit simulation             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         Build                       │
│  • Swift compilation                │
│  • Asset bundling                   │
│  • Code signing                     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│     Distribution                    │
│  • TestFlight (beta)                │
│  • App Store (production)           │
│  • Direct device install (dev)      │
└─────────────────────────────────────┘
```

## Extension Points

### Easy to Add
1. **New quotes**: Edit JSON
2. **New health metrics**: Add HealthKit query
3. **UI customization**: Modify SwiftUI views
4. **New contexts**: Add to enum & logic

### Moderate Difficulty
1. **Quote favorites**: Add UserDefaults storage
2. **Sharing**: Add share sheet
3. **Notifications**: Add UNUserNotificationCenter
4. **Widget**: Create widget extension

### Advanced
1. **Learning AI**: Track quote effectiveness
2. **Custom generation**: Claude creates new quotes
3. **Multi-platform**: iPad, Mac sync
4. **Social features**: Community sharing

---

**Built with modern Swift, powered by AI, designed for wisdom.** 🏛️✨
