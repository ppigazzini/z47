//! Small integer-math helpers -- the pure cores of frontier_softmenus'
//! TO_BLOCKS / cmod / modulo / maxI / minI / cmodNonNeg.
//!
//! These are the block-rounding and modulo/min/max primitives the softmenu layout
//! math uses. All are pure scalar arithmetic with no globals. Lift them here for
//! native coverage -- the softmenu owner is only reachable through the C oracle.

const std = @import("std");

/// Bytes-to-blocks rounding: (n + 3) >> 2 (4 bytes per block).
pub fn toBlocks(n: i32) u16 {
    return @intCast((n + 3) >> 2);
}

/// Floored modulo: always in [0, |d|).
pub fn cmod(n: i32, d: i32) i32 {
    return @mod(@rem(n, d) + d, d);
}

/// Positive-divisor modulo: valid for d > 0, result in [0, d).
pub fn modulo(n: i32, d: i32) i32 {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}

pub fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}

pub fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

/// Plain truncating remainder.
pub fn cmodNonNeg(n: i32, d: i32) i32 {
    return @rem(n, d);
}

test "toBlocks rounds up to 4-byte blocks" {
    try std.testing.expectEqual(@as(u16, 0), toBlocks(0));
    try std.testing.expectEqual(@as(u16, 1), toBlocks(1));
    try std.testing.expectEqual(@as(u16, 1), toBlocks(4));
    try std.testing.expectEqual(@as(u16, 2), toBlocks(5));
}

test "cmod and modulo give non-negative results for positive d" {
    try std.testing.expectEqual(@as(i32, 2), cmod(-1, 3));
    try std.testing.expectEqual(@as(i32, 1), cmod(7, 3));
    try std.testing.expectEqual(@as(i32, 2), modulo(-1, 3));
    try std.testing.expectEqual(@as(i32, 1), modulo(7, 3));
}

test "maxI / minI / cmodNonNeg" {
    try std.testing.expectEqual(@as(i32, 5), maxI(3, 5));
    try std.testing.expectEqual(@as(i32, 3), minI(3, 5));
    try std.testing.expectEqual(@as(i32, -1), cmodNonNeg(-7, 3));
}
