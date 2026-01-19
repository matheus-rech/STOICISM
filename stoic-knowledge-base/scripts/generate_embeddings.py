"""
Generate vector embeddings for passages.

Embeddings convert text into high-dimensional vectors that capture
semantic meaning. Similar texts will have similar vectors, enabling
semantic search for the RAG system.

Supports multiple embedding providers:
- OpenAI (text-embedding-3-small, text-embedding-3-large)
- Voyage AI (voyage-large-2)
- Local models via sentence-transformers
"""

import asyncio
import json
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.progress import Progress

from models import Passage

console = Console()

# ============================================================================
# Embedding Providers
# ============================================================================

class EmbeddingProvider:
    """Base class for embedding providers."""

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        raise NotImplementedError

    async def embed_single(self, text: str) -> list[float]:
        results = await self.embed_texts([text])
        return results[0]


class OpenAIEmbeddings(EmbeddingProvider):
    """OpenAI embeddings via their API."""

    def __init__(
        self,
        api_key: str,
        model: str = "text-embedding-3-small",
    ):
        from openai import AsyncOpenAI
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = model
        self.dimensions = 1536 if "small" in model else 3072

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        response = await self.client.embeddings.create(
            model=self.model,
            input=texts,
        )
        return [item.embedding for item in response.data]


class VoyageEmbeddings(EmbeddingProvider):
    """Voyage AI embeddings - excellent for retrieval."""

    def __init__(self, api_key: str, model: str = "voyage-large-2"):
        import voyageai
        self.client = voyageai.AsyncClient(api_key=api_key)
        self.model = model

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        response = await self.client.embed(texts, model=self.model)
        return response.embeddings


class LocalEmbeddings(EmbeddingProvider):
    """Local embeddings using sentence-transformers (no API needed)."""

    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        from sentence_transformers import SentenceTransformer
        self.model = SentenceTransformer(model_name)

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        # sentence-transformers is sync, so run in executor
        import asyncio
        loop = asyncio.get_event_loop()
        embeddings = await loop.run_in_executor(
            None,
            lambda: self.model.encode(texts).tolist()
        )
        return embeddings


# ============================================================================
# Embedding Generation
# ============================================================================

async def generate_embeddings(
    passages: list[Passage],
    provider: EmbeddingProvider,
    batch_size: int = 50,
) -> list[Passage]:
    """Generate embeddings for all passages."""

    with Progress() as progress:
        task = progress.add_task("[cyan]Generating embeddings...", total=len(passages))

        for i in range(0, len(passages), batch_size):
            batch = passages[i:i + batch_size]

            # Extract texts for embedding
            texts = [p.text for p in batch]

            try:
                # Generate embeddings
                embeddings = await provider.embed_texts(texts)

                # Assign to passages
                for passage, embedding in zip(batch, embeddings):
                    passage.embedding = embedding

            except Exception as e:
                console.print(f"[red]Error generating embeddings: {e}[/red]")
                # Continue with None embeddings for this batch

            progress.update(task, advance=len(batch))

            # Small delay to avoid rate limits
            await asyncio.sleep(0.1)

    return passages


# ============================================================================
# Vector Database Export
# ============================================================================

def export_for_pinecone(passages: list[Passage], output_file: Path):
    """Export passages in Pinecone-compatible format."""
    vectors = []

    for p in passages:
        if p.embedding is None:
            continue

        # Flatten tags for metadata (Pinecone has metadata limits)
        metadata = {
            "philosopher": p.source.philosopher_id.value,
            "work": p.source.work_id.value,
            "book": p.source.book or 0,
            "text": p.text[:1000],  # Truncate for metadata limit
            "concepts": ",".join(p.tags.primary_concepts[:3]),
            "situations": ",".join(p.tags.situations[:3]),
            "emotions": ",".join(p.tags.emotions[:3]),
            "difficulty": p.journey_context.difficulty.value,
            "quotability": p.metadata.quotability,
        }

        vectors.append({
            "id": p.id,
            "values": p.embedding,
            "metadata": metadata,
        })

    output_file.write_text(json.dumps(vectors, indent=2))
    console.print(f"[green]Exported {len(vectors)} vectors to {output_file}[/green]")


def export_for_supabase(passages: list[Passage], output_file: Path):
    """Export passages for Supabase pgvector."""
    rows = []

    for p in passages:
        if p.embedding is None:
            continue

        row = {
            "id": p.id,
            "philosopher_id": p.source.philosopher_id.value,
            "work_id": p.source.work_id.value,
            "book": p.source.book,
            "chapter": p.source.chapter,
            "letter": p.source.letter,
            "text": p.text,
            "embedding": p.embedding,  # Will need to be converted to vector type
            "tags": {
                "primary_concepts": p.tags.primary_concepts,
                "virtues": p.tags.virtues,
                "practices": p.tags.practices,
                "situations": p.tags.situations,
                "emotions": p.tags.emotions,
            },
            "health_context": {
                "stress_levels": [s.value for s in p.health_context.stress_levels],
                "times_of_day": [t.value for t in p.health_context.times_of_day],
            },
            "difficulty": p.journey_context.difficulty.value,
            "quotability": p.metadata.quotability,
            "actionability": p.metadata.actionability,
            "comfort": p.metadata.comfort,
        }
        rows.append(row)

    output_file.write_text(json.dumps(rows, indent=2))
    console.print(f"[green]Exported {len(rows)} rows to {output_file}[/green]")


# ============================================================================
# CLI
# ============================================================================

def main():
    """Generate embeddings from command line."""
    import argparse
    import os
    from dotenv import load_dotenv

    load_dotenv()

    parser = argparse.ArgumentParser(description="Generate embeddings for passages")
    parser.add_argument(
        "--input",
        "-i",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "processed" / "all_passages_tagged.json",
        help="Input file with tagged passages",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path(__file__).parent.parent / "data" / "embeddings" / "passages_with_embeddings.json",
        help="Output file for passages with embeddings",
    )
    parser.add_argument(
        "--provider",
        choices=["openai", "voyage", "local"],
        default="openai",
        help="Embedding provider to use",
    )
    parser.add_argument(
        "--model",
        type=str,
        default=None,
        help="Model name (provider-specific)",
    )
    parser.add_argument(
        "--api-key",
        type=str,
        default=None,
        help="API key (or set via environment variable)",
    )
    parser.add_argument(
        "--export-format",
        choices=["pinecone", "supabase", "both"],
        default="supabase",
        help="Export format for vector database",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=50,
        help="Batch size for embedding generation",
    )
    args = parser.parse_args()

    console.print("[bold cyan]Stoic Knowledge Base - Embedding Generation[/bold cyan]")

    # Load passages
    if not args.input.exists():
        console.print(f"[red]Input file not found: {args.input}[/red]")
        console.print("[yellow]Run tag_passages.py first to create tagged passages.[/yellow]")
        return

    with open(args.input) as f:
        passages_data = json.load(f)

    passages = [Passage.model_validate(p) for p in passages_data]
    console.print(f"Loaded {len(passages)} passages")

    # Initialize provider
    if args.provider == "openai":
        api_key = args.api_key or os.getenv("OPENAI_API_KEY")
        if not api_key:
            console.print("[red]Error: OPENAI_API_KEY not set[/red]")
            return
        model = args.model or "text-embedding-3-small"
        provider = OpenAIEmbeddings(api_key, model)
        console.print(f"Using OpenAI embeddings ({model})")

    elif args.provider == "voyage":
        api_key = args.api_key or os.getenv("VOYAGE_API_KEY")
        if not api_key:
            console.print("[red]Error: VOYAGE_API_KEY not set[/red]")
            return
        model = args.model or "voyage-large-2"
        provider = VoyageEmbeddings(api_key, model)
        console.print(f"Using Voyage embeddings ({model})")

    elif args.provider == "local":
        model = args.model or "all-MiniLM-L6-v2"
        provider = LocalEmbeddings(model)
        console.print(f"Using local embeddings ({model})")

    # Generate embeddings
    passages = asyncio.run(
        generate_embeddings(passages, provider, args.batch_size)
    )

    # Save full passages
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w") as f:
        json.dump([p.model_dump() for p in passages], f, indent=2)
    console.print(f"[green]Saved passages with embeddings to {args.output}[/green]")

    # Export for vector database
    export_dir = args.output.parent
    if args.export_format in ("pinecone", "both"):
        export_for_pinecone(passages, export_dir / "pinecone_vectors.json")
    if args.export_format in ("supabase", "both"):
        export_for_supabase(passages, export_dir / "supabase_rows.json")


if __name__ == "__main__":
    main()
