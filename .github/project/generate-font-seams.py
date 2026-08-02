#!/usr/bin/env python3
"""Generate the printer-font ABI seams from the upstream C tables.

Each pure-data glyph table in the upstream printing path is a generated ABI seam
(see the seam-and-core rule in
zig_docs/50-zig-c-boundaries-and-rewrite-policy.md): the contract-mandated
`extern struct` layout and `.qspi_data` linksection are derived from upstream C,
so an upstream pin advance is a regenerate, not a hand edit. This one generator
covers every such table; add a spec to FONTS to onboard another.

Usage:
    generate-font-seams.py [--repo-root .]            # write every seam
    generate-font-seams.py [--repo-root .] --stdout   # print, do not write
    generate-font-seams.py [--repo-root .] --check    # exit 1 if any drifted
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from upstream_paths import upstream_path

# One glyph literal: `.charCode=0xHHHH, .data={ b, b, ... }`. Comments are
# stripped first so the incidental `// A0` banners never reach the parser.
GLYPH_RE = re.compile(
    r"\.charCode\s*=\s*(0x[0-9a-fA-F]+)\s*,\s*\.data\s*=\s*\{([^}]*)\}",
    re.DOTALL,
)
COUNT_RE = re.compile(r"\.numberOfGlyphs\s*=\s*(\d+)")
COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)

# Each spec turns one upstream table into one seam. `multiline` wraps a wide
# glyph body across `bytes_per_line`-byte rows; a narrow glyph stays on one line.
FONTS = [
    {
        "c_source": "src/c47/printing/martelFonts.c",
        "seam_path": "zig_src/shell/generated/frontier_martel_fonts.zig",
        "table": "martelFont24",
        "struct_name": "MartelFont24",
        "section_const": "martel_section",
        "abi_type": "GlyphMartelPrinter",
        "data_len": 48,
        "multiline": True,
        "bytes_per_line": 6,
        "title": "Martel printer-font",
    },
    {
        "c_source": "src/c47/printing/printerFont8.c",
        "seam_path": "zig_src/shell/generated/frontier_printer_font8.zig",
        "table": "printerFont8",
        "struct_name": "PrinterFont8",
        "section_const": "pf8_section",
        "abi_type": "GlyphPrinter",
        "data_len": 5,
        "multiline": False,
        "bytes_per_line": 5,
        "title": "8-row printer-font",
    },
]


def strip_comments(text: str) -> str:
    return COMMENT_RE.sub("", text)


def parse_c(text: str, spec: dict) -> tuple[int, list[tuple[int, list[int]]]]:
    body = strip_comments(text)
    count_match = COUNT_RE.search(body)
    if not count_match:
        raise ValueError(f"{spec['c_source']}: no .numberOfGlyphs found")
    declared = int(count_match.group(1))

    glyphs: list[tuple[int, list[int]]] = []
    for m in GLYPH_RE.finditer(body):
        char_code = int(m.group(1), 16)
        data = [int(tok, 0) for tok in m.group(2).split(",") if tok.strip()]
        if len(data) != spec["data_len"]:
            raise ValueError(
                f"{spec['c_source']}: glyph 0x{char_code:04X} has {len(data)} "
                f"data bytes, expected {spec['data_len']}"
            )
        glyphs.append((char_code, data))

    if len(glyphs) != declared:
        raise ValueError(
            f"{spec['c_source']}: numberOfGlyphs={declared} but parsed {len(glyphs)} glyph literals"
        )
    return declared, glyphs


def render_glyph(char_code: int, data: list[int], spec: dict) -> list[str]:
    prefix = f"        .{{ .charCode = 0x{char_code:04X}, .data = .{{"
    if not spec["multiline"]:
        body = ", ".join(f"0x{b:02x}" for b in data)
        return [f"{prefix} {body} }} }},"]
    lines = [prefix]
    step = spec["bytes_per_line"]
    for row in range(0, len(data), step):
        chunk = ", ".join(f"0x{b:02x}" for b in data[row : row + step])
        lines.append(f"            {chunk},")
    lines.append("        } },")
    return lines


def render_zig(count: int, glyphs: list[tuple[int, list[int]]], spec: dict) -> str:
    lines: list[str] = []
    lines.append("// SEAM-GENERATED")
    lines.append("// SPDX-License-Identifier: GPL-3.0-only")
    lines.append("//")
    lines.append(f"// Generated ABI seam for {spec['c_source']}")
    lines.append(f"// ({spec['table']}). Produced by")
    lines.append("// .github/project/generate-font-seams.py from the upstream C table; do")
    lines.append("// not hand-edit. Regenerate after an upstream pin advance.")
    lines.append("//")
    lines.append(f"// Pure {spec['title']} glyph data, exported with C linkage and")
    lines.append("// force-included by frontier.zig; consumed by the IR printing path.")
    lines.append("")
    lines.append('const builtin = @import("builtin");')
    lines.append('const abi = @import("abi");')
    lines.append('const build_options = @import("frontier_build_options");')
    lines.append("")
    lines.append("// Upstream marks the table TO_QSPI: .qspi on old_hw DMCP, platform read-only")
    lines.append("// data section otherwise (mach-o needs SEG,sect form; ELF uses .rodata).")
    lines.append(
        f"const {spec['section_const']} = if (build_options.dmcp_build and build_options.old_hw)"
    )
    lines.append('    ".qspi_data"')
    lines.append("else if (builtin.target.os.tag == .macos)")
    lines.append('    "__TEXT,__const"')
    lines.append("else")
    lines.append('    ".rodata";')
    lines.append("")
    lines.append(f"const {spec['struct_name']} = extern struct {{")
    lines.append("    numberOfGlyphs: u16,")
    lines.append(f"    glyphs: [{count}]abi.{spec['abi_type']},")
    lines.append("};")
    lines.append("")
    lines.append(
        f"pub export const {spec['table']}: {spec['struct_name']} "
        f"linksection({spec['section_const']}) = .{{"
    )
    lines.append(f"    .numberOfGlyphs = {count},")
    lines.append("    .glyphs = .{")
    for char_code, data in glyphs:
        lines.extend(render_glyph(char_code, data, spec))
    lines.append("    },")
    lines.append("};")
    return "\n".join(lines) + "\n"


def generate(repo_root: Path, spec: dict) -> str:
    c_text = upstream_path(repo_root, spec["c_source"]).read_text(encoding="utf-8")
    count, glyphs = parse_c(c_text, spec)
    return render_zig(count, glyphs, spec)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--stdout", action="store_true", help="print to stdout, do not write")
    ap.add_argument("--check", action="store_true", help="exit 1 if any committed seam is stale")
    args = ap.parse_args()

    repo_root = Path(args.repo_root).resolve()
    rc = 0
    for spec in FONTS:
        rendered = generate(repo_root, spec)
        seam_file = repo_root / str(spec["seam_path"])

        if args.check:
            current = seam_file.read_text(encoding="utf-8") if seam_file.exists() else ""
            if current != rendered:
                print(
                    f"SEAM DRIFT: {spec['seam_path']} is stale -- regenerate with "
                    "generate-font-seams.py"
                )
                rc = 1
            else:
                print(f"{spec['seam_path']} is in sync with {spec['c_source']}")
        elif args.stdout:
            sys.stdout.write(rendered)
        else:
            seam_file.parent.mkdir(parents=True, exist_ok=True)
            seam_file.write_text(rendered, encoding="utf-8")
            print(f"wrote {spec['seam_path']}")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
