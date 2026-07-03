#!/usr/bin/env python3
"""Idiom-status census for the REPORT-23 idiomatic-Zig refactor (Phase infinity).

Counts the transliteration anti-patterns REPORT-23 §2 tracks, across zig_src/,
as a whole-tree total and per-owner. This is the ratchet metric: the numbers are
meant to fall as owners move to the L1/L2/L3 shape. A companion gate
(check-idiom-ratchet, wired non-blocking until REPORT-23 Phase 2) compares a
recorded baseline to forbid regressions.

Reproduces the §2 census with explicit, greppable patterns so the report and the
gate agree. Usage:

    python3 .github/project/report-idiom-status.py [--repo-root .] [--json]
    python3 .github/project/report-idiom-status.py --write-baseline
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BASELINE_PATH = ".github/project/idiom-status-baseline.json"

# (label, compiled regex, count_mode) -- count_mode "file" counts matching files,
# "site" counts total matches.
PATTERNS = [
    ("extern_struct_files", re.compile(r"extern struct"), "file"),
    ("cptr_files", re.compile(r"\[\*c\]"), "file"),
    ("ptrcast_sites", re.compile(r"@(?:ptrCast|alignCast)\("), "site"),
    ("callconv_c_sites", re.compile(r"callconv\(\.c\)"), "site"),
    ("printf_family_files", re.compile(r"\bs?n?printf\("), "file"),
    ("anyopaque_files", re.compile(r"anyopaque"), "file"),
    ("off_offset_sites", re.compile(r"\bOFF_[A-Za-z0-9_]+"), "site"),
    ("constants_blob_sites", re.compile(r'@extern\(\[\*\]const u8, \.\{ \.name = "constants"'), "site"),
    ("qspi_section_files", re.compile(r'"\.qspi_data"'), "file"),
]


def scan(repo_root: Path) -> dict:
    zig_root = repo_root / "zig_src"
    files = sorted(p for p in zig_root.rglob("*.zig"))

    totals = {label: 0 for label, _, _ in PATTERNS}
    per_owner: dict[str, dict] = {}
    owner_count = 0

    for path in files:
        rel = path.relative_to(repo_root).as_posix()
        text = path.read_text(encoding="utf-8", errors="ignore")
        row = {}
        for label, rx, mode in PATTERNS:
            matches = rx.findall(text)
            n = (1 if matches else 0) if mode == "file" else len(matches)
            row[label] = n
            totals[label] += n
        if path.name.endswith("_owned.zig"):
            owner_count += 1
        if any(row.values()):
            per_owner[rel] = row

    return {
        "file_count": len(files),
        "owner_count": owner_count,
        "totals": totals,
        "per_owner": per_owner,
    }


def print_report(result: dict) -> None:
    print(f"zig_src files: {result['file_count']}  owners: {result['owner_count']}")
    print("\nWhole-tree anti-pattern totals (REPORT-23 §2):")
    for label, _, mode in PATTERNS:
        print(f"  {label:26s} {result['totals'][label]:6d}  ({mode})")
    worst = sorted(
        result["per_owner"].items(),
        key=lambda kv: sum(kv[1].values()),
        reverse=True,
    )[:10]
    print("\nTop 10 owners by total anti-pattern count:")
    for rel, row in worst:
        print(f"  {sum(row.values()):5d}  {rel}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--json", action="store_true", help="emit the full census as JSON")
    ap.add_argument("--write-baseline", action="store_true", help="record totals to the baseline file")
    args = ap.parse_args()

    repo_root = Path(args.repo_root).resolve()
    result = scan(repo_root)

    if args.write_baseline:
        baseline = {"totals": result["totals"], "owner_count": result["owner_count"]}
        (repo_root / BASELINE_PATH).write_text(json.dumps(baseline, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {BASELINE_PATH}")
        return 0

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_report(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
