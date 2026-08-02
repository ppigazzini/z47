// SPDX-License-Identifier: GPL-3.0-only
//
// Pure WP34S short-integer *mode* arithmetic, lifted from frontier_integers.zig
// (src/c47/integers.c). Where abi.int_math holds the mode-free primitives
// (gcd/isqrt/modpow), these interpret a u64 word under a short-integer mode
// (unsigned / 1's-complement / 2's-complement / sign-magnitude) with a mask +
// sign bit, and compute the value/overflow decisions the WP34S_int* commands need.
//
// The calculator mode, mask, sign bit and word size are threaded in as the
// IntMode parameter (never read from a global), and every FLAG_OVERFLOW side
// effect is RETURNED rather than set -- so this stays a std-only, deterministic
// module that `zig build test:unit` exercises natively, reachable as
// `abi.shortint_arith` from any owner. frontier_integers keeps its global reads
// and flag writes and delegates the raw arithmetic here (cf. abi/int_math and
// abi/float_format for the same seam-and-delegate pattern).

const std = @import("std");

// Short-integer interpretation modes (SIM_* in integers.c / frontier_integers.zig).
pub const UNSIGNED: u8 = 0;
pub const ONES_COMPLEMENT: u8 = 1;
pub const TWOS_COMPLEMENT: u8 = 2;
pub const SIGN_MAGNITUDE: u8 = 3;

/// The active short-integer interpretation. `word_size` is consulted only by
/// powerHelper; the value/overflow primitives use mode/mask/sign_bit.
pub const IntMode = struct {
    mode: u8,
    mask: u64,
    sign_bit: u64,
    word_size: u8 = 0,
};

/// A decoded word: its magnitude and a 0/1 sign (matching the C `int sign`).
pub const Extracted = struct { value: u64, sign: i32 };

/// Decode a stored word into a magnitude + sign per the mode (WP34S_extract_value).
pub fn extractValue(m: IntMode, val: u64) Extracted {
    var value: u64 = val & m.mask;
    var sign: i32 = undefined;

    if (m.mode == UNSIGNED) {
        return .{ .value = value, .sign = 0 };
    }

    if ((value & m.sign_bit) != 0) {
        sign = 1;
        if (m.mode == TWOS_COMPLEMENT) {
            value = 0 -% value;
        } else if (m.mode == ONES_COMPLEMENT) {
            value = ~value;
        } else { // SIGN_MAGNITUDE
            value ^= m.sign_bit;
        }
    } else {
        sign = 0;
    }

    return .{ .value = value & m.mask, .sign = sign };
}

/// Re-encode a magnitude + sign back into a stored word (WP34S_build_value).
/// Returns the i64 bit-pattern the C routine returns; callers mask/@bitCast as
/// they did around the original.
pub fn buildValue(m: IntMode, x: u64, sign: i32) i64 {
    const value: u64 = x & m.mask;

    if (sign == 0 or m.mode == UNSIGNED) {
        return @bitCast(value);
    }
    if (m.mode == TWOS_COMPLEMENT) {
        return @bitCast((0 -% value) & m.mask);
    }
    if (m.mode == ONES_COMPLEMENT) {
        return @bitCast((~value) & m.mask);
    }
    return @bitCast(value | m.sign_bit); // SIGN_MAGNITUDE
}

/// A masked product plus a 0/1 overflow flag (WP34S_multiply_with_overflow).
pub const Multiplied = struct { product: u64, overflow: i32 };

/// Masked multiply with overflow detection. `overflow_in` carries an
/// already-latched overflow (the C code only ever raises it, never lowers it).
pub fn multiplyWithOverflow(m: IntMode, multiplier: u64, multiplicand: u64, overflow_in: i32) Multiplied {
    const product: u64 = (multiplier *% multiplicand) & m.mask;
    var overflow = overflow_in;

    if (overflow == 0 and multiplicand != 0) {
        const tbm: u64 = if (m.mode == UNSIGNED) 0 else m.sign_bit;
        if ((product & tbm) != 0 or product / multiplicand != multiplier) {
            overflow = 1;
        }
    }
    return .{ .product = product, .overflow = overflow };
}

/// Add/subtract overflow decision for matching-sign add / differing-sign subtract
/// (WP34S_calc_overflow). Returns whether the op overflows; `null` means the mode
/// byte is out of range (the caller shows the WP34S bug screen and treats it as no
/// overflow, exactly as the C default branch did).
pub fn calcOverflow(m: IntMode, xv: u64, yv: u64, neg: i32) ?bool {
    switch (m.mode) {
        UNSIGNED => {
            const u: u64 = (yv & (m.sign_bit - 1)) +% (xv & (m.sign_bit - 1));
            const i: i32 = @as(i32, if ((u & m.sign_bit) != 0) 1 else 0) +
                @as(i32, if ((xv & m.sign_bit) != 0) 1 else 0) +
                @as(i32, if ((yv & m.sign_bit) != 0) 1 else 0);
            return i > 1;
        },
        TWOS_COMPLEMENT => {
            const u: u64 = xv +% yv;
            if (neg != 0 and u == m.sign_bit) {
                return false;
            }
            if ((m.sign_bit & u) != 0) {
                return true;
            }
            if ((xv == m.sign_bit and yv != 0) or (yv == m.sign_bit and xv != 0)) {
                return true;
            }
            return false;
        },
        SIGN_MAGNITUDE, ONES_COMPLEMENT => {
            return (m.sign_bit & (xv +% yv)) != 0;
        },
        else => return null,
    }
}

/// A computed power plus a 0/1 overflow flag (WP34S_int_power_helper).
pub const Powered = struct { power: u64, overflow: i32 };

/// Square-and-multiply exponentiation with masked-multiply overflow tracking.
/// Consults `m.word_size` for the iteration bound, exactly as the C routine did.
pub fn powerHelper(m: IntMode, base_in: u64, exponent_in: u64, overflow_in: i32) Powered {
    var base = base_in;
    var exponent = exponent_in;
    var overflow = overflow_in;
    var power: u64 = 1;
    var i: u32 = 0;
    var overflow_next: i32 = 0;

    while (i < m.word_size and exponent != 0) : (i += 1) {
        if ((exponent & 1) != 0) {
            if (overflow_next != 0) {
                overflow = 1;
            }
            const r = multiplyWithOverflow(m, power, base, overflow);
            power = r.product;
            overflow = r.overflow;
        }
        exponent >>= 1;

        if (exponent != 0) {
            const r = multiplyWithOverflow(m, base, base, overflow_next);
            base = r.product;
            overflow_next = r.overflow;
        }
    }

    return .{ .power = power, .overflow = overflow };
}

// ===========================================================================
// Tests -- native, C-oracle-independent (run under `zig build test:unit`).
// An 8-bit word (mask 0xFF, sign bit 0x80) exercises every mode's edges.
// ===========================================================================
const testing = std.testing;

fn mode8(mode: u8) IntMode {
    return .{ .mode = mode, .mask = 0xFF, .sign_bit = 0x80, .word_size = 8 };
}

test "extractValue: unsigned keeps the whole word, sign 0" {
    const r = extractValue(mode8(UNSIGNED), 0xFF);
    try testing.expectEqual(@as(u64, 0xFF), r.value);
    try testing.expectEqual(@as(i32, 0), r.sign);
    // High bits above the word are masked off.
    try testing.expectEqual(@as(u64, 0x7F), extractValue(mode8(UNSIGNED), 0x1_7F).value);
}

test "extractValue: -1 has magnitude 1 in every signed mode" {
    // 2's-compl 0xFF, 1's-compl 0xFE, sign-mag 0x81 all encode -1 in 8 bits.
    inline for (.{ .{ TWOS_COMPLEMENT, 0xFF }, .{ ONES_COMPLEMENT, 0xFE }, .{ SIGN_MAGNITUDE, 0x81 } }) |c| {
        const r = extractValue(mode8(c[0]), c[1]);
        try testing.expectEqual(@as(u64, 1), r.value);
        try testing.expectEqual(@as(i32, 1), r.sign);
    }
}

test "extractValue: a positive signed word decodes to itself, sign 0" {
    const r = extractValue(mode8(TWOS_COMPLEMENT), 0x7F);
    try testing.expectEqual(@as(u64, 0x7F), r.value);
    try testing.expectEqual(@as(i32, 0), r.sign);
}

test "buildValue inverts extractValue for every 8-bit word and mode" {
    inline for (.{ UNSIGNED, ONES_COMPLEMENT, TWOS_COMPLEMENT, SIGN_MAGNITUDE }) |mode| {
        const m = mode8(mode);
        var x: u64 = 0;
        while (x <= 0xFF) : (x += 1) {
            const e = extractValue(m, x);
            const back: u64 = @as(u64, @bitCast(buildValue(m, e.value, e.sign))) & m.mask;
            try testing.expectEqual(x, back);
        }
    }
}

test "multiplyWithOverflow: exact product, no overflow" {
    const r = multiplyWithOverflow(mode8(UNSIGNED), 3, 4, 0);
    try testing.expectEqual(@as(u64, 12), r.product);
    try testing.expectEqual(@as(i32, 0), r.overflow);
}

test "multiplyWithOverflow: product exceeding the word raises overflow" {
    const r = multiplyWithOverflow(mode8(UNSIGNED), 16, 16, 0); // 256 -> 0 mod 256
    try testing.expectEqual(@as(u64, 0), r.product);
    try testing.expectEqual(@as(i32, 1), r.overflow);
}

test "multiplyWithOverflow: a signed product touching the sign bit overflows" {
    // 8-bit 2's-compl: 64 * 2 = 128 lands on the sign bit -> overflow.
    const r = multiplyWithOverflow(mode8(TWOS_COMPLEMENT), 64, 2, 0);
    try testing.expectEqual(@as(u64, 0x80), r.product);
    try testing.expectEqual(@as(i32, 1), r.overflow);
}

test "multiplyWithOverflow: a latched overflow is never lowered" {
    const r = multiplyWithOverflow(mode8(UNSIGNED), 3, 4, 1);
    try testing.expectEqual(@as(i32, 1), r.overflow);
}

test "calcOverflow: unsigned carry out of the top bit" {
    try testing.expectEqual(@as(?bool, true), calcOverflow(mode8(UNSIGNED), 0xFF, 0x01, 0));
    try testing.expectEqual(@as(?bool, false), calcOverflow(mode8(UNSIGNED), 0x01, 0x01, 0));
}

test "calcOverflow: signed add crossing the range overflows" {
    // 64 + 64 = 128 exceeds the 8-bit 2's-compl max (127).
    try testing.expectEqual(@as(?bool, true), calcOverflow(mode8(TWOS_COMPLEMENT), 64, 64, 0));
    try testing.expectEqual(@as(?bool, false), calcOverflow(mode8(TWOS_COMPLEMENT), 1, 1, 0));
}

test "calcOverflow: the INT_MIN special case (neg, sum == sign bit) does not overflow" {
    try testing.expectEqual(@as(?bool, false), calcOverflow(mode8(TWOS_COMPLEMENT), 0x80, 0, 1));
}

test "calcOverflow: an out-of-range mode returns null (bug-screen sentinel)" {
    try testing.expectEqual(@as(?bool, null), calcOverflow(mode8(7), 1, 1, 0));
}

test "powerHelper: small exact power" {
    const r = powerHelper(mode8(UNSIGNED), 2, 3, 0);
    try testing.expectEqual(@as(u64, 8), r.power);
    try testing.expectEqual(@as(i32, 0), r.overflow);
}

test "powerHelper: a power exceeding the word raises overflow" {
    const r = powerHelper(mode8(UNSIGNED), 2, 8, 0); // 256 does not fit in 8 bits
    try testing.expectEqual(@as(i32, 1), r.overflow);
}

test "powerHelper: exponent 0 yields 1 with no iterations" {
    const r = powerHelper(mode8(UNSIGNED), 5, 0, 0);
    try testing.expectEqual(@as(u64, 1), r.power);
    try testing.expectEqual(@as(i32, 0), r.overflow);
}
