#!/usr/bin/env python3
"""Every governance script under .github/project/ is run by something, or says why not.

WHY THIS EXISTS. REPORT-31 built nine gates. Measured in Annex N, **six of them ran
in no CI workflow at all** -- they fired only when a developer chose to type
`bash .github/project/run-local-gate.sh`. One of the six was
`check-parity-lanes-gated.py`, which exists because four parity lanes were declared,
buildable, green and run by nothing. The same defect, one level up, inside the
instrument built to stop it.

That is standing clause 7: **a check is in force only where it RUNS.** "It is in the
local gate" is a claim about a person's habits; "it is in CI" is a claim about a
system. This gate makes the difference visible and refuses the third state -- a
script that is neither, which is a check nobody runs and which still reads as
coverage on the page that names it.

HOW IT CLASSIFIES. Automatically, from what actually references the script:

  CI      named in .github/workflows/*.yml, or in run-host-parity-battery.sh
          (which a workflow runs), or in a build file (which CI builds).
  LOCAL   named in run-local-gate.sh and nowhere above. Allowed ONLY with a
          recorded reason in LOCAL_ONLY, because the endpoint here is not zero:
          some checks genuinely cannot run in CI.
  MANUAL  a maintainer step invoked by a human, allowed only with a reason that
          names the document telling them to.
  TOOL    not a check at all -- a library, generator, refactoring tool, runner, or
          a report that measures without judging. Allowed only with a reason.
  ORPHAN  none of the above. Fails.

WHAT IT DOES NOT CHECK -- stated per clause 6, because this gate is the one that
should least pretend otherwise. It does not know whether a script that IS run is
run over the right inputs, nor whether a workflow that names it is enabled, nor
whether a LOCAL reason is still true. It reads the reference, not the intent. The
exemption tables are the second half of it and they rot the way every table rots:
an entry whose script is gone, or whose script has since reached CI, is reported so
that the table cannot outlive its reason -- pass 9 lost a whole seam to a plausible
sentence attached to a file that no longer justified it.

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

# A workflow runs this, so anything it names is in CI transitively.
CI_RUNNERS = ("run-host-parity-battery.sh",)
# A human runs this.
LOCAL_RUNNER = "run-local-gate.sh"

SCRIPT_RE = re.compile(r"[A-Za-z0-9_.-]+\.(?:py|sh)")

# LOCAL, with a reason. The endpoint is not zero and never was: a check that needs
# a full rebuild per case belongs where somebody is already waiting for a build.
LOCAL_ONLY: dict[str, str] = {
    "check-oracle-negative-control.py": (
        "One full rebuild per mutant, 36 mutants. In CI that is 36 builds to prove"
        " what one local run proves before a push. Recorded as a cost, not as an"
        " oversight -- and the lane-coverage half of it (which lanes have no mutant"
        " at all) is a JSON baseline that the reviewer can read without running it."
    ),
}

# Invoked by a person, following a document that says to. The reason must name it.
MANUAL_ONLY: dict[str, str] = {
    "check-local-roadmap-sync.py": (
        "Maintainer step for the local roadmap, documented in CONTRIBUTING.md and"
        " docs/80-maintainer-workflow.md. It compares tracked docs against an"
        " untracked working roadmap, so CI has nothing to compare against."
    ),
    "check-retained-bridge-ledger.py": (
        "Maintainer step documented in docs/10, docs/70 and docs/80: it reviews the"
        " retained C bridge ledger, a judgement about what SHOULD still be C, which"
        " is a decision to make rather than an invariant to enforce."
    ),
    "check-iteration-report-sections.py": (
        "Lints the section structure of __DEV/ iteration reports. __DEV/ is"
        " gitignored, so CI never has the files this reads."
    ),
    "audit-saveload-field-coverage.py": (
        "Run when the calc-state golden changes. It CLASSIFIES every saved field by"
        " where it is assigned (RESET-DIRECT / CONFIG-DRIVEN / neither) so a human"
        " can see which ones the golden is pinning uninitialised memory for. A"
        " classification is not a verdict and gating it would invent one."
    ),
}

# Not a check. Libraries, generators, refactoring tools, runners, and reports that
# measure without judging.
NOT_A_GATE: dict[str, str] = {
    "upstream_paths.py": "Library: imported by the checks that resolve imported-tree paths.",
    "c_dependency_audit.py": "Library: imported by the C-dependency checks and reports.",
    "retained_bridge_review.py": "Library: imported by check-retained-bridge-ledger.py.",
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
    "report-idiom-status.py": "Report: prints the idiom metrics that check-idiom-ratchet.sh gates.",
    "report-narrowing-status.py": "Report: prints the narrowing metrics behind the ratchet.",
    "report-c-dependency-status.py": "Report: prints the C-dependency picture the Phase I policy gates.",
    "report-firmware-host-gap.py": "Report: prints where the firmware and host builds differ.",
}


def scripts(repo: Path) -> list[str]:
    return sorted(
        p.name for p in (repo / PROJECT_DIR).iterdir() if p.suffix in (".py", ".sh") and p.is_file()
    )


def referenced(repo: Path, paths: list[Path]) -> set[str]:
    names: set[str] = set()
    for path in paths:
        if path.is_file():
            names.update(SCRIPT_RE.findall(path.read_text(encoding="utf-8", errors="replace")))
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
            "\nreport that says it ran is then a claim about that person. Clause 7."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
