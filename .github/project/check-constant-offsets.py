#!/usr/bin/env python3
"""Constant-offset oracle.

The abi/constants.zig typed accessors reach the generated `constants` blob at a
hand-maintained byte offset (`at(4856)` -> const_1). A wrong offset reads mid-
constant garbage -> silent decNumber corruption -> SEGV (the offset-crash class).
This oracle proves every abi offset against the C ground truth in
src/generated/constantPointers.h, so the remaining constant-blob @ptrCast sites
can be migrated to named abi accessors safely.

Two checks per binding `constX -> O`:
  1. O must be a real constant boundary in constantPointers.h (else: garbage
     offset -> hard FAIL).
  2. the C constant living at O must be name-compatible with `constX` (catches a
     valid-but-swapped offset, e.g. const_1 pointing at const_2's slot).

Both run over the abi accessors AND over the offsets owners bind directly, in
`constR(N)` / `OFF_const_X` / `offset_const_X` form (see OWNERS). The owner half
used to be checked by nothing: --fix could remap it, but the default run read
only abi/constants.zig and the owner tables were assumed testSuite-gated. They
are not -- the display owner's IRFRAC constants are reached only with FLAG_IRFRAC
set, and the corpus never sets it -- so a blob shift could move them with no lane
able to notice. Check 2 is what makes this worth running: after a shift every
offset is still SOME constant's boundary, so only the name join catches it.

Exit 1 on any failure. Run standalone or via `zig build constant-offset-parity`.
"""

import pathlib
import re
import sys

from upstream_paths import upstream_path

ROOT = pathlib.Path(__file__).resolve().parents[2]
CPTR = upstream_path(ROOT, "src/generated/constantPointers.h")
ABI = ROOT / "src/abi/constants.zig"

# C: #define const_1 ((real_t *)(constants + 4856))  /  real34_t variant too
C_DEF = re.compile(r"#define\s+(const\w+)\s+\(\(real(?:34)?_t \*\)\(constants \+ (\d+)\)\)")
# abi: pub inline fn const_1() ... { return at(4856); }  (at | at34; the dynamic
# cstR(offset) helpers take an argument so `\(\)` excludes them). Matches EVERY
# zero-arg fixed-offset accessor, not just const*-named ones: the semantic
# root3on2() and the offset-named cNNNN()/qNNNN() accessors were previously skipped
# by a `const\w+` name anchor, so a stale offset on them went undetected (root3on2
# silently pointed at sqrt2/2 after a pin advance). See the name-check note below.
ABI_FN = re.compile(
    r"pub inline fn (?P<name>\w+)\(\)[^\{]*\{\s*return at3?4?\((?P<off>\d+)\);", re.S
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
        n = n[m.end() :]
    # drop the abi-only "Off" suffix annotation (const__1Off aliases const__1).
    if n.endswith("off"):
        n = n[:-3]
    return n


def _base(name: str) -> str:
    """Constant name minus its decNumber precision prefix (const_/const39_/...),
    for matching a constant whose only change across a pin advance was its digit
    count and hence its prefix (e.g. const_fpfToMph -> const39_fpfToMph)."""
    return re.sub(r"^const(?:34|39|75|1071|2139|2075|1000)?_", "", name)


# Owner-local constant offsets: the same C constant blob, bound in an owner by a
# raw byte offset instead of through an abi accessor. Every pattern captures the
# constant's NAME as well as its OFFSET, so one table serves both --fix (rewrite
# the offset) and the check (join the name against the C and prove the offset is
# still that constant's). Binding the two together is the point: an offset alone
# cannot be checked, because a blob shift moves one constant onto another's
# boundary and every offset stays "valid".
OWNERS = {
    "src/shell/display/display.zig": [r"const (?P<name>\w+) = constR3?4?\((?P<off>\d+)\)"],
    "src/shell/extensions/addons.zig": [r"const (?P<name>\w+) = constR3?4?\((?P<off>\d+)\)"],
    "src/shell/display/screen.zig": [r"const (?P<name>\w+) = constR3?4?\((?P<off>\d+)\)"],
    "src/shell/convert/conversion_units.zig": [
        r"const (?P<name>\w+) = constR3?4?\((?P<off>\d+)\)",
        r"const OFF_(?P<name>\w+) = (?P<off>\d+)",
        r"^[ \t]*(?P<off>\d+), // \d+ constFactor\w* = (?P<name>const\w+)",
    ],
    "src/core/numeric/command_wrappers/helpers.zig": [r"const offset_(?P<name>\w+) = (?P<off>\d+)"],
    "src/core/numeric/special/wp34s.zig": [r"const OFF_(?P<name>\w+): u32 = (?P<off>\d+)"],
}


def owner_sites(root: pathlib.Path):
    """Every (file, constant name, byte offset) an owner binds directly."""
    out = []
    for rel, pats in OWNERS.items():
        text = (root / rel).read_text()
        for pat in pats:
            for m in re.finditer(pat, text, re.M):
                out.append((rel, m.group("name"), int(m.group("off"))))
    return out


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

    def remap_group(m: re.Match, grp: str) -> str:
        """Rewrite only the named capture group `grp` (a byte offset) inside `m`."""
        nonlocal changed
        old = int(m.group(grp))
        no = new_off_for(old)
        if no in (None, "skip") or no == old:
            return m.group(0)
        changed += 1
        s, e = m.span(grp)
        return m.group(0)[: s - m.start()] + str(no) + m.group(0)[e - m.start() :]

    # abi/constants.zig: the at(N)/at34(N) accessors (offset is group 2).
    ABI.write_text(ABI_FN.sub(lambda m: remap_group(m, "off"), ABI.read_text()))

    missing_owners = [rel for rel in OWNERS if not (ROOT / rel).is_file()]
    if missing_owners:
        print("check-constant-offsets: BROKEN -- owner table names files that do not exist:")
        for rel in missing_owners:
            print(f"  {rel}")
        print("Refusing to remap: a partial rewrite is worse than no rewrite.")
        return 1
    for rel, pats in OWNERS.items():
        p = ROOT / rel
        text = p.read_text()
        for pat in pats:
            text = re.sub(pat, lambda m: remap_group(m, "off"), text, flags=re.M)
        p.write_text(text)

    print(
        f"--fix: {changed} constant offsets remapped (abi + owner tables), "
        f"{len(unresolved)} unresolved"
    )
    if unresolved:
        for off, name in unresolved:
            print(
                f"  UNRESOLVED old offset {off} (const {name}) not in new header "
                "-- rename the accessor by hand",
                file=sys.stderr,
            )
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
            print(
                "--fix: new constantPointers.h not generated (run `zig build constants`)",
                file=sys.stderr,
            )
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
        # "Not generated yet" is a legitimate skip -- the header is a build product.
        # "The imported tree is not where UPSTREAM_ROOT says" is not, and produces an
        # identical missing file, so the skip used to swallow a misconfigured root and
        # report a clean gate over 185 unchecked constant offsets. Separate the two by
        # asking whether the directory that should CONTAIN the header exists at all.
        if not cptr.parent.parent.is_dir():
            print(f"check-constant-offsets: BROKEN -- {cptr.parent.parent} is not a directory.")
            print("Check UPSTREAM_ROOT in .github/project/upstream-pin.env.")
            print("Refusing to skip: an unreadable imported tree is not 'not built yet'.")
            return 1
        print(
            f"check-constant-offsets: {cptr} not generated yet "
            "(run `zig build constants`); skipping"
        )
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

    # The same two tests over the offsets owners bind directly. These used to be
    # checked by nothing: --fix could remap them, but the default run looked only
    # at the abi accessors and the owner tables were left to the testSuite. That
    # fallback does not hold -- the display owner's IRFRAC constants are reached
    # only with FLAG_IRFRAC set, which the corpus never sets -- so a blob shift
    # moved them with no lane able to notice.
    missing_owners = [rel for rel in OWNERS if not (ROOT / rel).is_file()]
    if missing_owners:
        print("check-constant-offsets: BROKEN -- owner table names files that do not exist:")
        for rel in missing_owners:
            print(f"  {rel}")
        print("Refusing to report a clean gate over offsets nothing read.")
        return 1
    sites = owner_sites(ROOT)
    if not sites:
        print("check-constant-offsets: no owner offsets parsed -- regex drift?", file=sys.stderr)
        return 1
    for rel, zname, off in sites:
        if off not in off_to_names:
            garbage.append((f"{rel}:{zname}", off))
            continue
        nz = normalize(zname)
        if nz in all_c_norms and nz not in c_norms[off]:
            swapped.append((f"{rel}:{zname}", off, sorted(off_to_names[off])))

    total = len(accessors) + len(sites)
    ok = total - len(garbage) - len(swapped)
    print(
        f"constant-offset oracle: {len(accessors)} abi accessors + {len(sites)} owner-bound "
        f"offsets checked against {len(off_to_names)} C constant offsets"
    )
    print(f"  matched: {ok}")
    for zname, off in garbage:
        print(f"  GARBAGE OFFSET: {zname} -> {off} is not any C constant boundary")
    for zname, off, cnames in swapped:
        print(f"  NAME MISMATCH: {zname} -> {off} but C has {cnames} there")

    if garbage or swapped:
        print(f"FAIL: {len(garbage)} garbage + {len(swapped)} mismatched offsets", file=sys.stderr)
        return 1
    print("PASS: every constant offset, abi and owner-bound, matches the C ground truth")
    return 0


if __name__ == "__main__":
    sys.exit(main())
