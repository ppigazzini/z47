#!/usr/bin/env python3
"""Unreachable code in a test harness reads as coverage. Count it.

WHY THIS EXISTS. `clang -Wunused-function` over the harness sources finds 135
unreachable `static` functions, and 94 of them are `configure*` fixtures in the
math-wrapper driver whose names say exactly what happened: `configureUnitVector*`,
`configureCheckInteger*`, `configureCheckForZero*`, `configureCompare*` -- every
one belongs to a wrapper whose coverage MOVED to the full-core lane. The cases were
deleted and the fixtures were left behind.

That makes them evidence rather than litter. Each is a register configuration
somebody once thought worth driving, and at least one names a shape the migration
dropped: `configureDecompLongInteger` seeds `dtLongInteger, LI_NEGATIVE`, and the
lane it moved to had no negative long integer until the sign partition was added.

The same technique found the twenty dead statics deleted from
`math_wrappers_oracle.c` -- four of which were mirrors of c43 helpers that had
DRIFTED, silently, because nothing called them.

TWO RATCHETS, AND THE SECOND IS THE POINT. A gate that reports only what it could
analyse reads as a clean bill for what it could not. 23 of the 54 harness sources
do not compile standalone -- they need generated headers that only exist inside a
build tree -- so the dead-code count covers 31 files, and the number of files it
CANNOT cover is ratcheted too. Otherwise the cheapest way to pass this gate would
be to make a file harder to compile.

Usage:
  check-harness-dead-code.py [--repo-root .]
  check-harness-dead-code.py --bump        # re-record both baselines
  check-harness-dead-code.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

BASELINE = ".github/project/harness-dead-code-baseline.json"
GLOBS = ("build/tests/**/*.c",)

# The host build's own macros and include roots. Without them most of these files
# stop at `One of PC_BUILD and DMCP_BUILD must be defined` and would be counted as
# analysable-with-zero-findings, which is the wrong answer twice over.
COMMON_FLAGS = (
    "-DPC_BUILD=1",
    "-DLINUX=1",
    "-DOS64BIT=1",
    "-DDECNUMBER_FASTMUL=1",
    "-DTESTSUITE_BUILD=1",
    "-Iupstream/src/c47",
    "-Iupstream/dep/decNumberICU",
    "-Iupstream/src/testSuite",
)

UNUSED_RE = re.compile(r"unused function '(\w+)'")
# zig cc emits a trailing `FileNotFound` diagnostic of its own after a successful
# -fsyntax-only run; it is not a compile error in the source.
REAL_ERROR_RE = re.compile(r"^(?!.*FileNotFound).*error:", re.M)


def tracked(repo: Path) -> list[str]:
    return subprocess.run(
        ["git", "-C", str(repo), "ls-files", *GLOBS],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()


def analyse(repo: Path, rel: str) -> tuple[bool, list[str]]:
    """(analysable, dead function names)."""
    source = repo / rel
    completed = subprocess.run(
        [
            "zig",
            "cc",
            "-fsyntax-only",
            "-Wunused-function",
            f"-I{source.parent}",
            *COMMON_FLAGS,
            str(source),
        ],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if REAL_ERROR_RE.search(completed.stderr):
        return False, []
    return True, sorted(set(UNUSED_RE.findall(completed.stderr)))


def measure(repo: Path) -> tuple[dict[str, list[str]], list[str]]:
    dead: dict[str, list[str]] = {}
    unanalysable: list[str] = []
    for rel in tracked(repo):
        ok, names = analyse(repo, rel)
        if not ok:
            unanalysable.append(rel)
        elif names:
            dead[rel] = names
    return dead, sorted(unanalysable)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record both baselines")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    dead, unanalysable = measure(repo)
    counts = {rel: len(names) for rel, names in sorted(dead.items())}
    total = sum(counts.values())

    if args.bump:
        (repo / BASELINE).write_text(
            json.dumps(
                {
                    "_why": (
                        "Unreachable static functions in harness sources, and the harness"
                        " sources this check cannot analyse. Both may FALL and may not rise:"
                        " the first because dead test code reads as coverage, the second"
                        " because a gate that reports only what it could analyse reads as a"
                        " clean bill for what it could not."
                    ),
                    "dead_statics": counts,
                    "unanalysable": unanalysable,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        print(
            f"check-harness-dead-code: recorded {total} dead static(s) across"
            f" {len(counts)} file(s), {len(unanalysable)} unanalysable"
        )
        return 0

    baseline_path = repo / BASELINE
    if not baseline_path.is_file():
        print(f"check-harness-dead-code: BROKEN -- missing {BASELINE}. Run --bump.")
        return 1
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    recorded = baseline.get("dead_statics", {})
    recorded_unanalysable = set(baseline.get("unanalysable", []))

    analysed = len(tracked(repo)) - len(unanalysable)
    print(
        f"check-harness-dead-code: {total} unreachable static(s) across {len(counts)} file(s),"
        f" analysed {analysed} of {len(tracked(repo))} harness source(s)"
    )
    for rel, count in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"    {count:>4}  {rel}")

    problems: list[str] = []
    for rel, count in counts.items():
        allowed = recorded.get(rel)
        if allowed is None:
            problems.append(f"{rel}: {count} unreachable static(s) in a file that had none")
        elif count > allowed:
            problems.append(f"{rel}: unreachable statics rose {allowed} -> {count}")

    new_blind = sorted(set(unanalysable) - recorded_unanalysable)
    if new_blind:
        problems.append(
            "harness source(s) this check can no longer analyse:\n    "
            + ", ".join(new_blind)
            + "\n    Making a file harder to compile is not a way to pass this gate."
        )

    if args.self_test:
        # The ratchet direction, through the same comparison a real run uses.
        probe = dict(counts)
        victim = next(iter(probe), None)
        if victim is None:
            print("check-harness-dead-code: SELF-TEST BROKEN -- nothing to probe")
            return 1
        if probe[victim] + 1 <= recorded.get(victim, 0):
            print("check-harness-dead-code: SELF-TEST BROKEN -- baseline is above the measurement")
            return 1
        print("check-harness-dead-code: SELF-TEST OK -- a rise above the baseline is a failure")

    if problems:
        print("\nHARNESS DEAD CODE:")
        for problem in problems:
            print(f"  {problem}")
        print(
            "\nRead them before deleting them. These are register configurations somebody"
            "\nonce drove, and they are the only record of what a lane covered before its"
            "\ncases moved elsewhere."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
