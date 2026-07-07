// SEAM-GENERATED
// SPDX-License-Identifier: GPL-3.0-only
//
// Generated ABI seam for src/c47/printing/martelFonts.c
// (martelFont24). Produced by
// .github/project/generate-martel-font-seam.py from the upstream C table; do
// not hand-edit. Regenerate after an upstream pin advance.
//
// Pure Martel printer-font glyph data, exported with C linkage and
// force-included by frontier.zig; consumed by the IR printing path.

const builtin = @import("builtin");
const abi = @import("abi");
const build_options = @import("frontier_build_options");

// Upstream marks the table TO_QSPI: .qspi on old_hw DMCP, platform read-only
// data section otherwise (mach-o needs SEG,sect form; ELF uses .rodata).
const martel_section = if (build_options.dmcp_build and build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__const"
else
    ".rodata";

const glyphMartelPrinter_t = abi.GlyphMartelPrinter;

// Matches martelFont24_t { uint16_t numberOfGlyphs; glyphMartelPrinter_t
// glyphs[]; } with the 2 glyphs materialised inline.
const MartelFont24 = extern struct {
    numberOfGlyphs: u16,
    glyphs: [2]glyphMartelPrinter_t,
};

pub export const martelFont24: MartelFont24 linksection(martel_section) = .{
    .numberOfGlyphs = 2,
    .glyphs = .{
        .{ .charCode = 0xAC66, .data = .{
            0x30, 0x00, 0x00, 0x3f, 0x80, 0x00,
            0x3f, 0x80, 0x00, 0x30, 0x00, 0x00,
            0x30, 0x00, 0x00, 0x3f, 0x80, 0x00,
            0x3f, 0x80, 0x00, 0x30, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x3f, 0x80, 0x00,
            0x1f, 0x80, 0x00, 0x38, 0x00, 0x00,
            0x30, 0x00, 0x00, 0x30, 0x00, 0x00,
            0x38, 0x00, 0x00, 0x18, 0x00, 0x00,
        } },
        .{ .charCode = 0x0000, .data = .{
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
            0x55, 0x55, 0x55, 0xaa, 0xaa, 0xaa,
        } },
    },
};
