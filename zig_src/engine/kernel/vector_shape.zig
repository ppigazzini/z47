//! Matrix vector-shape classification -- the pure core shared by the register
//! codec and the matrix editor.
//!
//! A real-matrix register is treated as a geometric vector when its shape is
//! 1x2/2x1 (2D) or 1x3/3x1 (3D). The shape test is a pure predicate over the row
//! and column counts; the owners add the data-type and tag reads around it. Lift
//! it here for native coverage -- the register/matrix owners are only reachable
//! through the C oracle.

const std = @import("std");

/// Whether a `rows`x`cols` matrix is a 2D vector (1x2 or 2x1).
pub fn is2dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}

/// Whether a `rows`x`cols` matrix is a 3D vector (1x3 or 3x1).
pub fn is3dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}

test "2D vectors are 1x2 or 2x1" {
    try std.testing.expect(is2dVector(1, 2));
    try std.testing.expect(is2dVector(2, 1));
    try std.testing.expect(!is2dVector(1, 3));
    try std.testing.expect(!is2dVector(2, 2));
    try std.testing.expect(!is2dVector(1, 1));
}

test "3D vectors are 1x3 or 3x1" {
    try std.testing.expect(is3dVector(1, 3));
    try std.testing.expect(is3dVector(3, 1));
    try std.testing.expect(!is3dVector(1, 2));
    try std.testing.expect(!is3dVector(3, 3));
    try std.testing.expect(!is3dVector(2, 3));
}
