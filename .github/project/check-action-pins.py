#!/usr/bin/env python3
"""Every workflow action is pinned to one commit, named by its version.

A tag can be moved to other code after review; a full commit SHA cannot. Each
`uses:` line therefore names a 40-hex SHA and carries a `# vX.Y.Z` comment that
says which release it is. An action used in several places is pinned to the
same SHA and version everywhere, so updating one use and forgetting another
fails here. mlugg/setup-zig is pinned twice by design, once in the workflows
and once as SETUP_ZIG_ACTION_REF in zig-toolchain.env, and the two must agree.

The check reads only the repository. Whether a SHA really is the tag its
comment names is checked online by the actions-lock workflow, against
.github/workflows/actions.lock.

Usage:
    check-action-pins.py [--repo-root .]
    check-action-pins.py --self-test
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

USES = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)(.*)$")
PINNED = re.compile(r"^(?P<action>[\w.-]+/[\w.-]+(?:/[\w./-]+)?)@(?P<sha>[0-9a-f]{40})$")
VERSION = re.compile(r"^\s*#\s*(?P<version>v\d+(?:\.\d+){0,2})\s*$")
TOOLCHAIN_ENV = ".github/zig-toolchain.env"
SETUP_ZIG = "mlugg/setup-zig"


def check(workflows: dict[str, str], toolchain_env: str) -> list[str]:
    problems: list[str] = []
    seen: dict[str, set[tuple[str, str]]] = {}
    for name, text in sorted(workflows.items()):
        for number, line in enumerate(text.splitlines(), start=1):
            m = USES.match(line)
            if not m:
                continue
            target, rest = m.group(1).strip("'\""), m.group(2)
            if target.startswith("./"):
                continue
            pin = PINNED.match(target)
            if not pin:
                problems.append(f"{name}:{number}: {target} is not pinned to a 40-hex commit SHA")
                continue
            version = VERSION.match(rest)
            if not version:
                problems.append(
                    f"{name}:{number}: {target} has no `# vX.Y.Z` comment naming its release"
                )
                continue
            seen.setdefault(pin.group("action"), set()).add(
                (pin.group("sha"), version.group("version"))
            )
    for action, pins in sorted(seen.items()):
        if len(pins) > 1:
            listed = ", ".join(f"{sha[:12]} {version}" for sha, version in sorted(pins))
            problems.append(f"{action} is pinned {len(pins)} ways: {listed}")
    ref = re.search(r"^SETUP_ZIG_ACTION_REF=([0-9a-f]{40})\s*$", toolchain_env, re.M)
    zig_pins = seen.get(SETUP_ZIG, set())
    if zig_pins and not ref:
        problems.append(f"{TOOLCHAIN_ENV} names no 40-hex SETUP_ZIG_ACTION_REF")
    elif ref and zig_pins and {sha for sha, _ in zig_pins} != {ref.group(1)}:
        problems.append(
            f"{SETUP_ZIG} is pinned to {sorted(zig_pins)} but {TOOLCHAIN_ENV} says {ref.group(1)}"
        )
    return problems


def self_test() -> int:
    good = "      - uses: actions/checkout@" + "a" * 40 + " # v7.0.1\n"
    env = "SETUP_ZIG_ACTION_REF=" + "b" * 40 + "\n"
    cases = {
        "a pinned use": ({"a.yml": good}, env, 0),
        "a tag": ({"a.yml": "      - uses: actions/checkout@v7\n"}, env, 1),
        "no version comment": (
            {"a.yml": "      - uses: actions/checkout@" + "a" * 40 + "\n"},
            env,
            1,
        ),
        "two pins of one action": (
            {"a.yml": good, "b.yml": good.replace("a" * 40, "c" * 40)},
            env,
            1,
        ),
        "setup-zig against the env": (
            {"a.yml": "      - uses: mlugg/setup-zig@" + "d" * 40 + " # v2.2.1\n"},
            env,
            1,
        ),
    }
    for label, (workflows, toolchain, want) in cases.items():
        if len(check(workflows, toolchain)) != want:
            print(f"check-action-pins: SELF-TEST FAILED -- {label}")
            return 1
    print(
        "check-action-pins: SELF-TEST OK -- a tag, a missing version, a split pin and a setup-zig drift are caught"
    )
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    root = Path(args.repo_root)
    workflows = {
        p.name: p.read_text(encoding="utf-8")
        for p in sorted((root / ".github/workflows").glob("*.y*ml"))
    }
    if not workflows:
        print("check-action-pins: no workflows found; nothing was checked")
        return 1
    problems = check(workflows, (root / TOOLCHAIN_ENV).read_text(encoding="utf-8"))
    for problem in problems:
        print(problem)
    uses = sum(1 for text in workflows.values() for line in text.splitlines() if USES.match(line))
    print(
        f"check-action-pins: {uses} uses in {len(workflows)} workflows, {len(problems)} problem(s)"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
