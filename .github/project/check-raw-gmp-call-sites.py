#!/usr/bin/env python3
"""Long integer arithmetic goes through the overflow-checked operators, or says why not.

WHY THIS EXISTS. c43 gives longIntegerMultiply, longIntegerAdd and
longIntegerSubtract external linkage in integers.c, and each refuses a result wider
than MAX_LONG_INTEGER_SIZE_IN_BITS and reports an overflow. Twenty-three Zig call
sites across eight owners called the raw GMP entry points instead. Nineteen of them
answered where c43 raises an overflow error. The other two were in a loop that
squares its operand once per bit of an exponent, so with the refusal gone the
operand doubled every pass until the host ran out of memory -- on a shipping owner,
reached from an ordinary keystroke.

The guard was ported. It was exported. A sibling owner already used it. Nothing
noticed that most owners did not, because a missing bound is invisible until an
operand is large enough to need it, and no fixture was.

WHAT IT SCANS. Calls to the three growth operations under src/, in either spelling:
the __gmpz_ symbol directly, or a file-local alias of it. Extern declarations and
the alias definitions themselves are not call sites.

WHAT IT DOES NOT SCAN, per the rule that a gate states its own domain:

  - the _ui and _2exp variants. c43's longIntegerMultiplyUInt, longIntegerAddUInt
    and longIntegerMultiply2 are raw macros upstream too, so routing them through a
    checked operator would be a divergence, not a fix.
  - division, comparison, roots, and every other GMP entry point: none can produce a
    result wider than its operands.
  - the C under upstream/, which is the reference and is not ours to change.
  - build/tests/. A harness may legitimately do arithmetic the calculator cannot,
    and its own resource budget is what bounds it.

EXEMPTIONS COST A REASON. ALLOWED_FILES holds the implementations themselves.
Anything else needs a row in ALLOWED_SITES with a written reason -- an operand whose
width is bounded by its own conversion, a place where c43 demonstrably uses the raw
call. A site without a reason fails, on the same argument as every other manifest
here: a decision with a reason is a decision, one without is an oversight that
learned to hide.

Usage:
  check-raw-gmp-call-sites.py [--repo-root .]
  check-raw-gmp-call-sites.py --self-test   # prove the gate fires
"""

from __future__ import annotations

import argparse
import re
import sys
import tempfile
from pathlib import Path

# The three operations whose result can be wider than their operands, and which c43
# therefore routes through a checked wrapper.
GROWTH_OPS = ("mul", "add", "sub")

# The implementations of the checked operators. They perform the raw operation after
# taking the width decision, which is the whole point of them.
ALLOWED_FILES = {
    "src/shell/convert/integers.zig": (
        "the overflow-checked operators themselves: each calls the raw entry point "
        "only after comparing operand width against MAX_LONG_INTEGER_SIZE_IN_BITS"
    ),
}

# Individual sites that are raw for a stated reason. Keyed "path:line" is deliberately
# NOT used -- a line number rots on the next edit. Keyed by path plus the exact call
# text, so the reason survives a move and dies with the call.
ALLOWED_SITES: dict[tuple[str, str], str] = {}

CALL_RE = re.compile(r"(?:^|[^\w.])(?:(\w+)\.)?(__gmpz_|mpz_)(mul|add|sub)\s*\(")
ALIAS_RE = re.compile(r"^\s*(?:pub\s+)?const\s+mpz_(?:mul|add|sub)\s*=")
EXTERN_RE = re.compile(r"\bextern\s+fn\b")


def scan(repo_root: Path) -> list[tuple[str, int, str]]:
    """Every raw growth call under src/, as (path, line number, call text)."""
    found: list[tuple[str, int, str]] = []
    for path in sorted((repo_root / "src").rglob("*.zig")):
        rel = path.relative_to(repo_root).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
            code = line.split("//")[0]
            if EXTERN_RE.search(code) or ALIAS_RE.match(code):
                continue
            match = CALL_RE.search(code)
            if match and match.group(3) in GROWTH_OPS:
                found.append((rel, number, code.strip()))
    return found


def check(repo_root: Path) -> int:
    unexplained: list[tuple[str, int, str]] = []
    allowed_count = 0

    for rel, number, text in scan(repo_root):
        if rel in ALLOWED_FILES:
            allowed_count += 1
            continue
        if (rel, text) in ALLOWED_SITES:
            allowed_count += 1
            continue
        unexplained.append((rel, number, text))

    for path, reason in sorted(ALLOWED_FILES.items()):
        if not (repo_root / path).exists():
            print(f"FAIL: {path} is allowed to hold raw calls but does not exist")
            return 1
        print(f"  ALLOWED  {path}: {reason}")

    if unexplained:
        print()
        print(f"FAIL: {len(unexplained)} raw GMP growth call(s) outside the checked operators:")
        for rel, number, text in unexplained:
            print(f"  {rel}:{number}  {text}")
        print()
        print("Route each through longIntegerMultiply / longIntegerAdd / longIntegerSubtract")
        print("with c43's own argument order, or add it to ALLOWED_SITES with a reason.")
        return 1

    print("PASS: every long integer add, subtract and multiply under src/ is width-checked")
    print(f"      ({allowed_count} raw call(s), all inside the checked operators or explained)")
    return 0


def self_test(repo_root: Path) -> int:
    """A gate that has never fired is a claim, not a check."""
    failures = 0

    with tempfile.TemporaryDirectory() as tmp:
        fake = Path(tmp)
        (fake / "src" / "core").mkdir(parents=True)
        (fake / "src" / "shell" / "convert").mkdir(parents=True)
        (fake / "src" / "shell" / "convert" / "integers.zig").write_text(
            "extern fn __gmpz_mul(r: *T, a: *const T, b: *const T) void;\n"
            "const mpz_mul = __gmpz_mul;\n"
            "pub export fn longIntegerMultiply() void { mpz_mul(r, a, b); }\n",
            encoding="utf-8",
        )

        clean = fake / "src" / "core" / "clean.zig"
        clean.write_text(
            "// a comment mentioning __gmpz_mul( must not count\n"
            "extern fn __gmpz_mul(r: *T, a: *const T, b: *const T) void;\n"
            "pub fn f() void { runtime.longIntegerMultiply(&y, &x, &x); }\n"
            "pub fn g() void { runtime.__gmpz_mul_ui(&x, &x, 2); }\n"
            "pub fn h() void { runtime.__gmpz_tdiv_q_ui(&x, &x, 2); }\n",
            encoding="utf-8",
        )
        if check(fake) != 0:
            print("SELF-TEST FAIL: a clean tree did not pass")
            failures += 1

        clean.write_text("pub fn f() void { runtime.__gmpz_mul(&x, &x, &x); }\n", encoding="utf-8")
        if check(fake) == 0:
            print("SELF-TEST FAIL: a raw multiply was not caught")
            failures += 1

        clean.write_text("pub fn f() void { runtime.__gmpz_add(&x, &y, &x); }\n", encoding="utf-8")
        if check(fake) == 0:
            print("SELF-TEST FAIL: a raw add was not caught")
            failures += 1

    print()
    if failures:
        print(f"SELF-TEST: {failures} failure(s)")
        return 1
    print("SELF-TEST: the gate passes a clean tree and fires on a raw call")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    if args.self_test:
        return self_test(repo_root)
    return check(repo_root)


if __name__ == "__main__":
    sys.exit(main())
