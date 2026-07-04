#!/usr/bin/env python3
"""Constant-offset oracle (REPORT-23 P3 / MILESTONES-4 M22).

The abi/constants.zig typed accessors reach the generated `constants` blob at a
hand-maintained byte offset (`at(4856)` -> const_1). A wrong offset reads mid-
constant garbage -> silent decNumber corruption -> SEGV (the offset-crash class).
This oracle proves every abi offset against the C ground truth in
src/generated/constantPointers.h, so the remaining constant-blob @ptrCast sites
can be migrated to named abi accessors safely.

Two checks per abi accessor `constX() -> at(O)`:
  1. O must be a real constant boundary in constantPointers.h (else: garbage
     offset -> hard FAIL).
  2. the C constant living at O must be name-compatible with `constX` (catches a
     valid-but-swapped offset, e.g. const_1 pointing at const_2's slot).

Exit 1 on any failure. Run standalone or via `zig build constant-offset-parity`.
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
CPTR = ROOT / "src/generated/constantPointers.h"
ABI = ROOT / "zig_src/abi/constants.zig"

# C: #define const_1 ((real_t *)(constants + 4856))  /  real34_t variant too
C_DEF = re.compile(
    r"#define\s+(const\w+)\s+\(\(real(?:34)?_t \*\)\(constants \+ (\d+)\)\)"
)
# abi: pub inline fn const_1() ... { return at(4856); }  (at | at34 | cstR... skipped: dynamic)
ABI_FN = re.compile(
    r"pub inline fn (const\w+)\(\)[^\{]*\{\s*return at3?4?\((\d+)\);", re.S
)


def normalize(name: str) -> str:
    """Reduce a constant name to its identifying token set, dropping the
    decNumber precision annotations (39/34/75/1071/2139/2075/...) that the Zig
    accessors sometimes prepend but the C blob does not distinguish."""
    n = name.lower()
    if n.startswith("const"):
        n = n[5:]
    n = n.replace("_", "")
    # strip a leading precision-prefix run only when it is one of the known
    # decNumber contexts AND is followed by a letter (so "1on2" keeps its 1).
    m = re.match(r"(39|34|75|1071|2139|2075|1000)(?=[a-z])", n)
    if m:
        n = n[m.end():]
    # drop the abi-only "Off" suffix annotation (const__1Off aliases const__1).
    if n.endswith("off"):
        n = n[:-3]
    return n


def main() -> int:
    ctext = CPTR.read_text()
    # offset -> set of C names living there (usually one)
    off_to_names: dict[int, set] = {}
    for name, off in C_DEF.findall(ctext):
        off_to_names.setdefault(int(off), set()).add(name)
    c_norms = {off: {normalize(x) for x in names} for off, names in off_to_names.items()}

    atext = ABI.read_text()
    accessors = [(name, int(off)) for name, off in ABI_FN.findall(atext)]

    if not accessors:
        print("check-constant-offsets: no abi accessors parsed -- regex drift?", file=sys.stderr)
        return 1

    garbage = []
    swapped = []
    for zname, off in accessors:
        if off not in off_to_names:
            garbage.append((zname, off))
            continue
        if normalize(zname) not in c_norms[off]:
            swapped.append((zname, off, sorted(off_to_names[off])))

    ok = len(accessors) - len(garbage) - len(swapped)
    print(f"constant-offset oracle: {len(accessors)} abi accessors checked against "
          f"{len(off_to_names)} C constant offsets")
    print(f"  matched: {ok}")
    for zname, off in garbage:
        print(f"  GARBAGE OFFSET: abi.{zname}() -> at({off}) is not any C constant boundary")
    for zname, off, cnames in swapped:
        print(f"  NAME MISMATCH: abi.{zname}() -> at({off}) but C has {cnames} there")

    if garbage or swapped:
        print(f"FAIL: {len(garbage)} garbage + {len(swapped)} mismatched offsets", file=sys.stderr)
        return 1
    print("PASS: every abi constant offset matches the C ground truth")
    return 0


if __name__ == "__main__":
    sys.exit(main())
