#!/usr/bin/env python3
"""Every Zig `test` block under src/ is the root of a test the build runs.

WHY THIS EXISTS. Zig runs a test block only when the file holding it is analysed
from a test root: an @import that nothing references from a test leaves the
file's tests out of the binary, with no message. Seven blocks in four files sat
that way -- among them the register-tag arithmetic a resync had just added --
and read as coverage that never ran.

THE RULE. A file under src/ that holds a `test` block must itself be the root of
an `addTest` the build declares: an entry of build.zig's `pure_modules` list, or
a `root_source_file` beside an `addTest(` call under build/. Reaching a file
through another root's imports is not enough, because whether that reach runs
the file's tests depends on what the root references, which this check cannot
see and a reader cannot either.

Usage: check-test-reachability.py [--repo-root .] [--self-test]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

TEST_DECL = re.compile(r"^test\b", re.M)
PURE_MODULES = re.compile(r"const pure_modules = \[_\]\[\]const u8\{(.*?)\};", re.S)
SRC_LITERAL = re.compile(r'"(src/[A-Za-z0-9_/.-]+\.zig)"')
ROOT_SOURCE = re.compile(r'root_source_file = b\.path\("(src/[A-Za-z0-9_/.-]+\.zig)"\)')
# How far a root_source_file may sit from the addTest( that uses it.
NEAR = 12


def tracked(repo: Path, *globs: str) -> list[str]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", *globs], capture_output=True, text=True, check=True
    ).stdout
    return out.split()


def test_roots(repo: Path) -> set[str]:
    roots: set[str] = set()
    build_zig = (repo / "build.zig").read_text(encoding="utf-8")
    listed = PURE_MODULES.search(build_zig)
    if listed:
        roots.update(SRC_LITERAL.findall(listed.group(1)))
    for rel in ["build.zig", *tracked(repo, "build/*.zig", "build/**/*.zig")]:
        lines = (repo / rel).read_text(encoding="utf-8").splitlines()
        tests_at = [i for i, line in enumerate(lines) if "addTest(" in line]
        for i, line in enumerate(lines):
            found = ROOT_SOURCE.search(line)
            if found and any(abs(i - t) <= NEAR for t in tests_at):
                roots.add(found.group(1))
    return roots


def files_with_tests(repo: Path) -> list[str]:
    return sorted(
        rel
        for rel in tracked(repo, "src/*.zig", "src/**/*.zig")
        if TEST_DECL.search((repo / rel).read_text(encoding="utf-8"))
    )


def unreached(repo: Path) -> list[str]:
    roots = test_roots(repo)
    return [rel for rel in files_with_tests(repo) if rel not in roots]


def self_test() -> int:
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        (repo / "src").mkdir()
        (repo / "build").mkdir()
        (repo / "src/rooted.zig").write_text('test "a" {}\n')
        (repo / "src/orphan.zig").write_text('test "b" {}\n')
        (repo / "src/plain.zig").write_text("pub const x = 1;\n")
        (repo / "build.zig").write_text(
            'const pure_modules = [_][]const u8{\n    "src/rooted.zig",\n};\n'
        )
        (repo / "build/steps.zig").write_text(
            'const m = b.createModule(.{ .root_source_file = b.path("src/plain.zig") });\n'
        )
        subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True)
        got = unreached(repo)
        if got != ["src/orphan.zig"]:
            print(f"check-test-reachability: SELF-TEST FAILED -- got {got}")
            return 1
    print("check-test-reachability: SELF-TEST OK -- a test block no root reaches is reported")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    if args.self_test:
        return self_test()

    repo = Path(args.repo_root).resolve()
    missing = unreached(repo)
    total = len(files_with_tests(repo))
    if missing:
        print("TEST BLOCKS NO ROOT RUNS:")
        for rel in missing:
            print(f"  {rel}")
        print(
            "\nAdd each file to build.zig's pure_modules, or give it its own addTest root.\n"
            "A test block that never runs reads as coverage and is not."
        )
        return 1
    print(f"check-test-reachability: OK ({total} files with test blocks, every one a test root)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
