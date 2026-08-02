#!/usr/bin/env python3
"""Turn an upstream pin advance into a per-owner re-port worklist.

The whole point of mirroring the tree was that a resync becomes derivable: when
upstream moves the pin, a maintainer can mechanically find which owners a C change
lands in, instead of grepping and hoping. The correspondence manifest already
records who owns each upstream .c; this asks it once per changed file per resync
and hands back the plan.

It diffs the imported C between two pins in the sibling upstream checkout (../c43)
and, for each changed src/c47/*.c, computes the three Reflexion-Model outcomes a
change set produces that the steady-state gate cannot see:

  change     the .c was modified -> its owner(s) are the re-port worklist, ranked
             by churn (lines changed) so the hottest land first. A change that
             touches only an aggregate's cell attributes to the idiomatic owner
             that holds it -- the case a file-name diff cannot resolve.
  absence    the .c was added -> new upstream surface with no owner yet, to port.
  divergence the .c was deleted -> its owner is orphaned and must be retired.

This is the "which owners changed" step of the resync runbook, mechanised. It reads
only; it does not touch the tree or the pin.

Usage:
  report-resync-worklist.py <oldpin> <newpin> [--repo-root .] [--sibling ../c43]
"""

from __future__ import annotations

import argparse
import importlib.util
import os
import pathlib
import re
import subprocess
import sys

C_PREFIX = "src/c47/"
MANIFEST = ".github/project/upstream-correspondence.tsv"
HERE = pathlib.Path(__file__).resolve().parent
# git prints the enclosing C function on each hunk header after the second @@.
HUNK_FN = re.compile(r"@@ -\d+(?:,\d+)? \+\d+(?:,\d+)? @@\s*(.*)")
FN_NAME = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\s*\(")


def symbol_owner_index(repo: pathlib.Path) -> dict[str, list[str]]:
    """C function symbol -> owner(s), from the same symbol join the correspondence
    manifest is built on. This is what lets a change to one function in a 42-owner
    aggregate (matrix.c) point at the single owner that implements it, instead of
    the whole cluster."""
    path = HERE / "build-correspondence-manifest.py"
    spec = importlib.util.spec_from_file_location("corr_builder", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load the correspondence builder from {path}")
    b = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(b)
    idx: dict[str, list[str]] = {}
    for p in sorted((repo / "src").rglob("*.zig")):
        rel = str(p.relative_to(repo / "src").with_suffix(""))
        for sym, owner in b.zig_owned_symbols(rel, p.read_text(errors="ignore")).items():
            idx.setdefault(sym, []).append(owner)
    return idx


def load_owners(repo: pathlib.Path) -> dict[str, list[str]]:
    """upstream C relpath (under src/c47, no suffix) -> owner(s)."""
    owners: dict[str, list[str]] = {}
    path = repo / MANIFEST
    if not path.exists():
        return owners
    for line in path.read_text().splitlines():
        if line.startswith("#") or "\t" not in line:
            continue
        parts = line.split("\t")
        if len(parts) >= 2 and parts[0] != "-":
            owners.setdefault(parts[0], []).extend(parts[1].split(";"))
    return owners


def git(sibling: str, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", sibling, *args], capture_output=True, text=True, check=True
    ).stdout


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("oldpin")
    ap.add_argument("newpin")
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--sibling", default=None)
    args = ap.parse_args()
    repo = pathlib.Path(args.repo_root).resolve()
    sibling = args.sibling or str(repo.parent / "c43")

    if not os.path.isdir(os.path.join(sibling, ".git")):
        sys.exit(f"need the upstream checkout at {sibling} to diff the pins.")
    for pin in (args.oldpin, args.newpin):
        if (
            subprocess.run(
                ["git", "-C", sibling, "cat-file", "-e", pin + "^{commit}"], capture_output=True
            ).returncode
            != 0
        ):
            sys.exit(f"pin {pin} not found in {sibling}.")

    owners = load_owners(repo)
    sym_idx = symbol_owner_index(repo)

    def changed_functions(path: str) -> list[str]:
        diff = git(sibling, "diff", args.oldpin, args.newpin, "--", path)
        fns = []
        for m in HUNK_FN.finditer(diff):
            fn = FN_NAME.search(m.group(1))
            if fn:
                fns.append(fn.group(1))
        return sorted(set(fns))

    # name-status for A/M/D/R, numstat for churn
    status: dict[str, str] = {}
    for line in git(
        sibling, "diff", "--name-status", args.oldpin, args.newpin, "--", C_PREFIX
    ).splitlines():
        f = line.split("\t")
        st = f[0][0]
        path = f[-1]  # for R the new path is last
        if path.endswith(".c"):
            status[path] = st
    churn: dict[str, int] = {}
    for line in git(
        sibling, "diff", "--numstat", args.oldpin, args.newpin, "--", C_PREFIX
    ).splitlines():
        a, d, path = ([*line.split("\t"), "", "", ""])[:3]
        if path.endswith(".c") and a.isdigit() and d.isdigit():
            churn[path] = int(a) + int(d)

    def owner_of(path: str) -> list[str]:
        return owners.get(path[len(C_PREFIX) : -2], [])

    changed = sorted(
        ((p, churn.get(p, 0)) for p, s in status.items() if s == "M"), key=lambda x: -x[1]
    )
    added = sorted(p for p, s in status.items() if s == "A")
    deleted = sorted(p for p, s in status.items() if s == "D")

    print(f"RESYNC WORKLIST  {args.oldpin[:9]} -> {args.newpin[:9]}")
    print(f"  {len(changed)} changed, {len(added)} added, {len(deleted)} deleted (src/c47 only)\n")

    print("CHANGE -- re-port these owners (ranked by churn):")
    unowned = []
    for p, ch in changed:
        rel = p[len(C_PREFIX) :]
        # Attribute to the owner(s) of the FUNCTIONS the diff actually touched;
        # fall back to the file-level manifest when the hunk has no function
        # context (data tables) or the symbol is not owned by name.
        fns = changed_functions(p)
        pinpointed: dict[str, list[str]] = {}
        for fn in fns:
            for o in sym_idx.get(fn, []):
                pinpointed.setdefault(o, []).append(fn)
        file_owners = owner_of(p)
        if pinpointed:
            print(f"  {ch:>5}  {rel}  ({len(fns)} fn changed)")
            for o in sorted(pinpointed):
                print(f"         -> {o}  [{', '.join(sorted(set(pinpointed[o])))}]")
        elif file_owners:
            print(f"  {ch:>5}  {rel}  (no fn context; whole-file owners)")
            for o in sorted(set(file_owners)):
                print(f"         -> {o}")
        else:
            unowned.append((p, ch))
    if unowned:
        print("\n  changed but UNOWNED (font/generator seam, or a coverage gap):")
        for p, ch in unowned:
            print(f"  {ch:>5}  {p[len(C_PREFIX) :]}")

    if added:
        print("\nABSENCE -- new upstream surface, no owner yet (port from scratch):")
        for p in added:
            print(f"    {p[len(C_PREFIX) :]}")
    if deleted:
        print("\nDIVERGENCE -- upstream deleted; retire the orphaned owner:")
        for p in deleted:
            ow = owner_of(p)
            print(
                f"    {p[len(C_PREFIX) :]}"
                + ("  -> " + ", ".join(sorted(set(ow))) if ow else "  (no owner)")
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
