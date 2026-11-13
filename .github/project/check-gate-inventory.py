#!/usr/bin/env python3
"""Every governance script under .github/project/ is run by something, or says why not.

WHY THIS EXISTS. A gate that no workflow runs fires only when a developer chooses
to type `bash .github/project/run-local-gate.sh`. check-parity-lanes-gated.py
exists because parity lanes can be declared, buildable, green and run by nothing;
a governance script can fall into the same state one level up.

The rule: **a check is in force only where it RUNS.** "It is in the local gate" is
a claim about a person's habits; "it is in CI" is a claim about a system. This
gate makes the difference visible and refuses the third state -- a script that is
neither, which is a check nobody runs and which still reads as coverage on the
page that names it.

HOW IT CLASSIFIES. Automatically, from what actually references the script:

  CI      named in .github/workflows/*.yml, or in a CI_RUNNERS script (which a
          workflow runs), or in a build file (which CI builds).
  LOCAL   named in run-local-gate.sh and nowhere above. Allowed ONLY with a
          recorded reason in LOCAL_ONLY, because the endpoint here is not zero:
          some checks genuinely cannot run in CI.
  MANUAL  a maintainer step invoked by a human, allowed only with a reason that
          names the document telling them to.
  TOOL    not a check at all -- a library, generator, refactoring tool, runner, or
          a report that measures without judging. Allowed only with a reason.
  ORPHAN  none of the above. Fails.

WHAT IT DOES NOT CHECK -- stated because this gate is the one that should least
pretend otherwise. It does not know whether a script that IS run is run over the
right inputs, nor whether a workflow that names it is enabled, nor whether a LOCAL
reason is still true, nor whether a MANUAL reason's document still names the
script. It reads the reference, not the intent. The exemption tables are the
second half of it and they rot the way every table rots: an entry whose script is
gone, or whose script has since reached CI, is reported so that the table cannot
outlive its reason.

Usage:
  check-gate-inventory.py [--repo-root .]
  check-gate-inventory.py --list        # print the classification and stop
  check-gate-inventory.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

PROJECT_DIR = ".github/project"
WORKFLOW_GLOB = ".github/workflows/*.yml"
BUILD_GLOBS = ("build.zig", "build/**/*.zig")

# A workflow runs these, so anything they name is in CI transitively. The two
# gates among them delegate their verdict: check-idiom-ratchet.sh to the `--check`
# runs of the idiom and narrowing reporters, and
# check-c-dependency-phase-i-policy.sh to check-c-dependency-allowlist.py.
CI_RUNNERS = (
    "run-host-parity-battery.sh",
    "check-idiom-ratchet.sh",
    "check-c-dependency-phase-i-policy.sh",
)
# A human runs this.
LOCAL_RUNNER = "run-local-gate.sh"

SCRIPT_RE = re.compile(r"[A-Za-z0-9_.-]+\.(?:py|sh)")

# LOCAL, with a reason. The endpoint is not zero and never was: a check that needs
# a full rebuild per case belongs where somebody is already waiting for a build.
LOCAL_ONLY: dict[str, str] = {
    "check-oracle-negative-control.py": (
        "One full rebuild per mutant in oracle-negative-control.json's `mutants`. In"
        " CI that is one build per mutant to prove what one local run proves before"
        " a push. Recorded as a cost, not as an"
        " oversight -- and the lane-coverage half of it (which lanes have no mutant"
        " at all) is a JSON baseline that the reviewer can read without running it."
    ),
}

# Invoked by a person, following a document that says to. The reason must name it.
MANUAL_ONLY: dict[str, str] = {
    "check-local-roadmap-sync.py": (
        "Maintainer step for the local roadmap, documented in"
        " docs/80-maintainer-workflow.md (Local Roadmap Sync Flow), where"
        " CONTRIBUTING.md routes it. It compares tracked docs against an"
        " untracked working roadmap, so CI has nothing to compare against."
    ),
    "check-iteration-report-sections.py": (
        "Maintainer step in docs/80-maintainer-workflow.md (Local Roadmap Sync"
        " Flow): it lints the closure sections of a local iteration report on the"
        " ignored __DEV/ surface, so CI never has the files this reads."
    ),
}

# Not a check. Libraries, generators, refactoring tools, runners, and reports that
# measure without judging.
NOT_A_GATE: dict[str, str] = {
    "upstream_paths.py": "Library: imported by the checks that resolve imported-tree paths.",
    "c_dependency_audit.py": "Library: imported by the C-dependency checks and reports.",
    "lane_vocabulary.py": "Library: imported by check-parity-lanes-gated.py and check-oracle-negative-control.py.",
    "build-correspondence-manifest.py": (
        "Generator: writes upstream-correspondence.tsv, which"
        " check-upstream-correspondence.py then enforces in CI."
    ),
    "move-owners.py": "Refactoring tool: moves owners and rewrites their references.",
    "rename-owner.sh": "Refactoring tool: renames one owner and its build references.",
    "run-local-gate.sh": "Runner: the local pre-push battery this inventory classifies against.",
    "run-host-parity-battery.sh": "Runner: the shared battery CI and the local gate both invoke.",
    "run-upstream-sync-checks.sh": "Runner: the resync helper sequence, invoked during a sync.",
    "run-upstream-reportgap-dryrun.sh": "Runner: dry-run helper for the upstream report gap.",
    "audit-saveload-field-coverage.py": (
        "Report: classifies every saved calc-state field by where it is assigned"
        " (RESET-DIRECT / CONFIG-DRIVEN / neither) so a human can see which ones the"
        " golden may pin uninitialised memory for. It always exits 0: a"
        " classification is not a verdict, and gating it would invent one."
    ),
    "report-c-dependency-status.py": "Report: prints the C-dependency picture the Phase I policy gates.",
    "report-firmware-host-gap.py": "Report: prints where the firmware and host builds differ.",
    "report-resync-worklist.py": (
        "Report: names the owner of every C file a resync range changes; the"
        " runbook's first step, run by hand during a sync."
    ),
    "report-zig-coverage.sh": (
        "Report: symbolizes the coverage build's PCs into owner lines;"
        " check-coverage-ratchet.sh gates the floor."
    ),
}


def scripts(repo: Path) -> list[str]:
    return sorted(
        p.name for p in (repo / PROJECT_DIR).iterdir() if p.suffix in (".py", ".sh") and p.is_file()
    )


ZIG_SCRIPT_PATH_RE = re.compile(r"\.github/project/([A-Za-z0-9_.-]+\.(?:py|sh))")


def live_text(path: Path) -> str:
    """The text of `path` that can run something: comments dropped. A script a
    workflow only mentions in a comment is not run by it."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix == ".zig":
        return "\n".join(line.split("//", 1)[0] for line in text.splitlines())
    return "\n".join(re.sub(r"(^|\s)#.*$", "", line) for line in text.splitlines())


def referenced(repo: Path, paths: list[Path]) -> set[str]:
    names: set[str] = set()
    for path in paths:
        if not path.is_file():
            continue
        text = live_text(path)
        # A build file runs a script by its path; a bare name there is prose, as in
        # a step's help text.
        pattern = ZIG_SCRIPT_PATH_RE if path.suffix == ".zig" else SCRIPT_RE
        names.update(pattern.findall(text))
    return names


def classify(
    all_scripts: list[str],
    ci_names: set[str],
    local_names: set[str],
    local_only: dict[str, str],
    manual_only: dict[str, str],
    not_a_gate: dict[str, str],
) -> tuple[dict[str, str], list[str]]:
    """(script -> verdict, problems). Pure, so the self-test can drive it."""
    verdicts: dict[str, str] = {}
    problems: list[str] = []

    for name in all_scripts:
        if name in ci_names:
            verdicts[name] = "CI"
        elif name in not_a_gate:
            verdicts[name] = "TOOL"
        elif name in manual_only:
            verdicts[name] = "MANUAL"
        elif name in local_names:
            verdicts[name] = "LOCAL" if name in local_only else "LOCAL-UNRECORDED"
        else:
            verdicts[name] = "ORPHAN"

    for name, verdict in verdicts.items():
        if verdict == "ORPHAN":
            problems.append(
                f"{name}: run by NOTHING -- not a workflow, not the battery, not the"
                " build, not the local gate. Wire it up, or record it in LOCAL_ONLY /"
                " MANUAL_ONLY / NOT_A_GATE with a reason."
            )
        elif verdict == "LOCAL-UNRECORDED":
            problems.append(
                f"{name}: in the local gate and in no workflow, with no recorded"
                " reason. A check that runs only where a person remembers is a"
                " decision somebody has to make on purpose."
            )

    # The tables rot too. An entry whose script is gone, or which has since reached
    # CI, is a plausible sentence outliving the thing it justified.
    present = set(all_scripts)
    for table_name, table in (
        ("LOCAL_ONLY", local_only),
        ("MANUAL_ONLY", manual_only),
        ("NOT_A_GATE", not_a_gate),
    ):
        for name, reason in table.items():
            if name not in present:
                problems.append(f"{table_name}[{name}]: no such script. Stale exemption.")
            elif name in ci_names and table_name != "NOT_A_GATE":
                problems.append(
                    f"{table_name}[{name}]: this script IS in CI now. Delete the"
                    " exemption rather than leaving a reason that no longer applies."
                )
            elif not reason.strip():
                problems.append(f"{table_name}[{name}]: exempt with an empty reason.")

    return verdicts, problems


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--list", action="store_true", help="print the classification and stop")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()

    if args.self_test:
        _, problems = classify(["a.py"], set(), set(), {}, {}, {})
        if not problems:
            print("check-gate-inventory: SELF-TEST FAILED -- a script run by nothing passed")
            return 1
        _, problems = classify(["a.py"], set(), {"a.py"}, {}, {}, {})
        if not problems:
            print("check-gate-inventory: SELF-TEST FAILED -- an unrecorded local-only gate passed")
            return 1
        _, problems = classify([], set(), set(), {"gone.py": "reason"}, {}, {})
        if not problems:
            print(
                "check-gate-inventory: SELF-TEST FAILED -- an exemption for a deleted script passed"
            )
            return 1
        _, problems = classify(["a.py"], {"a.py"}, set(), {"a.py": "reason"}, {}, {})
        if not problems:
            print("check-gate-inventory: SELF-TEST FAILED -- an exemption for a CI gate passed")
            return 1
        _, problems = classify(["a.py"], {"a.py"}, set(), {}, {}, {})
        if problems:
            print("check-gate-inventory: SELF-TEST FAILED -- a gate in CI was reported")
            return 1
        print(
            "check-gate-inventory: SELF-TEST OK (an orphan, an unrecorded local gate, a"
            " stale exemption and a redundant exemption all fire; a gate in CI does not)"
        )
        return 0

    repo = Path(args.repo_root).resolve()
    ci_sources = sorted(repo.glob(WORKFLOW_GLOB))
    ci_sources += [repo / PROJECT_DIR / runner for runner in CI_RUNNERS]
    for pattern in BUILD_GLOBS:
        ci_sources += sorted(repo.glob(pattern))
    ci_names = referenced(repo, ci_sources)
    local_names = referenced(repo, [repo / PROJECT_DIR / LOCAL_RUNNER])

    all_scripts = scripts(repo)
    verdicts, problems = classify(
        all_scripts, ci_names, local_names, LOCAL_ONLY, MANUAL_ONLY, NOT_A_GATE
    )

    tally: dict[str, int] = {}
    for verdict in verdicts.values():
        tally[verdict] = tally.get(verdict, 0) + 1
    summary = ", ".join(f"{tally[k]} {k}" for k in sorted(tally))
    print(f"check-gate-inventory: {len(all_scripts)} script(s) -- {summary}")

    if args.list:
        for name in all_scripts:
            print(f"    {verdicts[name]:<17} {name}")
        return 0

    if problems:
        print("\nGOVERNANCE SCRIPTS NOBODY RUNS:")
        for problem in problems:
            print(f"  {problem}")
        print(
            "\nA gate that is in no workflow fires only when somebody remembers, and a"
            "\nreport that says it ran is then a claim about that person."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
