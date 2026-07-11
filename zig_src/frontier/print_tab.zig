//! Printer tab-advance count -- the pure core of frontier_print's printTabImpl.
//!
//! Advancing the printer to column `col` from the current `printer_column` (when
//! already to its left) emits `(col - printer_column) mod 7` blank columns, except
//! that a tab from the very start of a line to a column past the first tab stop
//! emits a full stop of 7. It is pure modular arithmetic with that one edge case
//! -- lift it here for native coverage; the print owner emits the blanks.

const std = @import("std");

/// The number of blank columns to advance from `printer_column` to reach `col`.
/// Callers use it only when `printer_column < col`.
pub fn tabAdvanceCount(printer_column: u16, col: u16) u16 {
    var i: u16 = (col - printer_column) % 7;
    if (i == 0 and printer_column == 0 and col > 6) {
        i = 7;
    }
    return i;
}

test "advance is the distance modulo the 7-column tab stop" {
    try std.testing.expectEqual(@as(u16, 3), tabAdvanceCount(0, 3));
    try std.testing.expectEqual(@as(u16, 2), tabAdvanceCount(5, 14)); // 9 % 7
    try std.testing.expectEqual(@as(u16, 0), tabAdvanceCount(7, 14)); // exact multiple, not from col 0
}

test "a full tab from the start of the line past the first stop emits 7" {
    try std.testing.expectEqual(@as(u16, 7), tabAdvanceCount(0, 7));
    try std.testing.expectEqual(@as(u16, 7), tabAdvanceCount(0, 14));
    try std.testing.expectEqual(@as(u16, 6), tabAdvanceCount(0, 6)); // col not past the first stop
}
