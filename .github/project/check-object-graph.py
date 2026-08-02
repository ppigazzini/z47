#!/usr/bin/env python3
"""Object-graph gate: the graph the LINKER builds, frozen per target.

WHAT THIS MEASURES, AND WHY IT IS NOT check-module-graph.py.

z47 has two dependency graphs and they are orthogonal.

  MODULE graph  `@import` over src/       what a reader navigates
                lever: the file tree          gated by check-module-graph.py
  OBJECT graph  build roots + link edges      what the LINKER builds
                lever: build/             gated here

Moving a file between directories changes the module graph and CANNOT change the
object graph -- the build names root files, never zones. A folder refactor that
claims an object-metric win is claiming something the tool cannot do. Know which
artefact owns a number before acting on it.

The object graph is the one that decides what a firmware package must carry and
what a parity suite can link standalone. Nothing pinned it until this gate.

WHERE THE OBJECT SET COMES FROM. `zig build object-manifest`, which is the build
DECLARING what it links (build/object_manifest.zig). It is not scraped. Every
wrong object-set number produced against this codebase came from asking something
other than the build:
  - a .zig-cache glob            -> included a test artefact
  - a `c47-` name-prefix filter  -> dropped the five host-* objects: 14 vs 19
  - `--verbose-link`             -> emits ONLY when a link actually runs; on a
                                    cached build it prints nothing, so the gate
                                    would see the truth in CI and NOTHING locally

WHAT IS GATED. Per target: the number of cyclic components, the size of the
largest, and the count of objects trapped in a cycle. None may rise.

WHAT IS REPORTED, NOT GATED. CCD / ACD / NCCD, and the one-symbol edges inside
each cycle. Lakos's NCCD ~1 target is calibrated for C++ builds where a cycle
costs compile time. z47's cycles cost neither compile time, flash (firmware.zig
passes -Wl,--gc-sections with -ffunction-sections, so unreferenced code is
discarded at function granularity) nor test isolation (every parity suite already
links its owner standalone against a fake runtime). Importing the threshold would
be cargo cult. The gateable property is binary; NCCD is the comparable summary
that says whether a change helped.

EVERY TARGET IS MEASURED. `sim` shows one object outside its cycle and `dmcp`
shows none: a single target is not evidence about the others.

Usage: check-object-graph.py [--repo-root .] [--bump] [--edges TARGET]
"""

import argparse
import collections
import json
import math
import os
import shutil
import subprocess
import sys

BASELINE = ".github/project/object-graph-baseline.json"
MANIFEST_DIR = os.path.join("zig-out", "object-graph")
TARGETS = ("sim", "dmcp", "dmcp5")

# Defined GLOBAL symbol types only. Counting every defined symbol instead measures
# nothing useful: local symbols dominate, and a 38-line owner "defines" 3084 of
# them. Only globals participate in linking, so only globals are edges.
GLOBAL_DEFINED = set("TDBRWVAGSC")


def nm_tool():
    # llvm-nm reads both the host x86-64 objects and the ARM firmware objects.
    for tool in ("llvm-nm", "nm"):
        if shutil.which(tool):
            return tool
    sys.exit("check-object-graph: no nm found; cannot read the object symbol tables")


def symbols(tool, path):
    defined, undefined = set(), set()
    out = subprocess.run([tool, "--print-file-name", path], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"check-object-graph: {tool} failed on {path}:\n{out.stderr}")
    for line in out.stdout.splitlines():
        parts = line.rsplit(":", 1)[-1].split()
        if len(parts) == 2 and parts[0] == "U":
            undefined.add(parts[1])
        elif len(parts) == 3 and parts[1] in GLOBAL_DEFINED:
            defined.add(parts[2])
    return defined, undefined


def build_graph(root, target, tool):
    manifest = os.path.join(root, MANIFEST_DIR, f"{target}-objects.txt")
    if not os.path.isfile(manifest):
        sys.exit(
            f"check-object-graph: no manifest for {target}. Run `zig build object-manifest` first."
        )
    with open(manifest, encoding="utf-8") as fh:
        paths = [ln.strip() for ln in fh if ln.strip()]

    # A gate must never report a clean tree from an empty measurement.
    if not paths:
        sys.exit(
            f"check-object-graph: BROKEN -- the {target} manifest is empty. "
            "A product with no objects is a broken measurement, not a clean graph."
        )

    names, defined, undefined = [], {}, {}
    for path in paths:
        name = os.path.basename(path)
        names.append(name)
        defined[name], undefined[name] = symbols(tool, path)

    provider = {}
    for name in names:
        for sym in defined[name]:
            provider.setdefault(sym, name)

    # edge A -> B when A leaves a symbol undefined that B defines
    edges = collections.defaultdict(lambda: collections.defaultdict(set))
    for name in names:
        for sym in undefined[name]:
            owner = provider.get(sym)
            if owner is not None and owner != name:
                edges[name][owner].add(sym)
    return names, edges


def sccs(nodes, edges):
    index, low, on_stack, stack, out, counter = {}, {}, {}, [], [], [0]
    for start in nodes:
        if start in index:
            continue
        work = [(start, iter(edges.get(start, {})))]
        index[start] = low[start] = counter[0]
        counter[0] += 1
        stack.append(start)
        on_stack[start] = True
        while work:
            node, it = work[-1]
            pushed = False
            for succ in it:
                if succ not in index:
                    index[succ] = low[succ] = counter[0]
                    counter[0] += 1
                    stack.append(succ)
                    on_stack[succ] = True
                    work.append((succ, iter(edges.get(succ, {}))))
                    pushed = True
                    break
                if on_stack.get(succ):
                    low[node] = min(low[node], index[succ])
            if pushed:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[node])
            if low[node] == index[node]:
                comp = []
                while True:
                    top = stack.pop()
                    on_stack[top] = False
                    comp.append(top)
                    if top == node:
                        break
                out.append(comp)
    return sorted([c for c in out if len(c) > 1], key=len, reverse=True)


def measure(root, target, tool):
    names, edges = build_graph(root, target, tool)
    comps = sccs(names, edges)

    def reach(start):
        seen, stack = {start}, [start]
        while stack:
            node = stack.pop()
            for succ in edges.get(node, {}):
                if succ not in seen:
                    seen.add(succ)
                    stack.append(succ)
        return len(seen)

    n = len(names)
    ccd = sum(reach(name) for name in names)
    tree = sum(int(math.log2(i + 1)) + 1 for i in range(n)) or 1

    # Edges inside a cycle carried by exactly ONE symbol: the cheap severances.
    # Reported so a slice can be chosen, never gated -- severing one is a design
    # decision about where a responsibility belongs, not a number to drive down.
    in_cycle = {name for comp in comps for name in comp}
    single = []
    for src in sorted(edges):
        for dst, syms in sorted(edges[src].items()):
            if len(syms) == 1 and src in in_cycle and dst in in_cycle:
                single.append({"from": src, "to": dst, "symbol": sorted(syms)[0]})

    return {
        "objects": n,
        "edges": sum(len(v) for v in edges.values()),
        "cycles": [len(c) for c in comps],
        "objects_in_cycles": len(in_cycle),
        "one_symbol_cycle_edges": len(single),
        "one_symbol_edge_list": single,
        "ccd": ccd,
        "acd": round(ccd / n, 1) if n else 0,
        "nccd": round(ccd / tree, 2),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    ap.add_argument(
        "--edges", metavar="TARGET", help="list the one-symbol cycle edges of a target and exit"
    )
    args = ap.parse_args()
    root = os.path.abspath(args.repo_root)
    tool = nm_tool()

    measured = {t: measure(root, t, tool) for t in TARGETS}

    if args.edges:
        for edge in measured[args.edges]["one_symbol_edge_list"]:
            print(f"  {edge['from']} --{edge['symbol']}--> {edge['to']}")
        return 0

    path = os.path.join(root, BASELINE)
    if args.bump:
        doc = {
            "note": (
                "REPORT-28 M1.2. The graph the LINKER builds, per target, from the "
                "object set the build DECLARES (zig build object-manifest). Distinct "
                "from the @import graph in check-module-graph.py: moving a file "
                "between directories changes that one and cannot change this one. "
                "Cycles/size/trapped are gated and must not rise. ccd/acd/nccd and "
                "the one-symbol cycle edges are REPORTED: Lakos's NCCD threshold "
                "assumes cycles cost compile time, and z47's cost neither compile "
                "time, flash (--gc-sections) nor test isolation (owners already link "
                "standalone)."
            ),
            "targets": {
                t: {k: v for k, v in m.items() if k != "one_symbol_edge_list"}
                for t, m in measured.items()
            },
        }
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, sort_keys=True)
            fh.write("\n")
        for t, m in measured.items():
            print(
                f"check-object-graph: re-pinned {t}: {m['objects']} objects, "
                f"cycles {m['cycles']}, {m['one_symbol_cycle_edges']} one-symbol "
                f"cycle edges, NCCD {m['nccd']}"
            )
        return 0

    if not os.path.isfile(path):
        sys.exit(f"missing baseline {BASELINE} (create it with --bump)")
    with open(path, encoding="utf-8") as fh:
        base = json.load(fh)["targets"]

    fails, improved = [], False
    for target, m in measured.items():
        b = base.get(target)
        if b is None:
            fails.append(f"{target}: no baseline entry (re-pin with --bump)")
            continue
        print(
            f"  {target:<6} objects {m['objects']:>3}  edges {m['edges']:>4}  "
            f"cycles {m['cycles']}  trapped {m['objects_in_cycles']:>3}  "
            f"1-sym cycle edges {m['one_symbol_cycle_edges']:>3}  "
            f"NCCD {m['nccd']}"
        )
        if len(m["cycles"]) > len(b["cycles"]):
            fails.append(
                f"{target}: cyclic components rose {len(b['cycles'])} -> {len(m['cycles'])}"
            )
        if m["cycles"] and b["cycles"] and max(m["cycles"]) > max(b["cycles"]):
            fails.append(
                f"{target}: largest object cycle grew {max(b['cycles'])} -> {max(m['cycles'])}"
            )
        if m["objects_in_cycles"] > b["objects_in_cycles"]:
            fails.append(
                f"{target}: objects trapped in a cycle rose "
                f"{b['objects_in_cycles']} -> {m['objects_in_cycles']}"
            )
        if m["objects_in_cycles"] < b["objects_in_cycles"] or len(m["cycles"]) < len(b["cycles"]):
            improved = True

    print("  (CCD/ACD/NCCD and one-symbol edges are reported, not gated)")

    if fails:
        print("\nOBJECT GRAPH REGRESSED:")
        for f in fails:
            print(f"  {f}")
        print("\nAn object cycle is what the linker must resolve together: it decides")
        print("what a firmware package carries and what a parity suite can link on")
        print("its own. Inspect the responsible edge with --edges <target>. If a")
        print("cycle legitimately shrank, re-pin with --bump.")
        return 1

    print("check-object-graph: OK" + ("  (IMPROVED -- re-pin with --bump)" if improved else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
