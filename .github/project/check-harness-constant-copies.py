#!/usr/bin/env python3
"""A constant hand-copied into a harness header is a frozen oracle one level down.

WHY THIS EXISTS (REPORT-31 M31-9 step 4). REPORT-31's rule is that a parity oracle
must be COMPILED FROM c43 source, because a hand-transliterated one cannot see c43
move -- the lane stays green and manufactures positive evidence that parity holds.
Converting the oracles does not finish the job: the harness HEADER around an oracle
carries constants too, and a hand-copied `#define`/enum value is the same defect at
a smaller scale. When c43 renumbers a flag, widens an error code or reorganizes an
enum block, a copy in `build/tests/<lane>/c47.h` stays put and the lane goes on
agreeing with an unported owner.

That is not hypothetical. `build/tests/stack_state/c47.h` carries

    FIRST_NAMED_RESERVED_VARIABLE = 2026,

which c43 moved to 2031 when it inserted five RESERVED_VARIABLE_SPARE placeholders.
Two models of the reserved-variable block coexist in the tree, and this copy is one
of the places the stale one lives.

WHAT THIS GATE DOES. It extracts every constant a z47-owned harness header declares
by hand -- object-like `#define`s and `enum` members -- and compiles one
`_Static_assert` per name against c43's own headers. Three outcomes:

  * the name is NOT declared by c43        -> harness-local, not a copy, ignored
  * declared by c43 with the SAME value    -> a COPY: correct today, frozen forever
  * declared by c43 with a DIFFERENT value -> a DRIFTED copy: already wrong

Compiling rather than regexing is deliberate and is the lesson from the softmenu
audits: enum members carry implicit values, `#define`s reference each other, and
only the compiler knows what `FIRST_NAMED_RESERVED_VARIABLE` actually is on each
side.

WHY A BASELINE AND NOT A HARD ZERO. Measured on the day this landed, the tree
carries hundreds of such copies across a dozen harness headers -- far past the
~20 that REPORT-31 M31-9 set as the point to stop and report rather than fix. So
this ships as a RATCHET: the recorded per-file counts may fall and may not rise,
and any DRIFTED copy fails outright regardless of the baseline, because a drifted
copy is a live wrong answer rather than a latent one. The fix for the backlog is
not to edit these headers one by one -- it is `build/tests/c43_oracle.zig`, which
lets a lane compile against upstream's own `c47.h` and declare no constants at all.

THREE CATEGORIES, NOT TWO. A harness value that disagrees with c43 is either a
stale copy (`drifted` -- a wrong answer, ratcheted, meant to reach zero) or a
design decision (`deliberate` -- the harness must disagree, and says why). Keeping
them in one column makes a decision indistinguishable from a defect, so the two
are separate here. `deliberate` is hand-authored, survives `--bump`, and every
entry must carry a reason: a deliberate divergence with a stated reason is a
decision, one without is a stale copy that learned to hide.

Usage:
  check-harness-constant-copies.py [--repo-root .]
  check-harness-constant-copies.py --bump        # re-record counts after removing copies
  check-harness-constant-copies.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from upstream_paths import upstream_path

BASELINE = ".github/project/harness-constant-copy-baseline.json"

TRACKED_GLOBS = ("build/**/*.h", "bridge/**/*.h")

# Object-like #define with a replacement list. A VALUELESS define is skipped on
# purpose: that is an include guard or a feature switch, not a copied constant --
# and it is what keeps the deliberate `#define C47_H` guard-claim out of the report.
DEFINE_RE = re.compile(r"^[ \t]*#[ \t]*define[ \t]+([A-Za-z_]\w*)[ \t]+(\S.*?)[ \t]*$", re.M)

# Comments are stripped before scanning so a commented-out constant is not a finding.
BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
LINE_COMMENT_RE = re.compile(r"//[^\n]*")

ENUM_HEAD_RE = re.compile(r"\benum\b[^{;]*\{")
ENUM_MEMBER_RE = re.compile(r"([A-Za-z_]\w*)[ \t]*(?:=[ \t]*([^,}]+?))?[ \t]*(?:,|$)", re.M)

INT_LITERAL_RE = re.compile(r"^[+-]?(?:0[xX][0-9a-fA-F]+|\d+)[uUlL]*$")


def as_int_literal(text: str) -> str | None:
    """Normalise a C integer literal to a decimal string, or None if it is not one.

    The `u`/`l` suffixes have to come off before int(): they are part of C's
    grammar, not Python's, and a `65535u` that raised here would otherwise take the
    whole gate down on a file it was only meant to skip.
    """
    if not INT_LITERAL_RE.match(text):
        return None
    return str(int(text.rstrip("uUlL"), 0))


# The same prelude a compiled-from-c43 UNIT oracle uses: upstream's own c47.h, the
# vendored decNumber headers, the generated constant pointers, and the six
# placeholder GTK/glib/cairo typedefs (build/tests/common). The include roots below
# are kept identical to build/tests/c43_oracle.zig's addUpstreamHeaderRoots on
# purpose, and this gate is currently the only thing that EXERCISES them -- the
# three conversions after M31-9 all took the full-core shape. If the two drift,
# this gate is measuring a configuration of c43 no lane could compile.
PRELUDE = '#include "c47.h"\n'


def strip_comments(text: str) -> str:
    return LINE_COMMENT_RE.sub("", BLOCK_COMMENT_RE.sub("", text))


def enum_bodies(text: str) -> list[str]:
    """Return the body of every `enum ... { ... }` block, brace-matched."""
    bodies = []
    for head in ENUM_HEAD_RE.finditer(text):
        depth = 1
        i = head.end()
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        bodies.append(text[head.end() : i - 1])
    return bodies


def extract_constants(text: str) -> dict[str, str | None]:
    """{name: int-literal-value or None} for every constant declared by hand."""
    found: dict[str, str | None] = {}
    clean = strip_comments(text)

    for name, replacement in DEFINE_RE.findall(clean):
        value = replacement.strip().strip("()").strip()
        found.setdefault(name, as_int_literal(value))

    for body in enum_bodies(clean):
        for name, value in ENUM_MEMBER_RE.findall(body):
            value = value.strip()
            found.setdefault(name, as_int_literal(value))

    return found


def tracked_headers(repo: Path) -> list[Path]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", *TRACKED_GLOBS],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    return [repo / p for p in out]


def classify(repo: Path, zig: str, candidates: list[tuple[str, str | None]]) -> tuple[set, dict]:
    """Compile one _Static_assert per (name, value) candidate against c43's headers.

    Returns (undeclared_names, {candidate_index: failed_requirement_text}).
    A candidate with no integer literal gets a tautological assert, so it only
    reports whether c43 declares the name at all.

    The assert MESSAGE carries the candidate index, not just the name: two harness
    headers may copy the same constant at different values, and reporting by name
    alone would silently collapse them into one verdict.
    """
    tmp = Path(tempfile.mkdtemp())
    src = tmp / "harness_constant_copies.c"
    with src.open("w") as f:
        f.write(PRELUDE)
        for index, (name, value) in enumerate(candidates):
            rhs = value if value is not None else f"({name})"
            f.write(f'_Static_assert(({name}) == ({rhs}), "{index}|{name}");\n')

    proc = subprocess.run(
        [
            zig,
            "cc",
            "-c",
            # Same reason audit-constant-parity.py needs it: clang's 20-error cap
            # would truncate the report at the first score of harness-local names.
            "-ferror-limit=0",
            "-DPC_BUILD=1",
            "-DLINUX=1",
            "-DOS64BIT=1",
            "-I",
            str(repo / "build/tests/common"),
            "-I",
            str(upstream_path(repo, "dep/decNumberICU")),
            "-I",
            str(upstream_path(repo, "src/generated")),
            "-I",
            str(upstream_path(repo, "src/c47")),
            str(src),
            "-o",
            str(tmp / "harness_constant_copies.o"),
        ],
        capture_output=True,
        text=True,
    )
    err = proc.stderr

    undeclared = set(re.findall(r"use of undeclared identifier '([A-Za-z_0-9]+)'", err))
    diverged = {}
    for requirement, index, _name in re.findall(
        r"static assertion failed due to requirement '(.*?)': (\d+)\|([A-Za-z_0-9]+)", err
    ):
        diverged[int(index)] = requirement
    return undeclared, diverged


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record the per-file counts")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    zig = shutil.which("zig")
    if not zig:
        print("check-harness-constant-copies: SKIP -- zig not on PATH")
        return 0

    headers = tracked_headers(repo)
    if not headers:
        print("check-harness-constant-copies: BROKEN -- found no tracked harness headers.")
        return 1

    # Every (header, name) pair is kept -- the per-file counts are the ratchet, so
    # collapsing a name that two headers both copy would make removing it from one
    # of them look like an increase in the other.
    owners: list[tuple[str, str, str | None]] = []
    for header in headers:
        rel = header.relative_to(repo).as_posix()
        for name, value in sorted(extract_constants(header.read_text(errors="replace")).items()):
            owners.append((rel, name, value))

    # One assert per DISTINCT (name, value): the compile is the expensive part and
    # the verdict depends only on the pair, not on which header wrote it.
    candidates: list[tuple[str, str | None]] = []
    candidate_index: dict[tuple[str, str | None], int] = {}
    for _rel, name, value in owners:
        key = (name, value)
        if key not in candidate_index:
            candidate_index[key] = len(candidates)
            candidates.append(key)

    if args.self_test:
        # The gate fires when a harness constant disagrees with c43. Prove it with a
        # value c43 cannot possibly hold, through the SAME compile path as a real run.
        undeclared, diverged = classify(repo, zig, [("REGISTER_X", "424242")])
        if 0 in diverged:
            print("check-harness-constant-copies: SELF-TEST OK -- a wrong value is detected")
            return 0
        print("check-harness-constant-copies: SELF-TEST FAILED -- a wrong value went unseen")
        print(f"  undeclared={sorted(undeclared)} diverged={diverged}")
        return 1

    undeclared, diverged = classify(repo, zig, candidates)

    per_file: dict[str, list[str]] = {}
    drifted: list[tuple[str, str, str]] = []
    for rel, name, value in owners:
        if name in undeclared:
            continue
        per_file.setdefault(rel, []).append(name)
        index = candidate_index[(name, value)]
        if index in diverged:
            drifted.append((rel, name, diverged[index]))

    counts = {rel: len(names) for rel, names in sorted(per_file.items())}
    total = sum(counts.values())

    # DELIBERATE divergences are hand-authored and survive --bump. A harness may
    # legitimately disagree with c43 -- build/tests/memory/c47.h shrinks
    # RAM_SIZE_IN_BLOCKS to 64 so the lane's pool fits a test binary, and setting
    # it to 65534 would not be a fix. Recording that as `drifted` put a design
    # decision in the same column as twenty stale copies, so it was re-counted and
    # re-explained on every pass. It is its own category now, and it costs a
    # written reason: a deliberate divergence with a stated reason is a decision,
    # one without is a stale copy that learned to hide.
    existing = {}
    baseline_file = repo / BASELINE
    if baseline_file.is_file():
        existing = json.loads(baseline_file.read_text(encoding="utf-8"))
    deliberate: dict[str, dict[str, str]] = existing.get("deliberate", {})

    def is_deliberate(rel: str, name: str) -> bool:
        return name in deliberate.get(rel, {})

    drifted_by_file: dict[str, list[str]] = {}
    for rel, name, _requirement in drifted:
        if is_deliberate(rel, name):
            continue
        drifted_by_file.setdefault(rel, []).append(name)

    if args.bump:
        (repo / BASELINE).write_text(
            json.dumps(
                {
                    "_why": (
                        "REPORT-31 M31-9. Per-file count of c43 constants a z47 harness"
                        " header declares by hand. These are frozen references one level"
                        " below a frozen oracle: correct today, unable to move when c43"
                        " moves. The ratchet allows a count to FALL and never to rise;"
                        " the fix is build/tests/c43_oracle.zig, which lets a lane compile"
                        " against upstream's own c47.h and declare nothing."
                    ),
                    "_drifted": (
                        "Copies whose value ALREADY disagrees with c43, measured 2026-08-03."
                        " Recorded rather than fixed: REPORT-31 M31-9 set ~20 as the point to"
                        " stop and report instead of fixing, and this is 64 across 6 headers,"
                        " which is a finding about the harness layer and not part of that"
                        " milestone. Each run reprints them. A drifted name NOT on this list"
                        " fails the gate. Most of them are a mock header inventing its own"
                        " compact numbering for a c43 enum (keyboard_state's CM_*/ITM_*,"
                        " math_wrappers' ERROR_*), which the conversions delete outright."
                    ),
                    "_deliberate": (
                        "Divergences from c43 that are DESIGN DECISIONS, not stale copies,"
                        " each with the reason it is one. Hand-authored: --bump preserves"
                        " this map and never adds to it. An entry with an empty reason"
                        " FAILS the gate."
                    ),
                    "counts": counts,
                    "deliberate": deliberate,
                    "drifted": {
                        rel: sorted(names) for rel, names in sorted(drifted_by_file.items())
                    },
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        print(
            f"check-harness-constant-copies: recorded {total} copies across {len(counts)}"
            f" headers, {sum(len(n) for n in drifted_by_file.values())} of them already"
            f" drifted, {sum(len(d) for d in deliberate.values())} deliberate"
        )
        return 0

    baseline_path = repo / BASELINE
    if not baseline_path.is_file():
        print(f"check-harness-constant-copies: BROKEN -- missing {BASELINE}. Run --bump.")
        return 1
    recorded = json.loads(baseline_path.read_text(encoding="utf-8"))
    baseline = recorded.get("counts", {})
    recorded_drift = {rel: set(names) for rel, names in recorded.get("drifted", {}).items()}

    problems: list[str] = []
    for rel, count in sorted(counts.items()):
        allowed = baseline.get(rel)
        if allowed is None:
            problems.append(
                f"{rel}: {count} c43 constant(s) hand-declared in a harness header that had none.\n"
                f"    Copied names: {', '.join(sorted(per_file[rel])[:12])}\n"
                f"    A copy cannot move when c43 moves. Use build/tests/c43_oracle.zig\n"
                f"    (addUpstreamHeaderRoots) and include c43's own headers instead."
            )
        elif count > allowed:
            problems.append(
                f"{rel}: hand-declared c43 constants rose {allowed} -> {count}.\n"
                f"    This ratchet only goes down. See build/tests/c43_oracle.zig."
            )

    for rel, name, requirement in sorted(drifted):
        if is_deliberate(rel, name):
            continue
        if name in recorded_drift.get(rel, set()):
            continue
        problems.append(
            f"{rel}: {name} has ALREADY DRIFTED from c43 -- requirement {requirement}.\n"
            f"    This is not a latent copy, it is a wrong value the harness asserts as\n"
            f"    c43's. Fix it at the source: include c43's header instead of copying."
        )

    # A deliberate divergence earns its exemption with a written reason. Without
    # one it is indistinguishable from the stale copies it sits beside.
    for rel, names in sorted(deliberate.items()):
        for name, reason in sorted(names.items()):
            if not str(reason).strip():
                problems.append(
                    f"{rel}: {name} is listed as a DELIBERATE divergence with no reason.\n"
                    f"    Write why the harness must disagree with c43 here, or move it\n"
                    f"    back to `drifted` and fix it."
                )

    real_drift = [(r, n, q) for r, n, q in drifted if not is_deliberate(r, n)]
    deliberate_seen = [(r, n, q) for r, n, q in drifted if is_deliberate(r, n)]

    print(
        f"check-harness-constant-copies: {len(candidates)} distinct (name, value) pairs scanned"
        f" across {len(headers)} harness headers"
    )
    print(f"  {len(undeclared)} harness-local (c43 does not declare them)")
    print(f"  {total} are copies of a c43 constant, across {len(counts)} headers")
    print(f"  {len(real_drift)} of those already disagree with c43's value:")
    for rel, name, requirement in sorted(real_drift):
        status = "recorded" if name in recorded_drift.get(rel, set()) else "NEW"
        print(f"    [{status}] {rel}: {name}  c43 vs harness {requirement}")
    if deliberate_seen:
        print(f"  {len(deliberate_seen)} diverge DELIBERATELY, each with a stated reason:")
        for rel, name, requirement in sorted(deliberate_seen):
            print(f"    [deliberate] {rel}: {name}  c43 vs harness {requirement}")
            print(f"                 {deliberate[rel][name]}")

    if problems:
        print("\nHARNESS CONSTANT COPIES:")
        for p in problems:
            print(f"  {p}")
        return 1

    print(
        "\nPASS: no new hand-copied c43 constants and no new drift."
        " The recorded backlog above is REPORT-31 M31-9's measured finding, not a clean bill."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
