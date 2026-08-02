#!/usr/bin/env python3
"""Rank same-named functions that have DRIFTED between z47's two load families.

WHY THIS EXISTS. z47 keeps a state-file family (`src/core/persist/`) and a
program-file family (`src/core/program/`) that parse different formats with
structurally identical helpers. Twice a fix has been applied to one and not the
other, and neither time did any lane notice:

  * upstream's matrix-dimension capacity clamp -- absent from the Zig for four
    resyncs (M-SAFE-1);
  * the M1 fuzz's saturating `parseU32LineZ` -- fixed in
    program_serialization_runtime.zig while the byte-identical twin in
    calc_state_runtime.zig kept wrapping for three weeks (M-SAFE-4).

Nothing existing can see this class. The parity oracles compare each owner
against upstream C, so two owners that differ from EACH OTHER both look fine, and
the idiom/narrowing ratchets count shapes rather than semantics.

RANKING, and this is the whole design. Divergence between twins is NORMAL -- the
two formats really are different -- so a list of "these differ" is noise. What is
suspicious is a twin pair that is ALMOST identical: a one-operator drift like `*`
versus `*|` is the M-SAFE-4 bug exactly, while a wholesale rewrite is two
functions that merely share a name. So pairs are ranked by similarity DESCENDING
and the near-misses come first.

TWO MODES, two kinds of twin. The default mode ranks same-named functions across
the two directories above. `--macro-families` (M-SAFE-11) compares the members of
one upstream `#define`-generated family against EACH OTHER -- see the section
below. The cross-directory mode stays a REPORT: some divergence there is
legitimate and the false-positive rate is not yet known, so per the REPORT-24 M2
lesson it is not gated. The macro-family mode IS gated, at zero, because a macro
guarantees its members are identical and there is nothing to calibrate away.

Run from the repo root:
  python3 .github/project/report-twin-divergence.py
  python3 .github/project/report-twin-divergence.py --min-similarity 0.5 --show-diff
  python3 .github/project/report-twin-divergence.py --json
  python3 .github/project/report-twin-divergence.py --macro-families
  python3 .github/project/report-twin-divergence.py --check
  python3 .github/project/report-twin-divergence.py --self-test
"""

from __future__ import annotations

import argparse
import difflib
import json
import pathlib
import re
import sys

from upstream_paths import upstream_path

# The two families to compare, each with the identifier stems that NAME it. Same-
# named functions across these directories are treated as twins. Adding a pair
# here is a statement that the two directories hold structurally parallel helpers.
#
# The stems matter as much as the paths. Every paired seam function differs by its
# family's own name -- `z47_calc_state_runtime_display_write_error` against
# `z47_program_serialization_runtime_display_write_error`,
# `use_fake_calc_state_harness_surface` against
# `use_fake_program_serialization_harness_surface` -- and that is not a
# behavioural difference, it is the family label. Left in, those pairs score ~0.86
# and crowd the top of the ranking while the real defect sits below them: measured
# on the tree before M-SAFE-4, the parseU32LineZ bug ranked SEVENTH of eight, under
# five such pairs. Canonicalising the stem drops them to identical and lets the
# ranking mean what it claims.
FAMILIES = (
    ("src/core/persist", ("calc_state",)),
    ("src/core/program", ("program_serialization",)),
)
FAMILY_TOKEN = "FAMILY"

FN_RE = re.compile(r"^(?:pub )?(?:inline |export |noinline )*fn\s+(\w+)")


def strip_noise(line: str) -> str:
    """Drop a line comment, keeping any code before it, and collapse whitespace.

    Comments are removed because twins legitimately document themselves
    differently -- one may carry the upstream citation and the other not -- and a
    prose difference is not a behavioural one. A `//` inside a string or character
    literal is NOT a comment, so both literal forms are tracked; Zig's `'/'` shows
    up in character-class code and would otherwise truncate a line mid-expression.
    """
    out, in_str, in_chr, esc = [], False, False, False
    i = 0
    while i < len(line):
        c = line[i]
        if esc:
            esc = False
        elif c == "\\" and (in_str or in_chr):
            esc = True
        elif c == '"' and not in_chr:
            in_str = not in_str
        elif c == "'" and not in_str:
            in_chr = not in_chr
        elif c == "/" and not in_str and not in_chr and line[i : i + 2] == "//":
            break
        out.append(c)
        i += 1
    return " ".join("".join(out).split())


def canonicalise_family(text: str, stems: tuple[str, ...]) -> str:
    """Replace this family's own name with a neutral token.

    Applied to bodies before comparison so that a seam pair which differs only in
    which family it belongs to compares as identical.
    """
    for stem in stems:
        text = text.replace(stem, FAMILY_TOKEN)
    return text


def function_bodies(path: pathlib.Path) -> dict[str, str]:
    """Map each top-level function name in `path` to its normalised body text."""
    lines = path.read_text().split("\n")
    bodies: dict[str, str] = {}
    i = 0
    while i < len(lines):
        m = FN_RE.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group(1)
        # Walk from the signature to the matching close brace. Depth is counted on
        # the noise-stripped text so a brace inside a comment cannot unbalance it.
        depth, collected, started = 0, [], False
        while i < len(lines):
            clean = strip_noise(lines[i])
            depth += clean.count("{") - clean.count("}")
            if clean.count("{"):
                started = True
            if clean:
                collected.append(clean)
            i += 1
            if started and depth <= 0:
                break
        # Keep the FIRST definition of a name in a file; a redefinition would not
        # compile, so a second hit means the regex matched something it should not.
        bodies.setdefault(name, " ".join(collected))
    return bodies


def collect(root: pathlib.Path, family: str, stems: tuple[str, ...]) -> dict[str, tuple[str, str]]:
    """Map function name -> (relative path, canonicalised body) for one family."""
    out: dict[str, tuple[str, str]] = {}
    for path in sorted((root / family).glob("*.zig")):
        for name, body in function_bodies(path).items():
            out.setdefault(name, (str(path.relative_to(root)), canonicalise_family(body, stems)))
    return out


def compare(root: pathlib.Path) -> list[dict]:
    (a_name, a_stems), (b_name, b_stems) = FAMILIES
    a, b = collect(root, a_name, a_stems), collect(root, b_name, b_stems)
    rows: list[dict] = []
    for name in sorted(set(a) & set(b)):
        (a_path, a_body), (b_path, b_body) = a[name], b[name]
        ratio = difflib.SequenceMatcher(None, a_body, b_body).ratio()
        rows.append(
            {
                "name": name,
                "identical": a_body == b_body,
                "similarity": round(ratio, 4),
                "a": {"file": a_path, "body": a_body},
                "b": {"file": b_path, "body": b_body},
            }
        )
    # Most suspicious first: drifted pairs, closest match at the top.
    rows.sort(key=lambda r: (r["identical"], -r["similarity"], r["name"]))
    return rows


# ---------------------------------------------------------------------------
# Macro families (M-SAFE-11, from finding 10)
#
# A "twin" is not only a cross-directory relationship. Upstream generates whole
# sets of functions from ONE `#define`, which makes them a family that must be
# ported identically -- and the pairing above cannot see it, because every member
# lives in the same file, in the same family. That is exactly how four of the six
# `stringTo*` parsers drifted to a different base and a different overflow answer
# while two kept the macro's shape, with nothing to notice.
#
# The comparison is between MEMBERS of one family rather than against the C: the
# macro guarantees the members are identical to each other, and that is a property
# the ports can be checked against without modelling C semantics. It does not
# check the ports match UPSTREAM -- changing every member the same wrong way keeps
# this green, which is why the behaviour probes in calc_state_parity.c exist too.
# ---------------------------------------------------------------------------

# A two-parameter `#define` continued over further lines. MULTILINE is
# load-bearing: without it `^` anchors to the start of the whole file, NO macro is
# ever found, and the scan reports a clean tree unconditionally. It shipped that
# way for one run, and the calibration below is what caught it.
#
# The parameter NAMES are not required to be `(name, type)`. Upstream happens to
# use that spelling for both of the families it has today -- verified by scanning
# every function-shaped macro in src/c47 -- but pinning the scan to the spelling
# means a resync introducing `somethingFunc(fn, kind)` is silently not scanned,
# and a silent miss is indistinguishable from a clean tree. What identifies a
# function generator is that its body defines one, so that is what is required.
C_MACRO_DEF_RE = re.compile(
    r"^[ \t]*#define[ \t]+(\w+)\(\s*\w+\s*,\s*\w+\s*\)[ \t]*\\\s*\n((?:[^\n]*\\[ \t]*\n)*[^\n]*)",
    re.MULTILINE,
)
TYPE_TOKEN = "TYPE"

# The C type each member is instantiated with, mapped to the Zig type a port uses.
C_TO_ZIG_TYPE = {
    "uint8_t": "u8",
    "uint16_t": "u16",
    "uint32_t": "u32",
    "uint64_t": "u64",
    "int8_t": "i8",
    "int16_t": "i16",
    "int32_t": "i32",
    "int64_t": "i64",
}


def c_macro_families(root: pathlib.Path) -> dict[str, list[tuple[str, str]]]:
    """macro name -> [(generated function name, C type)] across src/c47.

    A macro qualifies when its body DEFINES a function -- it carries a brace --
    which keeps the scan away from the value macros (`MIN(a,b)` and friends), that
    are not families of anything. A family needs more than one invocation: a macro
    used once generates nothing to be inconsistent with.
    """
    families: dict[str, list[tuple[str, str]]] = {}
    for path in sorted(upstream_path(root, "src/c47").glob("**/*.c")):
        text = path.read_text(encoding="utf-8", errors="replace")
        defined = {m.group(1) for m in C_MACRO_DEF_RE.finditer(text) if "{" in m.group(2)}
        for macro in defined:
            invocation = re.compile(
                rf"^\s*{re.escape(macro)}\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)", re.MULTILINE
            )
            members = [(m.group(1), m.group(2)) for m in invocation.finditer(text)]
            if len(members) > 1:
                families.setdefault(macro, []).extend(members)
    return families


def zig_bodies_everywhere(root: pathlib.Path) -> dict[str, tuple[str, str]]:
    """function name -> (relative path, normalised body) across all of src."""
    out: dict[str, tuple[str, str]] = {}
    for path in sorted(root.glob("src/**/*.zig")):
        for name, body in function_bodies(path).items():
            out.setdefault(name, (str(path.relative_to(root)), body))
    return out


def member_shape(body: str, name: str, zig_type: str) -> str:
    """A member's BODY with its target width neutralised.

    The signature is dropped rather than normalised. It is generated by the macro
    and differs between siblings only by name and type, so it carries no signal --
    and normalising it actively misleads: `[*:0]const u8` is the parameter type of
    EVERY member, so blanking the type token turned the `u8` member's signature
    into `[*:0]const TYPE` and reported the whole family as divergent on a tree
    where all six bodies were identical.

    What is kept is everything the macro fixes: which libc function is called,
    which base is passed, whether an out-of-range result is truncated or replaced.
    The base is a bare literal, and keeping literals is exactly what makes
    `base 10` and `base 0` compare unequal.
    """
    inner = body.split("{", 1)[1] if "{" in body else body
    shape = inner.replace(name, "MEMBER")
    return re.sub(rf"\b{re.escape(zig_type)}\b", TYPE_TOKEN, shape).strip()


def compare_macro_families(root: pathlib.Path) -> list[dict]:
    findings: list[dict] = []
    zig = zig_bodies_everywhere(root)
    for macro, members in sorted(c_macro_families(root).items()):
        shapes: dict[str, list[str]] = {}
        missing: list[str] = []
        for fn_name, c_type in members:
            zig_type = C_TO_ZIG_TYPE.get(c_type)
            entry = zig.get(fn_name)
            if entry is None or zig_type is None:
                missing.append(fn_name)
                continue
            path, body = entry
            shapes.setdefault(member_shape(body, fn_name, zig_type), []).append(
                f"{fn_name} ({path})"
            )
        if len(shapes) > 1:
            findings.append(
                {
                    "macro": macro,
                    "members": len(members),
                    "distinct_shapes": len(shapes),
                    "groups": [{"shape": s, "members": sorted(m)} for s, m in shapes.items()],
                    "unported": sorted(missing),
                }
            )
    return findings


def token_diff(a: str, b: str) -> list[str]:
    """The differing runs between two normalised bodies, as compact markers."""
    sm = difflib.SequenceMatcher(None, a.split(), b.split())
    out: list[str] = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        left = " ".join(a.split()[i1:i2]) or "-"
        right = " ".join(b.split()[j1:j2]) or "-"
        out.append(f"      {tag:7} persist: {left}\n              program: {right}")
    return out


def self_test() -> int:
    """Check the two parsing decisions this tool's output actually depends on.

    Both were wrong in an earlier draft, and neither shows up as a crash -- a
    mis-extracted body just compares as "different" and lands in the queue as
    noise, or worse compares as "identical" and hides a real drift.
    """
    checks: list[tuple[str, bool]] = []

    # A `//` inside a string or char literal is not a comment.
    checks.append(
        (
            "string literal with //",
            strip_noise('const s = "http://x"; // trailing') == 'const s = "http://x";',
        )
    )
    checks.append(
        (
            "char literal with /",
            strip_noise("if (c == '/') return; // note") == "if (c == '/') return;",
        )
    )

    # Brace matching must span a multi-line signature and stop at the right place.
    import tempfile

    src = (
        "fn a(\n    x: u8,\n) u8 {\n    if (x > 0) { return 1; }\n    return 0;\n}\n"
        "\nfn b() void {}\n"
    )
    with tempfile.TemporaryDirectory() as td:
        f = pathlib.Path(td) / "t.zig"
        f.write_text(src)
        bodies = function_bodies(f)
    checks.append(("multi-line signature captured", "a" in bodies and "return 0;" in bodies["a"]))
    checks.append(("next function not swallowed", bodies.get("b") == "fn b() void {}"))
    checks.append(("body stops at its own brace", "fn b()" not in bodies.get("a", "")))

    # Family canonicalisation makes a seam pair compare equal.
    checks.append(
        (
            "family stem canonicalised",
            canonicalise_family("z47_calc_state_runtime_x();", ("calc_state",))
            == canonicalise_family(
                "z47_program_serialization_runtime_x();", ("program_serialization",)
            ),
        )
    )

    # --- macro families (M-SAFE-11) ---
    # The first two exist because the scan shipped a run reporting a clean tree
    # for both of these reasons, and a clean report is not distinguishable from a
    # correct one by looking at it.
    macro_c = (
        "#define stringToUintFunc(name, type)              \\\n"
        "  type name(const char *str) {                    \\\n"
        "    return (type)strtoul(str, NULL, 0);           \\\n"
        "  }\n"
        "\n"
        "stringToUintFunc(stringToUint8,  uint8_t)\n"
        "stringToUintFunc(stringToUint16, uint16_t)\n"
    )
    checks.append(
        (
            "macro definition found other than at file start (MULTILINE)",
            [m.group(1) for m in C_MACRO_DEF_RE.finditer(macro_c)] == ["stringToUintFunc"],
        )
    )
    # A value macro is not a family of anything; requiring a brace keeps it out.
    value_macro = "#define MIN(a, b)  \\\n  ((a) < (b) ? (a) : (b))\n"
    checks.append(
        (
            "a value macro is not treated as a function family",
            [m.group(1) for m in C_MACRO_DEF_RE.finditer(value_macro) if "{" in m.group(2)] == [],
        )
    )
    checks.append(
        (
            "macro invocations and their C types extracted",
            re.compile(r"^\s*stringToUintFunc\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)", re.MULTILINE).findall(
                macro_c
            )
            == [("stringToUint8", "uint8_t"), ("stringToUint16", "uint16_t")],
        )
    )
    # Two members of one macro differ ONLY by name and width: same shape. The u8
    # member's parameter type is `[*:0]const u8`, which is why the signature is
    # dropped rather than normalised -- keeping it reported this pair as divergent.
    u8_body = "pub export fn stringToUint8(str: [*:0]const u8) u8 { return @truncate(strtoul(str, null, 0)); }"
    u16_body = "pub export fn stringToUint16(str: [*:0]const u8) u16 { return @truncate(strtoul(str, null, 0)); }"
    checks.append(
        (
            "siblings differing only by name and width share a shape",
            member_shape(u8_body, "stringToUint8", "u8")
            == member_shape(u16_body, "stringToUint16", "u16"),
        )
    )
    # ...and a different base is a different shape, which is finding 10 exactly.
    drifted = (
        "pub export fn stringToUint8(str: [*:0]const u8) u8 { return parseIntCompat(u8, str); }"
    )
    checks.append(
        (
            "a drifted member does NOT share the family shape",
            member_shape(drifted, "stringToUint8", "u8")
            != member_shape(u16_body, "stringToUint16", "u16"),
        )
    )

    failed = 0
    for label, ok in checks:
        print(f"  {'ok  ' if ok else 'FAIL'}  {label}")
        failed += not ok
    print("self-test: " + ("PASS" if not failed else f"{failed} FAILED"))
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--show-diff", action="store_true", help="print the differing token runs")
    ap.add_argument(
        "--min-similarity",
        type=float,
        default=0.0,
        help="only report drifted pairs at least this similar (0.0-1.0)",
    )
    ap.add_argument("--repo-root", default=None, help="scan this tree instead of the default")
    ap.add_argument(
        "--macro-families",
        action="store_true",
        help="report upstream #define-generated families whose z47 ports disagree in shape",
    )
    ap.add_argument(
        "--check",
        action="store_true",
        help="--macro-families, but exit nonzero if any family has disagreeing ports",
    )
    ap.add_argument("--self-test", action="store_true", help="check the extractor and exit")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = (
        pathlib.Path(args.repo_root).resolve()
        if args.repo_root
        else pathlib.Path(__file__).resolve().parents[2]
    )
    if args.macro_families or args.check:
        families = compare_macro_families(root)
        if args.json:
            print(json.dumps(families, indent=2))
        else:
            print("MACRO FAMILY DIVERGENCE -- upstream #define families whose z47 ports disagree")
            print(f"  families with disagreeing ports: {len(families)}\n")
            for f in families:
                print(
                    f"{f['macro']}  ({f['members']} members, {f['distinct_shapes']} distinct shapes)"
                )
                for g in f["groups"]:
                    print(f"    shape: {g['shape'][:150]}")
                    print(f"      members: {', '.join(g['members'])}")
                if f["unported"]:
                    print(f"    no Zig port found for: {', '.join(f['unported'])}")
                print()
            if not families:
                print("  every macro-generated family is ported consistently.")
        if args.check and families:
            print(
                f"MACRO FAMILY DIVERGENCE: {len(families)} upstream #define famil(y/ies) ported "
                "inconsistently. One macro means one behaviour; make the members' bodies agree.",
                file=sys.stderr,
            )
            return 1
        return 0

    rows = compare(root)
    drifted = [r for r in rows if not r["identical"] and r["similarity"] >= args.min_similarity]

    if args.json:
        json.dump({"pairs": rows, "drifted": len(drifted)}, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0

    identical = sum(1 for r in rows if r["identical"])
    print("Twin divergence across the two load families")
    print(f"  families        : {FAMILIES[0][0]} vs {FAMILIES[1][0]}")
    print(f"  shared names    : {len(rows)}")
    print(f"  identical       : {identical}")
    print(f"  drifted         : {len(rows) - identical}")
    print(f"  reported here   : {len(drifted)} (>= {args.min_similarity:.2f} similar)")
    print()
    print("Ranked most-suspicious first: a pair that is ALMOST identical has")
    print("probably had a fix applied to one side only, which is the class this")
    print("exists to catch. A low-similarity pair is usually two different")
    print("functions that share a name -- read it once and move on.")
    print()
    for r in drifted:
        print(f"  {r['similarity']:.3f}  {r['name']}()")
        print(f"           {r['a']['file']}")
        print(f"           {r['b']['file']}")
        if args.show_diff:
            for line in token_diff(r["a"]["body"], r["b"]["body"]):
                print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
