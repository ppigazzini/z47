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

/// True when `value` is a power of two (2^k for k >= 0). Zero is not a power.
pub fn isPowerOfTwo(value: u64) bool {
    return value != 0 and (value & (value - 1)) == 0;
}

/// Floor of the base-2 logarithm: the index of the highest set bit. `value` must
/// be > 0 (the short-integer LOG2 command rejects 0 before calling this).
pub fn log2Floor(value: u64) u32 {
    var v = value >> 1;
    var log2: u32 = 0;
    while (v != 0) : (v >>= 1) log2 += 1;
    return log2;
}

/// True when `value` is a power of ten (10^k for k >= 0).
pub fn isPowerOfTen(value: u64) bool {
    var v = value;
    while (v >= 10) : (v /= 10) {
        if (v % 10 != 0) return false;
    }
    return v == 1;
}

/// Floor of the base-10 logarithm. `value` must be > 0.
pub fn log10Floor(value: u64) u32 {
    var v = value;
    var r: u32 = 0;
    while (v >= 10) : (v /= 10) r += 1;
    return r;
}

/// (a * b) mod m, via a 128-bit product so the multiply never overflows. `m`
/// must be non-zero (callers in the modular commands guarantee it).
pub fn mulmod(a: u64, b: u64, m: u64) u64 {
    const x: u128 = @as(u128, a) * @as(u128, b);
    return @intCast(x % m);
}

/// (base ^ exp) mod m by right-to-left binary exponentiation. `m` must be
/// non-zero.
pub fn expmod(base: u64, exp: u64, m: u64) u64 {
    var e = exp;
    var x: u64 = 1;
    var y: u64 = base;
    while (e > 0) : (e >>= 1) {
        if ((e & 1) != 0) x = mulmod(x, y, m);
        y = mulmod(y, y, m);
    }
    return x % m;
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

test "log2Floor and isPowerOfTwo" {
    try std.testing.expectEqual(@as(u32, 0), log2Floor(1));
    try std.testing.expectEqual(@as(u32, 1), log2Floor(2));
    try std.testing.expectEqual(@as(u32, 1), log2Floor(3)); // floor
    try std.testing.expectEqual(@as(u32, 3), log2Floor(8));
    try std.testing.expectEqual(@as(u32, 3), log2Floor(15));
    try std.testing.expectEqual(@as(u32, 63), log2Floor(std.math.maxInt(u64)));

    try std.testing.expect(isPowerOfTwo(1));
    try std.testing.expect(isPowerOfTwo(2));
    try std.testing.expect(isPowerOfTwo(1 << 40));
    try std.testing.expect(!isPowerOfTwo(0));
    try std.testing.expect(!isPowerOfTwo(3));
    try std.testing.expect(!isPowerOfTwo(6));

    // For every power of two, log2Floor is exact and isPowerOfTwo agrees.
    var k: u6 = 0;
    while (k < 63) : (k += 1) {
        const p = @as(u64, 1) << k;
        try std.testing.expectEqual(@as(u32, k), log2Floor(p));
        try std.testing.expect(isPowerOfTwo(p));
        if (k >= 2) try std.testing.expect(!isPowerOfTwo(p + 1));
    }
}

test "log10Floor and isPowerOfTen" {
    try std.testing.expectEqual(@as(u32, 0), log10Floor(1));
    try std.testing.expectEqual(@as(u32, 0), log10Floor(9));
    try std.testing.expectEqual(@as(u32, 1), log10Floor(10));
    try std.testing.expectEqual(@as(u32, 1), log10Floor(99));
    try std.testing.expectEqual(@as(u32, 2), log10Floor(100));
    try std.testing.expectEqual(@as(u32, 18), log10Floor(1_000_000_000_000_000_000));

    try std.testing.expect(isPowerOfTen(1));
    try std.testing.expect(isPowerOfTen(10));
    try std.testing.expect(isPowerOfTen(1000));
    try std.testing.expect(!isPowerOfTen(50));
    try std.testing.expect(!isPowerOfTen(105));
    try std.testing.expect(!isPowerOfTen(0));

    // Every power of ten up to 10^18: exact floor and isPowerOfTen agrees.
    var p: u64 = 1;
    var e: u32 = 0;
    while (e <= 18) : (e += 1) {
        try std.testing.expectEqual(e, log10Floor(p));
        try std.testing.expect(isPowerOfTen(p));
        if (e >= 1) try std.testing.expect(!isPowerOfTen(p + 1));
        p *= 10;
    }
}

test "mulmod computes (a*b) mod m without overflow" {
    try std.testing.expectEqual(@as(u64, 0), mulmod(0, 5, 7));
    try std.testing.expectEqual(@as(u64, 6), mulmod(4, 5, 7)); // 20 mod 7
    try std.testing.expectEqual(@as(u64, 1), mulmod(3, 5, 7)); // 15 mod 7

    // Products that overflow u64 but not the 128-bit intermediate.
    const big = std.math.maxInt(u64);
    try std.testing.expectEqual(@as(u64, 0), mulmod(big, big, big));
    const m: u64 = 1_000_000_007;
    try std.testing.expectEqual(@as(u64, 1), mulmod(m - 1, m - 1, m)); // (m-1)^2 mod m
}

test "expmod computes (base^exp) mod m" {
    try std.testing.expectEqual(@as(u64, 1), expmod(2, 0, 7)); // x^0
    try std.testing.expectEqual(@as(u64, 1), expmod(2, 3, 7)); // 8 mod 7
    try std.testing.expectEqual(@as(u64, 4), expmod(2, 5, 7)); // 32 mod 7
    try std.testing.expectEqual(@as(u64, 0), expmod(2, 5, 1)); // mod 1

    // Fermat's little theorem: a^(p-1) == 1 (mod p) for prime p, gcd(a,p)==1.
    const p: u64 = 1_000_000_007;
    try std.testing.expectEqual(@as(u64, 1), expmod(2, p - 1, p));
    try std.testing.expectEqual(@as(u64, 1), expmod(123_456, p - 1, p));

    // Cross-check against a naive repeated-multiply reference for small inputs.
    var base: u64 = 0;
    while (base < 20) : (base += 1) {
        var exp: u64 = 0;
        while (exp < 12) : (exp += 1) {
            var ref: u64 = 1;
            var i: u64 = 0;
            while (i < exp) : (i += 1) ref = (ref * base) % 13;
            try std.testing.expectEqual(ref, expmod(base, exp, 13));
        }
    }
}
