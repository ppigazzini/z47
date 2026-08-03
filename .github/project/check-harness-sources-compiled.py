#!/usr/bin/env python3
"""A harness source no build step compiles is a file, not coverage.

WHY THIS EXISTS. `check-parity-lanes-gated.py` found four parity lanes the build
declared, that were buildable and green, and that NOTHING ran. This is the same
defect one level down: four `.c` files under `build/tests/` that compile from c43
source correctly and that no build step compiles.

The worst of them was not dead code. `math_wrappers_transform_oracle.c` is a
FINISHED compile-from-c43 conversion of `fnToRect` -- it `#define`s the names and
`#include`s `mathematics/toRect.c`, which is the shape every parity oracle in this
tree is supposed to have. Beside it, in the file the lane actually links, sat 73
hand-written lines reimplementing the same function. The conversion had been done
and never wired up, so the lane kept comparing against the transliteration.

Nothing could have reported that. The provenance gate answers "where did this
reference come from" and this file came from c43. The lane gate answers "is this
lane run" and the lane was. Neither asks "is this FILE connected to anything",
which is the question here and is why this is a separate gate rather than a clause
in either of those.

HOW IT WORKS. Every tracked `.c` under `build/tests/` must be named by some
`b.path(...)` in a tracked `.zig` build file. Zig string concatenation is folded
first, because the build really does write
`b.path("build/tests/math_wrappers/" ++ "random_fake_runtime_helpers.c")` and a
gate that missed that would report a compiled file as orphaned -- the failure mode
that teaches people to add exemptions.

EXEMPTIONS COST A REASON, on the same argument as the deliberate-divergence list in
`check-harness-constant-copies.py` and the exemption list in
`check-parity-lanes-gated.py`: a decision with a reason is a decision, one without
is an oversight that learned to hide. A file may be uncompiled -- some exist to be
`#include`d, some are a reference kept beside a lane on purpose -- but the sentence
saying which has to be written down.

THE BACKLOG IS SEPARATE FROM THE EXEMPTIONS, and the difference is the point. An
exemption says "this file is not meant to be compiled". The backlog says "this file
is meant to be compiled and is not, and nobody has fixed it yet". Putting the four
into EXEMPT would have made the gate green by writing down a reason that is not
true. The backlog may only shrink; its endpoint is empty.

Usage:
  check-harness-sources-compiled.py [--repo-root .]
  check-harness-sources-compiled.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

HARNESS_GLOBS = ("build/tests/**/*.c",)
BUILD_GLOBS = ("build/**/*.zig", "*.zig")

# `"a" ++ "b"` is one path spelled in two literals. Fold it before looking for a
# path, or a compiled file reads as an orphan.
CONCATENATION_RE = re.compile(r'"\s*\+\+\s*"', re.S)

# Uncompiled on purpose. The value is the reason, and an empty one fails the gate.
EXEMPT: dict[str, str] = {
    "build/tests/math_wrappers/math_ln_complex_runtime_constants.c": (
        "Not linked on purpose, and steps.zig says so at the site: the"
        " z47_math_wrappers_const_* accessors it defines come from the owner now, so"
        " linking it would give the lane a second definition of the constants it is"
        " supposed to be checking."
    ),
}


# Meant to be compiled, and is not. NOT an exemption: no reason here is a good one,
# and writing a plausible sentence beside each would have made the gate green while
# the defect stayed. May only shrink; the endpoint is empty.
BACKLOG: frozenset[str] = frozenset(
    {
        "build/tests/math_wrappers/math_wrappers_dispatch_oracle.c",
        "build/tests/math_wrappers/math_wrappers_misc_oracle.c",
        "build/tests/math_wrappers/math_wrappers_percent_oracle.c",
        "build/tests/math_wrappers/math_wrappers_transform_oracle.c",
    }
)


def tracked(repo: Path, globs: tuple[str, ...]) -> list[str]:
    return subprocess.run(
        ["git", "-C", str(repo), "ls-files", *globs],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()


def build_text(repo: Path) -> str:
    joined = "\n".join(
        (repo / rel).read_text(errors="replace") for rel in tracked(repo, BUILD_GLOBS)
    )
    return CONCATENATION_RE.sub("", joined)


def orphans(sources: list[str], blob: str) -> list[str]:
    return sorted(rel for rel in sources if rel not in blob and rel not in EXEMPT)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    blob = build_text(repo)
    sources = tracked(repo, HARNESS_GLOBS)
    found = orphans(sources, blob)

    unreasoned = sorted(rel for rel, why in EXEMPT.items() if not why.strip())
    if unreasoned:
        print("EXEMPT WITHOUT A REASON:")
        for rel in unreasoned:
            print(f"  {rel}")
        return 1

    print(
        f"check-harness-sources-compiled: {len(sources)} harness source(s),"
        f" {len(sources) - len(found) - len(EXEMPT)} compiled,"
        f" {len(EXEMPT)} exempt with a reason, {len(found)} compiled by nothing"
        f" ({len(BACKLOG)} recorded)"
    )

    if args.self_test:
        # Run the real extractor over the real blob with one path added that the
        # build cannot name, and require it back. Asserting a probe without passing
        # it through the extractor would prove only that the string was typed twice.
        probe = "build/tests/scratch/never_compiled_probe.c"
        if probe in blob or probe in EXEMPT:
            print("check-harness-sources-compiled: SELF-TEST BROKEN -- probe path is not novel")
            return 1
        if probe not in orphans([*sources, probe], blob):
            print(
                "check-harness-sources-compiled: SELF-TEST FAILED -- an uncompiled source"
                " went unreported"
            )
            return 1
        # And the fold: a concatenated path must NOT read as an orphan. Passed
        # through the same extractor, against the blob it really appears in.
        folded = "build/tests/math_wrappers/random_fake_runtime_helpers.c"
        if folded in orphans([folded], blob):
            print(
                "check-harness-sources-compiled: SELF-TEST FAILED -- a path the build"
                " spells with `++` reads as uncompiled"
            )
            return 1
        print(
            "check-harness-sources-compiled: SELF-TEST OK"
            " (an uncompiled source is reported, a concatenated path is not)"
        )

    new = [rel for rel in found if rel not in BACKLOG]
    if new:
        print("\nHARNESS SOURCES NO BUILD STEP COMPILES:")
        for rel in new:
            print(f"  {rel}")
        print(
            "\nWire each into a build step, delete it, or add it to EXEMPT in this file"
            "\nWITH the sentence saying why it is not compiled. One of these was a finished"
            "\nconversion sitting beside the hand-written body its lane was still using."
        )
        return 1

    stale = sorted(set(BACKLOG) - set(found))
    if stale:
        print("\nBACKLOG ENTRIES THAT ARE NOW COMPILED -- delete them from BACKLOG:")
        for rel in stale:
            print(f"  {rel}")
        print("\nA ratchet that is not tightened when the work lands stops being one.")
        return 1

    if found:
        print("  still uncompiled, at the recorded backlog:")
        for rel in found:
            print(f"    {rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
