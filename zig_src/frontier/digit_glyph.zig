//! Single decimal-digit glyph -- the pure core of frontier_softmenus'
//! _add_digitglyph.
//!
//! A decimal digit 1..9 is rendered by copying the "0" glyph into a buffer and
//! adding the digit to its first byte (0 leaves the plain zero glyph). It is pure
//! over the destination and the digit; the owner supplies the "0" glyph
//! constant. Lift it here for native coverage -- the softmenu owner is only
//! reachable through the C oracle. This module uses Zig many-item pointers rather
//! than C pointers, so it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Write the glyph for digit `xx` (1..9, else the zero glyph) into `dest`,
/// copying `zero_glyph` and offsetting its first byte.
pub fn addDigitGlyph(dest: [*]u8, xx: i16, zero_glyph: [*]const u8) void {
    var i: usize = 0;
    while (zero_glyph[i] != 0) : (i += 1) {
        dest[i] = zero_glyph[i];
    }
    dest[i] = 0;
    if (xx >= 1 and xx <= 9) {
        dest[0] +%= @intCast(xx);
    }
}

test "digit 0 leaves the zero glyph unchanged" {
    var d: [8]u8 = undefined;
    addDigitGlyph(&d, 0, "0");
    try std.testing.expectEqualStrings("0", std.mem.sliceTo(&d, 0));
}

test "digits 1..9 offset the first byte" {
    var d: [8]u8 = undefined;
    addDigitGlyph(&d, 5, "0");
    try std.testing.expectEqualStrings("5", std.mem.sliceTo(&d, 0));
    addDigitGlyph(&d, 9, "0");
    try std.testing.expectEqualStrings("9", std.mem.sliceTo(&d, 0));
}

test "out-of-range digits leave the zero glyph" {
    var d: [8]u8 = undefined;
    addDigitGlyph(&d, 10, "0");
    try std.testing.expectEqualStrings("0", std.mem.sliceTo(&d, 0));
}

test "a two-byte zero glyph is copied whole and offset on its first byte" {
    var d: [8]u8 = undefined;
    addDigitGlyph(&d, 3, "\x30\xa0");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x33, 0xa0 }, std.mem.sliceTo(&d, 0));
}
