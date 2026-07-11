//! Matrix linear-index decomposition -- the pure core shared by
//! frontier_recall's vector-element helpers.
//!
//! A 1-based linear element index into a row-major matrix decomposes to a 1-based
//! (row, col): row = (ix-1)/cols + 1, col = (ix-1)%cols + 1. It is pure integer
//! arithmetic. Lift it here for native coverage -- the recall owner is only
//! reachable through the C oracle.

const std = @import("std");

pub const RowCol = struct { row: i32, col: i32 };

/// Decompose a 1-based linear index `ix` over `cols` columns into 1-based
/// (row, col).
pub fn linearToRowCol(ix: i32, cols: i32) RowCol {
    return .{
        .row = @divTrunc(ix - 1, cols) + 1,
        .col = @rem(ix - 1, cols) + 1,
    };
}

test "the first element is row 1 col 1" {
    try std.testing.expectEqual(RowCol{ .row = 1, .col = 1 }, linearToRowCol(1, 5));
}

test "a full first row then wrap to the next" {
    try std.testing.expectEqual(RowCol{ .row = 1, .col = 5 }, linearToRowCol(5, 5));
    try std.testing.expectEqual(RowCol{ .row = 2, .col = 1 }, linearToRowCol(6, 5));
}

test "the last element of a 5x5 matrix" {
    try std.testing.expectEqual(RowCol{ .row = 5, .col = 5 }, linearToRowCol(25, 5));
}

test "a single-column matrix advances the row each step" {
    try std.testing.expectEqual(RowCol{ .row = 3, .col = 1 }, linearToRowCol(3, 1));
}
