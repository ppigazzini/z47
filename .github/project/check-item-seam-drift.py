#!/usr/bin/env python3
"""Item-seam drift gate: the seam must not outrun its owner.

WHAT THIS CATCHES, AND WHY NOTHING ELSE DOES.

`src/shell/display/items/items.zig` holds indexOfItems[], whose rows are
byte-dumped from the C-compiled table. It therefore ADVANCES BY ITSELF on every
upstream pin advance, while the hand-written owners that implement those items do
not. A row can start binding a different function, and nothing fails.

That has already cost users a feature. Upstream moved four plot overlays from
PLOT_* globals to system flags. The re-synced table began binding
    row 2294  fnGetSystemFlag  param 32875 (FLAG_PRMS)   "PLrms"
while shell/plot/graphs.zig still read a `PLOT_RMS` global that nothing wrote any
more. The toggles wrote a flag nothing read: PLrms/PLintg/PLdiff/PLshad did
nothing at all.

EVERY EXISTING GATE PASSED:
  audit-item-table-parity.py   verifies the table against the C   -> the table was CORRECT
  audit-constant-parity.py     verifies constants against the C   -> correct
  check-constant-offsets.py    verifies offsets against the C     -> correct
  the testSuite (12045 cases)  cannot see a plot                  -> green
The seam was faithful. The OWNER was stale. No gate asks that question.

THE RULE: when a row's (func, param) changes, a human must confirm the owner
implementing that symbol followed. This gate cannot decide that -- it FAILS on any
change and makes the confirmation explicit via --bump. A seam that moves silently
is the defect; a seam that moves loudly is a review.

Scope: all 2871 rows, keyed by item number. ~30 rows are comptime-conditional
(`if (option_xfn_1000) ext_fnXXfn else &itemToBeCoded`); their func EXPRESSION is
compared as text, so they are covered too. Capturing them is not optional: the first
sits at item 2554, and skipping them would shift the key of every later row and
report one upstream change as thousands of false drifts.

Usage: check-item-seam-drift.py            # enforce
       check-item-seam-drift.py --bump     # re-pin, ONLY with the owners verified
"""

import argparse
import json
import os
import re
import sys

ITEMS = "src/shell/display/items/items.zig"
BASELINE = ".github/project/item-seam-baseline.json"

# Every row, in table order, so the parse index IS the item number.
# The func field is captured as an EXPRESSION, not an identifier: ~30 rows are
# comptime-conditional (`if (option_xfn_1000) ext_fnXXfn else &itemToBeCoded`) and
# skipping them would shift the index of every row after position 2554, turning one
# upstream change into thousands of false drifts.
ROW = re.compile(r"\.\{\s*\.func\s*=\s*([^,]+?)\s*,\s*\.param\s*=\s*(\d+)\s*,")
ANY_ROW = re.compile(r"\.\{\s*\.func\s*=")


def extract(repo_root):
    path = os.path.join(repo_root, ITEMS)
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    start = text.index("indexOfItems")
    table = text[start:]
    rows = {str(i): [re.sub(r"\s+", " ", f), p] for i, (f, p) in enumerate(ROW.findall(table))}
    total = len(ANY_ROW.findall(table))
    return rows, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    args = ap.parse_args()
    root = os.path.abspath(args.repo_root)

    rows, total = extract(root)
    varying = total - len(rows)

    # A detector that finds nothing must not report a clean tree.
    if not rows:
        print("check-item-seam-drift: BROKEN -- parsed zero item rows.")
        print("items.zig is known to hold thousands. A zero count means the row")
        print("pattern stopped matching, not that the seam is unchanged.")
        return 1

    bpath = os.path.join(root, BASELINE)

    if args.bump:
        doc = {
            "note": (
                "Item-seam baseline. indexOfItems[] is byte-dumped from the C, so it "
                "advances by itself on a pin advance while hand-written owners do not. "
                "A changed (func, param) means a row now binds different behaviour: "
                "confirm the owner implementing that symbol followed, THEN --bump. "
                "Re-pinning without checking the owners reintroduces the dead-toggle "
                "class of defect that the other seam gates cannot see."
            ),
            "rows_total": len(rows),
            "unparsed_rows": varying,
            "rows": rows,
        }
        with open(bpath, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, sort_keys=True)
            fh.write("\n")
        print(f"check-item-seam-drift: re-pinned {len(rows)} item rows ({varying} unparsed)")
        return 0

    if not os.path.isfile(bpath):
        sys.exit(f"missing baseline {BASELINE} (create it with --bump)")
    with open(bpath, encoding="utf-8") as fh:
        base = json.load(fh)

    old = base["rows"]
    changed, added, removed = [], [], []
    for k, v in rows.items():
        if k not in old:
            added.append((k, v))
        elif old[k] != v:
            changed.append((k, old[k], v))
    for k in old:
        if k not in rows:
            removed.append((k, old[k]))

    varying_delta = varying != base.get("unparsed_rows", varying)

    if not (changed or added or removed or varying_delta):
        print(f"check-item-seam-drift: OK ({len(rows)} item rows unchanged)")
        return 0

    print("ITEM SEAM DRIFTED: the byte-dumped table changed.")
    print("The seam advances on a pin advance; the owners do not. Confirm that the")
    print("owner implementing each symbol below followed the change, then re-pin")
    print("with --bump. This gate cannot check the owner for you -- that is the point.")
    print()
    for k, o, n in changed[:40]:
        print(f"  row {k:>5}  func {o[0]} -> {n[0]}   param {o[1]} -> {n[1]}")
    if len(changed) > 40:
        print(f"  ... and {len(changed) - 40} more changed rows")
    for k, v in added[:10]:
        print(f"  row {k:>5}  ADDED    func {v[0]} param {v[1]}")
    for k, v in removed[:10]:
        print(f"  row {k:>5}  REMOVED  was func {v[0]} param {v[1]}")
    if varying_delta:
        print(f"  unparsed row count {base.get('unparsed_rows')} -> {varying}")
    print()
    print("Worked example of what this catches: rows binding fnGetSystemFlag with")
    print("params 32875-32878 (FLAG_PRMS/PINTG/PDIFF/PSHADE) while the plot renderer")
    print("still read PLOT_* globals -- the toggles wrote flags nothing read, and")
    print("every other gate passed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
