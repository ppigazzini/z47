#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

MILESTONE_HEADING_RE = re.compile(r"^##\s+Milestone\s+M\d+\s+Closure:\s+.+$")
SUBHEADING_RE = re.compile(r"^###\s+(.+?)\s*$")
TOP_HEADING_RE = re.compile(r"^##\s+")
BULLET_RE = re.compile(r"^\s*-\s+\S")
NUMBERED_RE = re.compile(r"^\s*\d+\.\s+\S")
TEXT_RE = re.compile(r"\S")

REQUIRED_SUBHEADINGS = (
    "Work-Type Breakdown",
    "Boundary Cost Delta",
    "Semantic Gain Delta",
    "Failure Ledger",
)


@dataclass(frozen=True)
class SectionWindow:
    title: str
    start: int
    end: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate that each milestone closure section in an iteration report "
            "contains the mandatory governance subsections and non-empty content."
        )
    )
    parser.add_argument(
        "--report",
        action="append",
        required=True,
        help="Path to a report markdown file. Repeat --report for multiple files.",
    )
    return parser.parse_args()


def normalize_heading(text: str) -> str:
    # Many sections include a milestone suffix, e.g. "Work-Type Breakdown (M8)".
    return re.sub(r"\s*\([^)]*\)\s*$", "", text.strip())


def find_milestone_windows(lines: list[str]) -> list[SectionWindow]:
    starts: list[tuple[int, str]] = []

    for idx, line in enumerate(lines):
        if MILESTONE_HEADING_RE.match(line):
            starts.append((idx, line.strip()))

    windows: list[SectionWindow] = []
    for i, (start_idx, title) in enumerate(starts):
        end_idx = starts[i + 1][0] if i + 1 < len(starts) else len(lines)
        windows.append(SectionWindow(title=title, start=start_idx, end=end_idx))

    return windows


def extract_subsections(lines: list[str], window: SectionWindow) -> dict[str, tuple[int, int]]:
    subsection_indices: list[tuple[str, int]] = []

    for idx in range(window.start + 1, window.end):
        match = SUBHEADING_RE.match(lines[idx])
        if match:
            raw_title = match.group(1)
            subsection_indices.append((normalize_heading(raw_title), idx))

    ranges: dict[str, tuple[int, int]] = {}
    for i, (title, start_idx) in enumerate(subsection_indices):
        end_idx = subsection_indices[i + 1][1] if i + 1 < len(subsection_indices) else window.end
        ranges[title] = (start_idx, end_idx)

    return ranges


def has_measured_content(lines: list[str], start: int, end: int) -> bool:
    saw_text = False
    for idx in range(start + 1, end):
        line = lines[idx]
        if SUBHEADING_RE.match(line) or TOP_HEADING_RE.match(line):
            break

        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("```"):
            saw_text = True
            continue
        if BULLET_RE.match(line) or NUMBERED_RE.match(line):
            return True
        if TEXT_RE.search(stripped):
            saw_text = True

    return saw_text


def validate_report(path: Path) -> list[str]:
    if not path.exists():
        return [f"{path}: missing report file"]

    lines = path.read_text(encoding="utf-8").splitlines()
    windows = find_milestone_windows(lines)
    if not windows:
        return [f"{path}: no milestone closure sections found"]

    errors: list[str] = []

    for window in windows:
        subsections = extract_subsections(lines, window)

        for required in REQUIRED_SUBHEADINGS:
            if required not in subsections:
                errors.append(f"{path}: {window.title} missing subsection '### {required}'")
                continue

            start, end = subsections[required]
            if not has_measured_content(lines, start, end):
                line_no = start + 1
                errors.append(
                    f"{path}:{line_no} subsection '### {required}' has no measurable content"
                )

    return errors


def main() -> int:
    args = parse_args()

    all_errors: list[str] = []
    for report in args.report:
        all_errors.extend(validate_report(Path(report).resolve()))

    if all_errors:
        for message in all_errors:
            print(f"ERROR: {message}", file=sys.stderr)
        return 1

    print(
        f"PASS: validated mandatory report governance sections across {len(args.report)} report file(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
