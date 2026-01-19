# ✅ Setup Checklist - Multi-Provider Support

## 📦 New Files Added

The following files have been created to support multiple LLM providers:

```
StoicCompanion/
├── LLMService.swift              ← Protocol & model definitions
├── ClaudeService.swift           ← Updated to use protocol
├── OpenAIService.swift           ← NEW: OpenAI & OpenRouter support
├── GeminiService.swift           ← NEW: Google Gemini support
├── LLMServiceFactory.swift       ← NEW: Provider factory
├── Config.swift                  ← Updated with multi-provider config
├── ContentView.swift             ← Updated to use factory
├── MULTI_PROVIDER_GUIDE.md       ← NEW: Comprehensive guide
└── SETUP_CHECKLIST.md            ← This file
```

## 🚀 Setup Steps

### Step 1: Add Files to Xcode Project

1. Open your `Stoic_Companion.xcodeproj` in Xcode
2. Drag these NEW files into your Watch App target:
   - [ ] `LLMService.swift`
   - [ ] `OpenAIService.swift`
   - [ ] `GeminiService.swift`
   - [ ] `LLMServiceFactory.swift`

3. **IMPORTANT**: Ensure these files are added to the Watch App target (check the target membership in File Inspector)

### Step 2: Update Existing Files

The following files have been modified and need to be updated in Xcode:

- [ ] `ClaudeService.swift` - Now conforms to LLMService protocol
- [ ] `Config.swift` - Multi-provider configuration
- [ ] `ContentView.swift` - Uses LLMServiceFactory

**To update**: Replace the old versions with the new ones from this directory.

### Step 3: Choose Your Provider

Edit `Config.swift`:

```swift
// CHOOSE YOUR PROVIDER (pick one)
static let llmProvider: LLMProvider = .claude        // Anthropic Claude
static let llmProvider: LLMProvider = .openai        // OpenAI GPT
static let llmProvider: LLMProvider = .openrouter    // OpenRouter (100+ models)
static let llmProvider: LLMProvider = .gemini        // Google Gemini

// CHOOSE YOUR MODEL (must match provider)
static let llmModel: LLMModel = .claudeSonnet4_5     // For Claude
static let llmModel: LLMModel = .gpt4o               // For OpenAI
static let llmModel: LLMModel = .openrouterGemini2   // For OpenRouter (FREE!)
static let llmModel: LLMModel = .gemini2Flash        // For Gemini
```

### Step 4: Add API Key

Choose **one** of these methods:

#### Method A: Hardcode in Config.swift (Quick Start)

```swift
static let claudeAPIKey = "sk-ant-YOUR_KEY_HERE"
static let openAIKey = "sk-YOUR_KEY_HERE"
static let openRouterKey = "sk-or-YOUR_KEY_HERE"
static let geminiKey = "YOUR_KEY_HERE"
```

⚠️ **Remember**: Add `Config.swift` to `.gitignore`!

#### Method B: Environment Variable (Recommended)

1. In Xcode: Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add variable:
   - Name: `CLAUDE_API_KEY` (or `OPENAI_API_KEY`, etc.)
   - Value: Your API key

#### Method C: Secrets.plist (Most Secure)

1. Create `Secrets.plist` in your project
2. Add to `.gitignore`
3. Add keys:
```xml
<dict>
    <key>ClaudeAPIKey</key>
    <string>sk-ant-YOUR_KEY_HERE</string>
</dict>
```

### Step 5: Build and Test

```bash
# In Xcode
1. Select your Apple Watch as destination
2. Product → Build (⌘B)
3. Fix any build errors (usually just missing target membership)
4. Product → Run (⌘R)
5. Watch the console for debug output
```

## 🔍 Verification

### Check 1: Build Success
- [ ] Project builds without errors
- [ ] All new files are included in Watch App target

### Check 2: Provider Configuration
- [ ] `llmProvider` is set correctly in Config.swift
- [ ] `llmModel` matches the provider
- [ ] API key is configured (check console for errors)

### Check 3: Runtime Testing
- [ ] App launches on Watch
- [ ] Tap "New Wisdom" button
- [ ] Quote appears (check console to see which provider was used)
- [ ] Console shows: `✅ [Provider] selected: quote_id`

### Check 4: Fallback Testing
- [ ] Try with invalid API key → should use local fallback
- [ ] Set `Config.useLLMAPI = false` → should use local selection
- [ ] Console shows: `⚠️ LLM API failed` and `Using local fallback selection`

## 🐛 Common Issues

### Issue: "Cannot find type 'LLMService' in scope"
**Fix**: Ensure `LLMService.swift` is added to Watch App target

### Issue: "Cannot find type 'LLMProvider' in scope"
**Fix**: Ensure `LLMService.swift` is compiled before other files

### Issue: "API key not configured"
**Fix**: Check Config.swift or environment variables are set correctly

### Issue: App crashes on launch
**Fix**: Enable debug mode and check console:
```swift
static let debugMode = true
```

### Issue: Wrong provider is being used
**Fix**: Double-check `llmProvider` value in Config.swift

## 📊 Testing Each Provider

### Test Claude
```swift
static let llmProvider: LLMProvider = .claude
static let llmModel: LLMModel = .claudeSonnet4_5
static let claudeAPIKey = "sk-ant-..."
```
**Expected**: Console shows `✅ Claude (Anthropic) selected: quote_id`

### Test OpenAI
```swift
static let llmProvider: LLMProvider = .openai
static let llmModel: LLMModel = .gpt4o
static let openAIKey = "sk-..."
```
**Expected**: Console shows `✅ OpenAI GPT selected: quote_id`

### Test OpenRouter
```swift
static let llmProvider: LLMProvider = .openrouter
static let llmModel: LLMModel = .openrouterGemini2
static let openRouterKey = "sk-or-..."
```
**Expected**: Console shows `✅ OpenRouter (Multi-Model) selected: quote_id`

### Test Gemini
```swift
static let llmProvider: LLMProvider = .gemini
static let llmModel: LLMModel = .gemini2Flash
static let geminiKey = "AIza..."
```
**Expected**: Console shows `✅ Google Gemini selected: quote_id`

## 🎯 Quick Start Recommendations

### For First-Time Setup
1. Use OpenRouter with free Gemini model
2. Get key from [openrouter.ai](https://openrouter.ai)
3. No credit card needed for free tier!

```swift
static let llmProvider: LLMProvider = .openrouter
static let llmModel: LLMModel = .openrouterGemini2  // FREE!
static let openRouterKey = "sk-or-YOUR_KEY_HERE"
```

### For Production Use
1. Use Claude Sonnet 4.5 for best quality
2. Get key from [console.anthropic.com](https://console.anthropic.com)

```swift
static let llmProvider: LLMProvider = .claude
static let llmModel: LLMModel = .claudeSonnet4_5
static let claudeAPIKey = "sk-ant-YOUR_KEY_HERE"
```

## 📚 Next Steps

- [ ] Read [MULTI_PROVIDER_GUIDE.md](MULTI_PROVIDER_GUIDE.md) for detailed documentation
- [ ] Test multiple providers to find your favorite
- [ ] Set up proper security (environment variables or Secrets.plist)
- [ ] Monitor API costs at provider dashboards
- [ ] Customize quote selection prompts if needed

## ✨ Features You Now Have

✅ Support for 4 major AI providers
✅ Access to 100+ models via OpenRouter
✅ Free tier options available
✅ Automatic fallback to local selection
✅ Debug mode for troubleshooting
✅ Flexible API key configuration
✅ Easy provider switching
✅ Production-ready error handling

## 🎉 You're Done!

Your Stoic Companion now supports multiple AI providers. Enjoy the flexibility of choosing the best model for your needs!

**Questions?** Check:
- [MULTI_PROVIDER_GUIDE.md](MULTI_PROVIDER_GUIDE.md) - Comprehensive guide
- [README.md](README.md) - Original documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details

**Happy philosophizing!** 🏛️✨
