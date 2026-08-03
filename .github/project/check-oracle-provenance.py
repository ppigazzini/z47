#!/usr/bin/env python3
"""Every parity oracle in the tree is compiled from c43 source. Keep it that way.

WHY THIS EXISTS (REPORT-31 M31-0, renamed at M31-14). z47's correctness claim is
function parity with c43, so the only question that matters about a parity
reference is: *when c43 changes, does this reference change with it?* Five oracles
answered no. They were hand-transliterated C reimplementing c43's behaviour, which
means the lane whose whole purpose is catching a c43 change was the reason nobody
saw it -- the lane stayed green and manufactured positive evidence that parity
held. All five are converted (M31-2, M31-3, M31-10, M31-12, M31-13) and the
`frozen` list is EMPTY, which is the endpoint the report set.

WHAT THIS GATE DOES NOW. Two things, and the second is the live one:

  frozen    -- a hand-transliterated oracle, bound to a CONTENT HASH of the c43
               file it mirrors so a pin bump that changes that file fails here
               instead of staying green. THE LIST IS EMPTY AND IS MEANT TO STAY
               EMPTY. It is kept rather than deleted because the machinery is what
               makes re-adding one a deliberate, reviewable act: an entry here is
               a written admission that a lane cannot see c43 move.

  generated -- an oracle EXTRACTED from c43 source by a script. Sound in shape,
               because the reference moves; the failure mode is not drift but
               STALENESS, when nothing re-ran the extractor. Those entries carry a
               `regenerate` command and this gate re-runs it and demands
               byte-identical output. `charstring_diff` is the one that needs it.

A COMPILED-FROM-c43 oracle -- the shape every parity lane now uses -- needs no
entry in either list, because there is nothing to hash: the reference IS the
imported source, and `check-imported-tree-pin.py` already holds that to the pin.

AND A THIRD CHECK, WHICH IS THE ONE THAT STILL FINDS THINGS (REPORT-31 M31-15).
Both lists above classify FILES. A reference is a FUNCTION. A file that
`#include`s c43 source can still carry a hand-written `oracle_<c43 name>` BODY
beside it -- and such a file was never eligible for the frozen list, so the
file-level answer was "sound" while 1960 lines of hand-written reference sat
inside two of them. That is the same false confidence a green hand-written lane
produces, committed by this gate.

So the third check extracts every `oracle_*` function DEFINITION from z47-owned C
and reports each whose stripped name c43 declares in its own headers. Two shapes
are deliberately NOT findings:

  * a driver helper -- `initRuntime`, `runCase`, `main`. Those carry no `oracle_`
    prefix, so they never match.
  * a DISAMBIGUATED name over a compiled reference -- `oracle_full_fnAdd`,
    `oracle_fnAtan2_legacy`. The suffix says "this is not the plain mirror", and
    the plain mirror is what the driver must not be calling.

It ships as a RATCHET, like the constant gate: the measured backlog is recorded
per file and may only fall.

Usage:
  check-oracle-provenance.py [--repo-root .]
  check-oracle-provenance.py --bump        # re-record hashes after re-transliterating
  check-oracle-provenance.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from upstream_paths import upstream_path

MANIFEST = ".github/project/oracle-provenance-manifest.json"


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_manifest(repo: Path) -> dict:
    path = repo / MANIFEST
    if not path.is_file():
        raise SystemExit(f"check-oracle-provenance: BROKEN -- missing {MANIFEST}.")
    return json.loads(path.read_text(encoding="utf-8"))


def check_frozen(repo: Path, entries: list[dict]) -> list[str]:
    problems: list[str] = []
    for entry in entries:
        oracle_rel = entry["oracle"]
        oracle = repo / oracle_rel
        if not oracle.is_file():
            problems.append(
                f"{oracle_rel}: listed as a frozen oracle but the file is gone.\n"
                f"    If it was converted to compile from c43 source, delete its entry"
                f" from {MANIFEST}."
            )
            continue

        recorded_oracle = entry.get("oracle_sha256", "")
        actual_oracle = sha256_of(oracle)
        if actual_oracle != recorded_oracle:
            problems.append(
                f"{oracle_rel}: the ORACLE changed but its mirror hashes were not"
                f" re-recorded.\n"
                f"    recorded {recorded_oracle[:16]}  actual {actual_oracle[:16]}\n"
                f"    Editing a frozen oracle IS the re-transliteration event. Re-read the"
                f" c43 source it mirrors, then `--bump` to record both sides together."
            )

        for mirror_rel, recorded in sorted(entry.get("mirrors", {}).items()):
            mirror = upstream_path(repo, mirror_rel)
            if not mirror.is_file():
                problems.append(
                    f"{oracle_rel}: mirrors {mirror_rel}, which does not exist in the"
                    f" imported tree.\n"
                    f"    Upstream renamed or deleted it; the oracle now mirrors nothing."
                )
                continue
            actual = sha256_of(mirror)
            if actual != recorded:
                problems.append(
                    f"{oracle_rel}: c43 MOVED and this hand-written oracle did not.\n"
                    f"    {mirror_rel}: recorded {recorded[:16]}  actual {actual[:16]}\n"
                    f"    {entry.get('milestone', 'REPORT-31')} converts this lane to"
                    f" compile from the c43 source, which is the real fix. Until then:"
                    f" diff that file against the pin it was last transliterated at,"
                    f" port any behavioural change into the oracle AND the Zig owner,"
                    f" then `--bump`."
                )
    return problems


def check_generated(repo: Path, entries: list[dict]) -> list[str]:
    problems: list[str] = []
    for entry in entries:
        oracle_rel = entry["oracle"]
        oracle = repo / oracle_rel
        command = entry["regenerate"]
        if not oracle.is_file():
            problems.append(f"{oracle_rel}: listed as a generated oracle but the file is gone.")
            continue
        before = oracle.read_bytes()
        proc = subprocess.run(
            ["bash", command],
            cwd=repo,
            capture_output=True,
            text=True,
        )
        after = oracle.read_bytes()
        # Restore before judging: a gate must not leave the tree rewritten, and a
        # failing extractor must not leave a half-written oracle behind either.
        oracle.write_bytes(before)
        if proc.returncode:
            problems.append(
                f"{oracle_rel}: its extractor `{command}` failed.\n"
                f"    {proc.stderr.strip().splitlines()[-1] if proc.stderr.strip() else ''}"
            )
            continue
        if after != before:
            problems.append(
                f"{oracle_rel}: STALE -- re-running `{command}` produces different content.\n"
                f"    This oracle is extracted from c43 source, so it moves when c43 does"
                f" -- but only if somebody re-runs the extractor. Run it and commit the"
                f" result, then re-port whatever the Zig owner now disagrees with."
            )
    return problems


# A function DEFINITION named oracle_<something>: a return type, the name, a
# parameter list, and an opening brace. A declaration ends in `;` and does not
# match; a call has no type in front of it.
ORACLE_BODY_RE = re.compile(
    r"^(?:static\s+)?[A-Za-z_][\w \*]*?\b(oracle_\w+)\s*\([^;]*\)\s*\{", re.M
)

# What c43 declares as a function in its OWN headers. A prototype line ends in
# `;` and has a name followed by `(`; that is enough to separate a c43 function
# name from a harness-local one, and it costs no compiler.
C43_PROTOTYPE_RE = re.compile(r"\b([a-zA-Z_]\w*)\s*\(")

FUNCTION_RATCHET = ".github/project/oracle-function-baseline.json"
TRACKED_C_GLOBS = ("build/**/*.c", "bridge/**/*.c")


def c43_function_names(repo: Path) -> set[str]:
    names: set[str] = set()
    root = upstream_path(repo, "src/c47")
    for header in root.rglob("*.h"):
        for raw in header.read_text(errors="replace").splitlines():
            line = raw.strip()
            if not line.endswith(";") or line.startswith("#"):
                continue
            match = C43_PROTOTYPE_RE.search(line)
            if match:
                names.add(match.group(1))
    return names


def tracked_c_sources(repo: Path) -> list[Path]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", *TRACKED_C_GLOBS],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    return [repo / rel for rel in out]


def measure_hand_written_bodies(repo: Path) -> dict[str, list[str]]:
    """{file: [oracle_X, ...]} for every body whose X is a c43 function.

    GENERATED oracles are skipped, and that exclusion is the difference between a
    useful gate and a noisy one. `charstring_diff_oracle.c` holds five `oracle_*`
    bodies that ARE c43's -- a script lifted them out of `charString.c`, and the
    `generated` list above already gates them on reproducing byte-identically. A
    body extracted by a tool is not a body somebody wrote.
    """
    c43 = c43_function_names(repo)
    generated = {e["oracle"] for e in load_manifest(repo).get("generated", [])}
    found: dict[str, list[str]] = {}
    for source in tracked_c_sources(repo):
        if source.relative_to(repo).as_posix() in generated:
            continue
        text = strip_block_comments(source.read_text(errors="replace"))
        mirrors = sorted(
            {name for name in ORACLE_BODY_RE.findall(text) if name[len("oracle_") :] in c43}
        )
        if mirrors:
            found[source.relative_to(repo).as_posix()] = mirrors
    return found


BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)


def strip_block_comments(text: str) -> str:
    return BLOCK_COMMENT_RE.sub("", text)


def check_functions(repo: Path) -> list[str]:
    path = repo / FUNCTION_RATCHET
    if not path.is_file():
        return [f"missing {FUNCTION_RATCHET}. Run --bump-functions to record the current backlog."]
    recorded = json.loads(path.read_text(encoding="utf-8")).get("counts", {})
    found = measure_hand_written_bodies(repo)

    problems: list[str] = []
    for rel, mirrors in sorted(found.items()):
        allowed = recorded.get(rel)
        if allowed is None:
            problems.append(
                f"{rel}: {len(mirrors)} hand-written reference BODY(s) in a file that"
                f" had none.\n"
                f"    {', '.join(mirrors[:8])}\n"
                f"    Each of these reimplements a c43 function under its own name. The"
                f" lane\n"
                f"    compares against this, not against c43, so it cannot see c43 move --"
                f" the\n"
                f"    defect REPORT-31 exists to remove, at function granularity."
            )
        elif len(mirrors) > allowed:
            problems.append(
                f"{rel}: hand-written reference bodies rose {allowed} ->"
                f" {len(mirrors)}.\n"
                f"    {', '.join(mirrors[:8])}\n"
                f"    This ratchet only goes down. Compile the c43 source instead, or"
                f" point the\n"
                f"    driver at a compiled reference that is already linked."
            )
    return problems


def bump_functions(repo: Path) -> int:
    found = measure_hand_written_bodies(repo)
    counts = {rel: len(names) for rel, names in sorted(found.items())}
    (repo / FUNCTION_RATCHET).write_text(
        json.dumps(
            {
                "_why": (
                    "REPORT-31 M31-15. Hand-written parity REFERENCE bodies -- an"
                    " oracle_<X> function definition where X is a function c43 declares"
                    " -- living inside files that also #include c43 source, which is why"
                    " neither the frozen nor the generated list could ever see them. The"
                    " ratchet only goes down; the endpoint is an empty object. Section 11"
                    " of the report is the plan."
                ),
                "counts": counts,
                "mirrors": found,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    total = sum(counts.values())
    print(
        f"check-oracle-provenance: recorded {total} hand-written reference bodies"
        f" across {len(counts)} files"
    )
    return 0


def self_test_functions(repo: Path) -> int:
    """Prove the function half fires, through the same extractor a real run uses."""
    c43 = c43_function_names(repo)
    if "fnAdd" not in c43:
        print("check-oracle-provenance: --self-test FAILED -- c43 prototype scan found no fnAdd.")
        return 1

    probe = "void oracle_fnAdd(uint16_t unusedButMandatoryParameter) {\n  return;\n}\n"
    mirrors = [n for n in ORACLE_BODY_RE.findall(probe) if n[len("oracle_") :] in c43]
    if mirrors != ["oracle_fnAdd"]:
        print(
            "check-oracle-provenance: --self-test FAILED -- a hand-written reference body"
            " went unseen."
        )
        return 1

    # And the two shapes that must NOT fire.
    for benign in (
        "void oracle_full_fnAdd(uint16_t p) {\n  return;\n}\n",  # disambiguated
        "static void initRuntime(void) {\n  return;\n}\n",  # driver helper
        "void oracle_fnAdd(uint16_t p);\n",  # a declaration, not a body
    ):
        if [n for n in ORACLE_BODY_RE.findall(benign) if n[len("oracle_") :] in c43]:
            print(
                "check-oracle-provenance: --self-test FAILED -- reported a body that is"
                f" not a hand-written reference: {benign.splitlines()[0]}"
            )
            return 1

    print("check-oracle-provenance: --self-test OK (function half fires, and only on a mirror)")
    return 0


def bump(repo: Path) -> int:
    manifest = load_manifest(repo)
    for entry in manifest.get("frozen", []):
        oracle = repo / entry["oracle"]
        entry["oracle_sha256"] = sha256_of(oracle)
        entry["mirrors"] = {
            rel: sha256_of(upstream_path(repo, rel)) for rel in sorted(entry.get("mirrors", {}))
        }
    (repo / MANIFEST).write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"check-oracle-provenance: re-recorded {len(manifest.get('frozen', []))} frozen oracles")
    return 0


def self_test(repo: Path) -> int:
    """A gate nobody has seen fail is a gate nobody should believe.

    Copies the tree's own manifest into a scratch repo with one byte changed in the
    mirrored c43 file, and demands a report naming the oracle.
    """
    manifest = load_manifest(repo)
    frozen = manifest.get("frozen", [])
    if not frozen:
        print("check-oracle-provenance: --self-test SKIPPED (frozen list is empty -- the goal)")
        return 0

    entry = frozen[0]
    mirror_rel = sorted(entry["mirrors"])[0]
    with tempfile.TemporaryDirectory() as tmp:
        scratch = Path(tmp)
        (scratch / ".github/project").mkdir(parents=True)
        (scratch / ".github/project/upstream-pin.env").write_text(
            "UPSTREAM_ROOT=upstream\n", encoding="utf-8"
        )
        oracle = scratch / entry["oracle"]
        oracle.parent.mkdir(parents=True, exist_ok=True)
        oracle.write_bytes((repo / entry["oracle"]).read_bytes())
        mirror = upstream_path(scratch, mirror_rel)
        mirror.parent.mkdir(parents=True, exist_ok=True)
        mirror.write_bytes(upstream_path(repo, mirror_rel).read_bytes() + b"\n// c43 moved\n")

        clean = check_frozen(scratch, [entry])
        if not any("c43 MOVED" in p for p in clean):
            print("check-oracle-provenance: --self-test FAILED -- a changed c43 file did not fire.")
            return 1

        # And the other direction: the oracle edited without re-recording.
        mirror.write_bytes(upstream_path(repo, mirror_rel).read_bytes())
        oracle.write_bytes(oracle.read_bytes() + b"\n// hand edit\n")
        edited = check_frozen(scratch, [entry])
        if not any("re-recorded" in p for p in edited):
            print("check-oracle-provenance: --self-test FAILED -- an edited oracle did not fire.")
            return 1

    print("check-oracle-provenance: --self-test OK (both drift directions fire)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record hashes after re-transliterating")
    ap.add_argument(
        "--bump-functions",
        action="store_true",
        help="re-record the hand-written-reference-body ratchet",
    )
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    if args.self_test:
        rc = self_test(repo)
        return rc or self_test_functions(repo)
    if args.bump_functions:
        return bump_functions(repo)
    if args.bump:
        return bump(repo)

    manifest = load_manifest(repo)
    frozen = manifest.get("frozen", [])
    generated = manifest.get("generated", [])
    problems = check_frozen(repo, frozen) + check_generated(repo, generated)
    function_problems = check_functions(repo)

    if problems:
        print("FROZEN PARITY ORACLES OUT OF STEP WITH c43:")
        for p in problems:
            print(f"  {p}")
        print()
        print("A hand-written oracle cannot detect c43 moving -- it IS the reference, and")
        print("it stayed put. That is why REPORT-31 exists. The fix is not to bump the")
        print("hash and move on; it is to convert the lane to compile from the c43 source.")
        return 1

    if function_problems:
        print("HAND-WRITTEN PARITY REFERENCES (function granularity):")
        for p in function_problems:
            print(f"  {p}")
        print()
        print("A reference is a FUNCTION, not a file. The lists above classify files, so a")
        print("hand-written body inside a file that ALSO #includes c43 source is invisible")
        print("to them -- which is how 1960 lines survived the first close-out.")
        return 1

    bodies = measure_hand_written_bodies(repo)
    remaining = sum(len(v) for v in bodies.values())

    if frozen:
        print(
            f"check-oracle-provenance: OK ({len(frozen)} frozen oracles still mirror their"
            f" pinned c43 counterparts, {len(generated)} generated oracles reproduce)"
        )
        print(
            "  Frozen is not sound -- these lanes cannot see c43 move. REPORT-31 tracks"
            " converting each one to compile from c43 source."
        )
    else:
        print(
            f"check-oracle-provenance: OK (no frozen oracle FILES remain;"
            f" {len(generated)} generated oracles reproduce)"
        )

    if remaining:
        print(
            f"  {remaining} hand-written reference BODIES remain across {len(bodies)}"
            f" file(s), at or below the recorded ratchet:"
        )
        for rel, names in sorted(bodies.items()):
            print(f"    {len(names):>3}  {rel}")
        print("  These are REPORT-31 section 11's subject. A file-level zero is not a clean bill.")
    else:
        print("  and no hand-written reference bodies remain either -- the real zero.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
