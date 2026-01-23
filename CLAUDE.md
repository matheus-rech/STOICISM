# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Stoic Camarade** is a watchOS-only context-aware stoic wisdom app for Apple Watch. It delivers personalized quotes from Marcus Aurelius, Epictetus, and Seneca based on real-time health data (heart rate, HRV, activity) and daily rhythms, using AI-powered quote selection and Nano Banana Pro image generation.

The project root contains the Xcode project at: `Stoic_Camarade.xcodeproj`

## Build Commands

All commands should be run from the repository root (`/path/to/STOICISM-main/`):

```bash
# Build for watchOS Simulator (MUST use -allowProvisioningUpdates)
xcodebuild -scheme "Stoic_Camarade Watch App" \
  -configuration Debug \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -allowProvisioningUpdates \
  build

# Clean build
xcodebuild -scheme "Stoic_Camarade Watch App" clean

# Run all tests (uses Swift Testing framework, not XCTest)
xcodebuild test -scheme "Stoic_Camarade Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -allowProvisioningUpdates

# Run specific test class
xcodebuild test -scheme "Stoic_Camarade Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -only-testing:"Stoic_Camarade Watch AppTests/BackendAPIServiceTests" \
  -allowProvisioningUpdates

# Run single test
xcodebuild test -scheme "Stoic_Camarade Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -only-testing:"Stoic_Camarade Watch AppTests/BackendAPIServiceTests/testHealthCheck" \
  -allowProvisioningUpdates

# Open in Xcode
open Stoic_Camarade.xcodeproj

# List available Watch simulators
xcrun simctl list devices available | grep Watch
```

### Installing to Simulator

```bash
# Boot simulator
xcrun simctl boot "Apple Watch Series 11 (42mm)"

# Install (path varies based on DerivedData)
xcrun simctl install "Apple Watch Series 11 (42mm)" \
  "/path/to/DerivedData/Build/Products/Debug-watchsimulator/Stoic_Camarade Watch App.app"

# Launch
xcrun simctl launch "Apple Watch Series 11 (42mm)" "Test.Stoic-Companion.watchkitapp"
```

## Testing

For detailed testing instructions, see `TESTING.md`. Quick reference:

**Testing Framework**: Swift Testing (NOT XCTest)
```swift
import Testing

@Test func example() async throws {
    #expect(condition)  // NOT XCTAssert()
}
```

**Common Test Commands**:
- Run all tests: See "Build Commands" section above
- Run specific test class: Use `-only-testing:"TargetName/TestClassName"`
- Run single test: Use `-only-testing:"TargetName/TestClassName/testMethod"`

**Test Organization**:
- Unit tests: `Stoic_Camarade Watch AppTests/`
- UI tests: `Stoic_Camarade Watch AppUITests/`
- Test targets must be properly configured in Xcode project

## Architecture

### Project Structure

```
STOICISM-main/                          # Repository root
├── Stoic_Camarade.xcodeproj           # Xcode project file
├── Stoic_Camarade Watch App/          # Main watchOS app source
│   ├── ContentView.swift               # Main UI + HealthDataManager + QuoteManager + Onboarding
│   ├── Config.swift                    # LLM/RAG config + API keys (embedded RAGService)
│   ├── BackendAPIService.swift         # Backend integration (philosopher matching, profiles)
│   ├── LLMService.swift                # Protocol + data models (StoicQuote, HealthContext, etc.)
│   ├── LLMServiceFactory.swift         # Provider factory
│   ├── ClaudeService.swift             # Claude API integration
│   ├── OpenAIService.swift             # OpenAI API integration
│   ├── GeminiService.swift             # Google Gemini integration + Nano Banana images
│   ├── StoicIntents.swift              # Siri shortcuts (App Intents)
│   ├── ComplicationController.swift    # Watch face complications
│   ├── PersistenceManager.swift        # Favorites, history, notifications, statistics, UserProfile
│   ├── PhilosopherLibraryView.swift    # Philosopher profiles from backend API
│   ├── ToolsGridView.swift             # Quick access tools + PremiumAssets design system
│   ├── StoicQuotes.json                # Quote database (30+ quotes, local fallback)
│   └── [Feature Views]                 # JournalView, BreathingView, etc.
├── Stoic_Camarade Watch AppTests/     # Unit tests (Swift Testing)
├── Stoic_Camarade Watch AppUITests/   # UI tests
├── stoic-knowledge-base/               # Separate Python FastAPI backend
│   ├── api/stoic_api.py                # FastAPI service (deployed to Railway)
│   ├── data/                           # 2,160 processed passages with embeddings
│   │   ├── raw/                        # Original texts from Project Gutenberg
│   │   ├── processed/                  # Chunked and tagged passages
│   │   ├── embeddings/                 # Passages with vector embeddings
│   │   └── philosophers.json           # Philosopher profiles
│   ├── database/schema.sql             # Supabase schema
│   ├── scripts/                        # Data processing pipeline (Python)
│   └── requirements.txt                # Python dependencies
├── railway.json                        # Railway deployment config
├── .github/workflows/                  # CI/CD workflow
├── CLAUDE.md                           # This file
└── TESTING.md                          # Complete testing guide
```

### Core Architecture Pattern

```
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   ContentView    │────▶│ HealthDataManager │────▶│    HealthKit     │
│    (Main UI)     │     │ (Context Builder) │     │ (HR, HRV, Steps) │
└────────┬─────────┘     └───────────────────┘     └──────────────────┘
         │
         ▼
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   QuoteManager   │────▶│    RAGService     │────▶│   Railway API    │
│  (Orchestrator)  │     │ (Primary: Semantic│     │ (2,160 passages) │
└────────┬─────────┘     │  Vector Search)   │     └──────────────────┘
         │               └───────────────────┘
         │ fallback
         ▼
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ LLMServiceFactory│────▶│   LLM Provider    │────▶│ Claude/OpenAI/   │
│ (Secondary)      │     │  (Quote Select +  │     │ Gemini/Router +  │
│                  │     │   Nano Banana)    │     │ Image Generation │
└──────────────────┘     └───────────────────┘     └──────────────────┘
```

### Key Components

**ContentView.swift** contains three embedded components:
- `ContentView`: Main SwiftUI interface with PremiumAssets design system
- `HealthDataManager`: Queries HealthKit, builds `HealthContext` (stress level, time of day, activity state)
- `QuoteManager`: Orchestrates quote retrieval with 3-tier fallback chain (RAG → LLM → Local)

**Important - File Consolidation**: Several files have been consolidated for better organization:
- ❌ **Models.swift** (removed) → All data models now in `LLMService.swift`
- ❌ **DynamicUserContext.swift** (standalone removed) → Now embedded in `PersistenceManager.swift`

If you see import errors or references to these files, they no longer exist as standalone files. Use the consolidated versions instead.

**RAGService** (embedded in Config.swift, Primary quote source):
- Connects to deployed API at `https://stoicism-production.up.railway.app`
- Semantic search across 2,160 passages from Marcus Aurelius, Epictetus, Seneca
- Vector embeddings (1,536 dimensions) for intelligent context matching
- Health check on init: `/health` endpoint validates Railway API availability
- Transforms `HealthContext` → semantic query → API request → `StoicQuote`
- If RAG fails and `ragFallbackToLLM` is true, marks as unavailable for session

**LLM Service Layer** (`LLMService` protocol) - Secondary fallback:
- `ClaudeService`: Uses Claude Sonnet 4.5 (recommended for quality)
- `OpenAIService`: Uses GPT-4o Mini (cost-effective, ~$0.60/month)
- `GeminiService`: Uses Gemini 2.5 Flash + Nano Banana image generation
  - **Nano Banana**: Gemini 2.5 Flash Image (fast background generation)
  - **Nano Banana Pro**: Gemini 3 Pro Image (premium background generation)
- All services implement `selectQuote(context:availableQuotes:)` and `generateResponse(prompt:)`

**Config.swift** manages:
- RAG settings: `ragAPIEndpoint`, `useRAGAPI`, `ragFallbackToLLM` (controls session-level fallback)
- Provider selection: `llmProvider` enum (.claude, .openai, .openrouter, .gemini)
- Model selection: `llmModel` (various models per provider, including Nano Banana image models)
- API key loading: Environment vars → Secrets.plist → hardcoded (priority order)
- **NOTE**: RAGService class is embedded at the end of Config.swift (lines 98-256)

**PersistenceManager** handles:
- `QuoteHistoryEntry`: Tracks viewed quotes with context and effectiveness
- `NotificationSettings`: Morning/evening/custom notifications
- `QuoteStatistics`: Streaks, favorites, helpful counts, per-author stats
- Favorites management with Set<String>
- History with 100-entry limit for watchOS storage efficiency

**ToolsGridView** and **PremiumAssets** (design system):
- **ToolsGridView**: Quick access grid to 12 stoic practice tools with favorites system
  - Core wisdom tools: Breathing, Journal, Evening Audit, Virtue Log
  - AI-powered features: Consult Marcus, Your Story, Philosopher Library (NEW)
  - Powerful practices: Memento Mori, Daily Challenge, SOS Calm
- **PremiumAssets** (defined in ToolsGridView.swift:294):
  - Color palette: Nano Banana Pro Series (vibrantOrange, electricBlue, successGreen, moonPurple)
  - Glassmorphism components: `GlassBackdrop` with configurable opacity and corner radius
  - Marcus Avatar: Animated gradient circle with bust silhouette and laurel wreath
  - Virtue Icons: Four cardinal virtues (wisdom, courage, justice, temperance) with themed colors

**BackendAPIService** (NEW - Full backend integration):
- **Philosopher Matching** ("Meet Your Stoic" feature):
  - Analyzes onboarding answers (profession, focus, goals, life context)
  - Calls `POST /match` with user profile
  - Returns AI-generated match reason (via GPT-4o-mini) with confidence score
  - Integrated into onboarding flow with optional AI matching or manual selection
  - Displays personalized match result before completion
- **Philosopher Library**:
  - Fetches all philosopher profiles via `GET /philosophers`
  - Displays detailed biographies, teaching styles, core themes
  - New tool accessible from ToolsGridView
  - Powered by Supabase backend data
- **User Profile Sync** (prepared but not fully activated):
  - `GET /user/{user_id}/profile` endpoint available
  - Can fetch matched philosopher and onboarding history from backend
  - Foundation for future cross-device sync

### Data Models

All data models are consolidated in `LLMService.swift`:

```swift
struct HealthContext {
    var heartRate: Double?
    var heartRateVariability: Double?
    var timeOfDay: String?          // morning/afternoon/evening/night
    var stressLevel: StressLevel    // low/normal/elevated/high
    var isActive: Bool
    var primaryContext: String      // Combined context for AI
    var activeCalories: Double?
    var steps: Double?
}

struct StoicQuote: Codable, Identifiable {
    let id: String
    let text: String
    let author: String              // Marcus Aurelius/Epictetus/Seneca
    let book: String
    let contexts: [String]          // Tags: stress, morning, control, etc.
    let heartRateContext: String?   // elevated/resting/any
    let timeOfDay: String?
    let activityContext: String?
}

// PersistenceManager models
struct QuoteHistoryEntry: Codable, Identifiable {
    let id: UUID
    let quoteId: String
    let timestamp: Date
    let context: String
    let heartRate: Double?
    var helpful: Bool?
    var heartRateAfter: Double?
}

struct QuoteStatistics: Codable {
    var totalQuotesViewed: Int
    var favoritesCount: Int
    var helpfulCount: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastViewedDate: Date?
    var quotesPerAuthor: [String: Int]
    var effectiveQuotes: [String: Int]
}
```

## Quote Retrieval Flow

The app uses a sophisticated 3-tier fallback system for quote selection:

### Priority 1: RAG API (Semantic Search)
```swift
// In QuoteManager.getContextualQuote()
if Config.useRAGAPI && ragAvailable {
    let quote = try await ragService.getContextualQuote(context: context)
    // Returns quote from 2,160 passages via vector similarity
}
```
- **Endpoint**: `https://stoicism-production.up.railway.app/quote`
- **Method**: POST with `HealthContext` payload
- **Query Building**: `buildSemanticQuery()` transforms context into natural language
  - High stress: "feeling overwhelmed and anxious"
  - Morning: "starting the day with purpose"
  - Active: "during physical activity"
- **Response**: Highest similarity quote with score and philosopher metadata
- **Fallback trigger**: If request fails and `Config.ragFallbackToLLM == true`, marks RAG unavailable

### Priority 2: LLM-based Selection
```swift
// Fallback when RAG unavailable
guard Config.useLLMAPI else { return selectLocalQuote() }
return try await llmService.selectQuote(context: context, availableQuotes: allQuotes)
```
- Uses configured provider (Claude/OpenAI/Gemini/OpenRouter)
- Sends context + local quote database to AI for intelligent selection
- **Gemini** can also generate background images via Nano Banana models:
  ```swift
  // In ContentView.fetchNewQuote()
  if Config.llmProvider == .gemini {
      if let generated = try? await quoteManager.generateBackground(for: quote) {
          image = UIImage(data: generated)
      }
  }
  ```

### Priority 3: Local Fallback
```swift
// Final fallback if all AI services fail
private func selectLocalQuote(for context: HealthContext) -> StoicQuote {
    let filtered = allQuotes.filter { $0.contexts.contains(context.primaryContext) }
    return filtered.randomElement() ?? allQuotes.randomElement()!
}
```
- Filters `StoicQuotes.json` by matching context tags
- Always succeeds (guaranteed quote availability)

### RAG Health Monitoring

Quick check of Railway API status:
```bash
# Check RAG API health
curl https://stoicism-production.up.railway.app/health

# Expected response when healthy
{"status":"healthy","version":"1.0.0"}

# If API is down, app automatically falls back to LLM → Local
```

In code:
```swift
// In QuoteManager.init()
Task {
    ragAvailable = await ragService.checkHealth()
    // Checks /health endpoint: {"status": "healthy", "version": "..."}
}
```

## Development Notes

### Xcode Configuration

**Scheme**: Single scheme named **"Stoic_Camarade Watch App"**
- Includes both Watch App and Watch App Extension targets
- **MUST** use `-allowProvisioningUpdates` flag in all xcodebuild commands
- Environment variables can be set in: Product → Scheme → Edit Scheme → Run → Arguments

**Target Membership** (when adding new files):
- Swift files → "Stoic_Camarade Watch App" target
- Test files → "Stoic_Camarade Watch AppTests" target
- UI test files → "Stoic_Camarade Watch AppUITests" target

**Common Xcode Build Issues**:
| Error | Solution |
|-------|----------|
| "Cannot find 'X' in scope" after adding file | Clean build folder (⇧⌘K), restart Xcode if needed |
| "No profiles found" during build | Add `-allowProvisioningUpdates` to xcodebuild command |
| "Signing requires a development team" | Set team in project settings or use `-allowProvisioningUpdates` |
| Xcode not recognizing new files | Check target membership, clean build folder |

### Switching AI Providers

Edit `Config.swift`:
```swift
static let llmProvider: LLMProvider = .openai  // or .claude, .gemini, .openrouter
static let llmModel: LLMModel = .gpt4oMini     // Must match provider
```

**Available Models**:
- **Claude**: Sonnet 4.5 (recommended), Opus 4.5 (most capable), Haiku 4.5 (fastest)
- **OpenAI**: GPT-4o, GPT-4o Mini, o1, o1 Mini
- **Gemini**: 2.5 Flash (efficient), 3 Pro Preview (best reasoning), 2.0 Flash/Pro
- **Nano Banana** (Gemini image models): 2.5 Flash Image (fast), 3 Pro Image Preview (premium)

Set API key via Xcode scheme environment variables or edit hardcoded value.

### Design System Usage

The app uses the PremiumAssets design system (defined in ToolsGridView.swift:294):

```swift
// Color palette
PremiumAssets.Colors.vibrantOrange      // Fire/Challenge
PremiumAssets.Colors.electricBlue       // Calm/Journal
PremiumAssets.Colors.successGreen       // Completion
PremiumAssets.Colors.moonPurple         // Evening/Reflection

// Components
PremiumAssets.GlassBackdrop(cornerRadius: 20, opacity: 0.1)
PremiumAssets.MarcusAvatar(size: 80)
PremiumAssets.VirtueIcon(virtue: .wisdom, size: 40)
```

### Adding Quotes

Edit `StoicQuotes.json`:
```json
{
  "id": "unique_id",
  "text": "Your stoic quote",
  "author": "Marcus Aurelius",
  "book": "Meditations, Book X",
  "contexts": ["morning", "action"],
  "heartRateContext": "any",
  "timeOfDay": "morning",
  "activityContext": "any"
}
```

### Debugging RAG Integration

Enable debug logging in `Config.swift`:
```swift
static let debugMode = true
```

**Console output:**
- 🟢 RAG API available: Health check succeeded
- 🟠 RAG API unavailable: Using LLM fallback
- 🔵 RAG Request: [stress_level]
- 🟢 RAG Response: [author name]
- 🔴 RAG health check failed: [error]
- ⚠️ RAG failed: [error description]

**Testing RAG independently:**
```bash
# Check Railway API health
curl https://stoicism-production.up.railway.app/health

# Test quote retrieval
curl -X POST https://stoicism-production.up.railway.app/quote \
  -H "Content-Type: application/json" \
  -d '{"context": {"stress_level": "elevated", "time_of_day": "morning", "is_active": false}}'
```

### Testing Without API

Force local fallback by disabling RAG/LLM in `Config.swift`:
```swift
static let useRAGAPI = false
static let useLLMAPI = false
// Or just: return selectLocalQuote(for: context)  // Skip AI call
```

### Siri Commands

All phrases must include `\(.applicationName)` per App Intents requirement:
- "Get Stoic Camarade wisdom"
- "Good morning Stoic Camarade"
- "I need Stoic Camarade calm"

### Feature Views

The app includes specialized Stoic practice views:
- **JournalView**: Daily journal with prompts and AI reflection analysis
- **BreathingView**: Guided breathing exercises with haptic feedback
- **EveningAuditView**: Evening reflection following Marcus Aurelius's practice
- **MementoMoriView**: Mortality reflection and life perspective exercises
- **NegativeVisualizationView**: Premeditatio malorum exercises
- **VirtueLoggingView**: Track Cardinal Virtues (Wisdom, Courage, Justice, Temperance)
- **ChallengesView**: 30-day Stoic challenges
- **ConsultMarcusView**: AI-powered Stoic advisor (uses LLM `generateResponse()`)
- **PersonalizedStoriesView**: Context-aware Stoic stories (embedded in ToolsGridView.swift)
- **PhilosopherLibraryView** (NEW): Fetches philosopher profiles from backend API, displays detailed biographies, teaching styles, and core themes
- **TomorrowFocusView**: Morning intention setting
- **SOSPanicView**: Crisis support with breathing and grounding
- **HistoryView**: Quote history with filtering and effectiveness tracking
- **FavoritesView**: Saved quotes
- **SettingsView**: App configuration and preferences
- **ToolsGridView**: Quick access favorites grid for all tools

## Backend API Integration

The Railway backend API (`https://stoicism-production.up.railway.app`) provides 5 endpoints:

**⚠️ Current Status**: As of last check, the Railway API is returning 404 errors. The app will automatically fall back to LLM → Local quotes. To redeploy, see `stoic-knowledge-base/README.md`.

### Available Endpoints

1. **✅ `GET /health`** - Health check (INTEGRATED in RAGService)
   - Returns: `{"status": "healthy", "version": "1.0.0"}`
   - Usage: Validates API availability on app startup

2. **✅ `POST /quote`** - Contextual quote retrieval (INTEGRATED in RAGService)
   - Request: `HealthContext` with stress level, time of day, activity state
   - Response: Semantically matched quote from 2,160 passages
   - Usage: Primary quote source with RAG semantic search

3. **✅ `POST /match`** - Philosopher matching (NEW - INTEGRATED in BackendAPIService)
   - Request: User ID + onboarding answers (profession, focus, goals, life context)
   - Response: Matched philosopher with AI-generated reason and confidence score
   - Usage: "Meet Your Stoic" feature in onboarding flow
   - Example:
     ```json
     {
       "philosopher_id": "marcus_aurelius",
       "philosopher_name": "Marcus Aurelius",
       "match_reason": "Based on your role in healthcare and focus on managing anxiety, Marcus Aurelius's gentle, duty-focused wisdom resonates with your journey of service under pressure.",
       "confidence": 0.85
     }
     ```

4. **✅ `GET /philosophers`** - List all philosophers (NEW - INTEGRATED in BackendAPIService)
   - Response: Array of philosopher profiles (name, era, biography, core_themes, teaching_style)
   - Usage: Philosopher Library view with detailed profiles
   - Powers the new "Library" tool in ToolsGridView

5. **🔶 `GET /user/{user_id}/profile`** - User profile retrieval (PREPARED but not actively used)
   - Response: User profile with matched philosopher, onboarding answers, unlocked philosophers
   - Usage: Foundation for future cross-device sync
   - Not yet integrated into main app flow

### Testing Backend API

```bash
# Health check
curl https://stoicism-production.up.railway.app/health

# Get philosophers list
curl https://stoicism-production.up.railway.app/philosophers

# Test philosopher matching (requires valid payload)
curl -X POST https://stoicism-production.up.railway.app/match \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "answers": [
      {"question_id": "profession", "answer": "healthcare professional"},
      {"question_id": "challenge", "answer": "managing anxiety"},
      {"question_id": "approach", "answer": "practical wisdom for high-pressure roles"}
    ]
  }'
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "No profiles for 'Test.Stoic-Companion' were found" | Add `-allowProvisioningUpdates` to xcodebuild |
| "Cannot find 'LLMService' in scope" | Restart Xcode: `killall Xcode && open *.xcodeproj` |
| "Cannot find 'PremiumAssets' in scope" | Ensure ToolsGridView.swift is in target, rebuild |
| "Cannot find 'BackendAPIService' in scope" | Ensure BackendAPIService.swift is in target, rebuild |
| "Cannot find 'Models'" or "Cannot find 'DynamicUserContext'" | These files were consolidated - use `LLMService.swift` and `PersistenceManager.swift` |
| Siri commands not working | Rebuild app, wait 5-10 min for Siri indexing |
| HealthKit not authorized | Delete app, reinstall, re-grant permissions |
| RAG API always failing | Check Railway deployment status with `curl` command above |
| Philosopher matching fails | Check Railway API health, verify Supabase connection, check console logs |
| Philosopher Library empty | Verify `GET /philosophers` endpoint, check backend has philosopher data |
| Match result not displaying | Check `philosopherMatch` state, verify OnboardingStep.matchResult in TabView |
| Quotes not contextual | Enable `debugMode` in Config.swift, check console for RAG/LLM logs |
| LLM fallback not working | Verify API key in Config.swift, check `ragFallbackToLLM = true` |
| Nano Banana images not generating | Verify `llmProvider = .gemini`, check Gemini API key, enable debug mode |

## CI/CD

GitHub Actions workflow at `.github/workflows/objective-c-xcode.yml`:
- Triggers on push/PR to main
- Runs `xcodebuild clean build analyze`

**Railway Deployment** (stoic-knowledge-base RAG API):
- Configuration: `railway.json` in project root
- Builder: NIXPACKS
- Replicas: 1 (no sleep)
- Restart policy: ON_FAILURE with 10 max retries
- See `stoic-knowledge-base/README.md` for deployment guide

## Additional Documentation

- `TESTING.md` - Complete testing guide for simulator and device
- `stoic-knowledge-base/README.md` - RAG API documentation and deployment
- `QUICK_TESTFLIGHT_STEPS.md` - TestFlight distribution guide
- `TESTFLIGHT_DISTRIBUTION_GUIDE.md` - Detailed TestFlight setup

## Project-Specific Notes

### HealthKit Entitlements

The app requires HealthKit access (`Stoic_Camarade.entitlements`):
```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array>
    <string>health-records</string>
</array>
```

### Nano Banana Pro Series

The app is part of the "Nano Banana Pro Series" aesthetic, which includes:
- Deep black backgrounds with glassmorphism
- Vibrant accent colors (orange, blue, green, purple)
- AI-generated quote backgrounds via Gemini image models
- Marcus Avatar with laurel wreath styling
- Premium typography with serif fonts for quotes
