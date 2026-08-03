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

WHAT IT DOES NOT CHECK. That the property list is complete. Nothing can: the set
of properties a program branches on is not derivable from a fixture table. What it
does is make the list explicit, so an incomplete one is an argument somebody can
have rather than a silence nobody notices.

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

# A fixture may belong to no class only with a reason. Empty on purpose: every
# shape in the table is a representative of something, and if one is not, saying
# which nothing it represents is the useful sentence.
UNCLASSIFIED: dict[str, str] = {}


def parse(repo: Path) -> tuple[list[str], list[tuple[str, str, str]]]:
    text = (repo / HARNESS).read_text(encoding="utf-8")
    fixtures_block = FIXTURES_RE.search(text)
    partition_block = PARTITION_RE.search(text)
    if not fixtures_block:
        raise RuntimeError("FIXTURES table not found")
    if not partition_block:
        raise RuntimeError("PARTITION_PROPERTIES table not found")
    fixtures = FIXTURE_ROW_RE.findall(fixtures_block.group(1))
    rows = PARTITION_ROW_RE.findall(partition_block.group(1))
    return fixtures, rows


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
        fixtures, rows = parse(repo)
    except (RuntimeError, OSError) as exc:
        print(f"check-fixture-partition: BROKEN -- {exc}")
        return 1

    properties: dict[str, set[str]] = {}
    for prop, class_name, _ in rows:
        properties.setdefault(prop, set()).add(class_name)

    print(
        f"check-fixture-partition: {len(fixtures)} fixture(s),"
        f" {len(properties)} partitioned propert(ies),"
        f" {len(rows)} (property, class) pair(s)"
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
        print(
            "check-fixture-partition: SELF-TEST OK"
            " (a class with no fixture and a fixture with no class both fire)"
        )

    found = problems_for(fixtures, rows)
    if found:
        print("\nFIXTURE PARTITION INCOMPLETE:")
        for problem in found:
            print(f"  {problem}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
