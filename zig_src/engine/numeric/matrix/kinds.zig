//! Matrix operand kinds and vector-size validity -- the pure core of
//! math_matrix_vector_validation.
//!
//! Matrix arithmetic first classifies the two operands (real/complex matrix or
//! not) and validates vector operands by size: a cross product needs two 1..3-D
//! vectors, a dot product needs two equal non-empty sizes. The classification
//! algebra and the size predicates are pure; the owner reads the operand types
//! and vector sizes from the register/matrix runtime at the edge.

const std = @import("std");

/// Which of the two operands are real/complex matrices.
pub const MatrixOperandKinds = struct {
    x_is_real_matrix: bool,
    x_is_complex_matrix: bool,
    y_is_real_matrix: bool,
    y_is_complex_matrix: bool,

    pub fn hasAnyMatrix(self: MatrixOperandKinds) bool {
        return self.x_is_real_matrix or self.x_is_complex_matrix or self.y_is_real_matrix or self.y_is_complex_matrix;
    }

    pub fn areBothMatrices(self: MatrixOperandKinds) bool {
        return (self.x_is_real_matrix or self.x_is_complex_matrix) and (self.y_is_real_matrix or self.y_is_complex_matrix);
    }
};

/// Cross-product vector sizes are valid when both are non-empty 1..3-D.
pub fn crossSizesValid(x_size: u32, y_size: u32) bool {
    return x_size != 0 and y_size != 0 and x_size <= 3 and y_size <= 3;
}

/// Dot-product vector sizes are valid when both are non-empty and equal.
pub fn dotSizesValid(x_size: u32, y_size: u32) bool {
    return x_size != 0 and y_size != 0 and x_size == y_size;
}

test "hasAnyMatrix / areBothMatrices" {
    const none = MatrixOperandKinds{ .x_is_real_matrix = false, .x_is_complex_matrix = false, .y_is_real_matrix = false, .y_is_complex_matrix = false };
    try std.testing.expect(!none.hasAnyMatrix());
    try std.testing.expect(!none.areBothMatrices());

    const one = MatrixOperandKinds{ .x_is_real_matrix = true, .x_is_complex_matrix = false, .y_is_real_matrix = false, .y_is_complex_matrix = false };
    try std.testing.expect(one.hasAnyMatrix());
    try std.testing.expect(!one.areBothMatrices());

    const both = MatrixOperandKinds{ .x_is_real_matrix = true, .x_is_complex_matrix = false, .y_is_real_matrix = false, .y_is_complex_matrix = true };
    try std.testing.expect(both.hasAnyMatrix());
    try std.testing.expect(both.areBothMatrices());
}

test "crossSizesValid accepts 1..3-D non-empty vectors" {
    try std.testing.expect(crossSizesValid(3, 2));
    try std.testing.expect(!crossSizesValid(0, 2));
    try std.testing.expect(!crossSizesValid(3, 4));
}

test "dotSizesValid needs equal non-empty sizes" {
    try std.testing.expect(dotSizesValid(4, 4));
    try std.testing.expect(!dotSizesValid(3, 4));
    try std.testing.expect(!dotSizesValid(0, 0));
}
