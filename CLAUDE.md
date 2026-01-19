# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Stoic Companion** is a watchOS-only context-aware stoic wisdom app for Apple Watch. It delivers personalized quotes from Marcus Aurelius, Epictetus, and Seneca based on real-time health data (heart rate, HRV, activity) and daily rhythms, using AI-powered quote selection.

The main project is located at: `StoicCompanion/Stoic_Companion/`

## Build Commands

All commands should be run from `StoicCompanion/Stoic_Companion/`:

```bash
# Build for watchOS Simulator (MUST use -allowProvisioningUpdates)
xcodebuild -scheme "Stoic_Companion Watch App" \
  -configuration Debug \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -allowProvisioningUpdates \
  build

# Clean build
xcodebuild -scheme "Stoic_Companion Watch App" clean

# Run tests
xcodebuild test -scheme "Stoic_Companion Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
  -allowProvisioningUpdates

# Open in Xcode
open StoicCompanion/Stoic_Companion/Stoic_Companion.xcodeproj

# List available Watch simulators
xcrun simctl list devices available | grep Watch
```

### Installing to Simulator

```bash
# Boot simulator
xcrun simctl boot "Apple Watch Series 11 (42mm)"

# Install (path varies based on DerivedData)
xcrun simctl install "Apple Watch Series 11 (42mm)" \
  "/path/to/DerivedData/Build/Products/Debug-watchsimulator/Stoic_Companion Watch App.app"

# Launch
xcrun simctl launch "Apple Watch Series 11 (42mm)" "Test.Stoic-Companion.watchkitapp"
```

## Architecture

### Project Structure

```
StoicCompanion/
├── Stoic_Companion/                    # Xcode project root
│   ├── Stoic_Companion.xcodeproj       # Xcode project file
│   ├── Stoic_Companion Watch App/      # Main watchOS app source
│   │   ├── ContentView.swift           # Main UI + HealthDataManager + QuoteManager
│   │   ├── Config.swift                # LLM provider selection & API keys + RAG config
│   │   ├── LLMService.swift            # Protocol for AI providers
│   │   ├── LLMServiceFactory.swift     # Provider factory
│   │   ├── RAGService.swift            # RAG API client for semantic quote retrieval
│   │   ├── ClaudeService.swift         # Claude API integration
│   │   ├── OpenAIService.swift         # OpenAI API integration
│   │   ├── GeminiService.swift         # Google Gemini integration
│   │   ├── StoicIntents.swift          # Siri shortcuts (App Intents)
│   │   ├── ComplicationController.swift # Watch face complications
│   │   ├── StoicQuotes.json            # Quote database (30+ quotes, local fallback)
│   │   └── [Feature Views]             # JournalView, BreathingView, etc.
│   ├── Stoic_Companion Watch AppTests/ # Unit tests
│   ├── stoic-knowledge-base/           # RAG Knowledge Base (2,160 passages)
│   │   ├── api/                        # FastAPI service (deployed on Railway)
│   │   ├── data/                       # Processed texts & embeddings
│   │   └── database/                   # Supabase schema & upload scripts
│   └── .github/workflows/              # CI/CD workflow
├── [Documentation files]               # README.md, ARCHITECTURE.md, etc.
└── [Backup folders]                    # Stoic_Companion_Backup/
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
│ (Secondary)      │     │  (Quote Select)   │     │ Gemini/Router    │
└──────────────────┘     └───────────────────┘     └──────────────────┘
```

### Key Components

**ContentView.swift** contains three embedded components:
- `ContentView`: Main SwiftUI interface
- `HealthDataManager`: Queries HealthKit, builds `HealthContext` (stress level, time of day, activity state)
- `QuoteManager`: Orchestrates quote retrieval with fallback chain (RAG → LLM → Local)

**RAGService.swift** (Primary quote source):
- Connects to deployed API at `https://stoicism-production.up.railway.app`
- Semantic search across 2,160 passages from Marcus Aurelius, Epictetus, Seneca
- Vector embeddings (1,536 dimensions) for intelligent context matching
- Transforms `HealthContext` → API request → `StoicQuote`

**LLM Service Layer** (`LLMService` protocol) - Secondary fallback:
- `ClaudeService`: Uses Claude Sonnet 4.5 (recommended for quality)
- `OpenAIService`: Uses GPT-4o Mini (cost-effective, ~$0.60/month)
- `GeminiService`: Uses Gemini 2.0 Flash
- All services implement `selectQuote(context:availableQuotes:)` and `generateResponse(prompt:)`

**Config.swift** manages:
- RAG settings: `ragAPIEndpoint`, `useRAGAPI`, `ragFallbackToLLM`
- Provider selection: `llmProvider` enum (.claude, .openai, .openrouter, .gemini)
- Model selection: `llmModel` (various models per provider)
- API key loading: Environment vars → Secrets.plist → hardcoded (priority order)

### Data Models

```swift
struct HealthContext {
    var heartRate: Double?
    var heartRateVariability: Double?
    var timeOfDay: String?          // morning/afternoon/evening/night
    var stressLevel: StressLevel    // low/normal/elevated/high
    var isActive: Bool
    var primaryContext: String      // Combined context for AI
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
```

## Development Notes

### Switching AI Providers

Edit `Config.swift`:
```swift
static let llmProvider: LLMProvider = .openai  // or .claude, .gemini, .openrouter
static let llmModel: LLMModel = .gpt4oMini     // Must match provider
```

Set API key via Xcode scheme environment variables or edit hardcoded value.

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

### Testing Without API

In `QuoteManager.getContextualQuote()`, use fallback directly:
```swift
return selectLocalQuote(for: context)  // Skip AI call
```

### Siri Commands

All phrases must include `\(.applicationName)` per App Intents requirement:
- "Get Stoic Companion wisdom"
- "Good morning Stoic Companion"
- "I need Stoic Companion calm"

### Testing Framework

Uses Swift Testing (not XCTest):
```swift
import Testing

@Test func example() async throws {
    #expect(condition)
}
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "No profiles for 'Test.Stoic-Companion' were found" | Add `-allowProvisioningUpdates` to xcodebuild |
| "Cannot find 'LLMService' in scope" | Restart Xcode: `killall Xcode && open *.xcodeproj` |
| Siri commands not working | Rebuild app, wait 5-10 min for Siri indexing |
| HealthKit not authorized | Delete app, reinstall, re-grant permissions |

## CI/CD

GitHub Actions workflow at `.github/workflows/objective-c-xcode.yml`:
- Triggers on push/PR to main
- Runs `xcodebuild clean build analyze`

## Additional Documentation

Detailed docs in `StoicCompanion/`:
- `ARCHITECTURE.md` - Full technical deep-dive
- `MULTI_PROVIDER_GUIDE.md` - AI provider comparison
- `TESTING_GUIDE.md` - Testing procedures
- `Stoic_Companion/CLAUDE.md` - Extended development guide
