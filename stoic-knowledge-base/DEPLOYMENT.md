# Stoic Knowledge Base API - Deployment Guide

## Live API ✅

**Production URL**: https://stoicism-production.up.railway.app

Test it:
```bash
# Health check
curl https://stoicism-production.up.railway.app/health
# {"status":"healthy","version":"1.0.0"}

# Get philosophers
curl https://stoicism-production.up.railway.app/philosophers

# Get a contextual quote
curl -X POST https://stoicism-production.up.railway.app/quote \
  -H "Content-Type: application/json" \
  -d '{"context": {"stress_level": "elevated", "time_of_day": "morning"}, "query": "dealing with anxiety"}'
```

---

## Deploy Your Own Instance

### Option 1: Railway (Recommended)

Railway offers a simple free tier perfect for this API.

### 1. Install Railway CLI
```bash
npm install -g @railway/cli
# or
brew install railway
```

### 2. Login and Initialize
```bash
cd stoic-knowledge-base/api
railway login
railway init
```

### 3. Set Environment Variables
```bash
railway variables set SUPABASE_URL="https://cugjrmmcogocyewdvfsf.supabase.co"
railway variables set SUPABASE_SERVICE_ROLE_KEY="your-key-here"
railway variables set OPENAI_API_KEY="your-openai-key"
```

### 4. Deploy
```bash
railway up
```

### 5. Get Your URL
```bash
railway domain
```

Your API will be available at: `https://your-app.railway.app`

---

## Alternative: Deploy to Fly.io

### 1. Install Fly CLI
```bash
brew install flyctl
```

### 2. Launch
```bash
cd stoic-knowledge-base/api
fly launch
```

### 3. Set Secrets
```bash
fly secrets set SUPABASE_URL="https://cugjrmmcogocyewdvfsf.supabase.co"
fly secrets set SUPABASE_SERVICE_ROLE_KEY="your-key-here"
fly secrets set OPENAI_API_KEY="your-openai-key"
```

### 4. Deploy
```bash
fly deploy
```

---

## Alternative: Deploy to Render

1. Go to [render.com](https://render.com)
2. Create new Web Service
3. Connect your GitHub repo
4. Set root directory: `stoic-knowledge-base/api`
5. Set start command: `uvicorn stoic_api:app --host 0.0.0.0 --port $PORT`
6. Add environment variables in dashboard

---

## API Endpoints

Once deployed, your API provides:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/quote` | POST | Get contextual quote based on health data |
| `/match` | POST | Match user with philosopher (onboarding) |
| `/philosophers` | GET | List all philosophers |
| `/user/{id}/profile` | GET | Get user profile |

### Example: Get a Quote

```bash
curl -X POST https://your-api.railway.app/quote \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "stress_level": "elevated",
      "time_of_day": "morning",
      "is_active": false
    },
    "query": "dealing with anxiety"
  }'
```

### Example: Match Philosopher

```bash
curl -X POST https://your-api.railway.app/match \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "answers": [
      {"question_id": "challenge", "answer": "I struggle with anger"},
      {"question_id": "style", "answer": "I prefer practical advice"}
    ]
  }'
```

---

## Watch App Integration

Update your Watch app's `Config.swift`:

```swift
// Before: Local/hardcoded quotes
// After: RAG API
static let ragAPIEndpoint = "https://your-api.railway.app"
```

Then in your quote fetching code:

```swift
func fetchContextualQuote(context: HealthContext) async throws -> StoicQuote {
    let url = URL(string: "\(Config.ragAPIEndpoint)/quote")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = QuoteRequest(
        context: context,
        query: nil
    )
    request.httpBody = try JSONEncoder().encode(body)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(QuoteResponse.self, from: data)
}
```

---

## Cost Estimates

| Service | Free Tier | Estimated Monthly Cost |
|---------|-----------|----------------------|
| Railway | 500 hours/month | $0 (hobby use) |
| Fly.io | 3 shared-cpu VMs | $0 (hobby use) |
| Render | 750 hours/month | $0 (hobby use) |
| Supabase | 500MB, 2GB transfer | $0 (already set up) |
| OpenAI | Pay-per-use | ~$0.50-2.00/month |

Total estimated: **$0-2/month** for personal use.
