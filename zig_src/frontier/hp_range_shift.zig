//! HP glyph range shift -- the pure core of frontier_char_string's
//! charCodeHPReplacement.
//!
//! When no exact replacement applies, a digit (1..9) or superscript-digit (1..9)
//! char code is shifted into the HP glyph block by offsetting from the HP-1 code.
//! It is pure integer arithmetic over the resolved code bounds. Lift it here for
//! native coverage -- the char-string owner resolves the glyph codes from
//! constants and delegates.

const std = @import("std");

/// The HP-block char code for a digit or superscript-digit `char_code`, or null
/// if it is in neither range.
pub fn hpRangeShift(char_code: u16, std_1: u16, std_9: u16, std_hp_1: u16, std_sup_1: u16, std_sup_9: u16) ?u16 {
    if (char_code >= std_1 and char_code <= std_9) {
        return char_code - std_1 + std_hp_1;
    }
    if (char_code >= std_sup_1 and char_code <= std_sup_9) {
        return char_code - std_sup_1 + std_hp_1;
    }
    return null;
}

test "digits and superscript digits shift into the HP block" {
    // std_1=0x31, std_9=0x39, std_hp_1=0x100, std_sup_1=0x161, std_sup_9=0x169.
    try std.testing.expectEqual(@as(?u16, 0x100), hpRangeShift(0x31, 0x31, 0x39, 0x100, 0x161, 0x169));
    try std.testing.expectEqual(@as(?u16, 0x104), hpRangeShift(0x35, 0x31, 0x39, 0x100, 0x161, 0x169));
    try std.testing.expectEqual(@as(?u16, 0x108), hpRangeShift(0x169, 0x31, 0x39, 0x100, 0x161, 0x169));
    try std.testing.expectEqual(@as(?u16, null), hpRangeShift(0x50, 0x31, 0x39, 0x100, 0x161, 0x169));
}
