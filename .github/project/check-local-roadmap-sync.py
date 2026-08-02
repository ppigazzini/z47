#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

EXPECTED_COLUMNS = ("ID", "Name", "Target state", "Current status")
HEADER_LINE = "| " + " | ".join(EXPECTED_COLUMNS) + " |"
SEPARATOR_RE = re.compile(r"^\|\s*-+\s*\|\s*-+\s*\|\s*-+\s*\|\s*-+\s*\|\s*$")
MILESTONE_ID_RE = re.compile(r"^M\d+$")
SUMMARY_HEADING = "Milestone Summary"
FOLLOW_ON_HEADING = "Follow-On Milestones"


@dataclass(frozen=True)
class TableOccurrence:
    heading: str
    line_number: int
    rows: list[dict[str, str]]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate that the repeated milestone-summary surfaces in a local "
            "roadmap markdown file stay synchronized."
        )
    )
    parser.add_argument(
        "--roadmap",
        required=True,
        help="markdown roadmap file to validate",
    )
    return parser.parse_args()


def parse_table_row(path: Path, line_number: int, raw_line: str) -> dict[str, str]:
    parts = [part.strip() for part in raw_line.strip().strip("|").split("|")]
    if len(parts) != len(EXPECTED_COLUMNS):
        raise ValueError(
            f"{path}:{line_number} expected {len(EXPECTED_COLUMNS)} columns in milestone table row, "
            f"found {len(parts)}"
        )

    row = dict(zip(EXPECTED_COLUMNS, parts, strict=True))
    milestone_id = row["ID"]
    if not MILESTONE_ID_RE.fullmatch(milestone_id):
        raise ValueError(
            f"{path}:{line_number} has invalid milestone ID {milestone_id!r}; expected M<number>"
        )

    for column_name, value in row.items():
        if not value:
            raise ValueError(f"{path}:{line_number} has empty {column_name!r} field")

    return row


def load_summary_tables(path: Path) -> list[TableOccurrence]:
    if not path.exists():
        raise ValueError(f"missing roadmap file: {path}")

    lines = path.read_text(encoding="utf-8").splitlines()
    heading = ""
    tables: list[TableOccurrence] = []
    line_index = 0

    while line_index < len(lines):
        line = lines[line_index]
        stripped = line.strip()

        if stripped.startswith("#"):
            heading = stripped.lstrip("#").strip()
            line_index += 1
            continue

        if stripped != HEADER_LINE:
            line_index += 1
            continue

        header_line_number = line_index + 1
        separator_index = line_index + 1
        if separator_index >= len(lines) or not SEPARATOR_RE.match(lines[separator_index].strip()):
            raise ValueError(
                f"{path}:{header_line_number} milestone table header is not followed by a markdown separator row"
            )

        row_index = separator_index + 1
        rows: list[dict[str, str]] = []
        seen_ids: set[str] = set()

        while row_index < len(lines) and lines[row_index].lstrip().startswith("|"):
            row = parse_table_row(path, row_index + 1, lines[row_index])
            milestone_id = row["ID"]
            if milestone_id in seen_ids:
                raise ValueError(
                    f"{path}:{row_index + 1} duplicates milestone ID {milestone_id!r} within the same table"
                )
            seen_ids.add(milestone_id)
            rows.append(row)
            row_index += 1

        if not rows:
            raise ValueError(f"{path}:{header_line_number} milestone table has no data rows")

        tables.append(TableOccurrence(heading=heading, line_number=header_line_number, rows=rows))
        line_index = row_index

    return tables


def keyed_rows(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    return {row["ID"]: row for row in rows}


def validate_tables(path: Path, tables: list[TableOccurrence]) -> tuple[int, int]:
    summary_tables = [table for table in tables if table.heading == SUMMARY_HEADING]
    if len(summary_tables) != 1:
        raise ValueError(
            f"{path} must contain exactly one '{SUMMARY_HEADING}' table; found {len(summary_tables)}"
        )

    follow_on_tables = [table for table in tables if table.heading == FOLLOW_ON_HEADING]
    if not follow_on_tables:
        raise ValueError(f"{path} must contain at least one '{FOLLOW_ON_HEADING}' table")

    summary_rows = keyed_rows(summary_tables[0].rows)

    for table in follow_on_tables:
        for row in table.rows:
            milestone_id = row["ID"]
            summary_row = summary_rows.get(milestone_id)
            if summary_row is None:
                raise ValueError(
                    f"{path}:{table.line_number} includes milestone {milestone_id!r} in '{FOLLOW_ON_HEADING}' "
                    f"but that ID is missing from '{SUMMARY_HEADING}'"
                )

            for column in EXPECTED_COLUMNS[1:]:
                if row[column] != summary_row[column]:
                    raise ValueError(
                        f"{path}:{table.line_number} has drift for milestone {milestone_id!r} column {column!r}: "
                        f"follow-on value {row[column]!r} does not match summary value {summary_row[column]!r}"
                    )

    return len(summary_rows), len(follow_on_tables)


def main() -> int:
    args = parse_args()
    roadmap_path = Path(args.roadmap).resolve()

    try:
        tables = load_summary_tables(roadmap_path)
        milestone_count, follow_on_count = validate_tables(roadmap_path, tables)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(
        f"PASS: {roadmap_path} keeps {milestone_count} milestone rows synchronized across "
        f"1 summary table and {follow_on_count} follow-on table(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
