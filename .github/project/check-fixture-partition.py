#!/usr/bin/env python3
"""A fixture table partitions the input space. Check WHICH properties it partitions.

WHY THIS EXISTS. The full-core differential runs every wrapper against every
register shape, and its own comment argues the case correctly: *"a fixture that
only ever presents one cannot tell a working discriminator from a constant."*
That reasoning was applied to exactly one property.

The shape table enumerated DATA TYPES exhaustively -- real, complex, both integer
kinds, string, both matrix kinds, time -- because somebody sat down and listed the
types. It contained no negative value at all: 1234, 42, 43, +90 degrees,
0xDEADBEEF with sign 0, +123456789012345678901234567890. `src/core/numeric/`
branches on sign at 265 sites across 52 files, and X was never negative in any case
the lane ran.

That was not a theory. Deleting the negative-infinity sign handling from
`arctanReal`, so `arctan(-inf)` answers +90 degrees instead of -90, left every case
in the lane agreeing.

Type was partitioned exhaustively; sign was not partitioned at all. The difference
was not care or effort -- it was that nothing wrote down the LIST of properties the
fixtures were supposed to discriminate, so there was nothing to be incomplete
against. This gate is that list, made checkable.

WHAT IT CHECKS. Two directions, and the second is the one that keeps the list
honest:

  * every declared (property, class) has a fixture -- a class nobody can reach is
    a branch nobody tests;
  * every fixture belongs to at least one class -- so a new shape cannot arrive
    without somebody saying what it is a representative OF. That is the direction
    that would have caught the sign gap, because it forces the question "which
    property is this a class of?" every time the table grows.

AND THE BINARY TABLE, WHICH IT USED TO IGNORE. The first version of this gate
parsed `FIXTURES` and contained no reference to `PAIRS` at all -- so it enforced a
property list over the 58 unary wrappers and said nothing whatever about the 28
binary ones, which include the four arithmetic dispatchers. Measured at that
point: 22 of 34 shapes never appeared as the X operand of any binary case,
including every negative one. Extending the pair table found a live defect
immediately (a long integer's sign tag read as an angular mode).

So the gate now requires every class to appear at least once in the X position of
`PAIRS`, and reports how many appear in Y. A gate is exactly as complete as the
list it enforces, OVER EXACTLY THE TABLE IT PARSES, and this one had two bounds
while admitting to one.

WHAT IT DOES NOT CHECK. That the property list is complete. Nothing can: the set
of properties a program branches on is not derivable from a fixture table. What it
does is make the list explicit, so an incomplete one is an argument somebody can
have rather than a silence nobody notices. That sentence is a statement of what
somebody still owes, not a discharge of it.

Usage:
  check-fixture-partition.py [--repo-root .]
  check-fixture-partition.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

HARNESS = "build/tests/math_wrappers_full_core/math_wrappers_full_core_parity_harness.c"

FIXTURES_RE = re.compile(r"static const fixture_t FIXTURES\[\] = \{(.*?)\n\};", re.S)
FIXTURE_ROW_RE = re.compile(r'\{\s*"([\w]+)"\s*,')
PARTITION_RE = re.compile(
    r"static const partitionClass_t PARTITION_PROPERTIES\[\] = \{(.*?)\n\};", re.S
)
PARTITION_ROW_RE = re.compile(r'\{\s*"([\w]+)"\s*,\s*"([\w]+)"\s*,\s*"([\w]+)"\s*\}')
PAIRS_RE = re.compile(r"static const pair_t PAIRS\[\] = \{(.*?)\n\};", re.S)
PAIRS_ROW_RE = re.compile(r'\{\s*"[^"]+"\s*,\s*(\w+)\s*,\s*(\w+)\s*\}')
FIXTURE_SEED_RE = re.compile(r'\{\s*"([\w]+)"\s*,\s*(\w+)\s*\}')

# Classes whose fixture cannot be the X operand of a binary case, with the reason.
# Empty: every shape the harness can build has been placed in the X position.
PAIR_X_EXEMPT: dict[str, str] = {}

# A fixture may belong to no class only with a reason. Empty on purpose: every
# shape in the table is a representative of something, and if one is not, saying
# which nothing it represents is the useful sentence.
UNCLASSIFIED: dict[str, str] = {}


def parse(repo: Path):
    """(fixture names, partition rows, fixture->seed, X seeds in PAIRS, Y seeds)."""
    text = (repo / HARNESS).read_text(encoding="utf-8")
    fixtures_block = FIXTURES_RE.search(text)
    partition_block = PARTITION_RE.search(text)
    pairs_block = PAIRS_RE.search(text)
    if not fixtures_block:
        raise RuntimeError("FIXTURES table not found")
    if not partition_block:
        raise RuntimeError("PARTITION_PROPERTIES table not found")
    if not pairs_block:
        raise RuntimeError("PAIRS table not found")
    fixtures = FIXTURE_ROW_RE.findall(fixtures_block.group(1))
    rows = PARTITION_ROW_RE.findall(partition_block.group(1))
    seed_of = dict(FIXTURE_SEED_RE.findall(fixtures_block.group(1)))
    pair_rows = PAIRS_ROW_RE.findall(pairs_block.group(1))
    return fixtures, rows, seed_of, {x for x, _ in pair_rows}, {y for _, y in pair_rows}


def pair_problems(
    rows: list[tuple[str, str, str]],
    seed_of: dict[str, str],
    pair_x: set[str],
) -> list[str]:
    """Every class must have a representative in the X operand of a binary case.

    The X position is the one that mattered: it was the position 22 of 34 shapes
    never occupied, and the position whose missing negative long integer hid a
    live defect.
    """
    found: list[str] = []
    for prop, class_name, fixture in rows:
        if fixture in PAIR_X_EXEMPT:
            continue
        seed = seed_of.get(fixture)
        if seed is None or seed in pair_x:
            continue
        found.append(
            f"class {prop}/{class_name} (fixture `{fixture}`) never appears as the X"
            f" operand of a binary case.\n"
            f"    The binary wrappers include the four arithmetic dispatchers. A class"
            f" that only\n"
            f"    ever appears in the unary table is unpartitioned for every one of them."
        )
    return found


def problems_for(fixtures: list[str], rows: list[tuple[str, str, str]]) -> list[str]:
    found: list[str] = []
    named = {fixture for _, _, fixture in rows}

    for prop, class_name, fixture in rows:
        if fixture not in fixtures:
            found.append(
                f"property {prop}/{class_name} names fixture `{fixture}`, which is not in FIXTURES"
            )

    for fixture in fixtures:
        if fixture in named or fixture in UNCLASSIFIED:
            continue
        found.append(
            f"fixture `{fixture}` is a representative of nothing.\n"
            f"    Add it to PARTITION_PROPERTIES under the property it is a class of, or\n"
            f"    to UNCLASSIFIED in this file with the sentence saying why it stands alone.\n"
            f"    This is the direction that catches a missing partition: a shape nobody\n"
            f"    classified is a shape nobody asked the property question about."
        )
    return found


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    try:
        fixtures, rows, seed_of, pair_x, pair_y = parse(repo)
    except (RuntimeError, OSError) as exc:
        print(f"check-fixture-partition: BROKEN -- {exc}")
        return 1

    properties: dict[str, set[str]] = {}
    for prop, class_name, _ in rows:
        properties.setdefault(prop, set()).add(class_name)

    classes_in_x = sum(1 for _, _, f in rows if seed_of.get(f) in pair_x)
    print(
        f"check-fixture-partition: {len(fixtures)} fixture(s),"
        f" {len(properties)} partitioned propert(ies),"
        f" {len(rows)} (property, class) pair(s)"
    )
    # The Y operand is seeded by its own `second*` family, which sets Y and Z
    # together, so a fixture seed never appears there and a "classes in Y" fraction
    # over the same rows would always read zero. Report the count and leave the
    # fraction to the X position, which is the one that hid a defect.
    print(
        f"    binary table: {classes_in_x}/{len(rows)} classes in the X operand,"
        f" {len(pair_x)} distinct X seed(s), {len(pair_y)} distinct Y seed(s)"
    )
    for prop in sorted(properties):
        print(f"    {prop:14s} {len(properties[prop])} class(es)")

    if args.self_test:
        # Both directions, through the same checker a real run uses.
        missing_fixture = problems_for(fixtures, [*rows, ("probe", "probeClass", "noSuchFixture")])
        if not any("noSuchFixture" in p for p in missing_fixture):
            print("check-fixture-partition: SELF-TEST FAILED -- a class naming no fixture passed")
            return 1
        unclassified = problems_for([*fixtures, "seedProbeUnclassified"], rows)
        if not any("seedProbeUnclassified" in p for p in unclassified):
            print("check-fixture-partition: SELF-TEST FAILED -- an unclassified fixture passed")
            return 1
        # And the binary direction: drop one class's seed from the X position.
        victim = next((f for _, _, f in rows if seed_of.get(f) in pair_x), None)
        if victim is None:
            print("check-fixture-partition: SELF-TEST BROKEN -- no class is in the X position")
            return 1
        thinned = pair_x - {seed_of[victim]}
        if not any(victim in p for p in pair_problems(rows, seed_of, thinned)):
            print(
                "check-fixture-partition: SELF-TEST FAILED -- a class missing from the X"
                " operand passed"
            )
            return 1
        print(
            "check-fixture-partition: SELF-TEST OK"
            " (a class with no fixture, a fixture with no class, and a class missing"
            " from the binary X operand all fire)"
        )

    found = problems_for(fixtures, rows) + pair_problems(rows, seed_of, pair_x)
    if found:
        print("\nFIXTURE PARTITION INCOMPLETE:")
        for problem in found:
            print(f"  {problem}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
