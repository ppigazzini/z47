#!/usr/bin/env python3
"""The imported tree must BE the commit the pin names.

WHY THIS EXISTS. `UPSTREAM_COMMIT` in upstream-pin.env was a claim nobody checked.
Every other invariant about the imported tree was gated -- ownership, added paths,
correspondence, the port ledger -- but not the one they all rest on: that the tree
actually equals the SHA. A resync imports "only the changed paths" (the whole-tree
alternative clobbers z47's divergences), and nothing verified the result.

It had drifted. Found 2026-08-02, all of it pre-existing:

  - res/combo/DMCP5_flash_3.57.bin was never imported; the tree still carried
    3.56.bin, and zig_dist.py hardcodes that name, so the R47 combo package
    shipped an outdated DMCP5 firmware image.
  - res/PROGRAMS was missing eleven example programs upstream ships, including the
    BinetV4 rename -- and res/PROGRAMS is staged into the host package, so users
    got a smaller program library than upstream's.
  - Five files sat behind upstream, among them a font changelog entry describing a
    STD-font glyph move.

Two of those hid from a casual `git diff --diff-filter=M` because they are RENAME
pairs, and from `--diff-filter=D` for the same reason. This gate takes A, D, M and
R together.

WHAT IT DOES NOT DO. It does not fetch. The pinned commit has to be present
locally, which it is after `git fetch upstream`, and the gate says so rather than
reporting a pass it cannot justify.

Usage: check-imported-tree-pin.py [--repo-root .]
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from upstream_paths import upstream_root

DIVERGENCES = ".github/project/imported-tree-divergences.txt"
PIN = ".github/project/upstream-pin.env"


def read_pin(repo: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in (repo / PIN).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line and not line.startswith("#") and "=" in line:
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out


def read_divergences(repo: Path) -> tuple[list[str], list[str]]:
    not_carried: list[str] = []
    patched: list[str] = []
    section = None
    for raw in (repo / DIVERGENCES).read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line == "[not-carried]":
            section = not_carried
            continue
        if line == "[patched]":
            section = patched
            continue
        if line.startswith("["):
            section = None
            continue
        if section is None:
            raise SystemExit(f"entry outside a known section in {DIVERGENCES}: {line}")
        section.append(line)
    return not_carried, patched


def covered(path: str, allowed: list[str]) -> bool:
    return any(path == a or path.startswith(a + "/") for a in allowed)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    pin = read_pin(repo)
    sha = pin.get("UPSTREAM_COMMIT", "")
    if not sha:
        print(f"check-imported-tree-pin: BROKEN -- no UPSTREAM_COMMIT in {PIN}.")
        return 1

    if subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", "--quiet", f"{sha}^{{commit}}"],
        capture_output=True,
    ).returncode:
        print(f"check-imported-tree-pin: BROKEN -- pinned commit {sha} is not present locally.")
        print(
            f"Fetch it first: git fetch {pin.get('UPSTREAM_REPOSITORY_URL', '<upstream>')} "
            f"{pin.get('UPSTREAM_BRANCH', 'master')}"
        )
        print("Refusing to report a matching tree without the commit to compare against.")
        return 1

    rel_root = upstream_root(repo).relative_to(repo).as_posix()
    tree = f"HEAD:{rel_root}" if rel_root != "." else "HEAD^{tree}"

    proc = subprocess.run(
        ["git", "-C", str(repo), "diff", "--name-status", "-M", sha, tree],
        capture_output=True,
        text=True,
    )
    if proc.returncode:
        print(f"check-imported-tree-pin: BROKEN -- cannot diff {sha} against {tree}.")
        print(proc.stderr.strip())
        return 1

    not_carried, patched = read_divergences(repo)
    if not not_carried and not patched:
        print(f"check-imported-tree-pin: BROKEN -- read no entries from {DIVERGENCES}.")
        return 1

    undeclared: list[str] = []
    for line in proc.stdout.splitlines():
        parts = line.split("\t")
        status = parts[0]
        if status.startswith("R") and len(parts) == 3:
            # A rename is a pair: upstream's name and z47's. Both must be excused,
            # because a rename here means z47 carries a DIFFERENT file, which is how
            # the stale DMCP5 flash image and the BinetV3/V4 drift stayed invisible.
            up, ours = parts[1], parts[2]
            if not (covered(up, not_carried + patched) and covered(ours, not_carried + patched)):
                undeclared.append(f"{status}  {up} -> {ours}")
            continue
        path = parts[-1]
        if status == "D":
            # In the pin, absent from z47: a path z47 does not carry.
            if not covered(path, not_carried):
                undeclared.append(f"missing   {path}")
        elif status == "A":
            # In z47, absent from the pin: an addition needing an exception.
            if not covered(path, not_carried + patched):
                undeclared.append(f"extra     {path}")
        else:
            if not covered(path, patched):
                undeclared.append(f"modified  {path}")

    if undeclared:
        print(f"IMPORTED TREE DOES NOT MATCH ITS PIN ({sha[:12]}):")
        for u in sorted(undeclared):
            print(f"  {u}")
        print()
        print("The pin says the imported tree IS this commit. Either import the missing")
        print(f"content, or declare the divergence in {DIVERGENCES} with the reason.")
        print("A `missing` line on a path the host package stages is user-visible.")
        return 1

    print(
        f"check-imported-tree-pin: OK (imported tree matches {sha[:12]}; "
        f"{len(not_carried)} not-carried and {len(patched)} patched exceptions declared)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
