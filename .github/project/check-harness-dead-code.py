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

# Headers the BUILD generates. Without them, 23 of the 54 harness sources stopped
# at a missing include and were counted as unanalysable -- including the full-core
# parity harness, the file this project has spent three passes growing. They live
# under .zig-cache at content-addressed paths, so they are discovered rather than
# named, and a tree that has never been built simply keeps the old blind set.
GENERATED_HEADERS = ("softmenuCatalogs.h", "constantPointers.h", "gitCommitHash.h")


def discovered_flags(repo: Path) -> list[str]:
    """GTK's include paths and the build's generated header directories."""
    flags: list[str] = []
    gtk = subprocess.run(["pkg-config", "--cflags", "gtk+-3.0"], capture_output=True, text=True)
    if gtk.returncode == 0:
        flags.extend(gtk.stdout.split())
    cache = repo / ".zig-cache"
    if cache.is_dir():
        for header in GENERATED_HEADERS:
            found = next(cache.rglob(header), None)
            if found is not None:
                flags.append(f"-I{found.parent}")
    return flags


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


def measure(repo: Path) -> tuple[dict[str, list[str]], list[str]]:
    dead: dict[str, list[str]] = {}
    unanalysable: list[str] = []
    extra = discovered_flags(repo)
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

    problems = compare(counts, unanalysable, recorded, recorded_unanalysable)

    if args.self_test:
        # SYNTHETIC, deliberately. The first version of this self-test probed the
        # live measurement, so it worked only while dead code existed -- and the
        # milestone that deleted the last of it turned the self-test into a hard
        # failure inside the gate runner. A self-test that depends on the defect
        # being present tests nothing once the defect is gone.
        if not compare({"probe.c": 1}, [], {}, set()):
            print(
                "check-harness-dead-code: SELF-TEST FAILED -- a file that gained dead code passed"
            )
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
        print(
            "check-harness-dead-code: SELF-TEST OK"
            " (new dead code, a rise, and a new blind spot all fire; the baseline does not)"
        )

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
