// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/beta.c: Beta(x, y) = Gamma(x)*Gamma(y)/
// Gamma(x+y), real and complex. Faithful line-by-line translation preserving
// the exact order of every real_t operation (beta.txt checks results to the
// last ULP). Exports fnBeta with C linkage; the static realBeta/complexBeta/
// betaReal/betaComplex helpers stay private. The SAVE_SPACE_DM42_12 gate is
// dead on every z47 build, so the body is ported unconditionally.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_wp34s = @import("wp34s.zig");
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

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

// Every Beta refusal names both operands, Y first then X, and the sentence
// that follows differs per arm (including upstream's missing parenthesis in
// the two Re(y) ones).
fn reportBetaError(function_name: [*:0]const u8, comptime tail: []const u8) void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }
    var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
    const y_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
    const x_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&buffer, "cannot calculate Beta of ({s}, {s}" ++ tail, .{ y_name, x_name }) catch "";
    moreInfoOnError(function_name, message, null, null);
}

fn complexBeta(xReal: *real_t, xImag: *real_t, yReal: *real_t, yImag: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) bool {
    // Beta(x, y) := Gamma(x) * Gamma(y) / Gamma(x+y)
    var tReal: real_t = undefined;
    var tImag: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(xReal, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        reportBetaError("In function complexBeta:", ") with Re(x)<=0");
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(yReal, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        reportBetaError("In function complexBeta:", " with Re(y)<=0");
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
        reportBetaError("In function complexBeta:", ") out of range");
        return false;
    }

    return true;
}

fn realBeta(x: *real_t, y: *real_t, r: *real_t, realContext: *realContext_t) bool {
    // Beta(x, y) := Gamma(x) * Gamma(y) / Gamma(x+y)
    var tReal: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(x, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        reportBetaError("In function realBeta:", ") with x<=0");
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(y, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        reportBetaError("In function realBeta:", " with Re(y)<=0");
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
        reportBetaError("In function realBeta:", ") out of range");
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
