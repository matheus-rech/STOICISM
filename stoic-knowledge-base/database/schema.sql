-- Stoic Knowledge Base Schema for Supabase
-- Run this in Supabase SQL Editor

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Philosophers table
CREATE TABLE philosophers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    era TEXT,
    biography TEXT,
    teaching_style TEXT,
    core_themes TEXT[],
    personality_traits TEXT[],
    voice_guidelines JSONB,
    signature_quotes TEXT[],
    unlock_criteria JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Passages table (main content)
CREATE TABLE passages (
    id TEXT PRIMARY KEY,
    philosopher_id TEXT REFERENCES philosophers(id),
    work_id TEXT NOT NULL,
    book INT,
    chapter INT,
    letter INT,
    section TEXT,
    text TEXT NOT NULL,
    embedding VECTOR(1536),  -- OpenAI text-embedding-3-small

    -- Tags (JSONB for flexibility)
    tags JSONB DEFAULT '{}'::JSONB,

    -- Context
    health_context JSONB DEFAULT '{}'::JSONB,
    journey_context JSONB DEFAULT '{}'::JSONB,

    -- Scores
    difficulty TEXT DEFAULT 'beginner',
    quotability INT DEFAULT 5,
    actionability INT DEFAULT 5,
    comfort INT DEFAULT 5,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profiles for matching
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT UNIQUE NOT NULL,  -- From your auth system
    matched_philosopher_id TEXT REFERENCES philosophers(id),
    onboarding_answers JSONB DEFAULT '{}'::JSONB,
    preferences JSONB DEFAULT '{}'::JSONB,
    unlocked_philosophers TEXT[] DEFAULT ARRAY['marcus_aurelius'],
    journey_stats JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Interaction log for learning
CREATE TABLE interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    passage_id TEXT REFERENCES passages(id),
    philosopher_id TEXT REFERENCES philosophers(id),
    action TEXT NOT NULL,  -- 'viewed', 'saved', 'shared', 'dismissed'
    context JSONB,  -- Health context at time of interaction
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Vector similarity search index (IVFFlat for faster queries)
CREATE INDEX passages_embedding_idx ON passages
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Filter indexes
CREATE INDEX passages_philosopher_idx ON passages(philosopher_id);
CREATE INDEX passages_work_idx ON passages(work_id);
CREATE INDEX passages_difficulty_idx ON passages(difficulty);
CREATE INDEX passages_quotability_idx ON passages(quotability);

-- GIN index for JSONB tag searches
CREATE INDEX passages_tags_idx ON passages USING GIN(tags);
CREATE INDEX passages_health_context_idx ON passages USING GIN(health_context);

-- User indexes
CREATE INDEX user_profiles_user_id_idx ON user_profiles(user_id);
CREATE INDEX interactions_user_id_idx ON interactions(user_id);
CREATE INDEX interactions_passage_id_idx ON interactions(passage_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Semantic search function
CREATE OR REPLACE FUNCTION match_passages(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 10,
    filter_philosopher TEXT DEFAULT NULL,
    filter_difficulty TEXT DEFAULT NULL,
    filter_stress_levels TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    philosopher_id TEXT,
    work_id TEXT,
    text TEXT,
    tags JSONB,
    difficulty TEXT,
    quotability INT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.philosopher_id,
        p.work_id,
        p.text,
        p.tags,
        p.difficulty,
        p.quotability,
        1 - (p.embedding <=> query_embedding) AS similarity
    FROM passages p
    WHERE
        (filter_philosopher IS NULL OR p.philosopher_id = filter_philosopher)
        AND (filter_difficulty IS NULL OR p.difficulty = filter_difficulty)
        AND (filter_stress_levels IS NULL OR
             p.health_context->'stress_levels' ?| filter_stress_levels)
        AND (1 - (p.embedding <=> query_embedding)) > match_threshold
    ORDER BY p.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Get contextual quotes (combines semantic search with filtering)
CREATE OR REPLACE FUNCTION get_contextual_quote(
    query_embedding VECTOR(1536),
    stress_level TEXT DEFAULT 'normal',
    time_of_day TEXT DEFAULT 'morning',
    user_philosopher TEXT DEFAULT NULL,
    avoid_passage_ids TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    philosopher_id TEXT,
    text TEXT,
    tags JSONB,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.philosopher_id,
        p.text,
        p.tags,
        1 - (p.embedding <=> query_embedding) AS similarity
    FROM passages p
    WHERE
        (user_philosopher IS NULL OR p.philosopher_id = user_philosopher)
        AND (avoid_passage_ids IS NULL OR NOT (p.id = ANY(avoid_passage_ids)))
        AND (
            p.health_context->'stress_levels' ? stress_level
            OR p.health_context->'stress_levels' ? 'normal'
        )
        AND (
            p.health_context->'times_of_day' ? time_of_day
            OR jsonb_array_length(p.health_context->'times_of_day') = 0
        )
    ORDER BY
        p.embedding <=> query_embedding,
        p.quotability DESC
    LIMIT 1;
END;
$$;

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE passages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;

-- Passages are publicly readable
CREATE POLICY "Passages are viewable by everyone"
ON passages FOR SELECT
USING (true);

-- Users can only access their own profile
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid()::TEXT = user_id);

-- Users can only access their own interactions
CREATE POLICY "Users can view own interactions"
ON interactions FOR SELECT
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert own interactions"
ON interactions FOR INSERT
WITH CHECK (auth.uid()::TEXT = user_id);
