# 🚂 Railway Environment Variables Setup Guide

## Quick Links
- **Railway Dashboard**: https://railway.app/dashboard
- **OpenAI API Keys**: https://platform.openai.com/api-keys
- **Supabase Dashboard**: https://supabase.com/dashboard

---

## Step 1: Get Your API Credentials

### A) OpenAI API Key

1. Go to: https://platform.openai.com/api-keys
2. Click **"+ Create new secret key"**
3. Name: "Stoic Companion RAG"
4. Click **Create secret key**
5. **COPY THE KEY** (starts with `sk-proj-...`)
   - ⚠️ You can only see it once!

### B) Supabase Credentials

1. Go to: https://supabase.com/dashboard
2. Click on your project (or create new project: "stoic-knowledge-base")
3. Click **Settings** (gear icon in sidebar)
4. Click **API** section
5. Copy these two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **service_role key**: (under "Project API keys" section)
     - Click "Reveal" next to service_role
     - Copy the key

---

## Step 2: Set Variables in Railway

### Method A: Railway Dashboard (Recommended)

1. **Open Railway**: https://railway.app/dashboard
2. **Find your project**: Look for "stoicism-production" or similar
3. **Click on the service** (your API deployment)
4. **Go to Variables tab**
5. **Click "+ New Variable"**
6. **Add these 3 variables**:

   **Variable 1:**
   ```
   Name: OPENAI_API_KEY
   Value: [Paste your OpenAI key from Step 1A]
   ```

   **Variable 2:**
   ```
   Name: SUPABASE_URL
   Value: [Paste your Supabase URL from Step 1B]
   ```

   **Variable 3:**
   ```
   Name: SUPABASE_SERVICE_ROLE_KEY
   Value: [Paste your Supabase service key from Step 1B]
   ```

7. **Click "Add" after each variable**
8. Railway will automatically **redeploy** (takes 1-2 minutes)

---

## Step 3: Verify Setup

Wait 2 minutes, then test:

```bash
curl -X POST https://stoicism-production.up.railway.app/health
```

Should return:
```json
{"status":"healthy","version":"1.0.0"}
```

Then test quote retrieval:
```bash
curl -X POST https://stoicism-production.up.railway.app/quote \
  -H "Content-Type: application/json" \
  -d '{"context": {"stress_level": "elevated", "time_of_day": "morning", "is_active": false}}'
```

Should return a Stoic quote!

---

## Step 4: Upload Data to Supabase (If Needed)

If you haven't uploaded the Stoic passages to Supabase yet:

1. **Check if data exists**:
   - Go to Supabase Dashboard
   - Click "Table Editor"
   - Look for "passages" table
   - If it exists with 2,160 rows, you're good! ✅
   - If empty or missing, continue to step 2

2. **Create database schema**:
   ```bash
   cd /Users/matheusrech/Desktop/STOICISM-main/stoic-knowledge-base/database
   # Copy the contents of schema.sql
   # Go to Supabase → SQL Editor → New query
   # Paste and run the SQL
   ```

3. **Upload passages**:
   ```bash
   cd /Users/matheusrech/Desktop/STOICISM-main/stoic-knowledge-base/database
   python3 upload_to_supabase.py \
     --url "YOUR_SUPABASE_URL" \
     --key "YOUR_SERVICE_ROLE_KEY"
   ```

---

## Troubleshooting

### "401 Unauthorized" error when testing quote
- Check that OPENAI_API_KEY is set correctly in Railway
- Make sure the key starts with `sk-proj-` or `sk-`

### "Internal Server Error" on /match endpoint
- Make sure all 3 variables are set
- Check Railway logs: Click service → Logs tab

### No quotes returned
- Data might not be uploaded to Supabase
- Check Supabase Table Editor for "passages" table
- Should have ~2,160 rows

### Railway not redeploying
- Go to Deployments tab
- Click "Deploy" manually

---

## Success Checklist

- ✅ OpenAI API key obtained
- ✅ Supabase project created
- ✅ Supabase credentials obtained
- ✅ All 3 variables set in Railway
- ✅ Railway redeployed successfully
- ✅ Health endpoint returns healthy
- ✅ Quote endpoint returns quotes
- ✅ Data uploaded to Supabase (2,160 passages)

---

🏛️ **May wisdom guide your deployment!**
