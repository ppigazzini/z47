// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/gd.c: the Gudermannian gd and inverse gd
// functions, real and complex. Faithful line-by-line translation preserving
// the exact order of every real_t operation (gd.txt / invGd.txt check results
// to the last ULP). Exports fnGd, fnInvGd and the four Gudermannian* entry
// points with C linkage; the static helpers stay private. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings.

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const angularMode_t = runtime.angularMode_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const realChangeSign = runtime.realChangeSign;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_NONE = runtime.ERROR_NONE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

// const_2 has a runtime accessor.
inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}
inline fn const_1on2() *const real_t {
    return runtime.z47_math_wrappers_const_1on2();
}

const abi = @import("abi");
const math_real_predicates = @import("math_real_predicates.zig");
const math_command_wrappers = @import("math_command_wrappers.zig"); // M-callconv: Zig-to-Zig
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_inverse_trig_command = @import("math_inverse_trig_command.zig"); // M-callconv: Zig-to-Zig
const math_ln_complex = @import("math_ln_complex.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("math_wp34s.zig"); // M-callconv: Zig-to-Zig
const consts = abi.constants;

// real ops / predicates not in runtime.
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
// real ops with a *align(1) const operand (blob constants).
extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *align(1) const real_t, real_context: *realContext_t) *real_t;
inline fn realMultiplyBlob(op1: *const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
extern fn decNumberSubtract(result: *real_t, lhs: *const real_t, rhs: *align(1) const real_t, real_context: *realContext_t) *real_t;
inline fn realSubtractBlob(op1: *const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
extern fn decNumberAdd(result: *real_t, lhs: *const real_t, rhs: *align(1) const real_t, real_context: *realContext_t) *real_t;
inline fn realAddBlob(op1: *const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}

const realIsPositive = math_real_predicates.realIsPositive;

// Cross-domain externs.

fn gdError(gd: bool, errorCode: u8) void {
    displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE, REGISTER_X);
    if (gd) {
        moreInfoOnError("In function fnGd:", "cannot calculate gd", null, null);
    } else {
        moreInfoOnError("In function fnInvGd:", "cannot calculate invGd", null, null);
    }
}

fn gdReal(gd: bool) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    const errorCode = if (gd) GudermannianReal(&x, &x, &runtime.ctxtReal39) else InverseGudermannianReal(&x, &x, &runtime.ctxtReal39);

    if (errorCode != ERROR_NONE) {
        gdError(gd, errorCode);
    } else {
        runtime.convertRealToResultRegister(&x, REGISTER_X, amNone);
    }
}

fn gdCplx(gd: bool) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag)) {
        return;
    }

    const errorCode = if (gd)
        GudermannianComplex(&xReal, &xImag, &xReal, &xImag, &runtime.ctxtReal39)
    else
        InverseGudermannianComplex(&xReal, &xImag, &xReal, &xImag, &runtime.ctxtReal39);

    if (errorCode != ERROR_NONE) {
        gdError(gd, errorCode);
    } else {
        runtime.convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
    }
}

pub export fn GudermannianReal(x: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    if (realIsInfinite(x)) {
        if (realIsPositive(x)) {
            realCopy(consts.const39piOn2(), res);
        } else {
            realCopy(consts.const39piOn2(), res);
            realChangeSign(res);
        }
    } else {
        // Gd(x) = 2 * Arctan(Exp(x)) - PI/2
        math_command_wrappers.realExp(x, res, realContext);
        math_wp34s.C47_WP34S_Atan(res, res, realContext);
        realMultiply(res, const_2(), res, realContext);
        realSubtractBlob(res, consts.const39piOn2(), res, realContext);
    }

    return ERROR_NONE;
}

pub export fn GudermannianComplex(xReal: *const real_t, xImag: *const real_t, resReal: *real_t, resImag: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    // Gd(x) = 2 * Arctan(Exp(x)) - PI/2
    math_command_wrappers.expComplex(xReal, xImag, resReal, resImag, realContext);
    _ = math_inverse_trig_command.ArctanComplex(resReal, resImag, resReal, resImag, realContext);

    realMultiply(resReal, const_2(), resReal, realContext);
    realMultiply(resImag, const_2(), resImag, realContext);
    realSubtractBlob(resReal, consts.const39piOn2(), resReal, realContext);

    return ERROR_NONE;
}

pub export fn InverseGudermannianReal(x: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    var result: u8 = ERROR_NONE;

    // InvGd(x) = Ln(Tan(x/2 + PI/4))
    if (!realIsNaN(x) and math_comparison_reals.realCompareAbsLessThan(x, consts.const39piOn2())) {
        if (realIsZero(x)) {
            realSetZero(res);
        } else {
            var sin: real_t = undefined;
            var cos: real_t = undefined;

            // InvGd(x) = Ln(Tan(x/2 + PI/4)), -PI/2 < x < PI/2
            realMultiply(x, const_1on2(), res, realContext); // r = x/2
            realAddBlob(res, consts.const39piOn4(), res, realContext); // r = x/2 + pi/4
            math_wp34s.C47_WP34S_Cvt2RadSinCosTan(res, amRadian, &sin, &cos, res, &runtime.ctxtReal39); // r = Tan(x/2 + pi/4)
            math_wp34s.WP34S_Ln(res, res, &runtime.ctxtReal39); // r = Ln(Tan(x/2 + pi/4))
        }
    } else {
        result = ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
    }

    return result;
}

pub export fn InverseGudermannianComplex(xReal: *const real_t, xImag: *const real_t, resReal: *real_t, resImag: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    // InvGd(x) = Ln(Tan(x / 2 + PI / 4))
    realMultiply(xReal, const_1on2(), resReal, realContext); // r = x/2
    realMultiply(xImag, const_1on2(), resImag, realContext);

    realAddBlob(xReal, consts.const39piOn4(), resReal, realContext); // r = x/2 + pi/2

    _ = math_command_wrappers.TanComplex(resReal, resImag, resReal, resImag, realContext); // r = Tan(x/2 + pi/4)
    math_ln_complex.lnComplex(resReal, resImag, resReal, resImag, realContext); // r = Ln(Tan(x/2 + pi/4))

    return ERROR_NONE;
}

fn doGdReal() callconv(.c) void {
    gdReal(true);
}

fn doInvGdReal() callconv(.c) void {
    gdReal(false);
}

fn doGdCplx() callconv(.c) void {
    gdCplx(true);
}

fn doInvGdCplx() callconv(.c) void {
    gdCplx(false);
}

pub export fn fnGd(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&doGdReal, &doGdCplx);
}

pub export fn fnInvGd(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&doInvGdReal, &doInvGdCplx);
}
