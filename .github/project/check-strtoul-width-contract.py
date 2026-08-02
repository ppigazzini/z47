#!/usr/bin/env python3
"""Every `strtol`/`strtoul` call in src must carry a decided width verdict.

WHY THIS EXISTS. `strtoul` returns `unsigned long`, which is 64-bit on the Linux
and macOS hosts and 32-bit on the arm-none-eabi firmware AND on Windows (LLP64).
So upstream's own behaviour differs between the targets z47 ships and tests on,
"parity" is undefined at those sites, and the parity oracles only ever exercise the
host. That is finding 9, and it was open for the whole of REPORT-30 because nobody
had written down which target's answer is authoritative at which site.

THE DIVERGENCE, measured rather than reasoned (see the report's appendix):

  unsigned  identical below 2**32; identical at and above 2**64, where both widths
            saturate to all-ones and truncate the same; DIFFERENT in between --
            64-bit yields the value's true low bits, 32-bit yields 0xFFFFFFFF.
  signed    different from 2**31 upward and it NEVER re-converges: 64-bit saturates
            to 2**63-1 (low 32 bits 0xFFFFFFFF, i.e. -1) while 32-bit saturates to
            2**31-1. The unsigned window closes; the signed one does not.

WHAT THIS GATE DOES. It does not judge a verdict, it insists one EXISTS. Each call
site must carry a `WIDTH-CONTRACT:` line within the preceding few lines naming one
of the four dispositions below. A resync that adds a parse site fails here until
somebody decides what that site's answer is, which is the property finding 9
actually needed -- the sites were never wrong so much as undecided.

  no-width-question   strtoll/strtoull: `long long` is 64-bit on every target.
  unreachable         no input in the divergence window can reach this site.
  accepted            it can, the two targets differ, and that is upstream's own
                      behaviour which z47 reproduces rather than corrects.
  bounded             the parse is pinned to a fixed width so both targets agree.

Run from the repo root:
  python3 .github/project/check-strtoul-width-contract.py
  python3 .github/project/check-strtoul-width-contract.py --list
  python3 .github/project/check-strtoul-width-contract.py --write-baseline
  python3 .github/project/check-strtoul-width-contract.py --self-test
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
BASELINE = HERE / "strtoul-width-contract-baseline.json"

# The parse calls that carry a width question, plus the two that provably do not
# (kept in scope on purpose: "no-width-question" is a verdict worth stating once,
# and it stops a reader re-deriving it every time they pass the site).
CALL_RE = re.compile(r"\b(strtoul|strtol|strtoull|strtoll)\s*\(")
DECL_RE = re.compile(r"^\s*(pub\s+)?extern\s+fn\b")
VERDICT_RE = re.compile(r"WIDTH-CONTRACT\s*:\s*(no-width-question|unreachable|accepted|bounded)\b")
COMMENT_RE = re.compile(r"^\s*//")

# How far above a call the verdict may sit. Small on purpose: a verdict that has
# drifted away from its site stops being a comment about that site.
VERDICT_LOOKBACK = 12


def call_sites(root: pathlib.Path) -> list[dict]:
    """Every strto* CALL in src, with the verdict covering it if there is one.

    `extern fn` declarations are not calls, and a call written inside a comment is
    prose about a call rather than one; both would otherwise inflate the count and
    demand verdicts that mean nothing.
    """
    out: list[dict] = []
    for path in sorted(root.glob("src/**/*.zig")):
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for n, line in enumerate(lines):
            call = CALL_RE.search(line)
            if call is None or DECL_RE.match(line) or COMMENT_RE.match(line):
                continue
            verdict = None
            for back in range(1, VERDICT_LOOKBACK + 1):
                if n - back < 0:
                    break
                above = lines[n - back]
                # Stop at the previous call site. Without this the lookback walks
                # past it and adopts ITS verdict, so a new parse added just below an
                # annotated one is silently reported as decided -- caught by
                # mutation-testing this gate, and only because the site COUNT also
                # changed. One verdict covers one call.
                if (
                    CALL_RE.search(above)
                    and not DECL_RE.match(above)
                    and not COMMENT_RE.match(above)
                ):
                    break
                m = VERDICT_RE.search(above)
                if m:
                    verdict = m.group(1)
                    break
            out.append(
                {
                    "file": str(path.relative_to(root)),
                    "line": n + 1,
                    "fn": call.group(1),
                    "code": line.strip()[:100],
                    "verdict": verdict,
                }
            )
    return out


def self_test() -> int:
    """The three classification decisions the count depends on."""
    failures: list[str] = []

    if DECL_RE.match("extern fn strtoul(s: [*c]const u8, e: ?*[*c]u8, b: c_int) c_ulong;") is None:
        failures.append("an extern declaration was not recognised as a non-call")
    if COMMENT_RE.match("    // strtoul(str, null, 0) is platform-width") is None:
        failures.append("a call named inside a comment was not recognised as prose")
    if not CALL_RE.search("return @truncate(strtoul(str, null, 0));"):
        failures.append("a real call site was not matched")
    if VERDICT_RE.search("// WIDTH-CONTRACT: accepted -- upstream diverges here too") is None:
        failures.append("a well-formed verdict was not parsed")
    if VERDICT_RE.search("// WIDTH-CONTRACT: probably fine") is not None:
        failures.append("an unrecognised disposition was accepted as a verdict")

    # A verdict covers ONE call. A second call below an annotated one must not
    # inherit it -- the lookback used to walk straight past the intervening site.
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        root = pathlib.Path(td)
        (root / "src").mkdir()
        (root / "src" / "t.zig").write_text(
            "// WIDTH-CONTRACT: accepted -- the first one\n"
            "fn a() u32 { return @truncate(strtoul(s, null, 10)); }\n"
            "fn b() u32 { return @truncate(strtoul(s, null, 10)); }\n"
        )
        found = call_sites(root)
        if len(found) != 2:
            failures.append(f"expected 2 sites in the fixture, got {len(found)}")
        elif found[0]["verdict"] != "accepted" or found[1]["verdict"] is not None:
            failures.append("a call inherited the verdict belonging to the call above it")

    for line in failures:
        print(f"SELF-TEST FAIL: {line}")
    if failures:
        return 1
    print("SELF-TEST OK: call/declaration/comment classification and verdict parsing")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--list", action="store_true", help="print every site and its verdict")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--repo-root", default=None, help="scan this tree instead of the default")
    ap.add_argument(
        "--write-baseline", action="store_true", help="rewrite the committed site count"
    )
    ap.add_argument("--self-test", action="store_true", help="check the classifier and exit")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = pathlib.Path(args.repo_root) if args.repo_root else HERE.parents[1]
    sites = call_sites(root)
    undecided = [s for s in sites if s["verdict"] is None]

    if args.json:
        print(json.dumps(sites, indent=2))
        return 1 if undecided else 0

    if args.write_baseline:
        BASELINE.write_text(json.dumps({"sites": len(sites)}, indent=2) + "\n")
        print(f"wrote baseline: sites = {len(sites)}")
        return 0

    if args.list:
        by_verdict: dict[str, int] = {}
        for s in sites:
            by_verdict[s["verdict"] or "UNDECIDED"] = (
                by_verdict.get(s["verdict"] or "UNDECIDED", 0) + 1
            )
            print(f"{s['file']}:{s['line']:<5} {s['verdict'] or 'UNDECIDED':<18} {s['code']}")
        print("\n  " + ", ".join(f"{k}={v}" for k, v in sorted(by_verdict.items())))

    if undecided:
        print(
            f"WIDTH CONTRACT: {len(undecided)} strto* call site(s) carry no verdict.\n"
            "  Every site must state which target's answer is authoritative, as a\n"
            "  `// WIDTH-CONTRACT: <no-width-question|unreachable|accepted|bounded>` line\n"
            "  above it. See REPORT-30 finding 9 for the measured divergence windows.",
            file=sys.stderr,
        )
        for s in undecided:
            print(f"    {s['file']}:{s['line']}  {s['code']}", file=sys.stderr)
        return 1

    expected = json.loads(BASELINE.read_text())["sites"]
    if len(sites) != expected:
        # Both directions fail. A site appearing is a new undecided question, and a
        # site vanishing means a verdict is now attached to nothing -- the count is
        # the thing that binds the verdicts to the code.
        print(
            f"WIDTH CONTRACT: {len(sites)} strto* call sites, baseline {expected}. "
            "Re-read the verdicts against the sites and update the baseline with "
            "--write-baseline in the same commit.",
            file=sys.stderr,
        )
        return 1

    print(
        f"strtoul_width_contract: {len(sites)} call sites, every one decided (baseline {expected})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
