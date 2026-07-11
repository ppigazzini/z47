//! Matrix-input small helpers -- the pure cores of math_matrix_mim_commands'
//! truncToU16 and numEl.
//!
//! truncToU16 truncates a signed value to its low 16 bits (via a bit-cast);
//! numEl is a matrix's element count (rows * cols). Both are pure integer
//! arithmetic. Lift them here for native coverage -- the matrix-input owner
//! otherwise routes through decimal/matrix runtimes.

const std = @import("std");

/// Truncate a signed 32-bit value to its low 16 bits.
pub fn truncToU16(v: i32) u16 {
    return @truncate(@as(u32, @bitCast(v)));
}

/// A matrix's element count.
pub fn numEl(rows: u16, cols: u16) usize {
    return @as(usize, rows) * cols;
}

test "truncToU16 keeps the low 16 bits" {
    try std.testing.expectEqual(@as(u16, 0x2345), truncToU16(0x12345));
    try std.testing.expectEqual(@as(u16, 0xffff), truncToU16(-1));
    try std.testing.expectEqual(@as(u16, 0), truncToU16(0x10000));
}

test "numEl multiplies rows by columns" {
    try std.testing.expectEqual(@as(usize, 12), numEl(3, 4));
    try std.testing.expectEqual(@as(usize, 0), numEl(0, 5));
}
