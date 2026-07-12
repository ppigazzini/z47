// SPDX-License-Identifier: GPL-3.0-only
//
// Shared sign / pointer predicates for the mathematics owners.
//
// These trivial field- and bit-test predicates were copy-pasted verbatim across
// many math owners (`realIsPositive` alone appeared identically in 13 files). They
// read only the std-only abi layout types -- `Real.bits`, `Real34.bytes`,
// `Mpz._mp_size` -- so they collect here as one shared, C-oracle-independent
// module that `zig build test:unit` exercises natively. This is a testable seam
// carved out of the mathematics module: behavior is byte-identical to the former
// per-file copies, and the owners alias these instead of redefining them.
//
// Only genuinely-pure predicates belong here. Sign tests that dispatch into
// decNumber/decQuad (`realIsZero`'s special-value check, `real34IsZero` via
// `decQuadIsZero`) stay in `math_command_wrappers_runtime.zig`; they are not
// std-only and cannot be unit-tested without the C runtime.

const std = @import("std");
const abi = @import("abi");

/// A real_t is flagged negative by the DECNEG bit of its `bits` byte; positive
/// (or zero/NaN) otherwise. Mirrors the decNumber sign convention.
pub inline fn realIsPositive(source: *align(1) const abi.Real) bool {
    return (source.bits & abi.DECNEG) == 0;
}

pub inline fn realIsNegative(source: *align(1) const abi.Real) bool {
    return (source.bits & abi.DECNEG) != 0;
}

/// A real_t carries a special (Inf/NaN/sNaN) encoding in the top nibble of `bits`.
pub inline fn realIsSpecial(source: *align(1) const abi.Real) bool {
    return (source.bits & abi.DECSPECIAL) != 0;
}

/// A real_t is zero when it has a single zero coefficient digit and is not a
/// special value (matches decNumberIsZero on the finite encoding). Sign is
/// irrelevant: negative zero is still zero.
pub inline fn realIsZero(source: *align(1) const abi.Real) bool {
    return source.digits == 1 and source.lsu[0] == 0 and !realIsSpecial(source);
}

/// A real_t is an infinity when the DECINF bit is set (NaN bits distinguish the
/// other special encodings).
pub inline fn realIsInfinite(source: *align(1) const abi.Real) bool {
    return (source.bits & abi.DECINF) != 0;
}

/// A real_t is a (quiet or signalling) NaN when either NaN bit is set.
pub inline fn realIsNaN(source: *align(1) const abi.Real) bool {
    return (source.bits & (abi.DECNAN | abi.DECSNAN)) != 0;
}

/// The raw sign bit of a decQuad (real34_t): the top bit of the last byte of the
/// 16-byte big-endian blob. NOTE this is the raw encoding sign, which differs from
/// decQuadIsNegative on NaN (a sign-set NaN is not "negative"); owners that need
/// the decNumber negativity semantics use runtime.real34IsNegative instead.
pub inline fn real34IsNegative(source: *align(1) const abi.Real34) bool {
    return (source.bytes[15] & 0x80) == 0x80;
}

/// GMP mpz sign lives in `_mp_size`: negative size is a negative value, 0 is zero.
pub inline fn longIntegerIsNegative(op: *const abi.Mpz) bool {
    return op._mp_size < 0;
}

pub inline fn longIntegerIsZero(op: *const abi.Mpz) bool {
    return op._mp_size == 0;
}

pub inline fn longIntegerIsNegativeOrZero(op: *const abi.Mpz) bool {
    return op._mp_size <= 0;
}

/// A long integer is a positive value not exceeding `bound` exactly when GMP
/// stores it in one positive limb within the bound: a non-positive `_mp_size` is
/// zero or negative, and a normalized mpz with two or more limbs necessarily
/// exceeds any single-limb bound. `bound` must fit in one limb (all callers use
/// small dimension caps). Equivalent to `!(sgn<=0) and mpz_cmp_ui(op,bound)<=0`.
pub inline fn longIntegerIsPositiveAtMost(op: *const abi.Mpz, bound: abi.MpLimb) bool {
    return op._mp_size == 1 and op._mp_d[0] <= bound;
}

/// Two pointers alias the same address (guards in-place matrix/vector ops).
pub inline fn samePtr(a: anytype, b: anytype) bool {
    return @intFromPtr(a) == @intFromPtr(b);
}

test "realIsPositive / realIsNegative read the DECNEG bit" {
    var r: abi.Real = std.mem.zeroes(abi.Real);
    r.bits = 0;
    try std.testing.expect(realIsPositive(&r));
    try std.testing.expect(!realIsNegative(&r));

    r.bits = abi.DECNEG;
    try std.testing.expect(!realIsPositive(&r));
    try std.testing.expect(realIsNegative(&r));

    // DECNEG set alongside unrelated flag bits is still negative.
    r.bits = abi.DECNEG | 0x01;
    try std.testing.expect(realIsNegative(&r));
    try std.testing.expect(!realIsPositive(&r));

    // Unrelated flag bits without DECNEG stay positive.
    r.bits = 0x7f & ~abi.DECNEG;
    try std.testing.expect(realIsPositive(&r));
}

test "realIsSpecial detects the Inf/NaN/sNaN bits" {
    var r: abi.Real = std.mem.zeroes(abi.Real);
    r.bits = 0;
    try std.testing.expect(!realIsSpecial(&r));
    for ([_]u8{ abi.DECINF, abi.DECNAN, abi.DECSNAN }) |flag| {
        r.bits = flag;
        try std.testing.expect(realIsSpecial(&r));
    }
    // The sign bit alone is not a special encoding.
    r.bits = abi.DECNEG;
    try std.testing.expect(!realIsSpecial(&r));
}

test "realIsZero requires one zero digit and a finite encoding" {
    var r: abi.Real = std.mem.zeroes(abi.Real);
    r.digits = 1;
    r.lsu[0] = 0;
    r.bits = 0;
    try std.testing.expect(realIsZero(&r));

    // Negative zero is still zero.
    r.bits = abi.DECNEG;
    try std.testing.expect(realIsZero(&r));

    // A special (Inf/NaN) encoding is never zero.
    r.bits = abi.DECINF;
    try std.testing.expect(!realIsZero(&r));

    // A non-zero coefficient is not zero.
    r.bits = 0;
    r.lsu[0] = 5;
    try std.testing.expect(!realIsZero(&r));

    // More than one coefficient digit is not the canonical zero.
    r.lsu[0] = 0;
    r.digits = 3;
    try std.testing.expect(!realIsZero(&r));
}

test "realIsInfinite / realIsNaN isolate their special bits" {
    var r: abi.Real = std.mem.zeroes(abi.Real);

    r.bits = abi.DECINF;
    try std.testing.expect(realIsInfinite(&r));
    try std.testing.expect(!realIsNaN(&r));

    r.bits = abi.DECNAN;
    try std.testing.expect(!realIsInfinite(&r));
    try std.testing.expect(realIsNaN(&r));

    r.bits = abi.DECSNAN;
    try std.testing.expect(!realIsInfinite(&r));
    try std.testing.expect(realIsNaN(&r));

    // A finite value is neither.
    r.bits = abi.DECNEG;
    try std.testing.expect(!realIsInfinite(&r));
    try std.testing.expect(!realIsNaN(&r));
}

test "real34IsNegative reads the MSB of the top blob byte" {
    var q: abi.Real34 = std.mem.zeroes(abi.Real34);
    try std.testing.expect(!real34IsNegative(&q));

    q.bytes[15] = 0x80;
    try std.testing.expect(real34IsNegative(&q));

    q.bytes[15] = 0x7f;
    try std.testing.expect(!real34IsNegative(&q));

    // Lower bytes never affect the sign.
    q.bytes[0] = 0xff;
    try std.testing.expect(!real34IsNegative(&q));
}

test "long-integer sign predicates read _mp_size" {
    var z: abi.Mpz = std.mem.zeroes(abi.Mpz);

    z._mp_size = 0;
    try std.testing.expect(longIntegerIsZero(&z));
    try std.testing.expect(longIntegerIsNegativeOrZero(&z));
    try std.testing.expect(!longIntegerIsNegative(&z));

    z._mp_size = -3;
    try std.testing.expect(longIntegerIsNegative(&z));
    try std.testing.expect(longIntegerIsNegativeOrZero(&z));
    try std.testing.expect(!longIntegerIsZero(&z));

    z._mp_size = 5;
    try std.testing.expect(!longIntegerIsNegative(&z));
    try std.testing.expect(!longIntegerIsNegativeOrZero(&z));
    try std.testing.expect(!longIntegerIsZero(&z));
}

test "real classification predicates are consistent across all 256 bits values" {
    // The real-classification predicates depend only on the `bits` byte, so this
    // is an EXHAUSTIVE property test -- every possible flag byte is checked, which
    // is stronger than fuzzing an 8-bit domain. It pins the exact bit each
    // predicate reads and the cross-predicate invariants that must always hold.
    var b: u16 = 0;
    while (b < 256) : (b += 1) {
        const bits: u8 = @intCast(b);
        var r: abi.Real = std.mem.zeroes(abi.Real);
        r.digits = 1;
        r.lsu[0] = 0;
        r.bits = bits;

        // Sign is a single bit: positive and negative partition every value.
        try std.testing.expect(realIsPositive(&r) != realIsNegative(&r));

        // Special is exactly the union of the infinite and NaN encodings.
        try std.testing.expectEqual(realIsInfinite(&r) or realIsNaN(&r), realIsSpecial(&r));

        // Each predicate reads exactly its documented mask (drift pin).
        try std.testing.expectEqual((bits & abi.DECNEG) != 0, realIsNegative(&r));
        try std.testing.expectEqual((bits & abi.DECINF) != 0, realIsInfinite(&r));
        try std.testing.expectEqual((bits & (abi.DECNAN | abi.DECSNAN)) != 0, realIsNaN(&r));
        try std.testing.expectEqual((bits & abi.DECSPECIAL) != 0, realIsSpecial(&r));

        // A canonical single zero digit is zero iff it is not a special encoding.
        try std.testing.expectEqual(!realIsSpecial(&r), realIsZero(&r));

        // A non-zero coefficient is never the canonical zero, whatever the flags.
        var nz = r;
        nz.lsu[0] = 1;
        try std.testing.expect(!realIsZero(&nz));
    }
}

test "longIntegerIsPositiveAtMost bounds a positive single-limb integer" {
    var limbs = [_]abi.MpLimb{0};
    var z: abi.Mpz = .{ ._mp_alloc = 1, ._mp_size = 0, ._mp_d = &limbs[0] };

    // Zero and negative are never a positive bounded value.
    z._mp_size = 0;
    try std.testing.expect(!longIntegerIsPositiveAtMost(&z, 4096));
    z._mp_size = -1;
    limbs[0] = 5;
    try std.testing.expect(!longIntegerIsPositiveAtMost(&z, 4096));

    // Positive, within or at the bound.
    z._mp_size = 1;
    limbs[0] = 1;
    try std.testing.expect(longIntegerIsPositiveAtMost(&z, 4096));
    limbs[0] = 4096;
    try std.testing.expect(longIntegerIsPositiveAtMost(&z, 4096));

    // Positive but over the bound.
    limbs[0] = 4097;
    try std.testing.expect(!longIntegerIsPositiveAtMost(&z, 4096));

    // Two or more limbs exceed any single-limb bound.
    var big = [_]abi.MpLimb{ 1, 1 };
    z._mp_d = &big[0];
    z._mp_size = 2;
    try std.testing.expect(!longIntegerIsPositiveAtMost(&z, 4096));
}

test "samePtr compares addresses, not values" {
    var a: u32 = 7;
    var b: u32 = 7;
    try std.testing.expect(samePtr(&a, &a));
    try std.testing.expect(!samePtr(&a, &b));
}
