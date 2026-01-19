"""
Ingest Stoic texts from public domain sources.

Downloads and saves raw texts from:
- MIT Classics Archive
- Standard Ebooks
- Wikisource
- Internet Archive
"""

import asyncio
import hashlib
import json
import re
from pathlib import Path
from typing import Optional

import httpx
from bs4 import BeautifulSoup
from rich.console import Console
from rich.progress import Progress, TaskID

from models import PhilosopherId, WorkId

console = Console()

# ============================================================================
# Source Configuration
# ============================================================================

SOURCES = {
    # -------------------------------------------------------------------------
    # MARCUS AURELIUS - Meditations (using single-page version)
    # -------------------------------------------------------------------------
    WorkId.MEDITATIONS: {
        "philosopher": PhilosopherId.MARCUS_AURELIUS,
        "title": "Meditations",
        "translator": "George Long",
        "year": 1862,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://classics.mit.edu/Antoninus/meditations.html",
                "type": "html_single",
            },
        ],
    },
    # -------------------------------------------------------------------------
    # EPICTETUS - Enchiridion
    # -------------------------------------------------------------------------
    WorkId.ENCHIRIDION: {
        "philosopher": PhilosopherId.EPICTETUS,
        "title": "Enchiridion (Handbook)",
        "translator": "Elizabeth Carter",
        "year": 1758,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://classics.mit.edu/Epictetus/epicench.html",
                "type": "html_single",
            },
        ],
    },
    # -------------------------------------------------------------------------
    # EPICTETUS - Discourses (using single-page version)
    # -------------------------------------------------------------------------
    WorkId.DISCOURSES: {
        "philosopher": PhilosopherId.EPICTETUS,
        "title": "Discourses",
        "translator": "George Long",
        "year": 1877,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://classics.mit.edu/Epictetus/discourses.html",
                "type": "html_single",
            },
        ],
    },
    # -------------------------------------------------------------------------
    # SENECA - Letters to Lucilius (sample - full requires multi-page fetch)
    # -------------------------------------------------------------------------
    WorkId.LETTERS: {
        "philosopher": PhilosopherId.SENECA,
        "title": "Moral Letters to Lucilius",
        "translator": "Richard Mott Gummere",
        "year": 1917,
        "license": "Public Domain",
        "sources": [
            {
                # Wikisource has organized letters
                "url": "https://en.wikisource.org/wiki/Moral_letters_to_Lucilius",
                "type": "wikisource_index",
                "letters": 124,
            },
        ],
    },
    # -------------------------------------------------------------------------
    # SENECA - On the Shortness of Life
    # -------------------------------------------------------------------------
    WorkId.ON_SHORTNESS_OF_LIFE: {
        "philosopher": PhilosopherId.SENECA,
        "title": "On the Shortness of Life",
        "translator": "John W. Basore",
        "year": 1932,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://en.wikisource.org/wiki/Moral_Essays/Book_X",
                "type": "wikisource_single",
            },
        ],
    },
    # -------------------------------------------------------------------------
    # SENECA - On Tranquility of Mind
    # -------------------------------------------------------------------------
    WorkId.ON_TRANQUILITY: {
        "philosopher": PhilosopherId.SENECA,
        "title": "On Tranquility of Mind",
        "translator": "Aubrey Stewart",
        "year": 1889,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://en.wikisource.org/wiki/Of_Peace_of_Mind",
                "type": "wikisource_single",
            },
        ],
    },
    # -------------------------------------------------------------------------
    # SENECA - On Anger
    # -------------------------------------------------------------------------
    WorkId.ON_ANGER: {
        "philosopher": PhilosopherId.SENECA,
        "title": "On Anger",
        "translator": "Aubrey Stewart",
        "year": 1889,
        "license": "Public Domain",
        "sources": [
            {
                "url": "https://en.wikisource.org/wiki/Of_Anger",
                "type": "wikisource_index",
                "books": 3,
            },
        ],
    },
}


# ============================================================================
# Fetch Functions
# ============================================================================

async def fetch_url(client: httpx.AsyncClient, url: str) -> Optional[str]:
    """Fetch a URL with retry logic."""
    for attempt in range(3):
        try:
            response = await client.get(url, timeout=30.0)
            response.raise_for_status()
            return response.text
        except httpx.HTTPError as e:
            console.print(f"[yellow]Attempt {attempt + 1} failed for {url}: {e}[/yellow]")
            await asyncio.sleep(2 ** attempt)
    return None


def extract_text_mit_classics(html: str) -> str:
    """Extract text from MIT Classics HTML pages."""
    soup = BeautifulSoup(html, "lxml")

    # Remove script and style elements
    for element in soup(["script", "style", "nav", "header", "footer"]):
        element.decompose()

    # Find main content
    content = soup.find("body")
    if not content:
        return ""

    # Get text and clean up
    text = content.get_text(separator="\n")

    # Clean up whitespace
    lines = [line.strip() for line in text.split("\n")]
    lines = [line for line in lines if line]

    # Remove navigation and metadata lines
    skip_patterns = [
        "The Internet Classics Archive",
        "MIT",
        "Brought to you by",
        "Web Atomics",
        "Home Page",
        "Search",
        "Comment on this work",
    ]

    filtered = []
    for line in lines:
        if not any(pattern in line for pattern in skip_patterns):
            filtered.append(line)

    return "\n".join(filtered)


def extract_text_wikisource(html: str) -> str:
    """Extract text from Wikisource HTML pages."""
    soup = BeautifulSoup(html, "lxml")

    # Find the main content div
    content = soup.find("div", {"class": "mw-parser-output"})
    if not content:
        content = soup.find("div", {"id": "mw-content-text"})
    if not content:
        return ""

    # Remove unwanted elements
    for element in content(["script", "style", "sup", "table"]):
        element.decompose()

    # Remove reference links
    for ref in content.find_all("a", {"class": "reference"}):
        ref.decompose()

    # Get text
    text = content.get_text(separator="\n")

    # Clean up
    lines = [line.strip() for line in text.split("\n")]
    lines = [line for line in lines if line and len(line) > 3]

    return "\n".join(lines)


# ============================================================================
# Ingestion Functions
# ============================================================================

async def ingest_mit_single(
    client: httpx.AsyncClient,
    work_id: WorkId,
    config: dict,
    output_dir: Path,
    progress: Progress,
    task: TaskID,
) -> dict:
    """Ingest a single-page MIT Classics text."""
    source = config["sources"][0]
    url = source["url"]

    progress.update(task, description=f"Fetching {config['title']}...")

    html = await fetch_url(client, url)
    if not html:
        return {"error": f"Failed to fetch {url}"}

    text = extract_text_mit_classics(html)

    # Save raw text
    output_file = output_dir / f"{work_id.value}.txt"
    output_file.write_text(text, encoding="utf-8")

    # Save metadata
    metadata = {
        "work_id": work_id.value,
        "philosopher": config["philosopher"].value,
        "title": config["title"],
        "translator": config["translator"],
        "year": config["year"],
        "license": config["license"],
        "source_url": url,
        "word_count": len(text.split()),
        "character_count": len(text),
        "content_hash": hashlib.md5(text.encode()).hexdigest(),
    }

    meta_file = output_dir / f"{work_id.value}_meta.json"
    meta_file.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    progress.update(task, advance=1)
    return metadata


async def ingest_mit_multi_book(
    client: httpx.AsyncClient,
    work_id: WorkId,
    config: dict,
    output_dir: Path,
    progress: Progress,
    task: TaskID,
) -> dict:
    """Ingest a multi-book MIT Classics text."""
    source = config["sources"][0]
    num_books = source["books"]
    pattern = source["book_pattern"]

    all_text = []
    book_metadata = []

    for book_num in range(1, num_books + 1):
        url = pattern.format(book=book_num)
        progress.update(task, description=f"Fetching {config['title']} Book {book_num}...")

        html = await fetch_url(client, url)
        if html:
            text = extract_text_mit_classics(html)
            all_text.append(f"\n\n=== BOOK {book_num} ===\n\n{text}")
            book_metadata.append({
                "book": book_num,
                "url": url,
                "word_count": len(text.split()),
            })

        await asyncio.sleep(0.5)  # Be nice to the server

    combined_text = "\n".join(all_text)

    # Save raw text
    output_file = output_dir / f"{work_id.value}.txt"
    output_file.write_text(combined_text, encoding="utf-8")

    # Save metadata
    metadata = {
        "work_id": work_id.value,
        "philosopher": config["philosopher"].value,
        "title": config["title"],
        "translator": config["translator"],
        "year": config["year"],
        "license": config["license"],
        "source_url": source["url"],
        "books": book_metadata,
        "word_count": len(combined_text.split()),
        "character_count": len(combined_text),
        "content_hash": hashlib.md5(combined_text.encode()).hexdigest(),
    }

    meta_file = output_dir / f"{work_id.value}_meta.json"
    meta_file.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    progress.update(task, advance=1)
    return metadata


async def ingest_wikisource_single(
    client: httpx.AsyncClient,
    work_id: WorkId,
    config: dict,
    output_dir: Path,
    progress: Progress,
    task: TaskID,
) -> dict:
    """Ingest a single Wikisource page."""
    source = config["sources"][0]
    url = source["url"]

    progress.update(task, description=f"Fetching {config['title']}...")

    html = await fetch_url(client, url)
    if not html:
        return {"error": f"Failed to fetch {url}"}

    text = extract_text_wikisource(html)

    # Save raw text
    output_file = output_dir / f"{work_id.value}.txt"
    output_file.write_text(text, encoding="utf-8")

    # Save metadata
    metadata = {
        "work_id": work_id.value,
        "philosopher": config["philosopher"].value,
        "title": config["title"],
        "translator": config["translator"],
        "year": config["year"],
        "license": config["license"],
        "source_url": url,
        "word_count": len(text.split()),
        "character_count": len(text),
        "content_hash": hashlib.md5(text.encode()).hexdigest(),
    }

    meta_file = output_dir / f"{work_id.value}_meta.json"
    meta_file.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    progress.update(task, advance=1)
    return metadata


# ============================================================================
# Main Ingestion
# ============================================================================

async def ingest_all(output_dir: Path, works: Optional[list[WorkId]] = None):
    """Ingest all configured sources or specified works."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # Filter to requested works
    to_ingest = {k: v for k, v in SOURCES.items() if works is None or k in works}

    results = {}

    async with httpx.AsyncClient(
        headers={"User-Agent": "StoicCompanion/1.0 (Educational Project)"},
        follow_redirects=True,
    ) as client:
        with Progress() as progress:
            task = progress.add_task("[cyan]Ingesting texts...", total=len(to_ingest))

            for work_id, config in to_ingest.items():
                source_type = config["sources"][0]["type"]

                try:
                    if source_type == "html_single":
                        result = await ingest_mit_single(
                            client, work_id, config, output_dir, progress, task
                        )
                    elif source_type == "html_index":
                        result = await ingest_mit_multi_book(
                            client, work_id, config, output_dir, progress, task
                        )
                    elif source_type == "wikisource_single":
                        result = await ingest_wikisource_single(
                            client, work_id, config, output_dir, progress, task
                        )
                    elif source_type == "wikisource_index":
                        # TODO: Implement multi-page Wikisource ingestion
                        console.print(f"[yellow]Skipping {work_id.value} (multi-page Wikisource not yet implemented)[/yellow]")
                        result = {"skipped": True}
                    else:
                        console.print(f"[red]Unknown source type: {source_type}[/red]")
                        result = {"error": f"Unknown source type: {source_type}"}

                    results[work_id.value] = result

                except Exception as e:
                    console.print(f"[red]Error ingesting {work_id.value}: {e}[/red]")
                    results[work_id.value] = {"error": str(e)}

    return results


# ============================================================================
# CLI
# ============================================================================

def main():
    """Run ingestion from command line."""
    import argparse

    parser = argparse.ArgumentParser(description="Ingest Stoic texts from public domain sources")
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "raw",
        help="Output directory for raw texts",
    )
    parser.add_argument(
        "--works",
        "-w",
        nargs="*",
        choices=[w.value for w in WorkId],
        help="Specific works to ingest (default: all)",
    )
    args = parser.parse_args()

    works = [WorkId(w) for w in args.works] if args.works else None

    console.print("[bold cyan]Stoic Knowledge Base - Text Ingestion[/bold cyan]")
    console.print(f"Output directory: {args.output}")

    results = asyncio.run(ingest_all(args.output, works))

    # Summary
    console.print("\n[bold]Ingestion Summary:[/bold]")
    for work_id, result in results.items():
        if "error" in result:
            console.print(f"  [red]✗[/red] {work_id}: {result['error']}")
        elif "skipped" in result:
            console.print(f"  [yellow]○[/yellow] {work_id}: Skipped")
        else:
            console.print(f"  [green]✓[/green] {work_id}: {result.get('word_count', 0):,} words")


if __name__ == "__main__":
    main()
