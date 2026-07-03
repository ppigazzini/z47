// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/printing/martelFonts.c: the Martel printer font glyph
// data (martelFont24). Pure data, exported with C linkage and force-included by
// frontier.zig; consumed by the IR printing path (print.c). Byte-for-byte copy
// of the upstream table.

const builtin = @import("builtin");
const build_options = @import("frontier_build_options");

// Upstream marks the table TO_QSPI (see fonts owner): .qspi on old_hw DMCP,
// platform read-only data section otherwise (mach-o needs SEG,sect form).
const martel_section = if (build_options.dmcp_build and build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__const"
else
    ".rodata";

const glyphMartelPrinter_t = extern struct {
    charCode: u16,
    data: [48]u8,
};

// Matches martelFont24_t { uint16_t numberOfGlyphs; glyphMartelPrinter_t glyphs[]; }
// with the two glyphs materialised inline.
const MartelFont24 = extern struct {
    numberOfGlyphs: u16,
    glyphs: [2]glyphMartelPrinter_t,
};

pub export const martelFont24: MartelFont24 linksection(martel_section) = .{
    .numberOfGlyphs = 2,
    .glyphs = .{
        // 2C60
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
        // Last glyph is for unknown unicodes
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
