# 🤖 Multi-Provider LLM Guide

Stoic Camarade now supports **multiple AI providers**! Choose from Claude, OpenAI, Gemini, or OpenRouter (which gives access to 100+ models).

## ✨ Supported Providers

| Provider | Models | Cost | Best For |
|----------|--------|------|----------|
| **Claude** (Anthropic) | Sonnet 4.5, Opus 4.5, Haiku 4.5 | $$ | Best reasoning, nuanced selection |
| **OpenAI** | GPT-4o, GPT-4o Mini, o1, o1-mini | $$$ | Latest GPT models, strong performance |
| **OpenRouter** | 100+ models from all providers | $ | Access everything, free options available |
| **Gemini** (Google) | Gemini 2.0 Flash, 2.0 Pro, 1.5 Pro | $ | Fast, cost-effective |

## 🚀 Quick Start

### 1. Choose Your Provider

Edit `Config.swift`:

```swift
// Choose one of: .claude, .openai, .openrouter, .gemini
static let llmProvider: LLMProvider = .claude
```

### 2. Select a Model

```swift
// Claude models
static let llmModel: LLMModel = .claudeSonnet4_5  // Recommended
static let llmModel: LLMModel = .claudeOpus4_5     // Most capable
static let llmModel: LLMModel = .claudeHaiku4_5    // Fastest/cheapest

// OpenAI models
static let llmModel: LLMModel = .gpt4o             // Latest GPT
static let llmModel: LLMModel = .gpt4oMini         // Cost-effective
static let llmModel: LLMModel = .o1                // Reasoning model
static let llmModel: LLMModel = .o1Mini            // Fast reasoning

// OpenRouter (100+ models)
static let llmModel: LLMModel = .openrouterGemini2  // FREE!
static let llmModel: LLMModel = .openrouterClaude   // Claude via OpenRouter
static let llmModel: LLMModel = .openrouterGPT4o    // GPT-4o via OpenRouter

// Gemini models
static let llmModel: LLMModel = .gemini2Flash      // Fast
static let llmModel: LLMModel = .gemini2Pro        // Capable
static let llmModel: LLMModel = .gemini1_5Pro      // Previous gen
```

### 3. Add API Key

```swift
// In Config.swift
static let claudeAPIKey = "sk-ant-..."        // From console.anthropic.com
static let openAIKey = "sk-..."               // From platform.openai.com
static let openRouterKey = "sk-or-..."        // From openrouter.ai
static let geminiKey = "AIza..."              // From aistudio.google.com
```

## 🔑 Getting API Keys

### Claude (Anthropic)
1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Create new key
5. Copy key (starts with `sk-ant-`)

**Pricing**: $3 per million input tokens (Sonnet 4.5)

### OpenAI
1. Go to [platform.openai.com](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Create new key
5. Copy key (starts with `sk-`)

**Pricing**: $2.50 per million input tokens (GPT-4o)

### OpenRouter (⭐ Recommended for Multiple Models)
1. Go to [openrouter.ai](https://openrouter.ai/)
2. Sign up or log in
3. Get API key
4. Copy key (starts with `sk-or-`)

**Why OpenRouter?**
- 🎯 Access 100+ models through **one API**
- 💰 **Free options available** (Gemini 2.0 Flash)
- 🔄 Easy switching between models
- 💳 Pay-per-use pricing

**Pricing**: Varies by model. Some are **FREE**!

### Google Gemini
1. Go to [aistudio.google.com](https://aistudio.google.com/)
2. Sign up with Google account
3. Get API key
4. Copy key

**Pricing**: Free tier available, $0.075 per million input tokens

## 📋 Configuration Examples

### Example 1: Claude Sonnet (Recommended)

```swift
struct Config {
    static let llmProvider: LLMProvider = .claude
    static let llmModel: LLMModel = .claudeSonnet4_5
    static let claudeAPIKey = "sk-ant-YOUR_KEY_HERE"
}
```

**Use Case**: Best overall quality, excellent reasoning

### Example 2: OpenRouter with Free Gemini

```swift
struct Config {
    static let llmProvider: LLMProvider = .openrouter
    static let llmModel: LLMModel = .openrouterGemini2  // FREE!
    static let openRouterKey = "sk-or-YOUR_KEY_HERE"
}
```

**Use Case**: Free usage, good quality

### Example 3: GPT-4o Latest

```swift
struct Config {
    static let llmProvider: LLMProvider = .openai
    static let llmModel: LLMModel = .gpt4o
    static let openAIKey = "sk-YOUR_KEY_HERE"
}
```

**Use Case**: Latest GPT capabilities

### Example 4: Cost-Optimized (Gemini Direct)

```swift
struct Config {
    static let llmProvider: LLMProvider = .gemini
    static let llmModel: LLMModel = .gemini2Flash
    static let geminiKey = "YOUR_KEY_HERE"
}
```

**Use Case**: Cheapest option, fast responses

## 🔐 Security Best Practices

### Option 1: Environment Variables (Recommended)

1. In Xcode: Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add key: `CLAUDE_API_KEY` = `sk-ant-...`

The app will automatically use environment variables first.

### Option 2: Secrets.plist (Private File)

Create `Secrets.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ClaudeAPIKey</key>
    <string>sk-ant-YOUR_KEY_HERE</string>
    <key>OpenAIKey</key>
    <string>sk-YOUR_KEY_HERE</string>
    <key>OpenRouterKey</key>
    <string>sk-or-YOUR_KEY_HERE</string>
    <key>GeminiKey</key>
    <string>YOUR_KEY_HERE</string>
</dict>
</plist>
```

**Important**: Add `Secrets.plist` to `.gitignore`!

### Option 3: Hardcode in Config.swift

⚠️ Not recommended for production or public repos!

## 🎯 Model Comparison

### Performance Ranking (Quote Selection Quality)

1. **Claude Opus 4.5** - Most sophisticated, best contextual understanding
2. **Claude Sonnet 4.5** - Excellent balance of quality and speed
3. **GPT-4o** - Strong general performance
4. **o1 / o1-mini** - Great for complex reasoning
5. **Gemini 2.0 Pro** - Good quality, very fast
6. **Claude Haiku 4.5** - Fast, good enough for most cases
7. **GPT-4o Mini** - Cost-effective, decent quality
8. **Gemini 2.0 Flash** - Very fast, acceptable quality

### Speed Ranking

1. **Gemini 2.0 Flash** - Fastest (< 1s)
2. **Claude Haiku 4.5** - Very fast (~1s)
3. **GPT-4o Mini** - Fast (~1.5s)
4. **Claude Sonnet 4.5** - Medium (~2s)
5. **GPT-4o** - Medium (~2.5s)
6. **Gemini 2.0 Pro** - Medium (~2.5s)
7. **Claude Opus 4.5** - Slower (~4s)
8. **o1 / o1-mini** - Slowest (reasoning models)

### Cost Ranking (Cheapest to Most Expensive)

1. **OpenRouter Gemini 2.0 Flash** - FREE
2. **Gemini 2.0 Flash** (direct) - $0.075/M tokens
3. **Claude Haiku 4.5** - $0.80/M tokens
4. **GPT-4o Mini** - $0.15/M tokens
5. **Gemini 2.0 Pro** - $1.25/M tokens
6. **OpenAI GPT-4o** - $2.50/M tokens
7. **Claude Sonnet 4.5** - $3.00/M tokens
8. **Claude Opus 4.5** - $15.00/M tokens
9. **OpenAI o1** - $15.00/M tokens

## 🛠️ Advanced Usage

### Switching Providers at Runtime

Currently not supported via UI, but you can create custom instances:

```swift
// In QuoteManager or custom service
let customService = LLMServiceFactory.createService(
    provider: .openai,
    apiKey: "sk-...",
    model: .gpt4oMini
)

let quote = try await customService.selectQuote(
    context: context,
    availableQuotes: allQuotes
)
```

### Testing Multiple Providers

```swift
// Test different providers
let providers: [LLMProvider] = [.claude, .openai, .gemini, .openrouter]

for provider in providers {
    if LLMServiceFactory.isConfigured(provider) {
        print("\(provider.displayName) is ready!")
    } else {
        print(LLMServiceFactory.setupInstructions(for: provider))
    }
}
```

### Fallback Strategy

The app automatically falls back to local quote selection if:
- API key is not configured
- Network request fails
- API returns an error
- `Config.useLLMAPI = false`

## 🐛 Troubleshooting

### "API key not configured" Error

**Solution**:
1. Check `Config.swift` has correct key
2. Verify key format (Claude: `sk-ant-`, OpenAI: `sk-`, etc.)
3. Try environment variable approach

### API Request Fails

**Check**:
- Network connectivity
- API key is valid (test at provider's website)
- Account has credits/active subscription
- Rate limits not exceeded

**Enable debug mode**:
```swift
static let debugMode = true
```

Watch console for detailed error messages.

### Wrong Provider Selected

**Verify in Config.swift**:
```swift
static let llmProvider: LLMProvider = .claude  // Make sure this matches your key!
```

### Slow Response Times

**Try**:
- Use faster model (Gemini 2.0 Flash, Claude Haiku)
- Check network connection
- Consider OpenRouter for potentially better routing

## 📊 Cost Estimation

For typical daily usage (10 quotes per day):

| Provider | Model | Daily Cost | Monthly Cost |
|----------|-------|------------|--------------|
| OpenRouter | Gemini 2.0 Flash | $0.00 | $0.00 |
| Gemini | 2.0 Flash | $0.00 | $0.01 |
| Claude | Haiku 4.5 | $0.00 | $0.02 |
| OpenAI | GPT-4o Mini | $0.00 | $0.01 |
| Claude | Sonnet 4.5 | $0.01 | $0.10 |
| OpenAI | GPT-4o | $0.01 | $0.15 |
| Claude | Opus 4.5 | $0.05 | $1.50 |

**Average quote request**: ~200 input tokens, ~20 output tokens

## 🎓 Recommendations

### For Most Users
**Provider**: OpenRouter
**Model**: Gemini 2.0 Flash (Free)
**Why**: Free, fast, good quality

### For Best Quality
**Provider**: Claude
**Model**: Sonnet 4.5
**Why**: Best contextual understanding, excellent reasoning

### For Latest Features
**Provider**: OpenAI
**Model**: GPT-4o
**Why**: Latest capabilities, strong performance

### For Testing/Development
**Provider**: OpenRouter
**Model**: openrouterGemini2
**Why**: Free tier perfect for development

## 🔄 Migration from Claude-Only

If you were using the old Claude-only version:

1. No code changes needed in your app!
2. The factory pattern is backward compatible
3. By default, it still uses Claude Sonnet 4.5
4. Just update `Config.swift` to try other providers

## 📚 Additional Resources

- [Claude API Docs](https://docs.anthropic.com/)
- [OpenAI API Docs](https://platform.openai.com/docs/)
- [OpenRouter Docs](https://openrouter.ai/docs)
- [Gemini API Docs](https://ai.google.dev/docs)

## 💡 Tips & Tricks

1. **Start with OpenRouter free tier** to test before committing to a paid provider
2. **Use Haiku/Mini models** during development, upgrade to better models for production
3. **Enable debug mode** to see which provider is actually responding
4. **Keep multiple API keys configured** for automatic failover (future feature)
5. **Monitor costs** - check your provider dashboards regularly

---

**Questions?** Check the main [README.md](README.md) or [ARCHITECTURE.md](ARCHITECTURE.md) for more details!

**Want to contribute?** Add support for more providers! The architecture makes it easy.
