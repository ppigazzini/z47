// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/beta.c: Beta(x, y) = Gamma(x)*Gamma(y)/
// Gamma(x+y), real and complex. Faithful line-by-line translation preserving
// the exact order of every real_t operation (beta.txt checks results to the
// last ULP). Exports fnBeta with C linkage; the static realBeta/complexBeta/
// betaReal/betaComplex helpers stay private. The SAVE_SPACE_DM42_12 gate is
// dead on every z47 build, so the body is ported unconditionally. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings
// (no-op under TESTSUITE/DMCP).

const runtime = @import("math_command_wrappers_runtime.zig");
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("math_wp34s.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realIsNaN = runtime.realIsNaN;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_OUT_OF_RANGE = runtime.ERROR_OUT_OF_RANGE;
const amNone = runtime.amNone;

// const_0 has a runtime accessor.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}

// realCompareLessEqual is not in runtime; extern it.

// Cross-domain Zig-exported externs.

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

fn complexBeta(xReal: *real_t, xImag: *real_t, yReal: *real_t, yImag: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) bool {
    // Beta(x, y) := Gamma(x) * Gamma(y) / Gamma(x+y)
    var tReal: real_t = undefined;
    var tImag: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(xReal, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function complexBeta:", "cannot calculate Beta with Re(x)<=0", null, null);
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(yReal, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function complexBeta:", "cannot calculate Beta with Re(y)<=0", null, null);
        return false;
    }

    math_wp34s.WP34S_ComplexGamma(xReal, xImag, &tReal, &tImag, realContext); // t = Gamma(x)
    math_wp34s.WP34S_ComplexGamma(yReal, yImag, rReal, rImag, realContext); // r = Gamma(y)

    runtime.mulComplexComplex(rReal, rImag, &tReal, &tImag, rReal, rImag, realContext); // r = Gamma(x) * Gamma(y)

    realAdd(xReal, yReal, &tReal, realContext); // t = x + y
    realAdd(xImag, yImag, &tImag, realContext);

    math_wp34s.WP34S_ComplexGamma(&tReal, &tImag, &tReal, &tImag, realContext); // t = Gamma(x + y);
    runtime.divComplexComplex(rReal, rImag, &tReal, &tImag, rReal, rImag, realContext); // r = Gamma(x) * Gamma(y) / Gamma(x + y);

    if (realIsNaN(rImag) or realIsNaN(rReal)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function complexBeta:", "cannot calculate Beta out of range", null, null);
        return false;
    }

    return true;
}

fn realBeta(x: *real_t, y: *real_t, r: *real_t, realContext: *realContext_t) bool {
    // Beta(x, y) := Gamma(x) * Gamma(y) / Gamma(x+y)
    var tReal: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(x, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function realBeta:", "cannot calculate Beta with x<=0", null, null);
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(y, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function realBeta:", "cannot calculate Beta with Re(y)<=0", null, null);
        return false;
    }

    math_wp34s.WP34S_Gamma(x, &tReal, realContext); // t = Gamma(x)
    math_wp34s.WP34S_Gamma(y, r, realContext); // r = Gamma(y)

    realMultiply(r, &tReal, r, realContext); // r = Gamma(x) * Gamma(y)

    realAdd(x, y, &tReal, realContext); // t = x + y

    math_wp34s.WP34S_Gamma(&tReal, &tReal, realContext); // t = Gamma(x + y);
    realDivide(r, &tReal, r, realContext); // r = Gamma(x) * Gamma(y) / Gamma(x + y);

    if (realIsNaN(r)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function realBeta:", "cannot calculate Beta out of range", null, null);
        return false;
    }

    return true;
}

fn betaComplex() callconv(.c) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag) or !runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag)) {
        return;
    }

    if (complexBeta(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &runtime.ctxtReal75)) {
        runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }
}

fn betaReal() callconv(.c) void {
    var r: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realBeta(&x, &y, &r, &runtime.ctxtReal39)) {
        runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
    }
}

pub export fn fnBeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&betaReal, &betaComplex);
}
