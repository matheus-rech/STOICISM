#!/bin/bash
# Stoic Companion - Railway Environment Setup
# This script will help you configure the Railway API with required environment variables

set -e

echo "🏛️  STOIC COMPANION - Railway API Setup"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI not found${NC}"
    echo "Install it with: npm install -g @railway/cli"
    echo "Or visit: https://docs.railway.app/guides/cli"
    exit 1
fi

echo -e "${GREEN}✅ Railway CLI found${NC}"
echo ""

# Step 1: Login to Railway
echo "📝 Step 1: Login to Railway"
echo "This will open your browser for authentication..."
read -p "Press ENTER to continue..."
railway login

echo ""
echo -e "${GREEN}✅ Logged in to Railway${NC}"
echo ""

# Step 2: Link to project
echo "📝 Step 2: Link to your Railway project"
echo "Select 'stoicism-production' or your Stoic API project"
read -p "Press ENTER to continue..."
railway link

echo ""
echo -e "${GREEN}✅ Project linked${NC}"
echo ""

# Step 3: Collect credentials
echo "📝 Step 3: Enter your API credentials"
echo ""

echo "🔑 OpenAI API Key"
echo "   Get it from: https://platform.openai.com/api-keys"
echo -n "   Enter OPENAI_API_KEY (starts with sk-proj-...): "
read -s OPENAI_KEY
echo ""

if [ -z "$OPENAI_KEY" ]; then
    echo -e "${RED}❌ OpenAI API key is required${NC}"
    exit 1
fi

echo ""
echo "🗄️  Supabase Project URL"
echo "   Get it from: Supabase Dashboard → Settings → API"
echo -n "   Enter SUPABASE_URL (https://xxxxx.supabase.co): "
read SUPABASE_URL

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ Supabase URL is required${NC}"
    exit 1
fi

echo ""
echo "🔐 Supabase Service Role Key"
echo "   Get it from: Supabase Dashboard → Settings → API → service_role"
echo -n "   Enter SUPABASE_SERVICE_ROLE_KEY: "
read -s SUPABASE_KEY
echo ""

if [ -z "$SUPABASE_KEY" ]; then
    echo -e "${RED}❌ Supabase service role key is required${NC}"
    exit 1
fi

echo ""
echo "📝 Step 4: Setting environment variables on Railway..."

# Set variables
railway variables --set OPENAI_API_KEY="$OPENAI_KEY"
railway variables --set SUPABASE_URL="$SUPABASE_URL"
railway variables --set SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_KEY"

echo ""
echo -e "${GREEN}✅ Environment variables set!${NC}"
echo ""

echo "🔄 Railway is now redeploying your API..."
echo "This will take 1-2 minutes."
echo ""

# Optional: Upload data to Supabase if not done
echo "📊 Data Upload"
echo "Do you need to upload the Stoic passages to Supabase?"
read -p "Upload data now? (y/n): " UPLOAD_DATA

if [ "$UPLOAD_DATA" = "y" ] || [ "$UPLOAD_DATA" = "Y" ]; then
    echo ""
    echo "📤 Uploading data to Supabase..."

    # Check if Python script exists
    if [ -f "stoic-knowledge-base/database/upload_to_supabase.py" ]; then
        cd stoic-knowledge-base/database
        python3 upload_to_supabase.py --url "$SUPABASE_URL" --key "$SUPABASE_KEY"
        cd ../..
        echo -e "${GREEN}✅ Data uploaded successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Upload script not found. Upload data manually:${NC}"
        echo "   cd stoic-knowledge-base/database"
        echo "   python3 upload_to_supabase.py --url YOUR_URL --key YOUR_KEY"
    fi
fi

echo ""
echo "✨ Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Wait 1-2 minutes for Railway to redeploy"
echo "2. Test your API:"
echo ""
echo "   curl -X POST https://stoicism-production.up.railway.app/quote \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"context\": {\"stress_level\": \"elevated\", \"time_of_day\": \"morning\", \"is_active\": false}}'"
echo ""
echo "3. If it works, you should see a Stoic quote!"
echo ""
echo -e "${GREEN}🏛️  May wisdom guide your path!${NC}"
