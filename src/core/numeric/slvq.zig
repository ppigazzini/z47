// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const__4 = consts.const__4;
const const_1on2 = consts.const_1on2;
const const_2 = consts.const_2;
const const_4 = consts.const_4;
//
// Zig owner for src/c47/mathematics/slvq.c: solve quadratic (SLVQ). Exports
// slvq.h's fnSlvq, solveQuadratic, solveQuadraticEquation and
// solveQuadraticEquation159. Covered by slvq.txt (fnSlvq) plus eigen.txt
// (matrix.c calls the 159 solver when OPTION_EIGEN_159 is defined, which it is
// on every z47 build).
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). Complex values are
// cplx_t at 75 digits and cplx159_t on the 159-digit path. The root-selection
// branches (b==0 / c==0 / general; real vs complex discriminant; the
// sign(b)-stabilised formula and Vieta x2 = c/(a*x1); for complex coefficients
// the square root of the discriminant with the sign that makes the numerator q
// the larger, the other root c/q) are reproduced exactly. OPTION_SQUARE_159 is
// undef on every z47 build, so fnSlvq uses the standard (75-digit)
// solveQuadraticEquation; the 159-digit solveQuadraticEquation159 is still
// compiled (OPTION_EIGEN_159). OPTION_SLVQ_SLVC is defined for every target
// built here, so the body is unconditional; the #undef'd DISCRIMINANT blocks
// are omitted. EXTRA_INFO sprintf hints become fixed moreInfoOnError strings.

const runtime = @import("command_wrappers/runtime.zig");
// slvc owns solveCoefficientVector, which both SLVQ and SLVC dispatch to; slvc
// imports this file back for solveQuadraticEquation.
const math_slvc = @import("slvc.zig");
const real_t = runtime.real_t;
const Real159 = abi.Real159;
const cplx_t = runtime.cplx_t;
const cplx159_t = runtime.cplx159_t;
const realContext_t = runtime.realContext_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;
const getRegisterDataType = runtime.getRegisterDataType;
const amNone = runtime.amNone;
const TI_ROOTS2: u8 = 102;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
const getRegisterAsComplexOrReal = runtime.getRegisterAsComplexOrReal;
extern fn fnDropZ(unused_but_mandatory_parameter: u16) void;

extern var temporaryInformation: u8;

// Real helpers from the shared runtime; every operand is a naturally aligned
// real_t, the 159-digit parts included (Real159 shares the decNumber header).
const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realSquareRoot = runtime.realSquareRoot;
const realFMA = runtime.realFMA;
const realMinus = runtime.realMinus;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;
const realChangeSign = runtime.realChangeSign;
const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;

// decNumberCopy moves the header plus only the units `digits` covers, so it is
// the one copy that is right for a 159-digit value.
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realPlus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = runtime.decNumberPlus(res, operand, ctxt);
}
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}

// Complex helpers from the shared runtime, cplx_t and cplx159_t.
const mulComplexComplex = runtime.mulComplexComplex;
const mulComplexReal = runtime.mulComplexReal;
const divComplexComplex = runtime.divComplexComplex;
const sqrtComplex = runtime.sqrtComplex;
const addComplex159 = runtime.addComplex159;
const subComplex159 = runtime.subComplex159;
const mulComplexComplex159 = runtime.mulComplexComplex159;
const mulComplexReal159 = runtime.mulComplexReal159;
const divComplexComplex159 = runtime.divComplexComplex159;
const sqrtComplex159 = runtime.sqrtComplex159;

// OPTION_SQUARE_159 is undefined on every target: solveQuadratic takes the
// 75-digit path and never the 159-digit staging.
const option_square_159 = false;

// ===========================================================================
// fnSlvq
// ===========================================================================
pub export fn fnSlvq(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    var realRoots: bool = true;
    var complexCoefs: bool = false;
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var c: cplx_t = undefined;
    var r: cplx_t = undefined;
    var x1: cplx_t = undefined;
    var x2: cplx_t = undefined;

    // A coefficient vector takes the matrix path: the element count picks the solver.
    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
        math_slvc.solveCoefficientVector();
        return;
    }

    if (!(getRegisterAsComplexOrReal(REGISTER_X, &c, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Y, &b, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Z, &a, &complexCoefs)))
    {
        return;
    }
    const realCoefs = !complexCoefs;

    if (realIsZero(&a.Real) and realIsZero(&a.Imag) and realIsZero(&b.Real) and realIsZero(&b.Imag)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function fnSlvq:", "cannot use 0 for Y and Z as input of SLVQ", null, null);
        return;
    }

    if (!saveLastX()) {
        return;
    }

    if (realCoefs == false) {
        realRoots = false;
    }

    solveQuadratic(&a, &b, &c, &r, &x1, &x2);

    realRoots = realRoots and realIsZero(&x1.Imag) and realIsZero(&x2.Imag);

    if (realRoots) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&x1.Real, REGISTER_X);
        convertRealToReal34ResultRegister(&x2.Real, REGISTER_Y);
    } else { // !realRoots
        if (realIsZero(&x1.Imag)) { // x1 is real
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            convertRealToReal34ResultRegister(&x1.Real, REGISTER_X);
        } else {
            reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
            convertComplexToResultRegister(&x1, REGISTER_X);
        }

        if (realIsZero(&x2.Imag)) { // x2 is real
            reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
            convertRealToReal34ResultRegister(&x2.Real, REGISTER_Y);
        } else {
            reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone);
            convertComplexToResultRegister(&x2, REGISTER_Y);
        }
    }

    temporaryInformation = TI_ROOTS2;
    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
    fnDropZ(0);
}

// ===========================================================================
// solveQuadratic
//
// a x^2 + b x + c = 0 at the precision the build selects: 159 digits under
// OPTION_SQUARE_159, 75 otherwise, results rounded to 39. Upstream lifted this
// out of fnSlvq so solveCoefficientVector could reach the same solver.
// ===========================================================================
pub export fn solveQuadratic(a: *const cplx_t, b: *const cplx_t, c: *const cplx_t, r: *cplx_t, x1: *cplx_t, x2: *cplx_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !option_square_159) {
        solveQuadraticEquation(a, b, c, r, x1, x2, &runtime.ctxtReal75);
        return;
    }

    var ctx159 = runtime.ctxtReal75;
    ctx159.digits = 159;
    var x1H: cplx159_t = undefined;
    var x2H: cplx159_t = undefined;
    var r0: cplx159_t = undefined;
    var aH: cplx159_t = undefined;
    var bH: cplx159_t = undefined;
    var cH: cplx159_t = undefined;

    realCopy(&a.Real, aH.Real.ptr());
    realCopy(&a.Imag, aH.Imag.ptr());
    realCopy(&b.Real, bH.Real.ptr());
    realCopy(&b.Imag, bH.Imag.ptr());
    realCopy(&c.Real, cH.Real.ptr());
    realCopy(&c.Imag, cH.Imag.ptr());
    realSetZero(r0.Real.ptr());
    realSetZero(r0.Imag.ptr());
    realSetZero(x1H.Real.ptr());
    realSetZero(x1H.Imag.ptr());
    realSetZero(x2H.Real.ptr());
    realSetZero(x2H.Imag.ptr());
    solveQuadraticEquation159(&aH, &bH, &cH, &r0, &x1H, &x2H, &ctx159);
    realPlus(r0.Real.ptr(), &r.Real, &runtime.ctxtReal39);
    realPlus(r0.Imag.ptr(), &r.Imag, &runtime.ctxtReal39);
    realPlus(x1H.Real.ptr(), &x1.Real, &runtime.ctxtReal39);
    realPlus(x1H.Imag.ptr(), &x1.Imag, &runtime.ctxtReal39);
    realPlus(x2H.Real.ptr(), &x2.Real, &runtime.ctxtReal39);
    realPlus(x2H.Imag.ptr(), &x2.Imag, &runtime.ctxtReal39);
}

// ===========================================================================
// solveQuadraticEquation
// ===========================================================================
pub export fn solveQuadraticEquation(a: *const cplx_t, b: *const cplx_t, c: *const cplx_t, r: *cplx_t, x1: *cplx_t, x2: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const realCoefs = realIsZero(&a.Imag) and realIsZero(&b.Imag) and realIsZero(&c.Imag);

    if (realCoefs) {
        if (realIsZero(&a.Real)) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            realMultiply(&b.Real, &b.Real, &r.Real, realContext);
            realSetZero(&r.Imag);
            // x1 = -c/b, x2 = NaN
            realDivide(&c.Real, &b.Real, &x1.Real, realContext);
            realChangeSign(&x1.Real);
            realSetNaN(&x2.Real);
            realSetZero(&x1.Imag);
            realSetZero(&x2.Imag);
        } else if (realIsZero(&c.Real)) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            realMultiply(&b.Real, &b.Real, &r.Real, realContext);
            realSetZero(&r.Imag);
            // x1 = 0
            realSetZero(&x1.Real);
            // x2 = -b/a
            realDivide(&b.Real, &a.Real, &x2.Real, realContext);
            realChangeSign(&x2.Real);
            realSetZero(&x1.Imag);
            realSetZero(&x2.Imag);
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            // r = b² - 4ac
            realMultiply(const__4(), &a.Real, &r.Real, realContext);

            // Fix potential aliasing in realMultiply
            var temp_multiply: real_t = undefined;
            realMultiply(&c.Real, &r.Real, &temp_multiply, realContext);
            realCopy(&temp_multiply, &r.Real);

            // Fix potential aliasing in realFMA
            var temp_result: real_t = undefined;
            realFMA(&b.Real, &b.Real, &r.Real, &temp_result, realContext);
            realCopy(&temp_result, &r.Real);
            realSetZero(&r.Imag);

            if (realIsPositive(&r.Real)) { // real roots
                // x1 = (-b - sign(b)*sqrt(r)) / 2a
                realSquareRoot(&r.Real, &x1.Real, realContext);
                if (realIsPositive(&b.Real)) {
                    realChangeSign(&x1.Real);
                }
                realSubtract(&x1.Real, &b.Real, &x1.Real, realContext);
                realMultiply(&x1.Real, const_1on2(), &x1.Real, realContext);
                realDivide(&x1.Real, &a.Real, &x1.Real, realContext);

                // x2 = c / ax1  (x1 connot be 0 here)
                realDivide(&c.Real, &a.Real, &x2.Real, realContext);
                realDivide(&x2.Real, &x1.Real, &x2.Real, realContext);

                realSetZero(&x1.Imag);
                realSetZero(&x2.Imag);
            } else { // complex roots
                // x1 = (-b - sign(b)*sqrt(r)) / 2a
                realMinus(&r.Real, &x1.Real, realContext);
                realSquareRoot(&x1.Real, &x1.Imag, realContext);
                realSetZero(&x1.Real);
                if (realIsPositive(&b.Real)) {
                    realChangeSign(&x1.Imag);
                }
                realSubtract(&x1.Real, &b.Real, &x1.Real, realContext);
                realSubtract(&x1.Imag, &b.Imag, &x1.Imag, realContext);
                realMultiply(&x1.Real, const_1on2(), &x1.Real, realContext);
                realMultiply(&x1.Imag, const_1on2(), &x1.Imag, realContext);
                realDivide(&x1.Real, &a.Real, &x1.Real, realContext);
                realDivide(&x1.Imag, &a.Real, &x1.Imag, realContext);

                // x2 = conj(x1)
                realCopy(&x1.Real, &x2.Real);
                realCopy(&x1.Imag, &x2.Imag);
                realChangeSign(&x2.Imag);
            }
        }
    } else { // Complex coefficients
        if (realIsZero(&a.Real) and realIsZero(&a.Imag)) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            mulComplexComplex(b, b, r, realContext);
            // x1 = -c/b, x2 = NaN
            divComplexComplex(c, b, x1, realContext);
            realChangeSign(&x1.Real);
            realChangeSign(&x1.Imag);
            realSetNaN(&x2.Real);
            realSetNaN(&x2.Imag);
        } else if (realIsZero(&c.Real) and realIsZero(&c.Imag)) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            mulComplexComplex(b, b, r, realContext);
            // x1 = 0
            realSetZero(&x1.Real);
            realSetZero(&x1.Imag);
            // x2 = -b/a
            divComplexComplex(b, a, x2, realContext);
            realChangeSign(&x2.Real);
            realChangeSign(&x2.Imag);
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            var ac: cplx_t = undefined;
            var b2: cplx_t = undefined;
            var sqrtR: cplx_t = undefined;
            var q: cplx_t = undefined;
            var dot: real_t = undefined;
            var product: real_t = undefined;

            // r = b² - 4ac
            mulComplexComplex(a, c, &ac, realContext);
            mulComplexReal(&ac, const_4(), r, realContext);
            mulComplexComplex(b, b, &b2, realContext);
            realSubtract(&b2.Real, &r.Real, &r.Real, realContext);
            realSubtract(&b2.Imag, &r.Imag, &r.Imag, realContext);

            sqrtComplex(r, &sqrtR, realContext);

            // Choose the sign that makes q = -(b +/- sqrt(r))/2 the larger numerator.
            realMultiply(&b.Imag, &sqrtR.Imag, &product, realContext);
            realFMA(&b.Real, &sqrtR.Real, &product, &dot, realContext);
            const qUsesMinusRoot = realIsPositive(&dot) and !realIsZero(&dot);
            if (qUsesMinusRoot) {
                realAdd(&b.Real, &sqrtR.Real, &q.Real, realContext);
                realAdd(&b.Imag, &sqrtR.Imag, &q.Imag, realContext);
                realChangeSign(&q.Real);
                realChangeSign(&q.Imag);
            } else {
                realSubtract(&sqrtR.Real, &b.Real, &q.Real, realContext);
                realSubtract(&sqrtR.Imag, &b.Imag, &q.Imag, realContext);
            }
            realMultiply(&q.Real, const_1on2(), &q.Real, realContext);
            realMultiply(&q.Imag, const_1on2(), &q.Imag, realContext);

            // Preserve the principal-square-root ordering while using c/q for the smaller numerator.
            if (qUsesMinusRoot) {
                divComplexComplex(c, &q, x1, realContext);
                divComplexComplex(&q, a, x2, realContext);
            } else {
                divComplexComplex(&q, a, x1, realContext);
                divComplexComplex(c, &q, x2, realContext);
            }
        }
    }
}

// ===========================================================================
// solveQuadraticEquation159 (OPTION_SQUARE_159 / OPTION_EIGEN_159)
// ===========================================================================
pub export fn solveQuadraticEquation159(a: *const cplx159_t, b: *const cplx159_t, c: *const cplx159_t, r: *cplx159_t, x1: *cplx159_t, x2: *cplx159_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const realCoefs = realIsZero(a.Imag.constPtr()) and realIsZero(b.Imag.constPtr()) and realIsZero(c.Imag.constPtr());

    if (realCoefs) {
        // All coefficients are real - use 159-digit precision
        var rR_b: Real159 = undefined;
        var a_h_b: Real159 = undefined;
        var b_h_b: Real159 = undefined;
        var c_h_b: Real159 = undefined;
        var temp_b: Real159 = undefined;
        var sqrt_r_b: Real159 = undefined;
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

        realCopy(a.Real.constPtr(), a_h);
        realCopy(b.Real.constPtr(), b_h);
        realCopy(c.Real.constPtr(), c_h);

        if (realIsZero(a.Real.constPtr())) {
            // bx + c = 0   (b is not 0 here)
            // r = b²
            realMultiply(b_h, b_h, r.Real.ptr(), realContext);
            realSetZero(r.Imag.ptr());
            // x1 = -c/b, x2 = NaN
            realDivide(c_h, b_h, x1.Real.ptr(), realContext);
            realChangeSign(x1.Real.ptr());
            realSetNaN(x2.Real.ptr());
            realSetZero(x1.Imag.ptr());
            realSetZero(x2.Imag.ptr());
        } else if (realIsZero(c.Real.constPtr())) {
            // ax² + bx = x(ax + b) = 0   (a is not 0 here)
            // r = b²
            realMultiply(b_h, b_h, r.Real.ptr(), realContext);
            realSetZero(r.Imag.ptr());
            // x1 = 0
            realSetZero(x1.Real.ptr());
            // x2 = -b/a
            realDivide(b_h, a_h, x2.Real.ptr(), realContext);
            realChangeSign(x2.Real.ptr());
            realSetZero(x1.Imag.ptr());
            realSetZero(x2.Imag.ptr());
        } else {
            // ax² + bx + c = 0   (a and c are not 0 here)
            // r = b² - 4ac (using FMA for better precision)
            realMultiply(const_4(), a_h, temp, realContext);
            realMultiply(c_h, temp, temp, realContext);
            realMinus(temp, temp, realContext);
            realFMA(b_h, b_h, temp, rR, realContext);

            realCopy(rR, r.Real.ptr());
            realSetZero(r.Imag.ptr());

            if (!realIsNegative(rR)) {
                // Real roots (r ≥ 0, including double root when r = 0)
                realSquareRoot(rR, sqrt_r, realContext);

                // x1 = (-b - sign(b)*sqrt(r)) / 2a  (numerically stable)
                realCopy(sqrt_r, temp);
                if (!realIsNegative(b_h)) {
                    realChangeSign(temp);
                }

                var neg_b_b: Real159 = undefined;
                const neg_b = neg_b_b.ptr();
                realMinus(b_h, neg_b, realContext);
                realAdd(neg_b, temp, temp, realContext);
                realMultiply(temp, const_1on2(), temp, realContext);
                realDivide(temp, a_h, x1.Real.ptr(), realContext);

                // x2 = c / (a*x1)  (Vieta's formula)
                realDivide(c_h, a_h, temp, realContext);
                realDivide(temp, x1.Real.ptr(), x2.Real.ptr(), realContext);

                realSetZero(x1.Imag.ptr());
                realSetZero(x2.Imag.ptr());
            } else {
                // Complex roots (r < 0)
                var temp_sqrt_b: Real159 = undefined;
                var temp_calc_b: Real159 = undefined;
                const temp_sqrt = temp_sqrt_b.ptr();
                const temp_calc = temp_calc_b.ptr();
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
                realDivide(temp_calc, a_h, x1.Real.ptr(), realContext);

                // Imaginary part: x_imag = ±sqrt(|r|) / 2a
                realCopy(sqrt_r, temp_calc);
                if (realIsPositive(b_h)) {
                    realChangeSign(temp_calc);
                }
                realMultiply(temp_calc, const_1on2(), temp_calc, realContext);
                realDivide(temp_calc, a_h, x1.Imag.ptr(), realContext);

                // x2 = conj(x1)
                realCopy(x1.Real.ptr(), x2.Real.ptr());
                realCopy(x1.Imag.ptr(), x2.Imag.ptr());
                realChangeSign(x2.Imag.ptr());
            }
        }
    } else {
        // Complex coefficients - use 159-digit precision
        var rC: cplx159_t = undefined;
        var temp1: cplx159_t = undefined;
        var temp2: cplx159_t = undefined;
        var sqrtZ: cplx159_t = undefined;
        realSetZero(rC.Real.ptr());
        realSetZero(rC.Imag.ptr());
        realSetZero(temp1.Real.ptr());
        realSetZero(temp1.Imag.ptr());
        realSetZero(temp2.Real.ptr());
        realSetZero(temp2.Imag.ptr());
        realSetZero(sqrtZ.Real.ptr());
        realSetZero(sqrtZ.Imag.ptr());

        var aH: cplx159_t = undefined;
        var bH: cplx159_t = undefined;
        var cH: cplx159_t = undefined;
        realCopy(a.Real.constPtr(), aH.Real.ptr());
        realCopy(a.Imag.constPtr(), aH.Imag.ptr());
        realCopy(b.Real.constPtr(), bH.Real.ptr());
        realCopy(b.Imag.constPtr(), bH.Imag.ptr());
        realCopy(c.Real.constPtr(), cH.Real.ptr());
        realCopy(c.Imag.constPtr(), cH.Imag.ptr());

        if (realIsZero(a.Real.constPtr()) and realIsZero(a.Imag.constPtr())) {
            // bx + c = 0 => x = -c/b
            // r = b²
            mulComplexComplex159(&bH, &bH, r, realContext);
            // x1 = -c/b, x2 = NaN
            divComplexComplex159(&cH, &bH, x1, realContext);
            realChangeSign(x1.Real.ptr());
            realChangeSign(x1.Imag.ptr());
            realSetNaN(x2.Real.ptr());
            realSetNaN(x2.Imag.ptr());
        } else {
            // Discriminant: r = b² - 4ac
            mulComplexComplex159(&bH, &bH, &rC, realContext);
            mulComplexComplex159(&aH, &cH, &temp1, realContext);
            mulComplexReal159(&temp1, const_4(), &temp1, realContext);
            realSubtract(rC.Real.ptr(), temp1.Real.ptr(), rC.Real.ptr(), realContext);
            realSubtract(rC.Imag.ptr(), temp1.Imag.ptr(), rC.Imag.ptr(), realContext);

            realCopy(rC.Real.ptr(), r.Real.ptr());
            realCopy(rC.Imag.ptr(), r.Imag.ptr());

            // sqrt(r) using 159-digit precision
            sqrtComplex159(&rC, &sqrtZ, realContext);

            // x1 = (-b + sqrt(r)) / (2a)
            realMinus(bH.Real.ptr(), temp1.Real.ptr(), realContext);
            realMinus(bH.Imag.ptr(), temp1.Imag.ptr(), realContext);
            addComplex159(&temp1, &sqrtZ, &temp1, realContext);
            mulComplexReal159(&aH, const_2(), &temp2, realContext);
            divComplexComplex159(&temp1, &temp2, x1, realContext);

            // x2 = (-b - sqrt(r)) / (2a)
            realMinus(bH.Real.ptr(), temp1.Real.ptr(), realContext);
            realMinus(bH.Imag.ptr(), temp1.Imag.ptr(), realContext);
            subComplex159(&temp1, &sqrtZ, &temp1, realContext);
            divComplexComplex159(&temp1, &temp2, x2, realContext);
        }
    }

    // Zero tiny imaginary parts that are below precision threshold
    var eff_exp: i32 = undefined;
    eff_exp = realGetExponent(x1.Imag.ptr());
    if (eff_exp < -realContext.digits) {
        realSetZero(x1.Imag.ptr());
    }
    eff_exp = realGetExponent(x2.Imag.ptr());
    if (eff_exp < -realContext.digits) {
        realSetZero(x2.Imag.ptr());
    }
}
