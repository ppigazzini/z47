// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
const const39_pi = consts.const39_pi;
const const75_2pi = consts.const75_2pi;
const const_28 = consts.const_28;
const const_205 = consts.const_205;
const const_gammaRm1 = consts.const_gammaRm1;
const const75_gammaC00 = consts.const75_gammaC00;
//
// Zig owner for src/c47/mathematics/lnbeta.c: ln Beta(x, y), real and complex.
// Positive arguments take the one-expression Lanczos form (C47_LnBetaPositiveReal
// / C47_LnBetaPositiveComplex, which f.c, hyper.c, beta.c and cpyx.c also call);
// the rest goes through LnGamma(x) + LnGamma(y) - LnGamma(x+y). Faithful
// line-by-line translation preserving the exact order of every real_t
// operation (lnbeta.txt checks results to the last ULP). Exports fnLnBeta,
// LnBeta, C47_LnBetaPositiveReal and C47_LnBetaPositiveComplex with C linkage;
// the static helpers stay private. EXTRA_INFO_MESSAGE hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_gamma = @import("gamma.zig");
const math_ln_complex = @import("../ln_complex.zig");
const math_runtime_helpers = @import("../command_wrappers/helpers.zig");
const math_transcendental = @import("transcendental_command.zig");
const math_wp34s = @import("wp34s.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realFMA = runtime.realFMA;
const realMinus = runtime.realMinus;
const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsSpecial = runtime.realIsSpecial;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;
const realChangeSign = runtime.realChangeSign;
const realIsAnInteger = runtime.realIsAnInteger;
const realToIntegralValue = runtime.realToIntegralValue;
const int32ToReal = runtime.int32ToReal;
const DEC_ROUND_FLOOR = runtime.DEC_ROUND_FLOOR;
const DEC_ROUND_HALF_EVEN = runtime.DEC_ROUND_HALF_EVEN;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;

const FLAG_SPCRES: i32 = 0x8017;
const FLAG_CPXRES: u16 = 0x8004;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

// const_0/const_1/const_2 have runtime accessors.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}
inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}
inline fn const_1on2() *const real_t {
    return runtime.z47_math_wrappers_const_1on2();
}
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}
inline fn const_minusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_minus_infinity();
}
// The 75-digit Lanczos coefficients c01..c29: each sits at a 60-byte stride
// from the first, which is a 4-aligned blob offset, so the cast holds.
inline fn const75_gammaC01(k: u32) *const real_t {
    return @alignCast(consts.gammaC75(k));
}

const realIsPositive = math_real_predicates.realIsPositive;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
inline fn realCompareLessEqual(a: *const real_t, b: *const real_t) bool {
    return math_comparison_reals.realCompareLessEqual(a, b);
}
inline fn realCompareGreaterThan(a: *const real_t, b: *const real_t) bool {
    return math_comparison_reals.realCompareGreaterThan(a, b);
}
inline fn realCompareEqual(a: *const real_t, b: *const real_t) bool {
    return math_comparison_reals.realCompareEqual(a, b);
}

const RESULT_TYPE_UNKNOWN: i8 = 0;
const RESULT_TYPE_REAL: i8 = 1;
const RESULT_TYPE_COMPLEX: i8 = 2;

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

// EXTRA_INFO_MESSAGE (defines.h): the macro prints three console lines -- the
// fixed "In function " prefix, the function name, then the message -- and is
// compiled out on the firmware and under the testSuite.
fn extraInfoMessage(function_name: [*:0]const u8, message: [*:0]const u8) void {
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function ", function_name, message, null);
    }
}

fn lanczosSumRatioReal(a: *const real_t, b: *const real_t, sumAB: *const real_t, res: *real_t, realContext: *realContext_t) void {
    var coefficientA: real_t = undefined;
    var denominatorB: real_t = undefined;
    var denominatorSum: real_t = undefined;
    var product: real_t = undefined;
    var sumLanczos: real_t = undefined;
    var term: real_t = undefined;
    var twentyEight: real_t = undefined;

    runtime.WP34S_LanczosSum(sumAB, const_28(), &sumLanczos, realContext);
    realSetZero(res);
    int32ToReal(28, &twentyEight);
    realAdd(b, &twentyEight, &denominatorB, realContext);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        realAdd(&denominatorB, a, &denominatorSum, realContext);
        realMultiply(&denominatorB, &denominatorSum, &product, realContext);
        realMultiply(const75_gammaC01(@intCast(k)), a, &coefficientA, realContext);
        realDivide(&coefficientA, &product, &term, realContext);
        realAdd(res, &term, res, realContext);
        realSubtract(&denominatorB, const_1(), &denominatorB, realContext);
    }
    realDivide(res, &sumLanczos, res, realContext);
    math_wp34s.WP34S_Ln1P(res, res, realContext);
}

// Positive real log-Beta evaluated as one Lanczos expression. Labelling the
// smaller argument a and the larger one b changes the three central logarithms
// to terms containing log1p(a/(b+h)). The Lanczos-sum quotient is formed from
// its termwise difference, so neither part depends on retaining a in a+b.
pub export fn C47_LnBetaPositiveReal(x: *const real_t, y: *const real_t, res: *real_t) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var logA: real_t = undefined;
    var logRa: real_t = undefined;
    var logRb: real_t = undefined;
    var logRatio: real_t = undefined;
    var ra: real_t = undefined;
    var rb: real_t = undefined;
    var sumAB: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    const realContext: *realContext_t = &runtime.ctxtReal75;

    if (realIsAnInteger(x) and realCompareLessEqual(x, const_205())) {
        var err: bool = undefined;
        const n = runtime.realToInt32C47(x, &err);

        math_wp34s.WP34S_Gamma(x, &t, realContext);
        math_wp34s.WP34S_Ln(&t, res, realContext);
        math_wp34s.WP34S_Ln(y, &t, realContext);
        realMultiply(x, &t, &t, realContext);
        realSubtract(res, &t, res, realContext);
        var k: i32 = 1;
        while (k < n) : (k += 1) {
            int32ToReal(k, &t);
            realDivide(&t, y, &t, realContext);
            math_wp34s.WP34S_Ln1P(&t, &t, realContext);
            realSubtract(res, &t, res, realContext);
        }
        return;
    }
    if (realIsAnInteger(y) and realCompareLessEqual(y, const_205())) {
        C47_LnBetaPositiveReal(y, x, res);
        return;
    }

    if (realCompareLessEqual(x, y)) {
        realCopy(x, &a);
        realCopy(y, &b);
    } else {
        realCopy(y, &a);
        realCopy(x, &b);
    }

    if (realCompareEqual(&a, const_1())) {
        math_wp34s.WP34S_Ln(&b, res, realContext);
        realChangeSign(res);
        return;
    }

    realAdd(&a, &b, &sumAB, realContext);

    runtime.WP34S_LanczosSum(&a, const_28(), &logA, realContext);
    math_wp34s.WP34S_Ln(&logA, &logA, realContext);
    lanczosSumRatioReal(&a, &b, &sumAB, &logRatio, realContext);

    realAdd(&a, const_gammaRm1(), &ra, realContext);
    realAdd(&b, const_gammaRm1(), &rb, realContext);
    math_wp34s.WP34S_Ln(&ra, &logRa, realContext);
    math_wp34s.WP34S_Ln(&rb, &logRb, realContext);

    realSubtract(&a, const_1on2(), &t, realContext);
    realMultiply(&t, &logRa, &t, realContext);
    realAdd(&logA, &logRatio, res, realContext);
    realAdd(res, &t, res, realContext);

    realMultiply(&a, &logRb, &t, realContext);
    realSubtract(res, &t, res, realContext);

    realDivide(&a, &rb, &u, realContext);
    math_wp34s.WP34S_Ln1P(&u, &u, realContext);
    realSubtract(&sumAB, const_1on2(), &t, realContext);
    realMultiply(&t, &u, &t, realContext);
    realSubtract(res, &t, res, realContext);
    realSubtract(res, const_gammaRm1(), res, realContext);
}

fn lanczosSumComplex(z: *const cplx_t, sum: *cplx_t, realContext: *realContext_t) void {
    var twentyEight: real_t = undefined;
    var denominator: cplx_t = undefined;
    var term: cplx_t = undefined;

    realSetZero(&sum.Real);
    realSetZero(&sum.Imag);
    int32ToReal(28, &twentyEight);
    realAdd(&z.Real, &twentyEight, &denominator.Real, realContext);
    realCopy(&z.Imag, &denominator.Imag);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        runtime.divRealComplex(const75_gammaC01(@intCast(k)), &denominator, &term, realContext);
        realAdd(&sum.Real, &term.Real, &sum.Real, realContext);
        realAdd(&sum.Imag, &term.Imag, &sum.Imag, realContext);
        realSubtract(&denominator.Real, const_1(), &denominator.Real, realContext);
    }
    realAdd(&sum.Real, const75_gammaC00(), &sum.Real, realContext);
}

fn lanczosSumRatioComplex(a: *const cplx_t, b: *const cplx_t, sum: *const cplx_t, res: *cplx_t, realContext: *realContext_t) void {
    var coefficientA: cplx_t = undefined;
    var denominatorB: cplx_t = undefined;
    var denominatorSum: cplx_t = undefined;
    var twentyEight: real_t = undefined;
    var product: cplx_t = undefined;
    var sumLanczos: cplx_t = undefined;
    var term: cplx_t = undefined;

    lanczosSumComplex(sum, &sumLanczos, realContext);
    realSetZero(&res.Real);
    realSetZero(&res.Imag);
    int32ToReal(28, &twentyEight);
    realAdd(&b.Real, &twentyEight, &denominatorB.Real, realContext);
    realCopy(&b.Imag, &denominatorB.Imag);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        realAdd(&denominatorB.Real, &a.Real, &denominatorSum.Real, realContext);
        realAdd(&denominatorB.Imag, &a.Imag, &denominatorSum.Imag, realContext);
        runtime.mulComplexComplex(&denominatorB, &denominatorSum, &product, realContext);
        realMultiply(const75_gammaC01(@intCast(k)), &a.Real, &coefficientA.Real, realContext);
        realMultiply(const75_gammaC01(@intCast(k)), &a.Imag, &coefficientA.Imag, realContext);
        runtime.divComplexComplex(&coefficientA, &product, &term, realContext);
        realAdd(&res.Real, &term.Real, &res.Real, realContext);
        realAdd(&res.Imag, &term.Imag, &res.Imag, realContext);
        realSubtract(&denominatorB.Real, const_1(), &denominatorB.Real, realContext);
    }
    runtime.divComplexComplex(res, &sumLanczos, res, realContext);
    math_transcendental.lnP1Complex(res, res, realContext);
}

pub export fn C47_LnBetaPositiveComplex(x: *const cplx_t, y: *const cplx_t, res: *cplx_t) callconv(.c) void {
    var magnitudeX: real_t = undefined;
    var magnitudeY: real_t = undefined;
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var logA: cplx_t = undefined;
    var logRatio: cplx_t = undefined;
    var ra: cplx_t = undefined;
    var rb: cplx_t = undefined;
    var logRa: cplx_t = undefined;
    var logRb: cplx_t = undefined;
    var sum: cplx_t = undefined;
    var t: cplx_t = undefined;
    var u: cplx_t = undefined;
    const realContext: *realContext_t = &runtime.ctxtReal75;

    if (realIsZero(&x.Imag) and realIsAnInteger(&x.Real) and realCompareLessEqual(&x.Real, const_205())) {
        var err: bool = undefined;
        const n = runtime.realToInt32C47(&x.Real, &err);

        math_wp34s.WP34S_Gamma(&x.Real, &t.Real, realContext);
        math_wp34s.WP34S_Ln(&t.Real, &res.Real, realContext);
        realSetZero(&res.Imag);
        math_ln_complex.lnComplex(y, &t, realContext);
        realMultiply(&x.Real, &t.Real, &t.Real, realContext);
        realMultiply(&x.Real, &t.Imag, &t.Imag, realContext);
        realSubtract(&res.Real, &t.Real, &res.Real, realContext);
        realSubtract(&res.Imag, &t.Imag, &res.Imag, realContext);
        var k: i32 = 1;
        while (k < n) : (k += 1) {
            int32ToReal(k, &t.Real);
            runtime.divRealComplex(&t.Real, y, &u, realContext);
            math_transcendental.lnP1Complex(&u, &u, realContext);
            realSubtract(&res.Real, &u.Real, &res.Real, realContext);
            realSubtract(&res.Imag, &u.Imag, &res.Imag, realContext);
        }
        return;
    }
    if (realIsZero(&y.Imag) and realIsAnInteger(&y.Real) and realCompareLessEqual(&y.Real, const_205())) {
        C47_LnBetaPositiveComplex(y, x, res);
        return;
    }

    runtime.complexMagnitude(x, &magnitudeX, realContext);
    runtime.complexMagnitude(y, &magnitudeY, realContext);
    if (realCompareLessEqual(&magnitudeX, &magnitudeY)) {
        realCopy(&x.Real, &a.Real);
        realCopy(&x.Imag, &a.Imag);
        realCopy(&y.Real, &b.Real);
        realCopy(&y.Imag, &b.Imag);
    } else {
        realCopy(&y.Real, &a.Real);
        realCopy(&y.Imag, &a.Imag);
        realCopy(&x.Real, &b.Real);
        realCopy(&x.Imag, &b.Imag);
    }

    if (realCompareEqual(&a.Real, const_1()) and realIsZero(&a.Imag)) {
        math_ln_complex.lnComplex(&b, res, realContext);
        realChangeSign(&res.Real);
        realChangeSign(&res.Imag);
        return;
    }

    realAdd(&a.Real, &b.Real, &sum.Real, realContext);
    realAdd(&a.Imag, &b.Imag, &sum.Imag, realContext);

    lanczosSumComplex(&a, &logA, realContext);
    math_ln_complex.lnComplex(&logA, &logA, realContext);
    lanczosSumRatioComplex(&a, &b, &sum, &logRatio, realContext);

    realAdd(&a.Real, const_gammaRm1(), &ra.Real, realContext);
    realCopy(&a.Imag, &ra.Imag);
    realAdd(&b.Real, const_gammaRm1(), &rb.Real, realContext);
    realCopy(&b.Imag, &rb.Imag);
    math_ln_complex.lnComplex(&ra, &logRa, realContext);
    math_ln_complex.lnComplex(&rb, &logRb, realContext);

    realSubtract(&a.Real, const_1on2(), &t.Real, realContext);
    realCopy(&a.Imag, &t.Imag);
    runtime.mulComplexComplex(&t, &logRa, res, realContext);
    realAdd(&res.Real, &logA.Real, &res.Real, realContext);
    realAdd(&res.Imag, &logA.Imag, &res.Imag, realContext);
    realAdd(&res.Real, &logRatio.Real, &res.Real, realContext);
    realAdd(&res.Imag, &logRatio.Imag, &res.Imag, realContext);

    runtime.mulComplexComplex(&a, &logRb, &t, realContext);
    realSubtract(&res.Real, &t.Real, &res.Real, realContext);
    realSubtract(&res.Imag, &t.Imag, &res.Imag, realContext);

    runtime.divComplexComplex(&a, &rb, &u, realContext);
    math_transcendental.lnP1Complex(&u, &u, realContext);
    realSubtract(&sum.Real, const_1on2(), &t.Real, realContext);
    realCopy(&sum.Imag, &t.Imag);
    runtime.mulComplexComplex(&t, &u, &t, realContext);
    realSubtract(&res.Real, &t.Real, &res.Real, realContext);
    realSubtract(&res.Imag, &t.Imag, &res.Imag, realContext);
    realSubtract(&res.Real, const_gammaRm1(), &res.Real, realContext);
}

fn _checkLnGammaArgs(resultType: *i8, xReal: *real_t, realContext: *realContext_t) bool {
    var result: bool = true;
    resultType.* = RESULT_TYPE_UNKNOWN;

    if (realIsInfinite(xReal)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            extraInfoMessage("_checkLnGammaArgs", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of lnbeta when flag SPCRES is not set");
        } else {
            math_runtime_helpers.realToReal34(if (realIsPositive(xReal)) const_plusInfinity() else const_NaN(), runtime.registerReal34Ptr(REGISTER_X));
        }

        result = false;
    } else if (realCompareLessEqual(xReal, const_0())) { // x <= 0
        if (realIsAnInteger(xReal)) {
            if (!runtime.getSystemFlag(FLAG_SPCRES)) {
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                extraInfoMessage("_checkLnGammaArgs", "cannot use a negative integer as X input of lnbeta when flag SPCRES is not set");
            } else {
                runtime.convertRealToResultRegister(const_NaN(), REGISTER_X, amNone);
            }

            result = false;
        } else { // x is negative and not an integer
            var tmp: real_t = undefined;

            realMinus(xReal, &tmp, realContext); // tmp = -x
            math_wp34s.WP34S_Mod(&tmp, const_2(), &tmp, realContext); // tmp = ?

            if (realCompareGreaterThan(&tmp, const_1())) { // the result is a real
                resultType.* = RESULT_TYPE_REAL;
            } else { // the result is a complex
                if (runtime.getFlag(FLAG_CPXRES)) {
                    resultType.* = RESULT_TYPE_COMPLEX;
                } else { // Domain error
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                    extraInfoMessage("_checkLnGammaArgs", "cannot use a as X input of lnbeta if gamma(X)<0 when flag I is not set");
                    result = false;
                }
            }
        }
    } else {
        resultType.* = RESULT_TYPE_REAL;
    }

    return result;
}

fn _lnGammaReal(xReal: *real_t, rReal: *real_t, realContext: *realContext_t) void {
    math_wp34s.WP34S_LnGamma(xReal, rReal, realContext);
}

fn _lnGammaComplex(xReal: *real_t, r: *cplx_t, realContext: *realContext_t) void {
    realCopy(xReal, &r.Imag);
    math_wp34s.WP34S_Gamma(xReal, xReal, realContext);
    runtime.realSetPositiveSign(xReal);
    math_wp34s.WP34S_Ln(xReal, xReal, realContext);
    realCopy(xReal, &r.Real);
    realToIntegralValue(&r.Imag, &r.Imag, DEC_ROUND_FLOOR, realContext);
    realMultiply(&r.Imag, const39_pi(), &r.Imag, realContext);
}

// complexLnGamma above 39 digits: the Lanczos value at the caller's width, with
// its imaginary part brought onto the 39-digit reference's branch.
fn lnGammaComplexWide(x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    if (realContext.digits <= 39 or realIsZero(&x.Imag)) {
        math_gamma.complexLnGamma(x, r, realContext);
    } else {
        var turns: real_t = undefined;
        var reference: cplx_t = undefined;

        math_gamma.complexLnGamma(x, &reference, &runtime.ctxtReal39);
        runtime.WP34S_ComplexLnGamma(x, r, realContext);
        realSubtract(&reference.Imag, &r.Imag, &turns, realContext);
        realDivide(&turns, const75_2pi(), &turns, realContext);
        realToIntegralValue(&turns, &turns, DEC_ROUND_HALF_EVEN, realContext);
        realFMA(const75_2pi(), &turns, &r.Imag, &r.Imag, realContext);
    }
}

fn lnBetaComplexDirect(x: *const cplx_t, y: *const cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    var t: cplx_t = undefined;

    lnGammaComplexWide(x, &t, realContext); // t = LnGamma(x)
    lnGammaComplexWide(y, r, realContext); // r = LnGamma(y)

    realAdd(&r.Real, &t.Real, &r.Real, realContext); // r = LnGamma(x) + LnGamma(y)
    realAdd(&r.Imag, &t.Imag, &r.Imag, realContext);

    realAdd(&x.Real, &y.Real, &t.Real, realContext); // t = x + y
    realAdd(&x.Imag, &y.Imag, &t.Imag, realContext);

    lnGammaComplexWide(&t, &t, realContext); // t = LnGamma(x + y);

    realSubtract(&r.Real, &t.Real, &r.Real, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x + y);
    realSubtract(&r.Imag, &t.Imag, &r.Imag, realContext);
}

fn _lnBetaComplex(x: *cplx_t, y: *cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    if (runtime.getSystemFlag(FLAG_SPCRES) and realIsZero(&x.Imag) and realIsZero(&y.Imag) and
        ((realIsInfinite(&x.Real) and realIsPositive(&x.Real) and realCompareGreaterThan(&y.Real, const_0())) or
            (realIsInfinite(&y.Real) and realIsPositive(&y.Real) and realCompareGreaterThan(&x.Real, const_0()))))
    {
        realCopy(const_minusInfinity(), &r.Real);
        realSetZero(&r.Imag);
    } else if (realCompareGreaterThan(&x.Real, const_0()) and realCompareGreaterThan(&y.Real, const_0()) and
        !realIsSpecial(&x.Real) and !realIsSpecial(&x.Imag) and !realIsSpecial(&y.Real) and !realIsSpecial(&y.Imag))
    {
        var turns: real_t = undefined;
        var reference: cplx_t = undefined;

        C47_LnBetaPositiveComplex(x, y, r);
        lnBetaComplexDirect(x, y, &reference, &runtime.ctxtReal39);
        realSubtract(&reference.Imag, &r.Imag, &turns, realContext);
        realDivide(&turns, const75_2pi(), &turns, realContext);
        realToIntegralValue(&turns, &turns, DEC_ROUND_HALF_EVEN, realContext);
        realFMA(const75_2pi(), &turns, &r.Imag, &r.Imag, realContext);
    } else {
        lnBetaComplexDirect(x, y, r, realContext);
    }
}

fn _lnBetaReal(xReal: *real_t, yReal: *real_t, r: *cplx_t, realContext: *realContext_t) bool {
    var xflag: i8 = undefined;
    var yflag: i8 = undefined;
    var sflag: i8 = undefined;

    if ((realIsInfinite(xReal) and realIsPositive(xReal) and realCompareGreaterThan(yReal, const_0())) or
        (realIsInfinite(yReal) and realIsPositive(yReal) and realCompareGreaterThan(xReal, const_0())))
    {
        if (runtime.getSystemFlag(FLAG_SPCRES)) {
            realCopy(const_minusInfinity(), &r.Real);
            realSetZero(&r.Imag);
            return true;
        }
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        extraInfoMessage("_lnBetaReal", "cannot use positive infinity in lnbeta when flag SPCRES is not set");
        return false;
    }

    if (realCompareGreaterThan(xReal, const_0()) and realCompareGreaterThan(yReal, const_0()) and !realIsSpecial(xReal) and !realIsSpecial(yReal)) {
        C47_LnBetaPositiveReal(xReal, yReal, &r.Real);
        realSetZero(&r.Imag);
        return true;
    }

    realAdd(xReal, yReal, &r.Real, realContext); // r = x+y

    if (_checkLnGammaArgs(&xflag, xReal, realContext) and _checkLnGammaArgs(&yflag, yReal, realContext) and _checkLnGammaArgs(&sflag, &r.Real, realContext)) {
        var gx: cplx_t = undefined; // LnGamma(x)
        var gy: cplx_t = undefined; // LnGamma(y)
        var gs: cplx_t = undefined; // LnGamma(x+y)

        if (xflag == RESULT_TYPE_REAL) {
            _lnGammaReal(xReal, &gx.Real, realContext);
            realSetZero(&gx.Imag);
        } else {
            _lnGammaComplex(xReal, &gx, realContext);
        }

        if (yflag == RESULT_TYPE_REAL) {
            _lnGammaReal(yReal, &gy.Real, realContext);
            realSetZero(&gy.Imag);
        } else {
            _lnGammaComplex(yReal, &gy, realContext);
        }

        if (sflag == RESULT_TYPE_REAL) {
            _lnGammaReal(&r.Real, &gs.Real, realContext);
            realSetZero(&gs.Imag);
        } else {
            _lnGammaComplex(&r.Real, &gs, realContext);
        }

        realAdd(&gx.Real, &gy.Real, &r.Real, realContext); // r = LnGamma(x) + LnGamma(y)
        realAdd(&gx.Imag, &gy.Imag, &r.Imag, realContext);

        realSubtract(&r.Real, &gs.Real, &r.Real, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x+y)
        realSubtract(&r.Imag, &gs.Imag, &r.Imag, realContext);

        return true;
    }

    return false;
}

// Deliberately outside OPTION_ZETA_BETA, which gates only the LN-beta key: the F
// distribution calls this from f.c, and WP34S_betai in wp34s.c calls it too.
// Gating it would leave both calling an empty function, the way erfc did before
// it went with OPTION_DIST_NORMAL. _lnBetaReal and the LnGamma helpers it reaches
// stay outside for the same reason. Only _lnBetaComplex, which nothing but the
// key uses, sits inside the option.
pub export fn LnBeta(x: *const real_t, y: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) void {
    var r: cplx_t = undefined;
    var xx: real_t = undefined;
    var yy: real_t = undefined;

    realCopy(x, &xx);
    realCopy(y, &yy);
    if (_lnBetaReal(&xx, &yy, &r, realContext) and realIsZero(&r.Imag)) {
        realCopy(&r.Real, res);
    } else {
        realSetNaN(res);
    }
}

fn lnbetaReal() callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var r: cplx_t = undefined;

    if (runtime.getRegisterAsReal(REGISTER_X, &x) and runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        if (_lnBetaReal(&x, &y, &r, &runtime.ctxtReal75)) {
            if (realIsZero(&r.Imag)) {
                runtime.convertRealToResultRegister(&r.Real, REGISTER_X, amNone);
            } else {
                runtime.convertComplexToResultRegister(&r, REGISTER_X);
            }
        }
    }
}

fn lnbetaCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (runtime.getRegisterAsComplex(REGISTER_X, &x) and runtime.getRegisterAsComplex(REGISTER_Y, &y)) {
        _lnBetaComplex(&x, &y, &r, &runtime.ctxtReal75);
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }
}

pub export fn fnLnBeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&lnbetaReal, &lnbetaCplx);
}
