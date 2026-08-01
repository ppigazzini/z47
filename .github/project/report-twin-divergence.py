#!/usr/bin/env python3
"""Rank same-named functions that have DRIFTED between z47's two load families.

WHY THIS EXISTS. z47 keeps a state-file family (`zig_src/core/persist/`) and a
program-file family (`zig_src/core/program/`) that parse different formats with
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

This is a REPORT, not a gate. Some divergence is legitimate and the false-positive
rate is not yet known; per the REPORT-24 M2 lesson, a heuristic that judges before
it is calibrated gets ignored. Gate it only once the queue is empty.

Run from the repo root:
  python3 .github/project/report-twin-divergence.py
  python3 .github/project/report-twin-divergence.py --min-similarity 0.5 --show-diff
  python3 .github/project/report-twin-divergence.py --json
"""

from __future__ import annotations

import argparse
import difflib
import json
import pathlib
import re
import sys

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
    ("zig_src/core/persist", ("calc_state",)),
    ("zig_src/core/program", ("program_serialization",)),
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
    checks.append((
        "string literal with //",
        strip_noise('const s = "http://x"; // trailing') == 'const s = "http://x";',
    ))
    checks.append((
        "char literal with /",
        strip_noise("if (c == '/') return; // note") == "if (c == '/') return;",
    ))

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
    checks.append((
        "family stem canonicalised",
        canonicalise_family("z47_calc_state_runtime_x();", ("calc_state",))
        == canonicalise_family("z47_program_serialization_runtime_x();", ("program_serialization",)),
    ))

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
    ap.add_argument("--self-test", action="store_true", help="check the extractor and exit")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = (
        pathlib.Path(args.repo_root).resolve()
        if args.repo_root
        else pathlib.Path(__file__).resolve().parents[2]
    )
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
