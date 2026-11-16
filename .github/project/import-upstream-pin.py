#!/usr/bin/env python3
"""Import a new upstream pin into the imported tree, as a three-way merge.

WHY THIS EXISTS. The imported tree is the pinned upstream commit minus the paths
imported-tree-divergences.txt declares [not-carried], plus the files it declares
[patched]. Copying the paths a range changed by hand misses some (the pin gate was
written after it did), needs the `upstream/` hop on every one, and a whole-tree
copy reverts every declared divergence. This script lets git do it instead:

1. build the old pin and the new pin, each minus the [not-carried] paths, in a
   private index;
2. three-way merge them into HEAD with `git merge-tree`: the base is HEAD with
   the old filtered pin under UPSTREAM_ROOT, the other side HEAD with the new
   one. A file z47 patches merges like any other, or stops the import as a
   conflict;
3. stage the result and move UPSTREAM_COMMIT in upstream-pin.env.

It never commits. The import and the Zig port land together as the resync
commit, on a linear history: no merge commit, and the filtered trees are not
stored anywhere.

WHAT IT REFUSES. A dirty tracked tree, an imported tree that is not at its
current pin (check-imported-tree-pin.py's condition), a pin that is not present
locally (`git fetch upstream` first), and any merge result that touches a path
outside UPSTREAM_ROOT. On a conflict it lists the paths and changes nothing.

Usage: import-upstream-pin.py <newpin> [--repo-root .] [--dry-run]
"""

from __future__ import annotations

import argparse
import datetime
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from upstream_paths import PIN_FILE_RELATIVE, covered, read_divergences, read_pin, upstream_root

# merge-tree needs commits; these exist only for the merge and are never referenced.
_SCRATCH_IDENTITY = {
    "GIT_AUTHOR_NAME": "import-upstream-pin",
    "GIT_AUTHOR_EMAIL": "import-upstream-pin@invalid",
    "GIT_COMMITTER_NAME": "import-upstream-pin",
    "GIT_COMMITTER_EMAIL": "import-upstream-pin@invalid",
}

# Upstream files whose rules z47 mirrors by hand in its own root copy.
_RECONCILED_BY_HAND = (".gitignore", ".gitattributes", ".gitmodules")


def git(repo: Path, *args: str, index: Path | None = None, stdin: bytes | None = None) -> str:
    env = dict(os.environ)
    if index is not None:
        env["GIT_INDEX_FILE"] = str(index)
        env.update(_SCRATCH_IDENTITY)
    proc = subprocess.run(
        ["git", "-C", str(repo), *args], input=stdin, capture_output=True, env=env
    )
    if proc.returncode:
        raise SystemExit(
            f"import-upstream-pin: git {' '.join(args)} failed:\n"
            + proc.stderr.decode(errors="replace").strip()
        )
    return proc.stdout.decode(errors="replace")


def resolve_commit(repo: Path, rev: str, pin: dict[str, str]) -> str:
    proc = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}"],
        capture_output=True,
        text=True,
    )
    if proc.returncode:
        raise SystemExit(
            f"import-upstream-pin: {rev} is not a commit present locally. Fetch it first:\n"
            f"  git fetch {pin.get('UPSTREAM_REPOSITORY_URL', '<upstream>')} "
            f"{pin.get('UPSTREAM_BRANCH', 'master')}"
        )
    return proc.stdout.strip()


def filtered_tree(repo: Path, commit: str, not_carried: list[str], index: Path) -> str:
    """The tree of ``commit`` without the [not-carried] paths."""
    git(repo, "read-tree", commit, index=index)
    files = [p for p in git(repo, "ls-files", "-z", index=index).split("\0") if p]
    dropped = [p for p in files if covered(p, not_carried)]
    if dropped:
        git(
            repo,
            "update-index",
            "-z",
            "--force-remove",
            "--stdin",
            index=index,
            stdin=("\0".join(dropped) + "\0").encode(),
        )
    return git(repo, "write-tree", index=index).strip()


def with_imported_tree(repo: Path, commit: str, root: str, tree: str, index: Path) -> str:
    """The tree of ``commit`` with ``tree`` mounted at ``root`` instead."""
    git(repo, "read-tree", commit, index=index)
    files = [p for p in git(repo, "ls-files", "-z", "--", root, index=index).split("\0") if p]
    if files:
        git(
            repo,
            "update-index",
            "-z",
            "--force-remove",
            "--stdin",
            index=index,
            stdin=("\0".join(files) + "\0").encode(),
        )
    git(repo, "read-tree", f"--prefix={root}/", tree, index=index)
    return git(repo, "write-tree", index=index).strip()


def scratch_commit(repo: Path, tree: str, index: Path, message: str) -> str:
    return git(repo, "commit-tree", tree, "-m", message, index=index).strip()


def changed_paths(repo: Path, old: str, new: str) -> list[str]:
    out = git(repo, "-c", "core.quotepath=off", "diff", "--name-only", old, new)
    return [p for p in out.splitlines() if p]


def write_pin(repo: Path, new_pin: str) -> None:
    pin_file = repo / PIN_FILE_RELATIVE
    today = datetime.date.today().isoformat()
    lines = []
    for raw in pin_file.read_text(encoding="utf-8").splitlines():
        if raw.startswith("UPSTREAM_COMMIT="):
            raw = f"UPSTREAM_COMMIT={new_pin}"
        elif raw.startswith("UPSTREAM_PIN_UPDATED="):
            raw = f"UPSTREAM_PIN_UPDATED={today}"
        lines.append(raw)
    pin_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("newpin", help="the upstream commit to import")
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--dry-run", action="store_true", help="report what would change and stop")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    pin = read_pin(repo)
    root = upstream_root(repo).relative_to(repo).as_posix()
    if root in {"", "."}:
        raise SystemExit(
            "import-upstream-pin: needs the imported tree under its own UPSTREAM_ROOT."
        )
    not_carried, patched = read_divergences(repo)

    old_pin = resolve_commit(repo, pin.get("UPSTREAM_COMMIT", ""), pin)
    new_pin = resolve_commit(repo, args.newpin, pin)
    if old_pin == new_pin:
        print(f"import-upstream-pin: already at {new_pin[:12]}; nothing to import.")
        return 0
    if subprocess.run(
        ["git", "-C", str(repo), "merge-base", "--is-ancestor", old_pin, new_pin],
        capture_output=True,
    ).returncode:
        print(
            f"warning: {old_pin[:12]} is not an ancestor of {new_pin[:12]}; upstream history moved."
        )

    if not args.dry_run and git(repo, "status", "--porcelain", "--untracked-files=no").strip():
        raise SystemExit(
            "import-upstream-pin: the tracked tree has uncommitted changes; commit or discard them first."
        )

    head = git(repo, "rev-parse", "HEAD").strip()
    with tempfile.TemporaryDirectory(prefix="import-upstream-pin-") as tmp:
        index = Path(tmp) / "index"
        old_filtered = filtered_tree(repo, old_pin, not_carried, index)
        new_filtered = filtered_tree(repo, new_pin, not_carried, index)

        # The imported tree must be at its pin before anything moves it: away from the
        # [patched] files, HEAD's imported tree is exactly the old filtered pin.
        drift = [
            p
            for p in changed_paths(repo, old_filtered, f"{head}:{root}")
            if not covered(p, patched)
        ]
        if drift:
            print(
                f"import-upstream-pin: {root}/ is not at its pin {old_pin[:12]}; these paths differ:"
            )
            for p in drift:
                print(f"  {p}")
            print("Run check-imported-tree-pin.py, and import only from a tree at its pin.")
            return 1

        base = scratch_commit(
            repo, with_imported_tree(repo, head, root, old_filtered, index), index, "base"
        )
        theirs = scratch_commit(
            repo, with_imported_tree(repo, head, root, new_filtered, index), index, "theirs"
        )
        proc = subprocess.run(
            [
                "git",
                "-C",
                str(repo),
                "merge-tree",
                "--write-tree",
                "--name-only",
                f"--merge-base={base}",
                head,
                theirs,
            ],
            capture_output=True,
            text=True,
        )
    if proc.returncode not in (0, 1):
        raise SystemExit(f"import-upstream-pin: git merge-tree failed:\n{proc.stderr.strip()}")
    result, _, detail = proc.stdout.partition("\n")
    if proc.returncode == 1:
        print(f"import-upstream-pin: CONFLICT importing {new_pin[:12]}; nothing was changed.")
        print(detail.rstrip())
        print(
            "Resolve the [patched] files above against the new pin by hand, or update their entries."
        )
        return 1

    outside = git(repo, "diff", "--name-only", head, result, "--", ".", f":(exclude){root}").split()
    if outside:
        raise SystemExit(f"import-upstream-pin: the merge touched paths outside {root}/: {outside}")
    leftover = [
        p for p in changed_paths(repo, new_filtered, f"{result}:{root}") if not covered(p, patched)
    ]
    if leftover:
        raise SystemExit(
            f"import-upstream-pin: merged tree differs from the new pin outside [patched]: {leftover}"
        )

    status = git(
        repo,
        "-c",
        "core.quotepath=off",
        "diff",
        "--name-status",
        "-M",
        f"{head}:{root}",
        f"{result}:{root}",
    )
    lines = [line for line in status.splitlines() if line]
    skipped = [p for p in changed_paths(repo, old_pin, new_pin) if covered(p, not_carried)]
    by_hand = [p for p in skipped if p in _RECONCILED_BY_HAND]

    print(
        f"import-upstream-pin: {old_pin[:12]} -> {new_pin[:12]}, "
        f"{len(lines)} path{'' if len(lines) == 1 else 's'} under {root}/:"
    )
    for line in lines:
        print(f"  {line}")
    print(
        f"{len(skipped)} changed upstream "
        f"{'path is' if len(skipped) == 1 else 'paths are'} [not-carried] and left out."
    )
    for p in by_hand:
        print(f"  {p} changed upstream: reconcile z47's own root {p} by hand.")

    if args.dry_run:
        print("Dry run: nothing was changed.")
        return 0

    git(repo, "read-tree", "-m", "-u", head, result)
    write_pin(repo, new_pin)
    git(repo, "add", "--", PIN_FILE_RELATIVE)
    print(f"Staged the import and moved UPSTREAM_COMMIT to {new_pin[:12]}. Next:")
    print(
        f"  python3 .github/project/report-resync-worklist.py {old_pin[:9]} {new_pin[:9]} --sibling ."
    )
    print("  port the owners it names, then commit the import and the port together.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
