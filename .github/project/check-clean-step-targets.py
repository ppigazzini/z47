#!/usr/bin/env python3
"""No destructive build step may target a z47-owned root.

WHY THIS EXISTS. `zig build clean` mirrors upstream's `make clean`, so its target
list is written in UPSTREAM's vocabulary: `build`, `build.sim`, `src/generated`,
`PROGRAMS/ALLPGMS`, and the `c47`/`r47`/`wp43` binaries its Makefile drops beside
itself. Every one of those names is relative to upstream's own root.

That was harmless while the import WAS the repo root. It stopped being harmless
the moment z47 took the canonical names: `rm -rf build` is upstream's meson output
directory and also z47's entire build system. Running `zig build clean` deleted
205 tracked files -- including the build description that defines the clean step.
Recoverable from git, and silent for anyone with uncommitted work in `build/`.

WHAT THIS GATE DOES. Extracts the `rm` targets from the destructive build steps
and fails if any of them, interpreted relative to the repo root, names a z47-owned
root from source-ownership.txt. A target is considered safe when it is prefixed by
the upstream root (the `"$u"/` form the clean step uses) or when it is one of the
build outputs z47 genuinely owns and means to delete.

WHY A GATE AND NOT A CODE REVIEW. The dangerous version of this line is the one
that looks exactly like upstream's. It reads as correct in review precisely
because it IS correct upstream, and the damage only appears when someone runs a
step nobody runs during normal work. That asymmetry is what a gate is for.

Usage: check-clean-step-targets.py [--repo-root .]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# The build files that contain destructive shell.
SCANNED = ("build/host/steps.zig",)

RM_RE = re.compile(r"\brm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(?P<targets>[^\n\\]*)")

# Paths z47 owns AND deliberately deletes. Everything else owned is off limits.
OWNED_DELETABLE = {".zig-cache", "zig-out", "cov_pcs.txt"}


def z47_roots(repo: Path) -> set[str]:
    manifest = repo / ".github/project/source-ownership.txt"
    roots: set[str] = set()
    section = None
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("["):
            section = line
            continue
        if section == "[z47-owned]":
            roots.add(line)
    return roots


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    owned = z47_roots(repo)
    if not owned:
        print("check-clean-step-targets: BROKEN -- read no z47-owned roots.")
        print("Refusing to report a clean result without the ownership manifest.")
        return 1

    violations: list[str] = []
    scanned_targets = 0
    for rel in SCANNED:
        path = repo / rel
        if not path.is_file():
            print(f"check-clean-step-targets: BROKEN -- {rel} is missing.")
            return 1
        # Only the shell itself, which in Zig is the `\\` multiline-string lines. A
        # `//` comment explaining the hazard necessarily quotes the dangerous form,
        # and scanning it would make this gate fail on its own documentation.
        shell = "\n".join(
            line.strip()[2:]
            for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip().startswith("\\\\")
        )
        for m in RM_RE.finditer(shell):
            for raw_target in m.group("targets").split():
                target = raw_target.strip("'\"")
                if not target or target.startswith("-"):
                    continue
                scanned_targets += 1
                # Prefixed with the upstream root -> aimed at the imported tree.
                if target.startswith('"$u"/') or target.startswith("$u/"):
                    continue
                head = target.split("/", 1)[0].strip("'\"")
                if head in OWNED_DELETABLE:
                    continue
                if head in owned:
                    violations.append(f"{rel}: `rm` targets z47-owned root: {target}")

    if violations:
        print("DESTRUCTIVE STEP TARGETS A Z47-OWNED ROOT:")
        for v in violations:
            print(f"  {v}")
        print()
        print("These lists are written in upstream's vocabulary, so a bare name means")
        print("upstream's file -- but resolved from the repo root it now means z47's.")
        print('Prefix the target with the upstream root ("$u"/...) or, if z47 really')
        print("owns the artefact, add it to OWNED_DELETABLE in this gate with a reason.")
        return 1

    print(
        f"check-clean-step-targets: OK ({scanned_targets} rm targets across "
        f"{len(SCANNED)} build file(s), none hit a z47-owned root)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
