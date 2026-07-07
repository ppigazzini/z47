#!/usr/bin/env python3
"""Generate the Martel printer-font ABI seam from the upstream C table.

Reads the pinned upstream `src/c47/printing/martelFonts.c` and emits the
`zig_src/frontier/generated/frontier_martel_fonts.zig` seam: the pure glyph-data
export (`martelFont24`) in its z47 platform-sectioned shape. This is a generated
ABI seam (see the seam-and-core rule in
zig_docs/50-zig-c-boundaries-and-rewrite-policy.md): the contract-mandated
`extern struct` layout and `.qspi_data` linksection live here, derived from
upstream C, so an upstream pin advance is a regenerate, not a hand edit.

Usage:
    generate-martel-font-seam.py [--repo-root .]            # write the seam
    generate-martel-font-seam.py [--repo-root .] --stdout   # print, do not write
    generate-martel-font-seam.py [--repo-root .] --check    # exit 1 if drifted
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

C_SOURCE = "src/c47/printing/martelFonts.c"
SEAM_PATH = "zig_src/frontier/generated/frontier_martel_fonts.zig"

# One glyph literal: `.charCode=0xHHHH, .data={ b, b, ... }`. Comments are
# stripped first so the incidental `// 2C60` banners never reach the parser.
GLYPH_RE = re.compile(
    r"\.charCode\s*=\s*(0x[0-9a-fA-F]+)\s*,\s*\.data\s*=\s*\{([^}]*)\}",
    re.DOTALL,
)
COUNT_RE = re.compile(r"\.numberOfGlyphs\s*=\s*(\d+)")
COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)


def strip_comments(text: str) -> str:
    return COMMENT_RE.sub("", text)


def parse_c(text: str) -> tuple[int, list[tuple[int, list[int]]]]:
    body = strip_comments(text)
    count_match = COUNT_RE.search(body)
    if not count_match:
        raise ValueError(f"{C_SOURCE}: no .numberOfGlyphs found")
    declared = int(count_match.group(1))

    glyphs: list[tuple[int, list[int]]] = []
    for m in GLYPH_RE.finditer(body):
        char_code = int(m.group(1), 16)
        data = [int(tok, 0) for tok in m.group(2).split(",") if tok.strip()]
        if len(data) != 48:
            raise ValueError(
                f"{C_SOURCE}: glyph 0x{char_code:04X} has {len(data)} data "
                "bytes, expected 48"
            )
        glyphs.append((char_code, data))

    if len(glyphs) != declared:
        raise ValueError(
            f"{C_SOURCE}: numberOfGlyphs={declared} but parsed {len(glyphs)} "
            "glyph literals"
        )
    return declared, glyphs


def render_zig(count: int, glyphs: list[tuple[int, list[int]]]) -> str:
    lines: list[str] = []
    lines.append("// SEAM-GENERATED")
    lines.append("// SPDX-License-Identifier: GPL-3.0-only")
    lines.append("//")
    lines.append("// Generated ABI seam for src/c47/printing/martelFonts.c")
    lines.append("// (martelFont24). Produced by")
    lines.append("// .github/project/generate-martel-font-seam.py from the upstream C table; do")
    lines.append("// not hand-edit. Regenerate after an upstream pin advance.")
    lines.append("//")
    lines.append("// Pure Martel printer-font glyph data, exported with C linkage and")
    lines.append("// force-included by frontier.zig; consumed by the IR printing path.")
    lines.append("")
    lines.append('const builtin = @import("builtin");')
    lines.append('const abi = @import("abi");')
    lines.append('const build_options = @import("frontier_build_options");')
    lines.append("")
    lines.append("// Upstream marks the table TO_QSPI: .qspi on old_hw DMCP, platform read-only")
    lines.append("// data section otherwise (mach-o needs SEG,sect form; ELF uses .rodata).")
    lines.append("const martel_section = if (build_options.dmcp_build and build_options.old_hw)")
    lines.append('    ".qspi_data"')
    lines.append("else if (builtin.target.os.tag == .macos)")
    lines.append('    "__TEXT,__const"')
    lines.append("else")
    lines.append('    ".rodata";')
    lines.append("")
    lines.append("const glyphMartelPrinter_t = abi.GlyphMartelPrinter;")
    lines.append("")
    lines.append("// Matches martelFont24_t { uint16_t numberOfGlyphs; glyphMartelPrinter_t")
    lines.append(f"// glyphs[]; }} with the {count} glyphs materialised inline.")
    lines.append("const MartelFont24 = extern struct {")
    lines.append("    numberOfGlyphs: u16,")
    lines.append(f"    glyphs: [{count}]glyphMartelPrinter_t,")
    lines.append("};")
    lines.append("")
    lines.append("pub export const martelFont24: MartelFont24 linksection(martel_section) = .{")
    lines.append(f"    .numberOfGlyphs = {count},")
    lines.append("    .glyphs = .{")
    for char_code, data in glyphs:
        lines.append(f"        .{{ .charCode = 0x{char_code:04X}, .data = .{{")
        for row in range(0, 48, 6):
            chunk = ", ".join(f"0x{b:02x}" for b in data[row : row + 6])
            lines.append(f"            {chunk},")
        lines.append("        } },")
    lines.append("    },")
    lines.append("};")
    return "\n".join(lines) + "\n"


def generate(repo_root: Path) -> str:
    c_text = (repo_root / C_SOURCE).read_text(encoding="utf-8")
    count, glyphs = parse_c(c_text)
    return render_zig(count, glyphs)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--stdout", action="store_true", help="print to stdout, do not write")
    ap.add_argument("--check", action="store_true", help="exit 1 if the committed seam is stale")
    args = ap.parse_args()

    repo_root = Path(args.repo_root).resolve()
    rendered = generate(repo_root)
    seam_file = repo_root / SEAM_PATH

    if args.check:
        current = seam_file.read_text(encoding="utf-8") if seam_file.exists() else ""
        if current != rendered:
            print(f"SEAM DRIFT: {SEAM_PATH} is stale -- regenerate with "
                  "generate-martel-font-seam.py")
            return 1
        print(f"{SEAM_PATH} is in sync with {C_SOURCE}")
        return 0

    if args.stdout:
        sys.stdout.write(rendered)
        return 0

    seam_file.parent.mkdir(parents=True, exist_ok=True)
    seam_file.write_text(rendered, encoding="utf-8")
    print(f"wrote {SEAM_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
