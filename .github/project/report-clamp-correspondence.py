#!/usr/bin/env python3
"""Rank upstream C guards whose Zig counterpart cannot be found.

WHY THIS EXISTS. `check-upstream-correspondence.py` joins SYMBOLS to owners, so it
answers "which owner absorbs this .c". It is blind to the thing that actually bit
us: upstream adding a guard INSIDE a function the Zig already has. Nothing in the
tree compares the two bodies, which is how upstream's matrix-dimension capacity
clamp -- a commented security fix, sitting in `saveRestoreCalcState.c` in plain
sight -- survived four resyncs before M-SAFE-1 ported it.

WHAT A "GUARD" IS HERE. An `if` in the upstream C whose body REJECTS rather than
computes: it zeroes the operands, returns, breaks, or raises a calculator error.
That is the shape upstream uses to refuse file-supplied input, and it is the shape
a 1:1 port is most likely to drop, because dropping it changes nothing that any
test observes until someone feeds the parser a hostile file.

THE SIGNAL, and this is the whole design. Matching guard BODIES is hopeless -- a
faithful port rewrites them freely. Matching the guard's THRESHOLD is not: a bound
is a number or a named constant, and a port that keeps the check keeps the bound,
whatever it does with the syntax around it. So each C guard is reduced to the set
of thresholds its comparisons test against (`> 0xFFFFu` -> 65535,
`>= MAX_LABEL_NAME_LENGTH` -> that name), and the Zig counterpart is searched for
any of them. A guard with no threshold at all -- `if(p == NULL) return;` -- is not
ranked, because there is nothing to match on and null checks are not the class
this hunts.

BOTH SIDES MUST BE READ THE SAME WAY, and getting this wrong cost two calibration
runs. The Zig side collects bounds from COMPARISONS only, exactly as the C side
does. An earlier version collected every number appearing anywhere in the Zig
function; a large function then covered almost any threshold by accident, and the
scan reported a clean queue for a tree with a known live bug.

FOLLOWING CALLS MATTERS TOO. The Zig counterpart of the matrix clamp does not
carry 65535 itself: `restoreRegister` calls `clampMatrixDims`, which calls
`clampToRegisterCapacity`, and only that last one holds `std.math.maxInt(u16)`.
So the search expands TWO call hops into helper bodies and normalises
`maxInt(uN)`/`minInt(iN)` to their values. One hop was measured and still reported
the fixed tree as broken at all three clamp sites. Depth is bounded and each name
expands once, because the call graph is cyclic and a deeper walk dilutes the
evidence until everything looks covered.

CALIBRATION. `--calibrate` reproduces the M-SAFE-1 miss: run against a worktree of
`75dbb6034^` and the matrix clamp must appear. Note that the milestone spec named
`811c9905d` as the calibration tree; at that pin `restoreRegister` had not been
ported to Zig at all, so there was no owner for the guard to be missing FROM. The
first tree where the miss is expressible is the parent of the commit that fixed it.

A REPORT that also RATCHETS, which is a deliberate departure from the milestone's
"gate only once the queue is empty". The queue is not empty: two load-path entries
remain, both triaged and neither a dropped guard (`fnDeleteBackup` is a reduced
port that branches on nothing, and the state-file version range lives in
`calc_state_header.zig` rather than in `restoreOneSection`). Waiting for zero
before gating would leave the next resync unprotected for the sake of a number,
and resync protection is the entire reason this exists. So `--check` fixes the
count where it stands and fails if it RISES -- the same shape as the absence
ratchet in check-upstream-correspondence.py. The REPORT-24 M2 objection is to
judging before calibrating; this is calibrated in both directions, against a tree
with the bug and a tree without it.

`--check` runs the self-test first. A scan whose extractor has quietly broken
reports a clean queue, and a clean queue from a broken tool is precisely the
failure this milestone was written to end.

Run from the repo root:
  python3 .github/project/report-clamp-correspondence.py
  python3 .github/project/report-clamp-correspondence.py --all-files --json
  python3 .github/project/report-clamp-correspondence.py --repo-root /tmp/old-tree
  python3 .github/project/report-clamp-correspondence.py --check
  python3 .github/project/report-clamp-correspondence.py --self-test
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
BASELINE = HERE / "clamp-correspondence-baseline.json"

# Slice 8.1's scope: the upstream load path, where a dropped guard means a hostile
# file reaches memory. --all-files widens to every .c once this queue is empty.
LOAD_PATH_FILES = (
    "saveRestoreCalcState.c",
    "config.c",
    "graphText.c",
)

# Bodies that REJECT rather than compute. `= 0` covers upstream's habit of zeroing
# the offending operands (`rows = cols = 0;`), which is the matrix clamp exactly.
REJECT_PATTERNS = (
    re.compile(r"\breturn\b"),
    re.compile(r"\bbreak\b"),
    re.compile(r"\bcontinue\b"),
    re.compile(r"=\s*0\s*[;,]"),
    re.compile(r"\bdisplayCalcErrorMessage\b"),
    re.compile(r"\bdisplayBugScreen\b"),
)

# A comment on the guard is upstream TELLING us the check matters. The matrix clamp
# carried one for four resyncs and nobody read it, so it ranks first here.
INTENT_WORDS = re.compile(
    r"\b(refuse|reject|overflow|out of bounds|out-of-bounds|truncat|"
    r"under-allocate|crash|corrupt|hostile|crafted|clamp|bogus|lie)",
    re.IGNORECASE,
)

COMPARISON = re.compile(r"(>=|<=|==|!=|>|<)\s*([A-Za-z_]\w*|0[xX][0-9a-fA-F]+|\d+)")
MACRO_NAME = re.compile(r"^[A-Z][A-Z0-9_]{3,}$")

# ALL_CAPS names that are sentinels rather than BOUNDS. A null or boolean check is
# not the class this hunts, and `NULL` appears in nearly every function on both
# sides, so leaving it in would match everything and rank nothing.
NON_BOUND = frozenset({"NULL", "TRUE", "FALSE", "NOPARAM"})

# <stdint.h> limit macros carry a VALUE, and a port is free to write the value.
# Upstream's program-load guard says `> UINT16_MAX` where the Zig owner says
# `> 0xFFFF`; without this table that identical bound reads as a dropped guard.
LIMIT_MACROS = {
    "UINT8_MAX": "255",
    "INT8_MAX": "127",
    "UINT16_MAX": "65535",
    "INT16_MAX": "32767",
    "UINT32_MAX": "4294967295",
    "INT32_MAX": "2147483647",
    "UINT64_MAX": "18446744073709551615",
    "INT64_MAX": "9223372036854775807",
}
MAXINT = re.compile(r"\b(maxInt|minInt)\s*\(\s*([iu])(\d+)\s*\)")
C_COMMENT = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)


def strip_c_comments(text: str) -> str:
    """Blank comments but keep every offset and newline.

    Length-preserving on purpose: offsets into the stripped text index the RAW
    text, which is what lets a guard be PARSED without its comments and then have
    its intent comment read back out of the original.
    """
    return C_COMMENT.sub(lambda m: re.sub(r"[^\n]", " ", m.group(0)), text)


def normalise_int(tok: str) -> int | None:
    """A threshold's VALUE, so `0xFFFFu` and `65535` compare equal."""
    t = tok.rstrip("uUlL")
    try:
        return int(t, 16) if t.lower().startswith("0x") else int(t)
    except ValueError:
        return None


SIGNATURE = re.compile(r"([A-Za-z_]\w*)\s*\([^()]*\)\s*$")


def c_functions(text: str) -> list[tuple[str, int, str]]:
    """(name, 1-based start line, raw body) for each top-level C function.

    Character-wise brace-depth scan rather than a line-wise one. The name is taken
    by looking BACK from the brace that opens depth 1: a function body is the only
    top-level `{` preceded by `name(params)`, so struct initialisers, array
    literals and `extern "C" {` fall out for free. A line-wise scan got this wrong
    -- it attributed the matrix clamp to the function AFTER the one holding it.
    """
    clean = strip_c_comments(text)
    out: list[tuple[str, int, str]] = []
    depth = 0
    opened_at: tuple[str, int] | None = None
    for i, ch in enumerate(clean):
        if ch == "{":
            if depth == 0:
                head = clean[max(0, i - 400) : i].rstrip()
                m = SIGNATURE.search(head)
                opened_at = (m.group(1), i) if m else None
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and opened_at is not None:
                name, start = opened_at
                out.append((name, clean.count("\n", 0, start) + 1, text[start : i + 1]))
                opened_at = None
            if depth < 0:
                depth = 0
    return out


def balanced_condition(text: str, open_idx: int) -> tuple[str, int] | None:
    """The text inside the parens starting at `open_idx`, and the index after."""
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[open_idx + 1 : i], i + 1
    return None


def guard_body(text: str, after: int) -> str:
    """The guard's consequent: a braced block, or the single statement after it."""
    rest = text[after : after + 400]
    stripped = rest.lstrip()
    if stripped.startswith("{"):
        offset = len(rest) - len(stripped)
        depth = 0
        for i in range(offset, len(rest)):
            if rest[i] == "{":
                depth += 1
            elif rest[i] == "}":
                depth -= 1
                if depth == 0:
                    return rest[offset : i + 1]
        return rest
    return stripped.split(";")[0] + ";"


def thresholds(condition: str) -> set[str]:
    """The bounds a condition tests against, as comparable tokens.

    Numbers become their decimal value so `0xFFFFu` matches `65535`; ALL_CAPS names
    stay as names, because a port that keeps the bound keeps the constant's name.
    Bare 0 and 1 are dropped: they are the sentinel/emptiness checks that every
    function has, and they match everything.
    """
    found: set[str] = set()
    for m in COMPARISON.finditer(condition):
        rhs = m.group(2)
        value = normalise_int(rhs)
        if value is not None:
            if value > 1:
                found.add(str(value))
            continue
        if rhs in LIMIT_MACROS:
            found.add(LIMIT_MACROS[rhs])
            continue
        # `> TO_BYTES(n)` compares against a COMPUTED size, not a named bound: the
        # macro is the arithmetic, not the threshold. Matching on its name reports
        # every owner that inlines the same arithmetic as missing the guard.
        if condition[m.end() : m.end() + 1] == "(":
            continue
        if MACRO_NAME.match(rhs) and rhs not in NON_BOUND:
            found.add(rhs.upper())
    return found


def c_guards(body: str) -> list[dict]:
    """Rejection-shaped `if`s in a C function body, with their thresholds."""
    clean = strip_c_comments(body)
    out: list[dict] = []
    for m in re.finditer(r"\bif\s*\(", clean):
        got = balanced_condition(clean, m.end() - 1)
        if got is None:
            continue
        condition, after = got
        consequent = guard_body(clean, after)
        if not any(p.search(consequent) for p in REJECT_PATTERNS):
            continue
        bounds = thresholds(condition)
        if not bounds:
            continue
        # Offsets into `clean` index `body` too -- the strip is length-preserving --
        # so the intent comment is read straight out of the raw text above the `if`.
        out.append(
            {
                "condition": " ".join(condition.split())[:150],
                "thresholds": sorted(bounds),
                "commented": bool(INTENT_WORDS.search(body[max(0, m.start() - 400) : m.start()])),
                "line_offset": clean.count("\n", 0, m.start()),
            }
        )
    return out


def zig_functions(root: pathlib.Path) -> dict[str, list[str]]:
    """name -> bodies. A name can be defined in more than one owner."""
    out: dict[str, list[str]] = {}
    sig = re.compile(r"^(?:pub\s+)?(?:export\s+|inline\s+)*fn\s+(\w+)\s*\(", re.MULTILINE)
    for path in sorted(root.glob("zig_src/**/*.zig")):
        text = path.read_text(encoding="utf-8", errors="replace")
        marks = [(m.group(1), m.start()) for m in sig.finditer(text)]
        for i, (name, pos) in enumerate(marks):
            end = marks[i + 1][1] if i + 1 < len(marks) else len(text)
            out.setdefault(name, []).append(text[pos:end])
    return out


CALL_DEPTH = 2


def expand_calls(body: str, table: dict[str, list[str]], depth: int = CALL_DEPTH) -> str:
    """Body plus the bodies of the helpers it calls, to `depth` hops.

    Without this the FIXED tree reports as broken, because a port that keeps a
    guard is free to put the bound in a helper. The matrix clamp needs TWO hops --
    `restoreRegister` calls `clampMatrixDims`, which calls `clampToRegisterCapacity`,
    and only that last one holds `std.math.maxInt(u16)`. One hop was measured and
    still reported the fixed tree as broken at all three of its clamp sites.

    Depth is bounded and each name is expanded once: the call graph here is cyclic
    (owners call back into their own module), so an unbounded walk does not
    terminate and a deep one dilutes the evidence until everything looks covered.
    """
    parts = [body]
    seen: set[str] = set()
    frontier = [body]
    for _ in range(depth):
        nxt: list[str] = []
        for text in frontier:
            for callee in set(re.findall(r"\b(\w+)\s*\(", text)):
                if callee in seen:
                    continue
                seen.add(callee)
                for helper in table.get(callee, ())[:3]:
                    parts.append(helper)
                    nxt.append(helper)
        frontier = nxt
    return "\n".join(parts)


ZIG_COMPARISON = re.compile(r"(>=|<=|==|!=|>|<)\s*([A-Za-z_][\w.]*|0[xX][0-9a-fA-F_]+|\d[\d_]*)")


def zig_bounds(text: str) -> set[str]:
    """The bounds Zig text COMPARES against, normalised to match the C side.

    Symmetric with `thresholds()` on purpose, and the symmetry is load-bearing.
    An earlier version collected every number appearing anywhere in the function
    and its helpers, which made a large function cover almost any threshold by
    accident: at the calibration tree it swallowed the matrix clamp and the scan
    reported a clean queue for a tree with a known live bug. A bound only counts
    if the Zig actually TESTS against it.
    """
    found: set[str] = set()
    # maxInt/minInt are bounds wherever they appear -- that is all they are for.
    for kind, sign, width in MAXINT.findall(text):
        bits = int(width)
        if kind == "maxInt":
            found.add(str((1 << (bits - 1)) - 1 if sign == "i" else (1 << bits) - 1))
        else:
            found.add(str(-(1 << (bits - 1)) if sign == "i" else 0))
    for _op, rhs in ZIG_COMPARISON.findall(text):
        value = normalise_int(rhs.replace("_", ""))
        if value is not None:
            if value > 1:
                found.add(str(value))
            continue
        # `abi.MAX_LABEL_NAME_LENGTH` carries the same bound as the C macro; the
        # namespace it is reached through is not part of the name. And porting a
        # C macro into a struct field lowercases it -- upstream's
        # `RAM_SIZE_IN_BLOCKS` is `geo.ram_size_in_blocks` here -- so names compare
        # case-insensitively, which is exactly the correspondence being checked.
        leaf = rhs.rsplit(".", 1)[-1].upper()
        if MACRO_NAME.match(leaf) and leaf not in NON_BOUND:
            found.add(leaf)
    return found


def zig_bound_index(root: pathlib.Path) -> dict[str, list[str]]:
    """threshold -> where in zig_src something COMPARES against it.

    Triage aid, not a filter. z47 sometimes moves a guard to a different owner than
    the C function that holds it -- the state-file version range lives in
    `calc_state_header.zig`, not in `restoreOneSection` -- and such a finding is a
    false positive that costs a search to dismiss. Annotating is the right response
    rather than widening the match: widening to the whole tree would ALSO swallow
    the M-SAFE-1 miss, because `maxInt(u16)` is compared against all over the tree.
    So the queue still reports it, and just says where else to look.
    """
    index: dict[str, list[str]] = {}
    for path in sorted(root.glob("zig_src/**/*.zig")):
        rel = path.relative_to(root)
        for n, line in enumerate(
            path.read_text(encoding="utf-8", errors="replace").splitlines(), 1
        ):
            for bound in zig_bounds(line):
                index.setdefault(bound, []).append(f"{rel}:{n}")
    return index


HAS_BRANCH = re.compile(r"\bif\s*\(|\bswitch\s*\(|\bwhile\s*\(")


def looks_like_stub(bodies: list[str]) -> bool:
    """A Zig owner that branches on nothing cannot be missing one guard.

    `fnDeleteBackup` is `_ = confirmation;` and nothing else -- a reduced port, not
    a dropped clamp. Reporting each of its C guards separately says the same thing
    three times and buries the real finding underneath.
    """
    return all(len(b) < 600 and not HAS_BRANCH.search(b) for b in bodies)


def scan(root: pathlib.Path, all_files: bool) -> list[dict]:
    zig = zig_functions(root)
    index = zig_bound_index(root)
    findings: list[dict] = []
    sources = sorted((root / "src" / "c47").glob("**/*.c"))
    if not all_files:
        sources = [p for p in sources if p.name in LOAD_PATH_FILES]
    for path in sources:
        text = path.read_text(encoding="utf-8", errors="replace")
        for name, line, body in c_functions(text):
            guards = c_guards(body)
            if not guards:
                continue
            counterparts = zig.get(name)
            if not counterparts:
                continue  # no Zig owner by this name: correspondence's job, not ours
            covered = set()
            for candidate in counterparts:
                covered |= zig_bounds(expand_calls(candidate, zig))
            stub = looks_like_stub(counterparts)
            unmatched = [g for g in guards if not (set(g["thresholds"]) & covered)]
            if stub and unmatched:
                # One finding for the owner, not one per guard it cannot hold.
                findings.append(
                    {
                        "c_file": str(path.relative_to(root)),
                        "c_function": name,
                        "c_line": line,
                        "condition": f"<{len(unmatched)} guards; the Zig owner is a stub>",
                        "thresholds": sorted({t for g in unmatched for t in g["thresholds"]}),
                        "commented": any(g["commented"] for g in unmatched),
                        "stub_owner": True,
                        "elsewhere": [],
                    }
                )
                continue
            for guard in unmatched:
                findings.append(
                    {
                        "c_file": str(path.relative_to(root)),
                        "c_function": name,
                        "c_line": line + guard["line_offset"],
                        "condition": guard["condition"],
                        "thresholds": guard["thresholds"],
                        "commented": guard["commented"],
                        "stub_owner": False,
                        "elsewhere": sorted(
                            {loc for t in guard["thresholds"] for loc in index.get(t, ())[:2]}
                        ),
                    }
                )
    # Strongest evidence first: upstream said in words that the check matters, and
    # nothing anywhere in the tree compares against its bound.
    findings.sort(
        key=lambda f: (
            not f["commented"],
            bool(f["elsewhere"]),
            f["stub_owner"],
            f["c_file"],
            f["c_line"],
        )
    )
    return findings


SELF_TEST_C = """
static void restoreRegister(int regist) {
  uint16_t rows, cols;
  rows = toUint16(value);
  // Refuse file-supplied dimensions that would overflow it, or reallocateRegister
  // would truncate the size and write out of bounds.
  if((uint64_t)rows * cols * REAL34_SIZE_IN_BLOCKS + TO_BLOCKS(sizeof(matrixHeader_t)) > 0xFFFFu) {
    rows = cols = 0;
  }
  reallocateRegister(regist, dtReal34Matrix, rows * cols, tag);
}

static void unrelated(void) {
  if(pointer == NULL) return;
  total = a + b;
}
"""


def self_test() -> int:
    """The extractor's own contract, checked without touching the tree."""
    failures: list[str] = []

    fns = {n: b for n, _l, b in c_functions(SELF_TEST_C)}
    if set(fns) != {"restoreRegister", "unrelated"}:
        failures.append(f"c_functions found {sorted(fns)}")

    guards = c_guards(fns.get("restoreRegister", ""))
    if len(guards) != 1:
        failures.append(f"expected 1 guard in restoreRegister, got {len(guards)}")
    elif "65535" not in guards[0]["thresholds"]:
        failures.append(f"0xFFFFu did not normalise to 65535: {guards[0]['thresholds']}")
    elif not guards[0]["commented"]:
        failures.append("the intent comment above the guard was not detected")

    # A null check has no threshold, so it must not enter the queue at all.
    if c_guards(fns.get("unrelated", "")):
        failures.append("a bare null check was ranked as a guard")

    if thresholds("(uint64_t)n + 2 > UINT16_MAX") != {"65535"}:
        failures.append("UINT16_MAX did not normalise to 65535")
    if thresholds("size > TO_BYTES(blocks)"):
        failures.append("a function-like macro was ranked as a threshold")
    if "RAM_SIZE_IN_BLOCKS" not in zig_bounds("if (b >= geo.ram_size_in_blocks) return;"):
        failures.append("a lowercased ported macro did not match its C name")
    if zig_bounds("if (n > std.math.maxInt(u16)) return;") < {"65535"}:
        failures.append("maxInt(u16) did not normalise to 65535")
    if "127" not in zig_bounds("x < std.math.maxInt(i8)"):
        failures.append("maxInt(i8) did not normalise to 127")

    # One-hop expansion is the rule that keeps the FIXED tree quiet.
    table = {"clampToRegisterCapacity": ["fn clampToRegisterCapacity() { if (n > 65535) {} }"]}
    if "65535" not in zig_bounds(expand_calls("x = clampToRegisterCapacity(d);", table)):
        failures.append("call expansion did not reach the helper's bound")

    for line in failures:
        print(f"SELF-TEST FAIL: {line}")
    if failures:
        return 1
    print("SELF-TEST OK: extractor, threshold normalisation and call expansion")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument(
        "--all-files",
        action="store_true",
        help="scan every src/c47 .c, not just the load path",
    )
    ap.add_argument("--repo-root", default=None, help="scan this tree instead of the default")
    ap.add_argument(
        "--calibrate",
        action="store_true",
        help="require the M-SAFE-1 matrix clamp in the queue, and exit nonzero if absent",
    )
    ap.add_argument("--self-test", action="store_true", help="check the extractor and exit")
    ap.add_argument(
        "--check",
        action="store_true",
        help="self-test, then fail if the load-path queue grew above its committed baseline",
    )
    ap.add_argument(
        "--write-baseline", action="store_true", help="rewrite the baseline to the current count"
    )
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = (
        pathlib.Path(args.repo_root)
        if args.repo_root
        else pathlib.Path(__file__).resolve().parents[2]
    )

    if args.check:
        # Tool rot first: a scan whose extractor has broken reports a clean queue,
        # which is the failure mode this whole milestone exists to prevent.
        if self_test() != 0:
            return 1
        count = len(scan(root, all_files=False))
        ceiling = json.loads(BASELINE.read_text())["load_path_queue"]
        if count > ceiling:
            print(
                f"CLAMP CORRESPONDENCE REGRESSION: load-path queue = {count}, baseline {ceiling}. "
                "An upstream guard on the load path has no threshold match in its Zig owner. "
                "Run this script with no arguments to see which, port the guard or explain it, "
                "then lower the baseline with --write-baseline in the same commit.",
                file=sys.stderr,
            )
            return 1
        note = "at baseline" if count == ceiling else f"below baseline {ceiling}"
        print(f"clamp_correspondence: load-path queue = {count} ({note})")
        return 0

    findings = scan(root, args.all_files)

    if args.write_baseline:
        BASELINE.write_text(
            json.dumps({"load_path_queue": len(scan(root, all_files=False))}, indent=2) + "\n"
        )
        print(f"wrote baseline: load_path_queue = {len(scan(root, all_files=False))}")
        return 0

    if args.json:
        print(json.dumps(findings, indent=2))
    else:
        scope = "every src/c47 .c" if args.all_files else ", ".join(LOAD_PATH_FILES)
        print("CLAMP CORRESPONDENCE -- upstream guards with no threshold match in the Zig owner")
        print(f"  scope: {scope}")
        print(f"  queue: {len(findings)}\n")
        for f in findings:
            flag = "COMMENTED " if f["commented"] else ""
            print(f"{flag}{f['c_file']}:{f['c_line']} {f['c_function']}()")
            print(f"    if ({f['condition']})")
            print(
                f"    thresholds not found in Zig {f['c_function']}(): {', '.join(f['thresholds'])}"
            )
            if f["stub_owner"]:
                print(
                    "    NOTE: the Zig owner branches on nothing -- a reduced port, not a dropped guard."
                )
            elif f["elsewhere"]:
                print(f"    but compared against at: {', '.join(f['elsewhere'])}")
            else:
                print("    and compared against NOWHERE in zig_src -- strongest signal.")
            print()

    if args.calibrate:
        hit = [
            f
            for f in findings
            if f["c_function"] == "restoreRegister" and "65535" in f["thresholds"]
        ]
        if not hit:
            print(
                "CALIBRATION FAIL: the M-SAFE-1 matrix clamp was not rediscovered. "
                "A scan that cannot find the bug we already know about will not find the next one.",
                file=sys.stderr,
            )
            return 1
        print(f"CALIBRATION OK: rediscovered the M-SAFE-1 miss ({len(hit)} guard(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
