// SPDX-License-Identifier: GPL-3.0-only
//
// WP34S inverse-circular functions (atan / atan2 / asin / acos), split out of
// wp34s.zig to break up that ~2600-line grab-bag. This family is fully
// self-contained: it calls no forward-trig or gamma function, only the shared
// low-level real helpers and constant accessors, which stay single-sourced in
// wp34s.zig (their constant-blob offsets are remapped on every pin advance,
// so duplicating them would double that sync cost) and are aliased here via a
// benign circular import. The owner keeps thin pub-export C-ABI wrappers and
// delegates; the four WP34S atan oracles gate byte-exactness. Transcription is
// verbatim (only the four exported entry points drop their C-ABI qualifiers to
// become the plain pub fns the owner's wrappers call).
//
// wp34s.c wraps each of the four 1071-digit helpers, and the `digits >= 1071`
// arm of each dispatcher that reaches it, in `#if defined(OPTION_XFN_1000)`, so
// without the option the four dispatchers are unconditional 75-digit calls.
// defines.h #undef's OPTION_XFN_1000 for every DM42 build ("does not work on
// DM42, due to stack constraint"), which is also what keeps the 1071-digit
// bodies out of that image.

const abi = @import("abi");
const owner = @import("../special/wp34s.zig");
const real_t = owner.real_t;
const realContext_t = owner.realContext_t;
const TaylorIterationMax = owner.TaylorIterationMax;
const BigReal = owner.BigReal;
const realGetExponent = owner.realGetExponent;
const mallocBigReal = owner.mallocBigReal;
const freeBigReal = owner.freeBigReal;
const runtime = @import("../command_wrappers/runtime.zig");
// The abort below is !PC_BUILD only; the host runs the loop to completion.
const is_dmcp_build = @import("builtin").target.os.tag == .freestanding;
const formatEminusD = owner.formatEminusD;
const stringToReal = owner.stringToReal;
const uInt32ToReal = owner.uInt32ToReal;
const realAdd = owner.realAdd;
const realChangeSign = owner.realChangeSign;
const realCopy = owner.realCopy;
const realCopyAbs = owner.realCopyAbs;
const realDivide = owner.realDivide;
const realIsInfinite = owner.realIsInfinite;
const realIsNaN = owner.realIsNaN;
const realMinus = owner.realMinus;
const realMultiply = owner.realMultiply;
const realPlus = owner.realPlus;
const realSetNegativeSign = owner.realSetNegativeSign;
const realSetZero = owner.realSetZero;
const realSquareRoot = owner.realSquareRoot;
const realSubtract = owner.realSubtract;
const const_0 = owner.const_0;
const const_1 = owner.const_1;
const const_1on10 = owner.const_1on10;
const const_2 = owner.const_2;
const const39_pi = owner.const39_pi;
const const39_piOn2 = owner.const39_piOn2;
const const39_piOn4 = owner.const39_piOn4;
const const39_3piOn4 = owner.const39_3piOn4;
const const75_pi = owner.const75_pi;
const const75_piOn2 = owner.const75_piOn2;
const const75_piOn4 = owner.const75_piOn4;
const const75_3piOn4 = owner.const75_3piOn4;
const const1071_pi = owner.const1071_pi;
const const1071_piOn2 = owner.const1071_piOn2;
const const1071_piOn4 = owner.const1071_piOn4;
const const1071_3piOn4 = owner.const1071_3piOn4;
const const_1on5 = owner.const_1on5;
const const39_1on3 = owner.const39_1on3;
const const39_1on7 = owner.const39_1on7;
const const39_1on9 = owner.const39_1on9;
const const39_1on11 = owner.const39_1on11;
const const39_1on13 = owner.const39_1on13;
const const39_1on15 = owner.const39_1on15;
const const39_atan1on10 = owner.const39_atan1on10;
const const39_atan2on10 = owner.const39_atan2on10;
const const39_atan3on10 = owner.const39_atan3on10;
const const39_atan4on10 = owner.const39_atan4on10;
const const39_atan5on10 = owner.const39_atan5on10;
const const39_atan6on10 = owner.const39_atan6on10;
const const39_atan7on10 = owner.const39_atan7on10;
const const39_atan8on10 = owner.const39_atan8on10;
const const39_atan9on10 = owner.const39_atan9on10;
const const39_atanP08 = owner.const39_atanP08;
const const39_atanP09 = owner.const39_atanP09;
const const39_atanP10 = owner.const39_atanP10;
const const39_atanP11 = owner.const39_atanP11;
const const39_atanP12 = owner.const39_atanP12;
const ERROR_SOLVER_ABORT = owner.ERROR_SOLVER_ABORT;
const NIM_REGISTER_LINE = owner.NIM_REGISTER_LINE;
const REGISTER_T = owner.REGISTER_T;
const checkHalfSec = owner.checkHalfSec;
const displayCalcErrorMessage = owner.displayCalcErrorMessage;
const exitKeyWaiting = owner.exitKeyWaiting;
const halfSec_clearT = owner.halfSec_clearT;
const halfSec_clearZ = owner.halfSec_clearZ;
const halfSec_disp = owner.halfSec_disp;
const halfSec_force = owner.halfSec_force;
const halfSec_timed = owner.halfSec_timed;
const math_comparison_reals = owner.math_comparison_reals;
const progressHalfSecUpdate_Integer = owner.progressHalfSecUpdate_Integer;
const realIsNegative = owner.realIsNegative;
const realIsPositive = owner.realIsPositive;
const realIsZero = owner.realIsZero;
const realSetNaN = owner.realSetNaN;

// ===========================================================================
// doAtan (static)
// ===========================================================================
fn doAtan(
    a: *align(1) real_t,
    angle: *align(1) real_t,
    a2: *align(1) real_t,
    t: *align(1) real_t,
    j: *align(1) real_t,
    z: *align(1) real_t,
    x: *align(1) const real_t,
    b: *align(1) real_t,
    epsilon: *align(1) real_t,
    last: *align(1) real_t,
    doEpsilon: bool,
    epsilonDigits: i32,
    doubles: *i32,
    invert: *c_int,
    neg: *c_int,
    realContext: *realContext_t,
) bool {
    var conditionToKeepIterating: bool = false;
    var tmpEpsilon: [16]u8 = undefined;
    if (doEpsilon) {
        stringToReal(formatEminusD(&tmpEpsilon, epsilonDigits), epsilon, realContext);
    }

    neg.* = @intFromBool(realIsNegative(x));

    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }

    realCopy(x, a);

    // arrange for a >= 0
    if (neg.* != 0) {
        realChangeSign(a);
    }

    // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
    invert.* = @intFromBool(math_comparison_reals.realCompareGreaterThan(@alignCast(a), @alignCast(const_1())));
    if (invert.* != 0) {
        realDivide(const_1(), a, a, realContext);
    }

    // Range reduce using tan(x/2) = tan(x)/(1+sqrt(1+tan(x)^2))
    {
        var n: i32 = 0;
        while (n < TaylorIterationMax) : (n += 1) {
            if (!doEpsilon and math_comparison_reals.realCompareLessEqual(@alignCast(a), @alignCast(const_1on10()))) {
                break;
            } else if (doEpsilon and math_comparison_reals.realCompareLessEqual(@alignCast(a), @alignCast(const_1on10()))) {
                break;
            }

            doubles.* += 1;
            // a = a/(1+sqrt(1+a^2)) -- at most 3 iterations.
            realMultiply(a, a, b, realContext);
            realAdd(b, const_1(), b, realContext);
            realSquareRoot(b, b, realContext);
            realAdd(b, const_1(), b, realContext);
            realDivide(a, b, a, realContext);
        }
    }

    // Now Taylor series: atan(x) = x(1-x^2/3+x^4/5-...)
    uInt32ToReal(3, angle);
    uInt32ToReal(5, j);
    realMultiply(a, a, a2, realContext); // a^2
    realCopy(a2, t);
    realDivide(t, angle, angle, realContext); // s = 1-t/3
    realSubtract(const_1(), angle, angle, realContext);

    var i: i32 = 0;
    while (true) {
        realCopy(angle, last);

        realMultiply(t, a2, t, realContext);
        realDivide(t, j, z, realContext);
        realAdd(angle, z, angle, realContext);

        realAdd(j, const_2(), j, realContext);

        realMultiply(t, a2, t, realContext);
        realDivide(t, j, z, realContext);
        realSubtract(angle, z, angle, realContext);

        realAdd(j, const_2(), j, realContext);

        if (doEpsilon) {
            realSubtract(angle, last, b, realContext);
            realCopyAbs(b, b);
            realSubtract(b, epsilon, b, realContext);
            conditionToKeepIterating = realIsPositive(b);
        } else {
            realSubtract(angle, last, b, realContext);
            realPlus(b, b, realContext);
            conditionToKeepIterating = !realIsZero(b);
        }

        if (owner.explicitTaylorIterVisibilitySelection and checkHalfSec()) {
            var ss: [100]u8 = undefined;
            abi.fmtBufZ(&ss, "Taylor Iter: {d}/{d}; Dig: {d}/", .{ i, TaylorIterationMax, -@as(i16, @truncate(realGetExponent(b))) });
            ss[40] = 0; // hard limit to what the screen shows
            _ = progressHalfSecUpdate_Integer(halfSec_timed, @ptrCast(&ss[0]), epsilonDigits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        // Firmware only: the host build runs the Taylor loop to completion.
        if (comptime is_dmcp_build) {
            if (exitKeyWaiting()) {
                _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", i, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
                break;
            }
        }

        i += 1;

        if (!(conditionToKeepIterating and i < TaylorIterationMax)) {
            break;
        }
    }

    realMultiply(angle, a, angle, realContext);

    while (doubles.* != 0) {
        realAdd(angle, angle, angle, realContext);
        doubles.* -= 1;
    }
    if (invert.* != 0) {
        realSubtract(if (realContext.digits > 51) const1071_piOn2() else const39_piOn2(), angle, angle, realContext);
    }
    if (neg.* != 0) {
        realChangeSign(angle);
    }
    return true;
}

// ===========================================================================
// Generic single-slot caches for the 1- and 2-input trig wrappers
// ===========================================================================
// Each cache is a single most-recent-call slot. The stored result is treated as a pure function of the key: the input
// value(s), the effective compute precision, and the rounding mode. Nothing else in realContext (emax/emin/clamp) changes
// an angle result, whose magnitude is always O(1), and the angular-mode conversion happens in the caller AFTER the cache,
// so the angular mode is deliberately not part of the key.
//
// The slots are global, so `call` writes the key and the result together AFTER computing, never a bare key before: a
// reentrant call (a display refresh computing another angle mid-computation, say) can only leave its OWN complete, correct
// pair, which the outer call then overwrites with its own -- there is no window where a stale key and a fresh result
// coexist. That ordering is why the wrappers need no in-progress flag and no scheduling assumption; do not stamp the key
// before the compute. A special result is never stored, so a hit is always a finite value.
//
// The zero sign is part of the key: realCompareIdentical is a byte compare, so -0 and +0 are different inputs, and 1 and
// 1.0 are too.
// The DM42 (OLD_HW) firmware has no room for the four slots: its .bss ends exactly at the DMCP system data block and they
// are 588 bytes past it. A hit returns what a recompute returns -- that is what upstream's CACHE_VERIFY build asserts --
// so on that board every call computes and the answers are unchanged.
const cache_slots_enabled = runtime.trig_result_cache;

const Cache1 = struct {
    valid: bool = false,
    digits: i32 = 0,
    round: i32 = 0,
    x: real_t = undefined,
    result: real_t = undefined,

    fn call(
        self: *Cache1,
        comptime compute: fn (*align(1) const real_t, *align(1) real_t, *realContext_t) void,
        x: *align(1) const real_t,
        out: *align(1) real_t,
        effDigits: i32,
        ctx: *realContext_t,
    ) void {
        var localX: real_t = undefined; // copied first, so `compute` is safe even when the caller aliases in == out
        realCopy(x, &localX);
        if (self.valid and effDigits == self.digits and ctx.round == self.round and runtime.realCompareIdentical(&self.x, &localX)) {
            realCopy(&self.result, out);
            return;
        }
        compute(&localX, out, ctx); // compute first: any nested call leaves its own complete pair
        realCopy(&localX, &self.x); // then stamp this call's key
        self.digits = effDigits;
        self.round = ctx.round;
        self.valid = false;
        if (!runtime.realIsSpecial(out)) { // and the result, together
            realCopy(out, &self.result);
            self.valid = true;
        }
    }
};

const Cache2 = struct {
    valid: bool = false,
    digits: i32 = 0,
    round: i32 = 0,
    y: real_t = undefined,
    x: real_t = undefined,
    result: real_t = undefined,

    fn call(
        self: *Cache2,
        comptime compute: fn (*align(1) const real_t, *align(1) const real_t, *align(1) real_t, *realContext_t) void,
        y: *align(1) const real_t,
        x: *align(1) const real_t,
        out: *align(1) real_t,
        effDigits: i32,
        ctx: *realContext_t,
    ) void {
        var localY: real_t = undefined;
        var localX: real_t = undefined;
        realCopy(y, &localY);
        realCopy(x, &localX);
        if (self.valid and effDigits == self.digits and ctx.round == self.round and
            runtime.realCompareIdentical(&self.y, &localY) and runtime.realCompareIdentical(&self.x, &localX))
        {
            realCopy(&self.result, out);
            return;
        }
        compute(&localY, &localX, out, ctx); // compute first (see Cache1.call)
        realCopy(&localY, &self.y); // then stamp the key
        realCopy(&localX, &self.x);
        self.digits = effDigits;
        self.round = ctx.round;
        self.valid = false;
        if (!runtime.realIsSpecial(out)) { // and the result, together
            realCopy(out, &self.result);
            self.valid = true;
        }
    }
};

// ===========================================================================
// atanEffectiveDigits / WP34S_Atan_table_compute (static)
// ===========================================================================
// The precision atan actually computes at. Requests above 39 go to the Taylor
// path at 75. At or below 39 the table path honours the request plus a couple of
// guard digits: about a dozen chained operations cost roughly one digit of
// accumulated rounding, measured as a steady 0.8 to 1.0 digits at every precision
// from 3 up to 39, so computing two beyond the request returns what the caller
// asked for with a digit to spare. The cap at 39 is why atan has always returned
// 38 correct digits to a 39 digit caller, table path or not.
//
// No lower floor: the loss is proportional, not a cliff, so a caller asking for
// little gets little quickly. Graph plotting narrows ctxtReal39 to
// significantDigits + 3, as low as 4, and pays for 6 rather than for 39.
//
// Both compute functions and the cache wrapper must agree on this, or the cache
// could hand a low precision result to a high precision request.
const ATAN_GUARD_DIGITS: i32 = 2;
fn atanEffectiveDigits(requestedDigits: i32) i32 {
    if (requestedDigits > 39) {
        return 75;
    }
    const withGuard = requestedDigits + ATAN_GUARD_DIGITS;
    return if (withGuard > 39) 39 else withGuard;
}

// atan(j/10) for j = 1..9; the ends are const_0 and const39_piOn4. The step must
// divide a power of ten so that j/step is exact at every working precision: a
// tenth is, 1/12 is not, and its rounding would break the identity the reduction
// rests on.
const ATAN_TABLE_STEP: i32 = 10;
fn atanTable(j: usize) *align(1) const real_t {
    return switch (j) {
        0 => const_0(),
        1 => const39_atan1on10(),
        2 => const39_atan2on10(),
        3 => const39_atan3on10(),
        4 => const39_atan4on10(),
        5 => const39_atan5on10(),
        6 => const39_atan6on10(),
        7 => const39_atan7on10(),
        8 => const39_atan8on10(),
        9 => const39_atan9on10(),
        else => const39_piOn4(),
    };
}

// P(v) with v = u*u, magnitudes only (the loop below negates v instead of
// tracking signs). Eight of the thirteen were constrained to the Taylor
// coefficients +-1/(2k+1) and only atanP08..12 left free for the fit. Eight
// constraints still land at 2.9e-41 against a 1e-40 budget, so they cost no extra
// term; a ninth would not fit. Holding the first at exactly 1 is what makes
// atan(x) come out as exactly x for tiny x rather than merely rounding to it.
const ATAN_COEFFICIENTS: i32 = 13;
fn atanPoly(k: usize) *align(1) const real_t {
    return switch (k) {
        0 => const_1(),
        1 => const39_1on3(),
        2 => const_1on5(),
        3 => const39_1on7(),
        4 => const39_1on9(),
        5 => const39_1on11(),
        6 => const39_1on13(),
        7 => const39_1on15(),
        8 => const39_atanP08(),
        9 => const39_atanP09(),
        10 => const39_atanP10(),
        11 => const39_atanP11(),
        else => const39_atanP12(),
    };
}

/// atan for requests at or below 39 digits.
///
/// Reduces through the addition formula against a tenth spaced table
///
///     a = |x|, and a > 1 is inverted by atan(a) = pi/2 - atan(1/a)
///     j = round(10a),  c = j/10,  u = (a - c)/(1 + a*c)   so |u| <= 1/20
///     atan(a) = atanTable[j] + u * P(u*u)
///
/// which costs one division where the Taylor path spent three square roots, and
/// then finishes with a fixed length polynomial instead of a convergence loop.
/// Horner starts below the top term once u is small enough that the leading terms
/// cannot reach the requested precision, so small arguments stay cheap.
///
/// Truncation error is 2.9e-41 as the coefficients are stored, an order of
/// magnitude under the 5e-40 the 39 digit table constants contribute anyway, so
/// the polynomial is not what limits the answer. At 39 digits this returns about
/// 38 correct digits, a little better than the Taylor path it replaces.
fn WP34S_Atan_table_compute(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    // Upstream declares these four REAL_T_ALLOC(name, 39), but the first thing the
    // function does is copy the caller's real_t whole, and decNumberCopyAbs copies
    // the SOURCE's digit count: a wide argument -- a long integer converted at 75
    // digits, say -- overruns a 39-digit buffer and corrupts the heap. Every write
    // after that is bounded by realContext->digits, which this path caps at 39, so
    // taking the full real_t here changes no value and only stops the overrun.
    const a_p = runtime.mallocReal(); // also the accumulator further down
    const u_p = runtime.mallocReal();
    const v_p = runtime.mallocReal();
    const c_p = runtime.mallocReal();
    defer {
        runtime.freeReal(a_p);
        runtime.freeReal(u_p);
        runtime.freeReal(v_p);
        runtime.freeReal(c_p);
    }

    if (a_p == null or u_p == null or v_p == null or c_p == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    const a = a_p.?;
    const u = u_p.?;
    const v = v_p.?;
    const c = c_p.?;

    if (realIsNaN(x)) {
        realSetNaN(angle);
        return;
    }

    const savedContextDigits = realContext.digits;
    realContext.digits = atanEffectiveDigits(savedContextDigits);

    const neg = realIsNegative(x); // kept: the result is negated again at the end
    realCopyAbs(x, a);

    const invert = math_comparison_reals.realCompareGreaterThan(@alignCast(a), @alignCast(const_1()));
    if (invert) {
        realDivide(const_1(), a, a, realContext); // 1/inf is 0, which lands on j = 0 and gives pi/2
    }

    // j = round(10a), always in [0, 10] and used directly as the index into
    // atanTable. c is borrowed for the scaled copy here and holds the table centre
    // from the next block on. Multiplying by ten in a decimal representation is
    // nothing but a shift of the exponent, so the scaling is free and exact; the
    // rounding is left to realToIntegralValue. a is |x| with anything above 1
    // inverted, and rounding 1/a can reach 1 but never pass it, so 10a stays inside
    // [0, 10] and no clamp is needed. realToInt32C47 cannot break that either:
    // every one of its failure paths returns 0.
    realCopy(a, c);
    c.exponent += 1;
    runtime.realToIntegralValue(@alignCast(c), @alignCast(c), runtime.DEC_ROUND_HALF_UP, realContext);
    const j: i32 = runtime.realToInt32C47(@alignCast(c), null);

    // c = j/10, exact for the same reason and for j = 0 too, since a zero stays a zero
    runtime.int32ToReal(j, @alignCast(c));
    c.exponent -= 1;
    realMultiply(a, c, v, realContext);
    realAdd(v, const_1(), v, realContext);
    realSubtract(a, c, u, realContext);
    realDivide(u, v, u, realContext);

    realMultiply(u, u, v, realContext); // v = u*u

    // v^k drops below the last digit being computed once k * |log10 v| passes that
    // many digits, so every coefficient above that index is dead weight. The + 6
    // keeps the cut a few digits clear of the rounding noise, at the cost of at
    // most one extra term.
    var top: i32 = ATAN_COEFFICIENTS - 1;
    if (realIsZero(v)) {
        top = 0;
    } else {
        const exponent: i32 = -realGetExponent(v);
        if (exponent > 0) {
            const needed = @divTrunc(realContext.digits + 6 + exponent - 1, exponent);
            if (needed < top) {
                top = needed;
            }
        }
    }

    // The series alternates: c0 - c1*v + c2*v^2 - ... = c0 - v*(c1 - v*(c2 - ...)).
    // Negating v turns every Horner step into the same acc*(-v) + c operation, so
    // atanPoly can hold plain magnitudes and neither the loop nor its seed needs to
    // track the sign.
    realChangeSign(v);
    realCopy(atanPoly(@intCast(top)), a);
    var k: i32 = top - 1;
    while (k >= 0) : (k -= 1) {
        realMultiply(a, v, a, realContext);
        realAdd(a, atanPoly(@intCast(k)), a, realContext);
    }
    realMultiply(a, u, a, realContext);
    realAdd(a, atanTable(@intCast(j)), angle, realContext);

    if (invert) {
        realSubtract(const39_piOn2(), angle, angle, realContext);
    }
    if (neg) {
        realChangeSign(angle);
    }

    realContext.digits = savedContextDigits;
}

// ===========================================================================
// WP34S_Atan_75_compute (static)
// ===========================================================================
// The Taylor series with sqrt halving, now reached only for requests above 39 digits.
fn WP34S_Atan_75_compute(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var doEpsilon: bool = false;

    // The eight working reals come from the heap, not the frame: eight
    // decNumbers at 60 bytes is 480 of this function's 656 byte frame, and it
    // sits on the integrand path of a plotted integral. The 1071 digit twin
    // below keeps its stack buffers. Mirrors upstream's REAL_T_ALLOC(name, 75)
    // block -- REAL_SIZE_IN_BYTES(75) is @sizeOf(real_t).
    const a_p = runtime.mallocReal();
    const b_p = runtime.mallocReal();
    const a2_p = runtime.mallocReal();
    const t_p = runtime.mallocReal();
    const j_p = runtime.mallocReal();
    const z_p = runtime.mallocReal();
    const last_p = runtime.mallocReal();
    const epsilon_p = runtime.mallocReal();
    defer {
        runtime.freeReal(a_p);
        runtime.freeReal(b_p);
        runtime.freeReal(a2_p);
        runtime.freeReal(t_p);
        runtime.freeReal(j_p);
        runtime.freeReal(z_p);
        runtime.freeReal(last_p);
        runtime.freeReal(epsilon_p);
    }

    var doubles: i32 = 0;
    var invert: c_int = undefined;
    var neg: c_int = undefined;
    const savedContextDigits = realContext.digits;
    var epsilonDigits: i32 = undefined;

    if (realContext.digits > 39) {
        realContext.digits = 75;
        epsilonDigits = 72;
        doEpsilon = true;
    } else {
        realContext.digits = 39;
        epsilonDigits = 39;
        doEpsilon = false;
    }

    if (a_p == null or b_p == null or a2_p == null or t_p == null or
        j_p == null or z_p == null or last_p == null or epsilon_p == null)
    {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        realContext.digits = savedContextDigits;
        return;
    }

    if (!doAtan(a_p.?, angle, a2_p.?, t_p.?, j_p.?, z_p.?, x, b_p.?, epsilon_p.?, last_p.?, doEpsilon, epsilonDigits, &doubles, &invert, &neg, realContext)) {
        realContext.digits = savedContextDigits;
        return; // NaN
    }
    realContext.digits = savedContextDigits;
}

// ===========================================================================
// C47do_WP34S_Atan_1071temp (static)
// ===========================================================================
// The eight working reals come from the heap, not the frame: eight 1071-digit
// decNumbers at 724 bytes each is 5792 bytes, nearly all of what was the largest
// frame in the build.
fn C47do_WP34S_Atan_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const a = mallocBigReal(1071);
    const b = mallocBigReal(1071);
    const a2 = mallocBigReal(1071);
    const t = mallocBigReal(1071);
    const j = mallocBigReal(1071);
    const z = mallocBigReal(1071);
    const last = mallocBigReal(1071);
    const epsilon = mallocBigReal(1071);
    defer {
        freeBigReal(a);
        freeBigReal(b);
        freeBigReal(a2);
        freeBigReal(t);
        freeBigReal(j);
        freeBigReal(z);
        freeBigReal(last);
        freeBigReal(epsilon);
    }
    if (a == null or b == null or a2 == null or t == null or j == null or z == null or last == null or epsilon == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    var doubles: i32 = 0;
    var invert: c_int = undefined;
    var neg: c_int = undefined;
    if (!doAtan(a.?, angle, a2.?, t.?, j.?, z.?, x, b.?, epsilon.?, last.?, true, 1040, &doubles, &invert, &neg, realContext)) {
        return; // NaN
    }
}

// The slots themselves. Held in a comptime-selected container so the board that does without them carries no .bss for
// them at all, rather than an unreachable branch over a live one.
const slots = if (cache_slots_enabled) struct {
    var atan: Cache1 = .{};
    var atan2: Cache2 = .{};
    var asin: Cache1 = .{};
    var acos: Cache1 = .{};
} else struct {};

// Cached wrapper for WP34S_Atan. Returns the previous result when the input, the effective precision and the rounding mode
// all match; see Cache1.call.
fn WP34S_Atan_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const effDigits: i32 = atanEffectiveDigits(realContext.digits); // the precision actually computed at, not the request
    // The table path serves every request at or below 39 digits; above it the
    // Taylor series at 75. Cache1.call takes its worker at comptime, so the choice
    // is a branch over two calls rather than a function value.
    if (effDigits > 39) {
        if (comptime !cache_slots_enabled) {
            WP34S_Atan_75_compute(x, angle, realContext);
            return;
        }
        slots.atan.call(WP34S_Atan_75_compute, x, angle, effDigits, realContext);
    } else {
        if (comptime !cache_slots_enabled) {
            WP34S_Atan_table_compute(x, angle, realContext);
            return;
        }
        slots.atan.call(WP34S_Atan_table_compute, x, angle, effDigits, realContext);
    }
}

// ===========================================================================
// C47_WP34S_Atan
// ===========================================================================
pub fn C47_WP34S_Atan(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (runtime.option_xfn_1000 and realContext.digits >= 1071) {
        C47do_WP34S_Atan_1071temp(x, angle, realContext);
    } else {
        WP34S_Atan_75_helper(x, angle, realContext);
    }
}

// pi-family selectors used by doAtan2 (the _pi/_piOn2/... macros).
inline fn pi_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_pi() else const75_pi()) else const39_pi();
}
inline fn piOn2_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_piOn2() else const75_piOn2()) else const39_piOn2();
}
inline fn piOn4_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_piOn4() else const75_piOn4()) else const39_piOn4();
}
inline fn threePiOn4_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_3piOn4() else const75_3piOn4()) else const39_3piOn4();
}

// ===========================================================================
// doAtan2 (static)
// ===========================================================================
fn doAtan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, r: *align(1) real_t, t: *align(1) real_t, realContext: *realContext_t) bool {
    const xNeg = realIsNegative(x);
    const yNeg = realIsNegative(y);

    if (realIsNaN(x) or realIsNaN(y)) {
        realSetNaN(atan);
        return false;
    }

    if (math_comparison_reals.realCompareEqual(@alignCast(y), @alignCast(const_0()))) {
        if (yNeg) {
            if (math_comparison_reals.realCompareEqual(@alignCast(x), @alignCast(const_0()))) {
                if (xNeg) {
                    realMinus(pi_d(realContext.digits), atan, realContext);
                } else {
                    realCopy(y, atan);
                }
            } else if (xNeg) {
                realMinus(pi_d(realContext.digits), atan, realContext);
            } else {
                realCopy(y, atan);
            }
        } else {
            if (math_comparison_reals.realCompareEqual(@alignCast(x), @alignCast(const_0()))) {
                if (xNeg) {
                    realCopy(pi_d(realContext.digits), atan);
                } else {
                    realSetZero(atan);
                }
            } else if (xNeg) {
                realCopy(pi_d(realContext.digits), atan);
            } else {
                realSetZero(atan);
            }
        }
        return true;
    }

    if (math_comparison_reals.realCompareEqual(@alignCast(x), @alignCast(const_0()))) {
        realCopy(piOn2_d(realContext.digits), atan);
        if (yNeg) {
            realSetNegativeSign(atan);
        }
        return true;
    }

    if (realIsInfinite(x)) {
        if (xNeg) {
            if (realIsInfinite(y)) {
                realCopy(threePiOn4_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            } else {
                realCopy(pi_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            }
        } else {
            if (realIsInfinite(y)) {
                realCopy(piOn4_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            } else {
                realSetZero(atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            }
        }
        return true;
    }

    if (realIsInfinite(y)) {
        realCopy(piOn2_d(realContext.digits), atan);
        if (yNeg) {
            realSetNegativeSign(atan);
        }
        return true;
    }

    realDivide(y, x, t, realContext);
    C47_WP34S_Atan(@ptrCast(t), @ptrCast(r), realContext);
    if (xNeg) {
        realCopy(pi_d(realContext.digits), t);
        if (yNeg) {
            realSetNegativeSign(t);
        }
    } else {
        realSetZero(t);
    }

    realAdd(r, t, atan, realContext);
    if (math_comparison_reals.realCompareEqual(@alignCast(atan), @alignCast(const_0())) and yNeg) {
        realSetNegativeSign(atan);
    }
    return true;
}

// ===========================================================================
// WP34S_Atan2_75_compute / 1071temp (static) + dispatcher
// ===========================================================================
fn WP34S_Atan2_75_compute(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    // These bodies work at real75; a wider caller context is narrowed for the
    // duration and put back on every exit.
    const savedContextDigits = realContext.digits;
    if (realContext.digits > 75) {
        realContext.digits = 75;
    }
    defer realContext.digits = savedContextDigits;
    var r: real_t = undefined;
    var t: real_t = undefined;
    if (!doAtan2(y, x, atan, &r, &t, realContext)) {
        return; // NaN
    }
}

// Two 1071-digit decNumbers at 724 bytes each were nearly the whole frame.
fn C47do_WP34S_Atan2_1071temp(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    const r = mallocBigReal(1071);
    const t = mallocBigReal(1071);
    defer {
        freeBigReal(r);
        freeBigReal(t);
    }
    if (r == null or t == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (!doAtan2(y, x, atan, r.?, t.?, realContext)) {
        return; // NaN
    }
}

// Cached wrapper for WP34S_Atan2. Returns the previous result when both inputs, the effective precision and the rounding
// mode match; see Cache2.call.
fn WP34S_Atan2_75_helper(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    if (comptime !cache_slots_enabled) {
        WP34S_Atan2_75_compute(y, x, atan, realContext);
        return;
    }
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Atan2_75_compute computes at
    slots.atan2.call(WP34S_Atan2_75_compute, y, x, atan, effDigits, realContext);
}

pub fn C47_WP34S_Atan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    if (runtime.option_xfn_1000 and realContext.digits >= 1071) {
        C47do_WP34S_Atan2_1071temp(y, x, atan, realContext);
    } else {
        WP34S_Atan2_75_helper(y, x, atan, realContext);
    }
}

// ===========================================================================
// doAsin (static) + dispatchers
// ===========================================================================
fn doAsin(x: *align(1) const real_t, angle: *align(1) real_t, abx: *align(1) real_t, z: *align(1) real_t, realContext: *realContext_t) bool {
    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }
    realCopyAbs(x, abx);
    if (math_comparison_reals.realCompareGreaterThan(@alignCast(abx), @alignCast(const_1()))) {
        realSetNaN(angle);
        return false;
    }
    // angle = 2*atan(x/(1+sqrt(1-x*x)))
    realMultiply(x, x, z, realContext);
    realSubtract(const_1(), z, z, realContext);
    realSquareRoot(z, z, realContext);
    realAdd(z, const_1(), z, realContext);
    realDivide(x, z, z, realContext);
    C47_WP34S_Atan(@ptrCast(z), @ptrCast(abx), realContext);
    realAdd(abx, abx, angle, realContext);
    return true;
}

fn WP34S_Asin_75_compute(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    // These bodies work at real75; a wider caller context is narrowed for the
    // duration and put back on every exit.
    const savedContextDigits = realContext.digits;
    if (realContext.digits > 75) {
        realContext.digits = 75;
    }
    defer realContext.digits = savedContextDigits;
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAsin(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Asin_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const abx = mallocBigReal(1071);
    const z = mallocBigReal(1071);
    defer {
        freeBigReal(abx);
        freeBigReal(z);
    }
    if (abx == null or z == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (!doAsin(x, angle, abx.?, z.?, realContext)) {
        return; // NaN
    }
}

// Cached wrapper for WP34S_Asin. See Cache1.call.
fn WP34S_Asin_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (comptime !cache_slots_enabled) {
        WP34S_Asin_75_compute(x, angle, realContext);
        return;
    }
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Asin_75_compute computes at
    slots.asin.call(WP34S_Asin_75_compute, x, angle, effDigits, realContext);
}

pub fn C47_WP34S_Asin(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (runtime.option_xfn_1000 and realContext.digits >= 1071) {
        C47do_WP34S_Asin_1071temp(x, angle, realContext);
    } else {
        WP34S_Asin_75_helper(x, angle, realContext);
    }
}

// ===========================================================================
// doAcos (static) + dispatchers
// ===========================================================================
fn doAcos(x: *align(1) const real_t, angle: *align(1) real_t, abx: *align(1) real_t, z: *align(1) real_t, realContext: *realContext_t) bool {
    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }
    realCopyAbs(x, abx);
    if (math_comparison_reals.realCompareGreaterThan(@alignCast(abx), @alignCast(const_1()))) {
        realSetNaN(angle);
        return false;
    }
    // angle = 2*atan((1-x)/sqrt(1-x*x))
    if (math_comparison_reals.realCompareEqual(@alignCast(x), @alignCast(const_1()))) {
        realSetZero(angle);
    } else {
        realMultiply(x, x, z, realContext);
        realSubtract(const_1(), z, z, realContext);
        realSquareRoot(z, z, realContext);
        realSubtract(const_1(), x, abx, realContext);
        realDivide(abx, z, z, realContext);
        C47_WP34S_Atan(@ptrCast(z), @ptrCast(abx), realContext);
        realAdd(abx, abx, angle, realContext);
    }
    return true;
}

fn WP34S_Acos_75_compute(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    // These bodies work at real75; a wider caller context is narrowed for the
    // duration and put back on every exit.
    const savedContextDigits = realContext.digits;
    if (realContext.digits > 75) {
        realContext.digits = 75;
    }
    defer realContext.digits = savedContextDigits;
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAcos(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Acos_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const abx = mallocBigReal(1071);
    const z = mallocBigReal(1071);
    defer {
        freeBigReal(abx);
        freeBigReal(z);
    }
    if (abx == null or z == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (!doAcos(x, angle, abx.?, z.?, realContext)) {
        return; // NaN
    }
}

// Cached wrapper for WP34S_Acos. See Cache1.call.
fn WP34S_Acos_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (comptime !cache_slots_enabled) {
        WP34S_Acos_75_compute(x, angle, realContext);
        return;
    }
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Acos_75_compute computes at
    slots.acos.call(WP34S_Acos_75_compute, x, angle, effDigits, realContext);
}

pub fn C47_WP34S_Acos(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (runtime.option_xfn_1000 and realContext.digits >= 1071) {
        C47do_WP34S_Acos_1071temp(x, angle, realContext);
    } else {
        WP34S_Acos_75_helper(x, angle, realContext);
    }
}
