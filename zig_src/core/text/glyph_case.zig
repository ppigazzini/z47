//! Glyph decoding and case conversion -- the pure core of frontier_string_funcs'
//! _getGlyphCode / _isSameGlyph / _toUpperOrLowerCase.
//!
//! The alpha string owner encodes each display glyph as one byte, or two bytes
//! when the high bit of the first is set. Reading a glyph code, comparing a code
//! against the glyph at a position, and rewriting a string to upper/lower case
//! via the upperLowerTable map are all pure byte arithmetic over a caller-owned
//! string plus the const case table. The owner touches state only at the edges
//! (the register fetch and the glyph-length count); the transforms themselves
//! carry no globals.
//!
//! Lifting them here gives the glyph codec and the case map their first native
//! coverage -- the string owner is only reachable through the C oracle. The owner
//! keeps _getGlyphCode / _isSameGlyph / _toUpperOrLowerCase as thin wrappers so
//! its several call sites are unchanged; each delegates here (passing the glyph
//! length and the case table in). This module uses Zig many-item pointers rather
//! than C pointers.

const std = @import("std");
const abi = @import("abi");

/// Read the 1- or 2-byte glyph code at the head of `ptr`. A high bit set on the
/// first byte means a two-byte glyph, packed big-endian.
pub fn glyphCode(ptr: [*]const u8) u16 {
    var glyph: u16 = @as(u16, ptr[0]) & 0xff;
    if ((glyph & 0x80) != 0) {
        glyph = (glyph << 8) | (@as(u16, ptr[1]) & 0xff);
    }
    return glyph;
}

/// Whether the glyph at `ptr` equals `glyph` (a code from glyphCode).
pub fn isSameGlyph(glyph: u16, ptr: [*]const u8) bool {
    var p: [*]const u8 = ptr;
    if ((glyph & 0x8000) != 0) {
        if ((glyph >> 8) != (@as(u16, p[0]) & 0xff)) {
            return false;
        }
        p += 1;
    }
    return (glyph & 0xff) == (@as(u16, p[0]) & 0xff);
}

/// Rewrite `ptr` in place to upper (`to_upper` true) or lower case, using the
/// sentinel-terminated `table` (an entry whose `upper[0]` is 0 ends it).
/// `glyph_length` is the glyph count of the string, as the owner computes it.
pub fn toUpperOrLowerCase(ptr: [*]u8, to_upper: bool, glyph_length: i16, table: []const abi.UpperLower) void {
    var pos: i16 = 0;

    var i: i16 = 1;
    while (i <= glyph_length) : (i += 1) {
        const glyph: u16 = glyphCode(ptr + @as(usize, @intCast(pos)));
        var j: usize = 0;
        while (j < table.len and table[j].upper[0] != 0) {
            const currentGlyph: u16 = if (to_upper)
                glyphCode(&table[j].lower)
            else
                glyphCode(&table[j].upper);
            if (glyph == currentGlyph) {
                const newGlyph: u16 = if (to_upper)
                    glyphCode(&table[j].upper)
                else
                    glyphCode(&table[j].lower);
                if ((glyph & 0x8000) != 0) {
                    ptr[@intCast(pos)] = @truncate(newGlyph >> 8);
                    ptr[@intCast(pos + 1)] = @truncate(newGlyph & 0xff);
                } else {
                    ptr[@intCast(pos)] = @truncate(newGlyph);
                }
                break;
            }
            j += 1;
        }
        pos += if ((glyph & 0x8000) != 0) 2 else 1;
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "glyphCode decodes one- and two-byte glyphs" {
    const one = [_]u8{ 'A', 0 };
    try std.testing.expectEqual(@as(u16, 'A'), glyphCode(&one));
    // High bit set on the first byte -> two-byte big-endian code.
    const two = [_]u8{ 0x81, 0x42, 0 };
    try std.testing.expectEqual(@as(u16, 0x8142), glyphCode(&two));
}

test "isSameGlyph matches one- and two-byte glyphs and rejects mismatches" {
    const s = [_]u8{ 0x81, 0x42, 'X', 0 };
    try std.testing.expect(isSameGlyph(0x8142, &s));
    try std.testing.expect(!isSameGlyph(0x8143, &s));
    // A single-byte code compares just the low byte at the position.
    try std.testing.expect(isSameGlyph('X', s[2..].ptr));
    try std.testing.expect(!isSameGlyph('Y', s[2..].ptr));
}

// A small synthetic case table: ASCII A<->a, plus a two-byte glyph pair, then
// the sentinel entry (upper[0] == 0) that terminates the scan.
const test_table = [_]abi.UpperLower{
    .{ .upper = .{ 'A', 0, 0 }, .lower = .{ 'a', 0, 0 } },
    .{ .upper = .{ 0x81, 0x41, 0 }, .lower = .{ 0x81, 0x61, 0 } },
    .{ .upper = .{ 0, 0, 0 }, .lower = .{ 0, 0, 0 } },
};

fn caseOf(src: []const u8, to_upper: bool, glyph_len: i16) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..src.len], src);
    toUpperOrLowerCase(&S.buf, to_upper, glyph_len, &test_table);
    return std.mem.sliceTo(&S.buf, 0);
}

test "single-byte glyphs convert to upper and lower case" {
    // "aXb" (3 glyphs): only 'a' is in the table.
    try std.testing.expectEqualStrings("AXb", caseOf("aXb\x00", true, 3));
    try std.testing.expectEqualStrings("aXb", caseOf("AXb\x00", false, 3));
}

test "two-byte glyphs convert in place without disturbing neighbours" {
    // 'Z', then two-byte upper 0x8141, then 'q' -> 3 glyphs. Lowercasing maps the
    // two-byte glyph 0x8141 -> 0x8161 and leaves 'Z' and 'q' untouched.
    const src = [_]u8{ 'Z', 0x81, 0x41, 'q', 0 };
    const out = caseOf(&src, false, 3);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'Z', 0x81, 0x61, 'q' }, out);
}

test "glyphs absent from the table are left unchanged" {
    try std.testing.expectEqualStrings("123", caseOf("123\x00", true, 3));
}
