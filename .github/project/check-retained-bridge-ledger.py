#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from c_dependency_audit import load_json, scan_classified_entries
from retained_bridge_review import load_rows, status_counts

LEDGER_PATH = ".github/project/retained-bridge-review.tsv"
PRODUCT_CONFIG_PATH = ".github/project/c-dependency-product-allowlist.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate that the retained bridge review ledger covers the current "
            "active product-lane bridge references exactly once."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    parser.add_argument(
        "--config",
        default=PRODUCT_CONFIG_PATH,
        help="Path to the product-lane C dependency audit config",
    )
    parser.add_argument(
        "--ledger",
        default=LEDGER_PATH,
        help="Path to the retained bridge review ledger",
    )
    return parser.parse_args()


def resolve_path(repo_root: Path, value: str) -> Path:
    return (repo_root / value).resolve() if not os.path.isabs(value) else Path(value)


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    cfg = load_json(resolve_path(repo_root, args.config))
    ledger_path = resolve_path(repo_root, args.ledger)

    _, classified = scan_classified_entries(repo_root, cfg)
    active_bridge = sorted(
        entry for entry in classified["first-party"] if entry.startswith("bridge/")
    )

    try:
        rows = load_rows(ledger_path)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    row_paths = [row["bridge_path"] for row in rows]
    duplicates = sorted({path for path in row_paths if row_paths.count(path) > 1})
    if duplicates:
        print("ERROR: duplicate retained bridge ledger rows detected:", file=sys.stderr)
        for path in duplicates:
            print(f"  {path}", file=sys.stderr)
        return 1

    missing = sorted(set(active_bridge) - set(row_paths))
    extra = sorted(set(row_paths) - set(active_bridge))
    if missing or extra:
        if missing:
            print("ERROR: retained bridge ledger is missing active paths:", file=sys.stderr)
            for path in missing:
                print(f"  {path}", file=sys.stderr)
        if extra:
            print("ERROR: retained bridge ledger lists inactive paths:", file=sys.stderr)
            for path in extra:
                print(f"  {path}", file=sys.stderr)
        return 1

    counts = status_counts(rows)
    print(f"PASS: retained bridge ledger covers {len(active_bridge)} active bridge references.")
    for status, count in counts.items():
        print(f"- {status}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
