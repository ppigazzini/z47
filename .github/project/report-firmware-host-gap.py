#!/usr/bin/env python3
"""Enumerate the DMCP-only firmware surface in the Zig owners (Annex A4).

Code guarded by `dmcp_build` runs only on the DM42/DM42n firmware target; the
host build compiles it but never executes it, so host tests cannot catch a
regression there. For M10 readiness every such region must be ACCOUNTED FOR --
either host-executed by a test (e.g. the M4 ring-buffer drain) or listed in the
M9 hardware-smoke checklist -- so nothing firmware-only is silently uncovered.

This report lists every `dmcp_build`-gated region in zig_src/, with its file,
line, and enclosing `pub fn`, grouped by owner. It is the inventory the M9
checklist (.github/project/M9-hardware-smoke-checklist.md) must cover.

Usage: report-firmware-host-gap.py [--repo-root .] [--owner-summary]
Exit code: 0 always (report).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

GATE_RE = re.compile(r"\bdmcp_build\b")
FN_RE = re.compile(r"\b(?:pub\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")


def enclosing_fn(lines: list[str], idx: int) -> str:
    """Nearest `fn name(` at or above line idx (best-effort, by lexical scan)."""
    for j in range(idx, -1, -1):
        m = FN_RE.search(lines[j])
        if m:
            return m.group(1)
    return "<file scope>"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    ap.add_argument(
        "--owner-summary", action="store_true", help="print only per-owner gated-region counts"
    )
    args = ap.parse_args()
    root = Path(args.repo_root)
    zig_src = root / "zig_src"

    total = 0
    per_owner: dict[str, list[tuple[int, str]]] = {}
    for path in sorted(zig_src.rglob("*.zig")):
        lines = path.read_text(errors="replace").splitlines()
        hits = []
        for i, line in enumerate(lines):
            if GATE_RE.search(line):
                hits.append((i + 1, enclosing_fn(lines, i)))
        if hits:
            per_owner[str(path.relative_to(root))] = hits
            total += len(hits)

    print(
        f"DMCP-only (dmcp_build-gated) regions in zig_src: {total} across {len(per_owner)} owners"
    )
    print(
        "Each MUST be host-executed by a test OR covered by the M9 hardware "
        "checklist -- none silently uncovered.\n"
    )

    for owner, hits in per_owner.items():
        if args.owner_summary:
            print(f"{len(hits):4d}  {owner}")
            continue
        print(f"{owner}  ({len(hits)} region(s)):")
        fns = sorted({fn for _, fn in hits})
        for fn in fns:
            ls = [str(ln) for ln, f in hits if f == fn]
            print(f"  - {fn}  (line{'s' if len(ls) > 1 else ''} {', '.join(ls)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
