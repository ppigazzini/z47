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
NAME_RE = re.compile(
    r"\bconst ((?:ITM_|TM_|FLAG_|ERROR_|TI_|SETTING_|CM_|PGM_|MAX_|MIN_|"
    r"NUMBER_OF_|SIZE_OF_|LAST_|FIRST_|REGISTER_|RESERVED_VARIABLE_|"
    r"MNU_|CST_|CATALOG_|RB_|SCRUPD_|ORTHOPOLY_|PARSER_|INDPM_|COMPARE_|"
    r"SOLVER_|PLOT_|SUM_|MATRIX_|dt[A-Z]|am[A-Z])[A-Za-z_0-9]*)"
    r"\s*:?\s*[a-z0-9]*\s*=\s*(0?x?[0-9A-Fa-f]+)\s*;"
)

# Constants that resolve in C but legitimately differ from the owner value.
# Keep this list tiny and always cite why.
KNOWN_DIVERGENCES = {
    # Deferred: the whole reserved-variable block is stale (OLD ADM/.. @2026 vs
    # current C ACC/.. @2031). Partial-fixing just this base would desync it from
    # LAST_RESERVED_VARIABLE and the RESERVED_VARIABLE_* body -- a parity-risky
    # reorganization deferred with near-zero practical impact. See the memory note
    # reserved-variable-model-stale.
    "FIRST_NAMED_RESERVED_VARIABLE": "deferred stale reserved-variable block (2026 vs C 2031)",
    # Derived from the above: defines.h computes it as (FIRST_NAMED_RESERVED_VARIABLE
    # - FIRST_RESERVED_VARIABLE), so the owner's 26 vs C's 31 is the SAME deferred
    # reserved-variable staleness, not an independent bug. Was previously hidden by
    # the clang error-limit truncation this audit just removed.
    "NUMBER_OF_LETTERED_VARIABLES": "derived from the deferred reserved-variable block (26 vs C 31)",
}

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


def collect_mirrors():
    """Return {name: value_str}; report names that carry conflicting values."""
    mirrors = {}
    conflicts = []
    for path in ZIG_SRC.rglob("*.zig"):
        for name, value in NAME_RE.findall(path.read_text(errors="ignore")):
            norm = str(int(value, 0))  # normalise hex/dec to a decimal literal
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
    print(
        "\nPASS: every C-mirrored constant and glyph string matches upstream C "
        "(known-deferred exceptions allowlisted)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
