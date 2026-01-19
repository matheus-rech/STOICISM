# Stoic Companion Knowledge Base Design

## Executive Summary

This document synthesizes research from three specialized agents to define a RAG-ready knowledge base for personalized Stoic philosophy delivery. The system enables:

1. **"Meet Your Stoic" matching** - Align users with philosophers based on life experiences
2. **Contextual wisdom delivery** - Select quotes based on HealthKit data + time + situation
3. **Progressive philosopher discovery** - Introduce new philosophers during the user journey

---

## Data Schema

### 1. Philosophers Collection

```typescript
interface Philosopher {
  id: string;                          // "marcus_aurelius" | "epictetus" | "seneca" | "musonius_rufus" | "cato"
  name: string;                        // "Marcus Aurelius"
  epithet: string;                     // "The Philosopher King"
  lifespan: string;                    // "121-180 CE"

  // Biographical Data
  biography: {
    birthContext: string;              // "Born in Rome to a prominent family..."
    formativeExperiences: string[];    // ["Adopted by Emperor Antoninus Pius at 17", ...]
    majorChallenges: string[];         // ["Germanic invasions", "Devastating plague", ...]
    death: string;                     // How they died (important for Stoics)
    occupation: string;                // "Roman Emperor"
  };

  // Personality Profile (for matching)
  personality: {
    teachingStyle: string;             // "Personal, introspective, self-correcting"
    communicationStyle: string;        // "Private journal entries, vivid imagery"
    temperament: string;               // "Self-critical, duty-bound, struggled with anger"
    strengths: string[];               // ["Humility", "Self-awareness", "Persistence"]
    flaws: string[];                   // ["Irritability", "Anxiety about mortality"]
  };

  // Key Struggles (for user matching)
  struggles: string[];                 // ["anger", "mortality", "responsibility", "power"]

  // Matching Criteria
  matchingProfile: {
    bestFor: string[];                 // ["Leaders and managers", "Those feeling overwhelmed"]
    lifeSituations: string[];          // ["High-pressure careers", "Leadership roles"]
    personalityTypes: string[];        // ["Conscientious", "Self-reflective", "Duty-oriented"]
    primaryThemes: string[];           // ["duty", "mortality", "resilience", "anger_management"]
  };

  // Voice Guidelines (for AI-generated responses in their style)
  voiceGuidelines: {
    perspective: string;               // "First person, introspective"
    tone: string;                      // "Self-questioning and self-correcting"
    characteristics: string[];         // ["Brief memorable phrases", "Cosmic perspective"]
    avoidances: string[];              // What NOT to do in their voice
  };

  // Primary Works
  works: WorkReference[];

  // Representative Quotes (5-7 that exemplify their character)
  signatureQuotes: SignatureQuote[];

  // Unlock Criteria
  unlockCriteria: {
    isDefault: boolean;                // true for Marcus Aurelius
    triggerConditions: string[];       // ["User shows interest in time management", ...]
    minimumDaysInApp?: number;         // Optional: require N days before unlock
  };
}

interface WorkReference {
  id: string;                          // "meditations"
  title: string;                       // "Meditations"
  latinTitle?: string;                 // "Ta eis heauton"
  structure: string;                   // "12 books of personal reflections"
  dateWritten: string;                 // "167-180 CE"
  themes: string[];                    // ["Self-discipline", "Acceptance", "Duty"]
  wordCount: number;                   // 50000
  publicDomainTranslation: {
    translator: string;                // "George Long"
    year: number;                      // 1862
    sourceUrl: string;                 // "https://standardebooks.org/..."
  };
}

interface SignatureQuote {
  text: string;
  source: string;                      // "Meditations, Book X"
  significance: string;                // Why this quote reveals their character
}
```

### 2. Passages Collection (RAG Content)

```typescript
interface Passage {
  id: string;                          // UUID or hash

  // Source Information
  source: {
    philosopherId: string;             // "marcus_aurelius"
    workId: string;                    // "meditations"
    book?: number;                     // 2
    chapter?: number;                  // 1
    letter?: number;                   // For Seneca's letters
    lineReference?: string;            // "2.1.1-3"
  };

  // Content
  content: {
    text: string;                      // The actual passage
    translation: string;               // "George Long (1862)"
    originalLanguage: "Greek" | "Latin";
    wordCount: number;
  };

  // Semantic Tags (from taxonomy)
  tags: {
    primaryConcepts: string[];         // ["dichotomy_of_control", "acceptance"]
    virtues: string[];                 // ["wisdom", "courage"]
    practices: string[];               // ["premeditatio_malorum"]
    situations: string[];              // ["difficult_people", "leadership"]
    emotions: string[];                // ["anger", "anxiety"]
  };

  // HealthKit Mapping
  healthContext: {
    stressLevels: ("low" | "normal" | "elevated" | "high")[];
    activityStates: ("active" | "sedentary" | "recovery")[];
    timesOfDay: ("morning" | "midday" | "evening" | "night")[];
  };

  // User Journey Mapping
  journeyContext: {
    stages: ("newcomer" | "building_habits" | "deepening" | "crisis")[];
    difficulty: "beginner" | "intermediate" | "advanced";
  };

  // Vector Embedding (for RAG)
  embedding?: number[];                // Generated by embedding model

  // Metadata
  metadata: {
    quotability: number;               // 1-10: How well it stands alone
    actionability: number;             // 1-10: How practical/applicable
    comfort: number;                   // 1-10: How soothing vs challenging
    popularity?: number;               // Based on usage analytics
  };
}
```

### 3. User Profile Collection

```typescript
interface UserProfile {
  id: string;

  // Onboarding Assessment Results
  onboarding: {
    completedAt: Date;
    responses: OnboardingResponse[];
    matchedPhilosopherId: string;      // Primary matched philosopher
    matchScores: {                     // Scores for all philosophers
      [philosopherId: string]: number; // 0-100
    };
  };

  // Life Context (from onboarding)
  lifeContext: {
    primaryStruggles: string[];        // ["anger", "time_management"]
    lifeSituation: string;             // "leadership_role"
    learningStyle: string;             // "practical" | "theoretical" | "storytelling"
    personalityTraits: string[];       // From assessment
  };

  // Unlocked Philosophers
  unlockedPhilosophers: {
    philosopherId: string;
    unlockedAt: Date;
    unlockedReason: string;            // "User showed interest in anger management"
  }[];

  // Journey Progress
  journey: {
    stage: "newcomer" | "building_habits" | "deepening" | "mastery";
    daysActive: number;
    passagesViewed: number;
    favoritedPassages: string[];       // Passage IDs
  };

  // Health Patterns (aggregated from HealthKit)
  healthPatterns?: {
    typicalMorningHRV: number;
    averageStressLevel: string;
    activeHours: string[];             // ["07:00", "18:00"]
  };
}

interface OnboardingResponse {
  questionId: string;
  questionText: string;
  selectedOption: string;
  philosopherWeights: {                // How this answer affects matching
    [philosopherId: string]: number;   // -10 to +10
  };
}
```

### 4. Onboarding Questions Collection

```typescript
interface OnboardingQuestion {
  id: string;
  order: number;

  // Question Content
  question: string;                    // "When things go wrong, do you..."
  category: string;                    // "control_orientation" | "life_situation" | "learning_style"

  // Options
  options: {
    id: string;
    text: string;                      // "Focus on fixing what I can control"
    philosopherWeights: {
      marcus_aurelius: number;         // 5
      epictetus: number;               // 10
      seneca: number;                  // 3
      musonius_rufus: number;          // 7
      cato: number;                    // 0
    };
    tags: string[];                    // Tags this answer implies about user
  }[];
}
```

---

## Onboarding Questions Design

### Question Set (8-10 questions, ~2 minutes)

#### 1. Control Orientation
**"When faced with a problem I cannot solve, I tend to..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Accept it and focus elsewhere | +3 | +10 | +5 | +7 | 0 |
| Keep trying different approaches | +5 | +3 | +8 | +5 | +7 |
| Analyze why it happened | +7 | +5 | +10 | +3 | +3 |
| Stand firm on principle regardless | +3 | +5 | 0 | +5 | +10 |

#### 2. Life Situation
**"My biggest daily challenge is..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Managing people and responsibilities | +10 | +3 | +5 | +3 | +5 |
| Dealing with circumstances beyond my control | +3 | +10 | +5 | +5 | +3 |
| Finding time for what matters | +5 | +3 | +10 | +5 | +3 |
| Living simply in a complex world | +3 | +5 | +3 | +10 | +5 |

#### 3. Emotional Struggle
**"The emotion I struggle with most is..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Anger or frustration | +7 | +5 | +10 | +5 | +3 |
| Anxiety about the future | +5 | +10 | +7 | +3 | +3 |
| Fear of death or loss | +10 | +5 | +8 | +5 | +7 |
| Feeling overwhelmed by duties | +10 | +3 | +5 | +5 | +5 |

#### 4. Learning Preference
**"I learn best through..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Personal reflection and journaling | +10 | +5 | +7 | +3 | +3 |
| Direct, challenging instruction | +3 | +10 | +5 | +7 | +5 |
| Conversational wisdom and stories | +5 | +5 | +10 | +3 | +3 |
| Practical exercises and habits | +5 | +7 | +5 | +10 | +5 |

#### 5. Background Experience
**"In my life, I've experienced..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Positions of power or leadership | +10 | +3 | +7 | +3 | +5 |
| Feeling trapped or powerless | +3 | +10 | +5 | +5 | +5 |
| Success followed by setbacks | +5 | +5 | +10 | +5 | +5 |
| Standing alone for my beliefs | +5 | +5 | +3 | +7 | +10 |

#### 6. Communication Style Preference
**"I prefer wisdom that is..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Gentle and self-reflective | +10 | +3 | +7 | +5 | +0 |
| Direct and challenging | +3 | +10 | +3 | +7 | +7 |
| Warm and conversational | +5 | +3 | +10 | +5 | +0 |
| No-nonsense and practical | +3 | +7 | +5 | +10 | +5 |

#### 7. Values Priority
**"What matters most to me is..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Fulfilling my duties well | +10 | +5 | +5 | +7 | +5 |
| Inner freedom and peace | +5 | +10 | +7 | +5 | +3 |
| Meaningful relationships | +5 | +5 | +10 | +5 | +3 |
| Living with integrity | +5 | +7 | +5 | +7 | +10 |

#### 8. Life Phase
**"I would describe my current life phase as..."**
| Option | Marcus | Epictetus | Seneca | Musonius | Cato |
|--------|--------|-----------|--------|----------|------|
| Carrying heavy responsibilities | +10 | +5 | +5 | +5 | +5 |
| Rebuilding after difficulties | +5 | +10 | +7 | +5 | +5 |
| Seeking more meaning and purpose | +7 | +7 | +10 | +7 | +5 |
| Simplifying and focusing | +5 | +5 | +5 | +10 | +7 |

---

## Matching Algorithm

```typescript
function calculatePhilosopherMatch(responses: OnboardingResponse[]): MatchResult {
  const scores: Record<string, number> = {
    marcus_aurelius: 0,
    epictetus: 0,
    seneca: 0,
    musonius_rufus: 0,
    cato: 0
  };

  // Sum weighted scores from all responses
  for (const response of responses) {
    const weights = response.philosopherWeights;
    for (const [philosopher, weight] of Object.entries(weights)) {
      scores[philosopher] += weight;
    }
  }

  // Normalize to 0-100
  const maxPossible = responses.length * 10; // Max score per question
  const normalized = Object.fromEntries(
    Object.entries(scores).map(([p, s]) => [p, Math.round((s / maxPossible) * 100)])
  );

  // Find primary match
  const sorted = Object.entries(normalized).sort((a, b) => b[1] - a[1]);
  const primaryMatch = sorted[0][0];

  // Calculate confidence (gap between top two)
  const confidence = sorted[0][1] - sorted[1][1];

  return {
    primaryMatch,
    scores: normalized,
    confidence,
    secondaryRecommendations: sorted.slice(1, 3).map(([p]) => p)
  };
}
```

---

## HealthKit → Theme Mapping Rules

```typescript
interface HealthContext {
  heartRate: number;
  hrv: number;                         // Heart Rate Variability (RMSSD)
  stepsToday: number;
  isActive: boolean;
  timeOfDay: "morning" | "midday" | "evening" | "night";
}

function mapHealthToThemes(health: HealthContext): ThemeSelection {
  const themes: string[] = [];
  const authorPriority: string[] = [];
  let tone: string;

  // Stress level assessment
  const stressLevel = assessStress(health.hrv, health.heartRate);

  // High Stress
  if (stressLevel === "high") {
    themes.push("dichotomy_of_control", "inner_citadel", "acceptance");
    authorPriority.push("epictetus", "marcus_aurelius");
    tone = "calming_supportive";
  }
  // Elevated Stress
  else if (stressLevel === "elevated") {
    if (health.timeOfDay === "morning") {
      themes.push("premeditatio_malorum", "preparation", "courage");
      authorPriority.push("seneca", "marcus_aurelius");
      tone = "strengthening";
    } else {
      themes.push("reflection", "acceptance", "letting_go");
      authorPriority.push("marcus_aurelius", "seneca");
      tone = "calming";
    }
  }
  // Normal/Relaxed
  else {
    if (health.timeOfDay === "morning") {
      themes.push("purpose", "virtue", "action", "gratitude");
      authorPriority.push("marcus_aurelius", "epictetus");
      tone = "inspiring";
    } else if (health.timeOfDay === "evening") {
      themes.push("gratitude", "reflection", "relationships", "contentment");
      authorPriority.push("seneca", "marcus_aurelius");
      tone = "reflective";
    } else if (health.timeOfDay === "night") {
      themes.push("acceptance", "peace", "memento_mori", "nature");
      authorPriority.push("marcus_aurelius");
      tone = "peaceful";
    } else {
      themes.push("focus", "patience", "perspective", "duty");
      authorPriority.push("marcus_aurelius", "epictetus");
      tone = "grounding";
    }
  }

  // Activity modifier
  if (health.isActive) {
    themes.push("courage", "endurance", "strength");
    authorPriority.unshift("marcus_aurelius");
    tone = "energizing";
  }

  return { themes, authorPriority, tone };
}

function assessStress(hrv: number, hr: number): "low" | "normal" | "elevated" | "high" {
  // Based on research: lower HRV = higher stress
  if (hrv < 50 && hr > 85) return "high";
  if (hrv < 65 || hr > 80) return "elevated";
  if (hrv > 80 && hr < 65) return "low";
  return "normal";
}
```

---

## Progressive Philosopher Unlocking

### Default State
- **Marcus Aurelius**: Available immediately (default philosopher)
- All others: Locked

### Unlock Triggers

| Philosopher | Unlock Conditions |
|-------------|-------------------|
| **Seneca** | User views 5+ passages tagged "anger" OR 5+ passages tagged "time" OR 20 days in app |
| **Epictetus** | User views 5+ passages tagged "control" OR reports feeling "trapped" OR 15 days in app |
| **Musonius Rufus** | User reaches "deepening" stage (90+ days) OR views 5+ passages tagged "practical" |
| **Cato** | User views 5+ passages tagged "integrity" OR "courage" OR 120 days in app |

### Unlock Notification
When a philosopher unlocks, present a "discovery" moment:

```swift
struct PhilosopherUnlockView: View {
  let philosopher: Philosopher

  var body: some View {
    VStack {
      Text("A New Voice Emerges")
        .font(.headline)

      Text(philosopher.epithet)
        .font(.title2)
        .bold()

      Text(philosopher.name)
        .font(.title)

      Text(philosopher.biography.birthContext)
        .font(.body)
        .multilineTextAlignment(.center)

      // Show a signature quote
      QuoteView(quote: philosopher.signatureQuotes[0])

      Button("Begin Learning") {
        // Set as active philosopher option
      }
    }
  }
}
```

---

## RAG Query Strategy

### Query Flow

```
1. User requests wisdom
   │
   ▼
2. Build context object:
   - HealthKit data (HR, HRV, steps, activity)
   - Time of day
   - User's matched philosopher
   - User's journey stage
   - Recent passage history (avoid repeats)
   │
   ▼
3. Map context to themes (using rules above)
   │
   ▼
4. Vector search with filters:
   - Filter by user's unlocked philosophers
   - Filter by appropriate difficulty level
   - Filter by mapped themes
   - Boost passages from matched philosopher
   │
   ▼
5. Re-rank results:
   - Prefer passages not recently shown
   - Prefer higher quotability scores
   - Match tone to current state
   │
   ▼
6. Return top passage with context
```

### Example Query Construction

```typescript
async function selectPassage(userContext: UserContext): Promise<Passage> {
  const themeSelection = mapHealthToThemes(userContext.health);

  const query = buildSemanticQuery(
    userContext.currentFeeling,        // Optional: "I'm feeling overwhelmed"
    themeSelection.themes
  );

  const filters = {
    philosopherId: { $in: userContext.unlockedPhilosophers },
    "journeyContext.difficulty": {
      $lte: mapStageToDifficulty(userContext.journey.stage)
    },
    "tags.primaryConcepts": { $in: themeSelection.themes },
    id: { $nin: userContext.recentlyShownPassages }
  };

  const boosts = {
    philosopherId: {
      [userContext.matchedPhilosopher]: 1.5  // Boost primary philosopher
    }
  };

  const results = await vectorDB.query({
    embedding: await embed(query),
    filters,
    boosts,
    limit: 5
  });

  // Re-rank by quotability and tone match
  return rerank(results, themeSelection.tone)[0];
}
```

---

## Primary Source URLs (Ready for Ingestion)

| Source | URL | Format | Priority |
|--------|-----|--------|----------|
| Meditations (Long) | https://standardebooks.org/ebooks/marcus-aurelius/meditations/george-long | EPUB/Text | Tier 1 |
| Enchiridion | https://classics.mit.edu/Epictetus/epicench.html | HTML | Tier 1 |
| Discourses | https://standardebooks.org/ebooks/epictetus/discourses/george-long | EPUB/Text | Tier 1 |
| Letters to Lucilius | https://en.wikisource.org/wiki/Moral_letters_to_Lucilius | HTML | Tier 1 |
| Seneca Dialogues | https://standardebooks.org/ebooks/seneca/dialogues/aubrey-stewart | EPUB/Text | Tier 2 |
| Musonius Rufus | https://archive.org/details/MUSONIUSRUFUSSTOICFRAGMENTS | PDF | Tier 3 |
| Life of Cato | https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Plutarch/Lives/Cato_Minor*.html | HTML | Tier 3 |

---

## Next Steps

1. **Set up backend infrastructure**
   - Choose vector database (Pinecone, Supabase pgvector, or Weaviate)
   - Set up API service (Cloudflare Workers, Vercel, or AWS Lambda)

2. **Ingest primary sources**
   - Download public domain translations
   - Chunk into passage-sized segments
   - Tag each passage with themes from taxonomy
   - Generate embeddings

3. **Build matching API**
   - Implement onboarding question flow
   - Calculate philosopher matches
   - Store user profiles

4. **Integrate with Watch app**
   - Add onboarding flow
   - Connect to backend API
   - Implement progressive unlocking UI

---

## Appendix: Philosopher Quick Reference

| Philosopher | Core Struggle | Best For | Teaching Style |
|-------------|---------------|----------|----------------|
| Marcus Aurelius | Duty, anger, mortality | Leaders, caregivers | Gentle, reflective |
| Epictetus | Control, freedom | Those feeling trapped | Direct, challenging |
| Seneca | Time, anger, fear | Busy professionals | Warm, psychological |
| Musonius Rufus | Simple living, discipline | Minimalists, practical | No-nonsense, austere |
| Cato | Integrity, resistance | Ethical dilemmas | By example, principled |
