// SPDX-License-Identifier: GPL-3.0-only
//
// Pure PCG32 (XSH-RR 64/32) permuted-congruential generator, lifted from
// math_random_primitives.zig. The state advance, the xorshift+rotate output
// permutation, and the Lemire-style bounded rejection sampler depend on nothing
// but plain u32/u64 arithmetic, so they live here as a std-only module exercised
// natively under `zig build test:unit`, reachable as abi.pcg32.
//
// The owner keeps the calculator-global `pcg32_global` rng state and the
// real_t-producing realRandomU01; it threads the global's {state, inc} through
// these stateless kernels and writes the advanced state back. Because inc is
// constant and state is single-threaded, writing the advanced state back once is
// identical to the C's per-call mutation.
//
// z47's generator is the canonical pcg-c-basic algorithm (multiplier
// 6364136223846793005; (32-rot)&31 == the reference's (-rot)&31), so the native
// test below pins the published reference output vectors -- a check against the
// upstream PCG reference, not just this transcription.

const std = @import("std");

const PCG_MULTIPLIER: u64 = 6364136223846793005;

/// One PCG32 step: the u32 output permutation of `state` plus the advanced state.
/// The output is derived from the INCOMING state (as in pcg32_random_r), and
/// `next_state` is what the rng's state becomes after the call.
pub const Step = struct { value: u32, next_state: u64 };

pub fn random(state: u64, inc: u64) Step {
    const xorshifted: u32 = @truncate(((state >> 18) ^ state) >> 27);
    const rot: u5 = @intCast((state >> 59) & 31);
    const inv_rot: u5 = @intCast((32 - @as(u6, rot)) & 31);
    return .{
        .value = (xorshifted >> rot) | (xorshifted << inv_rot),
        .next_state = state *% PCG_MULTIPLIER +% inc,
    };
}

/// Seed an rng (pcg32_srandom_r): returns the {state, inc} a freshly seeded
/// generator holds. The two intermediate outputs are discarded, as in the C.
pub const Seeded = struct { state: u64, inc: u64 };

pub fn seed(initstate: u64, initseq: u64) Seeded {
    const inc = (initseq << 1) | 1;
    var state: u64 = 0;
    state = random(state, inc).next_state; // advance from state 0 using inc
    state +%= initstate;
    state = random(state, inc).next_state;
    return .{ .state = state, .inc = inc };
}

/// A bounded sample plus the advanced state (the Lemire-style multiply/reject
/// scheme from boundedRand). Draws in [0, s).
pub const Bounded = struct { value: u32, next_state: u64 };

pub fn bounded(state: u64, inc: u64, s: u32) Bounded {
    var st = state;
    var step = random(st, inc);
    st = step.next_state;
    var rand = step.value;

    const initial_product = @as(u64, s) * @as(u64, rand);
    const integer_part: u32 = @intCast(initial_product >> 32);
    var fractional_part: u32 = @truncate(initial_product);

    if (fractional_part <= 1 + ~s) {
        return .{ .value = integer_part, .next_state = st };
    }

    var iterations: u4 = 0;
    while (iterations < 10) : (iterations += 1) {
        step = random(st, inc);
        st = step.next_state;
        rand = step.value;
        const product = @as(u64, s) * @as(u64, rand);
        const extra_fraction: u32 = @intCast(product >> 32);

        fractional_part +%= extra_fraction;
        if (fractional_part < extra_fraction) {
            return .{ .value = integer_part + 1, .next_state = st };
        }
        if (fractional_part != 0xffff_ffff) {
            return .{ .value = integer_part, .next_state = st };
        }

        fractional_part = @truncate(product);
    }

    return .{ .value = integer_part, .next_state = st };
}

// ===========================================================================
// Tests -- native (run under `zig build test:unit`).
// ===========================================================================
const testing = std.testing;

test "canonical pcg-c-basic reference vectors (seed 42, 54)" {
    // The published pcg32 demo output for pcg32_srandom_r(&rng, 42u, 54u).
    var s = seed(42, 54);
    const expected = [_]u32{ 0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e };
    for (expected) |want| {
        const r = random(s.state, s.inc);
        try testing.expectEqual(want, r.value);
        s.state = r.next_state;
    }
}

test "seed is deterministic and initseq-sensitive" {
    const a = seed(42, 54);
    const b = seed(42, 54);
    try testing.expectEqual(a.state, b.state);
    try testing.expectEqual(a.inc, b.inc);
    const c = seed(42, 55); // a different stream selector
    try testing.expect(a.inc != c.inc);
    // inc is always odd (the (initseq<<1)|1 construction).
    try testing.expectEqual(@as(u64, 1), a.inc & 1);
}

test "bounded stays in [0, s) and advances the state" {
    var s = seed(123, 1);
    var i: usize = 0;
    while (i < 500) : (i += 1) {
        const before = s.state;
        const r = bounded(s.state, s.inc, 6); // a die roll
        try testing.expect(r.value < 6);
        try testing.expect(r.next_state != before);
        s.state = r.next_state;
    }
}

test "bounded with s == 1 always yields 0" {
    var s = seed(7, 7);
    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const r = bounded(s.state, s.inc, 1);
        try testing.expectEqual(@as(u32, 0), r.value);
        s.state = r.next_state;
    }
}
