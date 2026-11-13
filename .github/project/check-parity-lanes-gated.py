#!/usr/bin/env python3
"""A parity lane that is in no gate is not a lane. Enumerate them; do not read them.

WHY THIS EXISTS. "Every parity lane is in the battery" was, until this script, a
claim verified by opening run-host-parity-battery.sh and looking. That is the same
mistake the oracle work kept finding one level down: a fact asserted in prose and
checked by a human who already believes it.

It was wrong four times over. `keyboard_entry_spec`, `charstring_diff`,
`constants_parity` and `tone_parity` were declared by the build, buildable, green,
and run by NOTHING -- not this battery, not the local gate, not CI. Two earlier
instances of the same shape had already been found by accident: seven math
differentials broken at link time while the full gate stayed green, and
`distribution_spec` which had stopped compiling entirely. An unrun lane is worse
than a missing one, because it reads as coverage.

HOW IT WORKS. The lane list comes from `zig build --help`, which is the build's own
declaration, and is diffed against the `zig build <step>` invocations in the
battery, the local gate and the workflows. A line that swallows the step's failure
(`zig build x || echo ...`) does not count: it runs the lane and cannot fail on it.
A lane that exists and is not run fails the gate. Nothing here is hand-maintained,
so adding a lane to build/host/steps.zig and forgetting to run it is a build
failure rather than a silence.

EXEMPTIONS COST A REASON. A lane can be excluded, but only in the manifest below
and only with a written reason -- a slow lane, a lane that needs hardware, a lane
CI runs somewhere else. An exemption without a reason fails the gate, on the same
argument as the deliberate-divergence list in check-harness-constant-copies.py: a
decision with a reason is a decision, one without is an oversight that learned to
hide.

Usage:
  check-parity-lanes-gated.py [--repo-root .]
  check-parity-lanes-gated.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

from lane_vocabulary import lane_steps

BATTERY = ".github/project/run-host-parity-battery.sh"
LOCAL_GATE = ".github/project/run-local-gate.sh"
WORKFLOW_GLOB = ".github/workflows/*.yml"

# Lanes that exist and are deliberately not in the battery. Each needs a reason.
# Empty on purpose: every lane the build declares is currently run. The mechanism
# stays because the honest answer to "why is this one not gated?" is a sentence,
# not a deletion.
EXEMPT: dict[str, str] = {}


def declared_lanes(repo: Path) -> set[str]:
    completed = subprocess.run(
        ["zig", "build", "--help"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(f"zig build --help failed:\n{completed.stderr[-2000:]}")
    return lane_steps(completed.stdout)


# `zig build` flags that take their value as the next word.
VALUE_FLAGS = {
    "--summary",
    "--prefix",
    "-p",
    "--cache-dir",
    "--global-cache-dir",
    "--zig-lib-dir",
    "--build-file",
    "--seed",
    "--color",
    "--sysroot",
    "--search-prefix",
}


def logical_lines(text: str) -> list[str]:
    """Shell lines with backslash continuations joined and comments dropped."""
    lines = []
    for line in re.sub(r"\\\n\s*", " ", text).splitlines():
        if not line.strip() or line.strip().startswith("#"):
            continue
        lines.append(re.sub(r"\s#.*$", "", line))
    return lines


def invoked_steps(text: str) -> set[str]:
    """Steps a script runs such that their failure fails the script."""
    steps: set[str] = set()
    for line in logical_lines(text):
        if "zig build" not in line or "||" in line:
            continue
        for tail in re.findall(r"zig build ([^;&|>]*)", line):
            tokens = iter(tail.split())
            for token in tokens:
                if token in VALUE_FLAGS:
                    next(tokens, None)
                elif not token.startswith("-"):
                    steps.add(token)
    return steps


def gated_steps(repo: Path) -> set[str]:
    sources = [repo / BATTERY, repo / LOCAL_GATE, *sorted(repo.glob(WORKFLOW_GLOB))]
    steps: set[str] = set()
    for source in sources:
        steps |= invoked_steps(source.read_text(encoding="utf-8"))
    return steps


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    try:
        lanes = declared_lanes(repo)
    except RuntimeError as exc:
        print(f"check-parity-lanes-gated: BROKEN -- {exc}")
        return 1

    gated = gated_steps(repo)
    ungated = sorted(lane for lane in lanes if lane not in gated and lane not in EXEMPT)

    exempt_here = sorted(lane for lane in lanes if lane in EXEMPT)
    print(
        f"check-parity-lanes-gated: {len(lanes)} lane(s) declared by the build,"
        f" {len(lanes) - len(ungated) - len(exempt_here)} gated,"
        f" {len(exempt_here)} exempt, {len(ungated)} ungated"
    )

    unreasoned = sorted(name for name, why in EXEMPT.items() if not why.strip())
    if unreasoned:
        print("\nEXEMPT WITHOUT A REASON:")
        for name in unreasoned:
            print(f"  {name}")
        return 1

    if args.self_test:
        # Remove a lane the battery really does run and confirm it is reported.
        probe = "flags_parity"
        if probe not in gated:
            print(f"check-parity-lanes-gated: SELF-TEST BROKEN -- {probe} is not in the battery")
            return 1
        pretend = sorted(
            lane for lane in lanes if lane not in (gated - {probe}) and lane not in EXEMPT
        )
        if probe not in pretend:
            print("check-parity-lanes-gated: SELF-TEST FAILED -- an ungated lane went unreported")
            return 1
        swallowed = invoked_steps("zig build swallowed || echo warning\n")
        continued = invoked_steps("zig build kept \\\n  --summary none\n")
        if swallowed or continued != {"kept"}:
            print(
                "check-parity-lanes-gated: SELF-TEST FAILED -- a swallowed or continued line was misread"
            )
            return 1
        print(
            "check-parity-lanes-gated: SELF-TEST OK -- an ungated lane is reported, and a"
            " lane whose failure is swallowed is not gated"
        )

    if ungated:
        print("\nPARITY LANES IN NO GATE:")
        for lane in ungated:
            print(f"  {lane}")
        print(
            f"\nAdd each to {BATTERY}, or add it to EXEMPT in this file WITH the reason"
            "\nit does not belong there. A lane nothing runs reads as coverage and is not."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
