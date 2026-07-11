//! Radix-mark character selection -- the pure core of keyboard_state_runtime's
//! radix34MarkChar.
//!
//! The RADIX34_MARK macros pick the display radix mark from the first two bytes
//! of the gap-radix item's softmenu name: a leading comma (or the wide-comma
//! glyph "\xa7\x88") means the radix is shown as a comma, otherwise a dot. It is
//! a pure two-byte test. Lift it here for native coverage -- the keyboard owner
//! resolves the name bytes from the item table and delegates.

const std = @import("std");

/// The radix mark (',' or '.') for a gap-radix softmenu name beginning with
/// bytes `b0`, `b1`.
pub fn radixMarkFromName(b0: u8, b1: u8) u8 {
    return if (b0 == ',' or (b0 == 0xa7 and b1 == 0x88)) ',' else '.';
}

test "comma and the wide-comma glyph select a comma mark" {
    try std.testing.expectEqual(@as(u8, ','), radixMarkFromName(',', 0));
    try std.testing.expectEqual(@as(u8, ','), radixMarkFromName(0xa7, 0x88));
}

test "anything else selects a dot mark" {
    try std.testing.expectEqual(@as(u8, '.'), radixMarkFromName('.', 0));
    try std.testing.expectEqual(@as(u8, '.'), radixMarkFromName(0xa7, 0x00)); // lone wide-comma lead byte
    try std.testing.expectEqual(@as(u8, '.'), radixMarkFromName(0, 0));
}
