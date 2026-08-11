//! Type-report encoders -- pure cores of math_get_type's matrixVectorShape and
//! angleCode.
//!
//! The TYPE report encodes a register's shape (row/column vector or neither) and
//! its angular mode into small integer codes. Both are pure integer arithmetic
//! over plain values. Lift them here for native coverage.

const std = @import("std");

/// The vector-shape code: 2 for a column vector (rows>1, cols==1), 1 for a row
/// vector (rows==1, cols>1), else 0.
pub fn matrixVectorShape(rows: u16, cols: u16) i32 {
    if (rows > 1 and cols == 1) return 2;
    if (rows == 1 and cols > 1) return 1;
    return 0;
}

/// The angle code: 5 minus the low 3 bits of the angular mode. Signed, as the
/// C `int angle` is: the tag's low three bits reach 6 (amSecond) and 7 (TM_HMS),
/// for which the code is -1 and -2 and folds negatively into the report value.
pub fn angleCode(angular_mode: i32) i32 {
    return 5 - (angular_mode & 0x07);
}

test "matrixVectorShape classifies row/column vectors" {
    try std.testing.expectEqual(@as(i32, 2), matrixVectorShape(3, 1));
    try std.testing.expectEqual(@as(i32, 1), matrixVectorShape(1, 3));
    try std.testing.expectEqual(@as(i32, 0), matrixVectorShape(2, 2));
    try std.testing.expectEqual(@as(i32, 0), matrixVectorShape(1, 1));
}

test "angleCode inverts the low three mode bits" {
    try std.testing.expectEqual(@as(i32, 5), angleCode(0));
    try std.testing.expectEqual(@as(i32, 3), angleCode(2));
    try std.testing.expectEqual(@as(i32, 0), angleCode(5));
    try std.testing.expectEqual(@as(i32, -1), angleCode(6));
    try std.testing.expectEqual(@as(i32, -2), angleCode(7));
}
