//! Byte bit-reversal -- the pure core of frontier_print's reverse.
//!
//! The IR printer emits each glyph column with its bits in reverse order; the
//! reversal is the classic nibble/pair/bit swap-mask trick over a u8. It is pure
//! and has no native coverage (the print owner is only reachable through the C
//! oracle). The owner keeps a thin reverse wrapper.

const std = @import("std");

/// Reverse the bit order of a byte (bit 0 <-> bit 7, and so on).
pub fn reverse(b_in: u8) u8 {
    var b = b_in;
    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
    return b;
}

test "reverse mirrors the bit order" {
    try std.testing.expectEqual(@as(u8, 0x00), reverse(0x00));
    try std.testing.expectEqual(@as(u8, 0xFF), reverse(0xFF));
    try std.testing.expectEqual(@as(u8, 0x80), reverse(0x01));
    try std.testing.expectEqual(@as(u8, 0x01), reverse(0x80));
    try std.testing.expectEqual(@as(u8, 0x0F), reverse(0xF0));
    try std.testing.expectEqual(@as(u8, 0xAA), reverse(0x55));
}

test "reverse is its own inverse" {
    var v: u16 = 0;
    while (v < 256) : (v += 1) {
        const b: u8 = @intCast(v);
        try std.testing.expectEqual(b, reverse(reverse(b)));
    }
}
