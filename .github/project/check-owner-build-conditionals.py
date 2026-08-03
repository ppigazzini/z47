#!/usr/bin/env python3
"""An owner must not change what it does because it is being tested.

WHY THIS EXISTS. `runtime.zig` carried, for a long time and unnoticed:

    pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = if (use_fake_wp34s_harness_surface) 2 else 24;

The harness header carried the same wrong value, so the lane's two sides agreed
perfectly about a number c43 has never used, and error-code behaviour in that lane
was held to nothing. The same flag still selects different STRUCT LAYOUTS: in the
unit-harness build the matrix header has no `mtag` field and matrix elements are a
fixed four-element inline array rather than a pointer. The lane compiles a
different program from the one that ships, and the difference is data layout.

Feathers calls this a PREPROCESSING SEAM (Working Effectively with Legacy Code,
ch. 4) and warns about exactly this: it lets the code under test differ from the
code that runs. z47's own `docs/90` has cited Feathers since the oracle work
began -- for a different chapter.

THE RULE, AND WHY IT IS NOT "NO CONDITIONALS". z47 is a 1:1 port of a C program
that is full of `#if`, and mirroring those is the job. A build-option conditional
in an owner is:

  * ALLOWED when upstream has the corresponding `#if` -- platform (DMCP_BUILD,
    OLD_HW), feature stripping (SAVE_SPACE_*, OPTION_*), diagnostics
    (EXTRA_INFO_ON_CALC_ERROR), and TESTSUITE_BUILD, which c43 uses itself (its
    random.c seeds 0xDeadBeef under it, and z47's owner mirrors that).

  * BANNED when it exists only because z47 has a test harness. The `use_fake_*`
    family has no upstream counterpart: it is scaffolding that reaches into the
    owner, and every one of its branches makes the tested program differ from the
    shipped one.

So the check is not "is this conditional?" but "does upstream have this
conditional?". A new option that mirrors an upstream `#if` is added to ALLOWED
with the macro it mirrors; a new `use_fake_*` is a defect.

RATCHETED, NOT ZERO. The banned family is large (measured when this landed:
117 sites across four flags), and removing it means giving the harnesses the real
types. The count may fall and may not rise, so the cleanup can proceed one flag at
a time while a new one fails immediately.

Usage:
  check-owner-build-conditionals.py [--repo-root .]
  check-owner-build-conditionals.py --bump        # re-record after removing some
  check-owner-build-conditionals.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

BASELINE = ".github/project/owner-build-conditional-baseline.json"

# Owners only. build/ is the build system and build/tests/ is the harness layer;
# both are allowed to know a harness exists. The point of the rule is that the
# SHIPPED code must not.
OWNER_GLOBS = ("src/**/*.zig",)

# Build options an owner may branch on, each with the upstream `#if` it mirrors.
# A port that did not mirror these would be the defect.
ALLOWED: dict[str, str] = {
    "dmcp_build": "DMCP_BUILD",
    "is_dmcp_build": "DMCP_BUILD",
    "old_hw": "OLD_HW",
    "is_old_hw": "OLD_HW",
    "state_old_hw": "OLD_HW",
    "dm42_pkg_xip": "the DM42 QSPI XIP packaging split",
    "extra_info_on_calc_error": "EXTRA_INFO_ON_CALC_ERROR",
    "ir_printing": "PRINTER / IR printing block",
    "option_elec": "OPTION_ELEC",
    "option_vector": "OPTION_VECTOR",
    "option_xfn_1000": "OPTION_XFN_1000",
    "calcmodel": "CALCMODEL / the C47 vs R47 model split",
    "calc_model_user_id": "CALCMODEL",
    "is_r47": "CALCMODEL -- the C47 vs R47 model split",
    "option_slvp": "OPTION_SLVP",
    "library_fn_base": "the DMCP ROM function-table base, which moves with the XIP packaging",
    "wp34s_mod_small_buffers": "WP34S_MOD_SMALL_BUFFERS",
    "is_testsuite_build": "TESTSUITE_BUILD -- c43 uses it itself (random.c seeds 0xDeadBeef under it)",
    "strip_15": "SAVE_SPACE_DM42_15",
    "strip_16": "SAVE_SPACE_DM42_16",
    "strip_17": "SAVE_SPACE_DM42_17",
    "strip_17b": "SAVE_SPACE_DM42_17B",
    "strip_17c": "SAVE_SPACE_DM42_17C",
    "strip_21_hp35": "SAVE_SPACE_DM42_21",
    "strip_ortho_bessel_ellip": "SAVE_SPACE_DM42_20",
    "version_str": "the version string, assembled at build time",
    "version_str2": "the version string, assembled at build time",
}

# Harness-only options that do NOT start with use_fake_. Recognising the family by
# prefix alone missed these, and they are the same seam: each selects a different
# TYPE for the owner depending on who is building it.
# Sites that select which OWNERS ARE LINKED rather than what an owner DOES. This
# is Feathers' LINK seam rather than a preprocessing one, and the distinction is
# worth keeping: the owners that do get compiled behave identically, so nothing
# here makes a tested owner differ from its shipped self. What it costs is
# coverage -- the excluded owners are not in that lane -- and that is a fact about
# the lane, not a defect in the owner. Each entry says where the excluded owners
# ARE covered.
# Keyed on FILE, which is why it is empty. It used to hold
# src/core/numeric/command_wrappers.zig with a reason about which owner files the
# math_command_wrappers lane links -- and that file contains exactly one
# build_options site, `export_public_ln_complex`, which is an EXPORT decision and
# not a link-set one. The exemption was carrying a plausible sentence about a
# decision that is not made at the site it exempted, and it hid that site for as
# long as it existed.
#
# A file-level exemption cannot distinguish two kinds of seam in one file. If one
# is needed again, key it on (file, option).
LINK_SET: dict[str, str] = {}

# Each entry is a VERDICT, not a label. The count sat at 59 across 9 options for
# four passes while the text below said "the endpoint is zero", and nobody had
# written down which of these can actually reach zero. Three answers exist and they
# are not the same answer:
#
#   REMOVABLE   -- no reason beyond nobody having done it.
#   BLOCKED     -- removable in principle, blocked on a named piece of work.
#   METHOD      -- the divergence IS the lane's method; removing it deletes the
#                  lane rather than fixing it, and the endpoint for these is not
#                  zero. Saying so is the honest form of "or a written reason".
HARNESS_ONLY: dict[str, str] = {
    "free_regions_are_inline_array": (
        "BLOCKED. FreeRegionsStorage becomes [N]T instead of [*]T because the fake"
        " runtime cannot allocate. Same obstacle as M31-37's matrix element half:"
        " unblocking it means the fake modelling allocation, which is the full-core"
        " conversion by another route."
    ),
    "use_array_backed_global_registers": (
        "BLOCKED. The global register file becomes an array instead of a pointer, for"
        " the same reason and behind the same work."
    ),
    "max_free_regions": (
        "METHOD. Caps the free-region table so a host binary can exhaust and walk it."
        " The allocator LOGIC is what is under test and it is size-independent;"
        " upstream's size makes every full-pool case unrunnable. Endpoint is not zero."
    ),
    "ram_size_in_blocks": (
        "METHOD. 64 against c43's 65534, so a host binary can exhaust and diff the"
        " whole pool. Already recorded as a reasoned deliberate divergence in"
        " check-harness-constant-copies.py; this is the same decision seen from the"
        " owner side. Endpoint is not zero."
    ),
    "export_public_ln_complex": (
        "REMOVABLE. Exports a worker so a focused oracle can link it -- the same"
        " question answered NO for curtReal and compareTypeErrorX, where the ruling"
        " was that a differential is not worth changing the product's symbol table."
        " This one predates that ruling and should go the same way."
    ),
}

# Any option matching this is harness scaffolding reaching into an owner.
BANNED_RE_PREFIX = re.compile(r"^use_fake_\w+$")


def is_harness_only(option: str) -> bool:
    return bool(BANNED_RE_PREFIX.match(option)) or option in HARNESS_ONLY


OPTION_REF_RE = re.compile(r"\b(?:build_options|frontier_build_options|\w*_build_options)\.(\w+)")


def tracked(repo: Path) -> list[str]:
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-files", *OWNER_GLOBS],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    return out


def scan(repo: Path) -> tuple[dict[str, list[str]], set[str], dict[str, list[str]]]:
    """{option: [file:line, ...]} for banned options, every option seen, link-set sites."""
    banned: dict[str, list[str]] = {}
    seen: set[str] = set()
    link_set: dict[str, list[str]] = {}

    # An owner may alias a banned option to a local name and branch on that, which
    # is the same seam wearing a different spelling. Collect the aliases first.
    aliases: dict[str, set[str]] = {}
    for rel in tracked(repo):
        text = (repo / rel).read_text(encoding="utf-8", errors="replace")
        for line in text.splitlines():
            for opt in OPTION_REF_RE.findall(line):
                seen.add(opt)
            m = re.match(r"\s*(?:pub\s+)?const\s+(\w+)\s*(?::[^=]+)?=\s*(.+)$", line)
            if m and OPTION_REF_RE.search(m.group(2)):
                for opt in OPTION_REF_RE.findall(m.group(2)):
                    if is_harness_only(opt):
                        aliases.setdefault(rel, set()).add(m.group(1))

    for rel in tracked(repo):
        text = (repo / rel).read_text(encoding="utf-8", errors="replace")
        local = aliases.get(rel, set())
        for number, line in enumerate(text.splitlines(), start=1):
            if line.lstrip().startswith("//"):
                continue
            hits = {opt for opt in OPTION_REF_RE.findall(line) if is_harness_only(opt)}
            for name in local:
                if re.search(rf"\b{re.escape(name)}\b", line):
                    hits.add(name)
            for opt in sorted(hits):
                if rel in LINK_SET:
                    link_set.setdefault(rel, []).append(f"{rel}:{number}")
                    continue
                banned.setdefault(opt, []).append(f"{rel}:{number}")

    return banned, seen, link_set


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--bump", action="store_true", help="re-record the per-option counts")
    ap.add_argument("--self-test", action="store_true", help="prove the gate fires")
    args = ap.parse_args()
    repo = Path(args.repo_root).resolve()

    banned, seen, link_set = scan(repo)
    counts = {opt: len(sites) for opt, sites in sorted(banned.items())}
    total = sum(counts.values())

    if args.self_test:
        probe = "use_fake_a_thing_that_does_not_exist"
        if not is_harness_only(probe):
            print(
                "check-owner-build-conditionals: SELF-TEST FAILED -- the pattern misses a use_fake_ option"
            )
            return 1
        for allowed in ALLOWED:
            if is_harness_only(allowed):
                print(
                    f"check-owner-build-conditionals: SELF-TEST FAILED -- {allowed} is both allowed and banned"
                )
                return 1
        print(
            "check-owner-build-conditionals: SELF-TEST OK -- a use_fake_ option is caught, allowed ones are not"
        )

    # An option that is neither allowed nor banned is a decision nobody has made.
    unclassified = sorted(o for o in seen if o not in ALLOWED and not is_harness_only(o))

    if args.bump:
        (repo / BASELINE).write_text(
            json.dumps(
                {
                    "_why": (
                        "Build-option conditionals inside OWNERS that exist only because z47 has"
                        " a test harness. Upstream has no counterpart, so every branch makes the"
                        " tested program differ from the shipped one. The count may FALL and may"
                        " not rise; the endpoint is an empty object. Removing them means giving"
                        " the harnesses the real types instead of harness-shaped ones."
                    ),
                    "counts": counts,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        print(
            f"check-owner-build-conditionals: recorded {total} site(s) across {len(counts)} option(s)"
        )
        return 0

    baseline_path = repo / BASELINE
    if not baseline_path.is_file():
        print(f"check-owner-build-conditionals: BROKEN -- missing {BASELINE}. Run --bump.")
        return 1
    recorded = json.loads(baseline_path.read_text(encoding="utf-8")).get("counts", {})

    problems: list[str] = []
    for opt, count in counts.items():
        allowed_count = recorded.get(opt)
        if allowed_count is None:
            problems.append(
                f"{opt}: {count} site(s) in owners, and this option is NOT in the baseline.\n"
                f"    First at {banned[opt][0]}.\n"
                f"    A `use_fake_*` option in an owner is harness scaffolding reaching into\n"
                f"    shipped code: the lane then tests a program that does not ship. Give the\n"
                f"    harness the real type instead."
            )
        elif count > allowed_count:
            problems.append(
                f"{opt}: rose {allowed_count} -> {count} site(s) in owners.\n"
                f"    This ratchet only goes down."
            )

    if unclassified:
        problems.append(
            "build options branched on in owners that are neither allowed nor banned:\n"
            f"    {', '.join(unclassified)}\n"
            "    Add each to ALLOWED with the upstream `#if` it mirrors, or rename it\n"
            "    `use_fake_*` if it is harness scaffolding. An unclassified option is a\n"
            "    decision nobody has made."
        )

    print(
        f"check-owner-build-conditionals: {total} harness-only conditional site(s)"
        f" across {len(counts)} option(s) in owners"
    )
    if link_set:
        linked = sum(len(v) for v in link_set.values())
        print(
            f"  plus {linked} LINK-SET site(s), which change which owners are compiled, not what they do:"
        )
        for rel in sorted(link_set):
            print(f"    {rel}: {LINK_SET[rel]}")
    for opt, count in counts.items():
        print(f"    {count:>4}  {opt}")

    if problems:
        print("\nOWNER BUILD CONDITIONALS:")
        for problem in problems:
            print(f"  {problem}")
        return 1

    if total:
        print(
            "  Recorded, not accepted: each of these makes the tested program differ from"
            "\n  the shipped one. The endpoint is zero for the REMOVABLE and BLOCKED"
            "\n  options and NOT for the METHOD ones, whose divergence IS the lane's"
            "\n  method -- see the verdict beside each in HARNESS_ONLY."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
