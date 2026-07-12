// SPDX-License-Identifier: GPL-3.0-only
//
// Pure linear-regression / curve-fit selection-bitmask helpers, lifted from
// frontier_curve_fitting.zig (lrCountOnes, minLRDataPoints). Both are plain u16
// bitmask arithmetic with no register/dec/GMP coupling, so they live here as a
// std-only module exercised natively under `zig build test:unit`; the owner keeps
// its pub-export C-ABI wrappers and delegates.
//
// The curve-fit selection is a 10-bit mask (bits 0-9 select fit models). These are
// largely testSuite-blind, so the native tests pin the mask boundaries -- the kind
// of magic constants (448, 575, 1023) an edit could silently shift.

const std = @import("std");

/// Number of fit models selected (lrCountOnes).
pub fn countOnes(curve_fitting: u16) u16 {
    return @popCount(curve_fitting);
}

/// Minimum data points required for the selected fit models (minLRDataPoints):
/// 3 if any of bits 6-8 (mask 448) are set, else 2 if any of bits 0-5 or bit 9
/// (mask 575) are set, else 65535 (an empty or out-of-range selection).
pub fn minDataPoints(selection: u16) u16 {
    if (selection > 1023) {
        return 65535;
    } else if (selection & 448 != 0) {
        return 3;
    } else if (selection & (63 + 512) != 0) {
        return 2;
    } else {
        return 65535; // if 0
    }
}

// ===========================================================================
// Tests -- native (run under `zig build test:unit`).
// ===========================================================================
const testing = std.testing;

test "countOnes counts the selected fit models" {
    try testing.expectEqual(@as(u16, 0), countOnes(0));
    try testing.expectEqual(@as(u16, 2), countOnes(0b101));
    try testing.expectEqual(@as(u16, 10), countOnes(0x3FF)); // all ten models
}

test "minDataPoints: bits 6-8 require three points" {
    try testing.expectEqual(@as(u16, 3), minDataPoints(64)); // bit 6
    try testing.expectEqual(@as(u16, 3), minDataPoints(448)); // bits 6,7,8
    // A 3-point bit takes precedence over a 2-point bit.
    try testing.expectEqual(@as(u16, 3), minDataPoints(64 | 1));
}

test "minDataPoints: bits 0-5 or bit 9 require two points" {
    try testing.expectEqual(@as(u16, 2), minDataPoints(1)); // bit 0
    try testing.expectEqual(@as(u16, 2), minDataPoints(63)); // bits 0-5
    try testing.expectEqual(@as(u16, 2), minDataPoints(512)); // bit 9
}

test "minDataPoints: empty or out-of-range selection is 65535" {
    try testing.expectEqual(@as(u16, 65535), minDataPoints(0));
    try testing.expectEqual(@as(u16, 65535), minDataPoints(1024)); // > 1023
}
