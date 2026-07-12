//! real34 sign-byte operations -- the pure core of stack_result's
//! real34IsNegative / real34SetPositiveSign.
//!
//! A decimal128 (real34) stores its sign in the high bit of its top byte. Testing
//! and clearing that bit are pure byte operations on the 16-byte value -- no
//! decimal arithmetic is involved. Lift them here for native coverage.

const std = @import("std");
const abi = @import("abi");

/// Whether the real34's sign bit (top byte, bit 7) is set.
pub fn isNegative(value: *const abi.Real34) bool {
    return (value.bytes[15] & 0x80) != 0;
}

/// Clear the real34's sign bit, making it non-negative.
pub fn setPositiveSign(value: *abi.Real34) void {
    value.bytes[15] &= 0x7f;
}

test "isNegative reads the top-byte sign bit" {
    var v = abi.Real34{ .bytes = std.mem.zeroes([16]u8) };
    try std.testing.expect(!isNegative(&v));
    v.bytes[15] = 0x80;
    try std.testing.expect(isNegative(&v));
    v.bytes[15] = 0xa2; // sign bit plus other bits
    try std.testing.expect(isNegative(&v));
}

test "setPositiveSign clears only the sign bit" {
    var v = abi.Real34{ .bytes = std.mem.zeroes([16]u8) };
    v.bytes[15] = 0xa2;
    setPositiveSign(&v);
    try std.testing.expectEqual(@as(u8, 0x22), v.bytes[15]);
    try std.testing.expect(!isNegative(&v));
}
