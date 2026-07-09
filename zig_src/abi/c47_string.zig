// SPDX-License-Identifier: GPL-3.0-only
//
// Pure C47 glyph-string navigation + UTF-8 codec, lifted from
// frontier_char_string.zig (src/c47/stringFuncs.c). The C47 internal encoding
// stores a glyph as one byte, or two bytes when the lead byte's high bit is set.
// These primitives walk that encoding (glyph count, next/prev glyph offset, last
// glyph, previous numeric glyph, template validation) and convert code points to
// and from UTF-8. They depend on nothing but the byte buffer, so they live here as
// a std-only module exercised natively under `zig build test:unit`, reachable as
// abi.c47_string. The frontier owner keeps its pub-export C-ABI wrappers (and the
// stringLastGlyph null guard) and delegates.
//
// stringNextGlyph/stringGlyphLength are testSuite-covered via compareString
// (catalog sorting); the editing/UTF-8 helpers are largely testSuite-blind, so the
// native tests below are their coverage. The C `char *` becomes a many-item
// pointer and strlen becomes an internal NUL scan; i16/i32/u32 widths are kept so
// the arithmetic is byte-identical.

const std = @import("std");

/// Byte length to the NUL terminator (the C `strlen`, returned as i32 to match
/// the owner's stringByteLength).
fn byteLen(str: [*]const u8) i32 {
    var i: usize = 0;
    while (str[i] != 0) : (i += 1) {}
    return @intCast(i);
}

/// stringNextGlyphNoEndCheck_JM: advance one glyph, not clamping to the length.
pub fn nextGlyphNoEndCheck(str: [*]const u8, posIn: i16) i16 {
    var pos = posIn;
    var posinc: i16 = 0;
    if (str[@intCast(pos)] == 0) {
        return pos;
    }
    if (str[@intCast(pos)] & 0x80 != 0) {
        posinc = 2;
        if (str[@intCast(pos + 2)] == 0) {
            return pos + 2;
        }
    } else {
        posinc = 1;
        if (str[@intCast(pos + 1)] == 0) {
            return pos + 1;
        }
    }
    pos += posinc;
    return pos;
}

/// stringNextGlyph: advance one glyph, clamped to the byte length.
pub fn nextGlyph(str: [*]const u8, posIn: i16) i16 {
    var pos = posIn;
    const lg: i16 = @intCast(byteLen(str));
    if (pos >= lg) {
        return lg;
    }
    pos += if (str[@intCast(pos)] & 0x80 != 0) @as(i16, 2) else @as(i16, 1);
    if (pos >= lg) {
        return lg;
    } else {
        return pos;
    }
}

/// stringPrevGlyph: the glyph offset immediately before `pos`.
pub fn prevGlyph(str: [*]const u8, posIn: i16) i16 {
    var pos = posIn;
    var prev: i16 = 0;
    const lg: i16 = @intCast(byteLen(str));
    if (pos >= lg) {
        pos = lg;
    }
    if (pos <= 1) {
        return 0;
    } else {
        var cnt: i16 = 0;
        while (str[@intCast(cnt)] != 0 and cnt < pos) {
            prev = cnt;
            cnt = nextGlyph(str, cnt);
        }
    }
    return prev;
}

/// isValidNumber: does `ss` match `template` (`.`=separator, `d`=digit, `s`=sign)?
pub fn isValidNumber(ss: [*]const u8, template: [*]const u8) bool {
    if (byteLen(ss) != byteLen(template)) {
        return false;
    }
    var nn: u16 = @intCast(byteLen(ss));
    while (nn != 0) {
        if ((template[nn - 1] == '.' and !(ss[nn - 1] == '.' or ss[nn - 1] == ',')) or
            (template[nn - 1] == 'd' and !(ss[nn - 1] >= '0' and ss[nn - 1] <= '9')) or
            (template[nn - 1] == 's' and !(ss[nn - 1] == '-' or ss[nn - 1] == '+')))
        {
            return false;
        }
        nn -%= 1;
    }
    return true;
}

/// stringPrevNumberGlyph: the previous glyph that is a digit (or the separator).
pub fn prevNumberGlyph(str: [*]const u8, pos: i16) i16 {
    var pos2: i16 = pos;
    while (true) {
        pos2 = prevGlyph(str, pos2);
        if (('0' <= str[@intCast(pos2)] and str[@intCast(pos2)] <= '9') or str[@intCast(pos)] == '.' or str[@intCast(pos)] == ',') {
            return pos2;
        }
        if (pos2 == 0) break;
    }
    return 0;
}

/// stringLastGlyph body (the null guard stays in the owner wrapper).
pub fn lastGlyph(str: [*]const u8) i16 {
    var last: i16 = 0;
    const lg: i16 = @intCast(byteLen(str));
    var next: i16 = 0;
    while (true) {
        if (last >= lg) {
            next = lg;
        } else {
            next += if (str[@intCast(last)] & 0x80 != 0) @as(i16, 2) else @as(i16, 1);
            if (next > lg) {
                next = lg;
            }
        }
        if (next == lg) {
            break;
        }
        last = next;
    }
    return last;
}

/// stringGlyphLength: the number of glyphs (not bytes) up to the NUL.
pub fn glyphLength(strIn: [*]const u8) i32 {
    var str = strIn;
    var len: i32 = 0;
    while (str[0] != 0) {
        if (str[0] & 0x80 != 0) {
            str += 2;
            len += 1;
        } else {
            str += 1;
            len += 1;
        }
    }
    return len;
}

/// codePointToUtf8: encode `codePoint` (<= 0xFFFF) into 1-3 UTF-8 bytes + trailing
/// zeros, into a 5-byte buffer.
pub fn codePointToUtf8(codePoint: u32, utf8: [*]u8) void {
    if (codePoint <= 0x00007F) {
        utf8[0] = @truncate(codePoint);
        utf8[1] = 0;
        utf8[2] = 0;
        utf8[3] = 0;
        utf8[4] = 0;
    } else if (codePoint <= 0x0007FF) {
        utf8[0] = @truncate(0xC0 | (codePoint >> 6));
        utf8[1] = @truncate(0x80 | (codePoint & 0x3F));
        utf8[2] = 0;
        utf8[3] = 0;
        utf8[4] = 0;
    } else {
        utf8[0] = @truncate(0xE0 | (codePoint >> 12));
        utf8[1] = @truncate(0x80 | ((codePoint >> 6) & 0x3F));
        utf8[2] = @truncate(0x80 | (codePoint & 0x3F));
        utf8[3] = 0;
        utf8[4] = 0;
    }
}

/// utf8ToCodePoint: decode the leading UTF-8 byte(s) into `codePoint`, returning
/// the number of bytes consumed (1-3).
pub fn utf8ToCodePoint(utf8: [*]const u8, codePoint: *u32) u32 {
    if ((utf8[0] & 0x80) == 0) {
        codePoint.* = utf8[0];
        return 1;
    } else if ((utf8[0] & 0xE0) == 0xC0) {
        codePoint.* = (@as(u32, utf8[0]) & 0x1F) << 6;
        codePoint.* |= (@as(u32, utf8[1]) & 0x3F);
        return 2;
    } else {
        codePoint.* = (@as(u32, utf8[0]) & 0x0F) << 12;
        codePoint.* |= (@as(u32, utf8[1]) & 0x3F) << 6;
        codePoint.* |= (@as(u32, utf8[2]) & 0x3F);
        return 3;
    }
}

// ===========================================================================
// Tests -- native (run under `zig build test:unit`). Fixtures use the C47
// encoding: a byte >= 0x80 starts a two-byte glyph. "\xa4\xb6" is one glyph.
// ===========================================================================
const testing = std.testing;

// "A" + one two-byte glyph (0xa4,0xb6) + "B": 4 bytes, 3 glyphs at offsets 0,1,3.
const mixed: [*:0]const u8 = "A\xa4\xb6B";

test "glyphLength counts glyphs, not bytes" {
    try testing.expectEqual(@as(i32, 2), glyphLength("AB"));
    try testing.expectEqual(@as(i32, 1), glyphLength("\xa4\xb6"));
    try testing.expectEqual(@as(i32, 3), glyphLength(mixed));
    try testing.expectEqual(@as(i32, 0), glyphLength(""));
}

test "nextGlyph steps one glyph and clamps to the length" {
    try testing.expectEqual(@as(i16, 1), nextGlyph(mixed, 0)); // 1-byte 'A'
    try testing.expectEqual(@as(i16, 3), nextGlyph(mixed, 1)); // 2-byte glyph
    try testing.expectEqual(@as(i16, 4), nextGlyph(mixed, 3)); // 'B' -> clamp to len
}

test "prevGlyph finds the offset before pos" {
    try testing.expectEqual(@as(i16, 1), prevGlyph(mixed, 3));
    try testing.expectEqual(@as(i16, 0), prevGlyph(mixed, 1)); // pos<=1 -> 0
}

test "lastGlyph returns the final glyph offset" {
    try testing.expectEqual(@as(i16, 3), lastGlyph(mixed));
    try testing.expectEqual(@as(i16, 0), lastGlyph("A"));
}

test "isValidNumber matches a sign/digit/separator template" {
    try testing.expect(isValidNumber("+5", "sd"));
    try testing.expect(isValidNumber("-12.34", "sdd.dd"));
    try testing.expect(isValidNumber("12,34", "dd.dd")); // ',' also accepted for '.'
    try testing.expect(!isValidNumber("+a", "sd")); // 'a' is not a digit
    try testing.expect(!isValidNumber("+5", "sdd")); // length mismatch
}

test "prevNumberGlyph returns the previous digit glyph" {
    try testing.expectEqual(@as(i16, 2), prevNumberGlyph("123", 3));
}

test "codePointToUtf8 encodes the three length classes" {
    var buf: [5]u8 = undefined;
    codePointToUtf8('A', &buf);
    try testing.expectEqualSlices(u8, &.{ 0x41, 0, 0, 0, 0 }, &buf);
    codePointToUtf8(0x00A9, &buf); // copyright sign
    try testing.expectEqualSlices(u8, &.{ 0xC2, 0xA9, 0, 0, 0 }, &buf);
    codePointToUtf8(0x20AC, &buf); // euro sign
    try testing.expectEqualSlices(u8, &.{ 0xE2, 0x82, 0xAC, 0, 0 }, &buf);
}

test "utf8ToCodePoint inverts codePointToUtf8, returning the byte count" {
    var buf: [5]u8 = undefined;
    var cp: u32 = undefined;
    inline for (.{ .{ @as(u32, 'A'), 1 }, .{ @as(u32, 0x00A9), 2 }, .{ @as(u32, 0x20AC), 3 } }) |c| {
        codePointToUtf8(c[0], &buf);
        const n = utf8ToCodePoint(&buf, &cp);
        try testing.expectEqual(@as(u32, c[0]), cp);
        try testing.expectEqual(@as(u32, c[1]), n);
    }
}
