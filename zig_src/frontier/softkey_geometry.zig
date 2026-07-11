//! Softkey rectangle geometry -- the pure core of frontier_softmenus'
//! initSoftkeyCoordinates.
//!
//! A softkey at grid column x (0..5) and row y (0..2) occupies [x1,x2) x [y1,y2):
//! the x edges come from the KEY_X column table (x and x+1), the y edges from the
//! screen baseline stepped up by the softmenu row height. Both are pure,
//! bounds-checked lookups returning null out of range; the owner turns null into
//! its bug-screen error. Lift them here for native coverage. This module uses Zig
//! many-item pointers rather than C pointers, so it stays out of the idiom ceiling.

const std = @import("std");

/// The [x1, x2] edges for grid column `x_softkey` (0..5) from the KEY_X column
/// table (needs 7 entries), or null when out of range.
pub fn softkeyXBounds(x_softkey: i16, key_x: [*]const c_int) ?[2]i16 {
    if (x_softkey < 0 or x_softkey > 5) return null;
    return .{
        @intCast(key_x[@intCast(x_softkey)]),
        @intCast(key_x[@intCast(x_softkey + 1)]),
    };
}

/// The [y1, y2] edges for grid row `y_softkey` (0..2): the row is `y_softkey`
/// steps of `height` up from `baseline`. Null when out of range.
pub fn softkeyYBounds(y_softkey: i16, height: i16, baseline: i16) ?[2]i16 {
    if (y_softkey < 0 or y_softkey > 2) return null;
    const y1 = baseline - height * y_softkey;
    return .{ y1, y1 + height };
}

test "x bounds read adjacent KEY_X entries and reject out of range" {
    const key_x = [_]c_int{ 0, 43, 86, 129, 172, 215, 258 };
    try std.testing.expectEqual(@as(?[2]i16, .{ 0, 43 }), softkeyXBounds(0, &key_x));
    try std.testing.expectEqual(@as(?[2]i16, .{ 215, 258 }), softkeyXBounds(5, &key_x));
    try std.testing.expectEqual(@as(?[2]i16, null), softkeyXBounds(6, &key_x));
    try std.testing.expectEqual(@as(?[2]i16, null), softkeyXBounds(-1, &key_x));
}

test "y bounds step up from the baseline and reject out of range" {
    // height 23, baseline 217.
    try std.testing.expectEqual(@as(?[2]i16, .{ 217, 240 }), softkeyYBounds(0, 23, 217));
    try std.testing.expectEqual(@as(?[2]i16, .{ 194, 217 }), softkeyYBounds(1, 23, 217));
    try std.testing.expectEqual(@as(?[2]i16, .{ 171, 194 }), softkeyYBounds(2, 23, 217));
    try std.testing.expectEqual(@as(?[2]i16, null), softkeyYBounds(3, 23, 217));
}
