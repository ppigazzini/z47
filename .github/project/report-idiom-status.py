#!/usr/bin/env python3
"""Idiom-status census for the REPORT-23 idiomatic-Zig refactor (Phase infinity).

Counts the transliteration anti-patterns REPORT-23 §2 tracks, across zig_src/,
per-owner. The census is split into two layers (churn-driven roadmap): CORE
(hand-written owner code) is the ratchet ceiling metric and is meant to fall as
owners move to idiomatic Zig; SEAM (generated ABI shims -- files under a
generated/ path carrying the '// SEAM-GENERATED' marker) holds the
contract-mandated C-ABI shapes and is reported separately, never graded. A
marker/path mismatch fails closed so a hand-written owner cannot dodge the
ceiling by faking the marker. A companion gate (check-idiom-ratchet) compares a
recorded baseline to forbid regressions in the CORE totals.

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

# Seam-and-core split (churn-driven roadmap). A "seam" file is a generated ABI
# shim: it holds the contract-mandated C-ABI shapes (extern struct / callconv(.c)
# / offsets) derived from upstream C, so it is graded separately from
# hand-written owner ("core") code. A seam file MUST both live under a
# `generated/` path in zig_src AND carry the marker below; a file with exactly
# one of those signals is a fail-closed guard violation, so a hand-written owner
# cannot smuggle debt out of the core ceiling by faking the marker.
SEAM_MARKER = "// SEAM-GENERATED"
SEAM_PATH_TOKEN = "/generated/"


def classify_layer(rel: str, text: str) -> tuple[str, str | None]:
    """Return (layer, violation). layer is 'seam' or 'core'; violation is a
    message when the marker and path signals disagree (fail closed)."""
    under_generated = SEAM_PATH_TOKEN in rel
    has_marker = SEAM_MARKER in text
    if under_generated and has_marker:
        return "seam", None
    if under_generated and not has_marker:
        return "core", f"{rel}: under generated/ but missing '{SEAM_MARKER}' marker"
    if has_marker and not under_generated:
        return "core", f"{rel}: has '{SEAM_MARKER}' marker but is not under a generated/ path"
    return "core", None

# (label, compiled regex, count_mode) -- count_mode "file" counts matching files,
# "site" counts total matches.
PATTERNS = [
    ("extern_struct_files", re.compile(r"extern struct"), "file"),
    ("cptr_files", re.compile(r"\[\*c\]"), "file"),
    ("ptrcast_sites", re.compile(r"@(?:ptrCast|alignCast)\("), "site"),
    ("callconv_c_sites", re.compile(r"callconv\(\.c\)"), "site"),
    # Zig-to-Zig `extern fn` redeclarations are transliteration debt: an owner
    # calling another owner's Zig-defined symbol through an untyped C-ABI extern
    # instead of a typed @import. Ratcheted down as owners convert to @import
    # (M-callconv). Floor is the genuine C boundary (GMP/decNumber/DMCP SDK) +
    # cross-module externs pending build-graph module wiring.
    ("extern_fn_sites", re.compile(r"\bextern fn "), "site"),
    ("printf_family_files", re.compile(r"\bs?n?printf\("), "file"),
    ("anyopaque_files", re.compile(r"anyopaque"), "file"),
    ("off_offset_sites", re.compile(r"\bOFF_[A-Za-z0-9_]+"), "site"),
    ("constants_blob_sites", re.compile(r'@extern\(\[\*\]const u8, \.\{ \.name = "constants"'), "site"),
    ("qspi_section_files", re.compile(r'"\.qspi_data"'), "file"),
]


def scan(repo_root: Path) -> dict:
    zig_root = repo_root / "zig_src"
    files = sorted(p for p in zig_root.rglob("*.zig"))

    # `totals` is the CORE (hand-written) census -- the ratchet ceiling metric.
    # `seam_totals` is the generated ABI-seam census, reported for visibility but
    # never graded against the ceiling.
    totals = {label: 0 for label, _, _ in PATTERNS}
    seam_totals = {label: 0 for label, _, _ in PATTERNS}
    per_owner: dict[str, dict] = {}
    owner_count = 0
    seam_file_count = 0
    violations: list[str] = []

    for path in files:
        rel = path.relative_to(repo_root).as_posix()
        text = path.read_text(encoding="utf-8", errors="ignore")
        layer, violation = classify_layer(rel, text)
        if violation:
            violations.append(violation)
        bucket = seam_totals if layer == "seam" else totals
        row = {}
        for label, rx, mode in PATTERNS:
            matches = rx.findall(text)
            n = (1 if matches else 0) if mode == "file" else len(matches)
            row[label] = n
            bucket[label] += n
        if layer == "seam":
            seam_file_count += 1
            continue
        # "Owner" = an idiomatic core file. The historical `_owned` role suffix was
        # dropped in M25 (project structure), so count every zig_src file that is
        # not an L3 C-ABI runtime/shared shim.
        if not path.name.endswith(("_runtime.zig", "_shared.zig")):
            owner_count += 1
        if any(row.values()):
            per_owner[rel] = row

    return {
        "file_count": len(files),
        "owner_count": owner_count,
        "seam_file_count": seam_file_count,
        "totals": totals,
        "seam_totals": seam_totals,
        "per_owner": per_owner,
        "violations": violations,
    }


def print_report(result: dict) -> None:
    print(f"zig_src files: {result['file_count']}  owners: {result['owner_count']}"
          f"  seam files: {result['seam_file_count']}")
    print("\nCore (hand-written) anti-pattern totals -- ratchet ceiling (REPORT-23 §2):")
    for label, _, mode in PATTERNS:
        print(f"  {label:26s} {result['totals'][label]:6d}  ({mode})")
    if result["seam_file_count"]:
        print("\nSeam (generated ABI) totals -- reported, NOT graded:")
        for label, _, mode in PATTERNS:
            print(f"  {label:26s} {result['seam_totals'][label]:6d}  ({mode})")
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
    ap.add_argument("--check", action="store_true", help="compare to baseline; exit 1 if any metric rose")
    args = ap.parse_args()

    repo_root = Path(args.repo_root).resolve()
    result = scan(repo_root)

    # The seam guard fails closed in every mode that writes or enforces state, so
    # a marker/path mismatch can never silently exempt a hand-written owner.
    if result["violations"] and (args.check or args.write_baseline):
        for v in result["violations"]:
            print(f"SEAM SCOPE VIOLATION: {v}")
        print("A seam file must live under a generated/ path AND carry the "
              f"'{SEAM_MARKER}' marker. Fix the file or its location.")
        return 1

    if args.check:
        baseline = json.loads((repo_root / BASELINE_PATH).read_text(encoding="utf-8"))["totals"]
        cur = result["totals"]
        rc = 0
        for key, ceiling in baseline.items():
            have = cur.get(key, 0)
            if have > ceiling:
                print(f"IDIOM RATCHET REGRESSION: {key} = {have}, baseline ceiling {ceiling} -- "
                      "a transliteration anti-pattern grew. Reduce it, or raise the ceiling with "
                      "an explicit justification (--write-baseline).")
                rc = 1
            elif have < ceiling:
                print(f"{key} = {have} (below ceiling {ceiling}) -- run --write-baseline to lock the gain")
            else:
                print(f"{key} = {have} (at ceiling)")
        return rc

    if args.write_baseline:
        baseline = {
            "totals": result["totals"],
            "owner_count": result["owner_count"],
            "seam_totals": result["seam_totals"],
            "seam_file_count": result["seam_file_count"],
        }
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
