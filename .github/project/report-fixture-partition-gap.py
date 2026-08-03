#!/usr/bin/env python3
"""What do the owners discriminate on that the fixtures do not partition?

WHY THIS EXISTS, AND WHY IT IS A REPORT AND NOT A GATE.

`check-fixture-partition.py` enforces a written list of properties, and its own
docstring says it cannot check that the list is COMPLETE. That sentence is true.
It was also, for one pass, treated as though it discharged the obligation -- and
in that pass the list omitted `FLAG_CPXRES`, which the owners read at 32 sites and
which decides whether an out-of-domain real answers with a complex result or a
domain error. Every fixture left it set; forcing the branch always-taken changed
nothing across the whole lane.

So: a gate cannot answer "is the list complete?", but somebody has to, and the
only honest form of the answer is a diff that a person reads.

This script produces that diff. It enumerates, mechanically, what the owner code
actually branches on -- the flags it reads, the data types it compares against,
the register predicates it calls -- and subtracts what `PARTITION_PROPERTIES`
already names.

**IT IS NOT GATED AT ZERO AND MUST NOT BE.** A non-empty result is the expected
state, for two honest reasons: some properties are display-only and no wrapper in
the case tables reads them (FLAG_POLAR lives in the ->CX commands), and some are
unreachable from these wrappers at all. The deliverable is the reviewed list, with
each row either turned into a property or given a sentence. Gating it at zero would
buy silence by adding fixtures for branches nothing runs, which is the failure this
whole report is about, inverted.

Usage:
  report-fixture-partition-gap.py [--repo-root .]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

HARNESS = "build/tests/math_wrappers_full_core/math_wrappers_full_core_parity_harness.c"
OWNER_ROOT = "src/core/numeric"

PARTITION_RE = re.compile(
    r"static const partitionClass_t PARTITION_PROPERTIES\[\] = \{(.*?)\n\};", re.S
)
PARTITION_ROW_RE = re.compile(r'\{\s*"([\w]+)"\s*,\s*"([\w]+)"\s*,\s*"([\w]+)"\s*\}')

FLAG_RE = re.compile(r"\bFLAG_([A-Z0-9_]+)\b")
DATATYPE_RE = re.compile(r"\bdt([A-Z]\w+)\b")
PREDICATE_RE = re.compile(r"\b(real34?Is[A-Z]\w*|isRegisterMatrix\w*|isMatrix\w+)\b")

# Properties the list names, mapped to the tokens that would show up in owner code.
# Kept explicit rather than fuzzy-matched: a property is only "covered" when
# somebody says which owner-visible thing it corresponds to.
PROPERTY_TOKENS = {
    "dataType": {
        "dtReal34",
        "dtComplex34",
        "dtLongInteger",
        "dtShortInteger",
        "dtString",
        "dtReal34Matrix",
        "dtComplex34Matrix",
        "dtTime",
    },
    "sign": {"realIsNegative", "real34IsNegative", "realIsPositive", "real34IsPositive"},
    "integerSign": set(),
    "integerZero": set(),
    "magnitude": {
        "realIsZero",
        "real34IsZero",
        "realIsNaN",
        "real34IsNaN",
        "realIsInfinite",
        "real34IsInfinite",
        "realIsSpecial",
        "real34IsSpecial",
    },
    "parity": set(),
    "angularMode": set(),
    "complexZero": set(),
    "complexRepresentation": set(),
    "matrixShape": {"isRegisterMatrixVector", "isMatrix2dVector", "isMatrix3dVector"},
    "matrixAngularMode": set(),
    "spcres": {"FLAG_SPCRES"},
    "cpxres": {"FLAG_CPXRES"},
    "resultFlags": {"FLAG_SPCRES", "FLAG_CPXRES"},
    "hprp": {"FLAG_HPRP"},
}

# Owner-visible things deliberately NOT partitioned, each with the reason. This is
# the half of the answer a gate cannot produce.
REVIEWED: dict[str, str] = {
    "FLAG_POLAR": (
        "Seven sites, all in cxtore.zig and retocx.zig -- the ->CX and RE->CX"
        " commands. This lane drives neither, so a fixture would partition a property"
        " no wrapper in its case tables reads."
    ),
    "FLAG_ALPHA": "Alpha-entry mode; no math wrapper in these tables reads it.",
    "FLAG_USER": "Keyboard remapping; belongs to the keyboard lanes.",
    "FLAG_SOLVING": "Set by the solver around a call, not by any wrapper here.",
    "FLAG_INTING": "Set by the integrator around a call, not by any wrapper here.",
    "FLAG_FRACT": "Fraction DISPLAY mode; changes rendering, not computation.",
    "FLAG_NUMLOCK": "Keyboard entry mode.",
    "FLAG_TOPHEX": "Display of hex digits.",
    "FLAG_SSIZE8": "Stack size; the harness fixes it and the wrappers do not vary it.",
    "FLAG_MYM_TRIPLE": "Menu behaviour.",
    "FLAG_HOME_TRIPLE": "Menu behaviour.",
    "dtConfig": (
        "A config descriptor register. No math wrapper accepts one; the orphaned unit"
        " fixture that built one belonged to a state-save case, not an arithmetic one."
    ),
    "dtDate": "Reachable, and currently only through fnCheckType's parameter sweep.",
    "FLAG_ASLIFT": (
        "Stack lift. Sixty sites, and every wrapper that produces a result sets it --"
        " so it is an OUTPUT of these wrappers, compared in the snapshot, rather than"
        " an input the fixtures should vary."
    ),
    "FLAG_QUIET": "Error-message suppression; changes what is displayed, not computed.",
    "FLAG_PROPFR": "Proper-fraction DISPLAY mode.",
    "dtConfigDescriptor_t": "A type name, not a register data type -- the scan sees the typedef.",
    "dtRealMatrix": "A spelling that appears only in comments; the register type is dtReal34Matrix.",
    "real34IsAnInteger": (
        "Covered in substance by the `parity` property, whose realEven/realOdd"
        " representatives are integers and whose realFraction one is not."
    ),
    "isMatrixVector": "The unprefixed spelling of isRegisterMatrixVector, covered by matrixShape.",
    "isRegisterMatrix2dVector": "Covered by matrixShape/vector2d.",
    "isRegisterMatrix3dVector": "Covered by matrixShape/vector3d.",
}

# Owner-visible things that SHOULD be partitioned and are not. Distinct from
# REVIEWED on purpose: these are open findings with a reason to act, not decisions.
# The report prints them separately so a real gap cannot be retired by writing a
# plausible sentence beside it.
OPEN: dict[str, str] = {
    "FLAG_CARRY": (
        "14 sites. Short-integer arithmetic SETS it and the rotate/shift wrappers READ"
        " it, so it is an input as well as an output. No fixture varies it."
    ),
    "FLAG_OVERFLOW": (
        "15 sites, same shape as FLAG_CARRY: written by the integer arithmetic and read"
        " back. No fixture varies it."
    ),
    "FLAG_WRAPEDG": "Integer index wrap behaviour; read by index_command. No fixture varies it.",
    "FLAG_WRAPEND": "Integer index wrap behaviour; read by index_command. No fixture varies it.",
    "isMatrixDiagonal": "A matrix shape class the fixture set has no representative for.",
    "isMatrixIndexed": "A matrix shape class the fixture set has no representative for.",
    "isRegisterMatrixFactors": "A matrix shape class the fixture set has no representative for.",
}


def owner_tokens(repo: Path) -> dict[str, set[str]]:
    files = subprocess.run(
        ["git", "-C", str(repo), "ls-files", f"{OWNER_ROOT}/**/*.zig"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    flags: set[str] = set()
    types: set[str] = set()
    preds: set[str] = set()
    for rel in files:
        text = (repo / rel).read_text(errors="replace")
        flags.update("FLAG_" + m for m in FLAG_RE.findall(text))
        types.update("dt" + m for m in DATATYPE_RE.findall(text))
        preds.update(PREDICATE_RE.findall(text))
    return {"flags": flags, "types": types, "predicates": preds}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    text = (repo / HARNESS).read_text(encoding="utf-8")
    block = PARTITION_RE.search(text)
    if not block:
        print("report-fixture-partition-gap: BROKEN -- PARTITION_PROPERTIES not found")
        return 1
    named_properties = {p for p, _, _ in PARTITION_ROW_RE.findall(block.group(1))}

    covered: set[str] = set()
    for prop in named_properties:
        covered |= PROPERTY_TOKENS.get(prop, set())

    found = owner_tokens(repo)
    print(
        f"report-fixture-partition-gap: {len(named_properties)} named propert(ies)"
        f" cover {len(covered)} owner-visible token(s)"
    )

    for kind in ("flags", "types", "predicates"):
        gap = sorted(
            t for t in found[kind] if t not in covered and t not in REVIEWED and t not in OPEN
        )
        openrows = sorted(t for t in found[kind] if t not in covered and t in OPEN)
        reviewed = sorted(t for t in found[kind] if t not in covered and t in REVIEWED)
        print(f"\n  {kind}: {len(found[kind])} seen, {len(gap)} unpartitioned and unreviewed")
        for token in gap:
            print(f"      {token}")
        if openrows:
            print(f"    OPEN -- should be partitioned and is not ({len(openrows)}):")
            for token in openrows:
                print(f"      {token} -- {OPEN[token][:74]}")
        if reviewed:
            print(f"    reviewed and deliberately not partitioned ({len(reviewed)}):")
            for token in reviewed:
                print(f"      {token} -- {REVIEWED[token][:76]}")

    print(
        "\nThis is a REPORT. A non-empty list is the expected state: some of these are"
        "\ndisplay-only and some are unreachable from these wrappers. Each row wants"
        "\neither a property in PARTITION_PROPERTIES or a sentence in REVIEWED above."
        "\nGating it at zero would buy silence by adding fixtures for branches nothing"
        "\nruns, which is this report's own failure mode inverted."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
