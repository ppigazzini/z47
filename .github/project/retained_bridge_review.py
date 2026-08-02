from __future__ import annotations

from pathlib import Path

EXPECTED_HEADER = (
    "bridge_path",
    "local_owner",
    "parity_target",
    "status",
    "notes",
)

ALLOWED_STATUSES = {
    "convert-now",
    "keep-temporarily",
    "blocked-by-larger-parity-boundary",
}


def load_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise ValueError(f"missing retained bridge review ledger: {path}")

    header_seen = False
    rows: list[dict[str, str]] = []

    with path.open("r", encoding="utf-8") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\n")
            if not line or line.startswith("#"):
                continue

            fields = line.split("\t")
            if not header_seen:
                if tuple(fields) != EXPECTED_HEADER:
                    raise ValueError(
                        f"{path}:{line_number} has an unexpected header; expected tabs for {' '.join(EXPECTED_HEADER)}"
                    )
                header_seen = True
                continue

            if len(fields) != len(EXPECTED_HEADER):
                raise ValueError(
                    f"{path}:{line_number} expected {len(EXPECTED_HEADER)} tab-separated columns, found {len(fields)}"
                )

            row = dict(zip(EXPECTED_HEADER, fields, strict=True))
            for column in EXPECTED_HEADER:
                if not row[column]:
                    raise ValueError(f"{path}:{line_number} has an empty {column} field")

            if row["status"] not in ALLOWED_STATUSES:
                allowed = ", ".join(sorted(ALLOWED_STATUSES))
                raise ValueError(
                    f"{path}:{line_number} has invalid status {row['status']!r}; expected one of: {allowed}"
                )

            rows.append(row)

    if not header_seen:
        raise ValueError(f"{path} is missing the tab-separated header row")

    return rows


def status_counts(rows: list[dict[str, str]]) -> dict[str, int]:
    counts = {status: 0 for status in sorted(ALLOWED_STATUSES)}
    for row in rows:
        counts[row["status"]] += 1
    return counts
