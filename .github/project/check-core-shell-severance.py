#!/usr/bin/env python3
"""core/shell coupling guard (REPORT-28 s42).

Measures two directed couplings from `zig_src/core/` to `zig_src/shell/`:

  * import edges -- a core file that `@import`s a shell SOURCE file. This is a
                    real Zig-level dependency and a genuine invariant: it must
                    stay at ZERO. It is zero today.
  * extern edges -- a core file that `extern`-consumes a symbol whose sole
                    first-party `pub export` lives in shell. FROZEN at the
                    current count as a non-regression guard. It may not rise.

WHY EXTERN EDGES ARE FROZEN AND NOT RATCHETED TO ZERO. This lint used to call
the extern edges "up-couplings NM9 severs by moving each symbol's definition
into its correct zone" and allowed them "only to shrink". That goal was wrong,
and it generated three separate milestones that measurement then killed.

Upstream C47 is ONE library (src/c47) plus a hal; it has no core/shell split.
z47's split is a z47 construct laid over that library. So a core file calling a
library-wide global is how UPSTREAM'S OWN CODE IS WRITTEN, not a defect: of the
469 shell-owned symbols core consumes, 465 (99.1%) are declared in upstream's
own src/c47 headers, and upstream's counterparts of z47's core files call them
freely (keyboard.c uses indexOfItems 21 times, solver/equation.c 7 times).
Driving these to zero would mean deviating from upstream in its hottest files.
There is no "correct zone" to move an upstream library global into.

So this asks only the question that has a right answer, exactly as the sibling
platform-purity gate does: "did z47 ADD a core->shell coupling it did not have?"
Lowering the count is a real architectural act, not a score: it means a
definition genuinely belonged in core. Re-pin with --update when that happens.

The 4 symbols that are NOT in upstream's headers were real debt, and asking this
question is what found them: PLOT_RMS/PLOT_INTG/PLOT_DIFF/PLOT_SHADE, globals
upstream replaced with system flags (FLAG_PRMS..FLAG_PSHADE) and z47 did not
follow. See REPORT-28 s42.

Baseline lives in core-shell-severance-baseline.json.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

REPO_DEFAULT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASELINE = os.path.join(os.path.dirname(__file__), "core-shell-severance-baseline.json")

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
    core_exports = exports_in(root, "core")
    abi_exports = exports_in(root, "abi")
    # Symbols whose only first-party definition is in shell.
    shell_owned = shell_exports - core_exports - abi_exports

    extern_edges: list[tuple[str, str]] = []
    import_edges: list[tuple[str, str]] = []
    for path in zig_files(root, "core"):
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
                # Both sides MUST be normalized. os.path.join('.', 'zig_src', 'shell')
                # is './zig_src/shell', while commonpath() returns 'zig_src/shell', so
                # the unnormalized comparison was NEVER true: this cap could not fire,
                # and every caller passes --repo-root '.'. The invariant read zero
                # because it was vacuous, not because the tree was clean.
                shell_root = os.path.normpath(os.path.join(root, "zig_src", "shell"))
                if os.path.commonpath([target, shell_root]) == shell_root:
                    import_edges.append((rel, imp))
    return extern_edges, import_edges


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=REPO_DEFAULT)
    ap.add_argument(
        "--update", action="store_true", help="re-pin the baseline (only if not increased)"
    )
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
            print(
                f"refusing --update: extern edges rose {base_extern} -> {n_extern}", file=sys.stderr
            )
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
        print(f"FAIL: {n_import} core->shell @import edge(s) (must be 0):", file=sys.stderr)
        for f, s in import_edges:
            print(f"  {f} @imports {s}", file=sys.stderr)
    if n_extern > base_extern:
        ok = False
        print(
            f"FAIL: core->shell extern edges rose {base_extern} -> {n_extern} (frozen guard):",
            file=sys.stderr,
        )

    status = "below" if n_extern < base_extern else "at"
    print(
        f"core->shell severance: import={n_import} (cap 0), extern={n_extern} ({status} ceiling {base_extern})"
    )
    if n_extern < base_extern:
        print(
            f"note: extern edges dropped {base_extern} -> {n_extern}; run --update to re-pin the guard."
        )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
