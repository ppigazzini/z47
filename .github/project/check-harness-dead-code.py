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

WHY TEN FILES STAY BLIND. The discovery above took the blind set from 23 to 10.
The remaining ten all live beside a harness-local `c47.h` -- the fake surface --
while also reaching upstream headers by relative path. A nested `#include "c47.h"`
inside an upstream header then resolves to whichever of the two the include path
offers first, and the two disagree about `angularMode_t` and `decQuad`. A single
flat include path cannot serve both, so this is the fake-surface seam showing up
in a third place rather than a missing header. It is recorded, not worked around:
inventing an include order that happens to compile would measure a translation
unit no build produces.

TWO RATCHETS, AND THE SECOND IS THE POINT. A gate that reports only what it could
analyse reads as a clean bill for what it could not. Some harness sources do not
compile standalone -- they need generated headers -- so the number of files this
check CANNOT cover is ratcheted alongside the dead-code count. Otherwise the
cheapest way to pass this gate would be to make a file harder to compile.

THE INPUT IS DECLARED, NOT DISCOVERED, AND A MISSING INPUT IS NOT A REGRESSION.
This check needs the generated headers below. It used to hunt for them under
.zig-cache and say, in this docstring, that a tree without them "simply keeps the
old blind set". It did not: it reported 13 extra blind files and exited 1, so a
missing input and a real regression printed the same kind of failure, and the
verdict depended on whether the machine happened to have built recently. That is
REPORT-31 Annex N.2, and the fix is here: the roots are NAMED, a missing header is
reported as CANNOT MEASURE with the command that produces it, and the baselines are
not consulted at all in that case.

Exit codes:
  0  measured, within both baselines
  1  measured, a ratchet was breached
  2  NOT measured -- a declared input is missing (never a ratchet verdict)

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

# Headers the BUILD generates, and the roots that hold them. Without them the
# harness sources stop at a missing include -- including the full-core parity
# harness, the file this project has spent three passes growing.
#
# `gitCommitHash.h` was in this list and is NOT here: measured, nothing in the tree
# produces it and every harness source compiles without it. A required input that
# never resolves teaches the reader that a missing input is normal.
GENERATED_HEADERS = ("constantPointers.h", "softmenuCatalogs.h")

# Written by `zig build constants` and `zig build catalogs`, which copy the
# generator output into the imported tree. Both are gitignored, so a fresh checkout
# does not have them and this check reports CANNOT MEASURE there rather than
# inventing a bigger blind set.
DECLARED_HEADER_ROOTS = ("upstream/src/generated",)

# The build cache is the SECOND place to look, not the first, and it is named here
# rather than being the whole mechanism. `zig build sim` leaves the same headers at
# content-addressed paths.
BUILD_CACHE_ROOT = ".zig-cache"

REMEDY = "run `zig build constants catalogs` (or any full `zig build sim`) first"


def generated_header_flags(repo: Path) -> tuple[list[str], list[str]]:
    """(-I flags for the generated headers, names of the ones that are missing)."""
    flags: list[str] = []
    missing: list[str] = []
    cache = repo / BUILD_CACHE_ROOT
    for header in GENERATED_HEADERS:
        found: Path | None = None
        for root in DECLARED_HEADER_ROOTS:
            candidate = repo / root / header
            if candidate.is_file():
                found = candidate.parent
                break
        if found is None and cache.is_dir():
            hit = next(cache.rglob(header), None)
            if hit is not None:
                found = hit.parent
        if found is None:
            missing.append(header)
        else:
            flags.append(f"-I{found}")
    return flags, missing


def discovered_flags(repo: Path) -> list[str]:
    """GTK's include paths, which pkg-config owns and this check only asks for."""
    gtk = subprocess.run(["pkg-config", "--cflags", "gtk+-3.0"], capture_output=True, text=True)
    return gtk.stdout.split() if gtk.returncode == 0 else []


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


def analyse(repo: Path, rel: str, extra: list[str]) -> tuple[bool, list[str]]:
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
            *extra,
            str(source),
        ],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if REAL_ERROR_RE.search(completed.stderr):
        return False, []
    return True, sorted(set(UNUSED_RE.findall(completed.stderr)))


def measure(repo: Path, generated: list[str]) -> tuple[dict[str, list[str]], list[str]]:
    dead: dict[str, list[str]] = {}
    unanalysable: list[str] = []
    extra = discovered_flags(repo) + generated
    for rel in tracked(repo):
        ok, names = analyse(repo, rel, extra)
        if not ok:
            unanalysable.append(rel)
        elif names:
            dead[rel] = names
    return dead, sorted(unanalysable)


def compare(
    counts: dict[str, int],
    unanalysable: list[str],
    recorded: dict[str, int],
    recorded_unanalysable: set[str],
) -> list[str]:
    """Both ratchets, in one place so the self-test can drive them with synthetic data."""
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
    return problems


def self_test() -> int:
    """SYNTHETIC, deliberately, and it never touches the tree.

    The first version probed the LIVE measurement, so it worked only while dead code
    existed and the milestone that deleted the last of it turned the self-test into a
    hard failure inside the gate runner. The second version still needed the
    generated headers to be present, which is the input this check now declares --
    so a self-test could only run where the thing it was proving was already true.
    """
    if not compare({"probe.c": 1}, [], {}, set()):
        print("check-harness-dead-code: SELF-TEST FAILED -- a file that gained dead code passed")
        return 1
    if not compare({"probe.c": 2}, [], {"probe.c": 1}, set()):
        print("check-harness-dead-code: SELF-TEST FAILED -- a rise above the baseline passed")
        return 1
    if not compare({}, ["probe.c"], {}, set()):
        print("check-harness-dead-code: SELF-TEST FAILED -- a newly unanalysable file passed")
        return 1
    if compare({"probe.c": 1}, ["blind.c"], {"probe.c": 1}, {"blind.c"}):
        print("check-harness-dead-code: SELF-TEST FAILED -- the recorded state was reported")
        return 1
    # And the input-declaration half: a missing generated header must be reported as
    # CANNOT MEASURE, never as a blind-set regression. Drive it with a root that
    # cannot exist rather than by deleting the real one.
    flags, missing = generated_header_flags(Path("/nonexistent-tree-for-self-test"))
    if flags or sorted(missing) != sorted(GENERATED_HEADERS):
        print(
            "check-harness-dead-code: SELF-TEST FAILED -- a tree with no generated headers"
            " did not report every one of them missing"
        )
        return 1
    print(
        "check-harness-dead-code: SELF-TEST OK"
        " (new dead code, a rise, and a new blind spot all fire; the baseline does not;"
        " a missing declared input is reported as such)"
    )
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record both baselines")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    if args.self_test:
        return self_test()

    generated, missing = generated_header_flags(repo)
    if missing:
        # DELIBERATELY NOT EXIT 1. A ratchet verdict says somebody made the tree
        # worse; this says the check could not look. Printing the same thing for
        # both is what let a never-built tree read as a 13-file regression.
        print("check-harness-dead-code: CANNOT MEASURE -- declared input missing")
        for header in missing:
            print(f"    {header}: not in {', '.join(DECLARED_HEADER_ROOTS)} nor {BUILD_CACHE_ROOT}")
        print(f"  {REMEDY}. No baseline was consulted; this is not a ratchet failure.")
        return 2

    dead, unanalysable = measure(repo, generated)
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

    problems = compare(counts, unanalysable, recorded, recorded_unanalysable)

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
