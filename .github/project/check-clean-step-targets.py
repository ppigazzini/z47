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

# Every z47-owned file that can carry destructive shell, not just the one that had
# the bug. The survey behind this list: `rm` appears in build/*.zig,
# build/host/*.sh, build/tests/**/*.sh and the workflows, and in every one of those
# except addCleanStep the target is a VARIABLE, which cannot be resolved statically
# and is skipped below. Scanning them anyway costs nothing and means a future
# literal lands in the gate rather than in someone's working tree.
SCANNED_GLOBS = ("build/**/*.zig", "build/**/*.sh", ".github/workflows/*.yml")

# ANY rm, with or without flags. The first version of this gate required an `f` in
# the flags, which let `rm -r build` and a bare `rm build` through -- both delete
# just as thoroughly. Flags are consumed as leading `-...` words in the loop below
# rather than matched here, so no flag spelling can slip past.
RM_RE = re.compile(r"\brm\s+(?P<targets>[^\n\\;&|]*)")

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

    files = sorted({p for glob in SCANNED_GLOBS for p in repo.glob(glob) if p.is_file()})
    if not files:
        print("check-clean-step-targets: BROKEN -- matched no build or workflow files.")
        print("Refusing to report a clean result from an empty scan.")
        return 1

    violations: list[str] = []
    scanned_targets = 0
    for path in files:
        rel = path.relative_to(repo)
        text = path.read_text(encoding="utf-8", errors="replace")
        if path.suffix == ".zig":
            # Only the shell itself, which in Zig is the `\\` multiline-string lines.
            # A `//` comment explaining the hazard necessarily quotes the dangerous
            # form, and scanning it would fail this gate on its own documentation.
            body = "\n".join(
                line.strip()[2:] for line in text.splitlines() if line.strip().startswith("\\\\")
            )
        else:
            # Shell and YAML: drop whole-line comments for the same reason.
            body = "\n".join(
                line for line in text.splitlines() if not line.lstrip().startswith("#")
            )
        for m in RM_RE.finditer(body):
            for raw_target in m.group("targets").split():
                target = raw_target.strip("'\"")
                # Leading `-...` words are flags, whatever their spelling.
                if not target or target.startswith("-"):
                    continue
                scanned_targets += 1
                # A shell variable cannot be resolved statically. Skipping these is
                # what keeps the gate honest rather than noisy: every rm outside
                # addCleanStep targets a computed staging path.
                if "$" in target:
                    continue
                # An absolute path is not a repo-relative root.
                if target.startswith("/"):
                    continue
                head = target.split("/", 1)[0]
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
        f"check-clean-step-targets: OK ({scanned_targets} literal rm targets across "
        f"{len(files)} build/workflow file(s), none hit a z47-owned root)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
