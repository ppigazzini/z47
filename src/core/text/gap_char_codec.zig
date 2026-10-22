//! Digit-group gap-character normalization -- the pure core of display.c's
//! getGapChar1Left / getGapChar1Right / getGapChar1Radix.
//!
//! A group separator is stored as a softmenu-name byte string; when it is a lone
//! ASCII separator character it is normalized to the character followed by a
//! 0x01 marker (the display's single-character-separator form). The left/right
//! variant accepts ',' '.' '\'' '_' when the string is exactly one byte; the
//! radix variant accepts only ',' '.' and a slightly looser length test. The
//! normalization is pure over the input bytes; the owner does the item-table
//! lookup. Lift it here for native coverage -- the display owner is only
//! reachable through the C oracle. This module uses Zig many-item pointers rather
//! than C pointers.

const std = @import("std");

const lit_comma1 = ",\x01";
const lit_dot1 = ".\x01";
const lit_quote1 = "'\x01";
const lit_underscore1 = "_\x01";

/// The separator followed by the 0x01 skip byte, for the four characters the
/// display draws as a one-byte gap; null for any other.
fn gapWithSkipByte(separator: u8) ?[*]const u8 {
    return switch (separator) {
        ',' => lit_comma1,
        '.' => lit_dot1,
        '\'' => lit_quote1,
        '_' => lit_underscore1,
        else => null,
    };
}

/// Left separator normalization (getGapChar1Left): a lone ',' '.' '\'' or '_'
/// becomes the character plus the 0x01 marker; anything else is returned
/// unchanged. The default gap takes two bytes, so the length is tested first.
pub fn gapChar1LR(s: [*]const u8) [*]const u8 {
    if (s[1] == 0 and s[2] == 0) {
        if (gapWithSkipByte(s[0])) |gap| {
            return gap;
        }
    }
    return s;
}

/// Radix separator normalization (getGapChar1Radix): only ',' and '.' are
/// normalized, and the length test accepts a two- or three-byte string. The
/// default radix mark is a period, so it is tested first.
pub fn gapChar1Radix(s: [*]const u8) [*]const u8 {
    if (s[1] == 0 or s[2] == 0) {
        if (s[0] == '.') {
            return lit_dot1;
        }
        if (s[0] == ',') {
            return lit_comma1;
        }
    }
    return s;
}

/// Right separator normalization (getGapChar1Right): the radix variant's looser
/// length test but the full ',' '.' '\'' '_' set. A gap of two bytes also
/// satisfies the length test, so the character is tested first.
pub fn gapChar1RightFull(s: [*]const u8) [*]const u8 {
    if (gapWithSkipByte(s[0])) |gap| {
        if (s[1] == 0 or s[2] == 0) {
            return gap;
        }
    }
    return s;
}

/// The radix mark character: ',' when the normalized radix `r` is a comma or the
/// wide-comma glyph `wcomma`, else '.'.
pub fn radix34MarkChar(r: [*]const u8, wcomma: [*]const u8) u8 {
    return if (r[0] == ',' or (r[0] == wcomma[0] and r[1] == wcomma[1])) ',' else '.';
}

fn bytes(p: [*]const u8) []const u8 {
    return std.mem.sliceTo(p, 0);
}

test "gapChar1LR normalizes lone separator characters" {
    try std.testing.expectEqualSlices(u8, &[_]u8{ ',', 0x01 }, bytes(gapChar1LR(",\x00\x00")));
    try std.testing.expectEqualSlices(u8, &[_]u8{ '.', 0x01 }, bytes(gapChar1LR(".\x00\x00")));
    try std.testing.expectEqualSlices(u8, &[_]u8{ '\'', 0x01 }, bytes(gapChar1LR("'\x00\x00")));
    try std.testing.expectEqualSlices(u8, &[_]u8{ '_', 0x01 }, bytes(gapChar1LR("_\x00\x00")));
}

test "gapChar1LR leaves non-separators and multi-byte strings unchanged" {
    try std.testing.expectEqualStrings("x", bytes(gapChar1LR("x\x00\x00")));
    // A second non-zero byte disqualifies the normalization.
    try std.testing.expectEqualSlices(u8, &[_]u8{ ',', 0x05 }, bytes(gapChar1LR(",\x05\x00")));
    // An empty string is returned as-is.
    try std.testing.expectEqualStrings("", bytes(gapChar1LR("\x00\x00\x00")));
}

test "gapChar1Radix normalizes only comma and dot, with the looser length test" {
    try std.testing.expectEqualSlices(u8, &[_]u8{ ',', 0x01 }, bytes(gapChar1Radix(",\x00\x00")));
    // s[1] != 0 but s[2] == 0 still qualifies for the radix variant.
    try std.testing.expectEqualSlices(u8, &[_]u8{ '.', 0x01 }, bytes(gapChar1Radix(".\x05\x00")));
    // Quote is not normalized by the radix variant.
    try std.testing.expectEqualStrings("'", bytes(gapChar1Radix("'\x00\x00")));
    // Both trailing bytes non-zero disqualifies it.
    try std.testing.expectEqualSlices(u8, &[_]u8{ ',', 0x05, 0x06 }, bytes(gapChar1Radix(",\x05\x06")));
}

test "gapChar1RightFull uses the looser length test with the full separator set" {
    // Looser test: s[2] == 0 qualifies even with s[1] != 0.
    try std.testing.expectEqualSlices(u8, &[_]u8{ '\'', 0x01 }, bytes(gapChar1RightFull("'\x05\x00")));
    try std.testing.expectEqualSlices(u8, &[_]u8{ '_', 0x01 }, bytes(gapChar1RightFull("_\x00\x00")));
    // Both trailing bytes non-zero disqualifies it.
    try std.testing.expectEqualSlices(u8, &[_]u8{ ',', 0x05, 0x06 }, bytes(gapChar1RightFull(",\x05\x06")));
}

test "radix34MarkChar picks comma for a comma or the wide-comma glyph" {
    const wcomma = "\xa7\x88";
    try std.testing.expectEqual(@as(u8, ','), radix34MarkChar(",\x00", wcomma));
    try std.testing.expectEqual(@as(u8, ','), radix34MarkChar(wcomma, wcomma));
    try std.testing.expectEqual(@as(u8, '.'), radix34MarkChar(".\x00", wcomma));
    try std.testing.expectEqual(@as(u8, '.'), radix34MarkChar("x\x00", wcomma));
}
