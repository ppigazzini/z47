#!/usr/bin/env python3
"""Every relative `#include` in a z47 harness must resolve on disk.

WHY THIS EXISTS. The parity oracles under `build/tests/` reach into the imported
upstream tree the only way a C oracle can: by including upstream's `.c` files
directly, with a relative path (`#include "../../../upstream/src/c47/stack.c"`).
That spelling is a hard dependency on where the imported tree is mounted, and
nothing checked it.

When the import moved off the repo root, 159 such includes across 21 files went
stale at once and **13 of 14 parity oracle lanes stopped compiling**. None of that
was visible from `zig build sim`, `zig build test`, or any governance gate: the
oracle lanes are separate steps, so a run that only builds the product and the
test corpus reports success. It took `run-host-parity-battery.sh` to surface the
first one -- and that script stops at the first failure, so it named exactly one
of the thirteen.

WHAT THIS GATE DOES. Resolves every relative `#include` in z47-owned C/H against
the including file's own directory, which is what the preprocessor does for a
quoted include, and fails on any that does not exist. It is a filesystem check, so
it costs milliseconds and needs no compiler, no build, and no upstream checkout
beyond the one already in the tree. A layout change now fails here -- in a gate
whose message says which file and which include -- instead of thirteen link-time
surprises later.

WHAT IT DELIBERATELY DOES NOT DO. It does not check angle-bracket includes or
include-path-relative ones: those are resolved by `-I` flags the build owns, and
`check-build-paths.sh` already pins those. Only the relative spellings, which no
flag can rescue, are this gate's business.

Usage: check-harness-includes.py [--repo-root .]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# A quoted include whose target starts with a `../` hop. Anything else is either
# a sibling header (resolved the same way, and checked too) or an -I lookup.
INCLUDE_RE = re.compile(r'^\s*#\s*include\s*"([^"]+)"', re.MULTILINE)

TRACKED_GLOBS = ("build/**/*.c", "build/**/*.h", "bridge/**/*.c", "bridge/**/*.h")


def tracked_sources(repo: Path) -> list[Path]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", *TRACKED_GLOBS],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split("\n")
    return [repo / p for p in out if p]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    sources = tracked_sources(repo)
    if not sources:
        print("check-harness-includes: BROKEN -- found no tracked harness C/H files.")
        print("This tree is known to carry parity oracles under build/tests/.")
        print("Refusing to report a clean result from an empty scan.")
        return 1

    checked = 0
    relative = 0
    failures: list[str] = []
    for src in sources:
        try:
            text = src.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            failures.append(f"{src.relative_to(repo)}: unreadable ({exc})")
            continue
        for target in INCLUDE_RE.findall(text):
            checked += 1
            if not target.startswith(".."):
                continue
            relative += 1
            if not (src.parent / target).resolve().is_file():
                failures.append(f'{src.relative_to(repo)}: #include "{target}" does not resolve')

    if failures:
        print("HARNESS INCLUDE PATHS BROKEN:")
        for f in failures:
            print(f"  {f}")
        print()
        print("A quoted #include is resolved relative to the including file, so these")
        print("cannot be fixed by an -I flag. If the imported tree moved, the hop count")
        print("or the UPSTREAM_ROOT segment in these includes has to move with it.")
        return 1

    print(
        f"check-harness-includes: OK ({relative} relative of {checked} quoted "
        f"includes across {len(sources)} harness files, all resolve)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
