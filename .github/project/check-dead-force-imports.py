#!/usr/bin/env python3
"""A force-import must force something into the link.

WHAT A FORCE-IMPORT IS FOR. Zig only analyses a file something references. An owner
whose symbols are reached by C ABI -- through the item dispatch table, or from
another object -- has no Zig-level referrer, so its `pub export` decls would never
be emitted and would silently vanish from the link. A module root force-imports it
(`_ = @import("owner.zig");`) precisely to make that emission happen.

So a force-import of a file that exports NOTHING forces nothing. It is dead: it
compiles a file whose symbols were already reachable, or -- worse -- it advertises
an intent that has quietly stopped being true.

WHY THIS NEEDS A GATE. Both failure modes are silent and both have happened here:

  * shell/real_type.zig was force-imported under the comment "realType.c owner:
    EXPORTS low-level real<->int helpers with C linkage". Its contents had moved to
    the kernel; it was reduced to a re-declaration shim with zero exports. The
    force-import and the comment both survived the move and both lied.
  * shell/runtime.zig declared 18 `pub extern fn z47_frontier_legacy_*` symbols
    that were defined NOWHERE in the tree and referenced by nothing. Entirely dead,
    and invisible because an unused extern declaration emits no code and breaks no
    link.

Neither cost a byte of flash -- `--gc-sections` and Zig's laziness see to that. Both
cost a reader the truth about what the root is doing and why.

THE RULE. Every force-imported file must export at least one symbol, by any of
Zig's three forms. If it does not, either it is dead (delete it), or its symbols are
reached some other way (remove the force-import and say so).

Usage: check-dead-force-imports.py [--repo-root .]
"""

import argparse
import os
import re
import sys

FORCE = re.compile(r'(?m)^\s*_\s*=\s*@import\("([^"]+\.zig)"\)\s*;')
# Zig exports a symbol three ways and a detector that knows only one reports
# confident nonsense: `pub export fn`, a bare `export fn` (file-scope, no pub), and
# `@export(&decl, .{ .name = ... })`. keyboard_state_ringbuffer.zig uses the third
# form exclusively -- seven times -- and a `pub export`-only regex called it dead.
EXPORT = re.compile(
    r"(?m)^\s*(?:pub\s+)?export\s+(?:fn|var|const)\s+\w+"
    r"|@export\s*\(")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    root = os.path.abspath(args.repo_root)

    forced = []  # (carrier, target)
    for dirpath, _dirs, names in os.walk(os.path.join(root, "zig_src")):
        for name in names:
            if not name.endswith(".zig"):
                continue
            carrier = os.path.join(dirpath, name)
            with open(carrier, encoding="utf-8") as fh:
                text = fh.read()
            for imp in FORCE.findall(text):
                target = os.path.normpath(os.path.join(os.path.dirname(carrier), imp))
                forced.append((os.path.relpath(carrier, root),
                               os.path.relpath(target, root) if os.path.isfile(target)
                               else None, target))

    # A detector that finds nothing must never report a clean tree.
    if not forced:
        print("check-dead-force-imports: BROKEN -- found no force-imports at all.")
        print("zig_src's module roots are known to use them. A zero count means the")
        print("pattern stopped matching, not that the tree is clean.")
        return 1

    dead, missing = [], []
    for carrier, rel, target in forced:
        if rel is None:
            missing.append((carrier, target))
            continue
        with open(target, encoding="utf-8") as fh:
            if not EXPORT.search(fh.read()):
                dead.append((carrier, rel))

    if missing:
        print("FORCE-IMPORT OF A FILE THAT DOES NOT EXIST:")
        for carrier, target in missing:
            print(f"  {carrier} -> {target}")
        return 1

    if dead:
        print(f"DEAD FORCE-IMPORT: {len(dead)} force-imported file(s) export nothing.")
        for carrier, rel in dead:
            print(f"  {carrier}\n      forces {rel}, which exports no symbol")
        print()
        print("A force-import exists to make a file's exports reach the link when no")
        print("Zig code references it. Forcing a file that exports nothing forces")
        print("nothing. Either the file is dead (delete it), or its symbols are")
        print("reached another way (drop the force-import). Both have happened here:")
        print("real_type.zig kept a force-import and a comment claiming it 'exports")
        print("low-level helpers' after its contents moved to the kernel, and")
        print("runtime.zig declared 18 externs defined nowhere at all.")
        return 1

    print(f"check-dead-force-imports: OK ({len(forced)} force-imports, "
          "every target exports at least one symbol)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
