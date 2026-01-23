# 🔒 Security Note - Testing Version

## ⚠️ Important: API Key Hardcoded for Testing

Your OpenAI API key is currently **hardcoded** in `Config.swift` for easy friend testing.

### Current Setup
```swift
static let openAIKey = "sk-proj-lqQo375r..."  // ← Your actual API key
```

## ✅ Protections in Place

1. **`.gitignore` configured** - `Config.swift` won't be committed to Git
2. **Local testing only** - Perfect for 2-3 friends testing on their devices
3. **No remote distribution** - Not uploaded to App Store or TestFlight

## 💰 Cost Monitoring

**Current Model**: GPT-4o Mini
**Pricing**: ~$0.15 per 1M input tokens

**Typical usage** (per person, per day):
- 10 quote requests
- ~200 tokens per request
- **Daily cost**: < $0.01
- **Monthly cost**: ~$0.20 per tester

**For 3 testers**: ~$0.60/month total

### Monitor Usage
Check your OpenAI dashboard: https://platform.openai.com/usage

## 🚨 If You Want to Share Publicly

**Before sharing code publicly** (GitHub, etc.):

### Option 1: Remove API Key
```swift
static let openAIKey = "YOUR_OPENAI_API_KEY_HERE"
```
And tell users to add their own key.

### Option 2: Use Environment Variables
Users set key in Xcode:
- Product → Scheme → Edit Scheme
- Environment Variables: `OPENAI_API_KEY` = their key

### Option 3: Use OpenRouter Free Tier
Switch to OpenRouter's free Gemini model:
```swift
static let llmProvider: LLMProvider = .openrouter
static let llmModel: LLMModel = .openrouterGemini2  // FREE!
static let openRouterKey = "sk-or-..."  // Free tier available
```

## 📊 Usage Estimates

### Testing Phase (1 month, 3 friends)
- **Worst case**: $2-3 if they use it heavily
- **Typical case**: $0.50-1.00
- **Best case**: $0.20-0.50

### If Model Changed to GPT-4o (More Expensive)
- **Cost**: 10x higher (~$5-10/month for 3 testers)
- Current model (GPT-4o Mini) is recommended for testing!

## 🛡️ Best Practices After Testing

Once testing is complete, consider:

1. **Set spending limits** in OpenAI dashboard
2. **Monitor usage** weekly during testing
3. **Revoke key** after testing ends (if not continuing)
4. **Switch to per-user keys** for production

## 🔄 Easy Model Switching

Want to use a free option? Edit `Config.swift`:

```swift
// Switch to FREE OpenRouter option
static let llmProvider: LLMProvider = .openrouter
static let llmModel: LLMModel = .openrouterGemini2
static let openRouterKey = "GET_FREE_KEY_AT_OPENROUTER.AI"
```

No code changes needed - just config!

## 📧 If Key Gets Compromised

1. Go to https://platform.openai.com/api-keys
2. Revoke the compromised key
3. Generate a new key
4. Update `Config.swift` with new key
5. Rebuild and redistribute to friends

## ✅ For Current Testing - You're Safe!

For your use case (2-3 friends, local testing, 1 month):
- ✅ Cost is minimal
- ✅ Risk is low
- ✅ Convenience is high
- ✅ Protected by .gitignore

**Just monitor your OpenAI usage dashboard periodically!**

## 💡 Pro Tip: Set Usage Limits

In OpenAI dashboard:
1. Go to Settings → Limits
2. Set monthly budget (e.g., $5)
3. Get email alerts at 50%, 75%, 100%

This prevents unexpected charges.

---

**Testing is meant to be easy - security can be tightened for production!** 🔒✨
