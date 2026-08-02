#!/usr/bin/env python3
"""Catch a repo-root-ANCHORED path that actually lives in the imported tree.

Moving the imported tree under UPSTREAM_ROOT turned every unqualified reference to
one of its files into a dangling path. The C `#include` half of that class has its
own gate (check-harness-includes.py); this covers the governance scripts, which
reach for those files through an explicit repo-root anchor:

    copying_source = repo_root / "COPYING"          # dangling since the move

The gate is restricted to *anchored* paths -- `repo_root / ...` in Python and
`$repo_root/...` / `$GITHUB_WORKSPACE/...` in shell -- because only those have a
CWD-independent meaning. A bare relative literal is deliberately out of scope: it
is correct in the harnesses whose CWD *is* the imported tree (build/host/gtk_io.zig
opens "res/testPgms/testPgms.bin", build/tests/testsuite_hal.zig opens "c47.sav"),
and it is also how the upstream-relative fragment is spelled at every CORRECT call
site that composes it with the root on another line. Widening this gate to bare
literals reports ~130 such sites, all of them fine; the resulting allowlist would
bury the one finding that matters. Runtime failure is the check for that half --
the scripts already die with a named path, which is how this class surfaces.

The rule, applied to anchored paths only:

    FAIL when the anchored path does NOT exist at the repo root
         but DOES exist under UPSTREAM_ROOT.

A not-yet-written output cannot trip it: it is absent from the imported tree too.
That is what removes the need for an allowlist of write targets.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

from upstream_paths import upstream_root

# The two files whose SUBJECT is the anti-pattern, and which therefore have to spell it
# out in prose: the resolver that exists to avoid it, and this gate. Neither performs a
# path access of its own, so excluding them costs no coverage. Comments and docstrings
# are not stripped before matching -- doing that precisely means tokenising, which buys
# nothing while the set of self-documenting files is these two. A new script that
# discusses the pattern in prose belongs here; the gate's own message says as much.
EXCLUDED_FILES = frozenset(
    {
        ".github/project/upstream_paths.py",
        ".github/project/check-imported-root-references.py",
    }
)

SCANNED_GLOBS = (
    ".github/project/*.py",
    ".github/project/*.sh",
    ".github/workflows/*.yml",
    "build/**/*.py",
    "build/**/*.sh",
)

# repo_root / "a" / "b/c"  ->  captures the quoted run so the segments can be joined.
PY_ANCHORED = re.compile(
    r"""\b(?:repo_root|REPO_ROOT|repo_dir)\s*/\s*((?:["'][^"']+["']\s*/?\s*)+)"""
)
PY_SEGMENT = re.compile(r"""["']([^"']+)["']""")

# "$repo_root/a/b", "${GITHUB_WORKSPACE}/a/b"
SH_ANCHORED = re.compile(
    r"""\$\{?(?:repo_root|REPO_ROOT|GITHUB_WORKSPACE)\}?/([A-Za-z0-9_.][A-Za-z0-9_./-]*)"""
)


def anchored_paths(text: str, *, is_python: bool) -> list[tuple[int, str]]:
    """Anchored paths in one file. `repo_root / "x"` is matched only in Python, because
    that spelling is Python syntax; in a shell or YAML file it can only be prose, and
    the comments registering this gate quote the anti-pattern verbatim."""
    found: list[tuple[int, str]] = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        if is_python:
            for run in PY_ANCHORED.findall(line):
                segments = PY_SEGMENT.findall(run)
                if segments:
                    found.append((lineno, "/".join(segments)))
        for path in SH_ANCHORED.findall(line):
            found.append((lineno, path.rstrip("/")))
    return found


def tracked_files(repo_root: Path) -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "--", *SCANNED_GLOBS],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line for line in out.stdout.splitlines() if line and line not in EXCLUDED_FILES]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        default=str(Path(__file__).resolve().parents[2]),
        help="repository root to scan (default: the root containing this script)",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    imported = upstream_root(repo_root)
    if imported.resolve() == repo_root.resolve():
        print("UPSTREAM_ROOT is the repo root: nothing to distinguish, gate is a no-op")
        return 0

    findings: list[str] = []
    anchors = 0

    for relative in tracked_files(repo_root):
        # errors="replace" rather than a second `except` arm: undecodable bytes cannot
        # be part of a path literal, so scanning them as replacement characters is
        # strictly better than skipping the file, and it keeps this to one exception
        # type. A parenthesized tuple would be rewritten to PEP 758 form (3.14-only)
        # by ruff's py314 target, and the workflows invoke an unpinned `python3`.
        try:
            text = (repo_root / relative).read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue

        for lineno, path in anchored_paths(text, is_python=relative.endswith(".py")):
            anchors += 1
            if (repo_root / path).exists():
                continue
            if not (imported / path).exists():
                continue
            findings.append(
                f"{relative}:{lineno}: anchored at the repo root as '{path}', "
                f"but the file is at {imported.name}/{path}"
            )

    if findings:
        print("Imported-tree paths anchored to the repo root:", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print(
            "\nResolve each through UPSTREAM_ROOT: upstream_path(repo_root, ...) in "
            "Python, resolve_repo_relative in shell.",
            file=sys.stderr,
        )
        return 1

    print(f"Repo-root-anchored path integrity OK ({anchors} anchored paths checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
