// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/gd.c: the Gudermannian gd and inverse gd
// functions, real and complex. Faithful line-by-line translation preserving
// the exact order of every real_t operation (gd.txt / invGd.txt check results
// to the last ULP). Exports fnGd, fnInvGd and the four Gudermannian* entry
// points with C linkage; the static helpers stay private.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realFMA = runtime.realFMA;
const realSquareRoot = runtime.realSquareRoot;
const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;
const realChangeSign = runtime.realChangeSign;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_NONE = runtime.ERROR_NONE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}
inline fn const_1on2() *const real_t {
    return runtime.z47_math_wrappers_const_1on2();
}
inline fn const__1() *const real_t {
    return runtime.z47_math_wrappers_const_minus_1();
}
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}
// pi/2 and 2 pi at the caller's width: 75 digits above a 39-digit context.
inline fn piOn2For(realContext: *const realContext_t) *const real_t {
    return if (realContext.digits > 39) runtime.z47_math_wrappers_const75_piOn2() else runtime.z47_math_wrappers_const_piOn2();
}
inline fn twoPiFor(realContext: *const realContext_t) *const real_t {
    return if (realContext.digits > 39) consts.const75_2pi() else consts.const39_2pi();
}

const abi = @import("abi");
const math_real_predicates = @import("../compare/real_predicates.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_inverse_trig_command = @import("../trig/inverse_trig_command.zig");
const math_wp34s = @import("wp34s.zig");
const consts = abi.constants;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

const realIsPositive = math_real_predicates.realIsPositive;

fn gdError(gd: bool, errorCode: u8) void {
    displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE);
    if (!runtime.extra_info_on_calc_error) {
        return;
    }
    // ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats this hint into
    // the shared errorMessage buffer of that size.
    var buffer: [512]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, false, false));
    if (gd) {
        const message = runtime.bufPrintZ(&buffer, "cannot calculate gd({s})", .{type_name}) catch "";
        moreInfoOnError("In function fnGd:", message, null, null);
    } else {
        const message = runtime.bufPrintZ(&buffer, "cannot calculate invGd({s})", .{type_name}) catch "";
        moreInfoOnError("In function fnInvGd:", message, null, null);
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
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &x)) {
        return;
    }

    const errorCode = if (gd)
        GudermannianComplex(&x, &x, &runtime.ctxtReal39)
    else
        InverseGudermannianComplex(&x, &x, &runtime.ctxtReal39);

    if (errorCode != ERROR_NONE) {
        gdError(gd, errorCode);
    } else {
        runtime.convertComplexToResultRegister(&x, REGISTER_X);
    }
}

pub export fn GudermannianReal(x: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    const piOn2 = piOn2For(realContext);

    if (realIsZero(x)) {
        if (realIsNegative(x)) {
            realDivide(const__1(), const_plusInfinity(), res, realContext);
        } else {
            realSetZero(res);
        }
    } else if (realIsInfinite(x)) {
        if (realIsPositive(x)) {
            realCopy(piOn2, res);
        } else {
            realCopy(piOn2, res);
            realChangeSign(res);
        }
    } else {
        // Gd(x) = 2*atan(tanh(x/2)).
        realMultiply(x, const_1on2(), res, realContext);
        math_wp34s.WP34S_Tanh(res, res, realContext);
        math_wp34s.C47_WP34S_Atan(res, res, realContext);
        realMultiply(res, const_2(), res, realContext);
    }

    return ERROR_NONE;
}

pub export fn GudermannianComplex(x: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) u8 {
    const twoPi = twoPiFor(realContext);
    var cosine: real_t = undefined;
    var tangent: cplx_t = undefined;
    const nonnegativeReal = !realIsNegative(&x.Real);

    realMultiply(&x.Real, const_1on2(), &tangent.Real, realContext);
    realMultiply(&x.Imag, const_1on2(), &tangent.Imag, realContext);
    _ = runtime.TanhComplex(&tangent, &tangent, realContext);
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&x.Imag, amRadian, null, &cosine, null, realContext);
    _ = runtime.ArctanComplex(&tangent, res, realContext);
    realMultiply(&res.Real, const_2(), &res.Real, realContext);
    realMultiply(&res.Imag, const_2(), &res.Imag, realContext);

    // The defining branch differs from 2*atan(tanh(z/2)) by -2*pi when Re(z) is
    // nonnegative and cos(Im(z)) is negative; both tests precede aliased output.
    if (nonnegativeReal and realIsNaN(&cosine)) {
        // cos(Im(z)) is NaN for an infinite or NaN Im(z), where the branch is
        // unknown: gd(+inf + iy) is pi/2 or -3pi/2 by the sign of cos(y).
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
    } else if (nonnegativeReal and realIsNegative(&cosine)) {
        realSubtract(&res.Real, twoPi, &res.Real, realContext);
    }

    return ERROR_NONE;
}

pub export fn InverseGudermannianReal(x: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) u8 {
    const piOn2 = piOn2For(realContext);
    var result: u8 = ERROR_NONE;

    if (realIsNaN(x)) {
        realSetNaN(res);
        return result;
    }

    // InvGd(x) = Ln(Tan(x/2 + PI/4))
    if (math_comparison_reals.realCompareAbsLessThan(x, piOn2)) {
        if (realIsZero(x)) {
            if (realIsNegative(x)) {
                realDivide(const__1(), const_plusInfinity(), res, realContext);
            } else {
                realSetZero(res);
            }
        } else {
            var sin: real_t = undefined;
            var cos: real_t = undefined;

            // InvGd(x) = asinh(tan(x)), -pi/2 < x < pi/2.
            math_wp34s.C47_WP34S_Cvt2RadSinCosTan(x, amRadian, &sin, &cos, res, realContext);
            _ = math_inverse_trig_command.ArcsinhReal(res, res, realContext);
        }
    } else {
        result = ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
    }

    return result;
}

pub export fn InverseGudermannianComplex(x: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) u8 {
    var sine: real_t = undefined;
    var cosine: real_t = undefined;
    var sinhImag: real_t = undefined;
    var modulus: real_t = undefined;

    // With z = a + ib and c = cos a + i sinh b, InvGd(z) = asinh(sin a / |c|) + i arg(c):
    // asinh(tan z) where cos a > 0, and i pi - asinh(tan z), or -i pi - asinh(tan z)
    // for b < 0, where cos a < 0. For a large |b|, tan z comes within e^(-2|b|) of
    // +-i, the branch points of asinh, and asinh(tan z) loses those digits.
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&x.Real, amRadian, &sine, &cosine, null, realContext);
    math_wp34s.WP34S_SinhCosh(&x.Imag, &sinhImag, null, realContext);
    realMultiply(&cosine, &cosine, &modulus, realContext);
    realFMA(&sinhImag, &sinhImag, &modulus, &modulus, realContext);
    realSquareRoot(&modulus, &modulus, realContext);
    realDivide(&sine, &modulus, &res.Real, realContext);
    _ = math_inverse_trig_command.ArcsinhReal(&res.Real, &res.Real, realContext);
    math_wp34s.C47_WP34S_Atan2(&sinhImag, &cosine, &res.Imag, realContext);

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
