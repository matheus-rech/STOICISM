"""
Rule-based passage tagging - FREE, no API needed.

Uses keyword matching and heuristics to tag passages based on our taxonomy.
Not as accurate as AI but instant and free.
"""

import json
import re
from pathlib import Path
from typing import Set

from rich.console import Console
from rich.progress import Progress

from models import (
    Passage,
    PassageTags,
    HealthContext,
    JourneyContext,
    StressLevel,
    TimeOfDay,
    JourneyStage,
    Difficulty,
)

console = Console()

# ============================================================================
# Keyword Rules
# ============================================================================

# Primary Concepts - keywords that indicate each concept
CONCEPT_KEYWORDS = {
    "dichotomy_of_control": [
        "control", "power over", "in our power", "not in our power",
        "up to us", "not up to us", "depends on us", "our choice",
        "within our control", "outside our control", "cannot control",
    ],
    "inner_citadel": [
        "inner", "citadel", "fortress", "mind", "soul", "ruling",
        "governing", "retreat", "within yourself", "inside",
    ],
    "premeditatio_malorum": [
        "anticipate", "prepare", "expect", "foresee", "imagine",
        "what if", "might happen", "could happen", "worst",
    ],
    "memento_mori": [
        "death", "die", "dying", "mortal", "mortality", "finite",
        "last day", "end", "life is short", "brief", "fleeting",
    ],
    "amor_fati": [
        "fate", "accept", "acceptance", "embrace", "love", "welcome",
        "providence", "universe", "nature", "meant to be",
    ],
    "impermanence": [
        "change", "changing", "pass", "passing", "temporary", "transient",
        "nothing lasts", "all things", "flow", "flux", "moment",
    ],
    "present_moment": [
        "present", "now", "today", "this moment", "current", "immediate",
        "at hand", "before you",
    ],
    "living_according_to_nature": [
        "nature", "natural", "according to nature", "rational",
        "reason", "logos", "universal", "cosmos",
    ],
}

# Virtues
VIRTUE_KEYWORDS = {
    "wisdom": [
        "wisdom", "wise", "knowledge", "understand", "judgment",
        "discern", "learn", "truth", "reason", "rational",
    ],
    "courage": [
        "courage", "brave", "bravery", "fear", "fearless", "bold",
        "endure", "persist", "strength", "fortitude", "stand firm",
    ],
    "justice": [
        "justice", "just", "fair", "duty", "obligation", "right",
        "wrong", "others", "society", "fellow", "citizen",
    ],
    "temperance": [
        "temperance", "moderate", "moderation", "restrain", "control",
        "self-control", "discipline", "excess", "pleasure", "desire",
    ],
}

# Practices
PRACTICE_KEYWORDS = {
    "morning_reflection": [
        "morning", "dawn", "arise", "wake", "begin the day", "start",
    ],
    "evening_review": [
        "evening", "night", "end of day", "review", "examine", "reflect",
        "sleep", "bed",
    ],
    "journaling": [
        "write", "record", "note", "journal", "yourself",
    ],
    "self_examination": [
        "examine", "ask yourself", "question", "reflect", "consider",
        "think about", "look within",
    ],
}

# Life Situations
SITUATION_KEYWORDS = {
    "difficult_people": [
        "people", "others", "man", "men", "someone", "they",
        "difficult", "annoying", "fool", "ignorant", "enemy",
    ],
    "anger_management": [
        "anger", "angry", "rage", "fury", "temper", "irritate",
        "provoke", "offend", "insult",
    ],
    "anxiety": [
        "anxious", "anxiety", "worry", "fear", "troubled", "disturbed",
        "concern", "uneasy", "restless",
    ],
    "grief": [
        "grief", "grieve", "loss", "lost", "mourn", "sorrow",
        "sadness", "death of", "passed away",
    ],
    "failure": [
        "fail", "failure", "mistake", "error", "wrong", "setback",
        "disappoint", "fall short",
    ],
    "success": [
        "success", "achieve", "accomplish", "triumph", "victory",
        "praise", "fame", "honor",
    ],
    "leadership": [
        "lead", "leader", "rule", "govern", "command", "authority",
        "power", "emperor", "king",
    ],
    "health_challenges": [
        "sick", "illness", "disease", "pain", "body", "health",
        "suffer", "affliction",
    ],
    "time_management": [
        "time", "busy", "hurry", "waste", "spend", "life is short",
        "procrastinate", "delay",
    ],
    "finding_purpose": [
        "purpose", "meaning", "why", "reason", "goal", "aim",
        "direction", "calling",
    ],
}

# Emotions
EMOTION_KEYWORDS = {
    "anger": ["anger", "angry", "rage", "fury", "wrath", "irritate"],
    "fear": ["fear", "afraid", "terror", "dread", "scary", "frighten"],
    "anxiety": ["anxious", "anxiety", "worry", "worried", "nervous"],
    "grief": ["grief", "sorrow", "mourn", "sad", "sadness", "loss"],
    "joy": ["joy", "happy", "happiness", "delight", "pleasure", "glad"],
    "frustration": ["frustrate", "annoyed", "irritate", "vexed"],
    "peace": ["peace", "calm", "tranquil", "serene", "quiet", "still"],
}


# ============================================================================
# Tagging Functions
# ============================================================================

def find_keywords(text: str, keyword_dict: dict) -> list[str]:
    """Find which categories match based on keywords."""
    text_lower = text.lower()
    matches = []

    for category, keywords in keyword_dict.items():
        for keyword in keywords:
            if keyword.lower() in text_lower:
                matches.append(category)
                break  # One match per category is enough

    return matches


def assess_difficulty(text: str) -> Difficulty:
    """Assess passage difficulty based on complexity indicators."""
    text_lower = text.lower()

    # Advanced indicators
    advanced_terms = [
        "indifferent", "preferred", "logos", "hegemonikon",
        "prohairesis", "oikeiosis", "cosmopolitan", "determinism",
    ]

    # Intermediate indicators
    intermediate_terms = [
        "virtue", "rational", "nature", "providence", "soul",
        "judgment", "impression", "assent",
    ]

    advanced_count = sum(1 for term in advanced_terms if term in text_lower)
    intermediate_count = sum(1 for term in intermediate_terms if term in text_lower)

    if advanced_count >= 2:
        return Difficulty.ADVANCED
    elif intermediate_count >= 2 or advanced_count >= 1:
        return Difficulty.INTERMEDIATE
    else:
        return Difficulty.BEGINNER


def assess_quotability(text: str) -> int:
    """Assess how well the passage stands alone as a quote."""
    # Factors that increase quotability
    score = 5

    # Short passages are more quotable
    word_count = len(text.split())
    if word_count < 50:
        score += 2
    elif word_count < 100:
        score += 1
    elif word_count > 200:
        score -= 2

    # Imperative/advice language is quotable
    advice_patterns = [
        r"\bdo not\b", r"\bnever\b", r"\balways\b", r"\bmust\b",
        r"\bshould\b", r"\bremember\b", r"\blet\b", r"\bbegin\b",
    ]
    for pattern in advice_patterns:
        if re.search(pattern, text.lower()):
            score += 1
            break

    # Questions are quotable
    if "?" in text:
        score += 1

    return min(10, max(1, score))


def assess_comfort(text: str) -> int:
    """Assess if passage is soothing (10) or challenging (1)."""
    text_lower = text.lower()

    # Comforting language
    comfort_words = [
        "peace", "calm", "gentle", "accept", "rest", "ease",
        "content", "tranquil", "serene", "grateful",
    ]

    # Challenging language
    challenge_words = [
        "must", "should", "stop", "cease", "wrong", "foolish",
        "lazy", "weak", "excuse", "complain",
    ]

    comfort_score = sum(1 for w in comfort_words if w in text_lower)
    challenge_score = sum(1 for w in challenge_words if w in text_lower)

    # Base is neutral (5), adjust based on language
    score = 5 + comfort_score - challenge_score
    return min(10, max(1, score))


def assess_actionability(text: str) -> int:
    """Assess how practical/applicable the advice is."""
    text_lower = text.lower()

    # Practical action words
    action_words = [
        "do", "practice", "try", "begin", "start", "stop",
        "when you", "if you", "every day", "each morning",
        "remind yourself", "tell yourself", "ask yourself",
    ]

    score = 5
    for word in action_words:
        if word in text_lower:
            score += 1

    return min(10, max(1, score))


def map_to_health_context(tags: PassageTags) -> HealthContext:
    """Map tags to appropriate health/time contexts."""
    stress_levels = []
    times_of_day = []

    # High stress situations
    if any(e in tags.emotions for e in ["anger", "anxiety", "fear"]):
        stress_levels.extend([StressLevel.ELEVATED, StressLevel.HIGH])

    if any(s in tags.situations for s in ["anger_management", "anxiety", "difficult_people"]):
        stress_levels.extend([StressLevel.ELEVATED, StressLevel.HIGH])

    # Calm/reflective content
    if "peace" in tags.emotions or "acceptance" in tags.primary_concepts:
        stress_levels.append(StressLevel.LOW)

    # Default to normal if nothing specific
    if not stress_levels:
        stress_levels = [StressLevel.NORMAL]

    # Time mapping based on practices
    if "morning_reflection" in tags.practices:
        times_of_day.append(TimeOfDay.MORNING)
    if "evening_review" in tags.practices:
        times_of_day.append(TimeOfDay.EVENING)

    # Memento mori is good for evening/night
    if "memento_mori" in tags.primary_concepts:
        times_of_day.extend([TimeOfDay.EVENING, TimeOfDay.NIGHT])

    # Action-oriented content for morning
    if any(c in tags.primary_concepts for c in ["premeditatio_malorum", "present_moment"]):
        times_of_day.append(TimeOfDay.MORNING)

    # Default to all times if nothing specific
    if not times_of_day:
        times_of_day = [TimeOfDay.MORNING, TimeOfDay.MIDDAY, TimeOfDay.EVENING]

    return HealthContext(
        stress_levels=list(set(stress_levels)),
        times_of_day=list(set(times_of_day)),
    )


def tag_passage(passage: Passage) -> Passage:
    """Tag a single passage using rules."""
    text = passage.text

    # Skip Gutenberg boilerplate
    if "Project Gutenberg" in text or "START OF" in text or "END OF" in text:
        return passage

    # Find matching tags
    tags = PassageTags(
        primary_concepts=find_keywords(text, CONCEPT_KEYWORDS)[:3],
        virtues=find_keywords(text, VIRTUE_KEYWORDS)[:2],
        practices=find_keywords(text, PRACTICE_KEYWORDS)[:2],
        situations=find_keywords(text, SITUATION_KEYWORDS)[:3],
        emotions=find_keywords(text, EMOTION_KEYWORDS)[:3],
    )

    passage.tags = tags

    # Assess quality metrics
    passage.metadata.quotability = assess_quotability(text)
    passage.metadata.actionability = assess_actionability(text)
    passage.metadata.comfort = assess_comfort(text)

    # Assess difficulty
    difficulty = assess_difficulty(text)
    passage.journey_context = JourneyContext(
        stages=[JourneyStage.NEWCOMER] if difficulty == Difficulty.BEGINNER else [JourneyStage.BUILDING_HABITS],
        difficulty=difficulty,
    )

    # Map to health context
    passage.health_context = map_to_health_context(tags)

    return passage


# ============================================================================
# Batch Processing
# ============================================================================

def tag_all_passages(passages: list[Passage]) -> list[Passage]:
    """Tag all passages using rules."""
    tagged = []
    skipped = 0

    with Progress() as progress:
        task = progress.add_task("[cyan]Tagging passages...", total=len(passages))

        for passage in passages:
            tagged_passage = tag_passage(passage)

            # Count passages with at least one tag
            has_tags = bool(
                tagged_passage.tags.primary_concepts or
                tagged_passage.tags.situations or
                tagged_passage.tags.emotions
            )

            if not has_tags:
                skipped += 1

            tagged.append(tagged_passage)
            progress.update(task, advance=1)

    console.print(f"\n[green]Tagged {len(tagged)} passages[/green]")
    console.print(f"[yellow]Skipped {skipped} passages (no tags matched)[/yellow]")

    return tagged


# ============================================================================
# CLI
# ============================================================================

def main():
    """Run rule-based tagging from command line."""
    import argparse

    parser = argparse.ArgumentParser(description="Tag passages using keyword rules (FREE)")
    parser.add_argument(
        "--input",
        "-i",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "processed" / "all_passages.json",
        help="Input file with passages",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "processed" / "all_passages_tagged.json",
        help="Output file for tagged passages",
    )
    args = parser.parse_args()

    console.print("[bold cyan]Stoic Knowledge Base - Rule-Based Tagging (FREE)[/bold cyan]")

    # Load passages
    if not args.input.exists():
        console.print(f"[red]Input file not found: {args.input}[/red]")
        return

    with open(args.input) as f:
        passages_data = json.load(f)

    passages = [Passage.model_validate(p) for p in passages_data]
    console.print(f"Loaded {len(passages)} passages")

    # Tag passages
    tagged = tag_all_passages(passages)

    # Filter out passages with no useful content
    useful = [p for p in tagged if p.tags.primary_concepts or p.tags.situations]
    console.print(f"[green]Useful passages: {len(useful)}[/green]")

    # Save results
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w") as f:
        json.dump([p.model_dump() for p in tagged], f, indent=2)

    console.print(f"\n[bold green]Saved tagged passages to {args.output}[/bold green]")

    # Show sample
    console.print("\n[bold]Sample tagged passage:[/bold]")
    for p in useful[:5]:
        if p.tags.primary_concepts:
            console.print(f"\n[cyan]{p.text[:150]}...[/cyan]")
            console.print(f"  Concepts: {p.tags.primary_concepts}")
            console.print(f"  Situations: {p.tags.situations}")
            console.print(f"  Emotions: {p.tags.emotions}")
            console.print(f"  Difficulty: {p.journey_context.difficulty.value}")
            break


if __name__ == "__main__":
    main()
