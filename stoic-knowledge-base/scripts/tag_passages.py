"""
Auto-tag passages using AI.

Uses Claude to analyze each passage and assign:
- Primary concepts (from taxonomy)
- Virtues addressed
- Stoic practices mentioned
- Life situations it addresses
- Emotions it helps with
- HealthKit context mapping
- Difficulty level
"""

import asyncio
import json
from pathlib import Path
from typing import Any

from anthropic import AsyncAnthropic
from rich.console import Console
from rich.progress import Progress

from models import (
    Passage,
    PassageTags,
    HealthContext,
    JourneyContext,
    StressLevel,
    ActivityState,
    TimeOfDay,
    JourneyStage,
    Difficulty,
    PRIMARY_CONCEPTS,
    VIRTUES,
    PRACTICES,
    SITUATIONS,
    EMOTIONS,
)

console = Console()

# ============================================================================
# Tagging Prompt
# ============================================================================

TAGGING_PROMPT = """You are an expert in Stoic philosophy tasked with categorizing passages for a wellness app.

Analyze the following passage and assign appropriate tags. Be selective - only assign tags that clearly apply.

## Available Tags

### Primary Concepts (Stoic philosophical concepts)
{concepts}

### Virtues (Cardinal Stoic virtues)
{virtues}

### Practices (Stoic exercises and habits)
{practices}

### Life Situations (Problems this passage addresses)
{situations}

### Emotions (Feelings this passage helps with)
{emotions}

## Passage to Analyze

Author: {author}
Source: {source}

"{text}"

## Instructions

Respond with a JSON object containing:

1. `primary_concepts`: List of 1-3 primary Stoic concepts this passage relates to
2. `virtues`: List of 0-2 cardinal virtues this passage emphasizes
3. `practices`: List of 0-2 Stoic practices mentioned or encouraged
4. `situations`: List of 1-3 life situations this passage could help with
5. `emotions`: List of 1-3 emotions this passage addresses or helps manage

6. `stress_levels`: When should this passage be shown based on user stress?
   - "low": User is relaxed, good for deeper reflection
   - "normal": Everyday wisdom
   - "elevated": User needs grounding
   - "high": User needs immediate comfort/support

7. `times_of_day`: When is this passage most appropriate?
   - "morning": Preparation for the day
   - "midday": Staying focused
   - "evening": Reflection and review
   - "night": Peace and acceptance

8. `difficulty`: How philosophically advanced is this passage?
   - "beginner": Simple, accessible wisdom
   - "intermediate": Requires some Stoic background
   - "advanced": Subtle or complex concepts

9. `quotability`: 1-10, how well does this stand alone as a quote?
10. `actionability`: 1-10, how practical/applicable is this advice?
11. `comfort`: 1-10, is this soothing (10) or challenging (1)?

Respond ONLY with valid JSON, no other text."""


# ============================================================================
# Tagging Function
# ============================================================================

async def tag_passage(
    client: AsyncAnthropic,
    passage: Passage,
    model: str = "claude-sonnet-4-20250514",
) -> dict[str, Any]:
    """Tag a single passage using Claude."""

    # Build source string
    source_parts = [passage.source.work_id.value]
    if passage.source.book:
        source_parts.append(f"Book {passage.source.book}")
    if passage.source.chapter:
        source_parts.append(f"Chapter {passage.source.chapter}")
    if passage.source.letter:
        source_parts.append(f"Letter {passage.source.letter}")

    prompt = TAGGING_PROMPT.format(
        concepts=", ".join(PRIMARY_CONCEPTS),
        virtues=", ".join(VIRTUES),
        practices=", ".join(PRACTICES),
        situations=", ".join(SITUATIONS),
        emotions=", ".join(EMOTIONS),
        author=passage.source.philosopher_id.value.replace("_", " ").title(),
        source=" > ".join(source_parts),
        text=passage.text,
    )

    try:
        response = await client.messages.create(
            model=model,
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        )

        # Extract JSON from response
        response_text = response.content[0].text.strip()

        # Handle potential markdown code blocks
        if response_text.startswith("```"):
            response_text = response_text.split("```")[1]
            if response_text.startswith("json"):
                response_text = response_text[4:]
            response_text = response_text.strip()

        return json.loads(response_text)

    except Exception as e:
        console.print(f"[red]Error tagging passage {passage.id}: {e}[/red]")
        return {}


def apply_tags(passage: Passage, tags: dict[str, Any]) -> Passage:
    """Apply AI-generated tags to a passage."""
    if not tags:
        return passage

    # Apply semantic tags
    passage.tags = PassageTags(
        primary_concepts=tags.get("primary_concepts", []),
        virtues=tags.get("virtues", []),
        practices=tags.get("practices", []),
        situations=tags.get("situations", []),
        emotions=tags.get("emotions", []),
    )

    # Apply health context
    stress_levels = tags.get("stress_levels", ["normal"])
    if isinstance(stress_levels, str):
        stress_levels = [stress_levels]

    times = tags.get("times_of_day", ["morning", "evening"])
    if isinstance(times, str):
        times = [times]

    passage.health_context = HealthContext(
        stress_levels=[StressLevel(s) for s in stress_levels if s in StressLevel._value2member_map_],
        activity_states=[ActivityState.SEDENTARY],  # Default, could be enhanced
        times_of_day=[TimeOfDay(t) for t in times if t in TimeOfDay._value2member_map_],
    )

    # Apply journey context
    difficulty = tags.get("difficulty", "beginner")
    passage.journey_context = JourneyContext(
        stages=[JourneyStage.NEWCOMER] if difficulty == "beginner" else [JourneyStage.BUILDING_HABITS],
        difficulty=Difficulty(difficulty) if difficulty in Difficulty._value2member_map_ else Difficulty.BEGINNER,
    )

    # Apply metadata scores
    passage.metadata.quotability = tags.get("quotability", 5)
    passage.metadata.actionability = tags.get("actionability", 5)
    passage.metadata.comfort = tags.get("comfort", 5)

    return passage


# ============================================================================
# Batch Processing
# ============================================================================

async def tag_all_passages(
    passages: list[Passage],
    api_key: str,
    batch_size: int = 5,
    model: str = "claude-sonnet-4-20250514",
) -> list[Passage]:
    """Tag all passages with rate limiting."""
    client = AsyncAnthropic(api_key=api_key)

    tagged_passages = []

    with Progress() as progress:
        task = progress.add_task("[cyan]Tagging passages...", total=len(passages))

        for i in range(0, len(passages), batch_size):
            batch = passages[i:i + batch_size]

            # Process batch concurrently
            tasks = [tag_passage(client, p, model) for p in batch]
            results = await asyncio.gather(*tasks)

            # Apply tags
            for passage, tags in zip(batch, results):
                tagged_passage = apply_tags(passage, tags)
                tagged_passages.append(tagged_passage)

            progress.update(task, advance=len(batch))

            # Rate limiting - be nice to the API
            await asyncio.sleep(1)

    return tagged_passages


# ============================================================================
# CLI
# ============================================================================

def main():
    """Run tagging from command line."""
    import argparse
    import os
    from dotenv import load_dotenv

    load_dotenv()

    parser = argparse.ArgumentParser(description="Tag passages using AI")
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
    parser.add_argument(
        "--api-key",
        type=str,
        default=os.getenv("ANTHROPIC_API_KEY"),
        help="Anthropic API key (or set ANTHROPIC_API_KEY env var)",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="claude-sonnet-4-20250514",
        help="Claude model to use for tagging",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=5,
        help="Batch size for concurrent requests",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of passages to tag (for testing)",
    )
    args = parser.parse_args()

    if not args.api_key:
        console.print("[red]Error: ANTHROPIC_API_KEY not set[/red]")
        return

    console.print("[bold cyan]Stoic Knowledge Base - AI Tagging[/bold cyan]")

    # Load passages
    if not args.input.exists():
        console.print(f"[red]Input file not found: {args.input}[/red]")
        return

    with open(args.input) as f:
        passages_data = json.load(f)

    passages = [Passage.model_validate(p) for p in passages_data]

    if args.limit:
        passages = passages[:args.limit]

    console.print(f"Loaded {len(passages)} passages")

    # Tag passages
    tagged = asyncio.run(
        tag_all_passages(
            passages,
            api_key=args.api_key,
            batch_size=args.batch_size,
            model=args.model,
        )
    )

    # Save results
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w") as f:
        json.dump([p.model_dump() for p in tagged], f, indent=2)

    console.print(f"\n[bold green]Tagged {len(tagged)} passages → {args.output}[/bold green]")


if __name__ == "__main__":
    main()
