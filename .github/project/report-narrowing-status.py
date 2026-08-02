#!/usr/bin/env python3
"""Rank the integer-narrowing sites on the untrusted-file load path (M-SAFE-3).

WHY THIS EXISTS. `@intCast` and `@truncate` are not interchangeable, and the
difference is a PARITY question before it is a safety one:

  * Where upstream assigns a wider value into a narrower type, C narrows by
    truncation and that is DEFINED behaviour the calculator's output may depend
    on. `@intCast` is illegal behaviour on the same input -- a trap in a safe
    build, silent UB in the ReleaseSmall firmware. Those sites must be
    `@truncate`.
  * Where the value provably fits, `@intCast` is correct and says something true
    about the code. Those sites must stay.

So the population cannot be swept in either direction: each site needs the
upstream C line read. This script does not decide -- it RANKS, and the ranking
is a queue for that reading. It is deliberately not a gate; the gate is the
`@intCast` ceiling in check-idiom-ratchet.sh.

Ranking signal: a site inside a function that carries `@setRuntimeSafety(true)`
is on the surface that parses bytes z47 did not write, so its operand can be
file-derived and a wrong spelling is reachable from a `.sav` / `.d47` / `.p47`.
Those are listed first.

Run from the repo root:
  python3 .github/project/report-narrowing-status.py
  python3 .github/project/report-narrowing-status.py --json
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

# The owners that parse externally-supplied files. Kept explicit rather than
# globbed: the point of the list is that adding an owner here is a deliberate
# statement that it reads untrusted bytes.
LOAD_OWNER_DIRS = (
    "zig_src/core/persist",
    "zig_src/core/program",
)

FN_RE = re.compile(r"^(?:pub )?(?:inline )?fn\s+(\w+)")
SAFETY_RE = re.compile(r"@setRuntimeSafety\(true\)")
CAST_RE = re.compile(r"@(intCast|truncate|bitCast)\b")
# `@intCast` inside a comment is prose, not code -- the idiom ratchet's habit of
# counting comments is a known wart and is not repeated here.
COMMENT_RE = re.compile(r"^\s*//")

# A cast whose operand is comptime-known cannot trap at RUNTIME: Zig evaluates it
# during analysis and a value that does not fit is a compile error instead. Those
# sites are correct by construction and do not belong in the reading queue.
#
# Recognising them is a heuristic on the operand's spelling: a bare numeric
# literal, or a SCREAMING_CASE name, and nothing else -- no call, index, field or
# operator. A lower-case name is deliberately NOT accepted even though many are
# constants, because the spelling alone cannot distinguish `some_const` from a
# local variable. The bias is one-directional and that is the point: it can leave
# a comptime site in the queue (a reader wastes a minute) but it can never drop a
# runtime one (a real narrowing goes unread).
COMPTIME_OPERAND_RE = re.compile(r"^\s*(?:[0-9][0-9_xXa-fA-F]*|[A-Z][A-Z0-9_]*)\s*$")

# KNOWN LIMITS, stated so a reader does not over-trust the counts:
#   * The scan is line-based. A cast whose operand spans lines yields a partial
#     operand, which falls through to "runtime" -- conservative, as above.
#   * `fn` is matched at column 0 only, so a nested function does not reset the
#     enclosing function's safety flag. There is one nested `fn` in these owners
#     (inside a test) and it is not in a safety-raised function, so nothing is
#     currently misattributed; revisit if that changes.


def operand_of(text: str, start: int) -> str | None:
    """Extract the parenthesised operand of the builtin starting at `start`."""
    open_at = text.find("(", start)
    if open_at < 0:
        return None
    depth = 0
    for i in range(open_at, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[open_at + 1 : i]
    return None


def scan_file(path: pathlib.Path) -> tuple[list[dict], set[tuple[str, str]]]:
    """Return this file's cast sites and the set of its safety-raised functions.

    The two are collected separately on purpose. A safety-raised function with no
    cast in it still counts toward coverage, so it must not be inferred from the
    cast list -- otherwise the floor below would permit dropping safety from every
    cast-free load function without noticing.
    """
    out: list[dict] = []
    safe_fns: set[tuple[str, str]] = set()
    fn_name = "<file scope>"
    fn_line = 0
    fn_safe = False
    # A function's safety attribute is its first statement, so remember whether
    # the function currently open declared one.
    for idx, raw in enumerate(path.read_text().split("\n"), start=1):
        m = FN_RE.match(raw)
        if m:
            fn_name, fn_line, fn_safe = m.group(1), idx, False
            continue
        if SAFETY_RE.search(raw) and not COMMENT_RE.match(raw):
            fn_safe = True
            safe_fns.add((str(path), fn_name))
            continue
        if COMMENT_RE.match(raw):
            continue
        for cast in CAST_RE.finditer(raw):
            operand = operand_of(raw, cast.end())
            comptime = operand is not None and bool(COMPTIME_OPERAND_RE.match(operand))
            out.append(
                {
                    "file": str(path),
                    "line": idx,
                    "builtin": "@" + cast.group(1),
                    "fn": fn_name,
                    "fn_line": fn_line,
                    "untrusted": fn_safe,
                    "comptime_operand": comptime,
                    "operand": (operand or "").strip(),
                    "text": raw.strip(),
                }
            )
    return out, safe_fns


def collect(root: pathlib.Path) -> tuple[list[dict], set[tuple[str, str]]]:
    sites: list[dict] = []
    safe_fns: set[tuple[str, str]] = set()
    for d in LOAD_OWNER_DIRS:
        for path in sorted((root / d).glob("*.zig")):
            file_sites, file_safe = scan_file(path.relative_to(root))
            sites.extend(file_sites)
            safe_fns |= file_safe
    return sites, safe_fns


# Ratcheted downward, monotonically. Deliberately ONE metric: the count of
# narrowings that can trap at runtime on a value a file supplied. The other
# tallies are context for a reader, not contracts -- ratcheting `intcast_sites`
# would push authors toward @truncate where @intCast is the honest spelling,
# which is the mistake this whole analysis exists to avoid.
RATCHETED = ("intcast_untrusted_runtime",)

# ...and a FLOOR, because the metric above has an obvious gaming vector: deleting
# a `@setRuntimeSafety(true)` drops every cast in that function out of the count,
# "improving" the ratchet by REMOVING a check from the shipped firmware. So the
# number of safety-raised functions on the load path may not fall either. Together
# the two say: cover at least as much, and narrow no more unsafely than today.
FLOORED = ("untrusted_fns",)


def summarise(sites: list[dict], safe_fns: set[tuple[str, str]]) -> dict:
    def count(pred) -> int:
        return sum(1 for s in sites if pred(s))

    return {
        "total_sites": len(sites),
        # Every function carrying @setRuntimeSafety(true), whether or not it holds
        # a cast: this is the coverage the ratchet is computed over, floored so it
        # cannot be shrunk to make the ratchet look better.
        "untrusted_fns": len(safe_fns),
        "intcast_sites": count(lambda s: s["builtin"] == "@intCast"),
        "truncate_sites": count(lambda s: s["builtin"] == "@truncate"),
        "bitcast_sites": count(lambda s: s["builtin"] == "@bitCast"),
        "intcast_on_untrusted_fns": count(lambda s: s["builtin"] == "@intCast" and s["untrusted"]),
        # The number that matters: an @intCast on an untrusted-parse function
        # whose operand is NOT comptime-known, so it can trap at runtime on a
        # value a file supplied.
        "intcast_untrusted_runtime": count(
            lambda s: s["builtin"] == "@intCast" and s["untrusted"] and not s["comptime_operand"]
        ),
        "truncate_on_untrusted_fns": count(
            lambda s: s["builtin"] == "@truncate" and s["untrusted"]
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument(
        "--all",
        action="store_true",
        help="list every site, not just those on untrusted-parse functions",
    )
    ap.add_argument(
        "--check",
        action="store_true",
        help="fail if a ratcheted metric grew above its committed ceiling",
    )
    ap.add_argument(
        "--write-baseline",
        action="store_true",
        help="rewrite the ceiling file to the current values",
    )
    args = ap.parse_args()

    root = pathlib.Path(__file__).resolve().parents[2]
    sites, safe_fns = collect(root)
    totals = summarise(sites, safe_fns)
    baseline_path = root / ".github/project/narrowing-status-baseline.json"

    if args.write_baseline:
        payload = {k: totals[k] for k in (*RATCHETED, *FLOORED)}
        baseline_path.write_text(json.dumps(payload, indent=2) + "\n")
        print(f"wrote {baseline_path.relative_to(root)}: {payload}")
        return 0

    if args.check:
        if not baseline_path.exists():
            print(f"MISSING BASELINE: {baseline_path}", file=sys.stderr)
            return 1
        ceilings = json.loads(baseline_path.read_text())
        failed = False
        for metric in RATCHETED:
            now, ceiling = totals[metric], ceilings.get(metric)
            if ceiling is None:
                print(f"NARROWING RATCHET: {metric} missing from the baseline", file=sys.stderr)
                failed = True
            elif now > ceiling:
                print(
                    f"NARROWING RATCHET REGRESSION: {metric} = {now}, ceiling {ceiling}"
                    " -- a narrowing site on the untrusted-file load path grew."
                    " Read the upstream C for it: an implicit narrowing there means"
                    " @truncate, a provable fit means @intCast. Then lower the"
                    " ceiling with --write-baseline in the same commit.",
                    file=sys.stderr,
                )
                failed = True
            else:
                note = "at ceiling" if now == ceiling else f"below ceiling {ceiling}"
                print(f"{metric} = {now} ({note})")
        for metric in FLOORED:
            now, floor = totals[metric], ceilings.get(metric)
            if floor is None:
                print(f"NARROWING RATCHET: {metric} missing from the baseline", file=sys.stderr)
                failed = True
            elif now < floor:
                print(
                    f"NARROWING RATCHET REGRESSION: {metric} = {now}, floor {floor}"
                    " -- runtime safety was REMOVED from a load-path function."
                    " That silently drops its narrowings out of the ratchet above"
                    " while making the shipped firmware check less, which is the"
                    " one way to satisfy this gate by making things worse.",
                    file=sys.stderr,
                )
                failed = True
            else:
                note = "at floor" if now == floor else f"above floor {floor}"
                print(f"{metric} = {now} ({note})")
        return 1 if failed else 0

    if args.json:
        json.dump({"totals": totals, "sites": sites}, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0

    print("Integer narrowing on the untrusted-file load path")
    print(f"  owners scanned : {', '.join(LOAD_OWNER_DIRS)}")
    for k, v in totals.items():
        print(f"  {k:26} {v}")
    print()
    print("QUEUE -- sites inside functions that carry @setRuntimeSafety(true),")
    print("i.e. where the operand can come from a file z47 did not write.")
    print("For each, read the upstream C line: implicit narrowing there means the")
    print("Zig must be @truncate, and a provable fit means @intCast is correct.")
    print()

    shown = [s for s in sites if args.all or (s["untrusted"] and not s["comptime_operand"])]
    shown.sort(key=lambda s: (not s["untrusted"], s["file"], s["line"]))
    for s in shown:
        flag = "UNTRUSTED" if s["untrusted"] else "         "
        print(f"{flag} {s['file']}:{s['line']}  {s['builtin']}  in {s['fn']}()")
        print(f"          {s['text']}")
    if not args.all:
        rest = len(sites) - len(shown)
        print(
            f"\n({rest} further sites: outside a safety-raised function, or a"
            " comptime-known operand that cannot trap at runtime; --all to list)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
