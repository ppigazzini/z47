#!/usr/bin/env python3
"""Report split first-party C status for future codebase reports."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

from c_dependency_audit import load_json, nonblank_line_count, scan_classified_entries
from retained_bridge_review import load_rows, status_counts


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Report split first-party C metrics for active product-build, "
            "retained-bridge, and parity-oracle surfaces."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    parser.add_argument(
        "--full-config",
        default=".github/project/c-dependency-allowlist.json",
        help="Path to the repo-wide C dependency audit config",
    )
    parser.add_argument(
        "--product-config",
        default=".github/project/c-dependency-product-allowlist.json",
        help="Path to the product-lane C dependency audit config",
    )
    parser.add_argument(
        "--retained-bridge-ledger",
        default=".github/project/retained-bridge-review.tsv",
        help="Path to the retained bridge review ledger",
    )
    return parser.parse_args()


def resolve_config_path(repo_root: Path, config: str) -> Path:
    return (repo_root / config).resolve() if not os.path.isabs(config) else Path(config)


def count_lines(repo_root: Path, entries: set[str]) -> int:
    return sum(nonblank_line_count(repo_root, entry) for entry in entries)


def print_table(title: str, rows: list[tuple[str, set[str]]], repo_root: Path) -> None:
    print(title)
    print("| Bucket | Files | Nonblank lines |")
    print("| --- | ---: | ---: |")
    for label, entries in rows:
        print(f"| {label} | {len(entries)} | {count_lines(repo_root, entries)} |")
    print()


def print_status_summary(title: str, counts: dict[str, int]) -> None:
    print(title)
    print("| Status | Files |")
    print("| --- | ---: |")
    for status in sorted(counts):
        print(f"| {status} | {counts[status]} |")
    print()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    full_cfg = load_json(resolve_config_path(repo_root, args.full_config))
    product_cfg = load_json(resolve_config_path(repo_root, args.product_config))
    retained_bridge_ledger_path = resolve_config_path(repo_root, args.retained_bridge_ledger)

    full_scan_files, full_classified = scan_classified_entries(repo_root, full_cfg)
    product_scan_files, product_classified = scan_classified_entries(repo_root, product_cfg)

    repo_first_party = full_classified["first-party"]
    product_first_party = product_classified["first-party"]
    retained_bridge = {entry for entry in product_first_party if entry.startswith("zig_bridge/")}
    product_source = {entry for entry in product_first_party if entry.startswith("src/")}
    other_product = product_first_party - retained_bridge - product_source
    parity_oracle = repo_first_party - product_first_party

    print("Split first-party C status")
    print(f"- product-lane scan files: {len(product_scan_files)}")
    print(f"- repo-wide scan files: {len(full_scan_files)}")
    print()

    print_table(
        "Active product-build first-party C",
        [
            ("total active product-build first-party C", product_first_party),
            ("retained bridge subset", retained_bridge),
            ("imported or generated source subset", product_source),
            ("other product-lane subset", other_product),
        ],
        repo_root,
    )

    print_table(
        "Repo-wide non-product first-party C",
        [("parity, oracle, fake-runtime, and test subset", parity_oracle)],
        repo_root,
    )

    if retained_bridge_ledger_path.exists():
        rows = load_rows(retained_bridge_ledger_path)
        print_status_summary("Retained bridge review status", status_counts(rows))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
