// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1e_37 = consts.const_1e_37;
const const_1e_49 = consts.const_1e_49;
const const_1e_71 = consts.const_1e_71;
const const39_pi = consts.const39_pi;
const const_NaN = consts.const_NaN;
//
// Zig owner for src/c47/mathematics/agm.c: the arithmetic-geometric mean, real
// and complex, with the NORMAL / E (for the second elliptic integral) / STEP
// variants. Faithful line-by-line translation preserving the exact order of
// every real_t operation (agm.txt checks results to the last ULP). Exports
// fnAgm and the realAgm* / complexAgm* helpers with C linkage; the static
// _realAgm / _complexAgm stay private. The EXTRA_INFO_ON_CALC_ERROR sprintf
// hint becomes a fixed moreInfoOnError string.

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realSquareRoot = runtime.realSquareRoot;
const realFMA = runtime.realFMA;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsInfinite = runtime.realIsInfinite;
const realIsSpecial = runtime.realIsSpecial;
const realIsNegative = runtime.realIsNegative;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realSetNaN = runtime.realSetNaN;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realChangeSign = runtime.realChangeSign;
const realRectangularToPolar = runtime.realRectangularToPolar;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const FLAG_CPXRES: u16 = 0x8004;
const FLAG_SPCRES = runtime.FLAG_SPCRES;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
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

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

// The convergence tolerance for the context width.
fn agmTolerance(realContext: *const realContext_t) *const real_t {
    if (realContext.digits <= 39) {
        return const_1e_37();
    } else if (realContext.digits <= 51) {
        return const_1e_49();
    } else {
        return const_1e_71();
    }
}

const AGM_MODE = enum(c_int) {
    AGM_MODE_NORMAL = 0,
    AGM_MODE_E = 1,
    AGM_MODE_STEP = 2,
};
const AGM_MODE_NORMAL = AGM_MODE.AGM_MODE_NORMAL;
const AGM_MODE_E = AGM_MODE.AGM_MODE_E;
const AGM_MODE_STEP = AGM_MODE.AGM_MODE_STEP;

fn _realAgm(mode: AGM_MODE, a: *const real_t, b: *const real_t, c: ?*real_t, res: *real_t, _a: ?[*]real_t, _b: ?[*]real_t, _sz: usize, realContext: *realContext_t) i32 {
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var cReal: real_t = undefined;
    var cCoeff: real_t = undefined;
    const tol = agmTolerance(realContext);
    var n: i32 = 0;

    realCopy(a, &aReal);
    realCopy(b, &bReal);
    if (mode == AGM_MODE_E) {
        realSetOne(&cCoeff);
    }
    if (mode == AGM_MODE_STEP) {
        realCopy(&aReal, &_a.?[0]);
        realCopy(&bReal, &_b.?[0]);
    }

    // a NaN or infinite mean never meets the tolerance, so the iteration also ends on one
    while (!realIsSpecial(&aReal) and !math_wp34s.WP34S_RelativeError(&aReal, &bReal, tol, realContext)) {
        if (mode == AGM_MODE_E) {
            realMultiply(&cCoeff, const_2(), &cCoeff, realContext);
            realSubtract(&aReal, &bReal, &cReal, realContext); // c = a - b
            realMultiply(&cReal, const_1on2(), &cReal, realContext); // c = (a - b) / 2
            realMultiply(&cReal, &cReal, &cReal, realContext); // c^2
            realFMA(&cReal, &cCoeff, c.?, c.?, realContext);
        }
        realAdd(&aReal, &bReal, &cReal, realContext); // c = a + b
        realMultiply(&aReal, &bReal, &bReal, realContext); // b = a * b
        realSquareRoot(&bReal, &bReal, realContext); // b = sqrt(a * b)
        realMultiply(&cReal, const_1on2(), &aReal, realContext); // a = (a + b) / 2
        n += 1;
        if (mode == AGM_MODE_STEP) {
            realCopy(&aReal, &_a.?[@intCast(n)]);
            realCopy(&bReal, &_b.?[@intCast(n)]);
            if (n >= @as(i32, @intCast(_sz)) - 1) {
                break;
            }
        }
    }

    if (mode == AGM_MODE_E) {
        realMultiply(c.?, const_1on2(), c.?, realContext);
    }

    realCopy(&aReal, res);
    return n;
}

fn _complexAgm(mode: AGM_MODE, a0: *const cplx_t, b0: *const cplx_t, cSum: ?*cplx_t, res: *cplx_t, _a: ?[*]cplx_t, _b: ?[*]cplx_t, _sz: usize, realContext: *realContext_t) i32 {
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var c: cplx_t = undefined;
    var aArg: real_t = undefined;
    var bArg: real_t = undefined;
    var cArg: real_t = undefined;
    var cCoeff: real_t = undefined;
    const tol = agmTolerance(realContext);
    var n: i32 = 0;

    realCopy(&a0.Real, &a.Real);
    realCopy(&a0.Imag, &a.Imag);
    realCopy(&b0.Real, &b.Real);
    realCopy(&b0.Imag, &b.Imag);
    if (mode == AGM_MODE_E) {
        realSetOne(&cCoeff);
    }
    if (mode == AGM_MODE_STEP) {
        realCopy(&a.Real, &_a.?[0].Real);
        realCopy(&a.Imag, &_a.?[0].Imag);
        realCopy(&b.Real, &_b.?[0].Real);
        realCopy(&b.Imag, &_b.?[0].Imag);
    }

    // a NaN or infinite mean never meets the tolerance, so the iteration also ends on one
    while (!realIsSpecial(&a.Real) and !realIsSpecial(&a.Imag) and
        (!math_wp34s.WP34S_RelativeError(&a.Real, &b.Real, tol, realContext) or !math_wp34s.WP34S_RelativeError(&a.Imag, &b.Imag, tol, realContext)))
    {
        if (mode == AGM_MODE_E) {
            realMultiply(&cCoeff, const_2(), &cCoeff, realContext);
            realSubtract(&a.Real, &b.Real, &c.Real, realContext);
            realSubtract(&a.Imag, &b.Imag, &c.Imag, realContext); // c = a - b
            realMultiply(&c.Real, const_1on2(), &c.Real, realContext);
            realMultiply(&c.Imag, const_1on2(), &c.Imag, realContext); // c = (a - b) / 2
            runtime.mulComplexComplex(&c, &c, &c, realContext); // c^2
            realFMA(&c.Real, &cCoeff, &cSum.?.Real, &cSum.?.Real, realContext);
            realFMA(&c.Imag, &cCoeff, &cSum.?.Imag, &cSum.?.Imag, realContext);
        }

        realRectangularToPolar(&a, c.mag(), &aArg, realContext);
        realRectangularToPolar(&b, c.mag(), &bArg, realContext);
        realAdd(&a.Real, &b.Real, &c.Real, realContext); // c = a + b real part
        realAdd(&a.Imag, &b.Imag, &c.Imag, realContext); // c = a + b imag part

        runtime.mulComplexComplex(&a, &b, &b, realContext); // b = a * b

        // b = sqrt(a * b)
        runtime.sqrtComplex(&b, &b, realContext);

        realMultiply(&c.Real, const_1on2(), &a.Real, realContext); // a = (a + b) / 2 real part
        realMultiply(&c.Imag, const_1on2(), &a.Imag, realContext); // a = (a + b) / 2 imag part

        n += 1;

        // choose appropriate one of 2 square roots
        realRectangularToPolar(&b, c.mag(), &cArg, realContext);
        realSubtract(&aArg, &cArg, &aArg, realContext);
        realSetPositiveSign(&aArg);
        realSubtract(&cArg, &bArg, &cArg, realContext);
        realSetPositiveSign(&cArg);
        realAdd(&aArg, &cArg, &bArg, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&bArg, const39_pi())) {
            realChangeSign(&b.Real);
            realChangeSign(&b.Imag);
        }

        if (mode == AGM_MODE_STEP) {
            const ni: usize = @intCast(n);
            realCopy(&a.Real, &_a.?[ni].Real);
            realCopy(&a.Imag, &_a.?[ni].Imag);
            realCopy(&b.Real, &_b.?[ni].Real);
            realCopy(&b.Imag, &_b.?[ni].Imag);
            if (n >= @as(i32, @intCast(_sz)) - 1) {
                break;
            }
        }
    }

    if (mode == AGM_MODE_E) {
        realMultiply(&cSum.?.Real, const_1on2(), &cSum.?.Real, realContext);
        realMultiply(&cSum.?.Imag, const_1on2(), &cSum.?.Imag, realContext);
    }

    realCopy(&a.Real, &res.Real);
    realCopy(&a.Imag, &res.Imag);
    return n;
}

pub export fn realAgm(a: *const real_t, b: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_NORMAL, a, b, null, res, null, null, 0, realContext));
}

pub export fn complexAgm(a: *const cplx_t, b: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_NORMAL, a, b, null, res, null, null, 0, realContext));
}

pub export fn realAgmForE(a: *const real_t, b: *const real_t, c: *real_t, res: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_E, a, b, c, res, null, null, 0, realContext));
}

pub export fn complexAgmForE(a: *const cplx_t, b: *const cplx_t, c: *cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_E, a, b, c, res, null, null, 0, realContext));
}

pub export fn realAgmStep(a: *const real_t, b: *const real_t, res: *real_t, aStep: [*]real_t, bStep: [*]real_t, bufSize: usize, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_STEP, a, b, null, res, aStep, bStep, bufSize, realContext));
}

pub export fn complexAgmStep(a: *const cplx_t, b: *const cplx_t, res: *cplx_t, aStep: [*]cplx_t, bStep: [*]cplx_t, bufSize: usize, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_STEP, a, b, null, res, aStep, bStep, bufSize, realContext));
}

// Complex AGM from the stack
fn doComplexAGM() callconv(.c) void {
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &a) or !runtime.getRegisterAsComplex(REGISTER_Y, &b)) {
        return;
    }

    if (realIsNaN(&a.Real) or realIsNaN(&a.Imag) or realIsNaN(&b.Real) or realIsNaN(&b.Imag)) {
        realSetNaN(&r.Real);
        realSetNaN(&r.Imag);
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
        return;
    }

    if (realIsInfinite(&a.Real) or realIsInfinite(&a.Imag) or realIsInfinite(&b.Real) or realIsInfinite(&b.Imag)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            return;
        }

        if (realIsZero(&a.Imag) and realIsZero(&b.Imag) and
            runtime.realCompareGreaterEqual(&a.Real, const_0()) and runtime.realCompareGreaterEqual(&b.Real, const_0()))
        {
            if (realIsZero(&a.Real) or realIsZero(&b.Real)) {
                realSetZero(&r.Real);
            } else {
                realCopy(const_plusInfinity(), &r.Real);
            }
            realSetZero(&r.Imag);
        } else {
            realSetNaN(&r.Real);
            realSetNaN(&r.Imag);
        }
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
        return;
    }

    _ = complexAgm(&a, &b, &r, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&r, REGISTER_X);
}

// Real AGM from the stack
fn doRealAGM() callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &a) or !runtime.getRegisterAsReal(REGISTER_Y, &b)) {
        return;
    }

    if (realIsNaN(&a) or realIsNaN(&b)) {
        runtime.convertRealToResultRegister(const_NaN(), REGISTER_X, amNone);
        return;
    }

    // Quick check for zero results
    realAdd(&a, &b, &r, &runtime.ctxtReal39);
    if (realIsZero(&a) or realIsZero(&b) or realIsZero(&r)) {
        runtime.convertRealToResultRegister(const_0(), REGISTER_X, amNone);
        return;
    }

    if (realIsNegative(&a) or realIsNegative(&b)) {
        if (runtime.getFlag(FLAG_CPXRES)) {
            doComplexAGM();
        } else {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            moreInfoOnError("In function doRealAGM:", "cannot use negative X and Y as input of AGM", null, null);
        }
    } else if (realIsInfinite(&a) or realIsInfinite(&b)) {
        if (runtime.getSystemFlag(FLAG_SPCRES)) {
            runtime.convertRealToResultRegister(const_plusInfinity(), REGISTER_X, amNone);
        } else {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        }
    } else {
        _ = realAgm(&a, &b, &r, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
    }
}

pub export fn fnAgm(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&doRealAGM, &doComplexAGM);
}
