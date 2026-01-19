"""
Local vector database using LanceDB.

Even simpler than ChromaDB - just files on disk.
No server, no Docker, pure Python.

Usage:
    python local_lancedb.py --setup
    python local_lancedb.py --query "I need calm"
"""

import argparse
import json
from pathlib import Path

import lancedb
import pyarrow as pa
from rich.console import Console
from rich.progress import Progress

console = Console()

DB_PATH = Path(__file__).parent / "lance_db"


def setup_database(data_dir: Path):
    """Load passages into LanceDB."""
    console.print("[cyan]Setting up LanceDB...[/cyan]")

    # Connect (creates directory if needed)
    db = lancedb.connect(str(DB_PATH))

    # Load passages
    passages_file = data_dir / "embeddings" / "supabase_rows.json"
    with open(passages_file) as f:
        passages = json.load(f)

    console.print(f"Preparing {len(passages)} passages...")

    # Prepare data for LanceDB
    records = []
    for p in passages:
        records.append({
            "id": p["id"],
            "text": p["text"],
            "vector": p["embedding"],
            "philosopher_id": p["philosopher_id"],
            "work_id": p["work_id"],
            "difficulty": p["difficulty"],
            "quotability": p["quotability"],
            "comfort": p["comfort"],
            "concepts": ",".join(p["tags"].get("primary_concepts", [])),
            "situations": ",".join(p["tags"].get("situations", [])),
            "emotions": ",".join(p["tags"].get("emotions", [])),
            "stress_levels": ",".join(p["health_context"].get("stress_levels", [])),
        })

    # Create table (overwrites if exists)
    console.print("Creating table...")
    table = db.create_table("passages", records, mode="overwrite")

    # Create vector index for faster search
    console.print("Creating vector index...")
    table.create_index(num_partitions=16, num_sub_vectors=48)

    console.print(f"[green]✓ Loaded {len(records)} passages into LanceDB[/green]")
    console.print(f"[green]✓ Database saved to: {DB_PATH}[/green]")


def search_with_embedding(
    query_embedding: list[float],
    n_results: int = 5,
    philosopher: str = None
) -> list[dict]:
    """Search using a pre-computed embedding."""
    db = lancedb.connect(str(DB_PATH))
    table = db.open_table("passages")

    # Build query
    query = table.search(query_embedding).limit(n_results)

    # Add filter if specified
    if philosopher:
        query = query.where(f"philosopher_id = '{philosopher}'")

    results = query.to_pandas()

    return results.to_dict("records")


def demo_search(query_text: str, n_results: int = 3):
    """
    Demo search - generates embedding and searches.

    Requires OpenAI API key for embedding generation.
    """
    import os
    from openai import OpenAI

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        console.print("[red]Set OPENAI_API_KEY for query embedding[/red]")
        console.print("[yellow]Or use search_with_embedding() directly with pre-computed vectors[/yellow]")
        return

    # Generate embedding for query
    client = OpenAI(api_key=api_key)
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=query_text
    )
    query_embedding = response.data[0].embedding

    # Search
    console.print(f"\n[cyan]Searching for:[/cyan] \"{query_text}\"")
    results = search_with_embedding(query_embedding, n_results)

    for i, r in enumerate(results):
        console.print(f"\n[bold]Result {i+1}[/bold] (distance: {r.get('_distance', 'N/A'):.3f})")
        console.print(f"[yellow]{r['text'][:200]}...[/yellow]")
        console.print(f"  Philosopher: {r['philosopher_id']}")
        console.print(f"  Concepts: {r['concepts']}")


def main():
    parser = argparse.ArgumentParser(description="Local LanceDB for Stoic passages")
    parser.add_argument("--setup", action="store_true", help="Load passages into database")
    parser.add_argument("--query", type=str, help="Search query to test")
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=Path(__file__).parent.parent / "data",
        help="Data directory",
    )
    args = parser.parse_args()

    if args.setup:
        setup_database(args.data_dir)
    elif args.query:
        demo_search(args.query)
    else:
        console.print("Use --setup to initialize or --query 'text' to search")


if __name__ == "__main__":
    main()
