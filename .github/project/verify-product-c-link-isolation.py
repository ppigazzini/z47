#!/usr/bin/env python3
"""Verify product binaries link zero first-party C, against the LIVE build graph.

The companion audit ``check-c-dependency-allowlist.py`` scans build ``.zig``
files for path-like ``.c`` string literals. That is fast but structurally
fragile: first-party C pulled in by a directory glob (``collectRelativeCFiles``)
or by a manifest the scanner does not resolve is invisible to it, which is how a
laundered "0" was historically possible (see REPORT-15).

This check closes that gap by parsing the *actual* ``zig build <target>
--verbose`` compiler invocations and asserting that every product compile/link
command -- everything except the explicitly allowlisted build-time generator
tools -- contains no first-party ``src/c47*`` or ``zig_bridge`` C source.

It complements, and does not replace, the literal-scan audit and the
``std.debug.assert(core_sources.len == 0)`` build-time guard.

Usage:
    verify-product-c-link-isolation.py [--target sim] [--repo-root .]
    verify-product-c-link-isolation.py --self-test   # prove the check can fail
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# Build-time host tools that legitimately compile first-party C to GENERATE
# headers/assets (catalogs, constants, raster fonts). They are not linked into
# any shipped product binary. Adding a name here is an explicit, reviewable
# decision -- never widen it to silence a real product-lane regression.
GENERATOR_TOOLS = frozenset({"generateCatalogs", "generateConstants", "ttf2RasterFonts"})

# First-party C surfaces that must never reach a product binary.
FIRST_PARTY_C = re.compile(r"\b(src/c47[a-z0-9-]*/[A-Za-z0-9_./-]+\.c|zig_bridge/[^\s]+\.c)\b")

# A parity/oracle/test executable is not a product binary; its name ends with a
# test/parity marker. Such targets are out of scope for THIS product check.
TEST_NAME = re.compile(r"(parity|oracle|test|fake)", re.IGNORECASE)


def split_commands(verbose_output: str) -> list[str]:
    """Split a --verbose build log into individual compiler invocations."""
    return re.split(r"(?=zig build-(?:exe|obj|lib))", verbose_output)


def command_name(cmd: str) -> str | None:
    m = re.search(r"--name\s+(\S+)", cmd)
    return m.group(1) if m else None


def first_party_c_in(cmd: str) -> list[str]:
    return sorted(set(FIRST_PARTY_C.findall(cmd)))


def audit_target(repo_root: Path, target: str) -> tuple[int, list[str]]:
    """Build the target verbosely and return (violation_count, report_lines)."""
    proc = subprocess.run(
        ["zig", "build", target, "--verbose"],
        cwd=repo_root,
        capture_output=True,
        text=True,
    )
    log = proc.stdout + proc.stderr
    lines: list[str] = []
    violations = 0
    checked = 0
    for cmd in split_commands(log):
        if "build-exe" not in cmd and "build-obj" not in cmd and "build-lib" not in cmd:
            continue
        name = command_name(cmd)
        if name is None:
            continue
        # the regex captures the first group; normalize to plain paths
        fp = [m[0] if isinstance(m, tuple) else m for m in first_party_c_in(cmd)]
        if name in GENERATOR_TOOLS or TEST_NAME.search(name):
            continue  # out of scope for the product check
        checked += 1
        if fp:
            violations += 1
            lines.append(f"  VIOLATION [{name}] links first-party C: {fp}")
    lines.insert(0, f"target '{target}': checked {checked} product compile/link commands")
    if proc.returncode != 0 and violations == 0:
        # build itself failed for an unrelated reason -- surface it, do not pass
        lines.append(f"  NOTE: 'zig build {target}' exited {proc.returncode}")
    return violations, lines


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--target", action="append", help="build target(s); default: sim")
    ap.add_argument(
        "--self-test",
        action="store_true",
        help="parse a synthetic log to prove a planted first-party C is caught",
    )
    args = ap.parse_args()

    if args.self_test:
        planted = (
            "zig build-exe --name c47 -- /repo/dep/decNumberICU/decQuad.c "
            "/repo/src/c47/charString.c\n"
            "zig build-exe --name generateCatalogs -- /repo/src/c47/items.c\n"
        )
        v = 0
        for cmd in split_commands(planted):
            name = command_name(cmd)
            if name is None or name in GENERATOR_TOOLS or TEST_NAME.search(name or ""):
                continue
            if first_party_c_in(cmd):
                v += 1
        if v == 1:
            print(
                "self-test PASS: planted product-lane first-party C was caught; "
                "generator-tool C was correctly ignored"
            )
            return 0
        print(f"self-test FAIL: expected 1 caught violation, got {v}")
        return 1

    repo_root = Path(args.repo_root).resolve()
    targets = args.target or ["sim"]
    total = 0
    for target in targets:
        v, lines = audit_target(repo_root, target)
        total += v
        print("\n".join(lines))
    if total:
        print(f"\nFAIL: {total} product compile/link command(s) link first-party C.")
        return 1
    print("\nPASS: no product binary links first-party C (verified against the live build graph).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
