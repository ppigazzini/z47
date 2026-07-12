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
# abi: pub inline fn const_1() ... { return at(4856); }  (at | at34; the dynamic
# cstR(offset) helpers take an argument so `\(\)` excludes them). Matches EVERY
# zero-arg fixed-offset accessor, not just const*-named ones: the semantic
# root3on2() and the offset-named cNNNN()/qNNNN() accessors were previously skipped
# by a `const\w+` name anchor, so a stale offset on them went undetected (root3on2
# silently pointed at sqrt2/2 after a pin advance). See the name-check note below.
ABI_FN = re.compile(
    r"pub inline fn (\w+)\(\)[^\{]*\{\s*return at3?4?\((\d+)\);", re.S
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


def _base(name: str) -> str:
    """Constant name minus its decNumber precision prefix (const_/const39_/...),
    for matching a constant whose only change across a pin advance was its digit
    count and hence its prefix (e.g. const_fpfToMph -> const39_fpfToMph)."""
    return re.sub(r"^const(?:34|39|75|1071|2139|2075|1000)?_", "", name)


def apply_fix(old_cptr: pathlib.Path, new_ctext: str) -> int:
    """`--fix`: rewrite every abi accessor's byte offset to track the same C
    constant across a constant-blob shift, by pairing the OLD header (which the
    current abi offsets still match) against the NEW one BY NAME -- exactly the
    remap done by hand on a pin advance. Read-only default; only touched under
    --fix. The behavioural proof stays the full parity battery (run-local-gate).

    old_cptr: the pre-advance constantPointers.h (regenerate it from the old
    pin's generateConstants.c in a cache-cleared `zig build constants`)."""
    if not old_cptr.exists():
        print(f"--fix: old header {old_cptr} not found", file=sys.stderr)
        return 1
    old_off_to_name: dict[int, str] = {}
    for name, off in C_DEF.findall(old_cptr.read_text()):
        old_off_to_name.setdefault(int(off), name)  # a representative name per offset
    new_name_to_off = {name: int(off) for name, off in C_DEF.findall(new_ctext)}
    new_base_to_offs: dict[str, set] = {}
    for name, off in new_name_to_off.items():
        new_base_to_offs.setdefault(_base(name), set()).add(off)

    changed = 0
    unresolved: list = []

    def new_off_for(old: int):
        """Old byte offset -> new byte offset for the SAME constant (by name, with
        a digit-prefix-rename fallback). None if the old offset is not a constant
        boundary (leave untouched) or the constant vanished (report)."""
        name = old_off_to_name.get(old)
        if name is None:
            return "skip"
        no = new_name_to_off.get(name)
        if no is None:
            cands = new_base_to_offs.get(_base(name), set())
            no = next(iter(cands)) if len(cands) == 1 else None
        if no is None:
            unresolved.append((old, name))
        return no

    def remap_group(m: "re.Match", grp: int) -> str:
        """Rewrite only capture group `grp` (a byte offset) inside match `m`."""
        nonlocal changed
        old = int(m.group(grp))
        no = new_off_for(old)
        if no in (None, "skip") or no == old:
            return m.group(0)
        changed += 1
        s, e = m.span(grp)
        return m.group(0)[: s - m.start()] + str(no) + m.group(0)[e - m.start():]

    # abi/constants.zig: the at(N)/at34(N) accessors (offset is group 2).
    ABI.write_text(ABI_FN.sub(lambda m: remap_group(m, 2), ABI.read_text()))

    # Owner-local offset tables (NOT covered by the abi oracle, testSuite-gated
    # only): the same by-name remap, keyed on each file's offset-literal pattern.
    OWNERS = {
        "zig_src/frontier/display/display.zig": [r"constR3?4?\((\d+)\)"],
        "zig_src/frontier/frontier_addons.zig": [r"constR3?4?\((\d+)\)"],
        "zig_src/frontier/display/screen.zig": [r"constR3?4?\((\d+)\)"],
        "zig_src/frontier/frontier_conversion_units.zig": [
            r"constR3?4?\((\d+)\)",
            r"OFF_const\w* = (\d+)",
            r"^\s*(\d+), // \d+ constFactor",
        ],
        "zig_src/mathematics/math_runtime_helpers.zig": [r"offset_const\w* = (\d+)"],
        "zig_src/mathematics/math_wp34s.zig": [r"OFF_const51_gammaC01: u32 = (\d+)"],
    }
    for rel, pats in OWNERS.items():
        p = ROOT / rel
        text = p.read_text()
        for pat in pats:
            text = re.sub(pat, lambda m: remap_group(m, 1), text, flags=re.M)
        p.write_text(text)

    print(f"--fix: {changed} constant offsets remapped (abi + owner tables), "
          f"{len(unresolved)} unresolved")
    if unresolved:
        for off, name in unresolved:
            print(f"  UNRESOLVED old offset {off} (const {name}) not in new header "
                  "-- rename the accessor by hand", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    args = sys.argv[1:]
    # constantPointers.h is a generateConstants build output (gitignored); it is
    # copied to src/generated by `zig build constants`. If it is absent (a fresh
    # checkout that has not built yet), skip rather than hard-fail -- the CI lane
    # runs `zig build constants` first so the gate is active there.
    def opt(flag):
        return pathlib.Path(args[args.index(flag) + 1]) if flag in args else None
    cptr = opt("--constant-pointers") or CPTR
    if "--fix" in args:
        if not cptr.exists():
            print("--fix: new constantPointers.h not generated (run `zig build constants`)", file=sys.stderr)
            return 1
        old = opt("--old-constant-pointers")
        if old is None:
            print("--fix requires --old-constant-pointers <pre-advance header>", file=sys.stderr)
            return 1
        rc = apply_fix(old, cptr.read_text())
        if rc:
            return rc
        # fall through to re-validate the freshly-fixed file against the new header
    if not cptr.exists():
        print(f"check-constant-offsets: {cptr} not generated yet "
              "(run `zig build constants`); skipping")
        return 0
    ctext = cptr.read_text()
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

    # Every C constant's normalized token. An accessor whose normalized name is in
    # here is a SEMANTIC accessor (const_1, root3on2) and must sit on the matching
    # constant; one that is not (the offset-named cNNNN/qNNNN, whose name encodes an
    # offset, not a constant) carries no name to verify, so it gets the garbage-
    # offset check only.
    all_c_norms = set().union(*c_norms.values()) if c_norms else set()

    garbage = []
    swapped = []
    for zname, off in accessors:
        if off not in off_to_names:
            garbage.append((zname, off))
            continue
        nz = normalize(zname)
        if nz in all_c_norms and nz not in c_norms[off]:
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
