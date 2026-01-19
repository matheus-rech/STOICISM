"""
Local vector database using ChromaDB.

No cloud services needed - everything runs locally.
Data persists to disk at ./chroma_db/

Usage:
    python local_chromadb.py --setup     # Load passages into ChromaDB
    python local_chromadb.py --query "I feel anxious"  # Test search
"""

import argparse
import json
from pathlib import Path

import chromadb
from chromadb.config import Settings
from rich.console import Console
from rich.progress import Progress

console = Console()

# Persistent local storage
DB_PATH = Path(__file__).parent / "chroma_db"


def get_client() -> chromadb.PersistentClient:
    """Get ChromaDB client with persistent storage."""
    return chromadb.PersistentClient(
        path=str(DB_PATH),
        settings=Settings(anonymized_telemetry=False)
    )


def setup_database(data_dir: Path):
    """Load passages into ChromaDB."""
    console.print("[cyan]Setting up ChromaDB...[/cyan]")

    client = get_client()

    # Create or get collection
    collection = client.get_or_create_collection(
        name="stoic_passages",
        metadata={"description": "Stoic philosophy passages with embeddings"}
    )

    # Load passages
    passages_file = data_dir / "embeddings" / "supabase_rows.json"
    with open(passages_file) as f:
        passages = json.load(f)

    console.print(f"Loading {len(passages)} passages...")

    # ChromaDB can batch upsert
    with Progress() as progress:
        task = progress.add_task("Adding passages", total=len(passages))

        batch_size = 100
        for i in range(0, len(passages), batch_size):
            batch = passages[i:i + batch_size]

            ids = [p["id"] for p in batch]
            embeddings = [p["embedding"] for p in batch]
            documents = [p["text"] for p in batch]
            metadatas = [
                {
                    "philosopher_id": p["philosopher_id"],
                    "work_id": p["work_id"],
                    "difficulty": p["difficulty"],
                    "quotability": p["quotability"],
                    "comfort": p["comfort"],
                    "concepts": ",".join(p["tags"].get("primary_concepts", [])),
                    "situations": ",".join(p["tags"].get("situations", [])),
                    "emotions": ",".join(p["tags"].get("emotions", [])),
                    "stress_levels": ",".join(p["health_context"].get("stress_levels", [])),
                }
                for p in batch
            ]

            collection.upsert(
                ids=ids,
                embeddings=embeddings,
                documents=documents,
                metadatas=metadatas,
            )

            progress.update(task, advance=len(batch))

    console.print(f"[green]✓ Loaded {collection.count()} passages into ChromaDB[/green]")
    console.print(f"[green]✓ Database saved to: {DB_PATH}[/green]")


def search(query_text: str, n_results: int = 5, philosopher: str = None):
    """
    Search for relevant passages.

    Note: For production, you'd generate embeddings from query_text.
    This example uses ChromaDB's built-in embedding (requires sentence-transformers).
    """
    client = get_client()
    collection = client.get_collection("stoic_passages")

    # Build filter
    where_filter = None
    if philosopher:
        where_filter = {"philosopher_id": philosopher}

    # Query - ChromaDB will use its default embedder for the query
    # For production with OpenAI embeddings, you'd pass query_embeddings instead
    results = collection.query(
        query_texts=[query_text],
        n_results=n_results,
        where=where_filter,
        include=["documents", "metadatas", "distances"]
    )

    return results


def search_with_embedding(query_embedding: list[float], n_results: int = 5, filters: dict = None):
    """Search using a pre-computed embedding (e.g., from OpenAI)."""
    client = get_client()
    collection = client.get_collection("stoic_passages")

    where_filter = None
    if filters:
        where_filter = filters

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        where=where_filter,
        include=["documents", "metadatas", "distances"]
    )

    return results


def demo_search(query: str):
    """Demo search functionality."""
    console.print(f"\n[cyan]Searching for:[/cyan] \"{query}\"")

    results = search(query, n_results=3)

    if results["documents"][0]:
        for i, (doc, meta, dist) in enumerate(zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0]
        )):
            console.print(f"\n[bold]Result {i+1}[/bold] (distance: {dist:.3f})")
            console.print(f"[yellow]{doc[:200]}...[/yellow]")
            console.print(f"  Philosopher: {meta['philosopher_id']}")
            console.print(f"  Concepts: {meta['concepts']}")
    else:
        console.print("[red]No results found[/red]")


def main():
    parser = argparse.ArgumentParser(description="Local ChromaDB for Stoic passages")
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
        console.print("\nExample:")
        console.print("  python local_chromadb.py --setup")
        console.print("  python local_chromadb.py --query 'I feel anxious about the future'")


if __name__ == "__main__":
    main()
