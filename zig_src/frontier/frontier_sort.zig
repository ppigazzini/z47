// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/sort.c: the string-comparison primitives compareChar
// and compareString used throughout catalog, variable, and label ordering.
// Exported with C linkage and force-included by frontier.zig. compareString is
// exercised directly by the testSuite (checkCatalogsSorting compares catalog
// entries with CMP_EXTENSIVE), which gives this owner real parity coverage.
//
// The glyph char-code ranges/tables below are baked from src/c47/fonts.h via the
// upstream GLYPH_TO_CHAR_CODE macro ((byte0 << 8) | byte1), matching the
// TO_QSPI tables in the original sort.c byte-for-byte.

const abi = @import("abi");
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_fonts = @import("frontier_fonts.zig"); // M-callconv: Zig-to-Zig

// Comparison modes (src/c47/defines.h).
const CMP_BINARY: i32 = 0;
const CMP_EXTENSIVE: i32 = 2;
const CMP_NAME: i32 = 3;

// Glyph table layout copied from upstream fonts.h. findGlyph (Zig-owned in
// frontier_fonts.zig) and standardFont need this exact extern layout.
const glyph_t = abi.Glyph;

const font_t = abi.Font;

extern const standardFont: font_t;

const UnSupSubRange = struct {
    low: u16,
    num: u16,
    base: u16,
};

// UNSUBRANGE(a, b, c) = { code(a), code(b) - code(a) + 1, c } from sort.c.
const unSupSubRanges = [_]UnSupSubRange{
    .{ .low = 0xa4b6, .num = 0xa4cf - 0xa4b6 + 1, .base = 'A' }, // STD_SUP_A..Z
    .{ .low = 0xa482, .num = 0xa49b - 0xa482 + 1, .base = 'a' }, // STD_SUP_a..z
    .{ .low = 0xa160, .num = 0xa161 - 0xa160 + 1, .base = '0' }, // STD_SUP_0..1
    .{ .low = 0xa163, .num = 0xa169 - 0xa163 + 1, .base = '3' }, // STD_SUP_3..9
    .{ .low = 0xa4d0, .num = 0xa4e9 - 0xa4d0 + 1, .base = 'A' }, // STD_SUB_A..Z
    .{ .low = 0xa49c, .num = 0xa4b5 - 0xa49c + 1, .base = 'a' }, // STD_SUB_a..z
    .{ .low = 0xa080, .num = 0xa089 - 0xa080 + 1, .base = '0' }, // STD_SUB_0..9
};

// unSupSubStruckTable from sort.c: {glyph, replacement} pairs.
const unSupSubStruckTable = [_]u16{
    0xa16a, '+', // STD_SUP_PLUS
    0xa16b, '-', // STD_SUP_MINUS
    0xa09e, 0xa21e, // STD_SUP_INFINITY -> STD_INFINITY
    0xa08f, '*', // STD_SUP_ASTERISK
    0xa08a, '+', // STD_SUB_PLUS
    0xa08b, '-', // STD_SUB_MINUS
    0xa09f, 0xa21e, // STD_SUB_INFINITY -> STD_INFINITY
    0xa296, 0x83b1, // STD_SUB_alpha -> STD_alpha
    0xa297, 0x83b4, // STD_SUB_delta -> STD_delta
    0xa298, 0x83bc, // STD_SUB_mu -> STD_mu
    0xa29a, 0xa299, // STD_SUB_SUN -> STD_SUN
    0xa138, 'T', // STD_TIME_T
    0xa145, 'D', // STD_DATE_D
    0xa192, '>', // STD_RIGHT_ARROW
};

fn charCodeUnSupSubStruck(charCode: u16) u16 {
    for (unSupSubRanges) |r| {
        if (charCode >= r.low and charCode < r.low + r.num) {
            return charCode - r.low + r.base;
        }
    }
    var i: usize = 0;
    while (i < unSupSubStruckTable.len) : (i += 2) {
        if (charCode == unSupSubStruckTable[i]) {
            return unSupSubStruckTable[i + 1];
        }
    }
    return charCode;
}

// Rank of a charCode in the standard font (replacement-glyph ordering).
inline fn standardGlyphs() [*]const glyph_t {
    return @ptrCast(&standardFont.glyphs);
}

pub export fn compareChar(char1: [*c]const u8, char2: [*c]const u8) callconv(.c) i32 {
    const code1: i16 = if ((char1[0] & 0x80) != 0)
        @intCast((@as(u16, char1[0] & 0x7f) << 8) | @as(u16, char1[1]))
    else
        @intCast(char1[0]);
    const code2: i16 = if ((char2[0] & 0x80) != 0)
        @intCast((@as(u16, char2[0] & 0x7f) << 8) | @as(u16, char2[1]))
    else
        @intCast(char2[0]);
    return @as(i32, code1) - @as(i32, code2);
}

// Read the glyph char-code at byte offset `pos` (two bytes when the high bit of
// the lead byte is set), matching the inline decode in sort.c.
inline fn glyphCodeAt(str: [*c]const u8, pos: i16) u16 {
    const p: usize = @intCast(pos);
    var charCode: u16 = str[p];
    if (charCode >= 0x80) {
        charCode = (charCode << 8) + str[p + 1];
    }
    return charCode;
}

pub export fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparisonType: i32) callconv(.c) i32 {
    const lga: i32 = frontier_char_string.stringGlyphLength(stra);
    const lgb: i32 = frontier_char_string.stringGlyphLength(strb);
    const shorter: i32 = if (lga < lgb) lga else lgb;

    // Compare using charCode only (binary or name ordering).
    if (comparisonType == CMP_BINARY or comparisonType == CMP_NAME) {
        var posa: i16 = 0;
        var posb: i16 = 0;
        var i: i32 = 0;
        while (i < shorter) : (i += 1) {
            var ca = glyphCodeAt(stra, posa);
            var cb = glyphCodeAt(strb, posb);
            if (comparisonType == CMP_NAME) {
                ca = charCodeUnSupSubStruck(ca);
                cb = charCodeUnSupSubStruck(cb);
            }
            const ranka: i16 = @bitCast(ca);
            const rankb: i16 = @bitCast(cb);
            if (ranka < rankb) return -1;
            if (ranka > rankb) return 1;
            posa = frontier_char_string.stringNextGlyph(stra, posa);
            posb = frontier_char_string.stringNextGlyph(strb, posb);
        }
        if (lga < lgb) return -1;
        if (lga > lgb) return 1;
        return 0;
    }

    // Compare using replacement glyphs (rank1).
    const glyphs = standardGlyphs();
    var posa: i16 = 0;
    var posb: i16 = 0;
    var i: i32 = 0;
    while (i < shorter) : (i += 1) {
        const ranka = glyphs[@intCast(frontier_fonts.findGlyph(&standardFont, glyphCodeAt(stra, posa)))].rank1;
        const rankb = glyphs[@intCast(frontier_fonts.findGlyph(&standardFont, glyphCodeAt(strb, posb)))].rank1;
        if (ranka < rankb) return -1;
        if (ranka > rankb) return 1;
        posa = frontier_char_string.stringNextGlyph(stra, posa);
        posb = frontier_char_string.stringNextGlyph(strb, posb);
    }
    if (lga < lgb) return -1;
    if (lga > lgb) return 1;

    // Replacement-glyph strings are equal: fall back to the original strings.
    if (comparisonType == CMP_EXTENSIVE) {
        posa = 0;
        posb = 0;
        i = 0;
        while (i < shorter) : (i += 1) {
            const ranka = glyphs[@intCast(frontier_fonts.findGlyph(&standardFont, glyphCodeAt(stra, posa)))].rank2;
            const rankb = glyphs[@intCast(frontier_fonts.findGlyph(&standardFont, glyphCodeAt(strb, posb)))].rank2;
            if (ranka < rankb) return -1;
            if (ranka > rankb) return 1;
            posa = frontier_char_string.stringNextGlyph(stra, posa);
            posb = frontier_char_string.stringNextGlyph(strb, posb);
        }
        if (lga < lgb) return -1;
        if (lga > lgb) return 1;
    }

    return 0;
}
