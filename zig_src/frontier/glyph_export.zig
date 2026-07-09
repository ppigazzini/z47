// SPDX-License-Identifier: GPL-3.0-only
//! Pure glyph -> export-character decoders lifted out of frontier_char_string.zig
//! (src/c47/charString.c). stringToASCII walks a glyph string and turns each
//! two-byte glyph into its plain-ASCII form; the range-decode chain at its heart
//! (superscript/subscript letters and digits, #-prefixed number bases, and the
//! curly-quote folds) moves here as `asciiFromGlyph`.
//!
//! The glyph ranges are threaded in as an AsciiRanges value built from the
//! owner's STD_* constants, so the module needs none of the shared glyph tables
//! and imports only std. The owner keeps the parts that are not pure decode --
//! the getText table lookup, the 0x81..0x83 "_" case, and the host-only debug
//! print of an undecoded glyph -- and the loop's output-pointer choreography.
//!
//! stringToASCII feeds clipboard/file export and ASCII menu names, so the
//! native tests below (bytes derived from the glyph range arithmetic, not the
//! port) are the decode's first direct coverage.

const std = @import("std");

/// A contiguous glyph range: matches when a1 == lead and lo <= a2 <= hi. `lo`
/// doubles as the base offset the decode arithmetic subtracts.
pub const GlyphRange = struct { lead: u8, lo: u8, hi: u8 };

/// The glyph ranges stringToASCII folds to plain ASCII, in check order.
pub const AsciiRanges = struct {
    sup_digit: GlyphRange, // -> '0' + (a2 - lo)
    sup_lower: GlyphRange, // -> 'a' + (a2 - lo)
    sup_upper: GlyphRange, // -> 'A' + (a2 - lo)
    sub_digit: GlyphRange, // -> '0' + (a2 - lo)
    sub_lower: GlyphRange, // -> 'a' + (a2 - lo)
    sub_upper: GlyphRange, // -> 'A' + (a2 - lo)
    base_low: GlyphRange, // bases 1..9   -> '#', '1' + (a2 - lo)
    base_high: GlyphRange, // bases 10..16 -> '#', '1', '0' + (a2 - lo)
    single_quote: GlyphRange, // -> '\''
    double_quote: GlyphRange, // -> '"'
};

fn inRange(a1: u8, a2: u8, r: GlyphRange) bool {
    return a1 == r.lead and a2 >= r.lo and a2 <= r.hi;
}

/// Decode the two-byte glyph (a1,a2) to plain ASCII, writing 1-3 bytes to `out`
/// and returning the count, or null when the glyph matches none of the ranges
/// (the owner then handles the 0x81..0x83 "_" case, the getText table, and the
/// undecoded fallback). Wrapping arithmetic (+%/-%) matches stringToASCII.
pub fn asciiFromGlyph(a1: u8, a2: u8, out: [*]u8, g: AsciiRanges) ?usize {
    if (inRange(a1, a2, g.sup_digit)) {
        out[0] = ('0' +% a2) -% g.sup_digit.lo;
        return 1;
    } else if (inRange(a1, a2, g.sup_lower)) {
        out[0] = ('a' +% a2) -% g.sup_lower.lo;
        return 1;
    } else if (inRange(a1, a2, g.sup_upper)) {
        out[0] = ('A' +% a2) -% g.sup_upper.lo;
        return 1;
    } else if (inRange(a1, a2, g.sub_digit)) {
        out[0] = ('0' +% a2) -% g.sub_digit.lo;
        return 1;
    } else if (inRange(a1, a2, g.sub_lower)) {
        out[0] = ('a' +% a2) -% g.sub_lower.lo;
        return 1;
    } else if (inRange(a1, a2, g.sub_upper)) {
        out[0] = ('A' +% a2) -% g.sub_upper.lo;
        return 1;
    } else if (inRange(a1, a2, g.base_low)) {
        out[0] = '#';
        out[1] = ('1' +% a2) -% g.base_low.lo;
        return 2;
    } else if (inRange(a1, a2, g.base_high)) {
        out[0] = '#';
        out[1] = '1';
        out[2] = ('0' +% a2) -% g.base_high.lo;
        return 3;
    } else if (inRange(a1, a2, g.single_quote)) {
        out[0] = '\'';
        return 1;
    } else if (inRange(a1, a2, g.double_quote)) {
        out[0] = '"';
        return 1;
    }
    return null;
}

/// The superscript/subscript glyph ranges stringToRTF wraps in RTF markup.
pub const SupSubRanges = struct {
    sup_digit: GlyphRange, // '0' + (a2 - lo), superscript
    sup_lower: GlyphRange, // 'a' + (a2 - lo), superscript
    sup_upper: GlyphRange, // 'A' + (a2 - lo), superscript
    sub_digit: GlyphRange, // '0' + (a2 - lo), subscript
    sub_lower: GlyphRange, // 'a' + (a2 - lo), subscript
    sub_upper: GlyphRange, // 'A' + (a2 - lo), subscript
};

/// Decode a superscript/subscript glyph (a1,a2) to its RTF markup, writing
/// `\super `/`\sub `, the ASCII character, then `\nosupersub ` to `out` and
/// returning the total byte count. Returns null when the glyph is not sup/sub
/// (the owner then tries getTextRTF and the \uNNN? escape). The decoded
/// character is always printable, so the owner's `if (bb[0] != 0)` markup guard
/// is always taken here; wrapping arithmetic (+%/-%) matches stringToRTF.
pub fn rtfFromGlyph(a1: u8, a2: u8, out: [*]u8, g: SupSubRanges) ?usize {
    var sign: i8 = undefined;
    var ch: u8 = undefined;
    if (inRange(a1, a2, g.sup_digit)) {
        sign = 1;
        ch = ('0' +% a2) -% g.sup_digit.lo;
    } else if (inRange(a1, a2, g.sup_lower)) {
        sign = 1;
        ch = ('a' +% a2) -% g.sup_lower.lo;
    } else if (inRange(a1, a2, g.sup_upper)) {
        sign = 1;
        ch = ('A' +% a2) -% g.sup_upper.lo;
    } else if (inRange(a1, a2, g.sub_digit)) {
        sign = -1;
        ch = ('0' +% a2) -% g.sub_digit.lo;
    } else if (inRange(a1, a2, g.sub_lower)) {
        sign = -1;
        ch = ('a' +% a2) -% g.sub_lower.lo;
    } else if (inRange(a1, a2, g.sub_upper)) {
        sign = -1;
        ch = ('A' +% a2) -% g.sub_upper.lo;
    } else {
        return null;
    }

    var d: usize = 0;
    const prefix = if (sign == 1) "\\super " else "\\sub ";
    for (prefix) |c| {
        out[d] = c;
        d += 1;
    }
    out[d] = ch;
    d += 1;
    for ("\\nosupersub ") |c| {
        out[d] = c;
        d += 1;
    }
    return d;
}

const testing = std.testing;

const owner_supsub = SupSubRanges{
    .sup_digit = .{ .lead = 0xa1, .lo = 0x60, .hi = 0x69 },
    .sup_lower = .{ .lead = 0xa4, .lo = 0x82, .hi = 0x9b },
    .sup_upper = .{ .lead = 0xa4, .lo = 0xb6, .hi = 0xcf },
    .sub_digit = .{ .lead = 0xa0, .lo = 0x80, .hi = 0x89 },
    .sub_lower = .{ .lead = 0xa4, .lo = 0x9c, .hi = 0xb5 },
    .sub_upper = .{ .lead = 0xa4, .lo = 0xd0, .hi = 0xe9 },
};

test "rtfFromGlyph wraps a superscript glyph in \\super markup" {
    var out: [32]u8 = undefined;
    const n = rtfFromGlyph(0xa1, 0x60, &out, owner_supsub).?; // superscript '0'
    try testing.expectEqualStrings("\\super 0\\nosupersub ", out[0..n]);
}

test "rtfFromGlyph wraps a subscript glyph in \\sub markup" {
    var out: [32]u8 = undefined;
    const n = rtfFromGlyph(0xa4, 0x9c, &out, owner_supsub).?; // subscript 'a'
    try testing.expectEqualStrings("\\sub a\\nosupersub ", out[0..n]);
    const m = rtfFromGlyph(0xa4, 0xd0, &out, owner_supsub).?; // subscript 'A'
    try testing.expectEqualStrings("\\sub A\\nosupersub ", out[0..m]);
}

test "rtfFromGlyph returns null for a non-sup/sub glyph" {
    var out: [32]u8 = undefined;
    // a curly-quote glyph (0xa0,0x18): stringToRTF has no sup/sub match for it.
    try testing.expectEqual(@as(?usize, null), rtfFromGlyph(0xa0, 0x18, &out, owner_supsub));
    try testing.expectEqual(@as(?usize, null), rtfFromGlyph(0x81, 0x00, &out, owner_supsub));
}

// The owner's frontier_char_string.zig glyph constants, verbatim.
const owner_ranges = AsciiRanges{
    .sup_digit = .{ .lead = 0xa1, .lo = 0x60, .hi = 0x69 }, // STD_SUP_0..9
    .sup_lower = .{ .lead = 0xa4, .lo = 0x82, .hi = 0x9b }, // STD_SUP_a..z
    .sup_upper = .{ .lead = 0xa4, .lo = 0xb6, .hi = 0xcf }, // STD_SUP_A..Z
    .sub_digit = .{ .lead = 0xa0, .lo = 0x80, .hi = 0x89 }, // STD_SUB_0..9
    .sub_lower = .{ .lead = 0xa4, .lo = 0x9c, .hi = 0xb5 }, // STD_SUB_a..z
    .sub_upper = .{ .lead = 0xa4, .lo = 0xd0, .hi = 0xe9 }, // STD_SUB_A..Z
    .base_low = .{ .lead = 0xa4, .lo = 0x60, .hi = 0x68 }, // STD_BASE_1..9
    .base_high = .{ .lead = 0xa4, .lo = 0x69, .hi = 0x6f }, // STD_BASE_10..16
    .single_quote = .{ .lead = 0xa0, .lo = 0x18, .hi = 0x1b },
    .double_quote = .{ .lead = 0xa0, .lo = 0x1c, .hi = 0x1f },
};

fn decode1(a1: u8, a2: u8) ?u8 {
    var out: [4]u8 = undefined;
    const n = asciiFromGlyph(a1, a2, &out, owner_ranges) orelse return null;
    return if (n == 1) out[0] else null;
}

test "asciiFromGlyph folds superscript digits and letters to ASCII" {
    try testing.expectEqual(@as(?u8, '0'), decode1(0xa1, 0x60));
    try testing.expectEqual(@as(?u8, '9'), decode1(0xa1, 0x69));
    try testing.expectEqual(@as(?u8, 'a'), decode1(0xa4, 0x82));
    try testing.expectEqual(@as(?u8, 'z'), decode1(0xa4, 0x9b));
    try testing.expectEqual(@as(?u8, 'A'), decode1(0xa4, 0xb6));
    try testing.expectEqual(@as(?u8, 'Z'), decode1(0xa4, 0xcf));
}

test "asciiFromGlyph folds subscript digits and letters to ASCII" {
    try testing.expectEqual(@as(?u8, '0'), decode1(0xa0, 0x80));
    try testing.expectEqual(@as(?u8, '9'), decode1(0xa0, 0x89));
    try testing.expectEqual(@as(?u8, 'a'), decode1(0xa4, 0x9c));
    try testing.expectEqual(@as(?u8, 'z'), decode1(0xa4, 0xb5));
    try testing.expectEqual(@as(?u8, 'A'), decode1(0xa4, 0xd0));
    try testing.expectEqual(@as(?u8, 'Z'), decode1(0xa4, 0xe9));
}

test "asciiFromGlyph expands base glyphs with a # prefix" {
    var out: [4]u8 = undefined;
    try testing.expectEqual(@as(?usize, 2), asciiFromGlyph(0xa4, 0x60, &out, owner_ranges));
    try testing.expectEqualStrings("#1", out[0..2]);
    try testing.expectEqual(@as(?usize, 2), asciiFromGlyph(0xa4, 0x68, &out, owner_ranges));
    try testing.expectEqualStrings("#9", out[0..2]);
    try testing.expectEqual(@as(?usize, 3), asciiFromGlyph(0xa4, 0x69, &out, owner_ranges));
    try testing.expectEqualStrings("#10", out[0..3]);
    try testing.expectEqual(@as(?usize, 3), asciiFromGlyph(0xa4, 0x6f, &out, owner_ranges));
    try testing.expectEqualStrings("#16", out[0..3]);
}

test "asciiFromGlyph folds the curly quotes" {
    try testing.expectEqual(@as(?u8, '\''), decode1(0xa0, 0x18));
    try testing.expectEqual(@as(?u8, '\''), decode1(0xa0, 0x1b));
    try testing.expectEqual(@as(?u8, '"'), decode1(0xa0, 0x1c));
    try testing.expectEqual(@as(?u8, '"'), decode1(0xa0, 0x1f));
}

test "asciiFromGlyph returns null for a glyph in no range" {
    var out: [4]u8 = undefined;
    try testing.expectEqual(@as(?usize, null), asciiFromGlyph(0x81, 0x00, &out, owner_ranges));
    try testing.expectEqual(@as(?usize, null), asciiFromGlyph(0xa1, 0x70, &out, owner_ranges)); // past sup digit hi
    try testing.expectEqual(@as(?usize, null), asciiFromGlyph(0xa4, 0x70, &out, owner_ranges)); // gap above base_high
}
