#!/usr/bin/env python3
"""Derive the upstream<->owner correspondence from the EXPORTED SYMBOL TABLE,
not from file names or header comments.

WHY SYMBOLS. z47's contract is behavioural parity at the ABI-swappable boundary:
the exported symbol names + signatures the parity oracles and other owners link.
Those symbol names are the ONE ontology shared across the C<->Zig boundary
unchanged. A path-identity gate (check-upstream-mirror.py) proves sameness of
*name*; it is silent on the aggregates -- circular_trig_command.zig owns
fnSin/fnCos/fnTan/... with no sin.zig/cos.zig twin, so the mirror gate calls
sin.c a forward violation while this join calls it OWNED. That is the coverage the
mirror gate structurally cannot see, and the reason this join exists.

THE JOIN. For every src/c47/**/*.c, collect the function symbols it DEFINES. For
every zig_src owner, collect the symbols it defines or exports, EXCLUDING pure
single-line forwarders (`X_owned.same(args);`) -- those are the dispatch/export
surface (command_wrappers.zig), not the behavioural owner. Join on symbol: the
C file maps to the owner(s) that implement its symbols. Provenance is recorded per
row: `symbol` (compiler-visible join), `comment` (only a header declaration,
pure-Zig helper with no C-visible symbol), or a typed z47-only kind carried from
upstream-mirror-exceptions.txt.

This supersedes report-owner-drift.py's stem matching, which drifts each resync
precisely because a file name is not a symbol.

Usage:
  build-correspondence-manifest.py            write the .tsv (default)
  build-correspondence-manifest.py --check    print coverage, write nothing
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

C_ROOT = "src/c47"
Z_ROOT = "zig_src"
MANIFEST = ".github/project/upstream-correspondence.tsv"
EXCEPTIONS = ".github/project/upstream-mirror-exceptions.txt"

# A C function definition, two shapes (C has no nested functions, so a
# type-led name-then-paren at statement position is always a definition):
#   (a) column 0: "<ret-and-qualifiers> [*]name(" -- catches multi-line signatures.
#   (b) any indent, body opens on the same line: "... name(<no ';'>) {" -- catches
#       the #if-guarded one-line stubs (distributions/*.c: "void fnNormalP(..){}").
# A bare in-body call ("foo(bar);") has no leading type and no "){", so neither
# shape matches it.
C_DEF = re.compile(r"^([A-Za-z_][A-Za-z0-9_\*\s]+?)\b([a-zA-Z_][A-Za-z0-9_]*)\s*\(", re.M)
C_DEF_STUB = re.compile(r"^[ \t]+[A-Za-z_][A-Za-z0-9_\*\s]+?\b([a-zA-Z_][A-Za-z0-9_]*)\s*\([^;]*\)\s*\{", re.M)
C_KEYWORDS = {"return", "else", "if", "while", "for", "switch", "case", "sizeof",
              "do", "typedef", "struct", "union", "enum", "static_assert"}

# Zig owner-visible symbols: `pub fn NAME` (impl) and `pub export fn NAME` (ABI).
Z_FN = re.compile(r"^\s*pub (?:export )?fn ([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.M)
# A pure forwarder body: a single `something_owned.NAME(...)` call on the next
# non-blank line. Detected structurally below, not by this alone.
Z_FORWARD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*_owned\.([A-Za-z_][A-Za-z0-9_]*)\s*\(")


def c_symbols(text: str) -> set[str]:
    out: set[str] = set()
    for m in C_DEF.finditer(text):
        ret = m.group(1).strip().split()[-1] if m.group(1).strip() else ""
        name = m.group(2)
        first = m.group(1).strip().split()[0] if m.group(1).strip() else ""
        if first in C_KEYWORDS or name in C_KEYWORDS:
            continue
        out.add(name)
    for m in C_DEF_STUB.finditer(text):
        if m.group(1) not in C_KEYWORDS:
            out.add(m.group(1))
    return out


IMPORT_ALIAS = re.compile(r'const ([A-Za-z_][A-Za-z0-9_]*)\s*=\s*@import\("([^"]+\.zig)"\)')


def zig_owned_symbols(rel: str, text: str) -> dict[str, str]:
    """Symbol -> owning owner relpath, for one Zig file at `rel`.

    Two sources, both keyed on the ABI/impl symbol name:
      * a `pub fn`/`pub export fn NAME` with a real body  -> this file owns NAME.
      * a forwarder `pub export fn NAME { ALIAS.method(...) }` whose ALIAS resolves
        via a file-local `const ALIAS = @import("path")` -> the imported owner owns
        NAME. This is how the command_wrappers dispatch surface attributes the C
        ABI symbol (fnCeil) to the idiomatic impl (rounding/integer_part.ceil),
        across z47's internal renames.
    """
    owners: dict[str, str] = {}
    here = pathlib.PurePosixPath(rel).parent
    aliases = {a: str((here / pathlib.PurePosixPath(p)).with_suffix(""))
               for a, p in IMPORT_ALIAS.findall(text)}
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"\s*pub (?:export )?fn ([A-Za-z_][A-Za-z0-9_]*)\s*\(", line)
        if not m:
            continue
        name = m.group(1)
        # Find the body-opening brace (signatures may span many lines), then read
        # the first two statements -- length-agnostic, so a multi-line forwarder
        # signature does not hide its single `ALIAS_owned.method(...)` body.
        j = i
        while j < len(lines) and "{" not in lines[j] and j - i < 12:
            j += 1
        body = "\n".join(lines[j:j + 3])
        fw = Z_FORWARD.search(body)
        if fw and body.count(";") <= 1:
            alias = re.search(r"([A-Za-z_][A-Za-z0-9_]*)_owned\.", body)
            key = f"{alias.group(1)}_owned" if alias else None
            if key in aliases:
                owners.setdefault(name, aliases[key])  # attribute to the impl
                continue
        owners.setdefault(name, rel)  # real body here
    return owners


def load_exception_rows(path: pathlib.Path) -> dict[str, str]:
    """z47-authored entries -> a kind tag, from the exceptions file sections."""
    kinds: dict[str, str] = {}
    if not path.exists():
        return kinds
    section = None
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section == "zig-authored":
            kinds[line] = "z47-only"
    return kinds


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--check", action="store_true", help="report coverage, write nothing")
    args = ap.parse_args()
    root = pathlib.Path(args.repo_root).resolve()

    # C side: symbol -> defining C file (relpath under C_ROOT, no suffix)
    c_sym_file: dict[str, list[str]] = {}
    c_files: list[str] = []
    for p in sorted((root / C_ROOT).rglob("*.c")):
        rel = str(p.relative_to(root / C_ROOT).with_suffix(""))
        c_files.append(rel)
        for s in c_symbols(p.read_text(errors="ignore")):
            c_sym_file.setdefault(s, []).append(rel)

    # Zig side: symbol -> owning owner(s), forwarders resolved to their impl
    z_sym_owner: dict[str, list[str]] = {}
    z_comment_twin: dict[str, str] = {}
    twin_re = re.compile(r"src/c47/([A-Za-z0-9_/]+)\.c")
    for p in sorted((root / Z_ROOT).rglob("*.zig")):
        rel = str(p.relative_to(root / Z_ROOT).with_suffix(""))
        text = p.read_text(errors="ignore")
        for s, owner in zig_owned_symbols(rel, text).items():
            z_sym_owner.setdefault(s, []).append(owner)
        head = "\n".join(text.splitlines()[:12])
        tw = twin_re.search(head)
        if tw:
            z_comment_twin[rel] = tw.group(1)

    # Join: C file -> owners (via symbol), plus provenance
    file_owners: dict[str, set[str]] = {}
    for sym, cfiles in c_sym_file.items():
        owners = z_sym_owner.get(sym)
        if not owners:
            continue
        for cf in cfiles:
            file_owners.setdefault(cf, set()).update(owners)

    # comment-only rows: an owner declares a twin the symbol join did not produce
    comment_rows: dict[str, set[str]] = {}
    for owner, twin in z_comment_twin.items():
        if twin not in file_owners or owner not in file_owners.get(twin, set()):
            comment_rows.setdefault(twin, set()).add(owner)

    exc_kinds = load_exception_rows(root / EXCEPTIONS)

    covered = sorted(file_owners)
    uncovered = sorted(set(c_files) - set(file_owners))

    if args.check:
        print(f"correspondence coverage: {len(covered)}/{len(c_files)} C files owned by symbol join")
        print(f"  comment-only twins (no symbol join): {len(comment_rows)}")
        print(f"  uncovered C files (no owner at all):  {len(uncovered)}")
        # aggregates the mirror gate cannot see: covered but path-unmirrored
        agg = [cf for cf, ow in file_owners.items()
               if not (root / Z_ROOT / "c47" / f"{cf}.zig").exists()
               and any((root / Z_ROOT / f"{o}.zig").exists() for o in ow)
               and all(pathlib.Path(o).name != pathlib.Path(cf).name for o in ow)]
        print(f"  owned-but-not-path-mirrored (mirror-gate-blind): {len(agg)}")
        return 0

    lines = ["# src/c47 C file\tzig_src owner(s)\tkind\tvia",
             "# Generated by build-correspondence-manifest.py -- do not hand-edit rows",
             "# marked via=symbol; they are recomputed from the export table each run."]
    for cf in covered:
        owners = ";".join(sorted(file_owners[cf]))
        lines.append(f"{cf}\t{owners}\tport\tsymbol")
    for cf in sorted(comment_rows):
        owners = ";".join(sorted(comment_rows[cf]))
        lines.append(f"{cf}\t{owners}\tport\tcomment")
    for name, kind in sorted(exc_kinds.items()):
        lines.append(f"-\t{name}\t{kind}\tz47-only")

    (root / MANIFEST).write_text("\n".join(lines) + "\n")
    print(f"wrote {MANIFEST}: {len(covered)} symbol rows, "
          f"{len(comment_rows)} comment rows, {len(exc_kinds)} z47-only rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
