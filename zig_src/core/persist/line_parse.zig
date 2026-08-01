//! Header-line matching and integer parsing -- the pure core of the state-file
//! and data-file header checks.
//!
//! Both take the caller's BUFFER, not a pointer into it. Every caller reads a
//! line into a fixed local array and therefore knows its length; the previous
//! shape passed `.ptr` and discarded that at the boundary, leaving each walk
//! bounded only by a NUL that `readLine()` promises from inside another function,
//! in C. A slice keeps the bound local and `std.mem.sliceTo` cannot leave it.
//!
//! Lifted here for native coverage: the owner these came from reaches libc and
//! the file I/O globals, so it is only testable through the C oracle, and
//! `parseU32` in particular has already carried a real defect (see below).

const std = @import("std");

/// Whether the NUL-terminated contents of `line` equal `expected`.
///
/// A line with no terminator inside the buffer compares as the whole buffer,
/// which cannot match a shorter `expected` -- so a missing NUL is a mismatch
/// rather than a walk off the end.
///
/// COST, measured rather than assumed: the `sliceTo` + `eql` pair is 192 bytes of
/// DMCP flash more than an equivalent hand-rolled index walk, and the whole rest
/// of M-SAFE-4 -- the slice signatures and the saturating parse that fixes the
/// version forgery -- is free. So this 192 bytes buys nothing but the clarity of
/// the std spelling, and it is kept anyway: the hand-rolled version written to
/// take the measurement got the unterminated-buffer case wrong on the first
/// attempt, returning false where this returns true. On a parser that decides
/// whether to trust a file, an obviously-correct one-liner is worth 2% of the
/// remaining flash headroom. Revisit if the budget tightens, and re-derive the
/// number rather than trusting this comment.
pub fn equals(line: []const u8, expected: []const u8) bool {
    return std.mem.eql(u8, std.mem.sliceTo(line, 0), expected);
}

/// Parse leading decimal digits of `line` as a u32, stopping at the first
/// non-digit or the terminator.
///
/// SATURATING, and that is load-bearing rather than tidy. The state-file header
/// caller accepts a version in [10000000, 20000000], and that value then selects
/// the parse layout for the whole rest of the file. Plain `*`/`+` on a u32 wraps,
/// which lets a crafted line land anywhere inside that window and FORGE a
/// version: the digits 4304967321 wrap to exactly 10000025. Saturating keeps an
/// absurd version absurd, so the range check rejects it. The sibling parser in
/// program_serialization_runtime.zig was fixed this way by the M1 malformed-input
/// fuzz; this twin was missed and kept wrapping until M-SAFE-4.
///
/// ON PARITY, because there is no single upstream behaviour to match here.
/// Upstream's `toUint32` is `strtoul(str, NULL, 10)` assigned into a `uint32_t`,
/// so its result depends on the width of `unsigned long`:
///
///   * LP64 host: `strtoul` returns 4304967321 -- no overflow, it fits -- and the
///     conversion to uint32_t truncates to 10000025. Upstream C ACCEPTS the
///     forgery on the host. Verified by compiling and running it.
///   * ILP32 firmware: `unsigned long` is 32-bit, `strtoul` saturates at
///     ULONG_MAX, and the range check rejects. Upstream C REFUSES it on the
///     device.
///
/// The two disagree, so "be faithful to upstream" does not resolve it. This picks
/// the firmware's answer: it is the build that ships, it is the safe one, and the
/// divergence is confined to inputs above 2^32, which no valid state file
/// contains -- every version the caller can accept is eight digits and parses
/// identically either way. See the c_long width note in the maintainer memory:
/// this is the same class as the LLP64 trap, on the restore path.
pub fn parseU32(line: []const u8) u32 {
    var value: u32 = 0;
    for (std.mem.sliceTo(line, 0)) |c| {
        if (c < '0' or c > '9') break;
        value = value *| 10 +| (c - '0');
    }
    return value;
}

test "equals matches only the NUL-terminated prefix" {
    var buf: [16]u8 = @splat(0);
    @memcpy(buf[0..5], "hello");
    try std.testing.expect(equals(&buf, "hello"));
    try std.testing.expect(!equals(&buf, "hell"));
    try std.testing.expect(!equals(&buf, "hello!"));
    // Trailing bytes after the terminator are not part of the line.
    buf[6] = 'X';
    try std.testing.expect(equals(&buf, "hello"));
}

test "equals treats an unterminated buffer as the whole buffer" {
    // readLine() always terminates, but the type no longer depends on that: a
    // buffer with no NUL compares as its full contents instead of reading on.
    const full = "abcd".*;
    try std.testing.expect(equals(&full, "abcd"));
    try std.testing.expect(!equals(&full, "abc"));
}

test "equals on an empty line" {
    const empty = [_]u8{0};
    try std.testing.expect(equals(&empty, ""));
    try std.testing.expect(!equals(&empty, "0"));
}

test "parseU32 reads leading digits and stops at the first non-digit" {
    try std.testing.expectEqual(@as(u32, 0), parseU32("0\x00"));
    try std.testing.expectEqual(@as(u32, 10000025), parseU32("10000025\x00"));
    try std.testing.expectEqual(@as(u32, 12), parseU32("12abc\x00"));
    try std.testing.expectEqual(@as(u32, 0), parseU32("abc\x00"));
    try std.testing.expectEqual(@as(u32, 0), parseU32("\x00"));
    // A leading sign is not a digit, so nothing is consumed -- as before.
    try std.testing.expectEqual(@as(u32, 0), parseU32("-5\x00"));
}

test "parseU32 saturates instead of wrapping into a plausible version" {
    // The exact forgery the saturation exists to stop: with wrapping u32
    // arithmetic these digits land on 10000025, a version the caller accepts.
    try std.testing.expectEqual(@as(u32, 4304967321 % (1 << 32)), @as(u32, 10000025));
    try std.testing.expectEqual(std.math.maxInt(u32), parseU32("4304967321\x00"));

    // ...and stays saturated however many digits follow, so no length of input
    // can steer the result back into the accepted window.
    try std.testing.expectEqual(std.math.maxInt(u32), parseU32("99999999999999999999\x00"));
    try std.testing.expectEqual(std.math.maxInt(u32), parseU32("4294967296\x00"));

    // The largest value that still fits is unchanged, so no valid file moves.
    try std.testing.expectEqual(std.math.maxInt(u32), parseU32("4294967295\x00"));
}

test "parseU32 accepts every version the caller's range check admits" {
    // Guard against a saturation bug that clipped legitimate values: the whole
    // accepted window must round-trip exactly.
    for ([_]u32{ 10_000_000, 10_000_025, 15_000_000, 19_999_999, 20_000_000 }) |v| {
        var buf: [16]u8 = @splat(0);
        const s = std.fmt.bufPrint(buf[0..15], "{d}", .{v}) catch unreachable;
        try std.testing.expectEqual(v, parseU32(buf[0 .. s.len + 1]));
    }
}
