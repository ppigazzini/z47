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
const frontier_char_string = @import("text/char_string.zig");
const frontier_fonts = @import("fonts/fonts.zig");
// Comparison modes (src/c47/defines.h).
const CMP_BINARY: i32 = 0;
const CMP_EXTENSIVE: i32 = 2;
const CMP_NAME: i32 = 3;

// Glyph table layout copied from upstream fonts.h. findGlyph (Zig-owned in
// frontier_fonts.zig) and standardFont need this exact extern layout.
const glyph_t = abi.Glyph;

const font_t = abi.Font;

extern const standardFont: font_t;

// The glyph char-code decode, super/subscript/struck folding, and compareChar
// lead difference are pure and live in the shared std-only abi.glyph_code module.
const glyph_code = abi.glyph_code;

// Rank of a charCode in the standard font (replacement-glyph ordering).
inline fn standardGlyphs() [*]const glyph_t {
    return @ptrCast(&standardFont.glyphs);
}

pub export fn compareChar(char1: [*c]const u8, char2: [*c]const u8) callconv(.c) i32 {
    return glyph_code.compareLeadChar(char1, char2);
}

// Read the glyph char-code at byte offset `pos` (delegates to the shared decode).
inline fn glyphCodeAt(str: [*c]const u8, pos: i16) u16 {
    return glyph_code.decodeGlyphAt(str, @intCast(pos));
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
                ca = glyph_code.foldUnSupSubStruck(ca);
                cb = glyph_code.foldUnSupSubStruck(cb);
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
