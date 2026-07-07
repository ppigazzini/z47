#!/usr/bin/env python3
"""Constant-parity audit: every defines.h/enum value a Zig owner hardcodes must
match the upstream C.

Owners mirror hundreds of C #define/enum values (item codes ITM_*, error codes
ERROR_*, flags FLAG_*, register indices REGISTER_*, temporary-info TI_*, calc
modes CM_*, the register data-type enum dt*, ...). constants_parity.zig is a
behavioral fnConstant/fnPi oracle -- NOT a value gate -- so before this tool
these mirrors had no continuous protection, and several have a documented history
of silently going stale on an edit (TM_CMP was 10021, dtReal34 was 0, ...).

This audit extracts every C-convention-named constant from zig_src, emits one
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

ROOT = pathlib.Path(__file__).resolve().parents[2]
ZIG_SRC = ROOT / "zig_src"

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
        [zig, "cc", "-c", "-DPC_BUILD=1", "-DLINUX=1", "-DOS64BIT=1",
         "-I", str(ROOT / "dep/decNumberICU"), "-I", str(ROOT / "src/c47"),
         str(src), "-o", str(tmp / "constant_parity.o")],
        capture_output=True, text=True,
    )
    err = proc.stderr

    diverged = sorted(set(re.findall(r"requirement '\(([A-Za-z_0-9]+)\) == \(\d+\)'", err)))
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

    if unexpected or conflicts:
        print(f"\nFAIL: {len(unexpected)} unexpected divergence(s), "
              f"{len(conflicts)} conflict(s)")
        return 1
    print("\nPASS: every C-mirrored constant matches upstream C "
          "(known-deferred exceptions allowlisted)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
