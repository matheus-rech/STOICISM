"""
Chunk raw Stoic texts into meaningful passages.

Uses semantic boundaries (chapters, sections, paragraphs) to create
passages suitable for RAG retrieval.
"""

import hashlib
import json
import re
from pathlib import Path
from typing import Generator, Optional, List

from rich.console import Console
from rich.progress import Progress

from models import (
    Passage,
    PassageMetadata,
    PassageTags,
    HealthContext,
    JourneyContext,
    SourceInfo,
    TranslationInfo,
    PhilosopherId,
    WorkId,
    Difficulty,
)

console = Console()

# ============================================================================
# Chunking Configuration
# ============================================================================

CHUNK_CONFIG = {
    # Target chunk size in words
    "min_words": 30,
    "target_words": 100,
    "max_words": 250,

    # Overlap for context preservation
    "overlap_sentences": 1,
}


# ============================================================================
# Text Cleaning
# ============================================================================

def clean_text(text: str) -> str:
    """Clean and normalize text."""
    # Normalize whitespace
    text = re.sub(r"\s+", " ", text)
    # Remove multiple newlines
    text = re.sub(r"\n{3,}", "\n\n", text)
    # Strip leading/trailing whitespace
    text = text.strip()
    return text


def normalize_for_search(text: str) -> str:
    """Create normalized version for search."""
    # Lowercase
    text = text.lower()
    # Remove punctuation except apostrophes
    text = re.sub(r"[^\w\s']", " ", text)
    # Normalize whitespace
    text = re.sub(r"\s+", " ", text)
    return text.strip()


# ============================================================================
# Chunking Functions
# ============================================================================

def split_into_sentences(text: str) -> list[str]:
    """Split text into sentences."""
    # Simple sentence splitter (could use spaCy for better results)
    sentences = re.split(r"(?<=[.!?])\s+", text)
    return [s.strip() for s in sentences if s.strip()]


def chunk_by_paragraph(text: str, min_words: int = 30, max_words: int = 250) -> Generator[str, None, None]:
    """Chunk text by paragraphs, merging small ones."""
    paragraphs = text.split("\n\n")
    current_chunk = []
    current_word_count = 0

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue

        para_words = len(para.split())

        # If adding this paragraph would exceed max, yield current chunk
        if current_word_count + para_words > max_words and current_chunk:
            yield " ".join(current_chunk)
            current_chunk = []
            current_word_count = 0

        current_chunk.append(para)
        current_word_count += para_words

        # If we've reached a good size, yield
        if current_word_count >= min_words:
            yield " ".join(current_chunk)
            current_chunk = []
            current_word_count = 0

    # Don't forget the last chunk
    if current_chunk:
        yield " ".join(current_chunk)


def chunk_meditations(text: str) -> Generator[tuple[str, dict], None, None]:
    """Chunk Meditations with book/section awareness."""
    current_book = 0

    # Split by book markers
    book_pattern = r"=== BOOK (\d+) ==="
    parts = re.split(book_pattern, text)

    i = 0
    while i < len(parts):
        if i + 1 < len(parts) and parts[i].strip().isdigit():
            # This is a book number
            current_book = int(parts[i].strip())
            book_text = parts[i + 1] if i + 1 < len(parts) else ""
            i += 2
        else:
            book_text = parts[i]
            i += 1

        if not book_text.strip():
            continue

        # Chunk this book's content
        for chunk_num, chunk in enumerate(chunk_by_paragraph(book_text), 1):
            metadata = {
                "book": current_book if current_book > 0 else None,
                "section": chunk_num,
            }
            yield chunk, metadata


def chunk_enchiridion(text: str) -> Generator[tuple[str, dict], None, None]:
    """Chunk Enchiridion by chapter markers."""
    # The Enchiridion has numbered chapters
    # Try to find chapter markers like "1.", "2.", etc.

    # Split by chapter numbers at start of line
    chapter_pattern = r"\n(\d{1,2})\.\s"
    parts = re.split(chapter_pattern, text)

    # Handle intro text before chapter 1
    if parts[0].strip():
        yield parts[0].strip(), {"chapter": 0}

    i = 1
    while i < len(parts):
        if parts[i].strip().isdigit():
            chapter = int(parts[i].strip())
            chapter_text = parts[i + 1] if i + 1 < len(parts) else ""
            i += 2

            # Each chapter is usually short enough to be one passage
            chapter_text = chapter_text.strip()
            if chapter_text:
                yield chapter_text, {"chapter": chapter}
        else:
            i += 1


def chunk_discourses(text: str) -> Generator[tuple[str, dict], None, None]:
    """Chunk Discourses with book/chapter awareness."""
    current_book = 0

    # Split by book markers
    book_pattern = r"=== BOOK (\d+) ==="
    parts = re.split(book_pattern, text)

    i = 0
    while i < len(parts):
        if i + 1 < len(parts) and parts[i].strip().isdigit():
            current_book = int(parts[i].strip())
            book_text = parts[i + 1] if i + 1 < len(parts) else ""
            i += 2
        else:
            book_text = parts[i]
            i += 1

        if not book_text.strip():
            continue

        # Chunk by paragraphs within each book
        for chunk_num, chunk in enumerate(chunk_by_paragraph(book_text, min_words=50, max_words=300), 1):
            metadata = {
                "book": current_book if current_book > 0 else None,
                "section": chunk_num,
            }
            yield chunk, metadata


def chunk_letters(text: str) -> Generator[tuple[str, dict], None, None]:
    """Chunk Seneca's Letters by letter number."""
    # Try to find letter markers
    letter_pattern = r"(?:Letter|LETTER|Epistle|EPISTLE)\s+(\d+)"

    parts = re.split(letter_pattern, text)

    i = 0
    while i < len(parts):
        if i + 1 < len(parts) and parts[i].strip().isdigit():
            letter_num = int(parts[i].strip())
            letter_text = parts[i + 1] if i + 1 < len(parts) else ""
            i += 2
        else:
            letter_text = parts[i]
            letter_num = None
            i += 1

        if not letter_text.strip():
            continue

        # Chunk the letter content
        for chunk_num, chunk in enumerate(chunk_by_paragraph(letter_text), 1):
            metadata = {
                "letter": letter_num,
                "section": chunk_num,
            }
            yield chunk, metadata


def chunk_generic(text: str) -> Generator[tuple[str, dict], None, None]:
    """Generic chunking for essays and dialogues."""
    for chunk_num, chunk in enumerate(chunk_by_paragraph(text), 1):
        yield chunk, {"section": chunk_num}


# ============================================================================
# Main Processing
# ============================================================================

def process_work(
    work_id: WorkId,
    raw_dir: Path,
    output_dir: Path,
) -> list[Passage]:
    """Process a single work into passages."""
    raw_file = raw_dir / f"{work_id.value}.txt"
    meta_file = raw_dir / f"{work_id.value}_meta.json"

    if not raw_file.exists():
        console.print(f"[yellow]Raw file not found: {raw_file}[/yellow]")
        return []

    # Load raw text and metadata
    text = raw_file.read_text(encoding="utf-8")
    metadata = json.loads(meta_file.read_text()) if meta_file.exists() else {}

    # Select chunking strategy
    chunkers = {
        WorkId.MEDITATIONS: chunk_meditations,
        WorkId.ENCHIRIDION: chunk_enchiridion,
        WorkId.DISCOURSES: chunk_discourses,
        WorkId.LETTERS: chunk_letters,
    }
    chunker = chunkers.get(work_id, chunk_generic)

    # Build translation info
    translation = TranslationInfo(
        translator=metadata.get("translator", "Unknown"),
        year=metadata.get("year", 0),
        source_url=metadata.get("source_url", ""),
        license=metadata.get("license", "Public Domain"),
    )

    passages = []
    for chunk_text, chunk_meta in chunker(text):
        # Clean the text
        chunk_text = clean_text(chunk_text)

        # Skip very short chunks
        word_count = len(chunk_text.split())
        if word_count < CHUNK_CONFIG["min_words"]:
            continue

        # Generate unique ID
        content_hash = hashlib.md5(chunk_text.encode()).hexdigest()[:12]
        passage_id = f"{work_id.value}_{content_hash}"

        # Build source info
        source = SourceInfo(
            philosopher_id=PhilosopherId(metadata.get("philosopher", "marcus_aurelius")),
            work_id=work_id,
            book=chunk_meta.get("book"),
            chapter=chunk_meta.get("chapter"),
            letter=chunk_meta.get("letter"),
            section=str(chunk_meta.get("section", "")),
        )

        # Create passage
        passage = Passage(
            id=passage_id,
            source=source,
            translation=translation,
            text=chunk_text,
            text_normalized=normalize_for_search(chunk_text),
            tags=PassageTags(),  # Will be filled by tagger
            health_context=HealthContext(),
            journey_context=JourneyContext(difficulty=Difficulty.BEGINNER),
            metadata=PassageMetadata(
                word_count=word_count,
                character_count=len(chunk_text),
            ),
        )

        passages.append(passage)

    return passages


def process_all(raw_dir: Path, output_dir: Path, works: Optional[List[WorkId]] = None):
    """Process all works into passages."""
    output_dir.mkdir(parents=True, exist_ok=True)

    all_passages = []
    works_to_process = works or list(WorkId)

    with Progress() as progress:
        task = progress.add_task("[cyan]Chunking texts...", total=len(works_to_process))

        for work_id in works_to_process:
            progress.update(task, description=f"Chunking {work_id.value}...")

            passages = process_work(work_id, raw_dir, output_dir)

            if passages:
                # Save passages for this work
                output_file = output_dir / f"{work_id.value}_passages.json"
                output_file.write_text(
                    json.dumps([p.model_dump() for p in passages], indent=2),
                    encoding="utf-8",
                )
                console.print(f"  [green]✓[/green] {work_id.value}: {len(passages)} passages")
                all_passages.extend(passages)
            else:
                console.print(f"  [yellow]○[/yellow] {work_id.value}: No passages generated")

            progress.update(task, advance=1)

    # Save combined passages
    combined_file = output_dir / "all_passages.json"
    combined_file.write_text(
        json.dumps([p.model_dump() for p in all_passages], indent=2),
        encoding="utf-8",
    )

    console.print(f"\n[bold green]Total: {len(all_passages)} passages[/bold green]")
    return all_passages


# ============================================================================
# CLI
# ============================================================================

def main():
    """Run chunking from command line."""
    import argparse

    parser = argparse.ArgumentParser(description="Chunk Stoic texts into passages")
    parser.add_argument(
        "--input",
        "-i",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "raw",
        help="Input directory with raw texts",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "processed",
        help="Output directory for passages",
    )
    parser.add_argument(
        "--works",
        "-w",
        nargs="*",
        choices=[w.value for w in WorkId],
        help="Specific works to process (default: all)",
    )
    args = parser.parse_args()

    works = [WorkId(w) for w in args.works] if args.works else None

    console.print("[bold cyan]Stoic Knowledge Base - Text Chunking[/bold cyan]")
    console.print(f"Input directory: {args.input}")
    console.print(f"Output directory: {args.output}")

    process_all(args.input, args.output, works)


if __name__ == "__main__":
    main()
