#!/usr/bin/env python3
"""NM9 headless-engine severance lint.

The z47 target architecture is a headless `engine/` that never depends on the
interactive `shell/`: no file under `zig_src/engine/` may reach up into
`zig_src/shell/`. Cross-zone consumption in this codebase is via the frozen
C-ABI (`extern`), so this lint measures two directed couplings:

  * import edges  -- an engine file that `@import`s a shell source file. The
                     architecture routes every cross-zone dependency through the
                     ABI, so this must stay at ZERO (an absolute invariant).
  * extern edges  -- an engine file that `extern`-consumes a symbol whose sole
                     first-party definition (`pub export`) lives in shell. These
                     are the up-couplings NM9 severs by moving each symbol's
                     definition into its correct zone (kernel/engine). Far from
                     zero today, so this is ratcheted: it may only shrink.

Baseline lives in engine-shell-severance-baseline.json. Run with --update to
re-pin it after a slice legitimately lowers the count (it can never raise it).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

REPO_DEFAULT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASELINE = os.path.join(os.path.dirname(__file__), "engine-shell-severance-baseline.json")

EXPORT_RE = re.compile(r"^\s*pub\s+export\s+(?:fn|var|const)\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
EXTERN_RE = re.compile(r"^\s*(?:pub\s+)?extern\s+(?:fn|var|const)\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
IMPORT_RE = re.compile(r"""@import\(\s*"([^"]+)"\s*\)""")


def zig_files(root: str, zone: str):
    base = os.path.join(root, "zig_src", zone)
    for dirpath, _dirs, names in os.walk(base):
        for n in names:
            if n.endswith(".zig"):
                yield os.path.join(dirpath, n)


def exports_in(root: str, zone: str) -> set[str]:
    syms: set[str] = set()
    for path in zig_files(root, zone):
        with open(path, encoding="utf-8") as fh:
            syms.update(EXPORT_RE.findall(fh.read()))
    return syms


def measure(root: str):
    shell_exports = exports_in(root, "shell")
    engine_exports = exports_in(root, "engine")
    seam_exports = exports_in(root, "seam")
    # Symbols whose only first-party definition is in shell.
    shell_owned = shell_exports - engine_exports - seam_exports

    extern_edges: list[tuple[str, str]] = []
    import_edges: list[tuple[str, str]] = []
    for path in zig_files(root, "engine"):
        rel = os.path.relpath(path, root)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for sym in set(EXTERN_RE.findall(text)):
            if sym in shell_owned:
                extern_edges.append((rel, sym))
        for imp in IMPORT_RE.findall(text):
            # relative @import that resolves into zig_src/shell/
            if "/" in imp or imp.endswith(".zig"):
                target = os.path.normpath(os.path.join(os.path.dirname(path), imp))
                if os.path.commonpath([target, os.path.join(root, "zig_src", "shell")]) == os.path.join(root, "zig_src", "shell"):
                    import_edges.append((rel, imp))
    return extern_edges, import_edges


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=REPO_DEFAULT)
    ap.add_argument("--update", action="store_true", help="re-pin the baseline (only if not increased)")
    ap.add_argument("--list", action="store_true", help="print every current edge")
    args = ap.parse_args()

    extern_edges, import_edges = measure(args.repo_root)
    n_extern = len({(f, s) for f, s in extern_edges})
    n_import = len(import_edges)

    if args.list:
        for f, s in sorted(set(extern_edges)):
            print(f"extern  {f}  ->  {s}")
        for f, s in sorted(import_edges):
            print(f"import  {f}  ->  {s}")

    with open(BASELINE, encoding="utf-8") as fh:
        base = json.load(fh)
    base_extern = base["extern_edges"]

    if args.update:
        if n_extern > base_extern:
            print(f"refusing --update: extern edges rose {base_extern} -> {n_extern}", file=sys.stderr)
            return 1
        base["extern_edges"] = n_extern
        with open(BASELINE, "w", encoding="utf-8") as fh:
            json.dump(base, fh, indent=2)
            fh.write("\n")
        print(f"baseline re-pinned: extern_edges = {n_extern}")
        return 0

    ok = True
    if n_import != 0:
        ok = False
        print(f"FAIL: {n_import} engine->shell @import edge(s) (must be 0):", file=sys.stderr)
        for f, s in import_edges:
            print(f"  {f} @imports {s}", file=sys.stderr)
    if n_extern > base_extern:
        ok = False
        print(f"FAIL: engine->shell extern edges rose {base_extern} -> {n_extern} (ratchet):", file=sys.stderr)

    status = "below" if n_extern < base_extern else "at"
    print(f"engine->shell severance: import={n_import} (cap 0), extern={n_extern} ({status} ceiling {base_extern})")
    if n_extern < base_extern:
        print(f"note: extern edges dropped {base_extern} -> {n_extern}; run --update to re-pin the ratchet.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
