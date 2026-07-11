//! Base-number subscript encoder -- the pure core of frontier_display's
//! addBaseNumber.
//!
//! A numeric base is appended to a display string as a subscript: a single
//! subscript glyph offset from the base-2 glyph for bases up to 16, otherwise two
//! subscript-digit glyphs (base/10 and base%10) offset from the subscript-0
//! glyph. It is a pure append + byte offset over the string and the two glyph
//! constants. Lift it here for native coverage. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");

// Append the NUL-terminated `glyph`; return the index of its last byte.
fn appendGlyphLastIndex(dest: [*]u8, glyph: [*]const u8) usize {
    var len: usize = 0;
    while (dest[len] != 0) : (len += 1) {}
    var i: usize = 0;
    while (glyph[i] != 0) : (i += 1) {
        dest[len + i] = glyph[i];
    }
    dest[len + i] = 0;
    return len + i - 1;
}

/// Append `base` as a subscript to `dest`, using the base-2 and subscript-0
/// glyphs.
pub fn addBaseNumber(dest: [*]u8, base: i16, base2_glyph: [*]const u8, sub0_glyph: [*]const u8) void {
    if (base <= 16) {
        const last = appendGlyphLastIndex(dest, base2_glyph);
        dest[last] +%= @intCast(base - 2);
    } else {
        var last = appendGlyphLastIndex(dest, sub0_glyph);
        dest[last] +%= @intCast(@divTrunc(base, 10));
        last = appendGlyphLastIndex(dest, sub0_glyph);
        dest[last] +%= @intCast(@rem(base, 10));
    }
}

test "a small base appends one offset subscript glyph" {
    var buf = [_]u8{ 'X', 0, 0, 0, 0, 0 };
    addBaseNumber(&buf, 10, "\x01\x60", "\x02\x80");
    // base-2 glyph {0x01,0x60}, last byte += (10-2) = 0x68.
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'X', 0x01, 0x68 }, std.mem.sliceTo(&buf, 0));
}

test "a large base appends two subscript digits" {
    var buf = [_]u8{ 'X', 0, 0, 0, 0, 0 };
    addBaseNumber(&buf, 20, "\x01\x60", "\x02\x80");
    // sub0 {0x02,0x80}: first += 20/10 = 2 -> 0x82, second += 20%10 = 0 -> 0x80.
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'X', 0x02, 0x82, 0x02, 0x80 }, std.mem.sliceTo(&buf, 0));
}
