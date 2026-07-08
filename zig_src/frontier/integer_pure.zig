// SPDX-License-Identifier: GPL-3.0-only
//
// Pure unsigned-integer primitives shared by the WP34S short-integer commands.
//
// These are the parts of the integer engine that depend on nothing but their u64
// inputs -- no calculator mode, flags, or registers -- so they live here as a
// std-only module that `zig build test:unit` exercises natively. frontier_integers
// keeps the mode/flag/register handling and delegates the raw arithmetic here.

const std = @import("std");

/// Euclidean greatest common divisor. gcd(a, 0) == a and gcd(0, b) == b, so
/// gcd(0, 0) == 0. Operates on the already-magnitude-extracted values.
pub fn gcd(a_in: u64, b_in: u64) u64 {
    var a = a_in;
    var b = b_in;
    while (b != 0) {
        const t = b;
        b = a % b;
        a = t;
    }
    return a;
}

/// Floor of the integer square root: the largest r with r*r <= value. Newton's
/// method from an over-estimate, then a single downward correction. A caller can
/// recover "value is a perfect square" as `isqrt(value) *% isqrt(value) == value`.
pub fn isqrt(value: u64) u64 {
    if (value == 0) return 0;
    var nn0: u64 = value / 2 + 1;
    var nn1: u64 = value / nn0 + nn0 / 2;
    while (nn1 < nn0) {
        nn0 = nn1;
        nn1 = (nn0 + value / nn0) / 2;
    }
    if (nn1 *% nn1 > value) nn1 -%= 1;
    return nn1;
}

test "gcd matches known pairs and boundary cases" {
    try std.testing.expectEqual(@as(u64, 6), gcd(54, 24));
    try std.testing.expectEqual(@as(u64, 6), gcd(24, 54)); // order independent
    try std.testing.expectEqual(@as(u64, 1), gcd(17, 5)); // coprime
    try std.testing.expectEqual(@as(u64, 12), gcd(12, 0)); // gcd(a,0) == a
    try std.testing.expectEqual(@as(u64, 12), gcd(0, 12)); // gcd(0,b) == b
    try std.testing.expectEqual(@as(u64, 0), gcd(0, 0));
    try std.testing.expectEqual(@as(u64, 7), gcd(7, 7)); // equal operands
    try std.testing.expectEqual(@as(u64, 1), gcd(std.math.maxInt(u64), std.math.maxInt(u64) - 1));
}

test "isqrt is the floor of the square root" {
    try std.testing.expectEqual(@as(u64, 0), isqrt(0));
    try std.testing.expectEqual(@as(u64, 1), isqrt(1));
    try std.testing.expectEqual(@as(u64, 1), isqrt(3)); // floor(sqrt 3)
    try std.testing.expectEqual(@as(u64, 2), isqrt(4)); // perfect square
    try std.testing.expectEqual(@as(u64, 3), isqrt(15));
    try std.testing.expectEqual(@as(u64, 4), isqrt(16));
    try std.testing.expectEqual(@as(u64, 1000), isqrt(1_000_000));
    try std.testing.expectEqual(@as(u64, 1_000_000_000), isqrt(1_000_000_000_000_000_000));

    // Upstream quirk, pinned for parity: the downward correction squares nn1 with
    // wrapping (`nn1 *% nn1`), so at the very top of the u64 range the square wraps
    // to 0, the correction is skipped, and the result is 2^32 rather than the
    // mathematical floor 2^32-1. WP34S_intSqrt behaves identically; do NOT "fix"
    // this here without matching the C engine (it would break short-integer parity).
    try std.testing.expectEqual(@as(u64, 1 << 32), isqrt(std.math.maxInt(u64)));

    // Property: r*r <= value < (r+1)*(r+1) for a spread of inputs, and the
    // perfect-square recovery a caller relies on for the CARRY flag.
    var v: u64 = 0;
    while (v <= 10_000) : (v += 1) {
        const r = isqrt(v);
        try std.testing.expect(r * r <= v);
        try std.testing.expect((r + 1) * (r + 1) > v);
        const is_square = (r * r == v);
        try std.testing.expectEqual(is_square, r *% r == v);
    }
}
