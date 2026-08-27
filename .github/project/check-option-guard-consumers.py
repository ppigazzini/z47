#!/usr/bin/env python3
"""Every upstream `#if defined(OPTION_X)` that VARIES must have a Zig consumer.

WHY THIS EXISTS. Four owners were found asserting in a comment that
`OPTION_IR_PRINTING` is "never defined for any z47 build" and DELETING the calls
it guards. It is defined -- for the host, for DMCP5 and for firmware packages 2
and 4 -- and the build graph had modelled that correctly the whole time. The
result was a printer that rendered every program step with an empty name, a TRACE
mode that printed nothing, and a TAM diagnostic that was dead in every build z47
has ever produced. A fifth owner hardcoded the C47 model text while the R47
simulator passes a different CALCMODEL, and three more declared OPTION_BESSEL,
OPTION_ORTHO and OPTION_ELLIPTIC dead while the same files gated on them
correctly a hundred lines below.

One derivation, wrong, in eight places. Nothing caught it, because a deleted call
compiles, links, and passes every parity lane -- those owners are exactly the ones
no lane reaches.

WHAT IT CHECKS. For each `OPTION_*` macro that guards code in the imported C:

  1. Is it INVARIANT? The macro set is computed with the preprocessor, once per
     target z47 actually builds (host, DMCP5, and DMCP packages 1-4), so this is
     measured, not parsed. An option defined for every target, or for none, gates
     nothing that can differ: its blocks are unconditionally live (or dead) and no
     owner needs to read it. Those are reported and skipped.

  2. Otherwise it VARIES, and two things must hold. z47 must model it as a build
     option -- the mapping lives in check-owner-build-conditionals.py's ALLOWED
     table, which already had to name the upstream macro each option mirrors, so
     this gate reads that table rather than restating it. And every owner set that
     holds a C file guarding on it must reference that option somewhere.

The second half is the one that bites. An owner that never mentions the option has
either ported both arms as one (a divergence on some package) or deleted the
guarded code (a divergence on the others). Neither is visible to a lane.

WHAT IT DOES NOT CHECK. That the owner reads the option CORRECTLY -- that is what
a 1:1 read against the C twin is for. This gate answers a narrower question that
happens to be the one that was silently false eight times: does anybody read it at
all?

Exit 1 on any unbaselined absence. Baseline entries carry a stated reason.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from upstream_paths import upstream_path, upstream_root

ROOT = Path(__file__).resolve().parents[2]
BASELINE = ROOT / ".github/project/option-guard-consumer-baseline.json"
MANIFEST = ROOT / ".github/project/upstream-correspondence.tsv"
OBC = ROOT / ".github/project/check-owner-build-conditionals.py"

GUARD = re.compile(r"#if\s+!?defined\(\s*(OPTION_[A-Z0-9_]+)\s*\)")
DEFINED = re.compile(r"^#define (OPTION_[A-Z0-9_]+)", re.M)

# Every target z47 builds, as the macros its build passes. Package selection is
# DMCP_PACKAGE, which defines.h turns into DMCP_PACKAGEn before the option blocks.
TARGETS = {
    "host": ["-DPC_BUILD", "-DLINUX", "-DOS64BIT"],
    "dmcp5": ["-DDMCP_BUILD", "-DNEW_HW", "-DOS32BIT"],
    "dmcp-pkg1": ["-DDMCP_BUILD", "-DOLD_HW", "-DOS32BIT", "-DDMCP_PACKAGE=1"],
    "dmcp-pkg2": ["-DDMCP_BUILD", "-DOLD_HW", "-DOS32BIT", "-DDMCP_PACKAGE=2"],
    "dmcp-pkg3": ["-DDMCP_BUILD", "-DOLD_HW", "-DOS32BIT", "-DDMCP_PACKAGE=3"],
    "dmcp-pkg4": ["-DDMCP_BUILD", "-DOLD_HW", "-DOS32BIT", "-DDMCP_PACKAGE=4"],
}


def options_for(target_flags: list[str], c47_dir: Path, dec_dir: Path) -> set[str] | None:
    """The OPTION_* macros defines.h leaves defined for one target."""
    with tempfile.TemporaryDirectory() as td:
        probe = Path(td) / "probe.c"
        probe.write_text('#include "defines.h"\n')
        proc = subprocess.run(
            [
                "zig",
                "cc",
                "-dM",
                "-E",
                *target_flags,
                "-I",
                str(c47_dir),
                "-I",
                str(dec_dir),
                str(probe),
            ],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            return None
        return set(DEFINED.findall(proc.stdout))


def load_owners() -> dict[str, list[str]]:
    """upstream C relpath under src/c47 (no suffix) -> owner module(s)."""
    owners: dict[str, list[str]] = {}
    if not MANIFEST.exists():
        return owners
    for line in MANIFEST.read_text().splitlines():
        if line.startswith("#") or "\t" not in line:
            continue
        parts = line.split("\t")
        if len(parts) >= 2 and parts[0] != "-":
            owners.setdefault(parts[0], []).extend(p for p in parts[1].split(";") if p)
    return owners


def macro_to_options() -> dict[str, set[str]]:
    """upstream macro -> the z47 build options that mirror it, from the one table
    that already records the pairing."""
    spec = importlib.util.spec_from_file_location("obc", OBC)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load {OBC}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    out: dict[str, set[str]] = {}
    for opt, mirror in mod.ALLOWED.items():
        for mac in re.findall(r"OPTION_[A-Z0-9_]+", mirror):
            out.setdefault(mac, set()).add(opt)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-baseline", action="store_true")
    args = ap.parse_args()

    c47 = upstream_path(ROOT, "src/c47")
    dec = upstream_path(ROOT, "dep/decNumberICU")
    if not (c47 / "defines.h").is_file():
        print(f"check-option-guard-consumers: BROKEN -- {c47}/defines.h missing.")
        print(f"Check UPSTREAM_ROOT ({upstream_root(ROOT)}) in upstream-pin.env.")
        return 1

    per_target: dict[str, set[str]] = {}
    for name, flags in TARGETS.items():
        got = options_for(flags, c47, dec)
        if got is None:
            print(f"check-option-guard-consumers: cannot preprocess defines.h for {name}; skipping")
            return 0
        per_target[name] = got

    # Which C file guards on which macro.
    guards: dict[str, set[str]] = {}
    for f in sorted(c47.rglob("*.c")):
        # A commented-out directive guards nothing. c47.c carries
        # `//#if defined(OPTION_IR_PRINTING)` over a live declaration, and reading
        # it as a guard invents a consumer the file does not need.
        live = "\n".join(
            ln
            for ln in f.read_text(errors="ignore").splitlines()
            if not ln.lstrip().startswith("//")
        )
        found = set(GUARD.findall(live))
        if found:
            guards[f.relative_to(c47).with_suffix("").as_posix()] = found

    used = set().union(*guards.values()) if guards else set()
    varying = {
        m
        for m in used
        if any(m in s for s in per_target.values()) and not all(m in s for s in per_target.values())
    }
    invariant = sorted(used - varying)

    owners = load_owners()
    mapping = macro_to_options()
    src = ROOT / "src"
    owner_text: dict[str, str] = {}

    def reads(owner: str, opts: set[str]) -> bool:
        p = src / (owner + ".zig")
        if not p.is_file():
            return False
        if owner not in owner_text:
            owner_text[owner] = p.read_text(errors="ignore")
        return any(re.search(rf"\b{re.escape(o)}\b", owner_text[owner]) for o in opts)

    unmodelled: list[tuple[str, str]] = []
    unread: list[tuple[str, str, str]] = []
    for rel, macros in sorted(guards.items()):
        for mac in sorted(macros & varying):
            opts = mapping.get(mac)
            if not opts:
                unmodelled.append((rel, mac))
                continue
            own = owners.get(rel)
            if not own:
                continue  # no owner: the correspondence gate is what covers that
            if not any(reads(o, opts) for o in own):
                unread.append((rel, mac, ",".join(sorted(set(own)))))

    findings = {
        "unmodelled": sorted(f"{r}:{m}" for r, m in unmodelled),
        "unread": sorted(f"{r}:{m}" for r, m, _ in unread),
    }
    if args.write_baseline:
        BASELINE.write_text(
            json.dumps(
                {
                    "_why": "Reviewed absences. Each entry is a claim that no owner needs to read "
                    "that option, with the reason. An entry is not a licence: it is a debt.",
                    "reasons": {},
                    **findings,
                },
                indent=1,
                sort_keys=True,
            )
            + "\n"
        )
        print(
            f"wrote {BASELINE.name}: {len(findings['unmodelled'])} unmodelled, {len(findings['unread'])} unread"
        )
        return 0

    print(
        f"option-guard consumers: {len(used)} OPTION_* macros guard code across {len(guards)} C files; "
        f"{len(varying)} vary across the {len(TARGETS)} targets, {len(invariant)} are invariant"
    )
    if not BASELINE.exists():
        print(
            f"FAIL: no baseline at {BASELINE} -- create it with --write-baseline", file=sys.stderr
        )
        return 1
    base = json.loads(BASELINE.read_text())
    reasons = base.get("reasons", {})

    failures = []
    for key in ("unmodelled", "unread"):
        known = set(base.get(key, []))
        now = set(findings[key])
        for k in sorted(now - known):
            failures.append(f"  NEW {key}: {k}")
        for k in sorted(known - now):
            failures.append(f"  {key} {k} is now covered -- re-pin with --write-baseline")
    for k in sorted(set(base.get("unmodelled", [])) | set(base.get("unread", []))):
        if k not in reasons:
            failures.append(f"  baselined without a reason: {k}")

    print(f"  modelled and read: {len(varying)} varying macros over their owners")
    print(
        f"  baselined: {len(base.get('unmodelled', []))} unmodelled, {len(base.get('unread', []))} unread"
    )
    if failures:
        print("\nOPTION-GUARD CONSUMERS FAILED")
        for f in failures:
            print(f)
        print("\nAn owner that never reads a varying option has either ported both")
        print("arms as one, or deleted the guarded code. Neither is visible to a lane.")
        return 1
    print("PASS: every varying OPTION_* guard is modelled and read by an owner")
    return 0


if __name__ == "__main__":
    sys.exit(main())
