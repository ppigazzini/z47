// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
const const39_pi = consts.const39_pi;
//
// Zig owner for src/c47/mathematics/lnbeta.c: ln Beta(x, y) = LnGamma(x) +
// LnGamma(y) - LnGamma(x+y), real and complex. Faithful line-by-line
// translation preserving the exact order of every real_t operation
// (lnbeta.txt checks results to the last ULP). Exports fnLnBeta and LnBeta
// with C linkage; the static helpers stay private. EXTRA_INFO_MESSAGE hints
// become fixed moreInfoOnError strings (no-op under TESTSUITE/DMCP).

const runtime = @import("../command_wrappers_runtime.zig");
const math_comparison_reals = @import("../comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_gamma = @import("gamma.zig"); // M-callconv: Zig-to-Zig
const math_runtime_helpers = @import("../runtime_helpers.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("wp34s.zig"); // M-callconv: Zig-to-Zig

const math_real_predicates = @import("../real_predicates.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;
const realIsAnInteger = runtime.realIsAnInteger;
const realToIntegralValue = runtime.realToIntegralValue;
const reallocateRegister = runtime.reallocateRegister;
const DEC_ROUND_FLOOR = runtime.DEC_ROUND_FLOOR;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const dtReal34 = runtime.dtReal34;

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
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}

// Blob-offset constants without a runtime accessor.

// real ops / predicates not in runtime: extern / inline macro equivalents.
const realIsPositive = math_real_predicates.realIsPositive;
extern fn decNumberMinus(res: *real_t, operand: *const real_t, ctxt: *realContext_t) *real_t;
inline fn realMinus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}

// realToReal34 with a *align(1) const source (const_NaN is from the blob).
extern fn convertRealToReal34ResultRegister(real: *align(1) const real_t, dest: runtime.calcRegister_t) void;
const real34_t = runtime.real34_t;

// realMultiply with a *align(1) const operand (const39_pi is from the blob).
extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *align(1) const real_t, real_context: *realContext_t) *real_t;
inline fn realMultiplyBlob(op1: *const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}

// Cross-domain externs.

const RESULT_TYPE_UNKNOWN: i8 = 0;
const RESULT_TYPE_REAL: i8 = 1;
const RESULT_TYPE_COMPLEX: i8 = 2;

fn _checkLnGammaArgs(resultType: *i8, xReal: *real_t, realContext: *realContext_t) bool {
    var result: bool = true;
    resultType.* = RESULT_TYPE_UNKNOWN;

    if (realIsInfinite(xReal)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function _checkLnGammaArgs", "cannot use +-Infinity as X input of lnbeta when flag D is not set", null, null);
        } else {
            math_runtime_helpers.realToReal34(if (realIsPositive(xReal)) const_plusInfinity() else const_NaN(), runtime.registerReal34Ptr(REGISTER_X));
        }

        result = false;
    } else if (math_comparison_reals.realCompareLessEqual(xReal, const_0())) { // x <= 0
        if (realIsAnInteger(xReal)) {
            if (!runtime.getSystemFlag(FLAG_SPCRES)) {
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function _checkLnGammaArgs", "cannot use a negative integer as X input of lnbeta when flag D is not set", null, null);
            } else {
                reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                convertRealToReal34ResultRegister(const_NaN(), REGISTER_X);
            }

            result = false;
        } else { // x is negative and not an integer
            var tmp: real_t = undefined;

            realMinus(xReal, &tmp, realContext); // tmp = -x
            math_wp34s.WP34S_Mod(&tmp, const_2(), &tmp, realContext); // tmp = ?

            if (math_comparison_reals.realCompareGreaterThan(&tmp, const_1())) { // the result is a real
                resultType.* = RESULT_TYPE_REAL;
            } else { // the result is a complex
                if (runtime.getFlag(FLAG_CPXRES)) {
                    resultType.* = RESULT_TYPE_COMPLEX;
                } else { // Domain error
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function _checkLnGammaArgs", "cannot use a as X input of lnbeta if gamma(X)<0 when flag I is not set", null, null);
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

fn _lnGammaComplex(xReal: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) void {
    realCopy(xReal, rImag);
    math_wp34s.WP34S_Gamma(xReal, xReal, realContext);
    runtime.realSetPositiveSign(xReal);
    math_wp34s.WP34S_Ln(xReal, xReal, realContext);
    realCopy(xReal, rReal);
    realToIntegralValue(rImag, rImag, DEC_ROUND_FLOOR, realContext);
    realMultiplyBlob(rImag, const39_pi(), rImag, realContext);
}

fn _lnBetaComplex(xReal: *real_t, xImag: *real_t, yReal: *real_t, yImag: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) void {
    // LnBeta(x, y) := LnGamma(x) + LnGamma(y) - LnGamma(x+y)
    var tReal: real_t = undefined;
    var tImag: real_t = undefined;

    math_gamma.complexLnGamma(xReal, xImag, &tReal, &tImag, realContext); // t = LnGamma(x)
    math_gamma.complexLnGamma(yReal, yImag, rReal, rImag, realContext); // r = LnGamma(y)

    realAdd(rReal, &tReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y)
    realAdd(rImag, &tImag, rImag, realContext);

    realAdd(xReal, yReal, &tReal, realContext); // t = x + y
    realAdd(xImag, yImag, &tImag, realContext);

    math_gamma.complexLnGamma(&tReal, &tImag, &tReal, &tImag, realContext); // t = LnGamma(x + y);

    realSubtract(rReal, &tReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x + y);
    realSubtract(rImag, &tImag, rImag, realContext);
}

fn _lnBetaReal(xReal: *real_t, yReal: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) bool {
    var xflag: i8 = undefined;
    var yflag: i8 = undefined;
    var sflag: i8 = undefined;

    realAdd(xReal, yReal, rReal, realContext); // r = x+y

    if (_checkLnGammaArgs(&xflag, xReal, realContext) and _checkLnGammaArgs(&yflag, yReal, realContext) and _checkLnGammaArgs(&sflag, rReal, realContext)) {
        var gxReal: real_t = undefined; // LnGamma(x)
        var gxImag: real_t = undefined;
        var gyReal: real_t = undefined; // LnGamma(y)
        var gyImag: real_t = undefined;
        var gsReal: real_t = undefined; // LnGamma(x+y)
        var gsImag: real_t = undefined;

        if (xflag == RESULT_TYPE_REAL) {
            _lnGammaReal(xReal, &gxReal, realContext);
            realSetZero(&gxImag);
        } else {
            _lnGammaComplex(xReal, &gxReal, &gxImag, realContext);
        }

        if (yflag == RESULT_TYPE_REAL) {
            _lnGammaReal(yReal, &gyReal, realContext);
            realSetZero(&gyImag);
        } else {
            _lnGammaComplex(yReal, &gyReal, &gyImag, realContext);
        }

        if (sflag == RESULT_TYPE_REAL) {
            _lnGammaReal(rReal, &gsReal, realContext);
            realSetZero(&gsImag);
        } else {
            _lnGammaComplex(rReal, &gsReal, &gsImag, realContext);
        }

        realAdd(&gxReal, &gyReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y)
        realAdd(&gxImag, &gyImag, rImag, realContext);

        realSubtract(rReal, &gsReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x+y)
        realSubtract(rImag, &gsImag, rImag, realContext);

        return true;
    }

    return false;
}

pub export fn LnBeta(x: *const real_t, y: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) void {
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;
    var xx: real_t = undefined;
    var yy: real_t = undefined;

    realCopy(x, &xx);
    realCopy(y, &yy);
    if (_lnBetaReal(&xx, &yy, &rReal, &rImag, realContext) and realIsZero(&rImag)) {
        realCopy(&rReal, res);
    } else {
        realSetNaN(res);
    }
}

fn lnbetaReal() callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (runtime.getRegisterAsReal(REGISTER_X, &x) and runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        if (_lnBetaReal(&x, &y, &rReal, &rImag, &runtime.ctxtReal39)) {
            if (realIsZero(&rImag)) {
                runtime.convertRealToResultRegister(&rReal, REGISTER_X, amNone);
            } else {
                runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
            }
        }
    }
}

fn lnbetaCplx() callconv(.c) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag) and runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag)) {
        _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }
}

pub export fn fnLnBeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&lnbetaReal, &lnbetaCplx);
}
