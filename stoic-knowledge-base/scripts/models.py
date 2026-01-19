"""
Data models for the Stoic Knowledge Base.
Matches schema defined in KNOWLEDGE_BASE_DESIGN.md
"""

from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class PhilosopherId(str, Enum):
    MARCUS_AURELIUS = "marcus_aurelius"
    EPICTETUS = "epictetus"
    SENECA = "seneca"
    MUSONIUS_RUFUS = "musonius_rufus"
    CATO = "cato"


class WorkId(str, Enum):
    # Marcus Aurelius
    MEDITATIONS = "meditations"
    # Epictetus
    DISCOURSES = "discourses"
    ENCHIRIDION = "enchiridion"
    # Seneca
    LETTERS = "letters_to_lucilius"
    ON_ANGER = "on_anger"
    ON_SHORTNESS_OF_LIFE = "on_shortness_of_life"
    ON_TRANQUILITY = "on_tranquility_of_mind"
    ON_PROVIDENCE = "on_providence"
    ON_HAPPY_LIFE = "on_happy_life"
    # Musonius Rufus
    LECTURES = "lectures"
    # Cato (secondary)
    LIFE_OF_CATO = "life_of_cato"


class StressLevel(str, Enum):
    LOW = "low"
    NORMAL = "normal"
    ELEVATED = "elevated"
    HIGH = "high"


class ActivityState(str, Enum):
    ACTIVE = "active"
    SEDENTARY = "sedentary"
    RECOVERY = "recovery"


class TimeOfDay(str, Enum):
    MORNING = "morning"
    MIDDAY = "midday"
    EVENING = "evening"
    NIGHT = "night"


class JourneyStage(str, Enum):
    NEWCOMER = "newcomer"
    BUILDING_HABITS = "building_habits"
    DEEPENING = "deepening"
    CRISIS = "crisis"


class Difficulty(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


# ============================================================================
# Source Information
# ============================================================================

class SourceInfo(BaseModel):
    """Where the passage comes from"""
    philosopher_id: PhilosopherId
    work_id: WorkId
    book: Optional[int] = None
    chapter: Optional[int] = None
    letter: Optional[int] = None
    section: Optional[str] = None
    line_reference: Optional[str] = None


class TranslationInfo(BaseModel):
    """Translation metadata"""
    translator: str
    year: int
    source_url: str
    license: str = "Public Domain"


# ============================================================================
# Tags (from Taxonomy)
# ============================================================================

class PassageTags(BaseModel):
    """Semantic tags for retrieval"""
    # Core concepts
    primary_concepts: list[str] = Field(default_factory=list)
    # Cardinal virtues
    virtues: list[str] = Field(default_factory=list)
    # Stoic practices
    practices: list[str] = Field(default_factory=list)
    # Life situations
    situations: list[str] = Field(default_factory=list)
    # Emotions addressed
    emotions: list[str] = Field(default_factory=list)


class HealthContext(BaseModel):
    """HealthKit mapping for passage selection"""
    stress_levels: list[StressLevel] = Field(default_factory=list)
    activity_states: list[ActivityState] = Field(default_factory=list)
    times_of_day: list[TimeOfDay] = Field(default_factory=list)


class JourneyContext(BaseModel):
    """User journey mapping"""
    stages: list[JourneyStage] = Field(default_factory=list)
    difficulty: Difficulty = Difficulty.BEGINNER


class PassageMetadata(BaseModel):
    """Quality and usage metrics"""
    quotability: int = Field(ge=1, le=10, default=5)  # Stands alone well
    actionability: int = Field(ge=1, le=10, default=5)  # Practical/applicable
    comfort: int = Field(ge=1, le=10, default=5)  # Soothing (10) vs challenging (1)
    word_count: int = 0
    character_count: int = 0


# ============================================================================
# Main Passage Model
# ============================================================================

class Passage(BaseModel):
    """
    A single passage from a Stoic text, ready for RAG.

    This is the core unit of the knowledge base - a meaningful
    chunk of wisdom that can be retrieved and presented to users.
    """
    id: str  # UUID or content hash

    # Source
    source: SourceInfo
    translation: TranslationInfo

    # Content
    text: str
    text_normalized: Optional[str] = None  # Lowercase, no punctuation (for search)

    # Semantic Tags
    tags: PassageTags = Field(default_factory=PassageTags)

    # Context Mapping
    health_context: HealthContext = Field(default_factory=HealthContext)
    journey_context: JourneyContext = Field(default_factory=JourneyContext)

    # Metadata
    metadata: PassageMetadata = Field(default_factory=PassageMetadata)

    # Vector Embedding (populated later)
    embedding: Optional[list[float]] = None

    def __str__(self) -> str:
        return f"[{self.source.philosopher_id.value}] {self.text[:80]}..."


# ============================================================================
# Philosopher Profile
# ============================================================================

class Biography(BaseModel):
    birth_context: str
    formative_experiences: list[str]
    major_challenges: list[str]
    death: str
    occupation: str


class Personality(BaseModel):
    teaching_style: str
    communication_style: str
    temperament: str
    strengths: list[str]
    flaws: list[str]


class MatchingProfile(BaseModel):
    best_for: list[str]
    life_situations: list[str]
    personality_types: list[str]
    primary_themes: list[str]


class VoiceGuidelines(BaseModel):
    perspective: str
    tone: str
    characteristics: list[str]
    avoidances: list[str] = Field(default_factory=list)


class SignatureQuote(BaseModel):
    text: str
    source: str
    significance: str


class UnlockCriteria(BaseModel):
    is_default: bool = False
    trigger_conditions: list[str] = Field(default_factory=list)
    minimum_days_in_app: Optional[int] = None


class Philosopher(BaseModel):
    """Complete philosopher profile for matching and voice"""
    id: PhilosopherId
    name: str
    epithet: str
    lifespan: str

    biography: Biography
    personality: Personality
    struggles: list[str]
    matching_profile: MatchingProfile
    voice_guidelines: VoiceGuidelines
    signature_quotes: list[SignatureQuote]
    unlock_criteria: UnlockCriteria


# ============================================================================
# Taxonomy Constants
# ============================================================================

# Primary Concepts (from research)
PRIMARY_CONCEPTS = [
    "dichotomy_of_control",
    "inner_citadel",
    "premeditatio_malorum",
    "memento_mori",
    "amor_fati",
    "prosoche",
    "view_from_above",
    "living_according_to_nature",
    "preferred_indifferents",
    "cosmopolitanism",
    "impermanence",
    "present_moment",
]

# Cardinal Virtues
VIRTUES = [
    "wisdom",
    "courage",
    "justice",
    "temperance",
]

# Practices
PRACTICES = [
    "negative_visualization",
    "morning_reflection",
    "evening_review",
    "journaling",
    "self_examination",
    "voluntary_discomfort",
]

# Life Situations
SITUATIONS = [
    "difficult_people",
    "anger_management",
    "anxiety",
    "grief",
    "failure",
    "success",
    "leadership",
    "relationships",
    "health_challenges",
    "career_transition",
    "time_management",
    "finding_purpose",
    "ethical_dilemma",
    "feeling_trapped",
    "overwhelm",
]

# Emotions
EMOTIONS = [
    "anger",
    "fear",
    "anxiety",
    "grief",
    "joy",
    "frustration",
    "envy",
    "regret",
    "hope",
    "peace",
]
