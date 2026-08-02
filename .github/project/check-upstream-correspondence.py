#!/usr/bin/env python3
"""Gate the upstream<->owner correspondence manifest.

A fitness function in the Software Reflexion Model sense (Murphy & Notkin, FSE
1995): it recomputes the symbol join from the live tree and checks it against the
committed manifest, computing the three reflexion outcomes --

  convergence  the committed via=symbol rows equal the recomputed join. If a
               resync moved a C symbol to a new owner (or added a C file), the
               recompute diverges and the gate FAILS "manifest stale" until
               build-correspondence-manifest.py is re-run and committed. THIS is
               the derivability property: every resync that touches src/c47 forces
               a manifest edit, so "which owner absorbs this .c" is always answered.
  absence      a src/c47 .c whose symbols no owner implements. Ratcheted: the
               count may fall, never rise above the baseline. A resync that adds
               an unowned upstream file trips this. Pure data/generator files with
               no runtime symbol are listed in NON_OWNER_ALLOW.
  divergence   handled by check-upstream-mirror.py's reverse class for path twins;
               here a stale manifest row is caught by the convergence diff.

Unlike check-upstream-mirror.py (path identity), this sees the aggregates: sin.c
has no sin.zig twin yet is OWNED by circular_trig_command, so the mirror gate calls
it a forward violation and this gate calls it covered. Coverage, not shape.

Usage:
  check-upstream-correspondence.py            recompute, diff, ratchet (default)
  check-upstream-correspondence.py --bump     rewrite the absence baseline
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MANIFEST = HERE / "upstream-correspondence.tsv"
BASELINE = HERE / "correspondence-baseline.json"

# C files with no runtime function symbol: SEAM-GENERATED font data and the
# build-time lookup generator. Genuine non-owners, not coverage holes.
NON_OWNER_ALLOW = {
    "printing/martelFonts",
    "printing/printerFont8",
    "reservedRegisterLookupGenerator",
}


def load_builder():
    path = HERE / "build-correspondence-manifest.py"
    spec = importlib.util.spec_from_file_location("corr_builder", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load the correspondence builder from {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def recompute(root: pathlib.Path, b) -> tuple[dict[str, set[str]], list[str]]:
    """Return (file->owners via symbol, uncovered C files)."""
    c_root = root / "src/c47"
    z_root = root / "zig_src"
    c_sym_file: dict[str, list[str]] = {}
    c_files: list[str] = []
    for p in sorted(c_root.rglob("*.c")):
        rel = str(p.relative_to(c_root).with_suffix(""))
        c_files.append(rel)
        for s in b.c_symbols(p.read_text(errors="ignore")):
            c_sym_file.setdefault(s, []).append(rel)
    z_sym_owner: dict[str, list[str]] = {}
    for p in sorted(z_root.rglob("*.zig")):
        rel = str(p.relative_to(z_root).with_suffix(""))
        for s, owner in b.zig_owned_symbols(rel, p.read_text(errors="ignore")).items():
            z_sym_owner.setdefault(s, []).append(owner)
    file_owners: dict[str, set[str]] = {}
    for sym, cfiles in c_sym_file.items():
        owners = z_sym_owner.get(sym)
        if not owners:
            continue
        for cf in cfiles:
            file_owners.setdefault(cf, set()).update(owners)
    uncovered = sorted(set(c_files) - set(file_owners) - NON_OWNER_ALLOW)
    return file_owners, uncovered


def committed_symbol_rows(path: pathlib.Path) -> dict[str, set[str]]:
    rows: dict[str, set[str]] = {}
    if not path.exists():
        return rows
    for line in path.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) == 4 and parts[3] == "symbol":
            rows[parts[0]] = set(parts[1].split(";"))
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    args = ap.parse_args()
    root = pathlib.Path(args.repo_root).resolve()
    b = load_builder()

    file_owners, uncovered = recompute(root, b)
    current = {"uncovered": len(uncovered)}

    print("UPSTREAM CORRESPONDENCE")
    print(f"  C files owned by symbol join   {len(file_owners)}")
    print(f"  uncovered (no owner)           {len(uncovered)}")

    if args.bump:
        BASELINE.write_text(json.dumps(current, indent=1) + "\n")
        print(f"bumped correspondence baseline -> {current}")
        return 0

    fail = []

    # convergence: committed manifest must equal the recomputed join
    committed = committed_symbol_rows(MANIFEST)
    live = {cf: ow for cf, ow in file_owners.items()}
    if committed != live:
        stale = sorted(
            (set(committed) ^ set(live))
            | {cf for cf in set(committed) & set(live) if committed[cf] != live[cf]}
        )
        fail.append(
            f"manifest stale in {len(stale)} file(s): "
            + ", ".join(stale[:5])
            + (" ..." if len(stale) > 5 else "")
        )
        fail.append("  -> re-run build-correspondence-manifest.py and commit")

    # absence ratchet
    if not BASELINE.exists():
        print(f"\nFAIL: no baseline at {BASELINE.name}; run --bump to seed it.")
        return 1
    base = json.loads(BASELINE.read_text())
    if current["uncovered"] > base["uncovered"]:
        fail.append(
            f"uncovered rose {base['uncovered']} -> {current['uncovered']}: " + ", ".join(uncovered)
        )

    if fail:
        print("\nFAIL: correspondence gate --")
        for f in fail:
            print("  " + f)
        return 1

    ahead = base["uncovered"] - current["uncovered"]
    note = f" ({ahead} ahead of baseline)" if ahead else ""
    print(
        f"\ncheck-upstream-correspondence: OK -- uncovered "
        f"{current['uncovered']} <= {base['uncovered']}{note}, manifest converged"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
