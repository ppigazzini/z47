//! Digit-group gap insertion -- the pure core of frontier_bufferize's
//! insertGapIP / insertGapFP.
//!
//! While formatting a number into the display buffer, a group-separator token is
//! written at each group boundary: on the integer side every groupwidth digits
//! from the right, on the fractional side every groupwidth digits from the left.
//! The decision (disabled, too few digits, last digit, or a boundary hit) and the
//! 1- or 2-byte token write are pure over plain values plus a destination; the
//! owner resolves the widths, the enabled flags, and whether the separator is a
//! single-byte one. Lift it here for native coverage -- the bufferize owner is
//! only reachable through the C oracle. This module uses Zig many-item pointers
//! rather than C pointers.

const std = @import("std");

fn writeToken(dest: [*]u8, token: u8, sep_single_byte: bool) i16 {
    if (!sep_single_byte) {
        dest[0] = token;
        dest[1] = 1;
        dest[2] = 0;
        return 2;
    }
    dest[0] = token;
    dest[1] = 0;
    return 1;
}

/// Integer-side gap: a boundary falls every `groupwidth` digits counted from the
/// right (numDigits - nth). Writes token 0xab and returns its byte length, or 0.
pub fn insertGapIP(dest: [*]u8, num_digits: i16, nth: i16, groupwidth: i16, disabled: bool, sep_single_byte: bool) i16 {
    if (disabled) return 0;
    if (num_digits <= groupwidth) return 0;
    if (nth + 1 == num_digits) return 0;
    if (@rem(num_digits - nth, groupwidth) == 1 or groupwidth == 1) {
        return writeToken(dest, 0xab, sep_single_byte);
    }
    return 0;
}

/// Fractional-side gap: a boundary falls every `groupwidth` digits counted from
/// the left (nth). Writes token 0xbb and returns its byte length, or 0.
pub fn insertGapFP(dest: [*]u8, num_digits: i16, nth: i16, groupwidth: i16, disabled: bool, sep_single_byte: bool) i16 {
    if (disabled) return 0;
    if (num_digits <= groupwidth) return 0;
    if (nth + 1 == num_digits) return 0;
    if (@rem(nth, groupwidth) == groupwidth - 1) {
        return writeToken(dest, 0xbb, sep_single_byte);
    }
    return 0;
}

test "insertGapIP suppresses the gap when disabled, short, or at the last digit" {
    var d: [4]u8 = undefined;
    try std.testing.expectEqual(@as(i16, 0), insertGapIP(&d, 6, 2, 3, true, true));
    try std.testing.expectEqual(@as(i16, 0), insertGapIP(&d, 3, 0, 3, false, true)); // num <= width
    try std.testing.expectEqual(@as(i16, 0), insertGapIP(&d, 5, 4, 3, false, true)); // last digit
}

test "insertGapIP writes the token at an integer-side boundary" {
    var d: [4]u8 = undefined;
    // numDigits 6, nth 2 -> (6-2) % 3 == 1: boundary. Single-byte separator.
    try std.testing.expectEqual(@as(i16, 1), insertGapIP(&d, 6, 2, 3, false, true));
    try std.testing.expectEqual(@as(u8, 0xab), d[0]);
    try std.testing.expectEqual(@as(u8, 0), d[1]);
    // Two-byte separator writes token + 0x01.
    try std.testing.expectEqual(@as(i16, 2), insertGapIP(&d, 6, 2, 3, false, false));
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xab, 0x01, 0 }, d[0..3]);
    // Off a boundary -> nothing.
    try std.testing.expectEqual(@as(i16, 0), insertGapIP(&d, 6, 3, 3, false, true));
}

test "insertGapFP writes the token at a fractional-side boundary" {
    var d: [4]u8 = undefined;
    // nth 2, width 3 -> nth % 3 == 2 == width-1: boundary. token 0xbb.
    try std.testing.expectEqual(@as(i16, 1), insertGapFP(&d, 6, 2, 3, false, true));
    try std.testing.expectEqual(@as(u8, 0xbb), d[0]);
    try std.testing.expectEqual(@as(i16, 0), insertGapFP(&d, 6, 1, 3, false, true));
}
