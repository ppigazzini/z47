// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const__4 = consts.const__4;
const const_1on2 = consts.const_1on2;
const const_2 = consts.const_2;
const const_4 = consts.const_4;
//
// Zig owner for src/c47/mathematics/slvq.c: solve quadratic (SLVQ). Exports
// slvq.h's fnSlvq, solveQuadraticEquation and solveQuadraticEquation159.
// Covered by slvq.txt (fnSlvq) plus eigen.txt (matrix.c calls the 159 solver
// when OPTION_EIGEN_159 is defined, which it is on every z47 build).
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). The root-selection
// branches (b==0 / c==0 / general; real vs complex discriminant; the
// sign(b)-stabilised formula and Vieta x2 = c/(a*x1)) are reproduced exactly.
// OPTION_SQUARE_159 is undef on every z47 build, so fnSlvq uses the standard
// (75-digit) solveQuadraticEquation; the 159-digit solveQuadraticEquation159 is
// still compiled (OPTION_EIGEN_159) and ported with 159-digit REAL_T_PTR
// scratch buffers. The dead SAVE_SPACE_DM42_12 guard and the #undef'd
// DISCRIMINANT blocks are omitted. EXTRA_INFO sprintf hints become fixed
// moreInfoOnError strings.

const runtime = @import("math_command_wrappers_runtime.zig");
const math_addition_cells = @import("math_addition_cells.zig"); // M-callconv: Zig-to-Zig
const math_division_cells = @import("math_division_cells.zig"); // M-callconv: Zig-to-Zig
const math_multiplication_cells = @import("math_multiplication_cells.zig"); // M-callconv: Zig-to-Zig
const math_subtraction_cells = @import("math_subtraction_cells.zig"); // M-callconv: Zig-to-Zig
const math_transform_complex_helpers = @import("math_transform_complex_helpers.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const amNone = runtime.amNone;
const TI_ROOTS2: u8 = 102;
const NOPARAM: u16 = 9876;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
extern fn fnDropZ(unused_but_mandatory_parameter: u16) void;
const realIsZero = runtime.realIsZero;

extern var temporaryInformation: u8;
extern fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, c: *real_t, cmplx: *bool) bool;

// real_t op helpers (operands *align(1) const so blob constants and 159-digit
// stack scratch both pass).
extern fn decNumberCopy(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberPlus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMinus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberAdd(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSubtract(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMultiply(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberDivide(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSquareRoot(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFMA(res: *align(1) real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn realSetNaN(value: *align(1) real_t) void;

inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn realMinus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
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
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
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
inline fn realIsZeroA(source: *align(1) const real_t) bool {
    return source.digits == 1 and source.lsu[0] == 0 and (source.bits & 0x70) == 0;
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

// Complex helpers (operands *align(1) const).

// Blob constants.

// REAL_T_PTR(name, 159): a 159-digit stack scratch real_t buffer.
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

// ===========================================================================
// fnSlvq
// ===========================================================================
pub export fn fnSlvq(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    var realRoots: bool = true;
    var complexCoefs: bool = false;
    var aReal: real_t = undefined;
    var bReal: real_t = undefined;
    var cReal: real_t = undefined;
    var rReal: real_t = undefined;
    var x1Real: real_t = undefined;
    var x2Real: real_t = undefined;
    var aImag: real_t = undefined;
    var bImag: real_t = undefined;
    var cImag: real_t = undefined;
    var rImag: real_t = undefined;
    var x1Imag: real_t = undefined;
    var x2Imag: real_t = undefined;

    if (!(getRegisterAsComplexOrReal(REGISTER_X, &cReal, &cImag, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Y, &bReal, &bImag, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Z, &aReal, &aImag, &complexCoefs)))
    {
        return;
    }
    const realCoefs = !complexCoefs;

    if (realIsZero(&aReal) and realIsZero(&aImag) and realIsZero(&bReal) and realIsZero(&bImag)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnSlvq:", "cannot use 0 for Y and Z as input of SLVQ", null, null);
        return;
    }

    if (!saveLastX()) {
        return;
    }

    if (realCoefs == false) {
        realRoots = false;
    }

    // OPTION_SQUARE_159 is undef on every z47 build -> standard 75-digit solver.
    solveQuadraticEquation(&aReal, &aImag, &bReal, &bImag, &cReal, &cImag, &rReal, &rImag, &x1Real, &x1Imag, &x2Real, &x2Imag, &runtime.ctxtReal75);

    realRoots = realRoots and realIsZero(&x1Imag) and realIsZero(&x2Imag);

    if (realRoots) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&x1Real, REGISTER_X);
        convertRealToReal34ResultRegister(&x2Real, REGISTER_Y);
    } else { // !realRoots
        if (realIsZero(&x1Imag)) { // x1 is real
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            convertRealToReal34ResultRegister(&x1Real, REGISTER_X);
        } else {
            reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
            convertComplexToResultRegister(&x1Real, &x1Imag, REGISTER_X);
        }

        if (realIsZero(&x2Imag)) { // x2 is real
            reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
            convertRealToReal34ResultRegister(&x2Real, REGISTER_Y);
        } else {
            reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone);
            convertComplexToResultRegister(&x2Real, &x2Imag, REGISTER_Y);
        }
    }

    temporaryInformation = TI_ROOTS2;
    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
    fnDropZ(0);
}

// ===========================================================================
// solveQuadraticEquation
// ===========================================================================
pub export fn solveQuadraticEquation(
    aReal: *align(1) const real_t,
    aImag: *align(1) const real_t,
    bReal: *align(1) const real_t,
    bImag: *align(1) const real_t,
    cReal: *align(1) const real_t,
    cImag: *align(1) const real_t,
    rReal: *align(1) real_t,
    rImag: *align(1) real_t,
    x1Real: *align(1) real_t,
    x1Imag: *align(1) real_t,
    x2Real: *align(1) real_t,
    x2Imag: *align(1) real_t,
    realContext: *realContext_t,
) linksection(runtime.code_section) callconv(.c) void {
    const realCoefs = realIsZeroA(aImag) and realIsZeroA(bImag) and realIsZeroA(cImag);

    if (realCoefs) {
        if (realIsZeroA(aReal)) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            realMultiply(bReal, bReal, rReal, realContext);
            realSetZero(rImag);
            // x1 = -c/b, x2 = NaN
            realDivide(cReal, bReal, x1Real, realContext);
            realChangeSign(x1Real);
            realSetNaN(x2Real);
            realSetZero(x1Imag);
            realSetZero(x2Imag);
        } else if (realIsZeroA(cReal)) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            realMultiply(bReal, bReal, rReal, realContext);
            realSetZero(rImag);
            // x1 = 0
            realSetZero(x1Real);
            // x2 = -b/a
            realDivide(bReal, aReal, x2Real, realContext);
            realChangeSign(x2Real);
            realSetZero(x1Imag);
            realSetZero(x2Imag);
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            // r = b² - 4ac
            realMultiply(const__4(), aReal, rReal, realContext);

            // Fix potential aliasing in realMultiply
            var temp_multiply: real_t = undefined;
            realMultiply(cReal, rReal, &temp_multiply, realContext);
            realCopy(&temp_multiply, rReal);

            // Fix potential aliasing in realFMA
            var temp_result: real_t = undefined;
            realFMA(bReal, bReal, rReal, &temp_result, realContext);
            realCopy(&temp_result, rReal);
            realSetZero(rImag);

            if (realIsPositiveA(rReal)) { // real roots
                // x1 = (-b - sign(b)*sqrt(r)) / 2a
                realSquareRoot(rReal, x1Real, realContext);
                if (realIsPositiveA(bReal)) {
                    realChangeSign(x1Real);
                }
                realSubtract(x1Real, bReal, x1Real, realContext);
                realMultiply(x1Real, const_1on2(), x1Real, realContext);
                realDivide(x1Real, aReal, x1Real, realContext);

                // x2 = c / ax1  (x1 connot be 0 here)
                realDivide(cReal, aReal, x2Real, realContext);
                realDivide(x2Real, x1Real, x2Real, realContext);

                realSetZero(x1Imag);
                realSetZero(x2Imag);
            } else { // complex roots
                // x1 = (-b - sign(b)*sqrt(r)) / 2a
                realMinus(rReal, x1Real, realContext);
                realSquareRoot(x1Real, x1Imag, realContext);
                realSetZero(x1Real);
                if (realIsPositiveA(bReal)) {
                    realChangeSign(x1Imag);
                }
                realSubtract(x1Real, bReal, x1Real, realContext);
                realSubtract(x1Imag, bImag, x1Imag, realContext);
                realMultiply(x1Real, const_1on2(), x1Real, realContext);
                realMultiply(x1Imag, const_1on2(), x1Imag, realContext);
                realDivide(x1Real, aReal, x1Real, realContext);
                realDivide(x1Imag, aReal, x1Imag, realContext);

                // x2 = conj(x1)
                realCopy(x1Real, x2Real);
                realCopy(x1Imag, x2Imag);
                realChangeSign(x2Imag);
            }
        }
    } else { // Complex coefficients
        if (realIsZeroA(aReal) and realIsZeroA(aImag)) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            math_multiplication_cells.mulComplexComplex(@alignCast(bReal), @alignCast(bImag), @alignCast(bReal), @alignCast(bImag), @alignCast(rReal), @alignCast(rImag), realContext);
            // x1 = -c/b, x2 = NaN
            math_division_cells.divComplexComplex(@alignCast(cReal), @alignCast(cImag), @alignCast(bReal), @alignCast(bImag), @alignCast(x1Real), @alignCast(x1Imag), realContext);
            realChangeSign(x1Real);
            realChangeSign(x1Imag);
            realSetNaN(x2Real);
            realSetNaN(x2Imag);
        } else if (realIsZeroA(cReal) and realIsZeroA(cImag)) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            math_multiplication_cells.mulComplexComplex(@alignCast(bReal), @alignCast(bImag), @alignCast(bReal), @alignCast(bImag), @alignCast(rReal), @alignCast(rImag), realContext);
            // x1 = 0
            realSetZero(x1Real);
            realSetZero(x1Imag);
            // x2 = -b/a
            math_division_cells.divComplexComplex(@alignCast(bReal), @alignCast(bImag), @alignCast(aReal), @alignCast(aImag), @alignCast(x2Real), @alignCast(x2Imag), realContext);
            realChangeSign(x2Real);
            realChangeSign(x2Imag);
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            // r = b² - 4ac
            realMultiply(const__4(), aReal, rReal, realContext);
            realMultiply(const__4(), aImag, rImag, realContext);
            math_multiplication_cells.mulComplexComplex(@alignCast(cReal), @alignCast(cImag), @alignCast(rReal), @alignCast(rImag), @alignCast(rReal), @alignCast(rImag), realContext);
            math_multiplication_cells.mulComplexComplex(@alignCast(bReal), @alignCast(bImag), @alignCast(bReal), @alignCast(bImag), @alignCast(x1Real), @alignCast(x1Imag), realContext);
            realAdd(x1Real, rReal, rReal, realContext);
            realAdd(x1Imag, rImag, rImag, realContext);

            // x1 = (-b + sqrt(r)) / 2a
            realCopy(rReal, x1Real);
            realCopy(rImag, x1Imag);
            math_transform_complex_helpers.realRectangularToPolar(@alignCast(x1Real), @alignCast(x1Imag), @alignCast(x1Real), @alignCast(x1Imag), realContext);
            realSquareRoot(x1Real, x1Real, realContext);
            realMultiply(x1Imag, const_1on2(), x1Imag, realContext);
            math_transform_complex_helpers.realPolarToRectangular(@alignCast(x1Real), @alignCast(x1Imag), @alignCast(x1Real), @alignCast(x1Imag), realContext);

            realSubtract(x1Real, bReal, x1Real, realContext);
            realSubtract(x1Imag, bImag, x1Imag, realContext);
            realMultiply(x1Real, const_1on2(), x1Real, realContext);
            realMultiply(x1Imag, const_1on2(), x1Imag, realContext);
            math_division_cells.divComplexComplex(@alignCast(x1Real), @alignCast(x1Imag), @alignCast(aReal), @alignCast(aImag), @alignCast(x1Real), @alignCast(x1Imag), realContext);

            // x2 = c / ax1  (x1 connot be 0 here)
            math_division_cells.divComplexComplex(@alignCast(cReal), @alignCast(cImag), @alignCast(aReal), @alignCast(aImag), @alignCast(x2Real), @alignCast(x2Imag), realContext);
            math_division_cells.divComplexComplex(@alignCast(x2Real), @alignCast(x2Imag), @alignCast(x1Real), @alignCast(x1Imag), @alignCast(x2Real), @alignCast(x2Imag), realContext);
        }
    }
}

// ===========================================================================
// solveQuadraticEquation159 (OPTION_EIGEN_159)
// ===========================================================================
pub export fn solveQuadraticEquation159(
    aReal: *align(1) const real_t,
    aImag: *align(1) const real_t,
    bReal: *align(1) const real_t,
    bImag: *align(1) const real_t,
    cReal: *align(1) const real_t,
    cImag: *align(1) const real_t,
    rReal: *align(1) real_t,
    rImag: *align(1) real_t,
    x1Real: *align(1) real_t,
    x1Imag: *align(1) real_t,
    x2Real: *align(1) real_t,
    x2Imag: *align(1) real_t,
    realContext: *realContext_t,
) linksection(runtime.code_section) callconv(.c) void {
    const realCoefs = realIsZeroA(aImag) and realIsZeroA(bImag) and realIsZeroA(cImag);

    if (realCoefs) {
        // All coefficients are real - use 159-digit precision
        var rR_b = BigReal(159){};
        var a_h_b = BigReal(159){};
        var b_h_b = BigReal(159){};
        var c_h_b = BigReal(159){};
        var temp_b = BigReal(159){};
        var sqrt_r_b = BigReal(159){};
        const rR = rR_b.ptr();
        const a_h = a_h_b.ptr();
        const b_h = b_h_b.ptr();
        const c_h = c_h_b.ptr();
        const temp = temp_b.ptr();
        const sqrt_r = sqrt_r_b.ptr();
        realSetZero(rR);
        realSetZero(a_h);
        realSetZero(b_h);
        realSetZero(c_h);
        realSetZero(temp);
        realSetZero(sqrt_r);

        realCopy(aReal, a_h);
        realCopy(bReal, b_h);
        realCopy(cReal, c_h);

        if (realIsZeroA(aReal)) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            realMultiply(b_h, b_h, rReal, realContext);
            realSetZero(rImag);
            // x1 = -c/b, x2 = NaN
            realDivide(c_h, b_h, x1Real, realContext);
            realChangeSign(x1Real);
            realSetNaN(x2Real);
            realSetZero(x1Imag);
            realSetZero(x2Imag);
        } else if (realIsZeroA(cReal)) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            realMultiply(b_h, b_h, rReal, realContext);
            realSetZero(rImag);
            // x1 = 0
            realSetZero(x1Real);
            // x2 = -b/a
            realDivide(b_h, a_h, x2Real, realContext);
            realChangeSign(x2Real);
            realSetZero(x1Imag);
            realSetZero(x2Imag);
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            // r = b² - 4ac (using FMA for better precision)
            realMultiply(const_4(), a_h, temp, realContext);
            realMultiply(c_h, temp, temp, realContext);
            realMinus(temp, temp, realContext);
            realFMA(b_h, b_h, temp, rR, realContext);

            realCopy(rR, rReal);
            realSetZero(rImag);

            if (!realIsNegativeA(rR)) {
                // Real roots (r ≥ 0, including double root when r = 0)
                realSquareRoot(rR, sqrt_r, realContext);

                // x1 = (-b - sign(b)*sqrt(r)) / 2a  (numerically stable)
                realCopy(sqrt_r, temp);
                if (!realIsNegativeA(b_h)) {
                    realChangeSign(temp);
                }

                var neg_b_b = BigReal(159){};
                const neg_b = neg_b_b.ptr();
                realMinus(b_h, neg_b, realContext);
                realAdd(neg_b, temp, temp, realContext);
                realMultiply(temp, const_1on2(), temp, realContext);
                realDivide(temp, a_h, x1Real, realContext);

                // x2 = c / (a*x1)  (Vieta's formula)
                realDivide(c_h, a_h, temp, realContext);
                realDivide(temp, x1Real, x2Real, realContext);

                realSetZero(x1Imag);
                realSetZero(x2Imag);
            } else {
                // Complex roots (r < 0)
                var x1R_h_b = BigReal(159){};
                var x1I_h_b = BigReal(159){};
                var temp_sqrt_b = BigReal(159){};
                var temp_calc_b = BigReal(159){};
                const x1R_h = x1R_h_b.ptr();
                const x1I_h = x1I_h_b.ptr();
                const temp_sqrt = temp_sqrt_b.ptr();
                const temp_calc = temp_calc_b.ptr();
                realSetZero(x1R_h);
                realSetZero(x1I_h);
                realSetZero(temp_sqrt);
                realSetZero(temp_calc);

                // Compute sqrt(|r|)
                realCopy(rR, temp_sqrt);
                realChangeSign(temp_sqrt); // temp_sqrt = -r = |r|
                realSquareRoot(temp_sqrt, sqrt_r, realContext);

                // Real part: x_real = -b / 2a
                realCopy(b_h, temp_calc);
                realChangeSign(temp_calc); // temp_calc = -b
                realMultiply(temp_calc, const_1on2(), temp_calc, realContext);
                realDivide(temp_calc, a_h, x1R_h, realContext);

                // Imaginary part: x_imag = ±sqrt(|r|) / 2a
                realCopy(sqrt_r, temp_calc);
                if (realIsPositiveA(b_h)) {
                    realChangeSign(temp_calc);
                }
                realMultiply(temp_calc, const_1on2(), temp_calc, realContext);
                realDivide(temp_calc, a_h, x1I_h, realContext);

                // Copy to output variables
                realCopy(x1R_h, x1Real);
                realCopy(x1I_h, x1Imag);

                // x2 = conj(x1)
                realCopy(x1Real, x2Real);
                realCopy(x1Imag, x2Imag);
                realChangeSign(x2Imag);
            }
        }
    } else {
        // Complex coefficients - use 159-digit precision
        var rR_b = BigReal(159){};
        var rI_b = BigReal(159){};
        var temp1R_b = BigReal(159){};
        var temp1I_b = BigReal(159){};
        var temp2R_b = BigReal(159){};
        var temp2I_b = BigReal(159){};
        var sqrtR_b = BigReal(159){};
        var sqrtI_b = BigReal(159){};
        const rR = rR_b.ptr();
        const rI = rI_b.ptr();
        const temp1R = temp1R_b.ptr();
        const temp1I = temp1I_b.ptr();
        const temp2R = temp2R_b.ptr();
        const temp2I = temp2I_b.ptr();
        const sqrtR = sqrtR_b.ptr();
        const sqrtI = sqrtI_b.ptr();
        realSetZero(rR);
        realSetZero(rI);
        realSetZero(temp1R);
        realSetZero(temp1I);
        realSetZero(temp2R);
        realSetZero(temp2I);
        realSetZero(sqrtR);
        realSetZero(sqrtI);

        var a_h_b = BigReal(159){};
        var b_h_b = BigReal(159){};
        var c_h_b = BigReal(159){};
        var aI_h_b = BigReal(159){};
        var bI_h_b = BigReal(159){};
        var cI_h_b = BigReal(159){};
        const a_h = a_h_b.ptr();
        const b_h = b_h_b.ptr();
        const c_h = c_h_b.ptr();
        const aI_h = aI_h_b.ptr();
        const bI_h = bI_h_b.ptr();
        const cI_h = cI_h_b.ptr();
        realCopy(aReal, a_h);
        realCopy(aImag, aI_h);
        realCopy(bReal, b_h);
        realCopy(bImag, bI_h);
        realCopy(cReal, c_h);
        realCopy(cImag, cI_h);

        if (realIsZeroA(aReal) and realIsZeroA(aImag)) {
            // bx + c = 0 => x = -c/b
            // r = b²
            math_multiplication_cells.mulComplexComplex(@alignCast(b_h), @alignCast(bI_h), @alignCast(b_h), @alignCast(bI_h), @alignCast(rReal), @alignCast(rImag), realContext);
            // x1 = -c/b, x2 = NaN
            math_division_cells.divComplexComplex(@alignCast(c_h), @alignCast(cI_h), @alignCast(b_h), @alignCast(bI_h), @alignCast(x1Real), @alignCast(x1Imag), realContext);
            realChangeSign(x1Real);
            realChangeSign(x1Imag);
            realSetNaN(x2Real);
            realSetNaN(x2Imag);
        } else {
            // Discriminant: r = b² - 4ac
            math_multiplication_cells.mulComplexComplex(@alignCast(b_h), @alignCast(bI_h), @alignCast(b_h), @alignCast(bI_h), @alignCast(rR), @alignCast(rI), realContext);
            math_multiplication_cells.mulComplexComplex(@alignCast(a_h), @alignCast(aI_h), @alignCast(c_h), @alignCast(cI_h), @alignCast(temp1R), @alignCast(temp1I), realContext);
            math_multiplication_cells.mulComplexReal(@alignCast(temp1R), @alignCast(temp1I), const_4(), @alignCast(temp1R), @alignCast(temp1I), realContext);
            realSubtract(rR, temp1R, rR, realContext);
            realSubtract(rI, temp1I, rI, realContext);

            realCopy(rR, rReal);
            realCopy(rI, rImag);

            // sqrt(r) using 159-digit precision
            math_transform_complex_helpers.sqrtComplex(@alignCast(rR), @alignCast(rI), @alignCast(sqrtR), @alignCast(sqrtI), realContext);

            // x1 = (-b + sqrt(r)) / (2a)
            realMinus(b_h, temp1R, realContext);
            realMinus(bI_h, temp1I, realContext);
            math_addition_cells.addComplex(@alignCast(temp1R), @alignCast(temp1I), @alignCast(sqrtR), @alignCast(sqrtI), @alignCast(temp1R), @alignCast(temp1I), realContext);
            math_multiplication_cells.mulComplexReal(@alignCast(a_h), @alignCast(aI_h), const_2(), @alignCast(temp2R), @alignCast(temp2I), realContext);
            math_division_cells.divComplexComplex(@alignCast(temp1R), @alignCast(temp1I), @alignCast(temp2R), @alignCast(temp2I), @alignCast(x1Real), @alignCast(x1Imag), realContext);

            // x2 = (-b - sqrt(r)) / (2a)
            realMinus(b_h, temp1R, realContext);
            realMinus(bI_h, temp1I, realContext);
            math_subtraction_cells.subComplex(@alignCast(temp1R), @alignCast(temp1I), @alignCast(sqrtR), @alignCast(sqrtI), @alignCast(temp1R), @alignCast(temp1I), realContext);
            math_division_cells.divComplexComplex(@alignCast(temp1R), @alignCast(temp1I), @alignCast(temp2R), @alignCast(temp2I), @alignCast(x2Real), @alignCast(x2Imag), realContext);
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
}

comptime {
    _ = const_0;
}
