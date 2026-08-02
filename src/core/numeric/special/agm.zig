// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1e_37 = consts.const_1e_37;
const const39_pi = consts.const39_pi;
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
const math_multiplication_cells = @import("../arithmetic/multiplication_cells.zig");
const math_transform_complex_helpers = @import("../transform/transform_complex_helpers.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realSquareRoot = runtime.realSquareRoot;
const realFMA = runtime.realFMA;
const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realChangeSign = runtime.realChangeSign;
const realRectangularToPolar = runtime.realRectangularToPolar;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const FLAG_CPXRES: u16 = 0x8004;

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

// Blob-offset constants without a runtime accessor.

extern fn realSetOne(value: *real_t) void;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}

// WP34S_RelativeError with a *align(1) const tolerance (const_1e_37 is blob).

// Complex helpers.

const AGM_MODE = enum(c_int) {
    AGM_MODE_NORMAL = 0,
    AGM_MODE_E = 1,
    AGM_MODE_STEP = 2,
};
const AGM_MODE_NORMAL = AGM_MODE.AGM_MODE_NORMAL;
const AGM_MODE_E = AGM_MODE.AGM_MODE_E;
const AGM_MODE_STEP = AGM_MODE.AGM_MODE_STEP;

fn _realAgm(mode: AGM_MODE, a: *const real_t, b: *const real_t, c: ?*real_t, res: *real_t, _a: ?[*]real_t, _b: ?[*]real_t, _sz: usize, realContext: *realContext_t) c_int {
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var cReal: real_t = undefined;
    var cCoeff: real_t = undefined;
    var n: c_int = 0;

    realCopy(a, &aReal);
    realCopy(b, &bReal);
    if (mode == AGM_MODE_E) {
        realSetOne(&cCoeff);
    }
    if (mode == AGM_MODE_STEP) {
        realCopy(&aReal, &_a.?[0]);
        realCopy(&bReal, &_b.?[0]);
    }

    while (!math_wp34s.WP34S_RelativeError(&aReal, &bReal, const_1e_37(), realContext)) {
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
            if (n >= @as(c_int, @intCast(_sz)) - 1) {
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

fn _complexAgm(mode: AGM_MODE, ar: *const real_t, ai: *const real_t, br: *const real_t, bi: *const real_t, cr: ?*real_t, ci: ?*real_t, resr: *real_t, resi: *real_t, _ar: ?[*]real_t, _ai: ?[*]real_t, _br: ?[*]real_t, _bi: ?[*]real_t, _sz: usize, realContext: *realContext_t) c_int {
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var cReal: real_t = undefined;
    var aImag: real_t = undefined;
    var bImag: real_t = undefined;
    var cImag: real_t = undefined;
    var aArg: real_t = undefined;
    var bArg: real_t = undefined;
    var cArg: real_t = undefined;
    var cCoeff: real_t = undefined;
    var n: c_int = 0;

    realCopy(ar, &aReal);
    realCopy(ai, &aImag);
    realCopy(br, &bReal);
    realCopy(bi, &bImag);
    if (mode == AGM_MODE_E) {
        realSetOne(&cCoeff);
    }
    if (mode == AGM_MODE_STEP) {
        realCopy(&aReal, &_ar.?[0]);
        realCopy(&aImag, &_ai.?[0]);
        realCopy(&bReal, &_br.?[0]);
        realCopy(&bImag, &_bi.?[0]);
    }

    while (!math_wp34s.WP34S_RelativeError(&aReal, &bReal, const_1e_37(), realContext) or !math_wp34s.WP34S_RelativeError(&aImag, &bImag, const_1e_37(), realContext)) {
        if (mode == AGM_MODE_E) {
            realMultiply(&cCoeff, const_2(), &cCoeff, realContext);
            realSubtract(&aReal, &bReal, &cReal, realContext);
            realSubtract(&aImag, &bImag, &cImag, realContext); // c = a - b
            realMultiply(&cReal, const_1on2(), &cReal, realContext);
            realMultiply(&cImag, const_1on2(), &cImag, realContext); // c = (a - b) / 2
            math_multiplication_cells.mulComplexComplex(&cReal, &cImag, &cReal, &cImag, &cReal, &cImag, realContext); // c^2
            realFMA(&cReal, &cCoeff, cr.?, cr.?, realContext);
            realFMA(&cImag, &cCoeff, ci.?, ci.?, realContext);
        }

        realRectangularToPolar(&aReal, &aImag, &cReal, &aArg, realContext);
        realRectangularToPolar(&bReal, &bImag, &cReal, &bArg, realContext);
        realAdd(&aReal, &bReal, &cReal, realContext); // c = a + b real part
        realAdd(&aImag, &bImag, &cImag, realContext); // c = a + b imag part

        math_multiplication_cells.mulComplexComplex(&aReal, &aImag, &bReal, &bImag, &bReal, &bImag, realContext); // b = a * b

        // b = sqrt(a * b)
        math_transform_complex_helpers.sqrtComplex(&bReal, &bImag, &bReal, &bImag, realContext);

        realMultiply(&cReal, const_1on2(), &aReal, realContext); // a = (a + b) / 2 real part
        realMultiply(&cImag, const_1on2(), &aImag, realContext); // a = (a + b) / 2 imag part

        n += 1;

        // choose appropriate one of 2 square roots
        realRectangularToPolar(&bReal, &bImag, &cReal, &cArg, realContext);
        realSubtract(&aArg, &cArg, &aArg, realContext);
        realSetPositiveSign(&aArg);
        realSubtract(&cArg, &bArg, &cArg, realContext);
        realSetPositiveSign(&cArg);
        realAdd(&aArg, &cArg, &bArg, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&bArg, const39_pi())) {
            realChangeSign(&bReal);
            realChangeSign(&bImag);
        }

        if (mode == AGM_MODE_STEP) {
            realCopy(&aReal, &_ar.?[@intCast(n)]);
            realCopy(&aImag, &_ai.?[@intCast(n)]);
            realCopy(&bReal, &_br.?[@intCast(n)]);
            realCopy(&bImag, &_bi.?[@intCast(n)]);
            if (n >= @as(c_int, @intCast(_sz)) - 1) {
                break;
            }
        }
    }

    if (mode == AGM_MODE_E) {
        realMultiply(cr.?, const_1on2(), cr.?, realContext);
        realMultiply(ci.?, const_1on2(), ci.?, realContext);
    }

    realCopy(&aReal, resr);
    realCopy(&aImag, resi);
    return n;
}

pub export fn realAgm(a: *const real_t, b: *const real_t, res: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_NORMAL, a, b, null, res, null, null, 0, realContext));
}

pub export fn complexAgm(ar: *const real_t, ai: *const real_t, br: *const real_t, bi: *const real_t, resr: *real_t, resi: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_NORMAL, ar, ai, br, bi, null, null, resr, resi, null, null, null, null, 0, realContext));
}

pub export fn realAgmForE(a: *const real_t, b: *const real_t, c: *real_t, res: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_E, a, b, c, res, null, null, 0, realContext));
}

pub export fn complexAgmForE(ar: *const real_t, ai: *const real_t, br: *const real_t, bi: *const real_t, cr: *real_t, ci: *real_t, resr: *real_t, resi: *real_t, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_E, ar, ai, br, bi, cr, ci, resr, resi, null, null, null, null, 0, realContext));
}

pub export fn realAgmStep(a: *const real_t, b: *const real_t, res: *real_t, aStep: [*]real_t, bStep: [*]real_t, bufSize: usize, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_realAgm(AGM_MODE_STEP, a, b, null, res, aStep, bStep, bufSize, realContext));
}

pub export fn complexAgmStep(ar: *const real_t, ai: *const real_t, br: *const real_t, bi: *const real_t, resr: *real_t, resi: *real_t, aStep: [*]real_t, aiStep: [*]real_t, bStep: [*]real_t, biStep: [*]real_t, bufSize: usize, realContext: *realContext_t) callconv(.c) usize {
    return @intCast(_complexAgm(AGM_MODE_STEP, ar, ai, br, bi, null, null, resr, resi, aStep, aiStep, bStep, biStep, bufSize, realContext));
}

// Complex AGM from the stack
fn doComplexAGM() callconv(.c) void {
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var rReal: real_t = undefined;
    var aImag: real_t = undefined;
    var bImag: real_t = undefined;
    var rImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &aReal, &aImag) or !runtime.getRegisterAsComplex(REGISTER_Y, &bReal, &bImag)) {
        return;
    }

    _ = complexAgm(&aReal, &aImag, &bReal, &bImag, &rReal, &rImag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}

// Real AGM from the stack
fn doRealAGM() callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &a) or !runtime.getRegisterAsReal(REGISTER_Y, &b)) {
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
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function doRealAGM:", "cannot use negative X and Y as input of AGM", null, null);
        }
    } else {
        _ = realAgm(&a, &b, &r, &runtime.ctxtReal75);
        runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
    }
}

pub export fn fnAgm(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&doRealAGM, &doComplexAGM);
}
