//! Caps-lock strip for command dispatch -- the pure core of gtk_gui_events'
//! stripCapsLockForCommand.
//!
//! For command-key dispatch an alphabetic keyval is normalized to upper or lower
//! case depending on the active shift state (bit 16 of the command-shift word).
//! It is pure bit arithmetic. Lift it here for native coverage -- the GTK events
//! owner otherwise reads the module shift global.

const std = @import("std");

/// Normalize the case of an alphabetic `keyval` per the `command_shift` state;
/// non-alphabetic keyvals pass through unchanged.
pub fn stripCapsLockForCommand(keyval: u32, command_shift: u32) u32 {
    const is_alpha = (keyval >= 'A' and keyval <= 'Z') or (keyval >= 'a' and keyval <= 'z');
    if (!is_alpha) return keyval;
    return (keyval & 0xFFFFDF) + (0x20 & ~(command_shift >> (16 - 5)));
}

test "non-alphabetic keyvals pass through" {
    try std.testing.expectEqual(@as(u32, '1'), stripCapsLockForCommand('1', 0));
    try std.testing.expectEqual(@as(u32, ' '), stripCapsLockForCommand(' ', 0x10000));
}

test "no shift lowercases, shift uppercases" {
    try std.testing.expectEqual(@as(u32, 'a'), stripCapsLockForCommand('A', 0));
    try std.testing.expectEqual(@as(u32, 'a'), stripCapsLockForCommand('a', 0));
    try std.testing.expectEqual(@as(u32, 'A'), stripCapsLockForCommand('a', 0x10000));
    try std.testing.expectEqual(@as(u32, 'A'), stripCapsLockForCommand('A', 0x10000));
}
