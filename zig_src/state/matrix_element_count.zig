//! Matrix element count -- the pure core of stack_result's
//! realMatrixElementCount / complexMatrixElementCount.
//!
//! A matrix register's element count is (total_blocks - header_blocks) /
//! element_blocks. It is pure integer arithmetic over block counts. Lift it here
//! for native coverage -- the stack-result owner reads the sizes from the
//! register runtime at the edge.

const std = @import("std");

/// The number of elements in a matrix payload of `total_blocks` blocks with a
/// `header_blocks` header and `element_blocks` per element.
pub fn elementCount(total_blocks: usize, header_blocks: usize, element_blocks: usize) usize {
    return (total_blocks - header_blocks) / element_blocks;
}

test "element count divides the payload after the header" {
    // 1-block header, 4 blocks per real34 element.
    try std.testing.expectEqual(@as(usize, 4), elementCount(17, 1, 4)); // (17-1)/4
    try std.testing.expectEqual(@as(usize, 0), elementCount(1, 1, 4)); // header only
    // 8 blocks per complex34 element.
    try std.testing.expectEqual(@as(usize, 3), elementCount(25, 1, 8)); // (25-1)/8
}
