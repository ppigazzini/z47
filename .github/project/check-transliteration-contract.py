#!/usr/bin/env python3
"""Transliteration-contract gate (REPORT-28 s41).

WHAT THIS PROTECTS, AND WHY IT LOOKS BACKWARDS

Every large z47 owner is a 1:1 port of a same-named upstream C file of near
identical size: screen.zig 6334 lines against screen.c 6623, items.zig 4699
against items.c 4734. Ordinary judgement says a 6000-line file is a design
failure to be split. Here that judgement is WRONG, and measurably so.

Those files are exactly the hot ones. Measured over two years of upstream
history: items.c 551 commits (the hottest file in the repository), softmenus.c
424, screen.c 345, addons.c 198. The 1:1 file shape is what lets a maintainer
apply an upstream C diff textually, and z47 re-syncs constantly -- every resync
re-ports behavioural changes concentrated in precisely these files. Splitting
screen.zig into eight cohesive owners would look like an architecture win and
would silently make every future resync a manual reconstruction.

So this gate encodes the rule from PROMPT.md: file shape is a per-file trade
against that file's churn, not an all-or-nothing style. Hot files stay
transliterated. Cold files may be idiomatised freely -- their parity oracle
proves the re-sync. This gate constrains ONLY the hot, 1:1 files; it says
nothing about the rest of the tree.

WHAT IT CHECKS. For each pinned pair: the z47 owner still exists, and its size
still tracks the C original. A collapsing ratio means the owner was split or
gutted -- the sync contract broken -- even though the code would still compile
and every test would still pass. Nothing else catches that.

NOT CHECKED HERE: files z47 has already decomposed by deliberate decision
(registers.c -> 18 owners, matrix.c -> 54, keyboard.c -> 7, solve.c -> 8). They
are not 1:1 and this gate has no opinion on them.

CHURN IS PINNED, NOT RECOMPUTED. Churn needs the upstream history, which is a
sibling checkout that CI does not have. It is measured at --bump time and
recorded below as the justification for each entry; enforcement uses only files
in this repo. Re-pin after an upstream resync, when the C side legitimately
moves: check-transliteration-contract.py --bump

Usage: check-transliteration-contract.py [--repo-root .] [--bump]
"""

import argparse
import json
import os
import subprocess
import sys

BASELINE = ".github/project/transliteration-contract-baseline.json"

# A port may drift this far from its pinned ratio before we call it a split.
# Sized to absorb normal per-resync churn while still catching a file being
# gutted: the smallest real decomposition in this tree took its root to 0.11 of
# the C, far outside any plausible drift band.
TOLERANCE = 0.20

# Upstream commits (2 years) at or above which a file counts as hot enough that
# 1:1 shape is worth freezing.
HOT_MIN_CHURN = 50

# Below this the port is not 1:1 -- z47 decomposed it deliberately, so the
# contract does not apply and the pair is not pinned.
ONE_TO_ONE_MIN_RATIO = 0.60


def count_lines(path):
    with open(path, "rb") as fh:
        return sum(1 for _ in fh)


def measure_churn(repo_root, since="2024-07-01"):
    """2-year commit counts per upstream C file, from the sibling checkout."""
    sibling = os.path.join(repo_root, "..", "c43")
    if not os.path.isdir(os.path.join(sibling, ".git")):
        sys.exit(
            "--bump needs the upstream checkout at ../c43 to measure churn.\n"
            "It is only required to re-pin; enforcement does not use it."
        )
    out = subprocess.run(
        ["git", "-C", sibling, "log", f"--since={since}",
         "--name-only", "--pretty=format:", "--", "src/"],
        capture_output=True, text=True, check=True,
    ).stdout
    churn = {}
    for line in out.split():
        if line.endswith(".c"):
            churn[line] = churn.get(line, 0) + 1
    return churn


def zig_owners_by_stem(repo_root):
    owners = {}
    for dirpath, _, names in os.walk(os.path.join(repo_root, "zig_src")):
        for name in names:
            if name.endswith(".zig"):
                rel = os.path.relpath(os.path.join(dirpath, name), repo_root)
                owners.setdefault(name[:-4], []).append(rel)
    return owners


def bump(repo_root):
    churn = measure_churn(repo_root)
    owners = zig_owners_by_stem(repo_root)
    entries = []
    for c_path, commits in sorted(churn.items(), key=lambda kv: -kv[1]):
        if commits < HOT_MIN_CHURN:
            continue
        abs_c = os.path.join(repo_root, c_path)
        if not os.path.isfile(abs_c):
            continue
        candidates = owners.get(os.path.basename(c_path)[:-2], [])
        if not candidates:
            continue  # ported under another name, or decomposed
        zig_rel = sorted(candidates)[0]
        c_lines = count_lines(abs_c)
        zig_lines = count_lines(os.path.join(repo_root, zig_rel))
        ratio = zig_lines / c_lines if c_lines else 0.0
        if ratio < ONE_TO_ONE_MIN_RATIO:
            continue  # deliberately decomposed; not a 1:1 contract
        entries.append({
            "c": c_path,
            "zig": zig_rel,
            "upstream_commits_2yr": commits,
            "c_lines": c_lines,
            "zig_lines": zig_lines,
            "ratio": round(ratio, 3),
        })
    doc = {
        "note": (
            "REPORT-28 s41. Hot upstream C files (>=%d commits/2yr) ported 1:1 to a "
            "same-named z47 owner. The 1:1 shape is what lets a maintainer apply an "
            "upstream diff textually, and these are the files upstream actually "
            "changes -- so their size is a SYNC CONTRACT, not a code smell to split. "
            "Enforcement checks the owner still exists and still tracks the C size "
            "within %.2f; churn is pinned here because CI has no upstream checkout. "
            "Re-pin after a resync with --bump." % (HOT_MIN_CHURN, TOLERANCE)
        ),
        "tolerance": TOLERANCE,
        "pairs": entries,
    }
    with open(os.path.join(repo_root, BASELINE), "w") as fh:
        json.dump(doc, fh, indent=2)
        fh.write("\n")
    print(f"check-transliteration-contract: re-pinned {len(entries)} 1:1 hot ports")


def enforce(repo_root):
    path = os.path.join(repo_root, BASELINE)
    if not os.path.isfile(path):
        sys.exit(f"missing baseline {BASELINE} (create it with --bump)")
    with open(path) as fh:
        doc = json.load(fh)
    pairs = doc["pairs"]
    if not pairs:
        sys.exit("check-transliteration-contract: BROKEN -- baseline pins no pairs.")
    tolerance = doc.get("tolerance", TOLERANCE)

    failures = []
    for entry in pairs:
        abs_zig = os.path.join(repo_root, entry["zig"])
        abs_c = os.path.join(repo_root, entry["c"])
        if not os.path.isfile(abs_zig):
            failures.append(
                f"{entry['zig']} is GONE -- it is the 1:1 port of {entry['c']} "
                f"({entry['upstream_commits_2yr']} upstream commits/2yr)"
            )
            continue
        if not os.path.isfile(abs_c):
            failures.append(f"{entry['c']} is gone from the imported tree; re-pin with --bump")
            continue
        c_lines = count_lines(abs_c)
        zig_lines = count_lines(abs_zig)
        ratio = zig_lines / c_lines if c_lines else 0.0
        if ratio < entry["ratio"] - tolerance:
            failures.append(
                f"{entry['zig']} shrank to {ratio:.2f} of {entry['c']} "
                f"(pinned {entry['ratio']:.2f}, now {zig_lines} vs {c_lines} lines) "
                f"-- {entry['upstream_commits_2yr']} upstream commits/2yr"
            )

    if failures:
        print("TRANSLITERATION CONTRACT BROKEN:")
        for f in failures:
            print(f"  {f}")
        print()
        print("These owners are 1:1 ports of the upstream C files that change most.")
        print("Their size is the sync contract: a maintainer applies an upstream diff")
        print("to them textually. Splitting one is invisible to the compiler and to")
        print("every test, and turns each future resync into a manual reconstruction.")
        print("Cold files may be idiomatised freely -- these may not.")
        print("If the C side genuinely moved (an upstream resync), re-pin with --bump.")
        return 1

    print(f"check-transliteration-contract: OK ({len(pairs)} hot 1:1 ports intact)")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true")
    args = ap.parse_args()
    repo_root = os.path.abspath(args.repo_root)
    if args.bump:
        bump(repo_root)
        return 0
    return enforce(repo_root)


if __name__ == "__main__":
    sys.exit(main())
