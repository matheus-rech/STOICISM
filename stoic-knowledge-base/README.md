# Stoic Knowledge Base

A RAG (Retrieval-Augmented Generation) knowledge base of Stoic philosophy for the Stoic Companion Apple Watch app.

## Live API ✅

**Production URL**: https://stoicism-production.up.railway.app

```bash
# Health check
curl https://stoicism-production.up.railway.app/health
# {"status":"healthy","version":"1.0.0"}

# Get contextual quote
curl -X POST https://stoicism-production.up.railway.app/quote \
  -H "Content-Type: application/json" \
  -d '{"context": {"stress_level": "elevated", "time_of_day": "morning"}, "query": "dealing with anxiety"}'
```

## Features

- **2,160 passages** from Marcus Aurelius, Epictetus, and Seneca
- **Vector embeddings** for semantic search (1,536 dimensions)
- **AI-powered tagging** with concepts, emotions, situations, and health contexts
- **Philosopher matching** algorithm for "Meet Your Stoic" feature
- **Health context awareness** - stress levels, time of day, activity states

## Data Pipeline

```
┌─────────────┐    ┌──────────┐    ┌──────────┐    ┌────────────┐    ┌──────────┐
│   Ingest    │───▶│  Chunk   │───▶│   Tag    │───▶│  Embed     │───▶│ Database │
│  (sources)  │    │ (passages)│   │  (AI)    │    │ (vectors)  │    │ (Supabase)│
└─────────────┘    └──────────┘    └──────────┘    └────────────┘    └──────────┘
```

## Quick Start

### 1. Install Dependencies

```bash
cd stoic-knowledge-base
pip install -r requirements.txt
```

### 2. Set Environment Variables

```bash
export OPENAI_API_KEY="your-key"
export SUPABASE_URL="your-project-url"
export SUPABASE_SERVICE_ROLE_KEY="your-service-key"
```

### 3. Process Texts (Already Done)

The data is already processed and available in `/data`:

- `data/raw/` - Original texts from Project Gutenberg
- `data/processed/` - Chunked and tagged passages
- `data/embeddings/` - Passages with vector embeddings
- `data/philosophers.json` - Philosopher profiles

### 4. Set Up Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Run `database/schema.sql` in SQL Editor
3. Upload data:

```bash
python database/upload_to_supabase.py \
  --url YOUR_SUPABASE_URL \
  --key YOUR_SERVICE_ROLE_KEY
```

### 5. Start API

```bash
cd api
uvicorn stoic_api:app --reload
```

## API Endpoints

### Get Contextual Quote

```http
POST /quote
Content-Type: application/json

{
  "context": {
    "stress_level": "elevated",
    "time_of_day": "evening",
    "heart_rate": 85,
    "is_active": false
  },
  "philosopher_id": null,  // Optional: filter by philosopher
  "query": null  // Optional: semantic query
}
```

Response:
```json
{
  "id": "meditations_abc123",
  "text": "Begin each day by telling yourself...",
  "philosopher": "Marcus Aurelius",
  "work": "Meditations",
  "tags": {
    "primary_concepts": ["premeditatio_malorum"],
    "situations": ["morning_routine"],
    "emotions": ["anxiety"]
  },
  "similarity": 0.85
}
```

### Match Philosopher

```http
POST /match
Content-Type: application/json

{
  "user_id": "user123",
  "answers": [
    {"question_id": "life_stage", "answer": "mid-career professional"},
    {"question_id": "challenge", "answer": "work-life balance"},
    {"question_id": "approach", "answer": "practical advice"}
  ]
}
```

## Data Schema

### Passage

```python
{
  "id": "meditations_abc123",
  "philosopher_id": "marcus_aurelius",
  "work_id": "meditations",
  "text": "The passage text...",
  "embedding": [0.023, 0.015, ...],  # 1536 dimensions
  "tags": {
    "primary_concepts": ["dichotomy_of_control"],
    "virtues": ["wisdom"],
    "practices": ["morning_reflection"],
    "situations": ["difficult_people"],
    "emotions": ["anger", "frustration"]
  },
  "health_context": {
    "stress_levels": ["elevated", "high"],
    "times_of_day": ["morning", "evening"]
  },
  "difficulty": "beginner",
  "quotability": 8,
  "actionability": 7,
  "comfort": 6
}
```

### Philosopher Profile

```python
{
  "id": "marcus_aurelius",
  "name": "Marcus Aurelius",
  "era": "121-180 CE",
  "biography": "Roman Emperor and philosopher...",
  "teaching_style": "Gentle self-reminder...",
  "core_themes": ["duty", "impermanence", "inner citadel"],
  "personality_traits": ["gentle", "introspective"],
  "matching_criteria": ["leadership", "responsibility", "public life"],
  "voice_guidelines": {
    "tone": "gentle and introspective",
    "phrases": ["remember that...", "consider that..."]
  }
}
```

## Taxonomy

### Primary Concepts
- `dichotomy_of_control` - What is/isn't in our power
- `inner_citadel` - Fortress of the mind
- `premeditatio_malorum` - Negative visualization
- `memento_mori` - Remembering death
- `amor_fati` - Love of fate
- `impermanence` - Everything changes
- `present_moment` - Focus on now
- `living_according_to_nature` - Rational living

### Emotions Addressed
- `anger`, `fear`, `anxiety`, `grief`
- `joy`, `frustration`, `peace`

### Life Situations
- `difficult_people`, `anger_management`, `anxiety`
- `grief`, `failure`, `success`, `leadership`
- `health_challenges`, `time_management`, `finding_purpose`

## Scripts

| Script | Purpose | Cost |
|--------|---------|------|
| `ingest_sources.py` | Download texts | Free |
| `chunk_passages.py` | Split into passages | Free |
| `tag_rules.py` | Rule-based tagging | Free |
| `tag_openai.py` | AI tagging (GPT-4o-mini) | ~$0.15 |
| `generate_embeddings.py` | Vector embeddings | ~$0.10 |

## Directory Structure

```
stoic-knowledge-base/
├── scripts/
│   ├── models.py           # Pydantic data models
│   ├── ingest_sources.py   # Download texts
│   ├── chunk_passages.py   # Create passages
│   ├── tag_rules.py        # Free tagging
│   ├── tag_openai.py       # AI tagging
│   └── generate_embeddings.py
├── data/
│   ├── raw/                # Original texts
│   ├── processed/          # Tagged passages
│   ├── embeddings/         # With vectors
│   └── philosophers.json   # Philosopher profiles
├── database/
│   ├── schema.sql          # Supabase schema
│   └── upload_to_supabase.py
├── api/
│   └── stoic_api.py        # FastAPI service
└── requirements.txt
```

## Integration with Watch App

The Watch app is now integrated with this RAG API via `RAGService.swift`:

```swift
// Config.swift
static let ragAPIEndpoint = "https://stoicism-production.up.railway.app"
static let useRAGAPI = true
static let ragFallbackToLLM = true
```

**Quote retrieval priority:**
1. **RAG API** (Primary) - Semantic search across 2,160 passages
2. **LLM Service** (Fallback) - Gemini/Claude/OpenAI quote selection
3. **Local JSON** (Final fallback) - 30+ embedded quotes

See the main [KNOWLEDGE_BASE_DESIGN.md](../StoicCompanion/KNOWLEDGE_BASE_DESIGN.md) for:
- Swift models matching this schema
- HealthKit → stress level mapping
- Onboarding flow questions
- Progressive philosopher unlocking

## License

The Stoic texts are public domain. The processing code is MIT licensed.
