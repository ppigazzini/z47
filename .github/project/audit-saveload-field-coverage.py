#!/usr/bin/env python3
"""Audit save/load field coverage for the calc-state golden (Annex A3).

The save/load parity golden only catches an upstream change to a save field if
that field has a DETERMINISTIC value in the harness's built state. A field that
is never set on the reset path holds uninitialised memory: the golden then pins
garbage that happens to be stable on one machine (e.g. exponentLimit = -6145,
found 2026-06-24) and a real upstream change can hide behind that noise -- or the
golden flakes across environments.

This audit lists every `saveStateValue(&field, ...)` serialised by
saveRestoreCalcState.c and classifies each by where it is assigned:

  - RESET-DIRECT  : assigned directly in resetOtherConfigurationStuff / doFnReset
                    / fnReset (config.c) -- deterministically set every reset.
  - CONFIG-DRIVEN : assigned only inside configCommon's data-driven Settings
                    switch. THIS IS NOT A RUNTIME GUARANTEE: configCommon sets a
                    field only when its setting-group is applied, so a field here
                    can still be uninitialised at runtime -- exponentLimit lived
                    in exactly this bucket yet held garbage (-6145) in the bare
                    harness (found 2026-06-24). Fields ONLY here deserve runtime
                    confirmation too.
  - SET-BY-HARNESS: assigned in the save_load_parity_harness buildState().
  - UNCOVERED     : no assignment found on any of those paths -> a strong
                    candidate for an uninitialised, non-deterministic golden
                    field. REVIEW before M10.

WHY STATIC ANALYSIS IS NOT THE LAST WORD: whether a field is deterministic
depends on runtime data flow, not just on a textual assignment existing (the
exponentLimit case proves it). The AUTHORITATIVE A3 check is a runtime
poison-diff -- memset the calc state to two different sentinel bytes, run
reset+buildState+save for each, and diff the two saves; any differing byte is an
uninitialised field. This script is the cheap first pass that produces the review
list; CONFIG-DRIVEN + UNCOVERED are the sets that the runtime poison-diff should
confirm.

Usage: audit-saveload-field-coverage.py [--repo-root .]
Exit code: 0 always (this is a report); grep 'UNCOVERED' to gate in CI if wanted.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from upstream_paths import upstream_path

SAVE_FILE = "src/c47/saveRestoreCalcState.c"
RESET_FILE = "src/c47/config.c"
HARNESS = "zig_build/tests/calc_state/save_load_parity_harness.c"

# Functions whose direct assignments count as deterministic reset-path init.
RESET_FUNCS = ("doFnReset", "resetOtherConfigurationStuff", "fnReset")
# Data-driven config setters (configCommon -> Sett applies a Settings table):
# assignments here are NOT a runtime guarantee -- a field is set only when its
# setting-group is applied (exponentLimit lives in Sett yet held garbage).
CONFIG_FUNCS = ("configCommon", "Sett")


def save_fields(text: str) -> list[str]:
    return sorted(set(re.findall(r"saveStateValue\(\s*&([A-Za-z_][A-Za-z0-9_]*)", text)))


def assigned_names(text: str) -> set[str]:
    """Names that appear as a plain lvalue assignment `name = ...` or memset."""
    out = set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*[^=]", text))
    out |= set(re.findall(r"memset\(\s*&?([A-Za-z_][A-Za-z0-9_]*)", text))
    return out


def fn_assigned(text: str, funcs: tuple[str, ...]) -> set[str]:
    """Names assigned inside any of the given function bodies.

    Relies on this codebase's K&R layout: a function definition opens with its
    signature ending in `{` and closes with a `}` in column 0. That is far more
    robust than counting braces through the body (configCommon contains char
    literals like '}' that defeat a naive depth counter)."""
    names: set[str] = set()
    for fn in funcs:
        m = re.search(r"^[A-Za-z].*\b" + re.escape(fn) + r"\s*\([^;{]*\)\s*\{", text, re.M)
        if not m:
            continue
        rest = text[m.end() :]
        end = re.search(r"^\}", rest, re.M)
        names |= assigned_names(rest[: end.start() if end else len(rest)])
    return names


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    root = Path(args.repo_root)

    config_text = upstream_path(root, RESET_FILE).read_text()
    fields = save_fields(upstream_path(root, SAVE_FILE).read_text())
    reset_set = fn_assigned(config_text, RESET_FUNCS)
    config_set = fn_assigned(config_text, CONFIG_FUNCS)
    harness_set = assigned_names((root / HARNESS).read_text())

    order = ("RESET-DIRECT", "CONFIG-DRIVEN", "SET-BY-HARNESS", "UNCOVERED")
    buckets: dict[str, list[str]] = {k: [] for k in order}
    for f in fields:
        if f in reset_set:
            buckets["RESET-DIRECT"].append(f)
        elif f in config_set:
            buckets["CONFIG-DRIVEN"].append(f)
        elif f in harness_set:
            buckets["SET-BY-HARNESS"].append(f)
        else:
            buckets["UNCOVERED"].append(f)

    print(f"save fields serialised: {len(fields)}")
    for k in order:
        print(f"  {k}: {len(buckets[k])}")
    for k, note in (
        (
            "CONFIG-DRIVEN",
            "set only by configCommon's data-driven switch -- NOT a "
            "runtime guarantee; confirm via the runtime poison-diff before M10",
        ),
        (
            "UNCOVERED",
            "no assignment on the reset path or in buildState -- set "
            "deterministically in buildState if a real save field",
        ),
    ):
        if buckets[k]:
            print(f"\n{k} ({note}):")
            for f in buckets[k]:
                print(f"  - {f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
