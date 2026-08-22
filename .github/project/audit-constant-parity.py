#!/usr/bin/env python3
"""Constant-parity audit: every defines.h/enum value a Zig owner hardcodes must
match the upstream C.

Owners mirror hundreds of C #define/enum values (item codes ITM_*, error codes
ERROR_*, flags FLAG_*, register indices REGISTER_*, temporary-info TI_*, calc
modes CM_*, the register data-type enum dt*, ...). constants_parity.zig is a
behavioral fnConstant/fnPi oracle -- NOT a value gate -- so before this tool
these mirrors had no continuous protection, and several have a documented history
of silently going stale on an edit (TM_CMP was 10021, dtReal34 was 0, ...).

This audit extracts every C-convention-named constant from src, emits one
`_Static_assert(NAME == VALUE)` per mirror, and compiles it against the pinned
upstream headers with `zig cc`. A mismatch is a real Zig-vs-C divergence; a name
C does not declare is a Zig-local alias (reported, not failed).

Names that resolve in C but legitimately differ are listed in KNOWN_DIVERGENCES
with a reason (currently only the deferred stale reserved-variable base). Any
un-listed divergence exits 1.

Run standalone or via `zig build constant-parity-audit`. Requires zig + the
upstream headers under src/c47 and dep/decNumberICU.
"""

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

from upstream_paths import upstream_path

ROOT = pathlib.Path(__file__).resolve().parents[2]
ZIG_SRC = ROOT / "src"

# C-symbol naming conventions owners mirror. Anchored so we only pick up genuine
# C #define/enum mirrors, not arbitrary Zig locals.
#
# TWO SHAPES THIS USED TO MISS, both found by audit and both stale for a whole
# resync before anyone noticed:
#
#   - a mirror whose VALUE is an expression. `NUMBER_OF_SYSTEM_FLAGS: i16 = 64 + 48`
#     is how the owner spells c43's `64+51`, and a value pattern that only accepted
#     one literal walked straight past it. The emitted check is a _Static_assert, so
#     an arithmetic value costs nothing -- the C compiler evaluates both sides.
#   - a mirror whose NAME starts outside the prefix list. INVALID_MENU is
#     `#define INVALID_MENU LAST_ITEM`, so it moves every time the item table grows,
#     and it sat at the previous pin's LAST_ITEM in four owners at once.
#
# Widen this list rather than special-casing a name: the cost of one more prefix is
# a few extra asserts, and the cost of a missing one is a silent divergence.
NAME_RE = re.compile(
    r"\bconst ((?:ITM_|TM_|FLAG_|ERROR_|TI_|SETTING_|CM_|PGM_|MAX_|MIN_|"
    r"NUMBER_OF_|SIZE_OF_|LAST_|FIRST_|REGISTER_|RESERVED_VARIABLE_|"
    r"MNU_|CST_|CATALOG_|RB_|SCRUPD_|ORTHOPOLY_|PARSER_|INDPM_|COMPARE_|"
    r"SOLVER_|PLOT_|SUM_|MATRIX_|INVALID_|NOPARAM|CONFIRMED|SCREENDUMP|"
    r"dt[A-Z]|am[A-Z])[A-Za-z_0-9]*)"
    r"\s*:?\s*[a-z0-9]*\s*=\s*"
    # a literal, or an arithmetic expression over literals: the assert evaluates it
    r"((?:0?x?[0-9A-Fa-f]+)(?:\s*[-+*]\s*(?:0?x?[0-9A-Fa-f]+))*)\s*;"
)

# Constants that resolve in C but legitimately differ from the owner value.
# Keep this list tiny and always cite why.
#
# EMPTY, and that is the exit criterion. It used to carry
# FIRST_NAMED_RESERVED_VARIABLE (2026 vs C 2031) and its derived
# NUMBER_OF_LETTERED_VARIABLES (26 vs C 31): z47 still named ADM/DENMAX/ISM/
# REALDF/NDEC at 2026-2030 after c43 replaced them with RESERVED_VARIABLE_SPARE
# placeholders and moved the named block to 2031. Two models coexisted in one
# tree -- frontier_config and softmenus already used the new values while the
# range-check owners used the old ones -- and reserved-variable IDs are
# serialized into state files, so it was a real parity gap and not only the
# blocker on converting the register-metadata oracle.
#
# Adding a row here is claiming z47 may differ from c43 on a constant. Do not do
# it to make this audit pass; a divergence that survives review belongs in a
# report with a milestone that closes it.
KNOWN_DIVERGENCES: dict[str, str] = {}

# Base translate-unit: same header prelude as the abi-layout ground-truth oracle,
# plus items.h for the ITM_* enum.
PRELUDE = """\
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include "defines.h"
#include "decContext.h"
#include "decNumber.h"
#include "decQuad.h"
#include "realType.h"
#include "mathematics/pcg_basic.h"
typedef struct _GtkWidget GtkWidget;
#include "typeDefinitions.h"
#include "items.h"
"""


# STD_* glyph byte-strings owners mirror from fonts.h. A wrong byte sequence
# renders the wrong glyph (testSuite-blind). String literals are not integer
# constant expressions, so these need a compile-and-run strcmp, not _Static_assert.
# Allow an optional `: [*:0]const u8`-style type annotation between name and `=`.
STRING_RE = re.compile(r'\bconst (STD_[A-Za-z_0-9]+)\s*(?::[^=;]+)?=\s*("(?:\\.|[^"\\])*")\s*;')

# Locally-renamed glyph aliases: owners that copy a fonts.h STD_* glyph under a
# different const name. Map each to the C macro it must equal so the strcmp still
# reaches it (the name-based #ifdef alone cannot -- the local name is not a macro).
STRING_ALIASES = {
    "std_cross": "STD_CROSS",
    "std_plus_minus": "STD_PLUS_MINUS",
    "std_infinity": "STD_INFINITY",
    "std_degree": "STD_DEGREE",
    "PRODUCT_SIGN": "STD_DOT",
}


def _alias_re(name):
    return re.compile(r"\bconst " + re.escape(name) + r'\s*(?::[^=;]+)?=\s*("(?:\\.|[^"\\])*")\s*;')


def collect_string_mirrors():
    """Return {c_macro: {value_literal: owner}} for STD_* and renamed glyph aliases.
    Keyed by the C macro each owner literal must equal."""
    mirrors = {}
    for path in ZIG_SRC.rglob("*.zig"):
        text = path.read_text(errors="ignore")
        for name, literal in STRING_RE.findall(text):
            mirrors.setdefault(name, {}).setdefault(literal, path.name)
        for local, cmacro in STRING_ALIASES.items():
            for literal in _alias_re(local).findall(text):
                mirrors.setdefault(cmacro, {}).setdefault(literal, f"{path.name}:{local}")
    return mirrors


def check_string_mirrors(zig, tmp):
    """Compile+run a strcmp of every STD_* owner literal against the fonts.h macro.
    Returns (checked, divergences[list of (name, literal, owner)])."""
    mirrors = collect_string_mirrors()
    src = tmp / "string_parity.c"
    checks = []
    for name in sorted(mirrors):
        for literal, owner in sorted(mirrors[name].items()):
            checks.append((name, literal, owner))
    with src.open("w") as f:
        f.write(PRELUDE)
        f.write('#include "fonts.h"\n#include <string.h>\n#include <stdio.h>\n')
        f.write("int main(void){int fails=0;\n")
        for i, (name, literal, _owner) in enumerate(checks):
            # STD_* are #define string macros, so #ifdef filters Zig-local names.
            f.write(f"#ifdef {name}\n")
            f.write(f'  if(strcmp({literal}, {name})){{printf("%d\\n",{i});fails++;}}\n')
            f.write("#endif\n")
        f.write("return fails;}\n")
    exe = tmp / "string_parity"
    comp = subprocess.run(
        [
            zig,
            "cc",
            "-DPC_BUILD=1",
            "-DLINUX=1",
            "-DOS64BIT=1",
            "-I",
            str(upstream_path(ROOT, "dep/decNumberICU")),
            "-I",
            str(upstream_path(ROOT, "src/c47")),
            str(src),
            "-o",
            str(exe),
        ],
        capture_output=True,
        text=True,
    )
    if comp.returncode != 0:
        print("string check: compile failed\n" + comp.stderr[:2000], file=sys.stderr)
        return len(checks), [("<compile-error>", "", "")]
    run = subprocess.run([str(exe)], capture_output=True, text=True)
    bad = [checks[int(x)] for x in run.stdout.split()]
    return len(checks), bad


def normalise_value(value: str) -> str:
    """A mirror's value as a decimal literal, for the cross-owner conflict test.

    Accepts the arithmetic forms owners use to echo a C macro's own spelling
    (`64 + 51` for c43's `64+51`). Only literals and + - * appear, so this stays a
    closed evaluation over ints -- the real comparison against C is still the
    _Static_assert, which sees the expression as written.
    """
    term = value.replace(" ", "")
    for op in "+-*":
        term = term.replace(op, " " + op + " ")
    out = 0
    pending = "+"
    for token in term.split():
        if token in "+-*":
            pending = token
            continue
        n = int(token, 0)
        out = out + n if pending == "+" else out - n if pending == "-" else out * n
    return str(out)


def collect_mirrors():
    """Return {name: value_str}; report names that carry conflicting values."""
    mirrors = {}
    conflicts = []
    for path in ZIG_SRC.rglob("*.zig"):
        for name, value in NAME_RE.findall(path.read_text(errors="ignore")):
            norm = normalise_value(value)
            if name in mirrors and mirrors[name] != norm:
                conflicts.append((name, mirrors[name], norm, path.name))
            else:
                mirrors.setdefault(name, norm)
    return mirrors, conflicts


def main():
    zig = shutil.which("zig")
    if not zig:
        print("SKIP: zig not on PATH", file=sys.stderr)
        return 0

    mirrors, conflicts = collect_mirrors()
    tmp = pathlib.Path(tempfile.mkdtemp())
    src = tmp / "constant_parity.c"
    names = sorted(mirrors)
    with src.open("w") as f:
        f.write(PRELUDE)
        for n in names:
            f.write(f'_Static_assert(({n}) == ({mirrors[n]}), "{n}");\n')

    proc = subprocess.run(
        # -ferror-limit=0: clang's default 20-error cap is consumed by the ~18
        # Zig-local "undeclared identifier" diagnostics, which silently TRUNCATED
        # the audit -- real divergences alphabetically after them (e.g. LAST_ITEM)
        # were never reported. Report every assertion.
        [
            zig,
            "cc",
            "-c",
            "-ferror-limit=0",
            "-DPC_BUILD=1",
            "-DLINUX=1",
            "-DOS64BIT=1",
            "-I",
            str(upstream_path(ROOT, "dep/decNumberICU")),
            "-I",
            str(upstream_path(ROOT, "src/c47")),
            str(src),
            "-o",
            str(tmp / "constant_parity.o"),
        ],
        capture_output=True,
        text=True,
    )
    err = proc.stderr

    # Each failing _Static_assert carries the constant name as its message
    # ("...requirement '(2870) == (2860)': LAST_ITEM"); parse that so the report
    # names the constant even when the preprocessor already substituted its value
    # into the requirement (a #define shows as the value, not the name).
    diverged = sorted(
        set(re.findall(r"static assertion failed due to requirement '.*': ([A-Za-z_0-9]+)", err))
    )
    undeclared = sorted(set(re.findall(r"use of undeclared identifier '([A-Za-z_0-9]+)'", err)))

    print(f"constant-parity audit: {len(mirrors)} C-convention mirrors extracted")
    print(f"  {len(undeclared)} Zig-local (not declared in C, ignored)")
    print(f"  {len(diverged)} resolve in C with a differing value")

    if conflicts:
        print("\nCONFLICT: same name, different values across owners:")
        for name, a, b, where in conflicts:
            print(f"  {name}: {a} vs {b} (at {where})")

    unexpected = [n for n in diverged if n not in KNOWN_DIVERGENCES]
    for n in diverged:
        tag = KNOWN_DIVERGENCES.get(n, "*** UNEXPECTED ***")
        print(f"  DIVERGES {n}: {tag}")

    # STD_* glyph byte-string mirrors (compile-and-run strcmp vs fonts.h).
    str_checked, str_bad = check_string_mirrors(zig, tmp)
    print(f"\nstring-mirror check: {str_checked} STD_* owner literals vs fonts.h")
    for name, literal, owner in str_bad:
        print(f"  STRING DIVERGES {name} = {literal} in {owner}")

    if unexpected or conflicts or str_bad:
        print(
            f"\nFAIL: {len(unexpected)} unexpected value divergence(s), "
            f"{len(conflicts)} conflict(s), {len(str_bad)} string divergence(s)"
        )
        return 1
    allowlisted = (
        f" ({len(KNOWN_DIVERGENCES)} allowlisted)"
        if KNOWN_DIVERGENCES
        else " (nothing allowlisted)"
    )
    print(f"\nPASS: every C-mirrored constant and glyph string matches upstream C{allowlisted}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
