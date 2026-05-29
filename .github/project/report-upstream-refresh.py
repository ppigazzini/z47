#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
import re


PIN_PATH = ".github/project/upstream-pin.env"
TEXT_EXTENSIONS = {
    ".c",
    ".cfg",
    ".env",
    ".h",
    ".md",
    ".py",
    ".sh",
    ".txt",
    ".yaml",
    ".yml",
    ".zig",
}
ROOT_TEXT_FILES = {"build.zig", "CONTRIBUTING.md", "ZIG-README.md"}
NORMALIZED_IMPORT_PREFIXES = (
    "src/",
    "dep/",
    "docs/",
    "res/",
    "LIBRARY/",
    "PROGRAMS/",
    "subprojects/",
    "tools/",
)
INLINE_REPLACED_SOURCES_RE = re.compile(
    r"const\s+replaced_core_sources\s*=\s*\[_\]\[\]const u8\s*\{"
)
STRING_LITERAL_RE = re.compile(r'"([^"\\]+)"')
RUNTIME_ZIG_CLASS = "runtime-zig"
BUILD_TOOL_ZIG_CLASS = "build-tool-zig"
BUILD_LOGIC_CLASS = "build-logic"
BUILD_MANIFEST_CLASS = "build-manifest"
RETAINED_C_CLASS = "retained-c-wrapper"
WORKFLOW_DOC_CLASS = "workflow-or-doc"


def add_touchpoint(
    mapping: dict[str, dict[str, set[str]]],
    changed_path: str,
    touchpoint_path: str,
    reason: str,
) -> None:
    mapping.setdefault(changed_path, {}).setdefault(touchpoint_path, set()).add(reason)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize new upstream commits, changed imported paths, and likely "
            "z47-owned touchpoints for an upstream refresh."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="repository root to inspect (default: current directory)",
    )
    parser.add_argument(
        "--fetch",
        action="store_true",
        help="fetch the pinned upstream branch before diffing",
    )
    parser.add_argument(
        "--base-rev",
        help="base revision to compare from (default: pinned upstream commit)",
    )
    parser.add_argument(
        "--head-rev",
        help=(
            "head revision to compare to (default: FETCH_HEAD after --fetch, "
            "otherwise pinned remote branch)"
        ),
    )
    parser.add_argument(
        "--max-commits",
        type=int,
        default=200,
        help="maximum number of new upstream commits to print; 0 prints all",
    )
    parser.add_argument(
        "--max-paths",
        type=int,
        default=200,
        help="maximum number of changed imported paths to print; 0 prints all",
    )
    return parser.parse_args()


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


def load_pin_env(pin_path: Path) -> dict[str, str]:
    if not pin_path.exists():
        raise ValueError(f"missing upstream pin file: {PIN_PATH}")

    values: dict[str, str] = {}
    for raw_line in pin_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()

    required = (
        "UPSTREAM_COMMIT",
        "UPSTREAM_REPOSITORY_URL",
        "UPSTREAM_BRANCH",
    )
    missing = [key for key in required if not values.get(key)]
    if missing:
        raise ValueError(
            f"{PIN_PATH} is missing required key(s): {', '.join(missing)}"
        )
    return values


def fetch_upstream(repo_root: Path, pin_values: dict[str, str]) -> None:
    git_output(
        repo_root,
        "fetch",
        "--prune",
        "--no-tags",
        pin_values["UPSTREAM_REPOSITORY_URL"],
        pin_values["UPSTREAM_BRANCH"],
    )


def resolve_revision(repo_root: Path, rev: str) -> str:
    return git_output(repo_root, "rev-parse", f"{rev}^{{commit}}") .strip()


def resolve_default_head(repo_root: Path, pin_values: dict[str, str], fetched: bool) -> str:
    if fetched:
        return "FETCH_HEAD"

    branch = pin_values["UPSTREAM_BRANCH"]
    remote_name = pin_values.get("UPSTREAM_REMOTE_NAME")
    candidates = []
    if remote_name:
        candidates.append(f"{remote_name}/{branch}")
    candidates.append(branch)

    for candidate in candidates:
        try:
            resolve_revision(repo_root, candidate)
            return candidate
        except ValueError:
            continue

    raise ValueError(
        "unable to resolve a comparison head; pass --head-rev explicitly or use --fetch"
    )


def normalize_imported_path(raw_value: str) -> str | None:
    value = raw_value.strip()
    if not value or value.startswith("#"):
        return None
    if value.startswith(NORMALIZED_IMPORT_PREFIXES):
        return value
    return f"src/c47/{value}"


def collect_manifest_touchpoints(repo_root: Path) -> dict[str, dict[str, set[str]]]:
    mapping: dict[str, dict[str, set[str]]] = {}
    zig_build_root = repo_root / "zig_build"

    for manifest_path in zig_build_root.rglob("*replaced_core_sources.txt"):
        rel_path = manifest_path.relative_to(repo_root).as_posix()
        for raw_line in manifest_path.read_text(encoding="utf-8").splitlines():
            source = normalize_imported_path(raw_line)
            if source is not None:
                add_touchpoint(mapping, source, rel_path, "manifest")

    for zig_path in zig_build_root.rglob("*.zig"):
        rel_path = zig_path.relative_to(repo_root).as_posix()
        in_replaced_sources = False
        for raw_line in zig_path.read_text(encoding="utf-8").splitlines():
            if not in_replaced_sources:
                if INLINE_REPLACED_SOURCES_RE.search(raw_line):
                    in_replaced_sources = True
                continue

            for match in STRING_LITERAL_RE.finditer(raw_line):
                source = normalize_imported_path(match.group(1))
                if source is not None:
                    add_touchpoint(mapping, source, rel_path, "manifest")

            if "};" in raw_line:
                in_replaced_sources = False

    return mapping


def iter_owned_text_paths(repo_root: Path) -> list[Path]:
    paths: list[Path] = []

    for root_name in (".github", "zig_build", "zig_src", "zig_bridge"):
        root = repo_root / root_name
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.is_dir():
                continue
            if path.suffix in TEXT_EXTENSIONS:
                paths.append(path)

    for name in ROOT_TEXT_FILES:
        root_path = repo_root / name
        if root_path.exists():
            paths.append(root_path)

    return paths


def exact_search_terms(changed_path: str) -> list[str]:
    terms = [changed_path]
    if changed_path.startswith("src/c47/") and changed_path.endswith(".h"):
        basename = changed_path.rsplit("/", 1)[1]
        terms.append(f'"{basename}"')
        terms.append(f'<{basename}>')
    return terms


def collect_exact_touchpoints(
    repo_root: Path,
    changed_paths: list[str],
) -> dict[str, dict[str, set[str]]]:
    mapping: dict[str, dict[str, set[str]]] = {}
    if not changed_paths:
        return mapping

    owned_files = iter_owned_text_paths(repo_root)
    for path in owned_files:
        rel_path = path.relative_to(repo_root).as_posix()
        text = path.read_text(encoding="utf-8", errors="ignore")
        for changed_path in changed_paths:
            if any(term in text for term in exact_search_terms(changed_path)):
                add_touchpoint(mapping, changed_path, rel_path, "exact")

    return mapping


def collect_touchpoints(
    repo_root: Path,
    changed_paths: list[str],
) -> dict[str, dict[str, set[str]]]:
    manifest_mapping = collect_manifest_touchpoints(repo_root)
    exact_mapping = collect_exact_touchpoints(repo_root, changed_paths)
    combined: dict[str, dict[str, set[str]]] = {}

    for changed_path in changed_paths:
        for source_mapping in (manifest_mapping, exact_mapping):
            for touchpoint_path, reasons in source_mapping.get(changed_path, {}).items():
                for reason in reasons:
                    add_touchpoint(combined, changed_path, touchpoint_path, reason)

    return {changed_path: touchpoints for changed_path, touchpoints in combined.items() if touchpoints}


def classify_touchpoint(touchpoint_path: str, reasons: set[str]) -> str:
    if "manifest" in reasons:
        return BUILD_MANIFEST_CLASS
    if touchpoint_path.startswith("zig_src/"):
        return RUNTIME_ZIG_CLASS
    if touchpoint_path.startswith("zig_build/tools/"):
        return BUILD_TOOL_ZIG_CLASS
    if touchpoint_path.startswith("zig_build/"):
        return BUILD_LOGIC_CLASS
    if touchpoint_path.startswith("zig_bridge/"):
        return RETAINED_C_CLASS
    return WORKFLOW_DOC_CLASS


def changed_path_classes(touchpoints: dict[str, set[str]]) -> set[str]:
    return {classify_touchpoint(path, reasons) for path, reasons in touchpoints.items()}


def print_labeled_list(title: str, items: list[str], limit: int) -> None:
    print(f"\n{title} ({len(items)}):")
    if not items:
        print("- none")
        return

    visible = items if limit == 0 else items[:limit]
    for item in visible:
        print(f"- {item}")

    if limit != 0 and len(items) > limit:
        print(f"- ... {len(items) - limit} more omitted")


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()

    try:
        pin_values = load_pin_env(repo_root / PIN_PATH)
        if args.fetch:
            fetch_upstream(repo_root, pin_values)

        base_rev = args.base_rev or pin_values["UPSTREAM_COMMIT"]
        head_rev = args.head_rev or resolve_default_head(repo_root, pin_values, args.fetch)
        base_commit = resolve_revision(repo_root, base_rev)
        head_commit = resolve_revision(repo_root, head_rev)

        counts = git_output(repo_root, "rev-list", "--left-right", "--count", f"{base_rev}...{head_rev}")
        base_only_str, head_only_str = counts.split()
        base_only = int(base_only_str)
        head_only = int(head_only_str)

        if base_only == 0 and head_only == 0:
            status = "pinned commit still matches upstream HEAD"
        elif base_only == 0:
            status = "upstream has moved"
        else:
            status = "comparison head diverged from pinned commit"

        log_args = [
            "log",
            "--reverse",
            "--format=%h %s",
            f"{base_rev}..{head_rev}",
        ]
        if args.max_commits > 0:
            log_args.insert(1, f"-n{args.max_commits}")
        commits = [line for line in git_output(repo_root, *log_args).splitlines() if line.strip()]

        all_changed_paths = [
            line.strip()
            for line in git_output(repo_root, "diff", "--name-only", f"{base_rev}..{head_rev}").splitlines()
            if line.strip()
        ]
        changed_paths = all_changed_paths if args.max_paths == 0 else all_changed_paths[: args.max_paths]
        top_level_counts = Counter(path.split("/", 1)[0] for path in all_changed_paths)
        touchpoints = collect_touchpoints(repo_root, all_changed_paths)
        covered_paths = sorted(touchpoints)
        uncovered_paths = [path for path in all_changed_paths if path not in touchpoints]
        class_counts = Counter()
        for changed_path in covered_paths:
            for touchpoint_class in changed_path_classes(touchpoints[changed_path]):
                class_counts[touchpoint_class] += 1
        retained_only_paths = [
            changed_path
            for changed_path in covered_paths
            if changed_path_classes(touchpoints[changed_path]).issubset(
                {RETAINED_C_CLASS, BUILD_MANIFEST_CLASS, WORKFLOW_DOC_CLASS}
            )
        ]
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"Pinned upstream commit: {base_commit}")
    print(f"Current upstream HEAD: {head_commit}")
    print(f"Comparison revision: {head_rev}")
    print(f"Pinned-only commits: {base_only}")
    print(f"New upstream commits: {head_only}")
    print(f"Status: {status}")

    print_labeled_list("New upstream commits", commits, args.max_commits)
    print_labeled_list("Changed imported paths", changed_paths, args.max_paths)

    print("\nChanged imported path summary:")
    for top_level, count in sorted(top_level_counts.items(), key=lambda item: (-item[1], item[0])):
        print(f"- {top_level}: {count}")

    print("\nChanged imported path ownership summary:")
    print(f"- {RUNTIME_ZIG_CLASS}: {class_counts[RUNTIME_ZIG_CLASS]}")
    print(f"- {BUILD_TOOL_ZIG_CLASS}: {class_counts[BUILD_TOOL_ZIG_CLASS]}")
    print(f"- {BUILD_LOGIC_CLASS}: {class_counts[BUILD_LOGIC_CLASS]}")
    print(f"- {BUILD_MANIFEST_CLASS}: {class_counts[BUILD_MANIFEST_CLASS]}")
    print(f"- {RETAINED_C_CLASS}: {class_counts[RETAINED_C_CLASS]}")
    print(f"- {WORKFLOW_DOC_CLASS}: {class_counts[WORKFLOW_DOC_CLASS]}")
    print(f"- retained-or-manifest-only changed paths: {len(retained_only_paths)}")
    print(f"- no explicit z47 touchpoint: {len(uncovered_paths)}")

    print(f"\nChanged imported paths with explicit z47 touchpoints ({len(covered_paths)}):")
    if not covered_paths:
        print("- none")
    else:
        for changed_path in covered_paths:
            print(f"- {changed_path}")
            for touchpoint, reasons in sorted(touchpoints[changed_path].items()):
                touchpoint_class = classify_touchpoint(touchpoint, reasons)
                reason_text = ", ".join(sorted(reasons))
                print(f"  - [{touchpoint_class}; {reason_text}] {touchpoint}")

    print_labeled_list(
        "Changed imported paths without explicit z47 touchpoints",
        uncovered_paths,
        args.max_paths,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())