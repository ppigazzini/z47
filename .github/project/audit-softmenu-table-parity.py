#!/usr/bin/env python3
"""Softmenu-table parity audit: the Zig menu_* mirrors must match upstream softmenus.c.

`zig_src/shell/display/softmenus/softmenus.zig` owns `softmenu[]` and every
`menu_*[]` table it points at. Those tables were dumped from the C once, at the
M3.3 port, and nothing has compared them against upstream since -- so a resync
that changes a menu leaves the Zig copy silently stale. The testSuite cannot see
it: it drives commands, not softkey layouts.

Ground truth is the C preprocessor, not a regex. softmenus.c is preprocessed for
the host build, which resolves the per-target `#if`s and expands every ITM_/MNU_
constant to its number, and the resulting initialisers are compared against the
Zig literals with the same host build options applied to their comptime gates.

gtk/gdk are stubbed with empty headers: this only preprocesses, so the real
GUI headers are never needed. The six catalogs that come from the generated
softmenuCatalogs.h (menu_FCNS and friends) need that header; if no build output
is present they are reported as SKIPPED, never silently dropped.

Exit codes: 0 clean or drift exactly at baseline, 1 new drift or drift that
changed, 2 the audit could not run.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Host build values for the frontier options softmenus.zig gates its tables on
# (zig_build/frontier/frontier.zig defaults; only the dmcp* variants override).
HOST_OPTIONS = {
    "dmcp_build": False,
    "old_hw": False,
    "option_vector": True,
    "option_elec": True,
    "option_slvp": True,
    "option_xfn_1000": True,
    "option_tvm_amort": True,
    "ir_printing": True,
    "extra_info": True,
    "strip_15": False,
    "strip_16": False,
    "strip_17": False,
    "strip_17b": False,
    "strip_17c": False,
    "strip_21_hp35": False,
    "strip_ortho_bessel_ellip": False,
}

# Menus whose initialiser lives in the generated softmenuCatalogs.h.
GENERATED_CATALOGS = {
    "menu_CONST",
    "menu_FCNS",
    "menu_FCNS_EIM",
    "menu_SYSFL",
    "menu_alpha_INTL",
    "menu_alpha_intl",
}

C_MENU_RE = re.compile(r"\b(menu_\w+)\[\]\s*=\s*\{(.*?)\}\s*;", re.S)
ZIG_MENU_RE = re.compile(r"const (menu_\w+) linksection\(code_\w+\) = \[_\]i16\{(.*?)\};", re.S)
# A whole table can be gated too: `= if (COND) [_]i16{...} else [_]i16{...};`.
ZIG_WHOLE_GATED_RE = re.compile(
    r"const (menu_\w+) linksection\(code_\w+\) = if \((.+?)\) \[_\]i16\{(.*?)\} else \[_\]i16\{(.*?)\};",
    re.S,
)
ZIG_GATED_RE = re.compile(r"\(if \((.+?)\) (.+?) else (.+?)\)", re.S)
ZIG_AS_RE = re.compile(r"@as\(i16, (-?\d+)\)")


def preprocess(repo: Path, catalogs_dir: Path | None) -> str:
    cc = os.environ.get("CC") or shutil.which("cc") or shutil.which("gcc")
    if cc is None:
        raise SystemExit2("no C preprocessor found (set CC)")
    with tempfile.TemporaryDirectory() as tmp:
        stub = Path(tmp)
        for header in ("gtk/gtk.h", "gdk/gdk.h"):
            path = stub / header
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("")
        for header in ("version.h", "softmenuCatalogs.h", "constantPointers.h"):
            if catalogs_dir is None or not (catalogs_dir / header).exists():
                (stub / header).write_text("")
        includes = ["-I", str(stub)]
        if catalogs_dir is not None:
            includes += ["-I", str(catalogs_dir)]
        includes += ["-I", str(repo / "src/c47"), "-I", str(repo / "dep/decNumberICU")]
        cmd = [
            cc,
            "-E",
            "-P",
            "-DPC_BUILD=1",
            "-DLINUX=1",
            "-DOS64BIT=1",
            *includes,
            str(repo / "src/c47/softmenus.c"),
        ]
        done = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
        if done.returncode != 0:
            raise SystemExit2("preprocessing softmenus.c failed:\n" + done.stderr[-2000:])
        return done.stdout


class SystemExit2(Exception):
    """Audit could not run (exit 2), as distinct from a drift finding (exit 1)."""


def c_menus(preprocessed: str) -> dict[str, list[int] | None]:
    out: dict[str, list[int] | None] = {}
    for match in C_MENU_RE.finditer(preprocessed):
        tokens = [t.strip() for t in match.group(2).split(",") if t.strip()]
        try:
            out[match.group(1)] = [int(eval(t, {"__builtins__": {}}, {})) for t in tokens]
        except Exception:
            out[match.group(1)] = None
    return out


def split_top_level(body: str) -> list[str]:
    items, depth, current = [], 0, ""
    for char in body:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if char == "," and depth == 0:
            items.append(current)
            current = ""
        else:
            current += char
    if current.strip():
        items.append(current)
    return [i for i in items if i.strip()]


def host_condition(condition: str) -> bool:
    expression = condition
    for name, value in HOST_OPTIONS.items():
        expression = re.sub(rf"\b{name}\b", str(value), expression)
    return bool(eval(expression.replace("!", " not "), {"__builtins__": {}}, {}))


def zig_value(token: str) -> int:
    token = token.strip()
    gated = ZIG_GATED_RE.fullmatch(token)
    if gated:
        condition, when_true, when_false = gated.groups()
        return zig_value(when_true if host_condition(condition) else when_false)
    coerced = ZIG_AS_RE.fullmatch(token)
    return int(coerced.group(1)) if coerced else int(token)


def zig_table(body: str) -> list[int]:
    return [zig_value(t) for t in split_top_level(re.sub(r"//.*", "", body))]


def zig_menus(source: str) -> dict[str, list[int] | None]:
    out: dict[str, list[int] | None] = {}
    for match in ZIG_MENU_RE.finditer(source):
        try:
            out[match.group(1)] = zig_table(match.group(2))
        except Exception:
            out[match.group(1)] = None
    for match in ZIG_WHOLE_GATED_RE.finditer(source):
        name, condition, when_true, when_false = match.groups()
        try:
            out[name] = zig_table(when_true if host_condition(condition) else when_false)
        except Exception:
            out[name] = None
    return out


def digest(c_values: list[int], zig_values: list[int]) -> str:
    payload = repr(c_values) + "|" + repr(zig_values)
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def find_catalogs_dir(repo: Path) -> Path | None:
    cache = repo / ".zig-cache"
    if not cache.is_dir():
        return None
    for header in cache.glob("o/*/softmenuCatalogs.h"):
        return header.parent
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--baseline", default=None)
    parser.add_argument("--write-baseline", action="store_true")
    args = parser.parse_args()

    repo = Path(args.repo_root).resolve()
    baseline_path = (
        Path(args.baseline)
        if args.baseline
        else repo / ".github/project/softmenu-parity-baseline.json"
    )
    owner = repo / "zig_src/shell/display/softmenus/softmenus.zig"

    try:
        preprocessed = preprocess(repo, find_catalogs_dir(repo))
    except SystemExit2 as error:
        print(f"softmenu-table parity: CANNOT RUN -- {error}")
        return 2

    from_c = c_menus(preprocessed)
    from_zig = zig_menus(owner.read_text(encoding="utf-8", errors="replace"))

    drifted: dict[str, dict[str, object]] = {}
    missing: list[str] = []
    skipped: list[str] = []
    # Menus this run could not judge either way. A baseline entry for one of
    # these must NOT read as "fixed": the governance job can run with no build
    # output, and then every generated catalog is unreadable rather than clean.
    unjudged: set[str] = set()
    compared = 0

    for name in sorted(set(from_c)):
        c_values = from_c[name]
        if c_values is None:
            skipped.append(f"{name} (C initialiser not constant-foldable)")
            unjudged.add(name)
            continue
        if name not in from_zig:
            if name in GENERATED_CATALOGS:
                skipped.append(f"{name} (generated catalog, no Zig literal)")
                unjudged.add(name)
            else:
                missing.append(name)
            continue
        zig_values = from_zig[name]
        if zig_values is None:
            skipped.append(f"{name} (Zig literal not evaluable)")
            unjudged.add(name)
            continue
        compared += 1
        if c_values != zig_values:
            drifted[name] = {
                "c_len": len(c_values),
                "zig_len": len(zig_values),
                "differing": sum(1 for x, y in zip(c_values, zig_values, strict=False) if x != y)
                + abs(len(c_values) - len(zig_values)),
                "digest": digest(c_values, zig_values),
            }

    if absent_catalogs := sorted(n for n in GENERATED_CATALOGS if n not in from_c):
        unjudged.update(absent_catalogs)
        skipped.append(
            f"{len(absent_catalogs)} generated catalogs absent, no build output to read "
            f"softmenuCatalogs.h from: {', '.join(absent_catalogs)}"
        )

    print(
        f"softmenu-table parity: compared {compared} menus, "
        f"{len(drifted)} drifted, {len(missing)} absent from the Zig owner, {len(skipped)} skipped"
    )
    for entry in skipped:
        print(f"  SKIPPED {entry}")
    for name, info in sorted(drifted.items()):
        print(
            f"  DRIFT   {name}: C {info['c_len']} entries, Zig {info['zig_len']}, "
            f"{info['differing']} differ"
        )
    for name in missing:
        print(f"  ABSENT  {name}: in softmenus.c, no Zig literal")

    current = {
        "note": (
            "Known softmenu-table drift, frozen per menu by a digest of the (C, Zig) "
            "value pairs. These tables were dumped from the C at the M3.3 port and "
            "never re-compared, so the drift predates the audit. New drift, or a "
            "change to a listed one, fails; a menu that becomes clean also fails, so "
            "the baseline is re-pinned rather than left claiming a fixed menu is broken."
        ),
        "drifted": drifted,
        "absent": sorted(missing),
    }

    if args.write_baseline:
        baseline_path.write_text(json.dumps(current, indent=1, sort_keys=True) + "\n")
        print(
            f"softmenu-table parity: wrote baseline ({len(drifted)} drifted, {len(missing)} absent)"
        )
        return 0

    if not baseline_path.exists():
        print(f"FAIL: no baseline at {baseline_path} -- create it with --write-baseline")
        return 1

    baseline = json.loads(baseline_path.read_text())
    known = baseline.get("drifted", {})
    known_absent = set(baseline.get("absent", []))

    failures: list[str] = []
    for name, info in sorted(drifted.items()):
        if name not in known:
            failures.append(
                f"NEW drift in {name} ({info['differing']} entries differ from softmenus.c)"
            )
        elif known[name].get("digest") != info["digest"]:
            failures.append(f"{name} drifted differently than the baseline records")
    for name in sorted(set(known) - set(drifted) - unjudged):
        failures.append(f"{name} now matches softmenus.c -- re-pin with --write-baseline")
    for name in sorted(set(missing) - known_absent):
        failures.append(f"NEW menu absent from the Zig owner: {name}")
    for name in sorted(known_absent - set(missing) - unjudged):
        failures.append(f"{name} is now present -- re-pin with --write-baseline")

    if failures:
        print("\nSOFTMENU TABLE PARITY FAILED:")
        for failure in failures:
            print(f"  {failure}")
        print(
            "\nA menu_* table that disagrees with softmenus.c is a softkey the user\n"
            "cannot reach, or one that runs the wrong command. Re-port the table."
        )
        return 1

    print(
        f"\ncheck-softmenu-table-parity: OK ({len(drifted)} drifted and {len(missing)} absent, all at baseline)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
