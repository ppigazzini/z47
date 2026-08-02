#!/usr/bin/env python3
"""A parity oracle that cannot see c43 move must at least say so out loud.

WHY THIS EXISTS (REPORT-31 M31-0). z47's correctness claim is function parity with
c43, so the only question that matters about a parity reference is: *when c43
changes, does this reference change with it?* Five oracles answered no. They are
hand-transliterated C that reimplements c43's behaviour, which means the lane whose
whole purpose is catching a c43 change is the reason nobody sees it -- the lane stays
green and manufactures positive evidence that parity holds.

The compensating control was human (`report-upstream-refresh.py` lists changed c43
paths on a pin bump; a maintainer decides what to re-port) and it fails in the
ordinary way: the list is long, the mirrored file changed for an unrelated reason,
the parity lane is green, and the reviewer moves on.

WHAT THIS GATE DOES. It binds each frozen oracle to a CONTENT HASH of the c43 file
it mirrors. When the pin advances and that c43 file changes, the hash no longer
matches and this fails, naming the oracle that has to be re-transliterated -- or,
better, converted to compile from the c43 source (REPORT-31 §4 option A) so the
manifest entry can be deleted.

It also records the oracle's OWN hash. A frozen oracle that changed without its
mirror's hash being re-recorded is an untracked re-transliteration; refreshing both
together is the act of asserting "I have re-read the c43 source and this mirrors it".

Generated oracles are a different, sound shape: the reference is extracted from c43
source by a script, so it moves. The failure mode there is not drift but STALENESS --
nothing re-ran the extractor. Those entries carry a `regenerate` command and this
gate re-runs it and demands byte-identical output.

WHAT IT IS NOT. This is an interim holding action, explicitly labelled as such in
REPORT-31 §4 option D: it converts a silent failure into a blocking question. It does
not make a frozen oracle correct. The endpoint is an empty `frozen` list.

Usage:
  check-frozen-oracle-drift.py [--repo-root .]
  check-frozen-oracle-drift.py --bump        # re-record hashes after re-transliterating
  check-frozen-oracle-drift.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from upstream_paths import upstream_path

MANIFEST = ".github/project/frozen-oracle-manifest.json"


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_manifest(repo: Path) -> dict:
    path = repo / MANIFEST
    if not path.is_file():
        raise SystemExit(f"check-frozen-oracle-drift: BROKEN -- missing {MANIFEST}.")
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


def bump(repo: Path) -> int:
    manifest = load_manifest(repo)
    for entry in manifest.get("frozen", []):
        oracle = repo / entry["oracle"]
        entry["oracle_sha256"] = sha256_of(oracle)
        entry["mirrors"] = {
            rel: sha256_of(upstream_path(repo, rel)) for rel in sorted(entry.get("mirrors", {}))
        }
    (repo / MANIFEST).write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(
        f"check-frozen-oracle-drift: re-recorded {len(manifest.get('frozen', []))} frozen oracles"
    )
    return 0


def self_test(repo: Path) -> int:
    """A gate nobody has seen fail is a gate nobody should believe.

    Copies the tree's own manifest into a scratch repo with one byte changed in the
    mirrored c43 file, and demands a report naming the oracle.
    """
    manifest = load_manifest(repo)
    frozen = manifest.get("frozen", [])
    if not frozen:
        print("check-frozen-oracle-drift: --self-test SKIPPED (frozen list is empty -- the goal)")
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
            print(
                "check-frozen-oracle-drift: --self-test FAILED -- a changed c43 file did not fire."
            )
            return 1

        # And the other direction: the oracle edited without re-recording.
        mirror.write_bytes(upstream_path(repo, mirror_rel).read_bytes())
        oracle.write_bytes(oracle.read_bytes() + b"\n// hand edit\n")
        edited = check_frozen(scratch, [entry])
        if not any("re-recorded" in p for p in edited):
            print("check-frozen-oracle-drift: --self-test FAILED -- an edited oracle did not fire.")
            return 1

    print("check-frozen-oracle-drift: --self-test OK (both drift directions fire)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record hashes after re-transliterating")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    if args.self_test:
        return self_test(repo)
    if args.bump:
        return bump(repo)

    manifest = load_manifest(repo)
    frozen = manifest.get("frozen", [])
    generated = manifest.get("generated", [])
    problems = check_frozen(repo, frozen) + check_generated(repo, generated)

    if problems:
        print("FROZEN PARITY ORACLES OUT OF STEP WITH c43:")
        for p in problems:
            print(f"  {p}")
        print()
        print("A hand-written oracle cannot detect c43 moving -- it IS the reference, and")
        print("it stayed put. That is why REPORT-31 exists. The fix is not to bump the")
        print("hash and move on; it is to convert the lane to compile from the c43 source.")
        return 1

    if frozen:
        print(
            f"check-frozen-oracle-drift: OK ({len(frozen)} frozen oracles still mirror their"
            f" pinned c43 counterparts, {len(generated)} generated oracles reproduce)"
        )
        print(
            "  Frozen is not sound -- these lanes cannot see c43 move. REPORT-31 tracks"
            " converting each one to compile from c43 source."
        )
    else:
        print(
            f"check-frozen-oracle-drift: OK (no frozen oracles remain;"
            f" {len(generated)} generated oracles reproduce)"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
