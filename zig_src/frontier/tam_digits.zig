//! TAM maximum-digit count -- the pure core of frontier_tam's _tamMaxDigits.
//!
//! When the temporary alpha-mode (TAM) input collects a bounded numeric
//! argument, the number of digits it will accept is derived from the upper
//! bound: a plain decimal-width count, except GTOP always reserves at least
//! three digits (its step numbers are shown zero-padded). That derivation is a
//! pure threshold ladder over the bound; the only state the owner reads is
//! whether the active TAM function is GTOP.
//!
//! Lifting it here gives the threshold ladder native coverage -- the TAM owner
//! is only reachable through the C oracle. The owner keeps the thin _tamMaxDigits
//! wrapper that passes the GTOP flag in.

const std = @import("std");

/// The number of digits (1..5) the TAM argument accepts for an upper bound of
/// `max`. GTOP (`is_gtop`) never returns fewer than three.
pub fn maxDigits(max: i16, is_gtop: bool) u8 {
    if (is_gtop) {
        return if (max < 1000) 3 else if (max < 10000) 4 else 5;
    }
    return if (max < 10) 1 else if (max < 100) 2 else if (max < 1000) 3 else if (max < 10000) 4 else 5;
}

test "the plain ladder counts decimal width" {
    try std.testing.expectEqual(@as(u8, 1), maxDigits(9, false));
    try std.testing.expectEqual(@as(u8, 2), maxDigits(10, false));
    try std.testing.expectEqual(@as(u8, 2), maxDigits(99, false));
    try std.testing.expectEqual(@as(u8, 3), maxDigits(100, false));
    try std.testing.expectEqual(@as(u8, 3), maxDigits(999, false));
    try std.testing.expectEqual(@as(u8, 4), maxDigits(1000, false));
    try std.testing.expectEqual(@as(u8, 4), maxDigits(9999, false));
    try std.testing.expectEqual(@as(u8, 5), maxDigits(10000, false));
}

test "GTOP reserves at least three digits" {
    try std.testing.expectEqual(@as(u8, 3), maxDigits(0, true));
    try std.testing.expectEqual(@as(u8, 3), maxDigits(9, true));
    try std.testing.expectEqual(@as(u8, 3), maxDigits(999, true));
    try std.testing.expectEqual(@as(u8, 4), maxDigits(1000, true));
    try std.testing.expectEqual(@as(u8, 4), maxDigits(9999, true));
    try std.testing.expectEqual(@as(u8, 5), maxDigits(10000, true));
}
