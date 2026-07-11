//! GTK integer helpers -- the pure core of gtk_gui_label's absItem.
//!
//! absItem computes the absolute value of an i16 in i32 (matching C's integer
//! promotion, so i16 MIN cannot trap). It is pure arithmetic. Lift it here for
//! native coverage -- the GTK label owner otherwise pulls in the item table.

const std = @import("std");

/// Absolute value of an i16, computed in i32.
pub fn absItem(x: i16) i16 {
    return @intCast(@max(@as(i32, x), -@as(i32, x)));
}

test "absItem returns the magnitude" {
    try std.testing.expectEqual(@as(i16, 5), absItem(5));
    try std.testing.expectEqual(@as(i16, 5), absItem(-5));
    try std.testing.expectEqual(@as(i16, 0), absItem(0));
    try std.testing.expectEqual(@as(i16, 100), absItem(-100));
}
