// SPDX-License-Identifier: GPL-3.0-only
//
// WP34S forward-circular functions (reduceAngleToRange + the Cvt2RadSinCosTan /
// SinCosTanTaylor sin/cos/tan Taylor engine), split out of math_wp34s.zig to
// finish breaking up that grab-bag (the inverse-circular half is in
// math_wp34s_atan.zig). The shared low-level helpers -- offset-bearing constant
// accessors, real primitives, BigReal, formatEminusD, and the two mod functions
// this half reaches (mod2Pi / WP34S_Mod) -- stay single-sourced in the owner
// (their constant-blob offsets are remapped every pin advance) and are aliased
// here via a benign circular import. The owner keeps three thin pub-export C-ABI
// wrappers and delegates; the four WP34S trig oracles gate byte-exactness.
// Transcription is verbatim (the three exported entry points drop their C-ABI
// qualifiers to become the plain pub fns the wrappers call).

const owner = @import("math_wp34s.zig");
const BigReal = owner.BigReal;
const ERROR_SOLVER_ABORT = owner.ERROR_SOLVER_ABORT;
const NIM_REGISTER_LINE = owner.NIM_REGISTER_LINE;
const REGISTER_T = owner.REGISTER_T;
const TaylorIterationMax = owner.TaylorIterationMax;
const WP34S_Mod = owner.WP34S_Mod;
const amDMS = owner.amDMS;
const amDegree = owner.amDegree;
const amGrad = owner.amGrad;
const amMultPi = owner.amMultPi;
const amRadian = owner.amRadian;
const angularMode_t = owner.angularMode_t;
const checkHalfSec = owner.checkHalfSec;
const const1071_pi = owner.const1071_pi;
const const1071_piOn2 = owner.const1071_piOn2;
const const1071_piOn4 = owner.const1071_piOn4;
const const39_root2on2 = owner.const39_root2on2;
const const75_pi = owner.const75_pi;
const const75_piOn2 = owner.const75_piOn2;
const const75_piOn4 = owner.const75_piOn4;
const const_0 = owner.const_0;
const const_1 = owner.const_1;
const const_100 = owner.const_100;
const const_180 = owner.const_180;
const const_1on2 = owner.const_1on2;
const const_1on4 = owner.const_1on4;
const const_2 = owner.const_2;
const const_200 = owner.const_200;
const const_360 = owner.const_360;
const const_400 = owner.const_400;
const const_45 = owner.const_45;
const const_50 = owner.const_50;
const const_90 = owner.const_90;
const convertAngleFromTo = owner.convertAngleFromTo;
const displayCalcErrorMessage = owner.displayCalcErrorMessage;
const exitKeyWaiting = owner.exitKeyWaiting;
const formatEminusD = owner.formatEminusD;
const halfSec_clearT = owner.halfSec_clearT;
const halfSec_clearZ = owner.halfSec_clearZ;
const halfSec_disp = owner.halfSec_disp;
const halfSec_force = owner.halfSec_force;
const halfSec_timed = owner.halfSec_timed;
const math_comparison_reals = owner.math_comparison_reals;
const maxI32 = owner.maxI32;
const mod2Pi = owner.mod2Pi;
const progressHalfSecUpdate_Integer = owner.progressHalfSecUpdate_Integer;
const realAdd = owner.realAdd;
const realChangeSign = owner.realChangeSign;
const realCompare = owner.realCompare;
const realContext_t = owner.realContext_t;
const realCopy = owner.realCopy;
const realCopyAbs = owner.realCopyAbs;
const realDivide = owner.realDivide;
const realGetExponent = owner.realGetExponent;
const realIsNaN = owner.realIsNaN;
const realIsNegative = owner.realIsNegative;
const realIsZero = owner.realIsZero;
const realMultiply = owner.realMultiply;
const realPlus = owner.realPlus;
const realSetNaN = owner.realSetNaN;
const realSetNegativeSign = owner.realSetNegativeSign;
const realSetOne = owner.realSetOne;
const realSetPositiveSign = owner.realSetPositiveSign;
const realSubtract = owner.realSubtract;
const real_t = owner.real_t;
const stringToReal = owner.stringToReal;

// ===========================================================================
// reduceAngleToRange
// ===========================================================================
pub fn reduceAngleToRange(
    angle: *align(1) real_t,
    angle45: *(*align(1) const real_t),
    angle90: *(*align(1) const real_t),
    angle180: *(*align(1) const real_t),
    angularMode: *angularMode_t,
    savedContextDigits: i32,
    realContext: *realContext_t,
) void {
    switch (angularMode.*) {
        amRadian => {
            if (savedContextDigits >= 1071) {
                angle45.* = const1071_piOn4();
                angle90.* = const1071_piOn2();
                angle180.* = const1071_pi();
            } else {
                angle45.* = const75_piOn4();
                angle90.* = const75_piOn2();
                angle180.* = const75_pi();
            }
            mod2Pi(angle, angle, realContext); // mod(angle, 2pi) --> angle
        },
        amMultPi => {
            angle45.* = const_1on4();
            angle90.* = const_1on2();
            angle180.* = const_1();
            WP34S_Mod(angle, const_2(), angle, realContext); // mod(angle, 2) --> angle
        },
        amGrad => {
            angle45.* = const_50();
            angle90.* = const_100();
            angle180.* = const_200();
            WP34S_Mod(angle, const_400(), angle, realContext); // mod(angle, 400g) --> angle
        },
        amDegree, amDMS => {
            angle45.* = const_45();
            angle90.* = const_90();
            angle180.* = const_180();
            WP34S_Mod(angle, const_360(), angle, realContext); // mod(angle, 360) --> angle
            angularMode.* = amDegree;
        },
        else => {},
    }
}

// ===========================================================================
// doWP34S_SinCosTanTaylor (static)
// ===========================================================================
fn doWP34S_SinCosTanTaylor(
    angle: *align(1) real_t,
    sinNeg: *bool,
    cosNeg: *bool,
    swap: *bool,
    sinOut: ?*align(1) real_t,
    cosOut: ?*align(1) real_t,
    tanOut: ?*align(1) real_t,
    angularMode_arg: angularMode_t,
    savedContextDigits: i32,
    realContext: *realContext_t,
) void {
    var angularMode = angularMode_arg;
    var angle45: *align(1) const real_t = const_0();
    var angle90: *align(1) const real_t = const_0();
    var angle180: *align(1) const real_t = const_0();

    // sin(-x) = -sin(x), cos(-x) = cos(x)
    if (realIsNegative(angle)) {
        sinNeg.* = true;
        realSetPositiveSign(angle);
    }

    reduceAngleToRange(@ptrCast(angle), &angle45, &angle90, &angle180, &angularMode, savedContextDigits, realContext);

    // sin(180+x) = -sin(x), cos(180+x) = -cos(x)
    if (math_comparison_reals.realCompareGreaterEqual(@alignCast(angle), @alignCast(angle180))) { // angle >= 180
        realSubtract(angle, angle180, angle, realContext); // angle - 180 --> angle
        sinNeg.* = !(sinNeg.*);
        cosNeg.* = !(cosNeg.*);
    }

    // sin(90+x) = cos(x), cos(90+x) = -sin(x)
    if (math_comparison_reals.realCompareGreaterEqual(@alignCast(angle), @alignCast(angle90))) { // angle >= 90
        realSubtract(angle, angle90, angle, realContext); // angle - 90 --> angle
        swap.* = true;
        cosNeg.* = !(cosNeg.*);
    }

    // sin(90-x) = cos(x), cos(90-x) = sin(x)
    if (math_comparison_reals.realCompareEqual(@alignCast(angle), @alignCast(angle45))) { // angle == 45
        if (sinOut) |s| {
            realCopy(const39_root2on2(), s);
        }
        if (cosOut) |c| {
            realCopy(const39_root2on2(), c);
        }
        if (tanOut) |t| {
            realSetOne(t);
        }
    } else { // angle < 90
        if (math_comparison_reals.realCompareGreaterThan(@alignCast(angle), @alignCast(angle45))) { // angle > 45
            realSubtract(angle90, angle, angle, realContext); // 90 - angle --> angle
            swap.* = !(swap.*);
        }
        convertAngleFromTo(angle, angularMode, amRadian, realContext);
        if (savedContextDigits >= 1071) {
            C47_WP34S_SinCosTanTaylor_temp1071(angle, swap.*, if (swap.*) cosOut else sinOut, if (swap.*) sinOut else cosOut, tanOut, realContext);
        } else {
            C47_WP34S_SinCosTanTaylor_temp75(angle, swap.*, if (swap.*) cosOut else sinOut, if (swap.*) sinOut else cosOut, tanOut, realContext);
        }
    }

    realContext.digits = savedContextDigits;

    if (sinOut) |s| {
        if (sinNeg.*) {
            realSetNegativeSign(s);
            if (tanOut) |t| {
                realSetNegativeSign(t);
            }
        }
        if (realIsZero(s)) {
            realSetPositiveSign(s);
            if (tanOut) |t| {
                realSetPositiveSign(t);
            }
        }
        realPlus(s, s, realContext);
    }

    if (cosOut) |c| {
        if (cosNeg.*) {
            realSetNegativeSign(c);
            if (tanOut) |t| {
                realChangeSign(t);
            }
        }
        if (realIsZero(c)) {
            realSetPositiveSign(c);
        }
        realPlus(c, c, realContext);
    }

    if (tanOut != null and cosOut != null and realIsZero(cosOut.?)) {
        realSetPositiveSign(tanOut.?);
        realPlus(tanOut.?, tanOut.?, realContext);
    }
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan_75temp (static)
// ===========================================================================
fn C47_WP34S_Cvt2RadSinCosTan_75temp(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var sinNeg: bool = false;
    var cosNeg: bool = false;
    var swap: bool = false;
    var angle: real_t = undefined;

    if (realIsNaN(an)) {
        if (sinOut) |s| realSetNaN(s);
        if (cosOut) |c| realSetNaN(c);
        if (tanOut) |t| realSetNaN(t);
        return;
    }

    realCopy(an, &angle);

    const savedContextDigits = realContext.digits;

    if (realContext.digits > 51) {
        realContext.digits = 75;
    } else {
        realContext.digits = 51;
    }

    doWP34S_SinCosTanTaylor(&angle, &sinNeg, &cosNeg, &swap, sinOut, cosOut, tanOut, angularMode, savedContextDigits, realContext);
}

// ===========================================================================
// doTaylorIterations (static)
// ===========================================================================
fn doTaylorIterations(
    a: *align(1) const real_t,
    angle: *align(1) real_t,
    a2: *align(1) real_t,
    t: *align(1) real_t,
    j: *align(1) real_t,
    z: *align(1) real_t,
    sin: *align(1) real_t,
    cos: *align(1) real_t,
    sinOut: ?*align(1) real_t,
    cosOut: ?*align(1) real_t,
    epsilonOrCompare: *align(1) real_t,
    doEpsilon: bool,
    epsilonDigits: i32,
    realContext: *realContext_t,
) void {
    var tmpEpsilon: [16]u8 = undefined;
    var endSin: bool = (sinOut == null);
    var endCos: bool = (cosOut == null);

    if (doEpsilon) {
        stringToReal(formatEminusD(&tmpEpsilon, epsilonDigits), epsilonOrCompare, realContext);
    }
    realCopy(a, angle);
    realMultiply(angle, angle, a2, realContext);
    realSetOne(j);
    realSetOne(t);
    realSetOne(sin);
    realSetOne(cos);

    var i: i32 = 1;
    while (!(endSin and endCos) and i < TaylorIterationMax) : (i += 1) {
        realAdd(j, const_1(), j, realContext);
        realDivide(a2, j, z, realContext);
        realMultiply(t, z, t, realContext);
        realChangeSign(t);
        var tExp = realGetExponent(t);

        if (!endCos) {
            realCopy(cos, z);
            realAdd(cos, t, cos, realContext);
            if (doEpsilon) {
                realCopyAbs(t, z);
            } else {
                realCompare(cos, z, epsilonOrCompare, realContext);
            }
            endCos = (!doEpsilon and realIsZero(epsilonOrCompare)) or (doEpsilon and math_comparison_reals.realCompareLessThan(@alignCast(z), @alignCast(epsilonOrCompare)));
        }

        realAdd(j, const_1(), j, realContext);
        realDivide(t, j, t, realContext);
        tExp = maxI32(tExp, realGetExponent(t));

        if (!endSin) {
            realCopy(sin, z);
            realAdd(sin, t, sin, realContext);
            if (doEpsilon) {
                realCopyAbs(t, z);
            } else {
                realCompare(sin, z, epsilonOrCompare, realContext);
            }
            endSin = (!doEpsilon and realIsZero(epsilonOrCompare)) or (doEpsilon and math_comparison_reals.realCompareLessThan(@alignCast(z), @alignCast(epsilonOrCompare)));
        }

        if (owner.explicitTaylorIterVisibilitySelection and checkHalfSec()) {
            _ = progressHalfSecUpdate_Integer(halfSec_timed, "Taylor Iter", epsilonDigits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        if (exitKeyWaiting()) {
            _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", i, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
            break;
        }
    }

    if (realIsZero(cos)) {
        realSetPositiveSign(cos);
    }
    if (realIsZero(sin)) {
        realSetPositiveSign(sin);
    }
    realMultiply(sin, angle, sin, realContext);
    owner.explicitTaylorIterVisibilitySelection = false;
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor_temp75
// ===========================================================================
pub fn C47_WP34S_SinCosTanTaylor_temp75(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var doEpsilon: bool = false;
    var epsilonDigits: i32 = undefined;
    var angle: real_t = undefined;
    var a2: real_t = undefined;
    var t: real_t = undefined;
    var j: real_t = undefined;
    var z: real_t = undefined;
    var sin: real_t = undefined;
    var cos: real_t = undefined;
    var epsilonOrCompare: real_t = undefined;

    const savedContextDigits = realContext.digits;

    if (realContext.digits > 51) {
        realContext.digits = 75;
        epsilonDigits = 72;
        doEpsilon = true;
    } else {
        realContext.digits = 51;
        epsilonDigits = 39;
        doEpsilon = false;
    }

    doTaylorIterations(a, &angle, &a2, &t, &j, &z, &sin, &cos, sinOut, cosOut, &epsilonOrCompare, doEpsilon, epsilonDigits, realContext);

    realContext.digits = savedContextDigits;

    if (sinOut) |s| {
        realPlus(&sin, s, realContext);
    }

    if (cosOut) |c| {
        realPlus(&cos, c, realContext);
    }

    if (tanOut) |tn| {
        if (sinOut == null or cosOut == null) {
            realSetNaN(tn);
        } else {
            if (swap) {
                realDivide(&cos, &sin, tn, realContext);
            } else {
                realDivide(&sin, &cos, tn, realContext);
            }
        }
    }
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan_1071temp (static)
// ===========================================================================
fn C47_WP34S_Cvt2RadSinCosTan_1071temp(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var sinNeg: bool = false;
    var cosNeg: bool = false;
    var swap: bool = false;
    var angle_buf: BigReal(1071) = .{};
    const angle = angle_buf.ptr();

    if (realIsNaN(an)) {
        if (sinOut) |s| realSetNaN(s);
        if (cosOut) |c| realSetNaN(c);
        if (tanOut) |t| realSetNaN(t);
        return;
    }

    realCopy(an, angle);

    const savedContextDigits = realContext.digits;

    doWP34S_SinCosTanTaylor(angle, &sinNeg, &cosNeg, &swap, sinOut, cosOut, tanOut, angularMode, savedContextDigits, realContext);
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan
// ===========================================================================
pub fn C47_WP34S_Cvt2RadSinCosTan(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47_WP34S_Cvt2RadSinCosTan_1071temp(an, angularMode, sinOut, cosOut, tanOut, realContext);
    } else {
        C47_WP34S_Cvt2RadSinCosTan_75temp(an, angularMode, sinOut, cosOut, tanOut, realContext);
    }
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor_temp1071
// ===========================================================================
fn C47_WP34S_SinCosTanTaylor_temp1071(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var angle_buf: BigReal(1071) = .{};
    var a2_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    var j_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    var sin_buf: BigReal(1071) = .{};
    var cos_buf: BigReal(1071) = .{};
    var epsilon_buf: BigReal(1071) = .{};

    const angle = angle_buf.ptr();
    const a2 = a2_buf.ptr();
    const t = t_buf.ptr();
    const j = j_buf.ptr();
    const z = z_buf.ptr();
    const sin = sin_buf.ptr();
    const cos = cos_buf.ptr();
    const epsilonOrCompare = epsilon_buf.ptr();

    doTaylorIterations(a, angle, a2, t, j, z, sin, cos, sinOut, cosOut, epsilonOrCompare, true, 1040, realContext);

    if (sinOut) |s| {
        realPlus(sin, s, realContext);
    }
    if (cosOut) |c| {
        realPlus(cos, c, realContext);
    }
    if (tanOut) |tn| {
        if (sinOut == null or cosOut == null) {
            realSetNaN(tn);
        } else {
            if (swap) {
                realDivide(cos, sin, tn, realContext);
            } else {
                realDivide(sin, cos, tn, realContext);
            }
        }
    }
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor (dispatcher) - not in wp34s.h but defined in C
// ===========================================================================
pub fn C47_WP34S_SinCosTanTaylor(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    if (realContext.digits >= 1071) {
        C47_WP34S_SinCosTanTaylor_temp1071(a, swap, sinOut, cosOut, tanOut, realContext);
    } else {
        C47_WP34S_SinCosTanTaylor_temp75(a, swap, sinOut, cosOut, tanOut, realContext);
    }
}
