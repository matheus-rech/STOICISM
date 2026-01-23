# 🔐 Security Setup Guide - Stoic Camarade

## ⚠️ URGENT: API Key Security

**CRITICAL ACTION REQUIRED:** The Gemini API key `AIzaSyDpIxsbBxCz7Llt9w3T1-Rhx3DF5byIfFk` was exposed in the Git repository history and must be revoked immediately.

### Immediate Steps

1. **Revoke the exposed key:**
   - Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Find the key ending in `...byIfFk`
   - Click "Delete" or "Revoke"

2. **Generate a new Gemini API key:**
   - In Google AI Studio, click "Create API Key"
   - Copy the new key
   - Update `Secrets.plist` with the new key

---

## API Key Management

Stoic Camarade supports three methods for providing API keys (in priority order):

### Method 1: Environment Variables (Recommended for Development)

```bash
# Add to your ~/.zshrc or ~/.bash_profile
export GEMINI_API_KEY="your_new_gemini_key_here"
export CLAUDE_API_KEY="your_claude_key"
export OPENAI_API_KEY="your_openai_key"
export OPENROUTER_API_KEY="your_openrouter_key"

# Reload shell
source ~/.zshrc
```

### Method 2: Secrets.plist (Recommended for Production)

1. **Update the existing `Secrets.plist`:**
   - Located at: `Stoic_Camarade Watch App/Secrets.plist`
   - Replace placeholder values with your actual keys
   - This file is in `.gitignore` and won't be committed

2. **Ensure it's added to your Xcode target:**
   - In Xcode, select `Secrets.plist`
   - In File Inspector, check "Stoic_Camarade Watch App" target membership

### Method 3: Hardcoded (NOT RECOMMENDED - Disabled)

Hardcoding API keys in `Config.swift` is now disabled for security. Use methods 1 or 2 instead.

---

## Files Added for Security

### Created Files:
- ✅ `.gitignore` - Excludes sensitive files from git
- ✅ `Config.xcconfig` - Build configuration (gitignored)
- ✅ `Config.xcconfig.template` - Template for team members
- ✅ `Secrets.plist` - Runtime API key storage (gitignored)

### Modified Files:
- ✅ `Config.swift` - Removed hardcoded API keys

---

## Verification

After setup, verify your configuration:

```bash
# Run from project root
cd /Users/matheusrech/Downloads/deploy/STOICISM-main

# Check that sensitive files are gitignored
git status

# You should NOT see:
# - Config.xcconfig
# - Secrets.plist
```

---

## Team Setup Instructions

For team members cloning this repository:

1. **Copy the template:**
   ```bash
   cp Config.xcconfig.template Config.xcconfig
   ```

2. **Edit `Config.xcconfig`:**
   - Add your own API keys
   - Never commit this file

3. **Create your `Secrets.plist`:**
   - See `Secrets.plist.template` (if exists) or create manually
   - Add to Xcode target but don't commit

---

## Security Best Practices

### ✅ DO:
- Use environment variables for local development
- Use Secrets.plist for production builds
- Revoke compromised keys immediately
- Use different API keys for development vs production
- Monitor API usage for anomalies

### ❌ DON'T:
- Commit API keys to version control
- Share API keys in Slack, email, or messaging apps
- Use the same API key across multiple projects
- Hardcode API keys in source code
- Include API keys in screenshots or demos

---

## Incident Response

If an API key is compromised:

1. **Revoke immediately** at the provider's console
2. **Generate new key** and update configuration
3. **Audit usage** for suspicious activity
4. **Update all deployments** with new key
5. **Review git history** to ensure key is purged

---

## Additional Resources

- [Google AI Studio](https://aistudio.google.com/) - Gemini API keys
- [Anthropic Console](https://console.anthropic.com/) - Claude API keys
- [OpenAI Platform](https://platform.openai.com/) - OpenAI API keys
- [OpenRouter](https://openrouter.ai/) - OpenRouter API keys

---

**Last Updated:** January 23, 2026
**Security Contact:** See CLAUDE.md for project maintainer info
