#!/usr/bin/env python3
"""A parity lane that is in no gate is not a lane. Enumerate them; do not read them.

WHY THIS EXISTS. "Every parity lane is in the battery" was, until this script, a
claim verified by opening run-host-parity-battery.sh and looking. That is the same
mistake the oracle work kept finding one level down: a fact asserted in prose and
checked by a human who already believes it.

It was wrong four times over. `keyboard_entry_parity`, `charstring_diff`,
`constants_parity` and `tone_parity` were declared by the build, buildable, green,
and run by NOTHING -- not this battery, not the local gate, not CI. Two earlier
instances of the same shape had already been found by accident: seven math
differentials broken at link time while the full gate stayed green, and
`distribution_parity` which had stopped compiling entirely. An unrun lane is worse
than a missing one, because it reads as coverage.

HOW IT WORKS. The lane list comes from `zig build --help`, which is the build's own
declaration, and is diffed against the `zig build <step>` lines in the battery. A
lane that exists and is not run fails the gate. Nothing here is hand-maintained, so
adding a lane to build/host/steps.zig and forgetting the battery is a build
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

BATTERY = ".github/project/run-host-parity-battery.sh"

# A build step is a parity lane when its name says so. The suffixes are the
# vocabulary the tree already uses: `_parity` for a differential against c43,
# `_oracle` for a focused worker-level one, `_diff` for a script-extracted
# reference, `_suite` for a grouped set.
LANE_RE = re.compile(r"^\s{2}([\w-]+(?:_parity|_oracle|_diff|_suite|-parity))\s", re.M)

# Lanes that exist and are deliberately not in the battery. Each needs a reason.
# Empty on purpose: every lane the build declares is currently run. The mechanism
# stays because the honest answer to "why is this one not gated?" is a sentence,
# not a deletion.
EXEMPT: dict[str, str] = {}

# Lanes the battery runs whose names do not carry a lane suffix.
EXTRA_BATTERY_STEPS = ("saveload_roundtrip",)


def declared_lanes(repo: Path) -> set[str]:
    completed = subprocess.run(
        ["zig", "build", "--help"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(f"zig build --help failed:\n{completed.stderr[-2000:]}")
    return set(LANE_RE.findall(completed.stdout))


def battery_steps(repo: Path) -> set[str]:
    text = (repo / BATTERY).read_text(encoding="utf-8")
    return set(re.findall(r"^\s*(?:retry_once\s+)?zig build (\S+)", text, re.M))


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

    gated = battery_steps(repo) | set(EXTRA_BATTERY_STEPS)
    ungated = sorted(lane for lane in lanes if lane not in gated and lane not in EXEMPT)

    exempt_here = sorted(lane for lane in lanes if lane in EXEMPT)
    print(
        f"check-parity-lanes-gated: {len(lanes)} lane(s) declared by the build,"
        f" {len(lanes) - len(ungated) - len(exempt_here)} in the battery,"
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
        print("check-parity-lanes-gated: SELF-TEST OK -- an ungated lane is reported")

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
