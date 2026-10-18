// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1 = consts.const_1;
const const_1e_37 = consts.const_1e_37;
const const_1on2 = consts.const_1on2;
const const39_root3on2 = consts.const39_root3on2;
const const_2 = consts.const_2;
const const_3 = consts.const_3;
const const_4 = consts.const_4;
const const__4 = consts.const__4;
const const_9 = consts.const_9;
const const_54 = consts.const_54;
const const_2916 = consts.const_2916;
//
// Zig owner for src/c47/mathematics/slvc.c: solve cubic (SLVC). Exports
// slvc.h's fnSlvc, solveCubic, solveCoefficientVector, solveCubicEquation,
// solveCubicEquation159 and realCubicHasOnlyRealRoots. Covered by slvc.txt
// (fnSlvc) plus eigen.txt (matrix.c calls both cubic solvers) and slvp.txt
// (slvp.c calls realCubicHasOnlyRealRoots).
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). Complex values are
// cplx_t at 75 digits and cplx159_t on the 159-digit paths, each part viewed as
// a real_t. The Abramowitz & Stegun §3.8.2 scaling (-9q, 54r, the /2916
// discriminant), the s1 cube root with s2 = -q / s1, the
// _realCheckedAdd/_realCheckedSubtract condition-number cancellation guards, the
// deflation of the two remaining roots from the largest, the pair refinement
// from the exact discriminant and the realIn real-root forcing are reproduced
// exactly. OPTION_CUBIC_159 and OPTION_EIGEN_159 are defined on every z47
// build, so fnSlvc uses the 159-digit solveCubicEquation159; the standard
// 75-digit solveCubicEquation is still exported (matrix.c calls it). The qsort
// root ordering uses libc qsort with the exact cmplxSortCompare comparator. The
// OPTION_SLVQ_SLVC guard is live but defined for every target built here, so
// the body is unconditional; the #undef'd DISCRIMINANT blocks are omitted.

const runtime = @import("command_wrappers/runtime.zig");
const math_comparison_reals = @import("compare/comparison_reals.zig");
const math_slvq = @import("slvq.zig");
const real_t = runtime.real_t;
const Real159 = abi.Real159;
const cplx_t = runtime.cplx_t;
const cplx159_t = runtime.cplx159_t;
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

// Coefficient-vector surface (solveCoefficientVector): the matrix register plumbing
// and the two refusals it can raise.
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;
const getRegisterDataType = runtime.getRegisterDataType;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;
const linkToRealMatrixRegister = runtime.linkToRealMatrixRegister;
const linkToComplexMatrixRegister = runtime.linkToComplexMatrixRegister;
const realMatrixInit = runtime.realMatrixInit;
const complexMatrixInit = runtime.complexMatrixInit;
const realMatrixFree = runtime.realMatrixFree;
const complexMatrixFree = runtime.complexMatrixFree;
const convertReal34MatrixToReal34MatrixRegister = runtime.convertReal34MatrixToReal34MatrixRegister;
const convertComplex34MatrixToComplex34MatrixRegister = runtime.convertComplex34MatrixToComplex34MatrixRegister;
const ERROR_MATRIX_MISMATCH = runtime.ERROR_MATRIX_MISMATCH;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_MESSAGE_LENGTH = 512; // defines.h
extern var errorMessage: [*c]u8;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
const getRegisterAsComplexOrReal = runtime.getRegisterAsComplexOrReal;
extern fn fnDropT(unused_but_mandatory_parameter: u16) void;

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
const realSetPositiveSign = runtime.realSetPositiveSign;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsNegative = runtime.realIsNegative;
const realIsSpecial = runtime.realIsSpecial;
const realCompareLessThan = runtime.realCompareLessThan;
const realCompareLessEqual = runtime.realCompareLessEqual;
const realCompareGreaterThan = runtime.realCompareGreaterThan;
const realCompareGreaterEqual = runtime.realCompareGreaterEqual;
const realCompareAbsGreaterThan = runtime.realCompareAbsGreaterThan;
const realCompareAbsLessThan = math_comparison_reals.realCompareAbsLessThan;

// decNumberCopy moves the header plus only the units `digits` covers, so it is
// the one copy that is right for a 159-digit value; a struct assignment of a
// real_t would stop at the 75-digit tail.
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realPlus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = runtime.decNumberPlus(res, operand, ctxt);
}
inline fn realCompare(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = runtime.decNumberCompare(res, op1, op2, ctxt);
}
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}
inline fn realGetUnadjustedExponent(source: *const real_t) i32 {
    return source.exponent;
}

// decContext.h DEC_Inexact.
const DEC_Inexact: u32 = 0x00000020;

inline fn chsComplex(a: *cplx_t) void {
    realChangeSign(&a.Real);
    realChangeSign(&a.Imag);
}

// Complex helpers from the shared runtime, cplx_t and cplx159_t.
const complexMagnitude2 = runtime.complexMagnitude2;
const addComplex = runtime.addComplex;
const subComplex = runtime.subComplex;
const mulComplexComplex = runtime.mulComplexComplex;
const mulComplexReal = runtime.mulComplexReal;
const divComplexComplex = runtime.divComplexComplex;
const divComplexReal = runtime.divComplexReal;
const sqrtComplex = runtime.sqrtComplex;
const curtComplex = runtime.curtComplex;
const addComplex159 = runtime.addComplex159;
const subComplex159 = runtime.subComplex159;
const mulComplexComplex159 = runtime.mulComplexComplex159;
const mulComplexReal159 = runtime.mulComplexReal159;
const divComplexComplex159 = runtime.divComplexComplex159;
const divComplexReal159 = runtime.divComplexReal159;
const sqrtComplex159 = runtime.sqrtComplex159;
const curtComplex159 = runtime.curtComplex159;

extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;

// libc qsort for the exact (unstable) ordering of the 3 roots.
extern fn qsort(base: *anyopaque, nmemb: usize, size: usize, compar: *const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;

// ===========================================================================
// cmplxSortCompare
// ===========================================================================
fn cmplxSortCompare(v1: ?*const anyopaque, v2: ?*const anyopaque) linksection(runtime.code_section) callconv(.c) c_int {
    const p1: *const cplx_t = @ptrCast(@alignCast(v1.?));
    const p2: *const cplx_t = @ptrCast(@alignCast(v2.?));
    var v1a: real_t = undefined;
    var v2a: real_t = undefined;
    var c: real_t = undefined;

    complexMagnitude2(p1, &v1a, &ctxtReal39);
    complexMagnitude2(p2, &v2a, &ctxtReal39);

    // NaN's aren't interesting so sort largest
    if (realIsNaN(&v1a)) {
        return if (realIsNaN(&v2a)) 0 else 1;
    }
    if (realIsNaN(&v2a)) {
        return -1;
    }

    // Zeros are uninteresting so sort larger
    if (realIsZero(&v1a)) {
        return if (realIsZero(&v2a)) 0 else 1;
    }
    if (realIsZero(&v2a)) {
        return -1;
    }

    // Complex values are less interesting than real ones
    if (realIsZero(&p1.Imag)) {
        if (!realIsZero(&p2.Imag)) {
            return -1;
        }
    } else if (realIsZero(&p2.Imag)) {
        return 1;
    }

    // Sort on magnitude
    realCompare(&v1a, &v2a, &c, &ctxtReal75);
    if (!realIsZero(&c)) {
        return 1 - 2 * @as(c_int, @intFromBool(realIsNegative(&c)));
    }

    // Equal magnitude, favour positive roots over negative
    if (realIsNegative(&p1.Real) and !realIsNegative(&p2.Real)) {
        return 1;
    }
    if (!realIsNegative(&p1.Real) and realIsNegative(&p2.Real)) {
        return -1;
    }
    if (realIsNegative(&p1.Imag) and !realIsNegative(&p2.Imag)) {
        return 1;
    }
    if (!realIsNegative(&p1.Imag) and realIsNegative(&p2.Imag)) {
        return -1;
    }

    // Favour smaller real parts
    realCompare(&p1.Real, &p2.Real, &c, &ctxtReal75);
    if (!realIsZero(&c)) {
        if (realIsNegative(&p1.Real)) {
            return 1 - 2 * @as(c_int, @intFromBool(realIsPositive(&c)));
        }
        return 1 - 2 * @as(c_int, @intFromBool(realIsNegative(&c)));
    }

    // Favour smaller imaginary parts
    realCompare(&p1.Imag, &p2.Imag, &c, &ctxtReal75);
    if (!realIsZero(&c)) {
        if (realIsNegative(&p1.Imag)) {
            return 1 - 2 * @as(c_int, @intFromBool(realIsPositive(&c)));
        } else {
            return 1 - 2 * @as(c_int, @intFromBool(realIsNegative(&c)));
        }
    }
    return 0;
}

// ===========================================================================
// realCubicHasOnlyRealRoots
// ===========================================================================
// The number of coefficient digits of a finite value
fn _realDigits(x: *const real_t) linksection(runtime.code_section) i32 {
    return if (realIsZero(x)) 1 else realGetExponent(x) - realGetUnadjustedExponent(x) + 1;
}

// The homogeneous form avoids another normalisation. A sign obscured by p159 round-off gives roots indistinguishable at Real34.
// slvc.c compiles it with OPTION_CUBIC_159, OPTION_EIGEN_159 or OPTION_SLVP_POLY,
// the three paths that call it.
comptime {
    if (runtime.option_cubic_159 or runtime.option_eigen_159 or runtime.option_slvp_poly) {
        @export(&realCubicHasOnlyRealRoots, .{ .name = "realCubicHasOnlyRealRoots" });
    }
}

pub fn realCubicHasOnlyRealRoots(a: *const real_t, b: *const real_t, c: *const real_t, d: *const real_t, unresolvedDigits: i32, discriminantOut: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) bool {
    var t0: Real159 = undefined;
    var t1: Real159 = undefined;
    var t2: Real159 = undefined;
    var t3: Real159 = undefined;
    var t4: Real159 = undefined;
    var p159: Real159 = undefined;
    var q159: Real159 = undefined;
    const p = p159.ptr();
    const q = q159.ptr();
    var term: [5]*real_t = .{ t0.ptr(), t1.ptr(), t2.ptr(), t3.ptr(), t4.ptr() };
    var factorDigits: [5]i32 = undefined;
    var roundingExponent: i32 = @divTrunc(@as(i32, -2147483647 - 1), 2);
    var i: i32 = undefined;
    var j: i32 = undefined;

    if (realIsSpecial(a) or realIsSpecial(b) or realIsSpecial(c) or realIsSpecial(d)) {
        return false;
    }

    realMultiply(b, b, p, realContext); // b^2 c^2
    realMultiply(c, c, q, realContext);
    realMultiply(p, q, term[0], realContext);
    realMultiply(q, c, q, realContext); // -4 a c^3
    realMultiply(a, q, term[1], realContext);
    realMultiply(term[1], const__4(), term[1], realContext);
    realMultiply(p, b, p, realContext); // -4 b^3 d
    realMultiply(p, d, term[2], realContext);
    realMultiply(term[2], const__4(), term[2], realContext);
    realMultiply(a, d, p, realContext); // -27 a^2 d^2
    realMultiply(p, p, term[3], realContext);
    realMultiply(term[3], const_3(), term[3], realContext);
    realMultiply(term[3], const_9(), term[3], realContext);
    realChangeSign(term[3]);
    realMultiply(a, b, p, realContext); // +18 a b c d
    realMultiply(c, d, q, realContext);
    realMultiply(p, q, term[4], realContext);
    realMultiply(term[4], const_2(), term[4], realContext);
    realMultiply(term[4], const_9(), term[4], realContext);

    // A term whose factors have fewer digits than realContext together is exact and narrower than realContext; otherwise its roundings stay below
    // 10^(exponent - digits + 2). Summed from the largest term down, a sum of narrower terms rounds only where it is over ten times each term left, which then
    // cannot cancel it, so only the terms bound D.
    i = _realDigits(a);
    j = _realDigits(d);
    factorDigits[3] = 2 + 2 * i + 2 * j;
    factorDigits[1] = 1 + i + 3 * _realDigits(c);
    factorDigits[4] = 2 + i + j + _realDigits(b) + _realDigits(c);
    factorDigits[2] = 1 + 3 * _realDigits(b) + j;
    factorDigits[0] = 2 * _realDigits(b) + 2 * _realDigits(c);
    i = 0;
    while (i < 5) : (i += 1) {
        const k: usize = @intCast(i);
        if (factorDigits[k] >= realContext.digits and !realIsZero(term[k])) {
            roundingExponent = @max(roundingExponent, realGetExponent(term[k]) - realContext.digits + 2);
        }
    }

    i = 1;
    while (i < 5) : (i += 1) {
        j = i;
        while (j > 0 and realCompareAbsGreaterThan(term[@intCast(j)], term[@intCast(j - 1)])) : (j -= 1) {
            const swap = term[@intCast(j)];

            term[@intCast(j)] = term[@intCast(j - 1)];
            term[@intCast(j - 1)] = swap;
        }
    }
    realCopy(term[0], p);
    realCopyAbs(term[0], q);
    i = 1;
    while (i < 5) : (i += 1) {
        const k: usize = @intCast(i);
        realAdd(p, term[k], p, realContext);
        realSetPositiveSign(term[k]);
        realAdd(q, term[k], q, realContext);
    }

    if (discriminantOut) |out| {
        realCopy(p, out);
    }
    // Five terms, each rounded by less than 10^(roundingExponent + 1), leave D within 10^(roundingExponent + 2)
    return realCompareGreaterEqual(p, const_0()) or
        realGetExponent(p) <= roundingExponent + 1 or
        (unresolvedDigits > 0 and realGetExponent(p) <= realGetExponent(q) - unresolvedDigits);
}

// ===========================================================================
// solveGeneralCubic
//
// a x^3 + b x^2 + c x + d = 0: a leading zero degrades to the quadratic at 75
// digits with a NaN third root; b, c, d are consumed and the roots come back
// sorted.
// ===========================================================================
fn solveGeneralCubic(a: *const cplx_t, b: *cplx_t, c: *cplx_t, d: *cplx_t, r: *cplx_t, x: *[3]cplx_t) linksection(runtime.code_section) void {
    if (realIsZero(&a.Real) and realIsZero(&a.Imag)) {
        math_slvq.solveQuadraticEquation(b, c, d, r, &x[0], &x[1], &ctxtReal75);
        realSetNaN(&x[2].Real);
        realSetNaN(&x[2].Imag);
    } else if (realIsZero(&d.Real) and realIsZero(&d.Imag)) {
        math_slvq.solveQuadraticEquation(a, b, c, r, &x[0], &x[1], &ctxtReal75);
        realSetZero(&x[2].Real);
        realSetZero(&x[2].Imag);
    } else {
        solveCubic(a, b, c, d, r, &x[0], &x[1], &x[2]);
    }
    qsort(@ptrCast(x), 3, @sizeOf(cplx_t), &cmplxSortCompare);
}

// ===========================================================================
// fnSlvc
// ===========================================================================
// The core (fnSlvcCore) returns an error instead of calling
// displayCalcErrorMessage inline; the exported fnSlvc wrapper maps it to a calc
// error at the ABI edge.
const SlvcError = error{LeadingCoeffsAllZero};

fn reportSlvcError(e: SlvcError) void {
    switch (e) {
        error.LeadingCoeffsAllZero => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                moreInfoOnError("In function fnSlvc:", "cannot use 0 for Y, Z and T as input of SLVC", null, null);
            }
        },
    }
}

pub export fn fnSlvc(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    fnSlvcCore() catch |e| reportSlvcError(e);
}

fn fnSlvcCore() linksection(runtime.code_section) SlvcError!void {
    var complexCoefs: bool = false;
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var c: cplx_t = undefined;
    var d: cplx_t = undefined;
    var r: cplx_t = undefined;
    var x: [3]cplx_t = undefined;

    // A coefficient vector takes the matrix path: the element count picks the solver.
    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
        solveCoefficientVector();
        return;
    }

    if (!(getRegisterAsComplexOrReal(REGISTER_X, &d, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Y, &c, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_Z, &b, &complexCoefs) and
        getRegisterAsComplexOrReal(REGISTER_T, &a, &complexCoefs)))
    {
        return;
    }

    if (realIsZero(&a.Real) and realIsZero(&a.Imag) and
        realIsZero(&b.Real) and realIsZero(&b.Imag) and
        realIsZero(&c.Real) and realIsZero(&c.Imag))
    {
        return error.LeadingCoeffsAllZero;
    }

    if (!saveLastX()) {
        return;
    }

    solveGeneralCubic(&a, &b, &c, &d, &r, &x);

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        if (realIsZero(&x[i].Imag) or (realIsNaN(&x[i].Real) and realIsNaN(&x[i].Imag))) {
            convertRealToResultRegister(&x[i].Real, REGISTER_X + @as(calcRegister_t, @intCast(i)), amNone);
        } else {
            convertComplexToResultRegister(&x[i], REGISTER_X + @as(calcRegister_t, @intCast(i)));
        }
        adjustResult(REGISTER_X + @as(calcRegister_t, @intCast(i)), false, true, REGISTER_X + @as(calcRegister_t, @intCast(i)), -1, -1);
    }
    temporaryInformation = TI_ROOTS3;

    fnDropT(0);
}

// ===========================================================================
// solveCoefficientVector
//
// X = a 1 x m or m x 1 coefficient vector, highest degree first: the element
// count picks the solver, 2 the linear, 3 the quadratic and 4 the cubic, from
// either SLVQ or SLVC. All roots come back as a row vector replacing X, real
// when every root is real; the rest of the stack is not consumed.
// ===========================================================================
pub export fn solveCoefficientVector() linksection(runtime.code_section) callconv(.c) void {
    var xr: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var r: cplx_t = undefined;
    var x: [3]cplx_t = undefined;
    var co: [4]cplx_t = undefined; // co[0] the leading coefficient

    const complexInput = getRegisterDataType(REGISTER_X) == dtComplex34Matrix;
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    if (complexInput) {
        linkToComplexMatrixRegister(REGISTER_X, &xc);
        rows = xc.header.matrixRows;
        cols = xc.header.matrixColumns;
    } else {
        linkToRealMatrixRegister(REGISTER_X, &xr);
        rows = xr.header.matrixRows;
        cols = xr.header.matrixColumns;
    }

    const m: u32 = @as(u32, rows) * @as(u32, cols);
    if ((rows != 1 and cols != 1) or m < 2 or m > 4) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "a coefficient vector holds 2 to 4 elements, not ({d}\x80\xd7{d})", .{ rows, cols });
            moreInfoOnError("In function solveCoefficientVector:", @ptrCast(errorMessage), null, null);
        }
        return;
    }

    var j: u32 = 0;
    while (j < m) : (j += 1) {
        if (complexInput) {
            const el = &complexElems(&xc)[j];
            runtime.real34ToReal(&el.real, &co[j].Real);
            runtime.real34ToReal(&el.imag, &co[j].Imag);
        } else {
            runtime.real34ToReal(&realElems(&xr)[j], &co[j].Real);
            realSetZero(&co[j].Imag);
        }
    }

    // The stack forms' refusal: the constant term alone is no equation.
    var allZero = true;
    j = 0;
    while (j + 1 < m) : (j += 1) {
        allZero = allZero and realIsZero(&co[j].Real) and realIsZero(&co[j].Imag);
    }
    if (allZero) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function solveCoefficientVector:", "every coefficient above the constant term is 0", null, null);
        }
        return;
    }

    var nRoots: u16 = undefined;
    if (m == 2) {
        // The trivial linear case keeps the family symmetrical: the single root is -b/a, as SLVP delivers it.
        if (realIsZero(&co[0].Imag) and realIsZero(&co[1].Imag)) {
            realDivide(&co[1].Real, &co[0].Real, &x[0].Real, &ctxtReal39);
            realChangeSign(&x[0].Real);
            realSetZero(&x[0].Imag);
        } else {
            divComplexComplex(&co[1], &co[0], &x[0], &ctxtReal75);
            chsComplex(&x[0]);
        }
        nRoots = 1;
    } else if (m == 3) {
        math_slvq.solveQuadratic(&co[0], &co[1], &co[2], &r, &x[0], &x[1]);
        nRoots = 2;
    } else {
        solveGeneralCubic(&co[0], &co[1], &co[2], &co[3], &r, &x);
        nRoots = 3;
    }

    // A NaN pair is the stack forms' real NaN root, not a complex value.
    var resultIsComplex = false;
    j = 0;
    while (j < nRoots) : (j += 1) {
        if (!realIsZero(&x[j].Imag) and !(realIsNaN(&x[j].Real) and realIsNaN(&x[j].Imag))) {
            resultIsComplex = true;
            break;
        }
    }

    // The result matrix is allocated, then L, then X is overwritten: every
    // failure leaves X and L untouched.
    if (resultIsComplex) {
        var res: complex34Matrix_t = undefined;
        if (!complexMatrixInit(&res, 1, nRoots)) {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                moreInfoOnError("In function solveCoefficientVector:", "Ram full", null, null);
            }
            return;
        }
        if (!saveLastX()) {
            complexMatrixFree(&res);
            return;
        }
        j = 0;
        while (j < nRoots) : (j += 1) {
            const el = &complexElems(&res)[j];
            runtime.realToReal34(&x[j].Real, &el.real);
            runtime.realToReal34(&x[j].Imag, &el.imag);
        }
        convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
        complexMatrixFree(&res);
    } else {
        var res: real34Matrix_t = undefined;
        if (!realMatrixInit(&res, 1, nRoots)) {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                moreInfoOnError("In function solveCoefficientVector:", "Ram full", null, null);
            }
            return;
        }
        if (!saveLastX()) {
            realMatrixFree(&res);
            return;
        }
        j = 0;
        while (j < nRoots) : (j += 1) {
            runtime.realToReal34(&x[j].Real, &realElems(&res)[j]);
        }
        convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        realMatrixFree(&res);
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

// ===========================================================================
// _checkConditionNumberOfAddSub
// ===========================================================================
fn _checkConditionNumberOfAddSub(operand1: *const real_t, operand2: *const real_t, res: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var conditionNumber1: real_t = undefined;
    var conditionNumber2: real_t = undefined;
    var conditionNumber: *real_t = &conditionNumber1;

    if (realIsZero(res)) {
        return false;
    } else {
        realDivide(res, operand1, &conditionNumber1, realContext);
        realSetPositiveSign(&conditionNumber1);
        realDivide(res, operand2, &conditionNumber2, realContext);
        realSetPositiveSign(&conditionNumber2);
        if (realIsZero(operand1)) {
            conditionNumber = &conditionNumber2;
        } else if (realIsZero(operand2)) {
            conditionNumber = &conditionNumber1;
        } else if (realCompareGreaterThan(&conditionNumber1, &conditionNumber2)) {
            conditionNumber = &conditionNumber2;
        } else {
            conditionNumber = &conditionNumber1;
        }
        return realCompareLessThan(conditionNumber, const_1e_37());
    }
}

fn _realCheckedAdd(operand1: *const real_t, operand2: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var r: real_t = undefined;
    realAdd(operand1, operand2, &r, realContext);
    if (_checkConditionNumberOfAddSub(operand1, operand2, &r, realContext)) {
        realSetZero(res);
    } else {
        realCopy(&r, res);
    }
}

fn _realCheckedSubtract(operand1: *const real_t, operand2: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var minus: real_t = undefined;
    realCopy(operand2, &minus);
    realChangeSign(&minus);
    _realCheckedAdd(operand1, &minus, res, realContext);
}

// ===========================================================================
// _solveMonicQuadratic159 / _deflateCubic159 (OPTION_CUBIC_159 / OPTION_EIGEN_159)
// ===========================================================================
fn _solveMonicQuadratic159(b: *const cplx159_t, c: *const cplx159_t, x1: *cplx159_t, x2: *cplx159_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var discriminant: cplx159_t = undefined;
    var sqrtDiscriminant: cplx159_t = undefined;
    var plus: cplx159_t = undefined;
    var minus: cplx159_t = undefined;
    var plusMagnitude2_b: Real159 = undefined;
    var minusMagnitude2_b: Real159 = undefined;
    var magnitudeTerm_b: Real159 = undefined;
    const plusMagnitude2 = plusMagnitude2_b.ptr();
    const minusMagnitude2 = minusMagnitude2_b.ptr();
    const magnitudeTerm = magnitudeTerm_b.ptr();

    if (realIsZero(c.Real.constPtr()) and realIsZero(c.Imag.constPtr())) {
        realMinus(b.Real.constPtr(), x1.Real.ptr(), realContext);
        realMinus(b.Imag.constPtr(), x1.Imag.ptr(), realContext);
        realSetZero(x2.Real.ptr());
        realSetZero(x2.Imag.ptr());
        return;
    }

    mulComplexComplex159(b, b, &discriminant, realContext);
    mulComplexReal159(c, const_4(), &plus, realContext);
    subComplex159(&discriminant, &plus, &discriminant, realContext);
    sqrtComplex159(&discriminant, &sqrtDiscriminant, realContext);

    realMinus(b.Real.constPtr(), plus.Real.ptr(), realContext);
    realMinus(b.Imag.constPtr(), plus.Imag.ptr(), realContext);
    realCopy(plus.Real.ptr(), minus.Real.ptr());
    realCopy(plus.Imag.ptr(), minus.Imag.ptr());
    addComplex159(&plus, &sqrtDiscriminant, &plus, realContext);
    subComplex159(&minus, &sqrtDiscriminant, &minus, realContext);
    realMultiply(plus.Real.ptr(), plus.Real.ptr(), plusMagnitude2, realContext);
    realMultiply(plus.Imag.ptr(), plus.Imag.ptr(), magnitudeTerm, realContext);
    realAdd(plusMagnitude2, magnitudeTerm, plusMagnitude2, realContext);
    realMultiply(minus.Real.ptr(), minus.Real.ptr(), minusMagnitude2, realContext);
    realMultiply(minus.Imag.ptr(), minus.Imag.ptr(), magnitudeTerm, realContext);
    realAdd(minusMagnitude2, magnitudeTerm, minusMagnitude2, realContext);

    if (realCompareGreaterEqual(plusMagnitude2, minusMagnitude2)) {
        mulComplexReal159(&plus, const_1on2(), x1, realContext);
    } else {
        mulComplexReal159(&minus, const_1on2(), x1, realContext);
    }
    divComplexComplex159(c, x1, x2, realContext);
}

fn _deflateCubic159(c2: *const cplx159_t, c1: *const cplx159_t, c0: *const cplx159_t, x1: *cplx159_t, x2: *cplx159_t, x3: *cplx159_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var magnitude1_b: Real159 = undefined;
    var magnitude2_b: Real159 = undefined;
    var magnitude3_b: Real159 = undefined;
    var magnitudeTerm_b: Real159 = undefined;
    const magnitude1 = magnitude1_b.ptr();
    const magnitude2 = magnitude2_b.ptr();
    const magnitude3 = magnitude3_b.ptr();
    const magnitudeTerm = magnitudeTerm_b.ptr();
    var root: cplx159_t = undefined;
    var b: cplx159_t = undefined;
    var c: cplx159_t = undefined;

    realMultiply(x1.Real.ptr(), x1.Real.ptr(), magnitude1, realContext);
    realMultiply(x1.Imag.ptr(), x1.Imag.ptr(), magnitudeTerm, realContext);
    realAdd(magnitude1, magnitudeTerm, magnitude1, realContext);
    realMultiply(x2.Real.ptr(), x2.Real.ptr(), magnitude2, realContext);
    realMultiply(x2.Imag.ptr(), x2.Imag.ptr(), magnitudeTerm, realContext);
    realAdd(magnitude2, magnitudeTerm, magnitude2, realContext);
    realMultiply(x3.Real.ptr(), x3.Real.ptr(), magnitude3, realContext);
    realMultiply(x3.Imag.ptr(), x3.Imag.ptr(), magnitudeTerm, realContext);
    realAdd(magnitude3, magnitudeTerm, magnitude3, realContext);
    if (realCompareGreaterEqual(magnitude1, magnitude2) and realCompareGreaterEqual(magnitude1, magnitude3)) {
        realCopy(x1.Real.ptr(), root.Real.ptr());
        realCopy(x1.Imag.ptr(), root.Imag.ptr());
    } else if (realCompareGreaterEqual(magnitude2, magnitude3)) {
        realCopy(x2.Real.ptr(), root.Real.ptr());
        realCopy(x2.Imag.ptr(), root.Imag.ptr());
    } else {
        realCopy(x3.Real.ptr(), root.Real.ptr());
        realCopy(x3.Imag.ptr(), root.Imag.ptr());
    }

    if (realIsZero(root.Real.ptr()) and realIsZero(root.Imag.ptr())) {
        return;
    }

    divComplexComplex159(c0, &root, &c, realContext);
    realChangeSign(c.Real.ptr());
    realChangeSign(c.Imag.ptr());
    subComplex159(&c, c1, &b, realContext);
    divComplexComplex159(&b, &root, &b, realContext);
    realCopy(root.Real.ptr(), x1.Real.ptr());
    realCopy(root.Imag.ptr(), x1.Imag.ptr());
    _solveMonicQuadratic159(&b, &c, x2, x3, realContext);
    addComplex159(x2, x3, &root, realContext);
    addComplex159(c2, &root, x1, realContext);
    realChangeSign(x1.Real.ptr());
    realChangeSign(x1.Imag.ptr());
}

// ===========================================================================
// _cubicPairFromDiscriminant (OPTION_SLVQ_SLVC && OPTION_CUBIC_159)
// ===========================================================================
// Real coefficients with D < 0 give a real root x1 and a pair u +- iv with D = -4 v^2 a^4 ((x1 - u)^2 + v^2)^2. Next to a double root the deflated quadratic
// cancels v^2 against u^2 at p159, while D has exact terms: where v^2 is 40 orders or more below (x1 - u)^2, v = sqrt(-D) / (2 a^2 (x1 - u)^2) to that order.
// u = (ad - bc) / (2 (a^2 x1^2 + ac)) at any size, as d - bc = (x1 + x2)(x1 + x3)(x2 + x3) for a = 1: ad - bc is exact and 0 for a pair on the imaginary axis,
// and the denominator is 2 a^2 ((x1 + u)^2 + v^2), with no cancellation.
// The real root is the one whose imaginary part is the smallest, as the solver sets it. When the solver has taken all three as real, its own test of the
// discriminant being coarser, the pair is the two closest roots.
fn _cubicPairFromDiscriminant(a: *const real_t, b: *const real_t, c: *const real_t, d: *const real_t, discriminant: *const real_t, x: *[3]*cplx159_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var v_b: Real159 = undefined;
    var denominator_b: Real159 = undefined;
    const v = v_b.ptr();
    const denominator = denominator_b.ptr();
    var r: u32 = 0;
    const allReal = realIsZero(x[0].Imag.ptr()) and realIsZero(x[1].Imag.ptr()) and realIsZero(x[2].Imag.ptr());

    if (allReal) {
        realSubtract(x[0].Real.ptr(), x[1].Real.ptr(), v, realContext); // r is the root outside the closest pair
        realSetPositiveSign(v);
        realSubtract(x[1].Real.ptr(), x[2].Real.ptr(), denominator, realContext);
        realSetPositiveSign(denominator);
        r = 2;
        if (realCompareLessThan(denominator, v)) {
            realCopy(denominator, v);
            r = 0;
        }
        realSubtract(x[0].Real.ptr(), x[2].Real.ptr(), denominator, realContext);
        realSetPositiveSign(denominator);
        if (realCompareLessThan(denominator, v)) {
            r = 1;
        }
    } else {
        if (realCompareAbsLessThan(x[1].Imag.ptr(), x[r].Imag.ptr())) {
            r = 1;
        }
        if (realCompareAbsLessThan(x[2].Imag.ptr(), x[r].Imag.ptr())) {
            r = 2;
        }
    }
    const p: u32 = (r + 1) % 3;
    const q: u32 = (r + 2) % 3;

    realMultiply(a, x[r].Real.ptr(), v, realContext);
    realMultiply(v, v, v, realContext);
    realFMA(a, c, v, denominator, realContext);
    if (!realIsZero(denominator)) {
        realMultiply(b, c, v, realContext);
        realChangeSign(v);
        realFMA(a, d, v, v, realContext);
        realDivide(v, denominator, v, realContext);
        realMultiply(v, const_1on2(), x[p].Real.ptr(), realContext);
        realCopy(x[p].Real.ptr(), x[q].Real.ptr());
    }
    realSubtract(x[r].Real.ptr(), x[p].Real.ptr(), denominator, realContext);
    realMultiply(denominator, denominator, denominator, realContext);
    realMultiply(x[p].Imag.ptr(), x[p].Imag.ptr(), v, realContext); // v^2 from the solver
    if (realIsZero(denominator) or (!allReal and realGetExponent(v) > realGetExponent(denominator) - 40)) {
        return;
    }
    realMultiply(a, a, v, realContext);
    realMultiply(denominator, v, denominator, realContext);
    realMultiply(denominator, const_2(), denominator, realContext);
    realMinus(discriminant, v, realContext);
    realSquareRoot(v, v, realContext);
    realDivide(v, denominator, v, realContext);

    realCopy(v, x[p].Imag.ptr()); // the roots are sorted afterwards
    realMinus(v, x[q].Imag.ptr(), realContext);
}

// ===========================================================================
// solveCubic
//
// a x^3 + b x^2 + c x + d = 0 at the precision the build selects: 159 digits
// under OPTION_CUBIC_159, 75 otherwise, results rounded to 39. Upstream lifted
// this out of fnSlvc so solveCoefficientVector could reach the same solver.
// ===========================================================================
pub export fn solveCubic(a: *const cplx_t, b: *const cplx_t, c: *const cplx_t, d: *const cplx_t, r: *cplx_t, x1: *cplx_t, x2: *cplx_t, x3: *cplx_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_cubic_159) {
        // y = a x gives y^3 + b y^2 + a c y + a^2 d, whose coefficients stay exact where those of x^3 + b/a x^2 + c/a x + d/a are rounded
        var ac: cplx_t = undefined;
        var a2d: cplx_t = undefined;
        mulComplexComplex(c, a, &ac, &ctxtReal75);
        mulComplexComplex(d, a, &a2d, &ctxtReal75);
        mulComplexComplex(&a2d, a, &a2d, &ctxtReal75);
        solveCubicEquation(b, &ac, &a2d, r, x1, x2, x3, &ctxtReal75);
        divComplexComplex(x1, a, x1, &ctxtReal75);
        divComplexComplex(x2, a, x2, &ctxtReal75);
        divComplexComplex(x3, a, x3, &ctxtReal75);
        return;
    }

    var ctx159 = ctxtReal75;
    ctx159.digits = 159;
    const realCoefficients = realIsZero(&a.Imag) and realIsZero(&b.Imag) and realIsZero(&c.Imag) and realIsZero(&d.Imag);
    var discriminant_b: Real159 = undefined;
    const discriminant = discriminant_b.ptr();
    realSetZero(discriminant);
    const onlyRealRoots = realCoefficients and realCubicHasOnlyRealRoots(&a.Real, &b.Real, &c.Real, &d.Real, 0, discriminant, &ctx159);
    var x1H: cplx159_t = undefined;
    var x2H: cplx159_t = undefined;
    var x3H: cplx159_t = undefined;
    var r0: cplx159_t = undefined;
    var aH: cplx159_t = undefined;
    var bH: cplx159_t = undefined;
    var cH: cplx159_t = undefined;
    var dH: cplx159_t = undefined;
    var x: [3]*cplx159_t = .{ &x1H, &x2H, &x3H };
    const t: *cplx159_t = &bH; // free once the solver is done
    const p: *cplx159_t = &cH;

    realCopy(&a.Real, aH.Real.ptr());
    realCopy(&a.Imag, aH.Imag.ptr());
    realCopy(&b.Real, bH.Real.ptr());
    realCopy(&b.Imag, bH.Imag.ptr());
    realCopy(&c.Real, cH.Real.ptr());
    realCopy(&c.Imag, cH.Imag.ptr());
    realCopy(&d.Real, dH.Real.ptr());
    realCopy(&d.Imag, dH.Imag.ptr());
    divComplexComplex159(&bH, &aH, &bH, &ctx159);
    divComplexComplex159(&cH, &aH, &cH, &ctx159);
    divComplexComplex159(&dH, &aH, &dH, &ctx159);
    solveCubicEquation159(&bH, &cH, &dH, &r0, &x1H, &x2H, &x3H, &ctx159);
    if (onlyRealRoots) {
        realSetZero(x1H.Imag.ptr());
        realSetZero(x2H.Imag.ptr());
        realSetZero(x3H.Imag.ptr());
    } else if (realCoefficients and realIsNegative(discriminant)) {
        _cubicPairFromDiscriminant(&a.Real, &b.Real, &c.Real, &d.Real, discriminant, &x, &ctx159);
    }

    // A root rounded to 34 digits, with a part more than 34 digits below the other dropped, is exact where the cubic takes it to 0 with no rounding: with
    // 34-digit coefficients the Horner terms stay within 159 digits. A root on an axis then has an exact 0 in place of the noise of the solver.
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        ctx159.digits = 34;
        realPlus(x[i].Real.ptr(), t.Real.ptr(), &ctx159);
        realPlus(x[i].Imag.ptr(), t.Imag.ptr(), &ctx159);
        ctx159.digits = 159;
        if (realGetExponent(t.Imag.ptr()) < realGetExponent(t.Real.ptr()) - 34) {
            realSetZero(t.Imag.ptr());
        } else if (realGetExponent(t.Real.ptr()) < realGetExponent(t.Imag.ptr()) - 34) {
            realSetZero(t.Real.ptr());
        }
        ctx159.status = 0;
        mulComplexComplex159(&aH, t, p, &ctx159);
        realAdd(p.Real.ptr(), &b.Real, p.Real.ptr(), &ctx159);
        realAdd(p.Imag.ptr(), &b.Imag, p.Imag.ptr(), &ctx159);
        mulComplexComplex159(p, t, p, &ctx159);
        realAdd(p.Real.ptr(), &c.Real, p.Real.ptr(), &ctx159);
        realAdd(p.Imag.ptr(), &c.Imag, p.Imag.ptr(), &ctx159);
        mulComplexComplex159(p, t, p, &ctx159);
        realAdd(p.Real.ptr(), &d.Real, p.Real.ptr(), &ctx159);
        realAdd(p.Imag.ptr(), &d.Imag, p.Imag.ptr(), &ctx159);
        if (realIsZero(p.Real.ptr()) and realIsZero(p.Imag.ptr()) and (ctx159.status & DEC_Inexact) == 0) {
            realCopy(t.Real.ptr(), x[i].Real.ptr());
            realCopy(t.Imag.ptr(), x[i].Imag.ptr());
        }
    }
    realPlus(r0.Real.ptr(), &r.Real, &ctxtReal39);
    realPlus(r0.Imag.ptr(), &r.Imag, &ctxtReal39);
    realPlus(x1H.Real.ptr(), &x1.Real, &ctxtReal39);
    realPlus(x1H.Imag.ptr(), &x1.Imag, &ctxtReal39);
    realPlus(x2H.Real.ptr(), &x2.Real, &ctxtReal39);
    realPlus(x2H.Imag.ptr(), &x2.Imag, &ctxtReal39);
    realPlus(x3H.Real.ptr(), &x3.Real, &ctxtReal39);
    realPlus(x3H.Imag.ptr(), &x3.Imag, &ctxtReal39);
}

// ===========================================================================
// solveCubicEquation
// ===========================================================================
pub export fn solveCubicEquation(c2: *const cplx_t, c1: *const cplx_t, c0: *const cplx_t, r: *cplx_t, x1: *cplx_t, x2: *cplx_t, x3: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    // x^3 + b x^2 + c x + d = 0  (Abramowitz & Stegun §3.8.2)
    var q: cplx_t = undefined;
    var rr: cplx_t = undefined;
    var s1: cplx_t = undefined;
    var s2: cplx_t = undefined;
    var a: cplx_t = undefined;
    const realIn = realIsZero(&c2.Imag) and realIsZero(&c1.Imag) and realIsZero(&c0.Imag);

    // Compute q, r and the discriminant by scaling things up so that divisions
    // are avoided until the final step: q^3 carries a factor of 729 and r^2 of
    // 2916, and 729 times 4 is 2916, so everything is upscaled by 2916.

    // q = (c - b^2 / 3) / 3 ; -9q = b^2 - 3c
    mulComplexReal(c1, const_3(), &rr, realContext);
    mulComplexComplex(c2, c2, &a, realContext);
    subComplex(&a, &rr, &q, realContext);

    // r = (b c - 3 d) / 6 - b^3 / 27 ; 54r = 9(b c - 3 d) - 2 b^3
    mulComplexComplex(c2, c1, &rr, realContext);
    mulComplexReal(c0, const_3(), &s1, realContext);
    subComplex(&rr, &s1, &rr, realContext);
    mulComplexReal(&rr, const_9(), &rr, realContext);

    mulComplexComplex(&a, c2, &a, realContext);
    addComplex(&a, &a, &a, realContext);
    subComplex(&rr, &a, &rr, realContext);

    // q^3 + r^2 = (-4 (-9q)^3 + (54r)^2) / 2916
    mulComplexComplex(&q, &q, r, realContext);
    mulComplexComplex(r, &q, r, realContext);
    mulComplexReal(r, const__4(), r, realContext);
    mulComplexComplex(&rr, &rr, &a, realContext);
    addComplex(r, &a, r, realContext);
    divComplexReal(r, const_2916(), r, realContext);

    // Scale r back to its proper range, q isn't needed anymore so it's good.
    divComplexReal(&rr, const_54(), &rr, realContext);

    // s1 = cbrt(r + sqrt(q^3 + r^2)) and s2 = -q / s1, as two cube roots taken apart can differ by a cube root of unity. The square root takes the sign that
    // makes r + sqrt the larger sum, Re(r conj(sqrt)) >= 0; with the sign changed, s1 and s2 trade places, and s1 - s2 is negated to keep the order of the roots.
    sqrtComplex(r, &s2, realContext);
    realMultiply(&rr.Real, &s2.Real, &a.Real, realContext);
    realFMA(&rr.Imag, &s2.Imag, &a.Real, &a.Real, realContext);
    const swapped = realIsNegative(&a.Real);
    if (swapped) {
        chsComplex(&s2);
    }
    addComplex(&rr, &s2, &s1, realContext);
    curtComplex(&s1, &s1, realContext);
    if (!realIsZero(&s1.Real)) { // a cube root with no real part is 0, and then r, the square root and s2 are 0 too
        divComplexComplex(&q, &s1, &s2, realContext);
        divComplexReal(&s2, const_9(), &s2, realContext);
    }

    // reusing q, r for (s1 ± s2)
    addComplex(&s1, &s2, &q, realContext);
    subComplex(&s1, &s2, &rr, realContext);
    if (swapped) {
        chsComplex(&rr);
    }
    realSetZero(&a.Real);
    realCopy(const39_root3on2(), &a.Imag);
    mulComplexComplex(&rr, &a, &rr, realContext);

    // roots
    divComplexReal(c2, const_3(), x2, realContext);
    _realCheckedSubtract(&q.Real, &x2.Real, &x1.Real, realContext);
    _realCheckedSubtract(&q.Imag, &x2.Imag, &x1.Imag, realContext);
    mulComplexReal(&q, const_1on2(), x3, realContext);
    _realCheckedAdd(&x3.Real, &x2.Real, &x3.Real, realContext);
    _realCheckedAdd(&x3.Imag, &x2.Imag, &x3.Imag, realContext);
    chsComplex(x3);
    _realCheckedAdd(&x3.Real, &rr.Real, &x2.Real, realContext);
    _realCheckedAdd(&x3.Imag, &rr.Imag, &x2.Imag, realContext);
    _realCheckedSubtract(&x3.Real, &rr.Real, &x3.Real, realContext);
    _realCheckedSubtract(&x3.Imag, &rr.Imag, &x3.Imag, realContext);

    // Force real outputs when the roots are known to be real. With one real root and a pair, s1 and s2 are real and x1 is the real root already.
    if (realIn and realCompareLessEqual(&r.Real, const_0())) {
        realSetZero(&x1.Imag);
        realSetZero(&x2.Imag);
        realSetZero(&x3.Imag);
    }
}

// ===========================================================================
// solveCubicEquation159 (OPTION_CUBIC_159 / OPTION_EIGEN_159)
// ===========================================================================
// Compiled with OPTION_CUBIC_159 or OPTION_EIGEN_159, as slvc.c compiles it: the
// 159-digit complex helpers it calls exist only under those options.
comptime {
    if (runtime.option_cubic_159 or runtime.option_eigen_159) {
        @export(&solveCubicEquation159, .{ .name = "solveCubicEquation159" });
    }
}

pub fn solveCubicEquation159(c2: *const cplx159_t, c1: *const cplx159_t, c0: *const cplx159_t, r: *cplx159_t, x1: *cplx159_t, x2: *cplx159_t, x3: *cplx159_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const realIn = realIsZero(c2.Imag.constPtr()) and realIsZero(c1.Imag.constPtr()) and realIsZero(c0.Imag.constPtr());

    // high-precision constant sqrt(3)/2
    var const159_root3on2_b: Real159 = undefined;
    const const159_root3on2 = const159_root3on2_b.ptr();
    realSquareRoot(const_3(), const159_root3on2, realContext);
    realMultiply(const159_root3on2, const_1on2(), const159_root3on2, realContext);

    // Intermediate variables in 159-digit precision
    var q: cplx159_t = undefined;
    var rr: cplx159_t = undefined;
    var s1: cplx159_t = undefined;
    var s2: cplx159_t = undefined;
    var a: cplx159_t = undefined;

    realSetZero(q.Real.ptr());
    realSetZero(q.Imag.ptr());
    realSetZero(rr.Real.ptr());
    realSetZero(rr.Imag.ptr());
    realSetZero(s1.Real.ptr());
    realSetZero(s1.Imag.ptr());
    realSetZero(s2.Real.ptr());
    realSetZero(s2.Imag.ptr());
    realSetZero(a.Real.ptr());
    realSetZero(a.Imag.ptr());

    // q = (c - b^2 / 3) / 3 ; 9q = (3c - b^2)
    mulComplexReal159(c1, const_3(), &rr, realContext);
    mulComplexComplex159(c2, c2, &q, realContext);
    subComplex159(&rr, &q, &q, realContext);

    // r = (b c - 3 d) / 6 - b^3 / 27 ; 54r = 9(b c - 3 d) - 2 b^3
    mulComplexComplex159(c2, c1, &rr, realContext);
    mulComplexReal159(c0, const_3(), &a, realContext);
    subComplex159(&rr, &a, &rr, realContext);
    mulComplexReal159(&rr, const_9(), &rr, realContext);

    mulComplexComplex159(c2, c2, &a, realContext);
    mulComplexComplex159(&a, c2, &a, realContext);
    addComplex159(&a, &a, &a, realContext);
    subComplex159(&rr, &a, &rr, realContext);

    // discriminant using intermediate 159-digit variables
    var discrim: cplx159_t = undefined;
    realSetZero(discrim.Real.ptr());
    realSetZero(discrim.Imag.ptr());

    // q^3 + r^2 = (4 (9q)^3 + (54r)^2) / 2916
    mulComplexComplex159(&q, &q, &discrim, realContext);
    mulComplexComplex159(&discrim, &q, &discrim, realContext);
    mulComplexReal159(&discrim, const_4(), &discrim, realContext);
    mulComplexComplex159(&rr, &rr, &a, realContext);
    addComplex159(&discrim, &a, &discrim, realContext);
    divComplexReal159(&discrim, const_2916(), &discrim, realContext);
    // Copy discriminant to output
    realCopy(discrim.Real.ptr(), r.Real.ptr());
    realCopy(discrim.Imag.ptr(), r.Imag.ptr());

    // Scale r back to its proper range, q isn't needed anymore so it's good.
    divComplexReal159(&rr, const_54(), &rr, realContext);

    // s1, s2 = cbrt(r ± sqrt(q^3 + r^2))
    sqrtComplex159(&discrim, &s1, realContext);
    subComplex159(&rr, &s1, &s2, realContext);
    addComplex159(&rr, &s1, &s1, realContext);
    // Two cube roots taken apart can differ by a cube root of unity, which turns two of the roots by 120 degrees: the larger of r +- sqrt takes the cube root, and
    // the other is -q over it, as s1 s2 = -q.
    realMultiply(s1.Real.ptr(), s1.Real.ptr(), a.Real.ptr(), realContext);
    realFMA(s1.Imag.ptr(), s1.Imag.ptr(), a.Real.ptr(), a.Real.ptr(), realContext);
    realMultiply(s2.Real.ptr(), s2.Real.ptr(), a.Imag.ptr(), realContext);
    realFMA(s2.Imag.ptr(), s2.Imag.ptr(), a.Imag.ptr(), a.Imag.ptr(), realContext);
    {
        const s2Larger = realCompareLessThan(a.Real.ptr(), a.Imag.ptr());
        const root: *cplx159_t = if (s2Larger) &s2 else &s1;
        const other: *cplx159_t = if (s2Larger) &s1 else &s2;

        curtComplex159(root, root, realContext);
        if (realIsZero(root.Real.ptr()) and realIsZero(root.Imag.ptr())) {
            realSetZero(other.Real.ptr());
            realSetZero(other.Imag.ptr());
        } else {
            divComplexComplex159(&q, root, other, realContext);
            divComplexReal159(other, const_9(), other, realContext); // q holds 9q
            realChangeSign(other.Real.ptr());
            realChangeSign(other.Imag.ptr());
        }
    }

    // reusing q, r for (s1 ± s2)
    addComplex159(&s1, &s2, &q, realContext);
    subComplex159(&s1, &s2, &rr, realContext);
    realSetZero(a.Real.ptr());
    realCopy(const159_root3on2, a.Imag.ptr());
    mulComplexComplex159(&rr, &a, &rr, realContext);

    // roots
    // x2 = c2 / 3; x1 = x2 - (s1 + s2); x3 = x2 + (s1 - s2)/2 - (s1 + s2)/2
    divComplexReal159(c2, const_3(), x2, realContext); // x2 = c2/3
    realSubtract(q.Real.ptr(), x2.Real.ptr(), x1.Real.ptr(), realContext); // x1Real = qr - x2Real
    realSubtract(q.Imag.ptr(), x2.Imag.ptr(), x1.Imag.ptr(), realContext); // x1Imag = qi - x2Imag
    mulComplexReal159(&q, const_1on2(), x3, realContext); // x3 = (qr + i*qi)*1/2
    realAdd(x3.Real.ptr(), x2.Real.ptr(), x3.Real.ptr(), realContext); // x3Real += x2Real
    realAdd(x3.Imag.ptr(), x2.Imag.ptr(), x3.Imag.ptr(), realContext); // x3Imag += x2Imag
    realChangeSign(x3.Real.ptr()); // x3 = -x3 (flip sign)
    realChangeSign(x3.Imag.ptr());
    realAdd(x3.Real.ptr(), rr.Real.ptr(), x2.Real.ptr(), realContext); // x2Real = x3Real + rr
    realAdd(x3.Imag.ptr(), rr.Imag.ptr(), x2.Imag.ptr(), realContext); // x2Imag = x3Imag + ri
    realSubtract(x3.Real.ptr(), rr.Real.ptr(), x3.Real.ptr(), realContext); // x3Real -= rr
    realSubtract(x3.Imag.ptr(), rr.Imag.ptr(), x3.Imag.ptr(), realContext); // x3Imag -= ri

    // One Cardano root has no subtraction between unlike root scales. Deflation reconstructs the other two without that loss.
    _deflateCubic159(c2, c1, c0, x1, x2, x3, realContext);

    // Force real outputs when the roots are known to be real
    if (realIn) {
        if (realCubicHasOnlyRealRoots(const_1(), c2.Real.constPtr(), c1.Real.constPtr(), c0.Real.constPtr(), 156, null, realContext)) {
            // Three real roots
            realSetZero(x1.Imag.ptr());
            realSetZero(x2.Imag.ptr());
            realSetZero(x3.Imag.ptr());
        } else {
            // One real, two complex roots
            if (realCompareAbsLessThan(x1.Imag.ptr(), x2.Imag.ptr())) {
                if (realCompareAbsLessThan(x1.Imag.ptr(), x3.Imag.ptr())) {
                    realSetZero(x1.Imag.ptr());
                } else {
                    realSetZero(x3.Imag.ptr());
                }
            } else {
                if (realCompareAbsLessThan(x2.Imag.ptr(), x3.Imag.ptr())) {
                    realSetZero(x2.Imag.ptr());
                } else {
                    realSetZero(x3.Imag.ptr());
                }
            }
        }
    }
}
