#!/usr/bin/env python3
"""A parity lane that cannot fail is not a parity lane. Prove each one bites.

WHY THIS EXISTS. Every probe in the parity harnesses was accepted on the same
criterion: patch a behavioural change into one side, confirm the lane goes red,
revert. That criterion was applied by hand, once, at the moment each probe was
written, and left no record. A lane that silently stopped comparing -- a fixture
that no longer reaches the code, a snapshot field that stopped being read, a
rename that quietly resolved both names to the same symbol -- would keep printing
"all agree" forever, and nothing would notice.

The technique has a name: mutation testing. A mutant is a small, deliberate
behavioural change; a mutant that the test suite fails to detect is a hole in the
suite, not a bug in the code. Here the suite is one differential lane and the
mutants are hand-picked rather than generated, which is the cheap version of the
idea and is enough to answer the question this gate asks: does this lane still
fail when the owner is wrong?

WHAT IT MUTATES, AND WHAT IT MUST NOT. Mutations are applied ONLY to z47's own Zig
owners. Never to c43: the imported tree is the reference, held to the pin by
check-imported-tree-pin.py, and editing it would both break that gate and invert
what the lane is measuring. Never to the harness either -- mutating the test to
see the test fail proves nothing about the code.

The manifest is deliberately small and hand-written. Generated mutants mostly fail
to compile, and the ones that do compile are mostly equivalent to the original, so
a generator spends its time producing noise. One mutation per behaviour that a
lane is supposed to be watching is worth more than a thousand random edits.

A SURVIVOR IS A FINDING, NOT A FAILURE TO CHASE. When a mutant survives, the lane
does not cover that behaviour. Record it in the manifest with `expected_survivor`
and a reason; do not delete the entry, and do not widen the mutation until it
dies. The recorded survivors are the honest statement of what these lanes do not
check.

Usage:
  check-oracle-negative-control.py [--repo-root .]
  check-oracle-negative-control.py --only <lane>   # one lane, for iteration
  check-oracle-negative-control.py --self-test     # prove this gate itself fires
"""

from __future__ import annotations

import argparse
import json
import re
import signal
import subprocess
import sys
from pathlib import Path

MANIFEST = ".github/project/oracle-negative-control.json"
COVERAGE_BASELINE = ".github/project/oracle-negative-control-coverage.json"

# Every file this gate has edited and not yet put back. A `finally` is not enough
# on its own: it runs on an exception, but NOT when the process is killed by a
# signal, and a run under `timeout` is killed by SIGTERM. That is not theoretical
# -- it happened, and it left a mutated owner in the working tree looking exactly
# like a hand edit. SIGTERM and SIGINT are turned into an exit so the restore
# below runs on the way out.
_pending_restores: dict[Path, str] = {}


def _restore_all() -> None:
    while _pending_restores:
        path, original = _pending_restores.popitem()
        try:
            path.write_text(original, encoding="utf-8")
        except OSError as exc:  # pragma: no cover - best effort on the way out
            print(f"check-oracle-negative-control: COULD NOT RESTORE {path}: {exc}")


def _on_signal(signum, _frame):  # pragma: no cover - signal path
    print(f"\ncheck-oracle-negative-control: signal {signum}; restoring mutated files")
    _restore_all()
    sys.exit(128 + signum)


def declared_lane_steps(repo: Path) -> list[str]:
    """The build's own lane list, the same source check-parity-lanes-gated.py uses."""
    completed = subprocess.run(["zig", "build", "--help"], cwd=repo, capture_output=True, text=True)
    if completed.returncode != 0:
        return []
    return sorted(
        set(
            re.findall(
                r"^\s{2}([\w-]+(?:_parity|_oracle|_diff|_suite|-parity))\s", completed.stdout, re.M
            )
        )
    )


def covered_lane_count(entries: list[dict]) -> int:
    return len({entry["step"] for entry in entries})


def uncovered_lanes(repo: Path, entries: list[dict]) -> list[str]:
    covered = {entry["step"] for entry in entries}
    return [lane for lane in declared_lane_steps(repo) if lane not in covered]


def run_lane(repo: Path, step: str) -> int:
    """Build and run one lane; return its exit status.

    The build and the run are one `zig build <step>` because the step already
    depends on its run artifact. A build FAILURE counts as a kill: a mutant that
    does not compile is still a change the lane refused to accept, and reporting
    it as a survivor would be the wrong way round.
    """
    completed = subprocess.run(
        ["zig", "build", step],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    return completed.returncode


def apply_mutation(path: Path, find: str, replace: str) -> str:
    original = path.read_text(encoding="utf-8")
    if find not in original:
        raise LookupError(f"{path}: mutation anchor not found: {find[:60]}")
    if original.count(find) != 1:
        raise LookupError(f"{path}: mutation anchor is not unique: {find[:60]}")
    _pending_restores[path] = original
    path.write_text(original.replace(find, replace), encoding="utf-8")
    return original


def restore(path: Path, original: str) -> None:
    path.write_text(original, encoding="utf-8")
    _pending_restores.pop(path, None)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--only", default=None, help="run a single lane by name")
    ap.add_argument(
        "--bump-coverage", action="store_true", help="re-record which lanes have no mutant"
    )
    ap.add_argument("--self-test", action="store_true", help="prove this gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    signal.signal(signal.SIGTERM, _on_signal)
    signal.signal(signal.SIGINT, _on_signal)

    manifest_path = repo / MANIFEST
    if not manifest_path.is_file():
        print(f"check-oracle-negative-control: BROKEN -- missing {MANIFEST}")
        return 1
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))["mutants"]

    if args.only:
        entries = [e for e in entries if e["lane"] == args.only]
        if not entries:
            print(f"check-oracle-negative-control: no mutant named lane {args.only!r}")
            return 1

    problems: list[str] = []
    survivors: list[str] = []
    killed = 0
    recorded_survivors = 0
    documented = 0

    try:
        for entry in entries:
            path = repo / entry["file"]
            name = f"{entry['lane']}: {entry['what']}"

            # An entry may carry no mutation at all: some lanes have no single
            # owner behaviour to change, and saying so is better than a placeholder
            # that reports SURVIVED for a mutation that never happened.
            if entry.get("no_mutation"):
                documented += 1
                print(f"  documented {name}  [{entry['no_mutation'][:70]}...]")
                continue

            if not path.is_file():
                problems.append(f"{name}: {entry['file']} does not exist")
                continue

            # A lane must be GREEN before it is mutated. Mutating an already-red
            # lane and observing red proves nothing.
            if run_lane(repo, entry["step"]) != 0:
                problems.append(f"{name}: lane {entry['step']} is red BEFORE mutation")
                continue

            try:
                original = apply_mutation(path, entry["find"], entry["replace"])
            except LookupError as exc:
                problems.append(f"{name}: {exc}")
                continue
            status = run_lane(repo, entry["step"])
            restore(path, original)

            if status != 0:
                killed += 1
                print(f"  killed    {name}")
            elif entry.get("expected_survivor"):
                recorded_survivors += 1
                print(f"  SURVIVED  {name}  [recorded: {entry['expected_survivor']}]")
            else:
                survivors.append(f"{name}\n      in {entry['file']}\n      {entry['why']}")
                print(f"  SURVIVED  {name}  <-- NOT RECORDED")
    finally:
        _restore_all()

    print(
        f"check-oracle-negative-control: {killed} mutant(s) killed,"
        f" {recorded_survivors} recorded survivor(s),"
        f" {documented} lane(s) documented as having no single behaviour to mutate"
    )

    # A lane with no mutant cannot produce a finding. Being RUN is not being proven
    # to detect anything, so the lanes still missing one are counted and ratcheted
    # rather than left silent -- a gate that reports only what it checked reads as
    # a clean bill for what it did not.
    if not args.only:
        uncovered = uncovered_lanes(repo, entries)
        coverage_path = repo / COVERAGE_BASELINE
        if args.bump_coverage:
            coverage_path.write_text(
                json.dumps(
                    {
                        "_why": (
                            "Parity lanes with no mutant in oracle-negative-control.json."
                            " They run, but nothing proves they would fail if the owner were"
                            " wrong. The count may FALL and may not rise; the endpoint is an"
                            " empty list."
                        ),
                        "lanes_without_a_mutant": uncovered,
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            print(
                f"check-oracle-negative-control: recorded {len(uncovered)} lane(s) with no mutant"
            )
            return 0
        recorded_uncovered = []
        if coverage_path.is_file():
            recorded_uncovered = json.loads(coverage_path.read_text(encoding="utf-8")).get(
                "lanes_without_a_mutant", []
            )
        print(
            f"  {len(uncovered)} lane(s) still have NO mutant, of {len(uncovered) + covered_lane_count(entries)}:"
        )
        for lane in uncovered:
            print(f"    {lane}")
        new_uncovered = sorted(set(uncovered) - set(recorded_uncovered))
        if new_uncovered:
            problems.append(
                "lane(s) with no mutant that were not on the recorded list:\n"
                f"    {', '.join(new_uncovered)}\n"
                "    A new lane needs a mutant, or this ratchet is meaningless."
            )

    if args.self_test:
        # The gate's own negative control: a mutation the lane cannot possibly
        # detect must be reported as an unrecorded survivor. Changing a comment
        # changes no behaviour, so nothing should catch it -- and if this gate
        # reports it as killed, the gate is measuring the build rather than the
        # lane.
        probe = repo / "src/core/numeric/compare/get_type.zig"
        text = probe.read_text(encoding="utf-8")
        marker = "// calculator the cohort is the displayed trailing digits"
        if marker not in text:
            print("check-oracle-negative-control: SELF-TEST BROKEN -- probe anchor gone")
            return 1
        _pending_restores[probe] = text
        probe.write_text(text.replace(marker, marker + " (self-test)"), encoding="utf-8")
        try:
            status = run_lane(repo, "math_wrappers_full_core_parity")
        finally:
            restore(probe, text)
        if status != 0:
            print("check-oracle-negative-control: SELF-TEST FAILED -- a comment edit went red")
            return 1
        print("check-oracle-negative-control: SELF-TEST OK -- a no-op edit survives, as it must")

    if problems:
        print("\nNEGATIVE CONTROL BROKEN:")
        for problem in problems:
            print(f"  {problem}")
        return 1

    if survivors:
        print("\nMUTANTS SURVIVED -- these lanes do not check what they claim to:")
        for survivor in survivors:
            print(f"  {survivor}")
        print(
            "\nEither the lane needs a case that reaches this behaviour, or the mutant is"
            "\nequivalent to the original and belongs in the manifest as an"
            " `expected_survivor` with a reason."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
