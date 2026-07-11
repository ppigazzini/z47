//! Two-byte big-endian decode -- the pure core of frontier_screen's str2dec.
//!
//! A two-byte value stored high-byte-first is decoded as ch[1] + (ch[0] << 8).
//! It is a pure byte operation. Lift it here for native coverage -- the screen
//! owner is only reachable through the C oracle. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");

/// Decode two big-endian bytes at `ch` into a u16.
pub fn str2dec(ch: [*]const u8) u16 {
    return @as(u16, ch[1]) + (@as(u16, ch[0]) << 8);
}

test "big-endian byte pairs decode correctly" {
    try std.testing.expectEqual(@as(u16, 0x1234), str2dec(&[_]u8{ 0x12, 0x34 }));
    try std.testing.expectEqual(@as(u16, 1), str2dec(&[_]u8{ 0, 1 }));
    try std.testing.expectEqual(@as(u16, 0x0100), str2dec(&[_]u8{ 1, 0 }));
    try std.testing.expectEqual(@as(u16, 0xffff), str2dec(&[_]u8{ 0xff, 0xff }));
}
