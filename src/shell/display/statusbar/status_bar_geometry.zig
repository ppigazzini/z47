//! Status-bar layout coordinates -- the pure core of frontier_status_bar's
//! xDate / xShift / yShift / lowerUnderLine.
//!
//! The status bar positions the date, the shift indicator, and the lower
//! underline from the status-bar flag state. Each coordinate is pure branching
//! arithmetic over booleans and layout constants. Lift it here for native
//! coverage -- the status-bar owner draws pixels and is only reachable through
//! the C oracle.

const std = @import("std");

/// The date x-origin: 1 when time or week-of-year is shown, else 25.
pub fn xDate(sb_time: bool, sb_woy: bool) i32 {
    return if (sb_time or sb_woy) 1 else 25;
}

/// The shift-indicator x-origin.
pub fn xShift(shift_right: bool, x_shift_r: i32, x_shift_l: i32) i32 {
    return if (shift_right) x_shift_r else x_shift_l;
}

/// The shift-indicator y-origin.
pub fn yShift(sb_date: bool, sb_time: bool, sb_woy: bool, sbar_shift: bool, y_shift_lo: i32) i32 {
    if ((!sb_date or !(sb_time or sb_woy)) and !sbar_shift) {
        return 0;
    }
    return if (sbar_shift) 0 else y_shift_lo;
}

/// The lower-underline height: 0 in a browser mode, else 2.
pub fn lowerUnderLine(is_browser: bool) i32 {
    return if (is_browser) 0 else 2;
}

test "xDate depends on time/week-of-year" {
    try std.testing.expectEqual(@as(i32, 1), xDate(true, false));
    try std.testing.expectEqual(@as(i32, 1), xDate(false, true));
    try std.testing.expectEqual(@as(i32, 25), xDate(false, false));
}

test "xShift picks the right/left origin" {
    try std.testing.expectEqual(@as(i32, 7), xShift(true, 7, 3));
    try std.testing.expectEqual(@as(i32, 3), xShift(false, 7, 3));
}

test "yShift branches on the date/time/shift flags" {
    // date shown with time, no shift -> lower origin.
    try std.testing.expectEqual(@as(i32, 10), yShift(true, true, false, false, 10));
    // shift active -> 0.
    try std.testing.expectEqual(@as(i32, 0), yShift(true, true, false, true, 10));
    // no date -> early 0.
    try std.testing.expectEqual(@as(i32, 0), yShift(false, true, false, false, 10));
}

test "lowerUnderLine is 0 in a browser" {
    try std.testing.expectEqual(@as(i32, 0), lowerUnderLine(true));
    try std.testing.expectEqual(@as(i32, 2), lowerUnderLine(false));
}
