"""
Upload passages and philosophers to Supabase.

Prerequisites:
1. Create a Supabase project at https://supabase.com
2. Run schema.sql in the SQL Editor
3. Get your project URL and service role key from Settings > API

Usage:
    python upload_to_supabase.py --url YOUR_SUPABASE_URL --key YOUR_SERVICE_ROLE_KEY
"""

import argparse
import json
from pathlib import Path

from rich.console import Console
from rich.progress import Progress
from supabase import create_client, Client

console = Console()


def load_data(data_dir: Path) -> tuple[list, list]:
    """Load passages and philosophers data."""
    # Load passages with embeddings
    passages_file = data_dir / "embeddings" / "supabase_rows.json"
    with open(passages_file) as f:
        passages = json.load(f)
    console.print(f"Loaded {len(passages)} passages")

    # Load philosophers
    philosophers_file = data_dir / "philosophers.json"
    with open(philosophers_file) as f:
        philosophers = json.load(f)
    console.print(f"Loaded {len(philosophers)} philosophers")

    return passages, philosophers


def upload_philosophers(client: Client, philosophers: list):
    """Upload philosopher profiles."""
    console.print("\n[cyan]Uploading philosophers...[/cyan]")

    for p in philosophers:
        data = {
            "id": p["id"],
            "name": p["name"],
            "era": p["era"],
            "biography": p["biography"],
            "teaching_style": p["teaching_style"],
            "core_themes": p["core_themes"],
            "personality_traits": p["personality_traits"],
            "voice_guidelines": p.get("voice_guidelines", {}),
            "signature_quotes": p.get("signature_quotes", []),
            "unlock_criteria": p.get("unlock_criteria", {}),
        }

        try:
            client.table("philosophers").upsert(data).execute()
            console.print(f"  [green]✓[/green] {p['name']}")
        except Exception as e:
            console.print(f"  [red]✗[/red] {p['name']}: {e}")


def upload_passages(client: Client, passages: list, batch_size: int = 100):
    """Upload passages in batches."""
    console.print(f"\n[cyan]Uploading {len(passages)} passages...[/cyan]")

    with Progress() as progress:
        task = progress.add_task("Uploading", total=len(passages))

        for i in range(0, len(passages), batch_size):
            batch = passages[i:i + batch_size]

            # Format for Supabase
            rows = []
            for p in batch:
                row = {
                    "id": p["id"],
                    "philosopher_id": p["philosopher_id"],
                    "work_id": p["work_id"],
                    "book": p.get("book"),
                    "chapter": p.get("chapter"),
                    "letter": p.get("letter"),
                    "text": p["text"],
                    "embedding": p["embedding"],
                    "tags": p["tags"],
                    "health_context": p["health_context"],
                    "difficulty": p["difficulty"],
                    "quotability": p["quotability"],
                    "actionability": p["actionability"],
                    "comfort": p["comfort"],
                }
                rows.append(row)

            try:
                client.table("passages").upsert(rows).execute()
            except Exception as e:
                console.print(f"\n[red]Error uploading batch {i}-{i+batch_size}: {e}[/red]")

            progress.update(task, advance=len(batch))

    console.print("[green]Upload complete![/green]")


def verify_upload(client: Client):
    """Verify the upload by running some queries."""
    console.print("\n[cyan]Verifying upload...[/cyan]")

    # Count passages
    result = client.table("passages").select("id", count="exact").execute()
    console.print(f"  Passages in database: {result.count}")

    # Count philosophers
    result = client.table("philosophers").select("id", count="exact").execute()
    console.print(f"  Philosophers in database: {result.count}")

    # Test semantic search (using RPC)
    console.print("\n[cyan]Testing semantic search...[/cyan]")
    console.print("  (Requires a sample query embedding)")


def main():
    parser = argparse.ArgumentParser(description="Upload Stoic knowledge base to Supabase")
    parser.add_argument("--url", required=True, help="Supabase project URL")
    parser.add_argument("--key", required=True, help="Supabase service role key")
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=Path(__file__).parent.parent / "data",
        help="Data directory",
    )
    parser.add_argument("--batch-size", type=int, default=100, help="Upload batch size")
    args = parser.parse_args()

    console.print("[bold cyan]Stoic Knowledge Base - Supabase Upload[/bold cyan]")

    # Initialize Supabase client
    client = create_client(args.url, args.key)
    console.print(f"Connected to Supabase: {args.url}")

    # Load data
    passages, philosophers = load_data(args.data_dir)

    # Upload
    upload_philosophers(client, philosophers)
    upload_passages(client, passages, args.batch_size)

    # Verify
    verify_upload(client)

    console.print("\n[bold green]✓ Knowledge base uploaded successfully![/bold green]")
    console.print("\nNext steps:")
    console.print("1. Test the match_passages function in SQL Editor")
    console.print("2. Set up Edge Functions for the API")
    console.print("3. Connect your Watch app to the API")


if __name__ == "__main__":
    main()
