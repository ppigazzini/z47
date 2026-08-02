#!/usr/bin/env python3
"""Module-graph gate: the @import graph's cycles, frozen and named.

WHAT THIS MEASURES. The `@import` graph over `src/**.zig` -- the structure a
reader navigates. This is NOT the structure the linker builds (that is the object
graph, whose objects are defined by `build/`'s build roots). The two are
orthogonal: moving a file between directories changes this graph and cannot change
the object graph. Know which one owns a number before acting on it.

WHAT IT ASSERTS.
  1. `abi/` is acyclic. It is the contract layer, imported by 41% of the tree; the
     bottom of the graph must be a bottom.
  2. The set of cyclic components does not grow. Cycles are frozen by SIZE and
     ZONE, not merely counted, so a new 3-file cycle cannot hide behind a
     disappearing one.

WHAT IT REPORTS BUT DOES NOT GATE. CCD / ACD / NCCD. Lakos's NCCD ~1 target is
calibrated for C++ builds where cycles cost compile time. In z47 they cost neither
compile time, flash (--gc-sections discards unreferenced code at function
granularity) nor test isolation (every owner already links standalone against a
fake runtime). Importing the threshold would be cargo cult. The gateable property
is binary -- acyclic or not -- and NCCD is the comparable summary that says whether
a change helped.

Usage: check-module-graph.py [--repo-root .] [--bump]
"""

import argparse
import collections
import json
import math
import os
import re
import sys

BASELINE = ".github/project/module-graph-baseline.json"
IMPORT = re.compile(r'@import\("([^"]+\.zig)"\)')


def build_graph(root):
    src = os.path.join(root, "src")
    files = [os.path.join(d, f) for d, _, fs in os.walk(src) for f in fs if f.endswith(".zig")]
    rel = {f: os.path.relpath(f, root) for f in files}
    known = set(files)
    g = collections.defaultdict(set)
    for f in files:
        with open(f, encoding="utf-8") as fh:
            text = fh.read()
        for m in IMPORT.finditer(text):
            t = os.path.normpath(os.path.join(os.path.dirname(f), m.group(1)))
            if t in known and t != f:
                g[f].add(t)
    return files, rel, g


def sccs(nodes, g):
    index, low, on, stack, out, c = {}, {}, {}, [], [], [0]
    for root in nodes:
        if root in index:
            continue
        work = [(root, iter(g.get(root, ())))]
        index[root] = low[root] = c[0]
        c[0] += 1
        stack.append(root)
        on[root] = True
        while work:
            v, it = work[-1]
            pushed = False
            for w in it:
                if w not in index:
                    index[w] = low[w] = c[0]
                    c[0] += 1
                    stack.append(w)
                    on[w] = True
                    work.append((w, iter(g.get(w, ()))))
                    pushed = True
                    break
                if on.get(w):
                    low[v] = min(low[v], index[w])
            if pushed:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[v])
            if low[v] == index[v]:
                comp = []
                while True:
                    w = stack.pop()
                    on[w] = False
                    comp.append(w)
                    if w == v:
                        break
                out.append(comp)
    return sorted([c_ for c_ in out if len(c_) > 1], key=len, reverse=True)


def zone_of(relpath):
    """The DIRECTORY a file lives in, at most two levels below src/.

    Must never return a filename: a cycle's fingerprint is (size, dominant zone),
    and if every member reported a distinct "zone" the dominant one would be
    chosen by dict order and the fingerprint would not survive a re-run.
    """
    parts = relpath.split(os.sep)  # src / abi / types.zig
    if len(parts) <= 2:
        return parts[0]
    if len(parts) == 3:
        return parts[1]  # src/abi/types.zig      -> abi
    return os.sep.join(parts[1:3])  # src/core/numeric/x.zig -> core/numeric


def measure(root):
    files, rel, g = build_graph(root)
    comps = sccs(files, g)

    def reach(v):
        seen, st = {v}, [v]
        while st:
            x = st.pop()
            for w in g.get(x, ()):
                if w not in seen:
                    seen.add(w)
                    st.append(w)
        return len(seen)

    n = len(files)
    ccd = sum(reach(v) for v in files)
    tree = sum(int(math.log2(i + 1)) + 1 for i in range(n)) or 1
    # a cycle is identified by (size, dominant zone) -- stable across renames
    fingerprints = []
    for comp in comps:
        zones = collections.Counter(zone_of(rel[f]) for f in comp)
        fingerprints.append({"size": len(comp), "zone": zones.most_common(1)[0][0]})
    abi_cycles = sum(
        1 for comp in comps if all(rel[f].startswith("src" + os.sep + "abi") for f in comp)
    )
    return {
        "files": n,
        "edges": sum(len(v) for v in g.values()),
        "cycles": fingerprints,
        "files_in_cycles": sum(len(c_) for c_ in comps),
        "abi_cycles": abi_cycles,
        "ccd": ccd,
        "acd": round(ccd / n, 1),
        "nccd": round(ccd / tree, 2),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    args = ap.parse_args()
    root = os.path.abspath(args.repo_root)
    m = measure(root)

    if m["files"] == 0:
        print("check-module-graph: BROKEN -- found no .zig files under src/.")
        print("Refusing to report a clean tree from an empty measurement.")
        return 1

    path = os.path.join(root, BASELINE)
    if args.bump:
        m["note"] = (
            "REPORT-28 M1.3. Cycles in the @import graph, frozen by (size, zone) so a "
            "new cycle cannot hide behind a disappearing one. abi_cycles must reach 0 "
            "(the contract layer is the bottom). ccd/acd/nccd are REPORTED, not gated: "
            "Lakos's NCCD threshold assumes cycles cost compile time, and in z47 they "
            "cost neither compile time, flash nor test isolation."
        )
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(m, fh, indent=1, sort_keys=True)
            fh.write("\n")
        print(
            f"check-module-graph: re-pinned {len(m['cycles'])} cycles, "
            f"{m['files_in_cycles']} files, abi_cycles={m['abi_cycles']}, "
            f"NCCD {m['nccd']}"
        )
        return 0

    if not os.path.isfile(path):
        sys.exit(f"missing baseline {BASELINE} (create it with --bump)")
    with open(path, encoding="utf-8") as fh:
        base = json.load(fh)

    fails = []
    if m["abi_cycles"] > base["abi_cycles"]:
        fails.append(
            f"abi/ cycles rose {base['abi_cycles']} -> {m['abi_cycles']}. "
            "The contract layer is imported by 41% of the tree; it must be "
            "the acyclic bottom."
        )

    def key(c):
        return (c["size"], c["zone"])

    old = collections.Counter(key(c) for c in base["cycles"])
    new = collections.Counter(key(c) for c in m["cycles"])
    for k, cnt in new.items():
        if cnt > old.get(k, 0):
            fails.append(f"new @import cycle: {k[0]} files in {k[1]} ({old.get(k, 0)} -> {cnt})")
    if m["files_in_cycles"] > base["files_in_cycles"]:
        fails.append(
            f"files trapped in cycles rose {base['files_in_cycles']} -> {m['files_in_cycles']}"
        )

    print(
        f"  files {m['files']}  edges {m['edges']}  cycles {len(m['cycles'])}  "
        f"trapped {m['files_in_cycles']}  abi_cycles {m['abi_cycles']}"
    )
    print(f"  CCD {m['ccd']}  ACD {m['acd']}  NCCD {m['nccd']}   (reported, not gated)")

    if fails:
        print("\nMODULE GRAPH REGRESSED:")
        for f in fails:
            print(f"  {f}")
        print("\nA cycle in the @import graph means those files cannot be read, or")
        print("reasoned about, one at a time. If a cycle legitimately shrank, re-pin")
        print("with --bump. A cycle must never be added.")
        return 1

    improved = (
        m["files_in_cycles"] < base["files_in_cycles"] or m["abi_cycles"] < base["abi_cycles"]
    )
    print("check-module-graph: OK" + ("  (IMPROVED -- re-pin with --bump)" if improved else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
