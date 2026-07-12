// SPDX-License-Identifier: GPL-3.0-only
//
// WP34S inverse-circular functions (atan / atan2 / asin / acos), split out of
// math_wp34s.zig to break up that ~2600-line grab-bag. This family is fully
// self-contained: it calls no forward-trig or gamma function, only the shared
// low-level real helpers and constant accessors, which stay single-sourced in
// math_wp34s.zig (their constant-blob offsets are remapped on every pin advance,
// so duplicating them would double that sync cost) and are aliased here via a
// benign circular import. The owner keeps thin pub-export C-ABI wrappers and
// delegates; the four WP34S atan oracles gate byte-exactness. Transcription is
// verbatim (only the four exported entry points drop their C-ABI qualifiers to
// become the plain pub fns the owner's wrappers call).

const owner = @import("../special/wp34s.zig");
const real_t = owner.real_t;
const realContext_t = owner.realContext_t;
const TaylorIterationMax = owner.TaylorIterationMax;
const BigReal = owner.BigReal;
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
            _ = progressHalfSecUpdate_Integer(halfSec_timed, "Taylor Iter", epsilonDigits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        if (exitKeyWaiting()) {
            _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", i, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
            break;
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
// WP34S_Atan_75temp (static)
// ===========================================================================
fn WP34S_Atan_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var doEpsilon: bool = false;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var a2: real_t = undefined;
    var t: real_t = undefined;
    var j: real_t = undefined;
    var z: real_t = undefined;
    var last: real_t = undefined;
    var epsilon: real_t = undefined;
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

    if (!doAtan(&a, angle, &a2, &t, &j, &z, x, &b, &epsilon, &last, doEpsilon, epsilonDigits, &doubles, &invert, &neg, realContext)) {
        realContext.digits = savedContextDigits;
        return; // NaN
    }
    realContext.digits = savedContextDigits;
}

// ===========================================================================
// C47do_WP34S_Atan_1071temp (static)
// ===========================================================================
fn C47do_WP34S_Atan_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var a_buf: BigReal(1071) = .{};
    var b_buf: BigReal(1071) = .{};
    var a2_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    var j_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    var last_buf: BigReal(1071) = .{};
    var epsilon_buf: BigReal(1071) = .{};
    var doubles: i32 = 0;
    var invert: c_int = undefined;
    var neg: c_int = undefined;
    if (!doAtan(a_buf.ptr(), angle, a2_buf.ptr(), t_buf.ptr(), j_buf.ptr(), z_buf.ptr(), x, b_buf.ptr(), epsilon_buf.ptr(), last_buf.ptr(), true, 1040, &doubles, &invert, &neg, realContext)) {
        return; // NaN
    }
}

// ===========================================================================
// C47_WP34S_Atan
// ===========================================================================
pub fn C47_WP34S_Atan(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Atan_1071temp(x, angle, realContext);
    } else {
        WP34S_Atan_75temp(x, angle, realContext);
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
// WP34S_Atan2_75temp / 1071temp (static) + dispatcher
// ===========================================================================
fn WP34S_Atan2_75temp(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    var r: real_t = undefined;
    var t: real_t = undefined;
    if (!doAtan2(y, x, atan, &r, &t, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Atan2_1071temp(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    var r_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    if (!doAtan2(y, x, atan, r_buf.ptr(), t_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub fn C47_WP34S_Atan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Atan2_1071temp(y, x, atan, realContext);
    } else {
        WP34S_Atan2_75temp(y, x, atan, realContext);
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

fn WP34S_Asin_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAsin(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Asin_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    if (!doAsin(x, angle, abx_buf.ptr(), z_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub fn C47_WP34S_Asin(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Asin_1071temp(x, angle, realContext);
    } else {
        WP34S_Asin_75temp(x, angle, realContext);
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

fn WP34S_Acos_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAcos(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Acos_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    if (!doAcos(x, angle, abx_buf.ptr(), z_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub fn C47_WP34S_Acos(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Acos_1071temp(x, angle, realContext);
    } else {
        WP34S_Acos_75temp(x, angle, realContext);
    }
}
