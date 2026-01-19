"""
Auto-tag passages using OpenAI GPT-4o-mini.
Very cheap (~$0.15 for 2000 passages).
"""

import asyncio
import json
from pathlib import Path

from openai import AsyncOpenAI
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
    PRIMARY_CONCEPTS,
    VIRTUES,
    PRACTICES,
    SITUATIONS,
    EMOTIONS,
)

console = Console()

TAGGING_PROMPT = """You are an expert in Stoic philosophy. Analyze this passage and return JSON tags.

Available tags:
- primary_concepts: {concepts}
- virtues: {virtues}
- practices: {practices}
- situations: {situations}
- emotions: {emotions}

Passage ({author}, {source}):
"{text}"

Return ONLY valid JSON:
{{
  "primary_concepts": ["1-3 concepts"],
  "virtues": ["0-2 virtues"],
  "practices": ["0-2 practices"],
  "situations": ["1-3 situations"],
  "emotions": ["1-3 emotions"],
  "stress_levels": ["low/normal/elevated/high"],
  "times_of_day": ["morning/midday/evening/night"],
  "difficulty": "beginner/intermediate/advanced",
  "quotability": 1-10,
  "actionability": 1-10,
  "comfort": 1-10
}}"""


async def tag_passage(client: AsyncOpenAI, passage: Passage) -> dict:
    """Tag a single passage using GPT-4o-mini."""
    # Skip boilerplate
    if "Project Gutenberg" in passage.text or len(passage.text) < 50:
        return {}

    source_parts = [passage.source.work_id.value]
    if passage.source.book:
        source_parts.append(f"Book {passage.source.book}")

    prompt = TAGGING_PROMPT.format(
        concepts=", ".join(PRIMARY_CONCEPTS),
        virtues=", ".join(VIRTUES),
        practices=", ".join(PRACTICES),
        situations=", ".join(SITUATIONS),
        emotions=", ".join(EMOTIONS),
        author=passage.source.philosopher_id.value.replace("_", " ").title(),
        source=" > ".join(source_parts),
        text=passage.text[:500],  # Truncate for cost
    )

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
            temperature=0.3,
        )

        text = response.choices[0].message.content.strip()
        # Handle markdown code blocks
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        return json.loads(text.strip())
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        return {}


def apply_tags(passage: Passage, tags: dict) -> Passage:
    """Apply tags to passage."""
    if not tags:
        return passage

    passage.tags = PassageTags(
        primary_concepts=tags.get("primary_concepts", [])[:3],
        virtues=tags.get("virtues", [])[:2],
        practices=tags.get("practices", [])[:2],
        situations=tags.get("situations", [])[:3],
        emotions=tags.get("emotions", [])[:3],
    )

    stress = tags.get("stress_levels", ["normal"])
    if isinstance(stress, str):
        stress = [stress]
    times = tags.get("times_of_day", ["morning"])
    if isinstance(times, str):
        times = [times]

    passage.health_context = HealthContext(
        stress_levels=[StressLevel(s) for s in stress if s in StressLevel._value2member_map_],
        times_of_day=[TimeOfDay(t) for t in times if t in TimeOfDay._value2member_map_],
    )

    diff = tags.get("difficulty", "beginner")
    passage.journey_context = JourneyContext(
        stages=[JourneyStage.NEWCOMER] if diff == "beginner" else [JourneyStage.BUILDING_HABITS],
        difficulty=Difficulty(diff) if diff in Difficulty._value2member_map_ else Difficulty.BEGINNER,
    )

    passage.metadata.quotability = tags.get("quotability", 5)
    passage.metadata.actionability = tags.get("actionability", 5)
    passage.metadata.comfort = tags.get("comfort", 5)

    return passage


async def tag_all(passages: list[Passage], api_key: str, batch_size: int = 20) -> list[Passage]:
    """Tag all passages."""
    client = AsyncOpenAI(api_key=api_key)
    tagged = []

    with Progress() as progress:
        task = progress.add_task("[cyan]Tagging with GPT-4o-mini...", total=len(passages))

        for i in range(0, len(passages), batch_size):
            batch = passages[i:i + batch_size]
            tasks = [tag_passage(client, p) for p in batch]
            results = await asyncio.gather(*tasks)

            for passage, tags in zip(batch, results):
                tagged.append(apply_tags(passage, tags))

            progress.update(task, advance=len(batch))
            await asyncio.sleep(0.5)  # Rate limit

    return tagged


def main():
    import argparse
    import os

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", "-i", type=Path,
                        default=Path(__file__).parent.parent / "data/processed/all_passages.json")
    parser.add_argument("--output", "-o", type=Path,
                        default=Path(__file__).parent.parent / "data/processed/all_passages_tagged.json")
    parser.add_argument("--api-key", type=str, default=os.getenv("OPENAI_API_KEY"))
    parser.add_argument("--limit", type=int, default=None)
    args = parser.parse_args()

    if not args.api_key:
        console.print("[red]OPENAI_API_KEY required[/red]")
        return

    console.print("[bold cyan]Tagging with OpenAI GPT-4o-mini[/bold cyan]")

    with open(args.input) as f:
        data = json.load(f)
    passages = [Passage.model_validate(p) for p in data]

    if args.limit:
        passages = passages[:args.limit]

    console.print(f"Tagging {len(passages)} passages...")

    tagged = asyncio.run(tag_all(passages, args.api_key))

    with open(args.output, "w") as f:
        json.dump([p.model_dump() for p in tagged], f, indent=2)

    useful = sum(1 for p in tagged if p.tags.primary_concepts)
    console.print(f"\n[bold green]Done! {useful} passages tagged → {args.output}[/bold green]")


if __name__ == "__main__":
    main()
