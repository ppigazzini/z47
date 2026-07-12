//! The small-prime lookup list -- the pure core lifted out of prime.zig.
//!
//! prime.zig enumerates the first 169 primes for trial division, the
//! Euler-phi/factoring fast paths, and next-prime search. The first block is a
//! direct table of the primes up to 251; the second block is stored as a table
//! of prime gaps that are accumulated from 251 upward. That index -> prime map is
//! pure integer arithmetic over two const tables -- no globals, no GMP -- so it
//! is the one genuinely std-only island in an otherwise decimal/mpz-heavy owner.
//!
//! Lifting it here gives it native coverage independent of the C oracle. The
//! owner keeps `smallPrimeList` / `smallPrimeListNumber` as thin aliases over
//! `at` / `count`, so its call sites are unchanged.

const std = @import("std");

// The primes 2..251 stored directly.
const small_primes = [_]u8{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251 };

// The gaps between consecutive primes above 251, accumulated from 251.
const small_primes2 = [_]u8{ 6, 6, 6, 2, 6, 4, 2, 10, 14, 4, 2, 4, 14, 6, 10, 2, 4, 6, 8, 6, 6, 4, 6, 8, 4, 8, 10, 2, 10, 2, 6, 4, 6, 8, 4, 2, 4, 12, 8, 4, 8, 4, 6, 12, 2, 18, 6, 10, 6, 6, 2, 6, 10, 6, 6, 2, 6, 6, 4, 2, 12, 10, 2, 4, 6, 6, 2, 12, 4, 6, 8, 10, 8, 10, 8, 6, 6, 4, 8, 6, 4, 8, 4, 14, 10, 12, 2, 10, 2, 4, 2, 10, 14, 4, 2, 4, 14, 4, 2, 4, 20, 4, 8, 10, 8, 4, 6, 6, 14, 4, 6, 6, 8, 6, 12 };

/// The number of primes this list can return (both blocks combined).
pub const count: u16 = small_primes.len + small_primes2.len;

/// The prime at `index` in the list, or 0 when `index` is out of range.
pub fn at(index: u16) u16 {
    var tt: u16 = 251;
    if (index < small_primes.len) {
        return small_primes[index];
    } else if (index < count) {
        const sub_index: u16 = index - @as(u16, small_primes.len);
        var ii: u16 = 0;
        while (ii <= sub_index and ii < small_primes2.len) : (ii += 1) {
            tt += small_primes2[ii];
        }
        return tt;
    } else {
        return 0;
    }
}

test "the direct block returns the primes up to 251" {
    try std.testing.expectEqual(@as(u16, 2), at(0));
    try std.testing.expectEqual(@as(u16, 3), at(1));
    try std.testing.expectEqual(@as(u16, 251), at(small_primes.len - 1));
}

test "the gap block continues the prime sequence past 251" {
    // 257, 263, 269, 271, 277 are the next five primes after 251.
    try std.testing.expectEqual(@as(u16, 257), at(54));
    try std.testing.expectEqual(@as(u16, 263), at(55));
    try std.testing.expectEqual(@as(u16, 269), at(56));
    try std.testing.expectEqual(@as(u16, 271), at(57));
    try std.testing.expectEqual(@as(u16, 277), at(58));
}

test "out-of-range indices return 0" {
    try std.testing.expectEqual(@as(u16, 0), at(count));
    try std.testing.expectEqual(@as(u16, 0), at(count + 5));
}

test "the whole list is strictly increasing" {
    // Every prime is larger than its predecessor -- a strong check that the gap
    // accumulation stays aligned across the block boundary.
    var i: u16 = 1;
    var prev = at(0);
    while (i < count) : (i += 1) {
        const cur = at(i);
        try std.testing.expect(cur > prev);
        prev = cur;
    }
}
