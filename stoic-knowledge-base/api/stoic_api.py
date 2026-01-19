"""
Stoic Knowledge Base API

FastAPI service for the Stoic Companion app.
Provides:
- Contextual quote retrieval (RAG)
- Philosopher matching
- User profile management

Run locally:
    uvicorn stoic_api:app --reload

Deploy to:
- Supabase Edge Functions
- Vercel
- Railway
- Fly.io
"""

import os
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from supabase import create_client, Client

# ============================================================================
# Configuration
# ============================================================================

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Initialize clients
supabase: Client = None
openai_client: OpenAI = None

app = FastAPI(
    title="Stoic Knowledge Base API",
    description="RAG-powered Stoic philosophy for the Stoic Companion app",
    version="1.0.0",
)

# CORS for Watch app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# Models
# ============================================================================

class HealthContext(BaseModel):
    heart_rate: Optional[float] = None
    hrv: Optional[float] = None
    stress_level: str = "normal"  # low, normal, elevated, high
    time_of_day: str = "morning"  # morning, midday, evening, night
    is_active: bool = False


class QuoteRequest(BaseModel):
    context: HealthContext
    user_id: Optional[str] = None
    philosopher_id: Optional[str] = None
    query: Optional[str] = None  # Optional semantic query


class QuoteResponse(BaseModel):
    id: str
    text: str
    philosopher: str
    work: str
    tags: dict
    similarity: Optional[float] = None


class OnboardingAnswer(BaseModel):
    question_id: str
    answer: str


class MatchRequest(BaseModel):
    user_id: str
    answers: list[OnboardingAnswer]


class MatchResponse(BaseModel):
    philosopher_id: str
    philosopher_name: str
    match_reason: str
    confidence: float


# ============================================================================
# Startup
# ============================================================================

@app.on_event("startup")
async def startup():
    global supabase, openai_client

    if not SUPABASE_URL or not SUPABASE_KEY:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required")

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    openai_client = OpenAI(api_key=OPENAI_API_KEY)


# ============================================================================
# Endpoints
# ============================================================================

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}


@app.post("/quote", response_model=QuoteResponse)
async def get_contextual_quote(request: QuoteRequest):
    """
    Get a contextual Stoic quote based on health data and optional semantic query.

    The algorithm:
    1. Generate embedding from context description (or query)
    2. Search passages with semantic similarity
    3. Filter by health context (stress level, time of day)
    4. Return top match
    """
    # Build context string for embedding
    context_parts = []

    if request.query:
        context_parts.append(request.query)
    else:
        # Build from health context
        stress_map = {
            "low": "feeling calm and peaceful",
            "normal": "normal day, looking for wisdom",
            "elevated": "feeling stressed and need perspective",
            "high": "very anxious and need calming guidance",
        }
        time_map = {
            "morning": "starting my day",
            "midday": "middle of my day",
            "evening": "reflecting on my day",
            "night": "ending my day, preparing to rest",
        }

        context_parts.append(stress_map.get(request.context.stress_level, ""))
        context_parts.append(time_map.get(request.context.time_of_day, ""))

        if request.context.is_active:
            context_parts.append("during exercise or activity")

    context_text = ", ".join(filter(None, context_parts))

    # Generate embedding
    try:
        embedding_response = openai_client.embeddings.create(
            model="text-embedding-3-small",
            input=context_text,
        )
        query_embedding = embedding_response.data[0].embedding
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding error: {e}")

    # Query Supabase with semantic search
    try:
        result = supabase.rpc(
            "match_passages",
            {
                "query_embedding": query_embedding,
                "match_threshold": 0.0,  # Low threshold since similarity scores are 0.2-0.4
                "match_count": 10,
            }
        ).execute()

        # Post-filter by philosopher if specified
        matches = result.data or []
        if request.philosopher_id and matches:
            matches = [m for m in matches if m["philosopher_id"] == request.philosopher_id]

        # Post-filter by stress level from health_context tags
        if matches:
            stress_filtered = [
                m for m in matches
                if request.context.stress_level in str(m.get("tags", {}).get("emotions", []))
                or "normal" in str(m.get("tags", {}))
            ]
            if stress_filtered:
                matches = stress_filtered

        result.data = matches[:5]  # Take top 5 after filtering

        if not result.data:
            raise HTTPException(status_code=404, detail="No matching quotes found")

        # Get top match
        top = result.data[0]

        return QuoteResponse(
            id=top["id"],
            text=top["text"],
            philosopher=top["philosopher_id"].replace("_", " ").title(),
            work=top["work_id"].replace("_", " ").title(),
            tags=top["tags"],
            similarity=top["similarity"],
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {e}")


@app.post("/match", response_model=MatchResponse)
async def match_philosopher(request: MatchRequest):
    """
    Match user with a philosopher based on onboarding answers.

    Uses the matching criteria defined in each philosopher profile.
    """
    # Get all philosophers
    result = supabase.table("philosophers").select("*").execute()
    philosophers = result.data

    # Score each philosopher
    scores = {}
    for p in philosophers:
        score = calculate_match_score(p, request.answers)
        scores[p["id"]] = {
            "score": score,
            "name": p["name"],
            "unlock_criteria": p.get("unlock_criteria", {}),
        }

    # Get best match
    best_id = max(scores, key=lambda x: scores[x]["score"])
    best = scores[best_id]

    # Generate match reason using OpenAI
    reason = await generate_match_reason(best_id, request.answers)

    # Save to user profile
    supabase.table("user_profiles").upsert({
        "user_id": request.user_id,
        "matched_philosopher_id": best_id,
        "onboarding_answers": [a.dict() for a in request.answers],
    }).execute()

    return MatchResponse(
        philosopher_id=best_id,
        philosopher_name=best["name"],
        match_reason=reason,
        confidence=best["score"],
    )


def calculate_match_score(philosopher: dict, answers: list[OnboardingAnswer]) -> float:
    """
    Calculate match score based on philosopher criteria and user answers.

    Scoring factors:
    - Life experience alignment
    - Preferred teaching style
    - Current challenges
    - Values alignment
    """
    score = 0.0
    criteria = philosopher.get("unlock_criteria", {})
    matching_criteria = criteria.get("matching_criteria", [])

    answer_map = {a.question_id: a.answer.lower() for a in answers}

    # Check each matching criterion
    for criterion in matching_criteria:
        criterion_lower = criterion.lower()

        # Match against answers
        for answer in answer_map.values():
            if any(word in answer for word in criterion_lower.split()):
                score += 1.0

    # Normalize score
    max_score = len(matching_criteria) if matching_criteria else 1
    return min(1.0, score / max_score)


async def generate_match_reason(philosopher_id: str, answers: list[OnboardingAnswer]) -> str:
    """Generate a personalized match reason using OpenAI."""
    try:
        # Get philosopher info
        result = supabase.table("philosophers").select("name, biography, core_themes").eq("id", philosopher_id).execute()
        philosopher = result.data[0] if result.data else {}

        prompt = f"""
Based on this user's answers:
{[f"- {a.question_id}: {a.answer}" for a in answers]}

And this philosopher:
- Name: {philosopher.get('name')}
- Biography: {philosopher.get('biography', '')[:200]}
- Core themes: {philosopher.get('core_themes', [])}

Write a brief, personal explanation (2-3 sentences) of why this philosopher
is a good match for this user. Be warm but not cheesy. Focus on shared
experiences or values.
"""

        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150,
            temperature=0.7,
        )

        return response.choices[0].message.content.strip()

    except Exception as e:
        # Fallback reason
        return f"Based on your experiences and values, {philosopher_id.replace('_', ' ').title()}'s teachings resonate with your journey."


@app.get("/philosophers")
async def list_philosophers():
    """Get all philosopher profiles."""
    result = supabase.table("philosophers").select(
        "id, name, era, biography, core_themes, teaching_style"
    ).execute()
    return {"philosophers": result.data}


@app.get("/user/{user_id}/profile")
async def get_user_profile(user_id: str):
    """Get user's profile including matched philosopher and unlocked philosophers."""
    result = supabase.table("user_profiles").select("*").eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    return result.data[0]


# ============================================================================
# Run
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
