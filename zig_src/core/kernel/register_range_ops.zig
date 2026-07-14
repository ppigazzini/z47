//! Register-range command geometry -- the pure core of stack_register_commands'
//! regSwap / regCopy.
//!
//! Swapping rejects overlapping source and destination ranges; copying picks an
//! iteration direction that avoids clobbering the overlap. Both are pure integer
//! interval arithmetic over the start indices and length. Lift them here for
//! native coverage -- the register-command owner reads the ranges from globals
//! and performs the descriptor moves.

const std = @import("std");

/// Whether the ranges [s, s+n) and [d, d+n) overlap.
pub fn rangesOverlap(s: u16, d: u16, n: u16) bool {
    return d < s + n and s < d + n;
}

/// The safe copy direction: ascending indices when the source is above the
/// destination, descending when below, and none when they coincide.
pub const CopyDirection = enum { none, ascending, descending };

pub fn copyDirection(s: u16, d: u16) CopyDirection {
    if (s > d) return .ascending;
    if (s < d) return .descending;
    return .none;
}

test "rangesOverlap detects overlapping and disjoint ranges" {
    try std.testing.expect(!rangesOverlap(0, 5, 3)); // [0,3) and [5,8)
    try std.testing.expect(rangesOverlap(0, 2, 3)); // [0,3) and [2,5)
    try std.testing.expect(rangesOverlap(2, 4, 3)); // [2,5) and [4,7)
    try std.testing.expect(!rangesOverlap(5, 0, 3)); // [5,8) and [0,3)
    try std.testing.expect(rangesOverlap(3, 3, 1)); // identical
}

test "copyDirection avoids clobbering the overlap" {
    try std.testing.expectEqual(CopyDirection.ascending, copyDirection(5, 2));
    try std.testing.expectEqual(CopyDirection.descending, copyDirection(2, 5));
    try std.testing.expectEqual(CopyDirection.none, copyDirection(3, 3));
}
