#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


PIN_PATH = ".github/project/upstream-pin.env"
LEDGER_PATH = ".github/project/upstream-port-ledger.tsv"
TRACKED_PATHS = (PIN_PATH, LEDGER_PATH)
EXPECTED_HEADER = (
    "upstream_commit",
    "upstream_subject",
    "surface",
    "kind",
    "local_owner",
    "parity_target",
    "status",
    "notes",
)
ALLOWED_STATUSES = {
    "pin-only",
    "no-op-for-z47",
    "ported-to-zig",
    "ported-to-build-overlay",
    "retained-c-boundary",
    "deferred",
    "blocked",
}
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate the tracked upstream port ledger and optionally require "
            "a ledger update when the upstream pin changes."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="repository root to validate (default: current directory)",
    )
    parser.add_argument(
        "--diff-base",
        help=(
            "git revision to diff against HEAD; when provided, a change to "
            f"{PIN_PATH} must also change {LEDGER_PATH}"
        ),
    )
    return parser.parse_args()


def load_upstream_commit(pin_path: Path) -> str:
    if not pin_path.exists():
        raise ValueError(f"missing upstream pin file: {PIN_PATH}")

    for raw_line in pin_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key == "UPSTREAM_COMMIT":
            commit = value.strip()
            if not COMMIT_RE.fullmatch(commit):
                raise ValueError(
                    f"{PIN_PATH} contains an invalid UPSTREAM_COMMIT value: {commit!r}"
                )
            return commit

    raise ValueError(f"{PIN_PATH} does not define UPSTREAM_COMMIT")


def load_ledger_rows(ledger_path: Path) -> list[dict[str, str]]:
    if not ledger_path.exists():
        raise ValueError(f"missing upstream port ledger: {LEDGER_PATH}")

    header_seen = False
    rows: list[dict[str, str]] = []

    with ledger_path.open("r", encoding="utf-8") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\n")
            if not line or line.startswith("#"):
                continue

            fields = line.split("\t")
            if not header_seen:
                if tuple(fields) != EXPECTED_HEADER:
                    raise ValueError(
                        f"{LEDGER_PATH}:{line_number} has an unexpected header; "
                        f"expected tabs for {' '.join(EXPECTED_HEADER)}"
                    )
                header_seen = True
                continue

            if len(fields) != len(EXPECTED_HEADER):
                raise ValueError(
                    f"{LEDGER_PATH}:{line_number} expected {len(EXPECTED_HEADER)} "
                    f"tab-separated columns, found {len(fields)}"
                )

            row = dict(zip(EXPECTED_HEADER, fields))
            if not COMMIT_RE.fullmatch(row["upstream_commit"]):
                raise ValueError(
                    f"{LEDGER_PATH}:{line_number} has an invalid upstream_commit "
                    f"value: {row['upstream_commit']!r}"
                )

            for column in EXPECTED_HEADER[:-1]:
                if not row[column]:
                    raise ValueError(
                        f"{LEDGER_PATH}:{line_number} has an empty {column} field"
                    )

            if row["status"] not in ALLOWED_STATUSES:
                allowed = ", ".join(sorted(ALLOWED_STATUSES))
                raise ValueError(
                    f"{LEDGER_PATH}:{line_number} has invalid status {row['status']!r}; "
                    f"expected one of: {allowed}"
                )

            rows.append(row)

    if not header_seen:
        raise ValueError(f"{LEDGER_PATH} is missing the tab-separated header row")
    if not rows:
        raise ValueError(f"{LEDGER_PATH} must contain at least one tracked row")

    return rows


def validate_pinned_commit_row(rows: list[dict[str, str]], pinned_commit: str) -> None:
    pin_rows = [
        row
        for row in rows
        if row["upstream_commit"] == pinned_commit and row["status"] == "pin-only"
    ]
    if len(pin_rows) != 1:
        raise ValueError(
            f"{LEDGER_PATH} must contain exactly one pin-only row for pinned commit "
            f"{pinned_commit}; found {len(pin_rows)}"
        )


def git_output(repo_root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        stderr = result.stderr.strip()
        stdout = result.stdout.strip()
        detail = stderr or stdout or f"git {' '.join(args)} failed"
        raise ValueError(detail)
    return result.stdout


def validate_branch_diff(repo_root: Path, diff_base: str) -> set[str]:
    changed_paths = {
        line.strip()
        for line in git_output(
            repo_root,
            "diff",
            "--name-only",
            diff_base,
            "HEAD",
            "--",
            *TRACKED_PATHS,
        ).splitlines()
        if line.strip()
    }

    if PIN_PATH in changed_paths and LEDGER_PATH not in changed_paths:
        raise ValueError(
            f"{PIN_PATH} changed since {diff_base} but {LEDGER_PATH} did not"
        )

    return changed_paths


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    try:
        pinned_commit = load_upstream_commit(repo_root / PIN_PATH)
        rows = load_ledger_rows(repo_root / LEDGER_PATH)
        validate_pinned_commit_row(rows, pinned_commit)

        changed_paths: set[str] = set()
        if args.diff_base:
            changed_paths = validate_branch_diff(repo_root, args.diff_base)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"PASS: upstream port ledger records pinned commit {pinned_commit}.")
    if args.diff_base:
        if changed_paths:
            print(
                "PASS: diff-base check inspected tracked changes in "
                + ", ".join(sorted(changed_paths))
                + "."
            )
        else:
            print("PASS: diff-base check saw no upstream-pin or ledger changes.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())