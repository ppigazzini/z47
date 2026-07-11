//! Formula exponent digit scan -- the pure core of equation.zig's _checkExponent.
//!
//! When the formula parser meets a number, it looks ahead to count the exponent
//! digits: an optional leading sign then decimal digits, stopping at anything
//! else, and bailing out with 0 on a '^' / ',' / '.' (which mean this is not a
//! plain exponent). It is a pure scan over the string. Lift it here for native
//! coverage -- the equation owner is only reachable through the C oracle. This
//! module uses Zig many-item pointers rather than C pointers, so it stays out of
//! the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Count the exponent digits at `str` (a leading '+'/'-' counts as one), or 0
/// when a '^', ',' or '.' is seen first.
pub fn checkExponent(str: [*]const u8) u32 {
    var p = str;
    var digits: u32 = 0;
    while (true) {
        switch (p[0]) {
            '0'...'9' => {
                digits += 1;
                p += 1;
            },
            '^', ',', '.' => return 0,
            '+', '-' => {
                if (digits == 0) {
                    digits += 1;
                    p += 1;
                } else {
                    return digits;
                }
            },
            else => return digits,
        }
    }
}

test "counts plain exponent digits" {
    try std.testing.expectEqual(@as(u32, 3), checkExponent("123"));
    try std.testing.expectEqual(@as(u32, 0), checkExponent(""));
}

test "a leading sign counts as one digit" {
    try std.testing.expectEqual(@as(u32, 2), checkExponent("+5"));
    try std.testing.expectEqual(@as(u32, 3), checkExponent("-42"));
}

test "a sign after digits stops the scan" {
    try std.testing.expectEqual(@as(u32, 1), checkExponent("5+3"));
}

test "a caret, comma or dot bails out with zero" {
    try std.testing.expectEqual(@as(u32, 0), checkExponent("12^"));
    try std.testing.expectEqual(@as(u32, 0), checkExponent("1.5"));
    try std.testing.expectEqual(@as(u32, 0), checkExponent(",5"));
}

test "a trailing non-digit stops the scan" {
    try std.testing.expectEqual(@as(u32, 2), checkExponent("42x"));
}
