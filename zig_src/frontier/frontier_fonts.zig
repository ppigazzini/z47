// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/fonts.c: findGlyph (binary search over a font's glyph
// table, called throughout the display path) and generateNotFoundGlyph (renders
// the hex code point of an unknown glyph). Exported with C linkage and
// force-included by frontier.zig. findGlyph is exercised pervasively by the
// testSuite via character display.

const builtin = @import("builtin");
const abi = @import("abi");
const build_options = @import("frontier_build_options");

// Upstream marks hexaFont TO_QSPI: the .qspi section only on old_hw DMCP
// (DMCP_BUILD + TWO_FILE_PGM); host and DMCP5 use the platform's read-only data
// section (mach-o needs SEG,sect form; ELF uses .rodata).
const hexa_font_section = if (build_options.dmcp_build and build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__const"
else
    ".rodata";

const glyph_t = abi.Glyph;

const font_t = abi.Font;
const glyph_font_search = @import("glyph_font_search.zig"); // std+abi pure search

extern var glyphNotFound: glyph_t;

// Little hexadecimal font for generating a not-found glyph (4 bytes per nibble
// row, 16 rows: 0-9 A-F).
const hexaFont: [64]u8 linksection(hexa_font_section) = .{
    0x69, 0x99, 0x99, 0x60, // 0
    0x22, 0x22, 0x22, 0x20, // 1
    0xe1, 0x16, 0x88, 0xf0, // 2
    0xe1, 0x16, 0x11, 0xe0, // 3
    0x99, 0x9f, 0x11, 0x10, // 4
    0xf8, 0x8e, 0x11, 0xe0, // 5
    0x68, 0x8e, 0x99, 0x60, // 6
    0xf1, 0x11, 0x11, 0x10, // 7
    0x69, 0x96, 0x99, 0x60, // 8
    0x69, 0x97, 0x11, 0x60, // 9
    0x69, 0x9f, 0x99, 0x90, // A
    0x88, 0x8e, 0x99, 0xe0, // b
    0x78, 0x88, 0x88, 0x70, // C
    0x11, 0x17, 0x99, 0x70, // d
    0xf8, 0x8e, 0x88, 0xf0, // E
    0xf8, 0x8e, 0x88, 0x80, // F
};

// The single binary-search core: exact charCode match, returns the index or -1
// on a miss (no id-based fallback, so a miss is never mistaken for index 0).
pub export fn findGlyphExact(font: *const font_t, charCode: u16) callconv(.c) i16 {
    return glyph_font_search.findGlyphExact(font, charCode);
}

pub export fn findGlyph(font: *const font_t, charCode: u16) callconv(.c) i16 {
    return glyph_font_search.findGlyph(font, charCode);
}

pub export fn generateNotFoundGlyph(font: i16, charCodeArg: u16) callconv(.c) void {
    var charCode = charCodeArg;
    if (charCode >= 0x8000) {
        charCode -= 0x8000;
    }

    glyphNotFound.rowsAboveGlyph = if (font == -2) 6 else 0; // -1 = standardFont
    glyphNotFound.rowsBelowGlyph = if (font == -2) 7 else 1; // -2 = numericFont

    const d = glyphNotFound.data;

    // Clear the inside of the special glyph.
    var i: i16 = 4;
    while (i <= 32) : (i += 2) {
        if (i == 18) {
            i += 2;
        }
        d[@intCast(i)] &= 0xc2;
        d[@intCast(i + 1)] &= 0x18;
    }

    // Fill the inside with the hexadecimal value of charCode.
    i = 4;
    while (i <= 32) : (i += 2) {
        if (i == 18) {
            i += 2;
        }

        var nibble1: u8 = if (i < 18) @intCast(@divTrunc(i, 2) - 2) else @intCast(@divTrunc(i, 2) - 10);
        var nibble2: u8 = undefined;
        const half: usize = nibble1 >> 1;
        const even = (nibble1 % 2 == 0);
        if (i < 18) {
            const lo: usize = @as(usize, (charCode & 0x0f00) >> 6) + half;
            const hi: usize = @as(usize, (charCode & 0xf000) >> 10) + half;
            if (even) {
                nibble2 = (hexaFont[lo] & 0xf0) >> 4;
                nibble1 = (hexaFont[hi] & 0xf0) >> 4;
            } else {
                nibble2 = hexaFont[lo] & 0x0f;
                nibble1 = hexaFont[hi] & 0x0f;
            }
        } else {
            const lo: usize = @as(usize, (charCode & 0x000f) << 2) + half;
            const hi: usize = @as(usize, (charCode & 0x00f0) >> 2) + half;
            if (even) {
                nibble2 = (hexaFont[lo] & 0xf0) >> 4;
                nibble1 = (hexaFont[hi] & 0xf0) >> 4;
            } else {
                nibble2 = hexaFont[lo] & 0x0f;
                nibble1 = hexaFont[hi] & 0x0f;
            }
        }

        d[@intCast(i)] |= @as(u8, @truncate((@as(u32, nibble1) << 2) | (@as(u32, nibble2) >> 3)));
        d[@intCast(i + 1)] |= @as(u8, @truncate(@as(u32, nibble2) << 5));
    }
}
