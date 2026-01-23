# Stoic Camarade + Gemini Integration Guide

## Overview

This guide shows how to integrate Gemini AI capabilities into your Stoic Camarade app, respecting watchOS constraints while adding powerful features via an iOS companion app.

---

## 🎯 Feature Matrix

| Feature | watchOS | iOS | Model | Battery Impact |
|---------|---------|-----|-------|----------------|
| Quote Selection | ✅ | ✅ | `gemini-2.5-flash` | Low |
| Consult Marcus Chat | ✅ | ✅ | `gemini-2.5-flash` | Low |
| Quick Reflections | ✅ | ✅ | `gemini-2.5-flash` | Low |
| Quote Backgrounds | ❌ | ✅ | `gemini-2.5-flash-image` | Medium |
| Photo → Wisdom | ❌ | ✅ | `gemini-2.5-flash` | Medium |
| Shareable Cards | ❌ | ✅ | `gemini-2.5-flash-image` | Medium |
| Stoic Infographics | ❌ | ✅ | `gemini-2.5-flash-image` | High |

---

## ⌚ watchOS Features (Already Great!)

### 1. Enhanced Quote Selection
Your app already does this well. Just switch to Gemini in `Config.swift`:

```swift
static let llmProvider: LLMProvider = .gemini
static let llmModel: LLMModel = .gemini2Flash
```

### 2. Consult Marcus (Improved)

```
┌─────────────────────────────────┐
│  ⌚ Apple Watch                 │
│  ┌───────────────────────────┐ │
│  │    🏛️ Consult Marcus      │ │
│  │                           │ │
│  │  "I'm anxious about       │ │
│  │   tomorrow's meeting"     │ │
│  │                           │ │
│  │  ─────────────────────── │ │
│  │                           │ │
│  │  "Focus only on what      │ │
│  │   you can prepare now.    │ │
│  │   The meeting itself      │ │
│  │   is not yet real."       │ │
│  │              — Marcus     │ │
│  │                           │ │
│  │  [Ask Another] [Done]     │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

### 3. Quick Reflection Generator

```
┌─────────────────────────────────┐
│  ⌚ Evening Audit               │
│  ┌───────────────────────────┐ │
│  │  📝 Today's Reflection    │ │
│  │                           │ │
│  │  Context: You logged      │ │
│  │  "felt frustrated at      │ │
│  │   slow progress"          │ │
│  │                           │ │
│  │  ─────────────────────── │ │
│  │                           │ │
│  │  "Progress is made in     │ │
│  │   small steps. What       │ │
│  │   single small step did   │ │
│  │   you take today?"        │ │
│  │                           │ │
│  │  [Save to Journal]        │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

---

## 📱 iOS Companion App Features (New!)

### 4. Quote Cards with AI Backgrounds

**User Flow:**
1. User favorites a quote on Watch
2. Opens iOS app → "My Quotes"
3. Taps "Create Card"
4. AI generates serene background
5. Quote overlaid with elegant typography
6. Share to Instagram/Messages

```
┌──────────────────────────────────────┐
│  📱 iPhone                           │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │    [AI-Generated Background]   │  │
│  │                                │  │
│  │    ┌──────────────────────┐   │  │
│  │    │                      │   │  │
│  │    │  "You have power     │   │  │
│  │    │   over your mind —   │   │  │
│  │    │   not outside        │   │  │
│  │    │   events."           │   │  │
│  │    │                      │   │  │
│  │    │   — Marcus Aurelius  │   │  │
│  │    │                      │   │  │
│  │    └──────────────────────┘   │  │
│  │                                │  │
│  │  [🔄 Regenerate] [📤 Share]   │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**Background Styles:**
- 🌅 **Serene** - Soft gradients, zen garden
- 🏛️ **Stoic** - Roman columns, warm sunset
- 🏔️ **Nature** - Mountains, lakes, mist
- ⬛ **Minimal** - Abstract geometric
- 🌌 **Cosmic** - Stars, galaxy, vastness

### 5. Photo → Stoic Wisdom

**User Flow:**
1. User takes photo of something bothering them (messy desk, traffic, etc.)
2. AI analyzes the image
3. Returns stoic perspective and actionable advice

```
┌──────────────────────────────────────┐
│  📱 What's on Your Mind?             │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │  [📸 Photo of cluttered desk] │  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│  🔍 Stoic Analysis:                  │
│                                      │
│  "A space showing many tasks        │
│   competing for attention."          │
│                                      │
│  🎯 What You Control:                │
│  "You can choose ONE task to         │
│   complete. The rest will wait."     │
│                                      │
│  📖 Principle:                       │
│  "Do not disturb yourself by         │
│   picturing your life as a whole."   │
│                                      │
│  ✅ Suggestion:                      │
│  "Clear one small corner. Start      │
│   there. Progress, not perfection."  │
│                                      │
│  [Save Insight] [Try Another]        │
└──────────────────────────────────────┘
```

### 6. Stoic Infographics

**User Flow:**
1. User selects a Stoic concept (e.g., "Dichotomy of Control")
2. AI generates educational infographic
3. Interactive hotspots explain each part

```
┌──────────────────────────────────────┐
│  📱 Explore: Dichotomy of Control    │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │  [AI-Generated Infographic]    │  │
│  │                                │  │
│  │      ┌─────┐    ┌─────┐       │  │
│  │      │  ✓  │    │  ✗  │       │  │
│  │      │ IN  │    │ OUT │       │  │
│  │      └──┬──┘    └──┬──┘       │  │
│  │         │          │          │  │
│  │    ┌────┴────┐ ┌───┴───┐     │  │
│  │    │Thoughts │ │Weather│     │  │
│  │    │Actions  │ │Others │     │  │
│  │    │Values   │ │Past   │     │  │
│  │    └─────────┘ └───────┘     │  │
│  │                                │  │
│  │  Tap regions for details →     │  │
│  └────────────────────────────────┘  │
│                                      │
│  [Download] [Share] [Learn More]     │
└──────────────────────────────────────┘
```

---

## 🔧 Implementation Priority

### Phase 1: Quick Wins (watchOS)
1. ✅ Switch to Gemini for quote selection (already supported)
2. 🔧 Add Gemini to `ConsultMarcusView.swift`
3. 🔧 Add AI reflection to `EveningAuditView.swift`

### Phase 2: iOS Companion (New App)
1. Create new iOS target in Xcode project
2. Implement `StoicGeminiService.swift`
3. Build Quote Card generator
4. Add Photo → Wisdom feature

### Phase 3: Polish
1. Sync favorites between Watch ↔ iOS
2. Add more background styles
3. Build infographic explorer

---

## 💰 Cost Estimate

| Feature | Calls/Day | Cost/Month |
|---------|-----------|------------|
| Quote Selection | 10 | ~$0.10 |
| Consult Marcus | 5 | ~$0.05 |
| Image Generation | 3 | ~$0.30 |
| Photo Analysis | 2 | ~$0.05 |
| **Total** | | **~$0.50/user** |

Gemini is very cost-effective for this use case!

---

## 🔐 API Key Setup

Add to your environment or `Config.swift`:

```swift
static let geminiKey = "AIzaSy..." // Your Google API key
```

Or use environment variable:
```bash
export GOOGLE_API_KEY="AIzaSy..."
```

---

## 📁 Files to Add

```
Stoic_Camarade/
├── Stoic_Camarade Watch App/
│   ├── GeminiService.swift      # Add this (watch-compatible)
│   └── ConsultMarcusView.swift  # Update to use Gemini
│
└── Stoic_Camarade iOS/         # NEW companion app
    ├── StoicGeminiService.swift # Full feature service
    ├── QuoteCardView.swift      # Card generator UI
    ├── PhotoWisdomView.swift    # Photo analysis UI
    └── InfographicView.swift    # Interactive infographics
```

---

## Next Steps

1. **Decide scope**: watchOS-only improvements, or add iOS companion?
2. **Set API key**: Add `GOOGLE_API_KEY` to environment
3. **Start small**: Integrate Gemini into ConsultMarcus first
4. **Iterate**: Add image features via iOS companion

Would you like me to implement any specific feature?
