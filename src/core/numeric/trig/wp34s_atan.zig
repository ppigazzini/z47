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
// WP34S_Atan_75_compute (static)
// ===========================================================================
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

// Cached wrapper for WP34S_Atan. Returns the previous result when the input, the effective precision and the rounding mode
// all match; see Cache1.call.
var atanCache: Cache1 = .{};
fn WP34S_Atan_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const effDigits: i32 = if (realContext.digits > 39) 75 else 39; // the precision WP34S_Atan_75_compute forces, not the request
    atanCache.call(WP34S_Atan_75_compute, x, angle, effDigits, realContext);
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
var atan2Cache: Cache2 = .{};
fn WP34S_Atan2_75_helper(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Atan2_75_compute computes at
    atan2Cache.call(WP34S_Atan2_75_compute, y, x, atan, effDigits, realContext);
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
var asinCache: Cache1 = .{};
fn WP34S_Asin_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Asin_75_compute computes at
    asinCache.call(WP34S_Asin_75_compute, x, angle, effDigits, realContext);
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
var acosCache: Cache1 = .{};
fn WP34S_Acos_75_helper(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    const effDigits: i32 = if (realContext.digits > 75) 75 else realContext.digits; // the precision WP34S_Acos_75_compute computes at
    acosCache.call(WP34S_Acos_75_compute, x, angle, effDigits, realContext);
}

pub fn C47_WP34S_Acos(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (runtime.option_xfn_1000 and realContext.digits >= 1071) {
        C47do_WP34S_Acos_1071temp(x, angle, realContext);
    } else {
        WP34S_Acos_75_helper(x, angle, realContext);
    }
}
