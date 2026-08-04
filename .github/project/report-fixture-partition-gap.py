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

WHAT IT COUNTS OVER, AND THE ROW THAT WAS WRONG BECAUSE OF IT. This subtracts one
lane's fixture tables from the owners' branch sites, and for one pass it said OPEN
in a voice that sounded like it had looked at the tree. It had not. `FLAG_CARRY`
was listed as "no fixture varies it" while `rotate_bits_parity` had been seeding it
as a case parameter since long before this report existed -- 38 cases, 32 with the
flag clear and 6 with it set, compared in its snapshot. That is standing clause 6
inside the instrument written for clause 5.

So a property now carries the lane that covers it, and four verdicts stand between
OPEN and a property:

  COVERED        another parity lane in the battery varies it. The lane is named and
                 the evidence is re-checked here, so the claim cannot rot.
  COVERED-FAKE   another lane varies it, but that lane's environment is a fake
                 runtime rather than the real core. NOT green: it says the
                 discrimination is real for this property and the surrounding state
                 is modelled. Written out per row, because "a green fake proves
                 control flow and not answers" is what this whole report is about.
  BLOCKED        no fixture over the current owner set can discriminate on it, and
                 the reason is a fact about the port rather than about the fixtures
                 -- typically that the only reader is still C both sides call.
  REVIEWED       reachable in principle, deliberately not partitioned, with a reason.

`--check` fails when this bookkeeping contradicts itself: an OPEN row that another
lane demonstrably references, or a COVERED / BLOCKED row whose named evidence is
gone. The GAP is still not gated; its accounting is.

Usage:
  report-fixture-partition-gap.py [--repo-root .]
  report-fixture-partition-gap.py --check       # fail on self-contradicting rows
  report-fixture-partition-gap.py --self-test   # prove --check fires
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
    "FLAG_OVERFLOW": (
        "An OUTPUT, and the proof is stronger than the FLAG_ASLIFT one. 15 writes"
        " across src/core/ and the only reads anywhere are statusBar (display) and"
        " ONE guard, in convertLongIntegerToShortIntegerRegister"
        " (shell/register_value_conversions.zig, mirroring"
        " registerValueConversions.c:114): `if(overflow && !getSystemFlag(FLAG_OVERFLOW))"
        " setSystemFlag(FLAG_OVERFLOW)`. That is outcome-identical to `if(overflow)"
        " setSystemFlag(...)` -- setting a set flag changes nothing -- so no fixture"
        " can discriminate on it however the flag is arranged. Dropping the guard was"
        " run against 12976 testSuite cases and the full-core lane: both stay green,"
        " which is what an equivalent mutant looks like. c43's integers.c:409 read is"
        " inside a `never used` comment block."
    ),
    "FLAG_WRAPEDG": (
        "The FLAG_ASLIFT verdict in a different owner. Set and cleared by the MATRIX"
        " EDITOR (matrix_nav.zig, matrix_editor.zig, mirroring ui/matrixEditor.c) and"
        " cleared by fnIndexMatrix; the only reads in the whole of c43 are the WRPEDG"
        " and WRPEND catalog items dispatching fnGetSystemFlag. No math wrapper reads"
        " either, so this lane would be partitioning another owner's output. It is the"
        " matrix-editor differential's property -- M31-75."
    ),
    "FLAG_WRAPEND": "The same, and set at the same four sites. See FLAG_WRAPEDG.",
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

# Partitioned by ANOTHER lane in the battery. `evidence` is a path that must still
# mention the token, so a lane that stops covering a property cannot leave the claim
# behind. `fake` says the covering lane's environment is a modelled runtime rather
# than the real core -- recorded per row, never averaged away.
COVERED: dict[str, dict[str, object]] = {
    "FLAG_CARRY": {
        "lane": "rotate_bits_parity",
        "evidence": "build/tests/rotate_bits/rotate_bits_parity.c",
        "needle": "rotateBitsResetState(word_size, x_raw, x_base, y_raw, y_base, z_raw, z_base, carry_flag)",
        "fake": True,
        "why": (
            "Seeded as a case parameter and compared in the snapshot: 38 runCase rows,"
            " 32 with the flag clear and 6 with it set. The environment is"
            " rotate_bits_fake_runtime.c, so the register file is modelled -- but the"
            " flag itself is modelled as a bool that both the c43 oracle and the Zig"
            " owner read through getSystemFlag, so the discrimination on THIS property"
            " is real. It was listed OPEN here for a pass because this report reads"
            " one lane's fixtures and spoke as though it had read the tree."
        ),
    },
}

# Cannot be discriminated by any fixture over the CURRENT owner set, and the reason
# is a fact about the port. `evidence` must still name the site that blocks it, and
# `needle` says what to look for there -- the token itself is usually not the thing
# that proves the verdict.
BLOCKED: dict[str, dict[str, object]] = {}

# Owner-visible things that SHOULD be partitioned and are not. Distinct from
# REVIEWED, COVERED and BLOCKED on purpose: these are open findings with a reason to
# act, not decisions. The report prints them separately so a real gap cannot be
# retired by writing a plausible sentence beside it.
OPEN: dict[str, str] = {
    "isMatrixDiagonal": (
        "A matrix shape class the fixture set has no representative for. eigen.zig:845,"
        " reached only from calculateEigenvalues -- so it is behind M31-37's stop"
        " condition and eigen_parity's recorded tolerance survivor, not just a fixture."
    ),
    "isMatrixIndexed": (
        "A matrix shape class the fixture set has no representative for."
        " index_command.zig:18, and the INDEX register it reports on is set by"
        " fnIndexMatrix, which this lane's fixtures never call."
    ),
    "isRegisterMatrixFactors": (
        "A matrix shape class the fixture set has no representative for. prime.zig:919,"
        " the factor-list-as-matrix shape, which no fixture builds."
    ),
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


def lanes_referencing(repo: Path, tokens: set[str]) -> dict[str, set[str]]:
    """token -> the harness directories that mention it, excluding this lane's own.

    Deliberately crude: a mention is a PROMPT to classify, not a claim of coverage.
    A gate that decided coverage by grepping would replace one unexamined verdict
    with another; this only refuses to let a row say "nothing varies it" while
    another lane's source has the token in it.
    """
    hits: dict[str, set[str]] = {token: set() for token in tokens}
    files = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "build/tests/**/*.c", "build/tests/**/*.zig"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    own_lane = str(Path(HARNESS).parent)
    for rel in files:
        if rel.startswith(own_lane):
            continue
        text = (repo / rel).read_text(errors="replace")
        for token in tokens:
            # A bare `#define FLAG_X 0x...` in a harness c47.h is a constant copy, not
            # a case that varies it. Require the token somewhere other than a #define.
            if any(
                token in line and not line.lstrip().startswith("#define")
                for line in text.splitlines()
            ):
                hits[token].add(str(Path(rel).parent))
    return hits


def contradictions(
    open_rows: dict[str, str],
    covered: dict[str, dict[str, object]],
    blocked: dict[str, dict[str, object]],
    referencing: dict[str, set[str]],
    evidence_exists: dict[str, bool],
) -> list[str]:
    """Pure, so the self-test drives it with synthetic rows."""
    problems: list[str] = []
    for token in sorted(open_rows):
        lanes = referencing.get(token) or set()
        if lanes:
            problems.append(
                f"{token}: listed OPEN -- 'no fixture varies it' -- but "
                + ", ".join(sorted(lanes))
                + " references it. Classify it COVERED with the lane named, or say"
                " why the reference is not coverage."
            )
    for name, table in (("COVERED", covered), ("BLOCKED", blocked)):
        for token, row in sorted(table.items()):
            if not evidence_exists.get(token, False):
                problems.append(
                    f"{token}: {name} points at {row.get('evidence')!r} for"
                    f" {row.get('needle')!r}, which is not there any more. A verdict"
                    " outlives its evidence exactly once before it is folklore."
                )
    return problems


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--check", action="store_true", help="fail on self-contradicting rows")
    ap.add_argument("--self-test", action="store_true", help="prove --check fires")
    args = ap.parse_args()

    if args.self_test:
        if not contradictions(
            {"FLAG_X": "no fixture varies it"}, {}, {}, {"FLAG_X": {"a_lane"}}, {}
        ):
            print(
                "report-fixture-partition-gap: SELF-TEST FAILED -- an OPEN row that another lane covers passed"
            )
            return 1
        if not contradictions({}, {"FLAG_X": {"evidence": "gone.c"}}, {}, {}, {"FLAG_X": False}):
            print(
                "report-fixture-partition-gap: SELF-TEST FAILED -- a COVERED row with vanished evidence passed"
            )
            return 1
        if not contradictions({}, {}, {"FLAG_X": {"evidence": "gone.zig"}}, {}, {"FLAG_X": False}):
            print(
                "report-fixture-partition-gap: SELF-TEST FAILED -- a BLOCKED row with vanished evidence passed"
            )
            return 1
        if contradictions(
            {"FLAG_Y": "open"},
            {"FLAG_X": {"evidence": "here.c"}},
            {},
            {"FLAG_Y": set()},
            {"FLAG_X": True},
        ):
            print("report-fixture-partition-gap: SELF-TEST FAILED -- consistent rows were reported")
            return 1
        print(
            "report-fixture-partition-gap: SELF-TEST OK (an OPEN row another lane"
            " covers, and a verdict whose evidence is gone, both fire)"
        )
        return 0

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

    classified = set(REVIEWED) | set(OPEN) | set(COVERED) | set(BLOCKED)
    for kind in ("flags", "types", "predicates"):
        seen = found[kind]
        gap = sorted(t for t in seen if t not in covered and t not in classified)
        openrows = sorted(t for t in seen if t not in covered and t in OPEN)
        coveredrows = sorted(t for t in seen if t not in covered and t in COVERED)
        blockedrows = sorted(t for t in seen if t not in covered and t in BLOCKED)
        reviewed = sorted(t for t in seen if t not in covered and t in REVIEWED)
        print(f"\n  {kind}: {len(seen)} seen, {len(gap)} unpartitioned and unreviewed")
        for token in gap:
            print(f"      {token}")
        if openrows:
            print(f"    OPEN -- should be partitioned and is not ({len(openrows)}):")
            for token in openrows:
                print(f"      {token} -- {OPEN[token][:74]}")
        if coveredrows:
            print(f"    COVERED by another lane ({len(coveredrows)}):")
            for token in coveredrows:
                row = COVERED[token]
                mark = "COVERED-FAKE" if row.get("fake") else "COVERED"
                print(f"      {token} -- {mark} by {row['lane']}")
        if blockedrows:
            print(
                f"    BLOCKED -- no fixture over the current owners can discriminate ({len(blockedrows)}):"
            )
            for token in blockedrows:
                print(f"      {token} -- {str(BLOCKED[token]['why'])[:70]}")
        if reviewed:
            print(f"    reviewed and deliberately not partitioned ({len(reviewed)}):")
            for token in reviewed:
                print(f"      {token} -- {REVIEWED[token][:76]}")

    tracked_tokens = set(OPEN) | set(COVERED) | set(BLOCKED)
    referencing = lanes_referencing(repo, tracked_tokens)
    # The row says WHAT to look for, because the token itself is usually not the
    # thing that proves coverage: rotate_bits seeds a `carry_flag` parameter, and
    # what blocks FLAG_OVERFLOW is an `extern fn` declaration naming neither flag.
    evidence_exists = {
        token: (repo / str(row["evidence"])).is_file()
        and str(row["needle"]) in (repo / str(row["evidence"])).read_text(errors="replace")
        for table in (COVERED, BLOCKED)
        for token, row in table.items()
    }
    problems = contradictions(OPEN, COVERED, BLOCKED, referencing, evidence_exists)

    print(
        "\nThis is a REPORT. A non-empty list is the expected state: some of these are"
        "\ndisplay-only and some are unreachable from these wrappers. Each row wants a"
        "\nproperty in PARTITION_PROPERTIES, or a sentence in REVIEWED, or the lane that"
        "\ncovers it. Gating the GAP at zero would buy silence by adding fixtures for"
        "\nbranches nothing runs, which is this report's own failure mode inverted --"
        "\nso what --check gates is the bookkeeping, not the number."
    )

    if problems:
        print("\nROWS THAT CONTRADICT THEMSELVES:")
        for problem in problems:
            print(f"  {problem}")
        return 1 if args.check else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
