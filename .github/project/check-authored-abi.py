#!/usr/bin/env python3
"""Authored-ABI ratchet: freeze what is inherited, ratchet what z47 wrote.

THE PARTITION THIS ENFORCES.

z47 exports 2734 `pub export` symbols. 2599 of them (95%) also appear in the pinned
C tree: they are the parity contract. z47 owners are drop-in swappable with the C at
the module-boundary API, so those symbols are MANDATED. Function-level parity means
the same calls; the same calls mean the same dependency graph. Driving that number
down is not an improvement -- it is a parity violation. **A gate whose success
condition is a parity violation is worse than no gate.**

The other 135 are z47's own: accessors and seam helpers it chose to export
(`z47_calc_state_get_config_file_version`, `installCoreHostHooks`, `reportBugError`,
`fnTimerStartImpl`, ...). They are the ONLY part of z47's exported ABI where
"should this symbol exist?" is z47's question to answer, and they were unratcheted:
nothing stopped the number growing one convenience accessor at a time.

WHAT THIS GATE DOES. Counts the `pub export` symbols absent from the pinned C tree
and fails when the set GROWS. A new authored export is a deliberate widening of
z47's own ABI surface and needs a reviewer, not a commit.

WHY EACH ONE MATTERS. Every authored `extern`/`pub export` pair lives in the link
graph, where it can only be measured with `nm`. The same relationship written as an
`@import` lives in the module graph, where the compiler checks it and a reader can
follow it. So each of the 135 is a candidate to become an import; this gate keeps
the list from growing while that happens.

NOTE ON THE C SYMBOL SET. Membership is decided by "does this identifier appear
anywhere in the imported C tree", not by parsing declarations. Parsing was tried and
was wrong: it missed function-pointer tables
(`extern void (* const addition[..][..])(void)`) and file-local globals, and
reported symbols as z47-authored that the C plainly contains.

Usage: check-authored-abi.py [--repo-root .] [--bump] [--list]
"""

import argparse
import collections
import json
import os
import re
import subprocess
import sys

BASELINE = ".github/project/authored-abi-baseline.json"
EXPORT = re.compile(r"(?m)^\s*pub export (?:fn|var|const)\s+(\w+)")
IDENT = re.compile(r"\b[A-Za-z_]\w*\b")


def measure(root):
    files = [
        os.path.join(d, f)
        for d, _, fs in os.walk(os.path.join(root, "zig_src"))
        for f in fs
        if f.endswith(".zig")
    ]
    owners = collections.defaultdict(set)
    for f in files:
        with open(f, encoding="utf-8") as fh:
            for m in EXPORT.finditer(fh.read()):
                owners[m.group(1)].add(os.path.relpath(f, root))
    # A symbol defined in two places is build-variant; it is not an authored surface.
    exported = {n for n, fs in owners.items() if len(fs) == 1}

    blob = subprocess.run(
        ["bash", "-c", "cat src/c47/*.c src/c47/*/*.c src/c47/*.h src/c47/*/*.h 2>/dev/null"],
        cwd=root,
        capture_output=True,
        text=True,
    ).stdout
    csyms = set(IDENT.findall(blob))
    if not csyms:
        return None, None, None  # the pinned C tree is unreadable

    authored = sorted(exported - csyms)
    return exported, authored, {n: sorted(owners[n])[0] for n in authored}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()
    root = os.path.abspath(args.repo_root)

    exported, authored, where = measure(root)

    if exported is None:
        print("check-authored-abi: BROKEN -- read no identifiers from src/c47.")
        print("The pinned C tree is the definition of the parity contract; without")
        print("it every z47 export would read as authored. Refusing to measure.")
        return 1
    if not exported:
        print("check-authored-abi: BROKEN -- found no `pub export` symbols in zig_src.")
        print("z47 is known to export thousands. Refusing to report a clean tree.")
        return 1

    if args.list:
        for n in authored:
            print(f"  {n:<48} {where[n]}")
        return 0

    path = os.path.join(root, BASELINE)
    if args.bump:
        doc = {
            "note": (
                "REPORT-28 M8 / goal G6. `pub export` symbols ABSENT from the pinned C "
                "tree: z47's own ABI surface. The other ~2599 exports are the parity "
                "contract and are deliberately NOT counted here -- driving those down "
                "would mean deviating from the C that parity requires. This list may "
                "shrink (prefer @import to extern, which moves a symbol from the link "
                "graph into the module graph) and must not grow without review."
            ),
            "exported_total": len(exported),
            "authored_count": len(authored),
            "authored": authored,
        }
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, sort_keys=True)
            fh.write("\n")
        print(
            f"check-authored-abi: re-pinned {len(authored)} authored symbols "
            f"of {len(exported)} exported"
        )
        return 0

    if not os.path.isfile(path):
        sys.exit(f"missing baseline {BASELINE} (create it with --bump)")
    with open(path, encoding="utf-8") as fh:
        base = json.load(fh)

    old = set(base["authored"])
    new = set(authored)
    added = sorted(new - old)
    removed = sorted(old - new)

    if added:
        print(f"AUTHORED ABI SURFACE GREW: {len(old)} -> {len(new)}")
        for n in added:
            print(f"  + {n:<46} {where[n]}")
        print()
        print("These symbols are exported by z47 and do not exist in the pinned C, so")
        print("they are not required by the parity contract -- they are z47's own ABI.")
        print("Each one lives in the link graph, where only `nm` can see it. If the")
        print("owner needs this symbol, prefer `@import`: that puts the relationship in")
        print("the module graph, where the compiler checks it and a reader can follow")
        print("it. If the export is genuinely required, re-pin with --bump and say why.")
        return 1

    if removed:
        print(
            f"check-authored-abi: OK -- authored surface SHRANK {len(old)} -> "
            f"{len(new)} (re-pin with --bump)"
        )
        for n in removed[:10]:
            print(f"  - {n}")
        return 0

    print(
        f"check-authored-abi: OK ({len(new)} authored of {len(exported)} exported; "
        f"{len(exported) - len(new)} parity-mandated and frozen)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
