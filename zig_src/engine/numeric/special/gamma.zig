// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
const const39_2pi = consts.const39_2pi;
const const39_pi = consts.const39_pi;
const const39_ln2piOn2 = consts.const39_ln2piOn2;
const const_12 = consts.const_12;
const const_360 = consts.const_360;
const const_1260 = consts.const_1260;
const const_1680 = consts.const_1680;
//
// Zig owner for src/c47/mathematics/gamma.c: the GAMMA and LNGAMMA commands,
// real and complex, plus the complexLnGamma helper (exported, used by lnbeta).
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (gamma.txt / gammaP.txt / gammaQ.txt check results to the last ULP).
// Exports fnGamma, fnLnGamma and complexLnGamma with C linkage; the static
// checkGammaDomain / gammaReal / lnGammaReal / gammaCplx / lnGammaCplx /
// complexLnGamma_Stirling helpers stay private. The EXTRA_INFO_ON_CALC_ERROR
// sprintf hints become fixed moreInfoOnError strings (no-op under TESTSUITE/
// DMCP).

const runtime = @import("../command_wrappers_runtime.zig");
const math_comparison_reals = @import("../comparison_reals.zig");
const math_division_cells = @import("../arithmetic/division_cells.zig");
const math_ln_complex = @import("../ln_complex.zig");
const math_multiplication_cells = @import("../arithmetic/multiplication_cells.zig");
const math_wp34s = @import("wp34s.zig");
const math_real_predicates = @import("../real_predicates.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const real34_t = runtime.real34_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realFMA = runtime.realFMA;
const realSetNaN = runtime.realSetNaN;
const realIsNaN = runtime.realIsNaN;
const realIsZero = runtime.realIsZero;
const realIsSpecial = runtime.realIsSpecial;
const realIsAnInteger = runtime.realIsAnInteger;
const realIsPositive = math_real_predicates.realIsPositive;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realToIntegralValue = runtime.realToIntegralValue;
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
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}

// Blob-offset constants without a runtime accessor.

// real ops / predicates / copy not in runtime, plus blob-constant variants.
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realMinus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
inline fn realMulB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realSubB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realAddB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realDivB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realFMAB(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
const decNumberFMA = @extern(*const fn (result: *real_t, factor1: *align(1) const real_t, factor2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) callconv(.c) *real_t, .{ .name = "decNumberFMA" });

// real34ToReal with a register-resident (unaligned) real34 source.
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: runtime.calcRegister_t) void;

// realSetNaN against a blob-aligned destination (const_NaN is read-only, but the
// register temp dest path stays aligned via realSetNaN runtime).
// Cross-domain externs (wp34s + complex helpers).

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

fn checkGammaDomain(xReal: *const real_t, out: *real_t) i32 {
    if (realIsSpecial(xReal)) {
        if (realIsNaN(xReal)) {
            realSetNaN(out);
        } else if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function checkGammaDomain:", "cannot use +-Infinity as X input of gamma when flag D is not set", null, null);
        } else {
            realCopy(if (realIsPositive(xReal)) const_plusInfinity() else const_NaN(), out);
        }
        return 0;
    }
    if (math_comparison_reals.realCompareLessEqual(xReal, const_0()) and realIsAnInteger(xReal)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function checkGammaDomain:", "cannot use a negative integer as X input of gamma when flag D is not set", null, null);
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
        realMinus(&xReal, &xImag, &runtime.ctxtReal39); // x.imag is used as a temp variable here
        math_wp34s.WP34S_Mod(&xImag, const_2(), &xImag, &runtime.ctxtReal39);
        if (math_comparison_reals.realCompareGreaterThan(&xImag, const_1())) { // the result is a real
            math_wp34s.WP34S_LnGamma(&xReal, &xReal, &runtime.ctxtReal39);
            convertRealToReal34ResultRegister(&xReal, REGISTER_X);
        } else { // the result is a complex
            if (runtime.getFlag(FLAG_CPXRES)) { // We can calculate a complex
                real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &xImag);
                reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                math_wp34s.WP34S_Gamma(&xReal, &xReal, &runtime.ctxtReal39);
                realSetPositiveSign(&xReal);
                math_wp34s.WP34S_Ln(&xReal, &xReal, &runtime.ctxtReal39);
                realToIntegralValue(&xImag, &xImag, DEC_ROUND_FLOOR, &runtime.ctxtReal39);
                realMulB(&xImag, const39_pi(), &xImag, &runtime.ctxtReal39);
                runtime.convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
            } else { // Domain error
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
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
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &zReal, &zImag)) {
        return;
    }
    math_wp34s.WP34S_ComplexGamma(&zReal, &zImag, &zReal, &zImag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
}

// Abramowitz & Stegun 6.1.41 (only approximation needed here)
fn complexLnGamma_Stirling(xReal: *const real_t, xImag: *const real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) void {
    // (z-1/2)ln(z) - z + (1/2)ln(2pi) + 1/(12z) - 1/(360z^3) + 1/(1260z^5) - 1/(1680z^7) ...
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;
    var z2Real: real_t = undefined;
    var z2Imag: real_t = undefined;
    var zxReal: real_t = undefined;
    var zxImag: real_t = undefined;
    var tReal: real_t = undefined;
    var tImag: real_t = undefined;
    realCopy(xReal, &zReal);
    realCopy(xImag, &zImag);
    math_ln_complex.lnComplex(&zReal, &zImag, rReal, rImag, realContext);
    realSubtract(&zReal, const_1on2(), &tReal, realContext);
    math_multiplication_cells.mulComplexComplex(&tReal, &zImag, rReal, rImag, rReal, rImag, realContext);

    realSubtract(rReal, &zReal, rReal, realContext);
    realSubtract(rImag, &zImag, rImag, realContext);

    realAddB(rReal, const39_ln2piOn2(), rReal, realContext);

    realMulB(const_12(), &zReal, &tReal, realContext);
    realMulB(const_12(), &zImag, &tImag, realContext);
    math_division_cells.divRealComplex(const_1(), &tReal, &tImag, &tReal, &tImag, realContext);
    realAdd(rReal, &zReal, rReal, realContext);
    realAdd(rImag, &zImag, rImag, realContext);

    math_multiplication_cells.mulComplexComplex(&zReal, &zImag, &zReal, &zImag, &z2Real, &z2Imag, realContext);
    math_multiplication_cells.mulComplexComplex(&zReal, &zImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
    realMulB(const_360(), &zxReal, &tReal, realContext);
    realMulB(const_360(), &zxImag, &tImag, realContext);
    math_division_cells.divRealComplex(const_1(), &tReal, &tImag, &tReal, &tImag, realContext);
    realSubtract(rReal, &zReal, rReal, realContext);
    realSubtract(rImag, &zImag, rImag, realContext);

    math_multiplication_cells.mulComplexComplex(&zxReal, &zxImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
    realMulB(const_1260(), &zxReal, &tReal, realContext);
    realMulB(const_1260(), &zxImag, &tImag, realContext);
    math_division_cells.divRealComplex(const_1(), &tReal, &tImag, &tReal, &tImag, realContext);
    realAdd(rReal, &zReal, rReal, realContext);
    realAdd(rImag, &zImag, rImag, realContext);

    math_multiplication_cells.mulComplexComplex(&zxReal, &zxImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
    realMulB(const_1680(), &zxReal, &tReal, realContext);
    realMulB(const_1680(), &zxImag, &tImag, realContext);
    math_division_cells.divRealComplex(const_1(), &tReal, &tImag, &tReal, &tImag, realContext);
    realSubtract(rReal, &zReal, rReal, realContext);
    realSubtract(rImag, &zImag, rImag, realContext);
}

pub export fn complexLnGamma(xReal: *const real_t, xImag: *const real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) callconv(.c) void {
    if (realIsZero(xImag)) {
        math_wp34s.WP34S_LnGamma(xReal, rReal, realContext);
        realCopy(if (realIsNaN(rReal)) const_NaN() else const_0(), rImag);
    } else {
        var zReal: real_t = undefined;
        var zImag: real_t = undefined;
        var tImag: real_t = undefined;
        realCopy(xReal, &zReal);
        realCopy(xImag, &zImag);
        complexLnGamma_Stirling(&zReal, &zImag, rReal, &tImag, &runtime.ctxtReal39);
        math_wp34s.WP34S_ComplexLnGamma(&zReal, &zImag, rReal, rImag, &runtime.ctxtReal39);
        realSubtract(&tImag, rImag, &tImag, &runtime.ctxtReal39);
        realDivB(&tImag, const39_2pi(), &tImag, &runtime.ctxtReal39);
        realToIntegralValue(&tImag, &tImag, DEC_ROUND_HALF_EVEN, &runtime.ctxtReal39);
        realFMAB(const39_2pi(), &tImag, rImag, rImag, &runtime.ctxtReal39);
    }
}

fn lnGammaCplx() callconv(.c) void {
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &zReal, &zImag)) {
        return;
    }
    complexLnGamma(&zReal, &zImag, &rReal, &rImag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}

pub export fn fnGamma(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&gammaReal, &gammaCplx);
}

pub export fn fnLnGamma(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&lnGammaReal, &lnGammaCplx);
}
