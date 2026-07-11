//! Status-bar update-flag clear -- the pure core of keyboard_state_runtime's
//! clearStatusbarUpdateFlags.
//!
//! Clearing the manual and one-time status-bar update bits from the screen-update
//! mode is a pure bit operation. Lift it here for native coverage.

const std = @import("std");

/// Clear the two status-bar update bits from `mode`.
pub fn clearStatusbarUpdateFlags(mode: u8, manual_bit: u8, skip_bit: u8) u8 {
    return mode & ~(manual_bit | skip_bit);
}

test "the manual and skip bits are cleared, others kept" {
    // manual = 0x02, skip = 0x04.
    try std.testing.expectEqual(@as(u8, 0xf9), clearStatusbarUpdateFlags(0xff, 0x02, 0x04));
    try std.testing.expectEqual(@as(u8, 0x01), clearStatusbarUpdateFlags(0x07, 0x02, 0x04));
    try std.testing.expectEqual(@as(u8, 0x80), clearStatusbarUpdateFlags(0x80, 0x02, 0x04));
}
