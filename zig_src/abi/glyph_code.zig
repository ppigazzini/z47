// SPDX-License-Identifier: GPL-3.0-only
//
// Pure glyph char-code helpers lifted from frontier_sort.zig (src/c47/sort.c):
// the 1-or-2-byte glyph-code decode, the super/subscript/struck-through folding
// used by CMP_NAME ordering, and the compareChar lead-glyph difference. These
// depend on nothing but their byte inputs (the fold tables are baked from
// fonts.h as u16 literals), so the module imports only std and is exercised
// natively under `zig build test:unit`, reachable as `abi.glyph_code`. The
// frontier owner keeps its C-ABI compareChar/compareString wrappers and delegates.
//
// compareString (hence foldUnSupSubStruck) is exercised by the testSuite's
// checkCatalogsSorting (CMP_EXTENSIVE/CMP_NAME), so the extraction is byte-checked
// at 9674/9674 in addition to the native tests below.

const std = @import("std");

// UNSUBRANGE(a, b, c) = { code(a), code(b) - code(a) + 1, c } from sort.c: a
// contiguous glyph range folded onto a base ASCII character.
const UnSupSubRange = struct { low: u16, num: u16, base: u16 };

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

/// Fold a super/subscript/struck-through glyph code to its base character code
/// (charCodeUnSupSubStruck from sort.c). Codes outside the ranges/table pass
/// through unchanged. Pure u16 -> u16.
pub fn foldUnSupSubStruck(char_code: u16) u16 {
    for (unSupSubRanges) |r| {
        if (char_code >= r.low and char_code < r.low + r.num) {
            return char_code - r.low + r.base;
        }
    }
    var i: usize = 0;
    while (i < unSupSubStruckTable.len) : (i += 2) {
        if (char_code == unSupSubStruckTable[i]) {
            return unSupSubStruckTable[i + 1];
        }
    }
    return char_code;
}

/// Decode the glyph char-code at byte offset `pos` (two bytes, KEEPING the lead
/// byte's marker bit, when that high bit is set), matching glyphCodeAt in sort.c.
/// Takes an unbounded many-item pointer because the C caller reads a NUL-checked
/// glyph string, not a bounded slice.
pub fn decodeGlyphAt(str: [*]const u8, pos: usize) u16 {
    var char_code: u16 = str[pos];
    if (char_code >= 0x80) {
        char_code = (char_code << 8) + str[pos + 1];
    }
    return char_code;
}

/// Decode the glyph char-code at `offset` (or from 0 when `offset` is null) and
/// advance `offset` past it -- charCodeFromString in charString.c. Same 1-or-2
/// byte decode as decodeGlyphAt (marker bit kept), but it also reports how many
/// bytes it consumed by writing the new position back through `offset`. The
/// wrapping u16 index arithmetic matches the owner.
pub fn charCodeFromString(ch: [*]const u8, offset: ?*u16) u16 {
    var loffset: u16 = if (offset) |o| o.* else 0;
    var char_code: u16 = ch[loffset];
    loffset +%= 1;
    if (char_code & 0x0080 != 0) {
        char_code = (char_code << 8) | ch[loffset];
        loffset +%= 1;
    }
    if (offset) |o| {
        o.* = loffset;
    }
    return char_code;
}

/// Signed difference of two lead glyph codes (compareChar from sort.c). NOTE the
/// decode here STRIPS the marker bit (`& 0x7f`) -- deliberately different from
/// decodeGlyphAt, which keeps it; the two encode distinct orderings in sort.c.
pub fn compareLeadChar(char1: [*]const u8, char2: [*]const u8) i32 {
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

// ===========================================================================
// Tests -- native (run under `zig build test:unit`).
// ===========================================================================
const testing = std.testing;

test "decodeGlyphAt: single-byte ASCII" {
    const s = [_]u8{'A'};
    try testing.expectEqual(@as(u16, 'A'), decodeGlyphAt(&s, 0));
}

test "decodeGlyphAt: a two-byte glyph keeps the marker bit" {
    const s = [_]u8{ 0xa4, 0xb6 }; // STD_SUP_A
    try testing.expectEqual(@as(u16, 0xa4b6), decodeGlyphAt(&s, 0));
}

test "foldUnSupSubStruck: a superscript letter folds to its base" {
    try testing.expectEqual(@as(u16, 'A'), foldUnSupSubStruck(0xa4b6)); // STD_SUP_A
    try testing.expectEqual(@as(u16, 'Z'), foldUnSupSubStruck(0xa4cf)); // top of the range
}

test "foldUnSupSubStruck: a subscript digit folds to its base" {
    try testing.expectEqual(@as(u16, '0'), foldUnSupSubStruck(0xa080)); // STD_SUB_0
    try testing.expectEqual(@as(u16, '9'), foldUnSupSubStruck(0xa089));
}

test "foldUnSupSubStruck: a struck-table entry maps to its replacement" {
    try testing.expectEqual(@as(u16, '+'), foldUnSupSubStruck(0xa16a)); // STD_SUP_PLUS
    try testing.expectEqual(@as(u16, 0xa21e), foldUnSupSubStruck(0xa09e)); // SUP_INFINITY -> INFINITY
    try testing.expectEqual(@as(u16, '>'), foldUnSupSubStruck(0xa192)); // RIGHT_ARROW
}

test "foldUnSupSubStruck: a plain code passes through unchanged" {
    try testing.expectEqual(@as(u16, 'A'), foldUnSupSubStruck('A'));
    try testing.expectEqual(@as(u16, 0x1234), foldUnSupSubStruck(0x1234));
}

test "foldUnSupSubStruck: every ranged code folds within its base alphabet" {
    // The superscript A..Z range must fold to a contiguous 'A'..'Z' run.
    var c: u16 = 0xa4b6;
    var expected: u16 = 'A';
    while (c <= 0xa4cf) : (c += 1) {
        try testing.expectEqual(expected, foldUnSupSubStruck(c));
        expected += 1;
    }
}

test "compareLeadChar: ASCII difference" {
    const a = [_]u8{'A'};
    const b = [_]u8{'B'};
    try testing.expectEqual(@as(i32, -1), compareLeadChar(&a, &b));
    try testing.expectEqual(@as(i32, 0), compareLeadChar(&a, &a));
}

test "compareLeadChar: the two-byte decode strips the marker bit" {
    const sup_a = [_]u8{ 0xa4, 0xb6 }; // (0x24 << 8) | 0xb6 = 0x24b6
    const ascii_a = [_]u8{'A'}; // 0x41
    try testing.expectEqual(@as(i32, 0x24b6 - 0x41), compareLeadChar(&sup_a, &ascii_a));
}

test "charCodeFromString: single-byte ASCII advances the offset by one" {
    const s = [_]u8{ 'A', 'B', 0 };
    var off: u16 = 0;
    try testing.expectEqual(@as(u16, 0x41), charCodeFromString(&s, &off));
    try testing.expectEqual(@as(u16, 1), off);
}

test "charCodeFromString: a two-byte glyph keeps the marker bit and advances by two" {
    const s = [_]u8{ 0xa0, 0x80, 0 };
    var off: u16 = 0;
    try testing.expectEqual(@as(u16, 0xa080), charCodeFromString(&s, &off));
    try testing.expectEqual(@as(u16, 2), off);
}

test "charCodeFromString: a null offset decodes from position zero without reporting" {
    const s = [_]u8{ 0xa4, 0x9c, 0 };
    try testing.expectEqual(@as(u16, 0xa49c), charCodeFromString(&s, null));
}

test "charCodeFromString: sequential decode walks glyph by glyph" {
    // 'x' (1 byte) then a two-byte glyph then '9' (1 byte).
    const s = [_]u8{ 'x', 0xa0, 0x81, '9', 0 };
    var off: u16 = 0;
    try testing.expectEqual(@as(u16, 0x78), charCodeFromString(&s, &off));
    try testing.expectEqual(@as(u16, 1), off);
    try testing.expectEqual(@as(u16, 0xa081), charCodeFromString(&s, &off));
    try testing.expectEqual(@as(u16, 3), off);
    try testing.expectEqual(@as(u16, 0x39), charCodeFromString(&s, &off));
    try testing.expectEqual(@as(u16, 4), off);
}
