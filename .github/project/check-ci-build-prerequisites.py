#!/usr/bin/env python3
"""A CI job that runs `zig build` must provision what that build links.

WHY THIS EXISTS. `check-gate-inventory.py` asks whether a workflow NAMES a script,
which is the right question for "is this check run by a system or by a habit". It
cannot ask whether the job naming it can EXECUTE it. Those are different questions
and the difference cost a red lane:

  Enforce the object graph matches the build's own declaration
    -> job: Native Zig unit tests (no C oracle)   [installs no host libraries]
    -> step: zig build object-manifest
    -> thread 3163 panic: pkg-config failed for library freetype2

The manifest names each object by its emitted binary, so writing it builds the
simulator's object set -- including the GTK runtime objects, whose translate-c step
shells out to pkg-config. A job with no GTK cannot produce it. The gate was in CI
by the inventory's reckoning and in force nowhere, which is the exact failure the
inventory was written to stop, one level down.

HOW IT CLASSIFIES A JOB. By what it PROVISIONS, across the three mechanisms this
tree actually uses -- `apt-get install` on the ubuntu runners, `brew install` on
macOS, and `msys2/setup-msys2` on Windows. A job that provisions any host library
may run anything. A job that provisions none may run only the build targets in
HOST_LIB_FREE below.

HOW THE MANIFEST IS DERIVED, AND WHY IT IS NOT A GUESS. `--probe TARGET` runs that
target with pkg-config pointed at a nonexistent directory, which is what a runner
without the -dev packages looks like to the build. That reproduces the CI failure
on a developer machine exactly, so the manifest is measured here rather than
discovered by pushing. Re-derive with --probe when adding a row.

WHAT IT DOES NOT CHECK, per the rule that a gate states its own domain:

  - `zig build` invoked from inside a Python or shell script the workflow calls.
    check-parity-lanes-gated.py runs `zig build --help`, which builds nothing; a
    script that runs a real target would be invisible here and is a hole this gate
    does not close.
  - Any prerequisite other than host libraries -- a missing Xvfb, an absent
    arm-none-eabi-gcc, a toolchain that did not install. Those fail loudly on their
    own; the pkg-config panic is the one that reads like a build error.
  - Whether a provisioned job installs the RIGHT libraries for what it runs. It
    asks whether the job provisions at all.

Usage:
  check-ci-build-prerequisites.py [--repo-root .]
  check-ci-build-prerequisites.py --probe test:unit   # measure a target's needs
  check-ci-build-prerequisites.py --self-test         # prove the gate fires
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - environment, not logic
    # A missing input and a passing check must not print the same thing. This gate
    # cannot parse a workflow without PyYAML, so it says so and exits non-zero
    # rather than reporting an empty audit as a clean one.
    print("cannot measure: PyYAML is not installed; `apt-get install -y python3-yaml`")
    raise SystemExit(2) from None

WORKFLOWS = ".github/workflows"

# Provisioning, by the three mechanisms this tree uses. A job that does none of
# these has whatever the bare runner image carries, which does not include the
# -dev packages a pkg-config lookup needs.
HOST_LIBRARY_TOKENS = ("gtk", "freetype", "gmp", "pulse", "cairo", "pango")
PROVISION_ACTIONS = ("msys2/setup-msys2",)

# Build targets that link nothing needing pkg-config, so a job may run them with no
# provisioning at all. Every row is measured with --probe, not assumed.
HOST_LIB_FREE = {
    "test:unit": (
        "probed: passes with pkg-config intact AND with it unavailable, so it links "
        "no system library"
    ),
    "docs": (
        "not probeable here -- the target fails on this machine with pkg-config "
        "intact, so a poisoned run cannot isolate the question. Verdict taken from "
        "CI instead: the linux-docs job runs it green while installing only doxygen "
        "and python3-pip, which IS the measurement, just not a local one"
    ),
}

ZIG_BUILD_RE = re.compile(r"\bzig build\b([^\n|&;#]*)")
FLAG_RE = re.compile(r"^-")


def strip_comments(run: str) -> str:
    """Shell comment lines are not commands. A `# ... zig build ...` note is prose."""
    out = []
    for line in run.split("\n"):
        stripped = line.lstrip()
        if stripped.startswith("#"):
            continue
        out.append(line.split(" #")[0])
    return "\n".join(out)


def build_targets(run: str) -> list[str]:
    """Every `zig build` target named in a run block, `--help` and flags excluded."""
    found: list[str] = []
    for tail in ZIG_BUILD_RE.findall(strip_comments(run)):
        for word in tail.split():
            if FLAG_RE.match(word):
                continue
            if word.startswith("$") or word.startswith('"'):
                continue
            found.append(word)
            break
    return found


def provisions(job: dict) -> bool:
    for step in job.get("steps") or []:
        uses = step.get("uses") or ""
        if any(action in uses for action in PROVISION_ACTIONS):
            return True
        run = step.get("run") or ""
        for line in strip_comments(run).split("\n"):
            installs = "apt-get install" in line or "brew install" in line or "pacman -S" in line
            if installs and any(token in line.lower() for token in HOST_LIBRARY_TOKENS):
                return True
        # macOS resolves its formula list into a variable, so the install line does
        # not name a library. The list that feeds it does.
        if "missing_formulae" in run and any(t in run.lower() for t in HOST_LIBRARY_TOKENS):
            return True
    return False


def audit(repo_root: Path) -> tuple[list[str], int]:
    """(violations, number of job/target pairs examined)."""
    violations: list[str] = []
    examined = 0

    for path in sorted((repo_root / WORKFLOWS).glob("*.yml")):
        document = yaml.safe_load(path.read_text(encoding="utf-8"))
        for job_name, job in (document.get("jobs") or {}).items():
            provisioned = provisions(job)
            for step in job.get("steps") or []:
                run = step.get("run") or ""
                for target in build_targets(run):
                    examined += 1
                    if provisioned or target in HOST_LIB_FREE:
                        continue
                    violations.append(
                        f"{path.name}: job `{job_name}` provisions no host libraries "
                        f"but runs `zig build {target}`\n"
                        f"    step: {step.get('name', '<unnamed>')}"
                    )
    return violations, examined


def check(repo_root: Path) -> int:
    violations, examined = audit(repo_root)
    if violations:
        print(f"FAIL: {len(violations)} build step(s) in jobs that cannot run them:")
        for violation in violations:
            print(f"  {violation}")
        print()
        print("Move the step to a job that provisions host libraries, or -- if the target")
        print("genuinely needs none -- prove it with --probe and add it to HOST_LIB_FREE.")
        return 1
    print(
        f"PASS: every `zig build` target in a workflow runs in a job that provisions "
        f"what it links ({examined} job/target pair(s) examined, "
        f"{len(HOST_LIB_FREE)} target(s) allowed without provisioning)"
    )
    return 0


def run_target(repo_root: Path, target: str, poisoned: bool) -> subprocess.CompletedProcess:
    environment = dict(os.environ)
    if poisoned:
        # What a runner without the -dev packages looks like to the build.
        environment["PKG_CONFIG_LIBDIR"] = "/nonexistent"
        environment["PKG_CONFIG_PATH"] = "/nonexistent"
    return subprocess.run(
        ["zig", "build", target],
        cwd=repo_root,
        env=environment,
        capture_output=True,
        text=True,
    )


def probe(repo_root: Path, target: str) -> int:
    """Measure a target's host-library dependency DIFFERENTIALLY.

    One poisoned run cannot tell "needs freetype" from "does not build here at
    all" -- the first version of this probe reported `docs` as needing host
    libraries when it fails on this machine either way. The verdict comes from the
    PAIR, and where the baseline already fails the probe says so instead of
    guessing.
    """
    baseline = run_target(repo_root, target, poisoned=False)
    if baseline.returncode != 0:
        print(f"PROBE: `zig build {target}` INCONCLUSIVE -- it fails here with pkg-config intact,")
        print("       so this machine cannot isolate the host-library question for it.")
        print("       Take the verdict from a CI job that runs it, and record which one.")
        return 2

    poisoned = run_target(repo_root, target, poisoned=True)
    if poisoned.returncode == 0:
        print(f"PROBE: `zig build {target}` SURVIVES with pkg-config unavailable")
        print("       It may appear in a job that provisions nothing; record it in")
        print("       HOST_LIB_FREE with this measurement as the reason.")
        return 0

    detail = next(
        (
            line.strip()
            for line in poisoned.stderr.split("\n")
            if "pkg-config" in line or "panic" in line
        ),
        "",
    )
    print(
        f"PROBE: `zig build {target}` NEEDS host libraries -- it passes with pkg-config and fails without"
    )
    if detail:
        print(f"       {detail}")
    print("       It belongs only in a job that provisions them.")
    return 1


SELF_TEST_PROVISIONED = """
name: probe
jobs:
  provisioned:
    runs-on: ubuntu-latest
    steps:
      - name: Install prerequisites
        run: sudo apt-get install -qq -y libgtk-3-dev
      - name: Build
        run: zig build object-manifest
"""

SELF_TEST_BARE = """
name: probe
jobs:
  bare:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: zig build object-manifest
"""

SELF_TEST_ALLOWED = """
name: probe
jobs:
  bare:
    runs-on: ubuntu-latest
    steps:
      - name: Unit tests
        run: zig build test:unit
"""

SELF_TEST_COMMENT = """
name: probe
jobs:
  bare:
    runs-on: ubuntu-latest
    steps:
      - name: Prose only
        run: |
          # the lane list comes from `zig build --help`, so this needs the toolchain
          python3 .github/project/check-parity-lanes-gated.py --repo-root .
"""

SELF_TEST_MSYS2 = """
name: probe
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: msys2/setup-msys2@66cd2cce69caa17b53920067426061ca1de3a884
      - name: Build
        run: zig build both
"""


def self_test(_repo_root: Path) -> int:
    cases = [
        ("a provisioned job may build anything", SELF_TEST_PROVISIONED, 0),
        ("a bare job may not", SELF_TEST_BARE, 1),
        ("a bare job may run a probed host-lib-free target", SELF_TEST_ALLOWED, 0),
        ("a `zig build` inside a comment is prose", SELF_TEST_COMMENT, 0),
        ("msys2 counts as provisioning", SELF_TEST_MSYS2, 0),
    ]
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        fake = Path(tmp)
        (fake / WORKFLOWS).mkdir(parents=True)
        target = fake / WORKFLOWS / "probe.yml"
        for label, document, expected in cases:
            target.write_text(document, encoding="utf-8")
            violations, _ = audit(fake)
            actual = 1 if violations else 0
            if actual != expected:
                print(f"SELF-TEST FAIL: {label} (expected {expected}, got {actual})")
                failures += 1
            else:
                print(f"  ok   {label}")

    print()
    if failures:
        print(f"SELF-TEST: {failures} failure(s)")
        return 1
    print("SELF-TEST: the gate fires on an unprovisioned build and passes the rest")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--probe", metavar="TARGET")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    if args.self_test:
        return self_test(repo_root)
    if args.probe:
        return probe(repo_root, args.probe)
    return check(repo_root)


if __name__ == "__main__":
    sys.exit(main())
