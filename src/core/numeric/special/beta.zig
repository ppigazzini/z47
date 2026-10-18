// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/beta.c: Beta(x, y) = exp(ln Beta(x, y)),
// real and complex, through the positive-argument log-Beta of lnbeta.c.
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (beta.txt checks results to the last ULP). Exports fnBeta with C
// linkage; the static realBeta/complexBeta/betaReal/betaComplex helpers stay
// private. OPTION_ZETA_BETA is defined for every target built here, so the
// body is unconditional -- the C's !OPTION_ZETA_BETA arm, an empty fnBeta, is
// the one that is never taken.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_lnbeta = @import("lnbeta.zig");
const math_transcendental = @import("transcendental_command.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsSpecial = runtime.realIsSpecial;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_OUT_OF_RANGE = runtime.ERROR_OUT_OF_RANGE;
const amNone = runtime.amNone;
const FLAG_SPCRES = runtime.FLAG_SPCRES;

// const_0 has a runtime accessor.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}

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

fn complexBeta(x: *cplx_t, y: *cplx_t, r: *cplx_t, realContext: *realContext_t) bool {
    if (math_comparison_reals.realCompareLessEqual(&x.Real, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        reportBetaError("In function complexBeta:", ") with Re(x)<=0");
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(&y.Real, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        reportBetaError("In function complexBeta:", " with Re(y)<=0");
        return false;
    }

    if (realIsSpecial(&x.Real) or realIsSpecial(&x.Imag) or realIsSpecial(&y.Real) or realIsSpecial(&y.Imag)) {
        if (runtime.getSystemFlag(FLAG_SPCRES) and realIsZero(&x.Imag) and realIsZero(&y.Imag) and
            !realIsNaN(&x.Real) and !realIsNaN(&y.Real) and (realIsInfinite(&x.Real) or realIsInfinite(&y.Real)))
        {
            realSetZero(&r.Real);
            realSetZero(&r.Imag);
            return true;
        }
        realSetNaN(&r.Real);
        realSetNaN(&r.Imag);
    } else {
        math_lnbeta.C47_LnBetaPositiveComplex(x, y, r);
        math_transcendental.expComplex(r, r, realContext);
    }

    if (realIsNaN(&r.Imag) or realIsNaN(&r.Real)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        reportBetaError("In function complexBeta:", ") out of range");
        return false;
    }

    return true;
}

fn realBeta(x: *real_t, y: *real_t, r: *real_t) bool {
    var tReal: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(x, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        reportBetaError("In function realBeta:", ") with x<=0");
        return false;
    } else if (math_comparison_reals.realCompareLessEqual(y, const_0())) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        reportBetaError("In function realBeta:", " with Re(y)<=0");
        return false;
    }

    if (realIsNaN(x) or realIsNaN(y)) {
        realSetNaN(r);
    } else if (realIsInfinite(x) or realIsInfinite(y)) {
        if (runtime.getSystemFlag(FLAG_SPCRES)) {
            realSetZero(r);
            return true;
        }
        realSetNaN(r);
    } else {
        math_lnbeta.C47_LnBetaPositiveReal(x, y, &tReal);
        math_transcendental.realExp(&tReal, r, &runtime.ctxtReal75);
    }

    if (realIsNaN(r)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        reportBetaError("In function realBeta:", ") out of range");
        return false;
    }

    return true;
}

fn betaComplex() callconv(.c) void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &x) or !runtime.getRegisterAsComplex(REGISTER_Y, &y)) {
        return;
    }

    if (complexBeta(&x, &y, &r, &runtime.ctxtReal75)) {
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }
}

fn betaReal() callconv(.c) void {
    var r: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realBeta(&x, &y, &r)) {
        runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
    }
}

pub export fn fnBeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&betaReal, &betaComplex);
}
