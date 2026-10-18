// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
const const39_2pi = consts.const39_2pi;
const const39_pi = consts.const39_pi;
const const39_ln2piOn2 = consts.const39_ln2piOn2;
//
// Zig owner for src/c47/mathematics/gamma.c: the GAMMA and LNGAMMA commands,
// real and complex, plus the complexLnGamma helper (exported, used by lnbeta).
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (gamma.txt / gammaP.txt / gammaQ.txt check results to the last ULP).
// Exports fnGamma, fnLnGamma and complexLnGamma with C linkage; the static
// checkGammaDomain / gammaReal / lnAbsGammaNegative / lnGammaReal / gammaCplx /
// lnGammaCplx / complexLnGamma_Stirling helpers stay private. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings
// (no-op under TESTSUITE/DMCP).

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_ln_complex = @import("../ln_complex.zig");
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
const realSetNaN = runtime.realSetNaN;
const realIsNaN = runtime.realIsNaN;
const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realIsSpecial = runtime.realIsSpecial;
const realIsAnInteger = runtime.realIsAnInteger;
const realIsPositive = math_real_predicates.realIsPositive;
const realToIntegralValue = runtime.realToIntegralValue;
const realMinus = runtime.realMinus;
const reallocateRegister = runtime.reallocateRegister;
const setRegisterAngularMode = runtime.setRegisterAngularMode;
const DEC_ROUND_FLOOR = runtime.DEC_ROUND_FLOOR;
const DEC_ROUND_HALF_EVEN = runtime.DEC_ROUND_HALF_EVEN;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const dtComplex34 = runtime.dtComplex34;

const FLAG_SPCRES: i32 = 0x8017;
const FLAG_CPXRES: u16 = 0x8004;

// Runtime const accessors.
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
inline fn const75_pi() *const real_t {
    return runtime.z47_math_wrappers_const75_pi();
}
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

fn checkGammaDomain(xReal: *const real_t, out: *real_t) i32 {
    if (realIsSpecial(xReal)) {
        if (realIsNaN(xReal)) {
            realSetNaN(out);
        } else if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            moreInfoOnError("In function checkGammaDomain:", "cannot use +-Infinity as X input of gamma when flag SPCRES is not set", null, null);
        } else {
            realCopy(if (realIsPositive(xReal)) const_plusInfinity() else const_NaN(), out);
        }
        return 0;
    }
    if (math_comparison_reals.realCompareLessEqual(xReal, const_0()) and realIsAnInteger(xReal)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            moreInfoOnError("In function checkGammaDomain:", "cannot use a negative integer as X input of gamma when flag SPCRES is not set", null, null);
        } else {
            realSetNaN(out);
        }
        return 0;
    }
    return 1;
}

fn gammaReal() callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    if (checkGammaDomain(&x, &x) != 0) {
        math_wp34s.WP34S_Gamma(&x, &x, &runtime.ctxtReal39);
    }
    runtime.convertRealToResultRegister(&x, REGISTER_X, amNone);
}

// ln|Gamma(x)| at 75 digits for a negative x that is not an integer; returns
// whether Gamma(x) is negative. Where it is, ln|Gamma(x)| is lnGamma(x + 1) -
// ln(-x), since Gamma(x + 1) = x Gamma(x) is then positive. Next to the zeros of
// ln|Gamma| on the negative axis the terms of the reflection cancel, so all of
// it is at 75 digits.
fn lnAbsGammaNegative(x: *const real_t, res: *real_t) bool {
    var xin: real_t = undefined;
    var t: real_t = undefined;

    realCopy(x, &xin);
    realMinus(&xin, &t, &runtime.ctxtReal75);
    math_wp34s.WP34S_Mod(&t, const_2(), &t, &runtime.ctxtReal75);
    if (math_comparison_reals.realCompareGreaterThan(&t, const_1())) {
        math_wp34s.WP34S_LnGamma(&xin, res, &runtime.ctxtReal75);
        return false;
    }
    realAdd(&xin, const_1(), &t, &runtime.ctxtReal75);
    math_wp34s.WP34S_LnGamma(&t, res, &runtime.ctxtReal75);
    realMinus(&xin, &t, &runtime.ctxtReal75);
    math_wp34s.WP34S_Ln(&t, &t, &runtime.ctxtReal75);
    realSubtract(res, &t, res, &runtime.ctxtReal75);
    return true;
}

fn lnGammaReal() callconv(.c) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &xReal)) {
        return;
    }
    setRegisterAngularMode(REGISTER_X, amNone);

    if (checkGammaDomain(&xReal, &xReal) == 0) {
        // goto end
        runtime.convertRealToResultRegister(&xReal, REGISTER_X, amNone);
        return;
    }

    if (math_comparison_reals.realCompareLessEqual(&xReal, const_0())) { // x <= 0
        // x is negative and not an integer
        realCopy(&xReal, &xImag); // x.imag is used as a temp variable here
        if (!lnAbsGammaNegative(&xImag, &xReal)) { // the result is a real
            runtime.convertRealToReal34ResultRegister(&xReal, REGISTER_X);
        } else { // the result is a complex
            if (runtime.getFlag(FLAG_CPXRES)) { // We can calculate a complex
                reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                realToIntegralValue(&xImag, &xImag, DEC_ROUND_FLOOR, &runtime.ctxtReal39);
                realMultiply(&xImag, const39_pi(), &xImag, &runtime.ctxtReal39);
                runtime.convertComplexPartsToResultRegister(&xReal, &xImag, REGISTER_X);
            } else { // Domain error
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                moreInfoOnError("In function lnGammaReal:", "cannot use a as X input of lngamma if gamma(X)<0 when flag I is not set", null, null);
            }
        }
        return;
    }

    math_wp34s.WP34S_LnGamma(&xReal, &xReal, &runtime.ctxtReal39);
    // end:
    runtime.convertRealToResultRegister(&xReal, REGISTER_X, amNone);
}

fn gammaCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &z)) {
        return;
    }
    runtime.WP34S_ComplexGamma(&z, &z, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z, REGISTER_X);
}

// Abramowitz & Stegun 6.1.41, leading terms only: (z-1/2)ln(z) - z + (1/2)ln(2pi).
// Not a general-purpose lnGamma: complexLnGamma() uses it only as a reference to pick
// the 2*pi winding integer for the imaginary part of the Lanczos result, so the
// imaginary part need only be within pi of the true value. The leading terms achieve
// that for every z off the real axis: the imaginary-part error stays below ~pi/2
// (approached near the negative real axis and, as |z| -> 0, tending to arg(z)/2), a
// full factor of 2 inside the margin. The asymptotic corrections
// 1/(12z) - 1/(360z^3) + 1/(1260z^5) - ... are intentionally omitted: where |z| is large
// enough for the truncated series to be accurate their total stays orders of magnitude
// below the ~pi decision margin, and for small |z| the divergent tail grows past pi
// (~6000 at z = 0.1i) and corrupts the winding choice.
fn complexLnGamma_Stirling(x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    var t: cplx_t = undefined;

    math_ln_complex.lnComplex(x, r, realContext);
    realSubtract(&x.Real, const_1on2(), &t.Real, realContext);
    realCopy(&x.Imag, &t.Imag);
    runtime.mulComplexComplex(&t, r, r, realContext);

    realSubtract(&r.Real, &x.Real, &r.Real, realContext);
    realSubtract(&r.Imag, &x.Imag, &r.Imag, realContext);

    realAdd(&r.Real, const39_ln2piOn2(), &r.Real, realContext);
}

pub export fn complexLnGamma(x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    if (realIsZero(&x.Imag) and realIsNegative(&x.Real) and !realIsAnInteger(&x.Real)) {
        // On the cut along the negative axis, the value from above: ln|Gamma(x)| + i pi floor(x)
        realToIntegralValue(&x.Real, &r.Imag, DEC_ROUND_FLOOR, realContext);
        realMultiply(&r.Imag, const75_pi(), &r.Imag, realContext);
        _ = lnAbsGammaNegative(&x.Real, &r.Real);
    } else if (realIsZero(&x.Imag)) {
        math_wp34s.WP34S_LnGamma(&x.Real, &r.Real, realContext);
        realCopy(if (realIsNaN(&r.Real)) const_NaN() else const_0(), &r.Imag);
    } else {
        var z: cplx_t = undefined;
        var t: cplx_t = undefined;
        realCopy(&x.Real, &z.Real);
        realCopy(&x.Imag, &z.Imag);
        complexLnGamma_Stirling(&z, &t, &runtime.ctxtReal39);
        runtime.WP34S_ComplexLnGamma(&z, r, &runtime.ctxtReal39);
        realSubtract(&t.Imag, &r.Imag, &t.Imag, &runtime.ctxtReal39);
        realDivide(&t.Imag, const39_2pi(), &t.Imag, &runtime.ctxtReal39);
        realToIntegralValue(&t.Imag, &t.Imag, DEC_ROUND_HALF_EVEN, &runtime.ctxtReal39);
        realFMA(const39_2pi(), &t.Imag, &r.Imag, &r.Imag, &runtime.ctxtReal39);
    }
}

fn lnGammaCplx() callconv(.c) void {
    var z: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &z)) {
        return;
    }
    complexLnGamma(&z, &r, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, REGISTER_X);
}

pub export fn fnGamma(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&gammaReal, &gammaCplx);
}

pub export fn fnLnGamma(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&lnGammaReal, &lnGammaCplx);
}
