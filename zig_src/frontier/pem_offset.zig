//! Program-editor left-offset logic -- the pure core of frontier_manage's
//! pemLeftOffset and its yShift helper.
//!
//! The PEM display shifts its left column right by 16 px to make room for the
//! f/g shift annunciators, but only on the register-T line, only when the
//! status bar is left-shifted, and only when the status-bar Y-shift is non-zero.
//! The Y-shift itself is a compound predicate over the date/time/week-of-year and
//! shift status-bar flags. Both are pure boolean/integer logic over flags passed
//! as parameters -- lift them here for native coverage; the PEM owner (only
//! reachable interactively) resolves the flags and delegates.

const std = @import("std");

/// The status-bar Y-shift: 0 unless the date/time/WoY annunciators are shown
/// without a shift, in which case the low shift `y_shift_lo` applies.
pub fn yShift(sb_date: bool, sb_time: bool, sb_woy: bool, sbar_shift: bool, y_shift_lo: i32) i32 {
    if ((!sb_date or !(sb_time or sb_woy)) and !sbar_shift) {
        return 0;
    }
    return if (sbar_shift) 0 else y_shift_lo;
}

/// The PEM left offset (0 or 16 px): 16 only on the register-T line, with a
/// left-shifted status bar, and a non-zero Y-shift.
pub fn pemLeftOffset(y: i32, y_pos_t_line: i32, x_shift_right: bool, y_shift_zero: bool) i32 {
    if (y > y_pos_t_line or x_shift_right or y_shift_zero) {
        return 0;
    }
    return 16;
}

test "yShift is the low shift only when annunciators show without a shift" {
    // y_shift_lo = 24. The if-branch returns 0 when (!date || !(time||woy)) && !shift.
    try std.testing.expectEqual(@as(i32, 24), yShift(true, true, true, false, 24)); // date & (time||woy) shown, not shifted -> low shift
    try std.testing.expectEqual(@as(i32, 0), yShift(false, false, false, false, 24)); // date off -> if-branch -> 0
    try std.testing.expectEqual(@as(i32, 0), yShift(true, false, false, false, 24)); // time & woy off -> if-branch -> 0
    try std.testing.expectEqual(@as(i32, 0), yShift(true, true, true, true, 24)); // shifted -> 0
}

test "pemLeftOffset is 16 only in the qualifying case" {
    // y_pos_t_line = 24.
    try std.testing.expectEqual(@as(i32, 16), pemLeftOffset(24, 24, false, false));
    try std.testing.expectEqual(@as(i32, 0), pemLeftOffset(45, 24, false, false)); // past the T line
    try std.testing.expectEqual(@as(i32, 0), pemLeftOffset(24, 24, true, false)); // right-shifted
    try std.testing.expectEqual(@as(i32, 0), pemLeftOffset(24, 24, false, true)); // zero y-shift
}
