#!/usr/bin/env python3
"""Every `extern var` declaration must be as wide as the `export var` that defines it.

A declaration narrower than the definition reads garbage. A declaration WIDER than
the definition is worse: every store through it writes past the end of the real
object, and what it lands on is decided by the linker.

This is what kept the Windows lane red for eight days. Four owners aliased
`bool_t` to `u32` while C defines it as one byte (typeDefinitions.h: `typedef bool
bool_t`), so `pemCursorIsZerothStep = 1` in `fnReturn` compiled to a four-byte
`MOV DWORD PTR [rip+disp], 1` into a one-byte flag and put three zero bytes past
it. Under ELF those bytes fell in alignment padding and nothing was observable.
Under COFF, where each export gets its own `.bss$name` COMDAT and the linker
reorders them, `plotStatMx` sat three bytes along and every stat plot lost its
matrix name.

Nothing else can see this. The defining owner is right, the declaring owner is
self-consistent, the corpus is green, and the sanitizers do not instrument Zig
globals. Only the combination is wrong, so only a cross-owner check finds it.

Byte-views are not flagged: declaring a `u16` global as `[2]u8` is a deliberate
idiom in the state codecs and has the same width. Types this cannot resolve --
structs, opaque handles -- are skipped rather than guessed at.
"""

import os
import re
import sys
from collections import defaultdict

SCALARS = {
    "bool": 1,
    "u8": 1,
    "i8": 1,
    "u16": 2,
    "i16": 2,
    "c_short": 2,
    "c_ushort": 2,
    "u32": 4,
    "i32": 4,
    "f32": 4,
    "c_int": 4,
    "c_uint": 4,
    "u64": 8,
    "i64": 8,
    "f64": 8,
    "usize": 8,
    "isize": 8,
}

ALIAS_RE = re.compile(r"^const ([A-Za-z_][A-Za-z0-9_]*) = ([A-Za-z_][A-Za-z0-9_]*);")
DEF_RE = re.compile(r"^\s*pub export var ([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^=;]+?)\s*=")
DECL_RE = re.compile(r"^\s*(?:pub )?extern var ([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^=;]+?)\s*;")
ARRAY_RE = re.compile(r"^\[(\d+)\]\s*(.+)$")


def width(type_text, aliases):
    """Byte width of `type_text` in a file whose aliases are `aliases`, or None."""
    text = type_text.strip()
    array = ARRAY_RE.match(text)
    if array:
        element = width(array.group(2), aliases)
        return None if element is None else int(array.group(1)) * element
    seen = set()
    while text in aliases and text not in seen:
        seen.add(text)
        text = aliases[text]
    return SCALARS.get(text)


def scan(root):
    definitions = {}
    declarations = defaultdict(list)
    for directory, _, files in os.walk(os.path.join(root, "zig_src")):
        for name in files:
            if not name.endswith(".zig"):
                continue
            path = os.path.join(directory, name)
            with open(path, errors="ignore") as handle:
                lines = handle.readlines()
            aliases = {}
            for line in lines:
                alias = ALIAS_RE.match(line)
                if alias:
                    aliases[alias.group(1)] = alias.group(2)
            for number, line in enumerate(lines, 1):
                definition = DEF_RE.match(line)
                if definition:
                    size = width(definition.group(2), aliases)
                    if size is not None:
                        definitions[definition.group(1)] = (
                            size,
                            path,
                            number,
                            definition.group(2).strip(),
                        )
                    continue
                declaration = DECL_RE.match(line)
                if declaration:
                    size = width(declaration.group(2), aliases)
                    if size is not None:
                        declarations[declaration.group(1)].append(
                            (size, path, number, declaration.group(2).strip())
                        )
    return definitions, declarations


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    definitions, declarations = scan(root)

    conflicts = 0
    checked = 0
    for symbol, rows in sorted(declarations.items()):
        if symbol not in definitions:
            continue
        def_size, def_path, def_line, def_type = definitions[symbol]
        for size, path, line, type_text in rows:
            checked += 1
            if size == def_size:
                continue
            conflicts += 1
            verdict = "writes past the end of" if size > def_size else "reads past the end of"
            print(f"EXTERN VAR WIDTH CONFLICT: {symbol}")
            print(f"  declared {size} byte(s) as {type_text!r} at {path}:{line}")
            print(f"  defined  {def_size} byte(s) as {def_type!r} at {def_path}:{def_line}")
            print(f"  a store through the declaration {verdict} the real object")
            print()

    if conflicts:
        print(f"{conflicts} conflict(s). Align each declaration with the definition's width.")
        return 1

    print(
        f"check-extern-var-widths: OK "
        f"({checked} extern var declarations checked against {len(definitions)} definitions)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
