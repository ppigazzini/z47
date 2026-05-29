#!/usr/bin/env python3
"""Phase A: audit C dependency allowlist and first-party baseline.

This tool scans build wiring files for path-like string literals used by C wiring,
classifies them, and fails if new first-party entries are introduced relative to
a checked-in baseline file.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from c_dependency_audit import load_baseline
from c_dependency_audit import load_json
from c_dependency_audit import scan_classified_entries
from c_dependency_audit import write_baseline


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit C dependency allowlist and first-party baseline")
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    parser.add_argument("--config", required=True, help="Path to JSON allowlist config")
    parser.add_argument("--update-baseline", action="store_true", help="Rewrite baseline from current scan")
    parser.add_argument("--max-first-party", type=int, default=None, help="Fail if detected first-party entries exceed this value")
    parser.add_argument(
        "--print-first-party-count",
        action="store_true",
        help="Print detected first-party entry count and exit",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    config_path = (repo_root / args.config).resolve() if not os.path.isabs(args.config) else Path(args.config)
    cfg = load_json(config_path)

    scan_files, classified = scan_classified_entries(repo_root, cfg)

    baseline_rel = cfg.get("baseline_file")
    if not baseline_rel:
        print("ERROR: baseline_file is missing in config", file=sys.stderr)
        return 2
    baseline_path = (repo_root / baseline_rel).resolve()

    if args.print_first_party_count:
        print(len(classified["first-party"]))
        return 0

    if args.update_baseline:
        write_baseline(baseline_path, classified["first-party"])
        print(f"Updated baseline: {baseline_path}")
        print(f"First-party entries: {len(classified['first-party'])}")
        return 0

    baseline = load_baseline(baseline_path)
    new_first_party = sorted(classified["first-party"] - baseline)

    print("C dependency audit summary")
    print(f"- scanned files: {len(scan_files)}")
    print(f"- external entries: {len(classified['external'])}")
    print(f"- first-party entries: {len(classified['first-party'])}")
    print(f"- generated entries: {len(classified['generated'])}")
    print(f"- ignored entries: {len(classified['ignored'])}")
    print("- unknown-c entries: 0")

    if new_first_party:
        print("\nERROR: new first-party C dependency entries detected:")
        for e in new_first_party:
            print(f"  {e}")
        print("\nIf intentional, update baseline with:")
        print("  python3 .github/project/check-c-dependency-allowlist.py --repo-root . --config .github/project/c-dependency-allowlist.json --update-baseline")
        return 1

    if args.max_first_party is not None and len(classified["first-party"]) > args.max_first_party:
        print("\nERROR: first-party C dependency cap exceeded:")
        print(f"  detected={len(classified['first-party'])} cap={args.max_first_party}")
        return 1

    print("\nPASS: no new first-party C dependency entries detected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
