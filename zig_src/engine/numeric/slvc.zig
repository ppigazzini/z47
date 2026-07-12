// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1e_37 = consts.const_1e_37;
const const_1on2 = consts.const_1on2;
const const39_root3on2 = consts.const39_root3on2;
const const_2 = consts.const_2;
const const_3 = consts.const_3;
const const_4 = consts.const_4;
const const_9 = consts.const_9;
const const_54 = consts.const_54;
const const_2916 = consts.const_2916;
//
// Zig owner for src/c47/mathematics/slvc.c: solve cubic (SLVC). Exports
// slvc.h's fnSlvc, solveCubicEquation and solveCubicEquation159. Covered by
// slvc.txt (fnSlvc) plus eigen.txt (matrix.c calls both cubic solvers).
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). The Abramowitz &
// Stegun §3.8.2 scaling (9q, 54r, the /2916 discriminant), the s1/s2 cube-root
// combination, the _realCheckedAdd/_realCheckedSubtract condition-number
// cancellation guards, and the realIn real-root forcing are reproduced exactly.
// OPTION_CUBIC_159 and OPTION_EIGEN_159 are defined on every z47 build, so
// fnSlvc uses the 159-digit solveCubicEquation159; the standard 75-digit
// solveCubicEquation is still exported (matrix.c calls it). The qsort root
// ordering uses libc qsort with the exact cmplxSortCompare comparator. The dead
// SAVE_SPACE_DM42_12 guard and the #undef'd DISCRIMINANT blocks are omitted.

const runtime = @import("command_wrappers_runtime.zig");
const math_addition_cells = @import("arithmetic/addition_cells.zig"); // M-callconv: Zig-to-Zig
const math_comparison_reals = @import("comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_division_cells = @import("arithmetic/division_cells.zig"); // M-callconv: Zig-to-Zig
const math_multiplication_cells = @import("arithmetic/multiplication_cells.zig"); // M-callconv: Zig-to-Zig
const math_runtime_helpers = @import("runtime_helpers.zig"); // M-callconv: Zig-to-Zig
const math_slvq = @import("slvq.zig"); // M-callconv: Zig-to-Zig
const math_subtraction_cells = @import("arithmetic/subtraction_cells.zig"); // M-callconv: Zig-to-Zig
const math_transform_complex_helpers = @import("transform/transform_complex_helpers.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const REGISTER_T = runtime.REGISTER_T;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const TI_ROOTS3: u8 = 103;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
extern fn fnDropT(unused_but_mandatory_parameter: u16) void;
const realIsZero = runtime.realIsZero;

extern var temporaryInformation: u8;
extern fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, c: *real_t, cmplx: *bool) bool;

// real_t op helpers (operands *align(1) const so blob constants and 159-digit
// stack scratch both pass).
extern fn decNumberCopy(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberAdd(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSubtract(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMultiply(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberDivide(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSquareRoot(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;

inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubtract(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realSquareRoot(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSquareRoot(res, operand, ctxt);
}
inline fn realSetZero(r: *align(1) real_t) void {
    r.bits = 0;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}
inline fn realChangeSign(operand: *align(1) real_t) void {
    operand.bits ^= 0x80;
}
inline fn realSetPositiveSign(operand: *align(1) real_t) void {
    operand.bits &= 0x7F;
}
inline fn realIsZeroA(source: *align(1) const real_t) bool {
    return source.digits == 1 and source.lsu[0] == 0 and (source.bits & 0x70) == 0;
}
inline fn realIsNaNA(source: *align(1) const real_t) bool {
    return (source.bits & (0x20 | 0x10)) != 0;
}
inline fn realIsNegativeA(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}
inline fn realIsPositiveA(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}

extern fn decNumberCompare(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
inline fn realCompareM(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}

// Complex helpers (operands *align(1) const).

inline fn chsComplex(aReal: *align(1) real_t, aImag: *align(1) real_t) void {
    realChangeSign(aReal);
    realChangeSign(aImag);
}

// Blob constants.

// REAL_T_PTR(name, 159).
inline fn realMaxDigits(comptime digits: u32) u32 {
    return ((digits + 2) / 6) * 6 + 3;
}
inline fn realSizeInBytes(comptime digits: u32) u32 {
    return 10 + 2 * (realMaxDigits(digits) / 3);
}
fn BigReal(comptime digits: u32) type {
    return struct {
        buf: [realSizeInBytes(digits)]u8 align(4) = undefined,
        inline fn ptr(self: *@This()) *align(1) real_t {
            return @ptrCast(&self.buf);
        }
    };
}

// struct cmplxPair { real_t r, i; }
const cmplxPair = abi.CmplxPair;

extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;

// libc qsort for the exact (unstable) ordering of the 3 roots.
extern fn qsort(base: *anyopaque, nmemb: usize, size: usize, compar: *const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;

// ===========================================================================
// cmplxSortCompare
// ===========================================================================
fn cmplxSortCompare(v1: ?*const anyopaque, v2: ?*const anyopaque) linksection(runtime.code_section) callconv(.c) c_int {
    const p1: *const cmplxPair = @ptrCast(@alignCast(v1.?));
    const p2: *const cmplxPair = @ptrCast(@alignCast(v2.?));
    var v1a: real_t = undefined;
    var v2a: real_t = undefined;
    var c: real_t = undefined;

    math_runtime_helpers.complexMagnitude2(&p1.r, &p1.i, &v1a, &ctxtReal39);
    math_runtime_helpers.complexMagnitude2(&p2.r, &p2.i, &v2a, &ctxtReal39);

    // NaN's aren't interesting so sort largest
    if (realIsNaNA(&v1a)) {
        return if (realIsNaNA(&v2a)) 0 else 1;
    }
    if (realIsNaNA(&v2a)) {
        return -1;
    }

    // Zeros are uninteresting so sort larger
    if (realIsZeroA(&v1a)) {
        return if (realIsZeroA(&v2a)) 0 else 1;
    }
    if (realIsZeroA(&v2a)) {
        return -1;
    }

    // Complex values are less interesting than real ones
    if (realIsZeroA(&p1.i)) {
        if (!realIsZeroA(&p2.i)) {
            return -1;
        }
    } else if (realIsZeroA(&p2.i)) {
        return 1;
    }

    // Sort on magnitude
    realCompareM(&v1a, &v2a, &c, &ctxtReal75);
    if (!realIsZeroA(&c)) {
        return 1 - 2 * @as(c_int, @intFromBool(realIsNegativeA(&c)));
    }

    // Equal magnitude, favour positive roots over negative
    if (realIsNegativeA(&p1.r) and !realIsNegativeA(&p2.r)) {
        return 1;
    }
    if (!realIsNegativeA(&p1.r) and realIsNegativeA(&p2.r)) {
        return -1;
    }
    if (realIsNegativeA(&p1.i) and !realIsNegativeA(&p2.i)) {
        return 1;
    }
    if (!realIsNegativeA(&p1.i) and realIsNegativeA(&p2.i)) {
        return -1;
    }

    // Favour smaller real parts
    realCompareM(&p1.r, &p2.r, &c, &ctxtReal75);
    if (!realIsZeroA(&c)) {
        if (realIsNegativeA(&p1.r)) {
            return 1 - 2 * @as(c_int, @intFromBool(realIsPositiveA(&c)));
        }
        return 1 - 2 * @as(c_int, @intFromBool(realIsNegativeA(&c)));
    }

    // Favour smaller imaginary parts
    realCompareM(&p1.i, &p2.i, &c, &ctxtReal75);
    if (!realIsZeroA(&c)) {
        if (realIsNegativeA(&p1.i)) {
            return 1 - 2 * @as(c_int, @intFromBool(realIsPositiveA(&c)));
        } else {
            return 1 - 2 * @as(c_int, @intFromBool(realIsNegativeA(&c)));
        }
    }
    return 0;
}

// ===========================================================================
// fnSlvc
// ===========================================================================
// L2 error surface (REPORT-23 §6 P5): the core returns an error instead of
// calling displayCalcErrorMessage inline; the L3 shim maps it at the ABI edge.
const SlvcError = error{LeadingCoeffsAllZero};

fn reportSlvcError(e: SlvcError) void {
    switch (e) {
        error.LeadingCoeffsAllZero => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnSlvc:", "cannot use 0 for Y, Z and T as input of SLVC", null, null);
        },
    }
}

pub export fn fnSlvc(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    fnSlvcCore() catch |e| reportSlvcError(e);
}

fn fnSlvcCore() linksection(runtime.code_section) SlvcError!void {
    var complexCoefs: bool = false;
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var cReal: real_t = undefined;
    var dReal: real_t = undefined;
    var rReal: real_t = undefined;
    var aImag: real_t = undefined;
    var bImag: real_t = undefined;
    var cImag: real_t = undefined;
    var dImag: real_t = undefined;
    var rImag: real_t = undefined;
    var x: [3]cmplxPair = undefined;

    if (!(getRegisterAsComplexOrReal(REGISTER_X, &dReal, &dImag, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Y, &cReal, &cImag, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Z, &bReal, &bImag, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_T, &aReal, &aImag, &complexCoefs)))
    {
        return;
    }

    if (realIsZero(&aReal) and realIsZero(&aImag) and
        realIsZero(&bReal) and realIsZero(&bImag) and
        realIsZero(&cReal) and realIsZero(&cImag))
    {
        return error.LeadingCoeffsAllZero;
    }

    if (!saveLastX()) {
        return;
    }

    if (realIsZero(&aReal) and realIsZero(&aImag)) {
        math_slvq.solveQuadraticEquation(&bReal, &bImag, &cReal, &cImag, &dReal, &dImag, &rReal, &rImag, &x[0].r, &x[0].i, &x[1].r, &x[1].i, &ctxtReal75);
        realSetNaN(&x[2].r);
        realSetNaN(&x[2].i);
    } else {
        math_division_cells.divComplexComplex(&bReal, &bImag, &aReal, &aImag, &bReal, &bImag, &ctxtReal75);
        math_division_cells.divComplexComplex(&cReal, &cImag, &aReal, &aImag, &cReal, &cImag, &ctxtReal75);
        math_division_cells.divComplexComplex(&dReal, &dImag, &aReal, &aImag, &dReal, &dImag, &ctxtReal75);

        // OPTION_CUBIC_159 is defined on every z47 build -> 159-digit solver.
        var c159 = ctxtReal75;
        c159.digits = 159;
        var x1r_b = BigReal(159){};
        var x1i_b = BigReal(159){};
        var x2r_b = BigReal(159){};
        var x2i_b = BigReal(159){};
        var x3r_b = BigReal(159){};
        var x3i_b = BigReal(159){};
        var r0r_b = BigReal(159){};
        var r0i_b = BigReal(159){};
        var bRealH_b = BigReal(159){};
        var bImagH_b = BigReal(159){};
        var cRealH_b = BigReal(159){};
        var cImagH_b = BigReal(159){};
        var dRealH_b = BigReal(159){};
        var dImagH_b = BigReal(159){};
        const x1r = x1r_b.ptr();
        const x1i = x1i_b.ptr();
        const x2r = x2r_b.ptr();
        const x2i = x2i_b.ptr();
        const x3r = x3r_b.ptr();
        const x3i = x3i_b.ptr();
        const r0r = r0r_b.ptr();
        const r0i = r0i_b.ptr();
        const bRealH = bRealH_b.ptr();
        const bImagH = bImagH_b.ptr();
        const cRealH = cRealH_b.ptr();
        const cImagH = cImagH_b.ptr();
        const dRealH = dRealH_b.ptr();
        const dImagH = dImagH_b.ptr();

        realPlus(&bReal, bRealH, &c159);
        realPlus(&bImag, bImagH, &c159);
        realPlus(&cReal, cRealH, &c159);
        realPlus(&cImag, cImagH, &c159);
        realPlus(&dReal, dRealH, &c159);
        realPlus(&dImag, dImagH, &c159);
        realSetZero(r0r);
        realSetZero(r0i);
        realSetZero(x1r);
        realSetZero(x1i);
        realSetZero(x2r);
        realSetZero(x2i);
        realSetZero(x3r);
        realSetZero(x3i);
        solveCubicEquation159(bRealH, bImagH, cRealH, cImagH, dRealH, dImagH, r0r, r0i, x1r, x1i, x2r, x2i, x3r, x3i, &c159);
        realPlus(r0r, &rReal, &ctxtReal39);
        realPlus(r0i, &rImag, &ctxtReal39);
        realPlus(x1r, &x[0].r, &ctxtReal39);
        realPlus(x1i, &x[0].i, &ctxtReal39);
        realPlus(x2r, &x[1].r, &ctxtReal39);
        realPlus(x2i, &x[1].i, &ctxtReal39);
        realPlus(x3r, &x[2].r, &ctxtReal39);
        realPlus(x3i, &x[2].i, &ctxtReal39);
    }

    qsort(@ptrCast(&x), 3, @sizeOf(cmplxPair), &cmplxSortCompare);
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        if (realIsZeroA(&x[i].i) or (realIsNaNA(&x[i].r) and realIsNaNA(&x[i].i))) {
            convertRealToResultRegister(&x[i].r, REGISTER_X + @as(calcRegister_t, @intCast(i)), amNone);
        } else {
            convertComplexToResultRegister(&x[i].r, &x[i].i, REGISTER_X + @as(calcRegister_t, @intCast(i)));
        }
        adjustResult(REGISTER_X + @as(calcRegister_t, @intCast(i)), false, true, REGISTER_X + @as(calcRegister_t, @intCast(i)), -1, -1);
    }
    temporaryInformation = TI_ROOTS3;

    fnDropT(0);
}

// realSetNaN / realPlus on naturally-aligned and align(1) destinations.
extern fn realSetNaN(value: *align(1) real_t) void;
extern fn decNumberPlus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}

// solveQuadraticEquation lives in the slvq owner.

// ===========================================================================
// _checkConditionNumberOfAddSub
// ===========================================================================
fn _checkConditionNumberOfAddSub(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *align(1) const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var conditionNumber1: real_t = undefined;
    var conditionNumber2: real_t = undefined;
    var conditionNumber: *align(1) real_t = &conditionNumber1;

    if (realIsZeroA(res)) {
        return false;
    } else {
        realDivide(res, operand1, &conditionNumber1, realContext);
        realSetPositiveSign(&conditionNumber1);
        realDivide(res, operand2, &conditionNumber2, realContext);
        realSetPositiveSign(&conditionNumber2);
        if (realIsZeroA(operand1)) {
            conditionNumber = &conditionNumber2;
        } else if (realIsZeroA(operand2)) {
            conditionNumber = &conditionNumber1;
        } else if (math_comparison_reals.realCompareGreaterThan(&conditionNumber1, &conditionNumber2)) {
            conditionNumber = &conditionNumber2;
        } else {
            conditionNumber = &conditionNumber1;
        }
        return math_comparison_reals.realCompareLessThan(@alignCast(conditionNumber), const_1e_37());
    }
}

fn _realCheckedAdd(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var r: real_t = undefined;
    realAdd(operand1, operand2, &r, realContext);
    if (_checkConditionNumberOfAddSub(operand1, operand2, &r, realContext)) {
        realSetZero(res);
    } else {
        realCopy(&r, res);
    }
}

fn _realCheckedSubtract(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var r: real_t = undefined;
    realSubtract(operand1, operand2, &r, realContext);
    if (_checkConditionNumberOfAddSub(operand1, operand2, &r, realContext)) {
        realSetZero(res);
    } else {
        realCopy(&r, res);
    }
}

// ===========================================================================
// solveCubicEquation
// ===========================================================================
pub export fn solveCubicEquation(
    c2Real: *align(1) const real_t,
    c2Imag: *align(1) const real_t,
    c1Real: *align(1) const real_t,
    c1Imag: *align(1) const real_t,
    c0Real: *align(1) const real_t,
    c0Imag: *align(1) const real_t,
    rReal: *align(1) real_t,
    rImag: *align(1) real_t,
    x1Real: *align(1) real_t,
    x1Imag: *align(1) real_t,
    x2Real: *align(1) real_t,
    x2Imag: *align(1) real_t,
    x3Real: *align(1) real_t,
    x3Imag: *align(1) real_t,
    realContext: *realContext_t,
) linksection(runtime.code_section) callconv(.c) void {
    // x^3 + b x^2 + c x + d = 0  (Abramowitz & Stegun §3.8.2)
    var qr: real_t = undefined;
    var qi: real_t = undefined;
    var rr: real_t = undefined;
    var ri: real_t = undefined;
    var s1r: real_t = undefined;
    var s1i: real_t = undefined;
    var s2r: real_t = undefined;
    var s2i: real_t = undefined;
    var ar: real_t = undefined;
    var ai: real_t = undefined;
    const realIn = realIsZeroA(c2Imag) and realIsZeroA(c1Imag) and realIsZeroA(c0Imag);

    // q = (c - b^2 / 3) / 3 ; 9q = (3c - b^2)
    math_multiplication_cells.mulComplexReal(@alignCast(c1Real), @alignCast(c1Imag), const_3(), &rr, &ri, realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c2Real), @alignCast(c2Imag), &qr, &qi, realContext);
    math_subtraction_cells.subComplex(&rr, &ri, &qr, &qi, &qr, &qi, realContext);

    // r = (b c - 3 d) / 6 - b^3 / 27 ; 54r = 9(b c - 3 d) - 2 b^3
    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c1Real), @alignCast(c1Imag), &rr, &ri, realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(c0Real), @alignCast(c0Imag), const_3(), &ar, &ai, realContext);
    math_subtraction_cells.subComplex(&rr, &ri, &ar, &ai, &rr, &ri, realContext);
    math_multiplication_cells.mulComplexReal(&rr, &ri, const_9(), &rr, &ri, realContext);

    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c2Real), @alignCast(c2Imag), &ar, &ai, realContext);
    math_multiplication_cells.mulComplexComplex(&ar, &ai, @alignCast(c2Real), @alignCast(c2Imag), &ar, &ai, realContext);
    math_addition_cells.addComplex(&ar, &ai, &ar, &ai, &ar, &ai, realContext);
    math_subtraction_cells.subComplex(&rr, &ri, &ar, &ai, &rr, &ri, realContext);

    // q^3 + r^2 = (4 (9q)^3 + (54r)^2) / 2916
    math_multiplication_cells.mulComplexComplex(&qr, &qi, &qr, &qi, @alignCast(rReal), @alignCast(rImag), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(rReal), @alignCast(rImag), &qr, &qi, @alignCast(rReal), @alignCast(rImag), realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(rReal), @alignCast(rImag), const_4(), @alignCast(rReal), @alignCast(rImag), realContext);
    math_multiplication_cells.mulComplexComplex(&rr, &ri, &rr, &ri, &ar, &ai, realContext);
    math_addition_cells.addComplex(@alignCast(rReal), @alignCast(rImag), &ar, &ai, @alignCast(rReal), @alignCast(rImag), realContext);
    math_division_cells.divComplexReal(@alignCast(rReal), @alignCast(rImag), const_2916(), @alignCast(rReal), @alignCast(rImag), realContext);

    // Scale r back to its proper range.
    math_division_cells.divComplexReal(&rr, &ri, const_54(), &rr, &ri, realContext);

    // s1, s2 = cbrt(r ± sqrt(q^3 + r^2))
    math_transform_complex_helpers.sqrtComplex(@alignCast(rReal), @alignCast(rImag), &s1r, &s1i, realContext);
    math_subtraction_cells.subComplex(&rr, &ri, &s1r, &s1i, &s2r, &s2i, realContext);
    math_addition_cells.addComplex(&rr, &ri, &s1r, &s1i, &s1r, &s1i, realContext);
    math_transform_complex_helpers.curtComplex(&s1r, &s1i, &s1r, &s1i, realContext);
    math_transform_complex_helpers.curtComplex(&s2r, &s2i, &s2r, &s2i, realContext);

    // reusing q, r for (s1 ± s2)
    math_addition_cells.addComplex(&s1r, &s1i, &s2r, &s2i, &qr, &qi, realContext);
    math_subtraction_cells.subComplex(&s1r, &s1i, &s2r, &s2i, &rr, &ri, realContext);
    math_multiplication_cells.mulComplexComplex(&rr, &ri, const_0(), const39_root3on2(), &rr, &ri, realContext);

    // roots
    math_division_cells.divComplexReal(@alignCast(c2Real), @alignCast(c2Imag), const_3(), @alignCast(x2Real), @alignCast(x2Imag), realContext);
    _realCheckedSubtract(&qr, x2Real, x1Real, realContext);
    _realCheckedSubtract(&qi, x2Imag, x1Imag, realContext);
    math_multiplication_cells.mulComplexReal(&qr, &qi, const_1on2(), @alignCast(x3Real), @alignCast(x3Imag), realContext);
    _realCheckedAdd(x3Real, x2Real, x3Real, realContext);
    _realCheckedAdd(x3Imag, x2Imag, x3Imag, realContext);
    chsComplex(x3Real, x3Imag);
    _realCheckedAdd(x3Real, &rr, x2Real, realContext);
    _realCheckedAdd(x3Imag, &ri, x2Imag, realContext);
    _realCheckedSubtract(x3Real, &rr, x3Real, realContext);
    _realCheckedSubtract(x3Imag, &ri, x3Imag, realContext);

    // Force real outputs when the roots are known to be real
    if (realIn) {
        if (realIsZeroA(rReal) or realIsNegativeA(rImag)) {
            // Three real roots
            realSetZero(x1Imag);
            realSetZero(x2Imag);
            realSetZero(x3Imag);
        } else {
            // One real, two complex roots
            if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x1Imag), @alignCast(x2Imag))) {
                if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x1Imag), @alignCast(x3Imag))) {
                    realSetZero(x1Imag);
                } else {
                    realSetZero(x3Imag);
                }
            } else {
                if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x2Imag), @alignCast(x3Imag))) {
                    realSetZero(x2Imag);
                } else {
                    realSetZero(x3Imag);
                }
            }
        }
    }
}

// ===========================================================================
// solveCubicEquation159 (OPTION_CUBIC_159 / OPTION_EIGEN_159)
// ===========================================================================
pub export fn solveCubicEquation159(
    c2Real: *align(1) const real_t,
    c2Imag: *align(1) const real_t,
    c1Real: *align(1) const real_t,
    c1Imag: *align(1) const real_t,
    c0Real: *align(1) const real_t,
    c0Imag: *align(1) const real_t,
    rReal: *align(1) real_t,
    rImag: *align(1) real_t,
    x1Real: *align(1) real_t,
    x1Imag: *align(1) real_t,
    x2Real: *align(1) real_t,
    x2Imag: *align(1) real_t,
    x3Real: *align(1) real_t,
    x3Imag: *align(1) real_t,
    realContext: *realContext_t,
) linksection(runtime.code_section) callconv(.c) void {
    const realIn = realIsZeroA(c2Imag) and realIsZeroA(c1Imag) and realIsZeroA(c0Imag);

    // high-precision constant sqrt(3)/2
    var const159_root3on2_b = BigReal(159){};
    const const159_root3on2 = const159_root3on2_b.ptr();
    realSquareRoot(const_3(), const159_root3on2, realContext);
    realMultiply(const159_root3on2, const_1on2(), const159_root3on2, realContext);

    var qr_b = BigReal(159){};
    var qi_b = BigReal(159){};
    var rr_b = BigReal(159){};
    var ri_b = BigReal(159){};
    var s1r_b = BigReal(159){};
    var s1i_b = BigReal(159){};
    var s2r_b = BigReal(159){};
    var s2i_b = BigReal(159){};
    var ar_b = BigReal(159){};
    var ai_b = BigReal(159){};
    const qr = qr_b.ptr();
    const qi = qi_b.ptr();
    const rr = rr_b.ptr();
    const ri = ri_b.ptr();
    const s1r = s1r_b.ptr();
    const s1i = s1i_b.ptr();
    const s2r = s2r_b.ptr();
    const s2i = s2i_b.ptr();
    const ar = ar_b.ptr();
    const ai = ai_b.ptr();

    realSetZero(qr);
    realSetZero(qi);
    realSetZero(rr);
    realSetZero(ri);
    realSetZero(s1r);
    realSetZero(s1i);
    realSetZero(s2r);
    realSetZero(s2i);
    realSetZero(ar);
    realSetZero(ai);

    // q = (c - b^2 / 3) / 3 ; 9q = (3c - b^2)
    math_multiplication_cells.mulComplexReal(@alignCast(c1Real), @alignCast(c1Imag), const_3(), @alignCast(rr), @alignCast(ri), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c2Real), @alignCast(c2Imag), @alignCast(qr), @alignCast(qi), realContext);
    math_subtraction_cells.subComplex(@alignCast(rr), @alignCast(ri), @alignCast(qr), @alignCast(qi), @alignCast(qr), @alignCast(qi), realContext);

    // r = (b c - 3 d) / 6 - b^3 / 27 ; 54r = 9(b c - 3 d) - 2 b^3
    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c1Real), @alignCast(c1Imag), @alignCast(rr), @alignCast(ri), realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(c0Real), @alignCast(c0Imag), const_3(), @alignCast(ar), @alignCast(ai), realContext);
    math_subtraction_cells.subComplex(@alignCast(rr), @alignCast(ri), @alignCast(ar), @alignCast(ai), @alignCast(rr), @alignCast(ri), realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(rr), @alignCast(ri), const_9(), @alignCast(rr), @alignCast(ri), realContext);

    math_multiplication_cells.mulComplexComplex(@alignCast(c2Real), @alignCast(c2Imag), @alignCast(c2Real), @alignCast(c2Imag), @alignCast(ar), @alignCast(ai), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(ar), @alignCast(ai), @alignCast(c2Real), @alignCast(c2Imag), @alignCast(ar), @alignCast(ai), realContext);
    math_addition_cells.addComplex(@alignCast(ar), @alignCast(ai), @alignCast(ar), @alignCast(ai), @alignCast(ar), @alignCast(ai), realContext);
    math_subtraction_cells.subComplex(@alignCast(rr), @alignCast(ri), @alignCast(ar), @alignCast(ai), @alignCast(rr), @alignCast(ri), realContext);

    // discriminant using intermediate 159-digit variables
    var discrimR_b = BigReal(159){};
    var discrimI_b = BigReal(159){};
    const discrimR = discrimR_b.ptr();
    const discrimI = discrimI_b.ptr();
    realSetZero(discrimR);
    realSetZero(discrimI);

    // q^3 + r^2 = (4 (9q)^3 + (54r)^2) / 2916
    math_multiplication_cells.mulComplexComplex(@alignCast(qr), @alignCast(qi), @alignCast(qr), @alignCast(qi), @alignCast(discrimR), @alignCast(discrimI), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(discrimR), @alignCast(discrimI), @alignCast(qr), @alignCast(qi), @alignCast(discrimR), @alignCast(discrimI), realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(discrimR), @alignCast(discrimI), const_4(), @alignCast(discrimR), @alignCast(discrimI), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(rr), @alignCast(ri), @alignCast(rr), @alignCast(ri), @alignCast(ar), @alignCast(ai), realContext);
    math_addition_cells.addComplex(@alignCast(discrimR), @alignCast(discrimI), @alignCast(ar), @alignCast(ai), @alignCast(discrimR), @alignCast(discrimI), realContext);
    math_division_cells.divComplexReal(@alignCast(discrimR), @alignCast(discrimI), const_2916(), @alignCast(discrimR), @alignCast(discrimI), realContext);
    realCopy(discrimR, rReal);
    realCopy(discrimI, rImag);

    // Scale r back to its proper range.
    math_division_cells.divComplexReal(@alignCast(rr), @alignCast(ri), const_54(), @alignCast(rr), @alignCast(ri), realContext);

    // s1, s2 = cbrt(r ± sqrt(q^3 + r^2))
    math_transform_complex_helpers.sqrtComplex(@alignCast(discrimR), @alignCast(discrimI), @alignCast(s1r), @alignCast(s1i), realContext);
    math_subtraction_cells.subComplex(@alignCast(rr), @alignCast(ri), @alignCast(s1r), @alignCast(s1i), @alignCast(s2r), @alignCast(s2i), realContext);
    math_addition_cells.addComplex(@alignCast(rr), @alignCast(ri), @alignCast(s1r), @alignCast(s1i), @alignCast(s1r), @alignCast(s1i), realContext);
    math_transform_complex_helpers.curtComplex(@alignCast(s1r), @alignCast(s1i), @alignCast(s1r), @alignCast(s1i), realContext);
    math_transform_complex_helpers.curtComplex(@alignCast(s2r), @alignCast(s2i), @alignCast(s2r), @alignCast(s2i), realContext);

    // reusing q, r for (s1 ± s2)
    math_addition_cells.addComplex(@alignCast(s1r), @alignCast(s1i), @alignCast(s2r), @alignCast(s2i), @alignCast(qr), @alignCast(qi), realContext);
    math_subtraction_cells.subComplex(@alignCast(s1r), @alignCast(s1i), @alignCast(s2r), @alignCast(s2i), @alignCast(rr), @alignCast(ri), realContext);
    math_multiplication_cells.mulComplexComplex(@alignCast(rr), @alignCast(ri), const_0(), @alignCast(const159_root3on2), @alignCast(rr), @alignCast(ri), realContext);

    // roots
    math_division_cells.divComplexReal(@alignCast(c2Real), @alignCast(c2Imag), const_3(), @alignCast(x2Real), @alignCast(x2Imag), realContext); // x2 = c2/3
    realSubtract(qr, x2Real, x1Real, realContext);
    realSubtract(qi, x2Imag, x1Imag, realContext);
    math_multiplication_cells.mulComplexReal(@alignCast(qr), @alignCast(qi), const_1on2(), @alignCast(x3Real), @alignCast(x3Imag), realContext);
    realAdd(x3Real, x2Real, x3Real, realContext);
    realAdd(x3Imag, x2Imag, x3Imag, realContext);
    chsComplex(x3Real, x3Imag);
    realAdd(x3Real, rr, x2Real, realContext);
    realAdd(x3Imag, ri, x2Imag, realContext);
    realSubtract(x3Real, rr, x3Real, realContext);
    realSubtract(x3Imag, ri, x3Imag, realContext);

    // Force real outputs when the roots are known to be real
    if (realIn) {
        if (realIsZeroA(rReal) or realIsNegativeA(rImag)) {
            realSetZero(x1Imag);
            realSetZero(x2Imag);
            realSetZero(x3Imag);
        } else {
            if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x1Imag), @alignCast(x2Imag))) {
                if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x1Imag), @alignCast(x3Imag))) {
                    realSetZero(x1Imag);
                } else {
                    realSetZero(x3Imag);
                }
            } else {
                if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x2Imag), @alignCast(x3Imag))) {
                    realSetZero(x2Imag);
                } else {
                    realSetZero(x3Imag);
                }
            }
        }
    }

    // Zero tiny imaginary parts that are below precision threshold
    var eff_exp: i32 = undefined;
    eff_exp = realGetExponent(x1Imag);
    if (eff_exp < -realContext.digits) {
        realSetZero(x1Imag);
    }
    eff_exp = realGetExponent(x2Imag);
    if (eff_exp < -realContext.digits) {
        realSetZero(x2Imag);
    }
    eff_exp = realGetExponent(x3Imag);
    if (eff_exp < -realContext.digits) {
        realSetZero(x3Imag);
    }
}

comptime {
    _ = realIsZero;
}
