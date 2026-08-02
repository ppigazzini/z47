from __future__ import annotations

import glob
import json
import re
from pathlib import Path

STRING_RE = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
STRING_CONCAT_RE = re.compile(
    r'"(?:[^"\\]*(?:\\.[^"\\]*)*)"(?:\s*\+\+\s*"(?:[^"\\]*(?:\\.[^"\\]*)*)")+'
)
REPLACED_CORE_SOURCES_RE = re.compile(
    r"const\s+replaced_core_sources(?:_manifest)?\s*=\s*(?:\[_\]\[\]const u8\s*\{|@embedFile\()"
)
MANIFEST_EMBED_RE = re.compile(r'@embedFile\("([^"]*sources\.txt)"\)')
# Manifests whose entries are NOT first-party product C: replaced-core lists the
# upstream units Zig already owns (excluded from compilation), and parity-oracle
# lists test-lane oracle sources. Every other *sources.txt manifest feeds
# addCSourceFile in the product build graph and must be counted.
EXCLUDED_MANIFEST_MARKERS = ("replaced_core", "parity_oracle")


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalize_path(repo_root: Path, value: str) -> str:
    value = value.replace("\\\\", "/")
    value = value.strip()
    while value.startswith("./"):
        value = value[2:]

    if "/" not in value or not value.endswith(".c"):
        return value

    if (repo_root / value).exists():
        return value

    src_relative = Path("src") / value
    if (repo_root / src_relative).exists():
        return src_relative.as_posix()

    c47_relative = Path("src") / "c47" / value
    if (repo_root / c47_relative).exists():
        return c47_relative.as_posix()

    return value


def manifest_c_entries(repo_root: Path, manifest_path: Path) -> set[str]:
    """Read a build source manifest and return its existing first-party .c entries."""
    found: set[str] = set()
    if not manifest_path.is_file():
        return found
    for raw_line in manifest_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or not line.endswith(".c"):
            continue
        entry = normalize_path(repo_root, line)
        if (repo_root / entry).is_file():
            found.add(entry)
    return found


def candidate_literals_from_file(repo_root: Path, path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    found: set[str] = set()

    in_replaced_core_sources = False

    for raw_line in text.splitlines():
        if not in_replaced_core_sources and REPLACED_CORE_SOURCES_RE.search(raw_line):
            in_replaced_core_sources = True
        if in_replaced_core_sources:
            if ");" in raw_line or "};" in raw_line:
                in_replaced_core_sources = False
            continue

        if "addCopyFileToSource(" in raw_line:
            continue

        for embed in MANIFEST_EMBED_RE.finditer(raw_line):
            manifest_name = embed.group(1)
            if any(marker in manifest_name for marker in EXCLUDED_MANIFEST_MARKERS):
                continue
            found.update(manifest_c_entries(repo_root, path.parent / manifest_name))

        for chain in STRING_CONCAT_RE.finditer(raw_line):
            literal = normalize_path(repo_root, "".join(STRING_RE.findall(chain.group(0))))
            if "/" not in literal or not literal.endswith(".c"):
                continue
            found.add(literal)

        for match in STRING_RE.finditer(raw_line):
            literal = normalize_path(repo_root, match.group(1))
            if "/" not in literal or not literal.endswith(".c"):
                continue
            found.add(literal)

    return found


def classify_entry(entry: str, cfg: dict) -> str:
    external = tuple(cfg.get("allowed_external_prefixes", []))
    first_party = tuple(cfg.get("first_party_prefixes", []))
    generated = tuple(cfg.get("generated_prefixes", []))
    ignored = tuple(cfg.get("ignored_prefixes", []))

    if entry.startswith(ignored):
        return "ignored"
    if entry.startswith(external):
        return "external"
    if entry.startswith(first_party):
        return "first-party"
    if entry.startswith(generated):
        return "generated"
    if entry.endswith(".c"):
        return "first-party"
    return "other"


def resolve_scan_files(repo_root: Path, cfg: dict) -> list[Path]:
    files: list[Path] = []
    for pattern in cfg.get("scan_globs", []):
        full_pattern = str(repo_root / pattern)
        for match in glob.glob(full_pattern, recursive=True):
            path = Path(match)
            if path.is_file():
                files.append(path)
    return sorted(set(files))


def classify_entries(entries: set[str], cfg: dict) -> dict[str, set[str]]:
    classified: dict[str, set[str]] = {
        "external": set(),
        "first-party": set(),
        "generated": set(),
        "ignored": set(),
        "other": set(),
    }
    for entry in entries:
        classified[classify_entry(entry, cfg)].add(entry)
    return classified


def scan_classified_entries(repo_root: Path, cfg: dict) -> tuple[list[Path], dict[str, set[str]]]:
    scan_files = resolve_scan_files(repo_root, cfg)
    entries: set[str] = set()
    for path in scan_files:
        entries.update(candidate_literals_from_file(repo_root, path))
    return scan_files, classify_entries(entries, cfg)


def load_baseline(path: Path) -> set[str]:
    if not path.exists():
        return set()
    entries: set[str] = set()
    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        entries.add(line)
    return entries


def write_baseline(path: Path, entries: set[str]) -> None:
    lines = [
        "# First-party C dependency baseline entries (Phase A)",
        "# Auto-generated by .github/project/check-c-dependency-allowlist.py --update-baseline",
        "",
    ]
    lines.extend(sorted(entries))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def nonblank_line_count(repo_root: Path, entry: str) -> int:
    path = repo_root / entry
    if not path.exists() or not path.is_file():
        return 0
    return sum(
        1 for line in path.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip()
    )
