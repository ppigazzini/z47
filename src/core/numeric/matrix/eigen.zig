// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
const const_1on2 = consts.const_1on2;
const const_1on4 = consts.const_1on4;
const const_4 = consts.const_4;
const const_7 = consts.const_7;
const const_1e_30 = consts.const_1e_30;
const const_1e_34 = consts.const_1e_34;
// Zig port of the eigenvalue/eigenvector engine of src/c47/mathematics/matrix.c
// (the static numeric workers behind fnEigenvalues/fnEigenvectors/
// fnMatrixSquareRoot). BigReal(n) is the Zig equivalent of upstream's
// REAL_T_PTR(name, n) stack buffer; the 2x2/3x3 block solvers pick their
// internal digit count from OPTION_EIGEN_159 (see eigen_block_digits).
//
// The whole engine, and the four commands it serves, sit inside matrix.c's
// `#if defined(OPTION_EIGEN)`; the commands get empty bodies from the
// `#if !defined(OPTION_EIGEN)` stub block above it. defines.h #undef's
// OPTION_EIGEN for some DM42 packages (build/firmware.zig's dm42Package table).
//
// The workers are pub-exported so the file is fully analysed before the public
// commands are wired (the upstream copies are file-static, so the global Zig
// symbols never clash). The arithmetic is translated 1:1 against the decNumber
// primitives and the already-Zig-owned solveQuadraticEquation159 (math_slvq);
// the whole chain is verified by the Wolfram-referenced eigenvalue cases in the
// testSuite's matrix.txt once fnEigenvalues lands.
//
// This owner mirrors the real-op + BigReal scaffolding of math_slvq.zig.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_division_cells = @import("../arithmetic/division_cells.zig");
const math_matrix_complex_core = @import("complex_core.zig");
const math_matrix_product = @import("product.zig");
const math_multiplication_cells = @import("../arithmetic/multiplication_cells.zig");
const math_runtime_helpers = @import("../command_wrappers/helpers.zig");
const math_slvc = @import("../slvc.zig");
const math_slvq = @import("../slvq.zig");
const math_transform_complex_helpers = @import("../transform/transform_complex_helpers.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const math_addition_cells = @import("../arithmetic/addition_cells.zig");
const math_subtraction_cells = @import("../arithmetic/subtraction_cells.zig");
const math_vector_dot_scalar = @import("vector_dot_scalar.zig");
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

// The engine works on cplx_t arrays carved out of pool blocks sized in real_t,
// so a cplx_t has to be exactly two real_t with nothing between or after them.
const cplx_t = abi.Complex;
const cplx159_t = runtime.cplx159_t;
comptime {
    std.debug.assert(@sizeOf(cplx_t) == 2 * @sizeOf(real_t));
    std.debug.assert(@offsetOf(cplx_t, "Imag") == @sizeOf(real_t));
}

// The cplx_t arithmetic the engine calls, by the names matrix.c calls it.
const addComplex = math_addition_cells.addComplex;
const subComplex = math_subtraction_cells.subComplex;
const mulComplexComplex = math_multiplication_cells.mulComplexComplex;
const mulComplexReal = math_multiplication_cells.mulComplexReal;
const divComplexComplex = math_division_cells.divComplexComplex;
const divComplexReal = math_division_cells.divComplexReal;
const complexMagnitude = math_runtime_helpers.complexMagnitude;
const realCompareLessThan = math_comparison_reals.realCompareLessThan;
const realCompareGreaterThan = math_comparison_reals.realCompareGreaterThan;
const realCompareEqual = math_comparison_reals.realCompareEqual;

// fnEigenvalues command-handler dependencies (matrix.c).
extern fn fnRecallVElement(n: u16) void;
extern fn decQuadPlus(res: *align(1) real34_t, operand: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
inline fn real34Plus(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadPlus(res, operand, &runtime.ctxtReal34);
}
const FLAG_ASLIFT: i32 = 0xc023;
const ERROR_MATRIX_MISMATCH: u8 = 21;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    return std.mem.printSentinel(buffer, format, args, 0);
}

// --- decNumber primitives (operands *align(1) so blob constants + 159-digit
// stack scratch both pass) ------------------------------------------------
extern fn decNumberCopy(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberPlus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberAdd(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSubtract(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMultiply(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberDivide(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSquareRoot(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFMA(res: *align(1) real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn realSetOne(r: *align(1) real_t) void;
const allocC47Blocks = runtime.allocC47Blocks;
const freeC47Blocks = runtime.freeC47Blocks;

// A pool block of cplx_t; the pool hands out 4-aligned blocks, which cplx_t needs.
inline fn allocCplx(size_in_blocks: usize) ?[*]cplx_t {
    return @ptrCast(@alignCast(allocC47Blocks(size_in_blocks) orelse return null));
}
extern fn decNumberCopyAbs(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern var currentKeyCode: u8;
extern var currentSolverNestingDepth: u16;
extern var significantDigits: u8;

inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}

// Eigenvalue setup (matrix.c). toleranceDigits and eigenTolerance read
// significantDigits, so they are evaluated per call as the C macros are.
const extraDigits: i32 = 3;
const FLAG_SOLVING: i32 = 0xc026;

fn toleranceDigits() i32 {
    if (runtime.is_testsuite_build) {
        return 34 + extraDigits;
    }
    const significant_digits: i32 = significantDigits;
    return (if (significant_digits == 0) 34 else significant_digits) + extraDigits;
}

fn eigenTolerance() i32 {
    return @min(70, toleranceDigits() * 2);
}

const ERROR_SOLVER_ABORT: u8 = 60;

inline fn realCopyAbs(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
const realIsSpecial = math_real_predicates.realIsSpecial;

inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
inline fn realIsNegativeA(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}
inline fn realSetPositiveSign(operand: *align(1) real_t) void {
    operand.bits &= 0x7f;
}

// diagMode_t (matrix.c) selects which elements sumOfSubSupDiagonalAll sums.
const DIAG: c_int = 0;
const SUPSUBDIAG: c_int = 1;
const NONDIAG: c_int = 2;
const CHDIAG: c_int = 3;
// defines.h: symmetric/tridiagonal detection tolerance exponent.
const symmetricTolerance: i32 = 30;
// Clamp a rotation residue smaller than 10^-eigenNoiseThreshold of the smallest
// input element to zero.
const eigenNoiseThreshold: i32 = 70;
// The post-QR block threshold, relative to the average diagonal magnitude.
const finalBlockTolerance: i32 = 30;

inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
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
inline fn realIsZeroA(source: *align(1) const real_t) bool {
    return source.digits == 1 and source.lsu[0] == 0 and (source.bits & 0x70) == 0;
}

// Complex helper used by the 2x2/3x3 closed-form solvers.

// math_slvq-owned quadratic solvers (Zig exports).

// Eigen iteration monitoring flag (matrix.c suppresses the keyboard monitor).
extern var blockMonitoring: bool;

// --- blob constants -------------------------------------------------------

const ERROR_NO_ROOT_FOUND: u8 = 20;

// The NaN setter, taken at align(1) like the decNumber primitives above.
extern fn realSetNaN(value: *align(1) real_t) void;
extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// --- BigReal(159): REAL_T_PTR(name, 159) stack scratch -------------------
inline fn realMaxDigits(comptime digits: u32) u32 {
    return ((digits + 2) / 6) * 6 + 3;
}
inline fn realSizeInBytes(comptime digits: u32) u32 {
    return 10 + 2 * (realMaxDigits(digits) / 3);
}
fn BigReal(comptime digits: u32) linksection(runtime.code_section) type {
    return struct {
        buf: [realSizeInBytes(digits)]u8 align(4) = undefined,
        inline fn ptr(self: *@This()) *align(1) real_t {
            return @ptrCast(&self.buf);
        }
    };
}

// Internal working precision of the 2x2 and 3x3 block solvers. matrix.c gives
// each of them an `#if defined(OPTION_EIGEN_159)` / `#else` pair: cplx159_t
// intermediates plus a realPlus round-back through the caller's context with the
// option, cplx_t written straight into the caller's outputs without it.
// defines.h #undef's OPTION_EIGEN_159 in the block common to packages 1-4, so
// every DM42 package that keeps OPTION_EIGEN runs at 75.
const eigen_block_digits: u32 = if (runtime.option_eigen_159) 159 else 75;
const BlockCplx = if (runtime.option_eigen_159) cplx159_t else cplx_t;

// A part of a BlockCplx, as the real_t the decNumber primitives take.
inline fn blockRe(z: *BlockCplx) *real_t {
    return if (comptime runtime.option_eigen_159) z.Real.ptr() else &z.Real;
}
inline fn blockIm(z: *BlockCplx) *real_t {
    return if (comptime runtime.option_eigen_159) z.Imag.ptr() else &z.Imag;
}

// EIGEN_MUL: the 2x2 and 3x3 helpers mix 75 digit matrix elements with 159
// digit intermediates when OPTION_EIGEN_159 is set, so a factor given by its
// parts is copied into a cplx159_t first; without it the factors are cplx_t.
fn eigenMul(f1r: *const real_t, f1i: *const real_t, f2r: *const real_t, f2i: *const real_t, product: *BlockCplx, ctx159: *realContext_t) linksection(runtime.code_section) void {
    if (comptime runtime.option_eigen_159) {
        var f1: cplx159_t = undefined;
        var f2: cplx159_t = undefined;
        realCopy(f1r, f1.Real.ptr());
        realCopy(f1i, f1.Imag.ptr());
        realCopy(f2r, f2.Real.ptr());
        realCopy(f2i, f2.Imag.ptr());
        runtime.mulComplexComplex159(&f1, &f2, product, ctx159);
    } else {
        var f1: cplx_t = undefined;
        var f2: cplx_t = undefined;
        realCopy(f1r, &f1.Real);
        realCopy(f1i, &f1.Imag);
        realCopy(f2r, &f2.Real);
        realCopy(f2i, &f2.Imag);
        mulComplexComplex(&f1, &f2, product, ctx159);
    }
}
inline fn eigenMulElem(f1: *const cplx_t, f2: *const cplx_t, product: *BlockCplx, ctx159: *realContext_t) void {
    eigenMul(&f1.Real, &f1.Imag, &f2.Real, &f2.Imag, product, ctx159);
}

// ===========================================================================
// calculateEigenvalues22 -- eigenvalues of the bottom-right 2x2 sub-matrix of
// the size x size cplx_t array `mat`.
// ===========================================================================
pub export fn calculateEigenvalues22(mat: [*]const cplx_t, size: u16, t1: *cplx_t, t2: *cplx_t, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
    var ctx159: realContext_t = runtime.ctxtReal75;
    ctx159.digits = eigen_block_digits;

    var tr: BlockCplx = undefined;
    var det: BlockCplx = undefined;
    var discr: BlockCplx = undefined;
    var one: BlockCplx = undefined;
    const trR = blockRe(&tr);
    const trI = blockIm(&tr);
    const detR = blockRe(&det);
    const detI = blockIm(&det);
    const discrR = blockRe(&discr);
    const discrI = blockIm(&discr);

    realSetZero(trR);
    realSetZero(trI);
    realSetZero(detR);
    realSetZero(detI);
    realSetZero(discrR);
    realSetZero(discrI);

    const sz: usize = size;
    const a = &mat[(sz - 2) * sz + (sz - 2)];
    const b = &mat[(sz - 2) * sz + (sz - 1)];
    const c = &mat[(sz - 1) * sz + (sz - 2)];
    const d = &mat[(sz - 1) * sz + (sz - 1)];

    // determinant ad - bc
    if (realIsZeroA(&a.Imag) and realIsZeroA(&b.Imag) and realIsZeroA(&c.Imag) and realIsZeroA(&d.Imag)) {
        realMultiply(&a.Real, &d.Real, detR, &ctx159);
        realMultiply(&b.Real, &c.Real, trR, &ctx159); // reuse trR as temp
        realSubtract(detR, trR, detR, &ctx159);
        realSetZero(detI);
    } else {
        eigenMulElem(a, d, &det, &ctx159);
        eigenMulElem(b, c, &tr, &ctx159);
        realSubtract(detR, trR, detR, &ctx159);
        realSubtract(detI, trI, detI, &ctx159);
    }

    // negative trace -(a + d)
    realAdd(&a.Real, &d.Real, trR, &ctx159);
    realAdd(&a.Imag, &d.Imag, trI, &ctx159);
    realChangeSign(trR);
    realChangeSign(trI);

    blockMonitoring = true;
    realSetOne(blockRe(&one));
    realSetZero(blockIm(&one));
    if (comptime runtime.option_eigen_159) {
        var t1H: cplx159_t = undefined;
        var t2H: cplx159_t = undefined;
        realSetZero(t1H.Real.ptr());
        realSetZero(t1H.Imag.ptr());
        realSetZero(t2H.Real.ptr());
        realSetZero(t2H.Imag.ptr());
        math_slvq.solveQuadraticEquation159(&one, &tr, &det, &discr, &t1H, &t2H, &ctx159);
        // Round the 159-digit roots back through the caller's context.
        realPlus(t1H.Real.ptr(), &t1.Real, realContext);
        realPlus(t1H.Imag.ptr(), &t1.Imag, realContext);
        realPlus(t2H.Real.ptr(), &t2.Real, realContext);
        realPlus(t2H.Imag.ptr(), &t2.Imag, realContext);
    } else {
        math_slvq.solveQuadraticEquation(&one, &tr, &det, &discr, t1, t2, &ctx159);
    }
    blockMonitoring = false;

    if (is_real_symmetric) {
        realSetZero(&t1.Imag);
        realSetZero(&t2.Imag);
    }
}

inline fn realSizeInBlocks(comptime digits: u32) u32 {
    return (realSizeInBytes(digits) + 3) / 4;
}

// adjCpxMat: conjugate transpose of a size x size cplx_t matrix.
fn adjCpxMat(x: [*]const cplx_t, size: u16, res: [*]cplx_t) linksection(runtime.code_section) void {
    const sz: usize = size;
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            realCopy(&x[i * sz + j].Real, &res[j * sz + i].Real);
            realCopy(&x[i * sz + j].Imag, &res[j * sz + i].Imag);
            realChangeSign(&res[j * sz + i].Imag);
        }
    }
}

// ===========================================================================
// QR_decomposition_householder -- Householder QR of the size x size cplx_t
// matrix `mat`, producing q and r, also cplx_t. Uses
// a single C47-block bulk allocation for all scratch, matching upstream.
// ===========================================================================
pub export fn QR_decomposition_householder(mat: [*]const cplx_t, size: u16, q: [*]cplx_t, r: [*]cplx_t, realContext: *realContext_t) callconv(.c) void {
    const sz: usize = size;
    const n2: usize = sz * sz; // cplx_t per matrix
    const bulkSize: usize = (sz * sz * 5 + sz) * realSizeInBlocks(75) * 2;

    if (allocCplx(bulkSize)) |bulk| {
        // Zero the entire bulk allocation.
        {
            var z: usize = 0;
            while (z < sz * sz * 5 + sz) : (z += 1) {
                realSetZero(&bulk[z].Real);
                realSetZero(&bulk[z].Imag);
            }
        }

        const matr = bulk;
        const matq = bulk + n2;
        const qq = bulk + 2 * n2;
        const qt = bulk + 3 * n2;
        const newMat = bulk + 4 * n2;
        const v = bulk + 5 * n2;

        var sum: real_t = undefined;
        var mt: cplx_t = undefined;

        // Copy mat -> matr.
        var i: usize = 0;
        while (i < n2) : (i += 1) {
            realCopy(&mat[i].Real, &matr[i].Real);
            realCopy(&mat[i].Imag, &matr[i].Imag);
        }
        // Initialize Q to identity.
        i = 0;
        while (i < n2) : (i += 1) {
            realSetZero(&matq[i].Real);
            realSetZero(&matq[i].Imag);
        }
        i = 0;
        while (i < sz) : (i += 1) realSetOne(&matq[i * sz + i].Real);

        var j: usize = 0;
        while (j < sz - 1) : (j += 1) {
            // Column vector of the sub-matrix + its norm.
            realSetZero(&sum);
            i = 0;
            while (i < sz - j) : (i += 1) {
                realCopy(&matr[(i + j) * sz + j].Real, &v[i].Real);
                realCopy(&matr[(i + j) * sz + j].Imag, &v[i].Imag);
                var temp_v1: real_t = undefined;
                var temp_v2: real_t = undefined;
                realFMA(&v[i].Real, &v[i].Real, &sum, &temp_v1, realContext);
                realCopy(&temp_v1, &sum);
                realFMA(&v[i].Imag, &v[i].Imag, &sum, &temp_v2, realContext);
                realCopy(&temp_v2, &sum);
            }
            realSquareRoot(&sum, &sum, realContext);

            // u = x - alpha e1, with alpha's sign opposite to v[0]'s so the
            // subtraction is effectively an addition and cannot cancel.
            if (realIsZeroA(&v[0].Imag)) {
                if (!realIsNegativeA(&v[0].Real)) {
                    realChangeSign(&sum);
                }
                realSubtract(&v[0].Real, &sum, &v[0].Real, realContext);
            } else {
                // alpha = ||v|| * exp(i*arg(v[0]))
                blockMonitoring = true;
                math_transform_complex_helpers.realRectangularToPolar(&v[0], mt.mag(), mt.arg(), realContext);
                blockMonitoring = true;
                math_transform_complex_helpers.realPolarToRectangular(&sum, mt.arg(), &mt, realContext);
                blockMonitoring = false;
                realAdd(&v[0].Real, &mt.Real, &v[0].Real, realContext);
                realAdd(&v[0].Imag, &mt.Imag, &v[0].Imag, realContext);
            }

            // Norm of u.
            realSetZero(&sum);
            i = 0;
            while (i < sz - j) : (i += 1) {
                var temp_v1: real_t = undefined;
                var temp_v2: real_t = undefined;
                realFMA(&v[i].Real, &v[i].Real, &sum, &temp_v1, realContext);
                realCopy(&temp_v1, &sum);
                realFMA(&v[i].Imag, &v[i].Imag, &sum, &temp_v2, realContext);
                realCopy(&temp_v2, &sum);
            }
            realSquareRoot(&sum, &sum, realContext);

            // v = u / ||u|| with a precision-dependent zero threshold.
            var min_norm: real_t = undefined;
            realSetOne(&min_norm);
            min_norm.exponent -= realContext.digits;

            i = 0;
            while (i < sz - j) : (i += 1) {
                if (realCompareLessThan(&sum, &min_norm)) {
                    // Norm too small for the precision: keep the vector as it
                    // is, which skips this Householder step.
                    realCopy(&v[i].Real, &mt.Real);
                    realCopy(&v[i].Imag, &mt.Imag);
                } else if (realIsZeroA(&v[i].Imag)) {
                    realDivide(&v[i].Real, &sum, &mt.Real, realContext);
                    realSetZero(&mt.Imag);
                } else {
                    realCopy(&sum, &mt.Real);
                    realSetZero(&mt.Imag);
                    divComplexComplex(&v[i], &mt, &mt, realContext);
                }
                realCopy(&mt.Real, &v[i].Real);
                realCopy(&mt.Imag, &v[i].Imag);
            }

            // qq = I.
            i = 0;
            while (i < n2) : (i += 1) {
                realSetZero(&qq[i].Real);
                realSetZero(&qq[i].Imag);
            }
            i = 0;
            while (i < sz) : (i += 1) realSetOne(&qq[i * sz + i].Real);

            // qq -= 2 v v*.
            i = 0;
            while (i < sz - j) : (i += 1) {
                var k: usize = 0;
                while (k < sz - j) : (k += 1) {
                    const qe = (i + j) * sz + k + j;
                    realSubtract(const_0(), &v[k].Imag, &sum, realContext);
                    if (realIsZeroA(&v[i].Imag) and realIsZeroA(&sum)) {
                        realMultiply(&v[i].Real, &v[k].Real, &mt.Real, realContext);
                        realSetZero(&mt.Imag);
                    } else {
                        realCopy(&v[k].Real, &mt.Real); // mt = conj(v[k]), sum takes -Im v[k]
                        realCopy(&sum, &mt.Imag);
                        mulComplexComplex(&v[i], &mt, &mt, realContext);
                    }
                    realMultiply(&mt.Real, const_2(), &mt.Real, realContext);
                    realMultiply(&mt.Imag, const_2(), &mt.Imag, realContext);
                    realSubtract(&qq[qe].Real, &mt.Real, &qq[qe].Real, realContext);
                    realSubtract(&qq[qe].Imag, &mt.Imag, &qq[qe].Imag, realContext);
                }
            }

            // R = qq * matr.
            math_matrix_complex_core.mulCpxMat(qq, matr, size, size, size, newMat, realContext);
            i = 0;
            while (i < n2) : (i += 1) {
                realCopy(&newMat[i].Real, &matr[i].Real);
                realCopy(&newMat[i].Imag, &matr[i].Imag);
            }
            // Q = matq * qq*.
            adjCpxMat(qq, size, qt);
            math_matrix_complex_core.mulCpxMat(matq, qt, size, size, size, newMat, realContext);
            i = 0;
            while (i < n2) : (i += 1) {
                realCopy(&newMat[i].Real, &matq[i].Real);
                realCopy(&newMat[i].Imag, &matq[i].Imag);
            }
        }

        // Make sure R is triangular.
        j = 0;
        while (j < sz - 1) : (j += 1) {
            i = j + 1;
            while (i < sz) : (i += 1) {
                realSetZero(&matr[i * sz + j].Real);
                realSetZero(&matr[i * sz + j].Imag);
            }
        }

        // Copy results out.
        i = 0;
        while (i < n2) : (i += 1) {
            realCopy(&matq[i].Real, &q[i].Real);
            realCopy(&matq[i].Imag, &q[i].Imag);
            realCopy(&matr[i].Real, &r[i].Real);
            realCopy(&matr[i].Imag, &r[i].Imag);
        }

        freeC47Blocks(bulk, bulkSize);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function QR_decomposition_householder:", "Ram full", null, null);
        }
    }
}

// ===========================================================================
// calculateEigenvalues33 -- closed-form eigenvalues of the bottom-right 3x3
// sub-matrix via its characteristic cubic (see eigen_block_digits for the
// precision the configuration selects).
// ===========================================================================
pub export fn calculateEigenvalues33(mat: [*]const cplx_t, size: u16, t1: *cplx_t, t2: *cplx_t, t3: *cplx_t, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
    var ctx159: realContext_t = runtime.ctxtReal75;
    ctx159.digits = eigen_block_digits;

    var aek: BlockCplx = undefined;
    var bfg: BlockCplx = undefined;
    var cdh: BlockCplx = undefined;
    var ceg: BlockCplx = undefined;
    var bdk: BlockCplx = undefined;
    var afh: BlockCplx = undefined;
    var b: BlockCplx = undefined;
    var c: BlockCplx = undefined;
    var d: BlockCplx = undefined;
    var discr: BlockCplx = undefined;
    const aekr = blockRe(&aek);
    const aeki = blockIm(&aek);
    const bfgr = blockRe(&bfg);
    const bfgi = blockIm(&bfg);
    const cdhr = blockRe(&cdh);
    const cdhi = blockIm(&cdh);
    const cegr = blockRe(&ceg);
    const cegi = blockIm(&ceg);
    const bdkr = blockRe(&bdk);
    const bdki = blockIm(&bdk);
    const afhr = blockRe(&afh);
    const afhi = blockIm(&afh);
    const br = blockRe(&b);
    const bi = blockIm(&b);
    const cr = blockRe(&c);
    const ci = blockIm(&c);
    const dr = blockRe(&d);
    const di = blockIm(&d);
    const discrR = blockRe(&discr);
    const discrI = blockIm(&discr);

    const sz: usize = size;
    var m: [9]*const cplx_t = undefined;
    m[0] = &mat[(sz - 3) * sz + (sz - 3)];
    m[1] = &mat[(sz - 3) * sz + (sz - 2)];
    m[2] = &mat[(sz - 3) * sz + (sz - 1)];
    m[3] = &mat[(sz - 2) * sz + (sz - 3)];
    m[4] = &mat[(sz - 2) * sz + (sz - 2)];
    m[5] = &mat[(sz - 2) * sz + (sz - 1)];
    m[6] = &mat[(sz - 1) * sz + (sz - 3)];
    m[7] = &mat[(sz - 1) * sz + (sz - 2)];
    m[8] = &mat[(sz - 1) * sz + (sz - 1)];

    realSetZero(br);
    realSetZero(bi);
    realSetZero(cr);
    realSetZero(ci);
    realSetZero(dr);
    realSetZero(di);
    realSetZero(discrR);
    realSetZero(discrI);
    realSetZero(aekr);
    realSetZero(aeki);
    realSetZero(bfgr);
    realSetZero(bfgi);
    realSetZero(cdhr);
    realSetZero(cdhi);
    realSetZero(cegr);
    realSetZero(cegi);
    realSetZero(bdkr);
    realSetZero(bdki);
    realSetZero(afhr);
    realSetZero(afhi);

    // quadratic coefficient: -trace
    realAdd(&m[0].Real, &m[4].Real, br, &ctx159);
    realAdd(&m[0].Imag, &m[4].Imag, bi, &ctx159);
    realAdd(br, &m[8].Real, br, &ctx159);
    realAdd(bi, &m[8].Imag, bi, &ctx159);
    realChangeSign(br);
    realChangeSign(bi);

    // linear coefficient: sum of principal 2x2 minors
    eigenMulElem(m[0], m[4], &aek, &ctx159);
    eigenMulElem(m[1], m[3], &bdk, &ctx159);
    eigenMulElem(m[0], m[8], &cdh, &ctx159);
    eigenMulElem(m[2], m[6], &ceg, &ctx159);
    eigenMulElem(m[4], m[8], &bfg, &ctx159);
    eigenMulElem(m[5], m[7], &afh, &ctx159);
    realAdd(aekr, cdhr, cr, &ctx159);
    realAdd(aeki, cdhi, ci, &ctx159);
    realAdd(cr, bfgr, cr, &ctx159);
    realAdd(ci, bfgi, ci, &ctx159);
    realSubtract(cr, bdkr, cr, &ctx159);
    realSubtract(ci, bdki, ci, &ctx159);
    realSubtract(cr, cegr, cr, &ctx159);
    realSubtract(ci, cegi, ci, &ctx159);
    realSubtract(cr, afhr, cr, &ctx159);
    realSubtract(ci, afhi, ci, &ctx159);

    // constant term: -determinant
    eigenMul(aekr, aeki, &m[8].Real, &m[8].Imag, &aek, &ctx159);
    eigenMulElem(m[1], m[5], &bfg, &ctx159);
    eigenMul(bfgr, bfgi, &m[6].Real, &m[6].Imag, &bfg, &ctx159);
    eigenMulElem(m[2], m[3], &cdh, &ctx159);
    eigenMul(cdhr, cdhi, &m[7].Real, &m[7].Imag, &cdh, &ctx159);
    eigenMul(cegr, cegi, &m[4].Real, &m[4].Imag, &ceg, &ctx159);
    eigenMul(bdkr, bdki, &m[8].Real, &m[8].Imag, &bdk, &ctx159);
    eigenMul(afhr, afhi, &m[0].Real, &m[0].Imag, &afh, &ctx159);
    realAdd(aekr, bfgr, dr, &ctx159);
    realAdd(aeki, bfgi, di, &ctx159);
    realAdd(dr, cdhr, dr, &ctx159);
    realAdd(di, cdhi, di, &ctx159);
    realSubtract(dr, cegr, dr, &ctx159);
    realSubtract(di, cegi, di, &ctx159);
    realSubtract(dr, bdkr, dr, &ctx159);
    realSubtract(di, bdki, di, &ctx159);
    realSubtract(dr, afhr, dr, &ctx159);
    realSubtract(di, afhi, di, &ctx159);
    realChangeSign(dr);
    realChangeSign(di);

    blockMonitoring = true;
    if (comptime runtime.option_eigen_159) {
        var t1H: cplx159_t = undefined;
        var t2H: cplx159_t = undefined;
        var t3H: cplx159_t = undefined;
        realSetZero(t1H.Real.ptr());
        realSetZero(t1H.Imag.ptr());
        realSetZero(t2H.Real.ptr());
        realSetZero(t2H.Imag.ptr());
        realSetZero(t3H.Real.ptr());
        realSetZero(t3H.Imag.ptr());

        math_slvc.solveCubicEquation159(&b, &c, &d, &discr, &t1H, &t2H, &t3H, &ctx159);

        // Round the 159-digit roots back through the caller's context.
        realPlus(t1H.Real.ptr(), &t1.Real, realContext);
        realPlus(t1H.Imag.ptr(), &t1.Imag, realContext);
        realPlus(t2H.Real.ptr(), &t2.Real, realContext);
        realPlus(t2H.Imag.ptr(), &t2.Imag, realContext);
        realPlus(t3H.Real.ptr(), &t3.Real, realContext);
        realPlus(t3H.Imag.ptr(), &t3.Imag, realContext);
    } else {
        math_slvc.solveCubicEquation(&b, &c, &d, &discr, t1, t2, t3, &ctx159);
    }
    blockMonitoring = false;

    if (is_real_symmetric) {
        realSetZero(&t1.Imag);
        realSetZero(&t2.Imag);
        realSetZero(&t3.Imag);
    }
}

// ===========================================================================
// Eigenvalue ordering and matrix-shape helpers.
// ===========================================================================

// Merge-sort the computed eigenvalues (stored on the diagonal of eig) by
// descending magnitude, using the (i+1)/(i+2) off-diagonal slots as scratch.
fn sortEigenvalues(eig: [*]cplx_t, size: u16, begin_a: u16, begin_b: u16, end_b: u16, realContext: *realContext_t) linksection(runtime.code_section) void {
    const end_a: u16 = begin_b - 1;
    const sz: usize = size;

    if (size < 2) {
        return;
    } else if (begin_a == end_b) {
        return;
    } else if (size == 2) { // simply compare
        complexMagnitude(&eig[0], &eig[1].Real, realContext);
        complexMagnitude(&eig[3], &eig[2].Real, realContext);
        if (realCompareLessThan(&eig[1].Real, &eig[2].Real)) {
            realCopy(&eig[0].Real, &eig[1].Real);
            realCopy(&eig[0].Imag, &eig[1].Imag);
            realCopy(&eig[3].Real, &eig[0].Real);
            realCopy(&eig[3].Imag, &eig[0].Imag);
            realCopy(&eig[1].Real, &eig[3].Real);
            realCopy(&eig[1].Imag, &eig[3].Imag);
        }
    } else {
        var a: u16 = begin_a;
        var b: u16 = begin_b;
        sortEigenvalues(eig, size, begin_a, @intCast((@as(u32, begin_a) + end_a + 2) / 2), end_a, realContext);
        sortEigenvalues(eig, size, begin_b, @intCast((@as(u32, begin_b) + end_b + 2) / 2), end_b, realContext);
        var i: u16 = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            complexMagnitude(&eig[ii * sz + ii], &eig[ii * sz + (ii + 1) % sz].Real, realContext);
        }
        i = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            const dst = &eig[ii * sz + (ii + 2) % sz];
            const aa: usize = a;
            const bb: usize = b;
            if (a > end_a) {
                realCopy(&eig[bb * sz + bb].Real, &dst.Real);
                realCopy(&eig[bb * sz + bb].Imag, &dst.Imag);
                b += 1;
            } else if (b > end_b) {
                realCopy(&eig[aa * sz + aa].Real, &dst.Real);
                realCopy(&eig[aa * sz + aa].Imag, &dst.Imag);
                a += 1;
            } else if (realCompareLessThan(&eig[aa * sz + (aa + 1) % sz].Real, &eig[bb * sz + (bb + 1) % sz].Real)) {
                realCopy(&eig[bb * sz + bb].Real, &dst.Real);
                realCopy(&eig[bb * sz + bb].Imag, &dst.Imag);
                b += 1;
            } else {
                realCopy(&eig[aa * sz + aa].Real, &dst.Real);
                realCopy(&eig[aa * sz + aa].Imag, &dst.Imag);
                a += 1;
            }
        }
        i = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            realCopy(&eig[ii * sz + (ii + 2) % sz].Real, &eig[ii * sz + ii].Real);
            realCopy(&eig[ii * sz + (ii + 2) % sz].Imag, &eig[ii * sz + ii].Imag);
        }
    }
}

// True when every off-diagonal element has magnitude below tol.
fn isMatrixDiagonal(matrix: [*]const cplx_t, size: u16, tol: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    for (0..sz) |i| {
        for (0..sz) |j| {
            if (i != j) {
                var offdiag_mag: real_t = undefined;
                complexMagnitude(&matrix[i * sz + j], &offdiag_mag, realContext);
                if (!realCompareLessThan(&offdiag_mag, tol)) {
                    return false;
                }
            }
        }
    }
    return true;
}

// ===========================================================================
// Sum of the selected elements of the top-left activeSize x activeSize part of
// a square matrix: DIAG the diagonal, SUPSUBDIAG the super- and subdiagonal,
// NONDIAG every off-diagonal element, CHDIAG the change of the diagonal since
// the previous call, which firstCall starts by recording it in
// previousDiagonal. CHDIAG alone reads previousDiagonal. ABS_SUMS is defined
// and CONV_SUM_159 is not, so each element adds |Re| + |Im| at realContext.
// ===========================================================================

fn sumOfSubSupDiagonalAll(heading: [*:0]const u8, matrix: [*]const cplx_t, previousDiagonal: ?[*]cplx_t, size: u16, activeSize: u16, mode: c_int, sum: *real_t, firstCall: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = heading;
    var elemRe: real_t = undefined;
    var elemIm: real_t = undefined;
    realSetZero(sum);
    const sz: usize = size;
    var i: u16 = 0;
    while (i < activeSize) : (i += 1) {
        var j: u16 = 0;
        while (j < activeSize) : (j += 1) {
            const include = switch (mode) {
                DIAG => i == j,
                SUPSUBDIAG => (i == j + 1) or (j == i + 1),
                NONDIAG => i != j,
                CHDIAG => i == j,
                else => false,
            };
            if (include) {
                const ii: usize = i;
                const jj: usize = j;
                realCopy(&matrix[ii * sz + jj].Real, &elemRe);
                realCopy(&matrix[ii * sz + jj].Imag, &elemIm);
                if (mode == CHDIAG) {
                    const previous = previousDiagonal.?;
                    if (firstCall) {
                        // store the initial diagonal and skip summing
                        realCopy(&elemRe, &previous[ii].Real);
                        realCopy(&elemIm, &previous[ii].Imag);
                        continue;
                    } else {
                        // change = |current - previous|
                        var prevRe: real_t = undefined;
                        var prevIm: real_t = undefined;
                        var changeRe: real_t = undefined;
                        var changeIm: real_t = undefined;
                        realCopy(&previous[ii].Real, &prevRe);
                        realCopy(&previous[ii].Imag, &prevIm);
                        realSubtract(&elemRe, &prevRe, &changeRe, realContext);
                        realSubtract(&elemIm, &prevIm, &changeIm, realContext);
                        realSetPositiveSign(&changeRe);
                        realSetPositiveSign(&changeIm);
                        realCopy(&elemRe, &previous[ii].Real);
                        realCopy(&elemIm, &previous[ii].Imag);
                        elemRe = changeRe;
                        elemIm = changeIm;
                    }
                } else {
                    realSetPositiveSign(&elemRe);
                    realSetPositiveSign(&elemIm);
                }
                // ABS_SUMS: the sum of absolute values, not of squares.
                realAdd(&elemRe, sum, sum, realContext);
                realAdd(&elemIm, sum, sum, realContext);
            }
        }
    }
}

pub export fn dropNoise(eig: [*]cplx_t, size: u16, dig: u16) linksection(runtime.code_section) callconv(.c) void {
    var c: realContext_t = runtime.ctxtReal39; // ctxtDeNoise
    c.digits = dig;
    c.round = runtime.DEC_ROUND_HALF_UP;
    const sz: usize = size;
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        const ptr = &eig[i * sz + i];
        realPlus(&ptr.Real, &ptr.Real, &c);
        realPlus(&ptr.Imag, &ptr.Imag, &c);
    }
}

fn isElementWithinTolerance(value_re: *align(1) const real_t, value_im: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var mag: real_t = undefined;
    // |value| with the operations of complexMagnitude(), on separate parts.
    realMultiply(value_re, value_re, &mag, realContext);
    realFMA(value_im, value_im, &mag, &mag, realContext);
    realSquareRoot(&mag, &mag, realContext);
    return realCompareLessThan(&mag, tol);
}

// Real symmetric: every imaginary part on and above the diagonal, and every
// a[i][j] - a[j][i], is within 1E-symmetricTolerance.
fn checkMatrixProperties(a: [*]const cplx_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var tol: real_t = undefined;
    realSetOne(&tol);
    tol.exponent -= symmetricTolerance;
    const sz: usize = size;
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        var j: usize = i;
        while (j < sz) : (j += 1) { // only the upper triangle
            const a_ij = &a[i * sz + j];
            const a_ji = &a[j * sz + i];
            // a real matrix: the imaginary part is zero
            if (!isElementWithinTolerance(&a_ij.Imag, const_0(), &tol, realContext)) {
                return false;
            }
            // symmetric: a[i][j] == a[j][i]
            if (i < j) {
                var diff_val: real_t = undefined;
                realSubtract(&a_ij.Real, &a_ji.Real, &diff_val, realContext);
                if (!isElementWithinTolerance(&diff_val, const_0(), &tol, realContext)) {
                    return false;
                }
            }
        }
    }
    return true;
}

pub export fn isRealSymmetric(a: [*]const cplx_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) bool {
    return checkMatrixProperties(a, size, realContext);
}

fn solveEigenBlock(a: [*]cplx_t, eig: [*]const cplx_t, size: u16, first_unconverged: c_int, last_unconverged: c_int, is_real_symmetric: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    const n = last_unconverged - first_unconverged + 1;
    if (n < 2 or n > 3) {
        return;
    }
    var block: [9]cplx_t = undefined; // the largest block is 3x3
    const sz: usize = size;
    const nn: usize = @intCast(n);
    const fu: usize = @intCast(first_unconverged);
    var row: usize = 0;
    while (row < nn) : (row += 1) {
        var col: usize = 0;
        while (col < nn) : (col += 1) {
            const src_row = fu + row;
            const src_col = fu + col;
            realCopy(&eig[src_row * sz + src_col].Real, &block[row * nn + col].Real);
            realCopy(&eig[src_row * sz + src_col].Imag, &block[row * nn + col].Imag);
        }
    }
    var ev: [3]cplx_t = undefined;
    if (n == 2) {
        calculateEigenvalues22(&block, 2, &ev[0], &ev[1], is_real_symmetric, realContext);
    } else if (n == 3) {
        calculateEigenvalues33(&block, 3, &ev[0], &ev[1], &ev[2], is_real_symmetric, realContext);
    }
    // Write the eigenvalues back to the diagonal of a.
    var i: usize = 0;
    while (i < nn) : (i += 1) {
        const pos = fu + i;
        realCopy(&ev[i].Real, &a[pos * sz + pos].Real);
        realCopy(&ev[i].Imag, &a[pos * sz + pos].Imag);
    }
}

// The eigenvalues of an exact real symmetric matrix by cyclic Jacobi rotations,
// on the diagonal of matrix. False, with matrix possibly rotated, when an
// element is special, the matrix is not exactly real symmetric, or the
// rotations do not bring the off-diagonal under the tolerance in the
// iteration limit.
fn calculateSymmetricEigenvalues(matrix: [*]cplx_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var smallestExponent: i32 = 999999;
    const sz: usize = size;

    var i: usize = 0;
    while (i < sz * sz) : (i += 1) {
        if (realIsSpecial(&matrix[i].Real) or realIsSpecial(&matrix[i].Imag)) {
            return false;
        }
        if (!realIsZeroA(&matrix[i].Real)) {
            smallestExponent = @min(smallestExponent, realGetExponent(&matrix[i].Real));
        }
        if (!realIsZeroA(&matrix[i].Imag)) {
            smallestExponent = @min(smallestExponent, realGetExponent(&matrix[i].Imag));
        }
    }
    var row: usize = 0;
    while (row < sz) : (row += 1) {
        var column: usize = row;
        while (column < sz) : (column += 1) {
            if (!realIsZeroA(&matrix[row * sz + column].Imag) or
                !realIsZeroA(&matrix[column * sz + row].Imag) or
                !realCompareEqual(&matrix[row * sz + column].Real, &matrix[column * sz + row].Real))
            {
                return false;
            }
        }
    }

    const iterationLimit: u32 = @as(u32, size) * 12 + 24;
    var iteration: u32 = 0;
    while (iteration < iterationLimit) : (iteration += 1) {
        var p: usize = 0;
        while (p + 1 < sz) : (p += 1) {
            var q: usize = p + 1;
            while (q < sz) : (q += 1) {
                const apq = &matrix[p * sz + q].Real;
                if (realIsZeroA(apq)) {
                    continue;
                }

                var tau: real_t = undefined;
                var denominator: real_t = undefined;
                var magnitude: real_t = undefined;
                var t: real_t = undefined;
                var c: real_t = undefined;
                var s: real_t = undefined;
                var term: real_t = undefined;
                realSubtract(&matrix[q * sz + q].Real, &matrix[p * sz + p].Real, &tau, realContext);
                realMultiply(apq, const_2(), &denominator, realContext);
                realDivide(&tau, &denominator, &tau, realContext);
                realCopyAbs(&tau, &magnitude);
                realFMA(&magnitude, &magnitude, const_1(), &denominator, realContext);
                realSquareRoot(&denominator, &denominator, realContext);
                realAdd(&magnitude, &denominator, &denominator, realContext);
                realDivide(const_1(), &denominator, &t, realContext);
                if (realIsNegativeA(&tau)) {
                    realChangeSign(&t);
                }

                realFMA(&t, &t, const_1(), &denominator, realContext);
                realSquareRoot(&denominator, &denominator, realContext);
                realDivide(const_1(), &denominator, &c, realContext);
                realMultiply(&t, &c, &s, realContext);

                realMultiply(&t, apq, &term, realContext);
                realSubtract(&matrix[p * sz + p].Real, &term, &matrix[p * sz + p].Real, realContext);
                realAdd(&matrix[q * sz + q].Real, &term, &matrix[q * sz + q].Real, realContext);
                realSetZero(apq);
                realSetZero(&matrix[q * sz + p].Real);

                var k: usize = 0;
                while (k < sz) : (k += 1) {
                    if (k == p or k == q) {
                        continue;
                    }
                    var oldP: real_t = undefined;
                    var oldQ: real_t = undefined;
                    var newP: real_t = undefined;
                    var newQ: real_t = undefined;
                    realCopy(&matrix[k * sz + p].Real, &oldP);
                    realCopy(&matrix[k * sz + q].Real, &oldQ);
                    realMultiply(&c, &oldP, &newP, realContext);
                    realMultiply(&s, &oldQ, &term, realContext);
                    realSubtract(&newP, &term, &newP, realContext);
                    realMultiply(&c, &oldQ, &newQ, realContext);
                    realFMA(&s, &oldP, &newQ, &newQ, realContext);
                    realCopy(&newP, &matrix[k * sz + p].Real);
                    realCopy(&newP, &matrix[p * sz + k].Real);
                    realCopy(&newQ, &matrix[k * sz + q].Real);
                    realCopy(&newQ, &matrix[q * sz + k].Real);
                }
            }
        }

        var offDiagonalMax: real_t = undefined;
        var diagonalMax: real_t = undefined;
        var magnitude: real_t = undefined;
        var tolerance: real_t = undefined;
        realSetZero(&offDiagonalMax);
        realSetZero(&diagonalMax);
        row = 0;
        while (row < sz) : (row += 1) {
            realCopyAbs(&matrix[row * sz + row].Real, &magnitude);
            if (realCompareLessThan(&diagonalMax, &magnitude)) {
                realCopy(&magnitude, &diagonalMax);
            }
            var column: usize = row + 1;
            while (column < sz) : (column += 1) {
                realCopyAbs(&matrix[row * sz + column].Real, &magnitude);
                if (realCompareLessThan(&offDiagonalMax, &magnitude)) {
                    realCopy(&magnitude, &offDiagonalMax);
                }
            }
        }
        realCopy(&diagonalMax, &tolerance);
        if (realIsZeroA(&tolerance)) { // a zero diagonal gives no scale, so the test falls back to one
            realSetOne(&tolerance);
        }
        tolerance.exponent -= 60;
        if (realCompareLessThan(&offDiagonalMax, &tolerance)) {
            // rounding noise of the rotations, below the smallest input element
            row = 0;
            while (row < sz) : (row += 1) {
                if (realGetExponent(&matrix[row * sz + row].Real) < smallestExponent - eigenNoiseThreshold) {
                    realSetZero(&matrix[row * sz + row].Real);
                }
            }
            return true;
        }
    }
    return false;
}

// ===========================================================================
// Eigenvalues of a general complex matrix of size > 3, by the scheme LAPACK's
// dlahqr uses: reduce to upper Hessenberg once, then run shifted QR on that
// form with Givens rotations. A sweep costs O(n^2) and neither Q nor R is
// formed. The shift is a single complex one, so a complex eigenvalue deflates
// as a 1x1 and no real 2x2 block machinery is needed.
// ===========================================================================

// Element (i, j) of the n x n complex matrix m (matrix.c's CX).
inline fn cxAt(m: anytype, n: u16, i: usize, j: usize) @TypeOf(&m[0]) {
    return &m[i * n + j];
}

fn cxCopy(src: *const cplx_t, dst: *cplx_t) linksection(runtime.code_section) void {
    realCopy(&src.Real, &dst.Real);
    realCopy(&src.Imag, &dst.Imag);
}

fn cxSetZero(z: *cplx_t) linksection(runtime.code_section) void {
    realSetZero(&z.Real);
    realSetZero(&z.Imag);
}

fn cxConj(x: *const cplx_t, z: *cplx_t) linksection(runtime.code_section) void {
    realCopy(&x.Real, &z.Real);
    realCopy(&x.Imag, &z.Imag);
    if (!realIsZeroA(&z.Imag)) {
        realChangeSign(&z.Imag);
    }
}

// LAPACK CABS1: |Re x| + |Im x|, the norm zlahqr's deflation tests use, with no
// square root.
fn cxAbs1(x: *const cplx_t, r: *real_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var t: real_t = undefined;
    realCopyAbs(&x.Real, r);
    realCopyAbs(&x.Imag, &t);
    realAdd(r, &t, r, ctx);
}

fn cxIsZero(x: *const cplx_t) linksection(runtime.code_section) bool {
    return realIsZeroA(&x.Real) and realIsZeroA(&x.Imag);
}

// Principal square root through polar form.
fn cxSqrt(x: *const cplx_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var m: real_t = undefined;
    var t: real_t = undefined;

    if (cxIsZero(x)) {
        cxSetZero(z);
        return;
    }
    blockMonitoring = true;
    math_transform_complex_helpers.realRectangularToPolar(x, &m, &t, ctx);
    blockMonitoring = false;
    realSquareRoot(&m, &m, ctx);
    realMultiply(&t, const_1on2(), &t, ctx);
    blockMonitoring = true;
    math_transform_complex_helpers.realPolarToRectangular(&m, &t, z, ctx);
    blockMonitoring = false;
}

// Reduction to upper Hessenberg by complex Householder similarity, in place on
// a (n x n complex). Scratch: v and w, n complex each.
fn hessenbergReduce(a: [*]cplx_t, n: u16, v: [*]cplx_t, w: [*]cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var nrm: real_t = undefined;
    var alpha: real_t = undefined;
    var tmp: real_t = undefined;
    var two: real_t = undefined;

    realAdd(const_1(), const_1(), &two, ctx);

    var k: u16 = 0;
    while (k + 2 < n) : (k += 1) {
        // x = a[k+1..n-1][k]; nothing to do when it is already a single element
        realSetZero(&nrm);
        var i: u16 = k + 1;
        while (i < n) : (i += 1) {
            complexMagnitude(cxAt(a, n, i, k), &tmp, ctx);
            realFMA(&tmp, &tmp, &nrm, &nrm, ctx);
        }
        realSquareRoot(&nrm, &nrm, ctx);
        if (realIsZeroA(&nrm)) {
            continue;
        }

        // is the column already reduced?
        {
            var reduced = true;
            i = k + 2;
            while (reduced and i < n) : (i += 1) {
                reduced = cxIsZero(cxAt(a, n, i, k));
            }
            if (reduced) {
                continue;
            }
        }

        // v = x + e^{i arg(x0)} * ||x|| * e1, then normalise
        i = k + 1;
        while (i < n) : (i += 1) {
            cxCopy(cxAt(a, n, i, k), &v[i]);
        }
        complexMagnitude(&v[k + 1], &alpha, ctx);
        if (realIsZeroA(&alpha)) {
            realAdd(&v[k + 1].Real, &nrm, &v[k + 1].Real, ctx);
        } else {
            var phase: cplx_t = undefined;
            realDivide(&nrm, &alpha, &tmp, ctx); // ||x|| / |x0|
            mulComplexReal(&v[k + 1], &tmp, &phase, ctx);
            addComplex(&v[k + 1], &phase, &v[k + 1], ctx);
        }

        realSetZero(&nrm);
        i = k + 1;
        while (i < n) : (i += 1) {
            complexMagnitude(&v[i], &tmp, ctx);
            realFMA(&tmp, &tmp, &nrm, &nrm, ctx);
        }
        realSquareRoot(&nrm, &nrm, ctx);
        if (realIsZeroA(&nrm)) {
            continue;
        }
        i = k + 1;
        while (i < n) : (i += 1) {
            divComplexReal(&v[i], &nrm, &v[i], ctx);
        }

        // A[k+1:, :] -= 2 v (v^H A[k+1:, :])
        var j: u16 = 0;
        while (j < n) : (j += 1) {
            var acc: cplx_t = undefined;
            var cv: cplx_t = undefined;
            var prod: cplx_t = undefined;
            cxSetZero(&acc);
            i = k + 1;
            while (i < n) : (i += 1) {
                cxConj(&v[i], &cv);
                mulComplexComplex(&cv, cxAt(a, n, i, j), &prod, ctx);
                addComplex(&acc, &prod, &acc, ctx);
            }
            mulComplexReal(&acc, &two, &acc, ctx);
            cxCopy(&acc, &w[j]);
        }
        i = k + 1;
        while (i < n) : (i += 1) {
            j = 0;
            while (j < n) : (j += 1) {
                var prod: cplx_t = undefined;
                mulComplexComplex(&v[i], &w[j], &prod, ctx);
                subComplex(cxAt(a, n, i, j), &prod, cxAt(a, n, i, j), ctx);
            }
        }

        // A[:, k+1:] -= 2 (A[:, k+1:] v) v^H
        i = 0;
        while (i < n) : (i += 1) {
            var acc: cplx_t = undefined;
            var prod: cplx_t = undefined;
            cxSetZero(&acc);
            j = k + 1;
            while (j < n) : (j += 1) {
                mulComplexComplex(cxAt(a, n, i, j), &v[j], &prod, ctx);
                addComplex(&acc, &prod, &acc, ctx);
            }
            mulComplexReal(&acc, &two, &acc, ctx);
            cxCopy(&acc, &w[i]);
        }
        i = 0;
        while (i < n) : (i += 1) {
            j = k + 1;
            while (j < n) : (j += 1) {
                var cv: cplx_t = undefined;
                var prod: cplx_t = undefined;
                cxConj(&v[j], &cv);
                mulComplexComplex(&w[i], &cv, &prod, ctx);
                subComplex(cxAt(a, n, i, j), &prod, cxAt(a, n, i, j), ctx);
            }
        }

        // the annihilated entries are structurally zero: set them so exactly
        i = k + 2;
        while (i < n) : (i += 1) {
            cxSetZero(cxAt(a, n, i, k));
        }
    }
}

// Complex Givens rotation: c real, s complex, with
//   [ c        s ] [ f ]   [ r ]
//   [ -conj(s) c ] [ g ] = [ 0 ]
fn cxGivens(f: *const cplx_t, g: *const cplx_t, c: *real_t, s: *cplx_t, r: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var af: real_t = undefined;
    var ag: real_t = undefined;
    var t: real_t = undefined;

    complexMagnitude(f, &af, ctx);
    complexMagnitude(g, &ag, ctx);

    if (realIsZeroA(&ag)) {
        realSetOne(c);
        cxSetZero(s);
        cxCopy(f, r);
        return;
    }
    if (realIsZeroA(&af)) {
        realSetZero(c);
        cxSetZero(s);
        realSetOne(&s.Real); // s = 1
        cxCopy(g, r);
        return;
    }

    realMultiply(&af, &af, &t, ctx);
    realFMA(&ag, &ag, &t, &t, ctx);
    realSquareRoot(&t, &t, ctx); // t = sqrt(|f|^2 + |g|^2)

    realDivide(&af, &t, c, ctx); // c = |f| / t

    {
        var phase: cplx_t = undefined;
        var cg: cplx_t = undefined;
        divComplexReal(f, &af, &phase, ctx); // phase = f / |f|
        cxConj(g, &cg);
        mulComplexComplex(&phase, &cg, s, ctx);
        divComplexReal(s, &t, s, ctx); // s = phase * conj(g) / t
        mulComplexReal(&phase, &t, r, ctx); // r = phase * t
    }
}

// One explicit shifted QR sweep on the active Hessenberg window [lo..hi].
// Rotations are kept in cs (n reals) and sn (n complex).
fn hessenbergQrSweep(a: [*]cplx_t, n: u16, lo: u16, hi: u16, shift: *const cplx_t, cs: [*]real_t, sn: [*]cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var i: u16 = lo;
    while (i <= hi) : (i += 1) {
        subComplex(cxAt(a, n, i, i), shift, cxAt(a, n, i, i), ctx);
    }

    // QR: annihilate the subdiagonal left to right
    var k: u16 = lo;
    while (k < hi) : (k += 1) {
        var c: real_t = undefined;
        var s: cplx_t = undefined;
        var r: cplx_t = undefined;

        cxGivens(cxAt(a, n, k, k), cxAt(a, n, k + 1, k), &c, &s, &r, ctx);
        realCopy(&c, &cs[k]);
        cxCopy(&s, &sn[k]);

        cxCopy(&r, cxAt(a, n, k, k));
        cxSetZero(cxAt(a, n, k + 1, k));

        var j: u16 = k + 1;
        while (j <= hi) : (j += 1) {
            var t1: cplx_t = undefined;
            var t2: cplx_t = undefined;
            var u: cplx_t = undefined;
            var w: cplx_t = undefined;
            var cs2: cplx_t = undefined;

            cxCopy(cxAt(a, n, k, j), &u);
            cxCopy(cxAt(a, n, k + 1, j), &w);

            mulComplexReal(&u, &c, &t1, ctx);
            mulComplexComplex(&s, &w, &t2, ctx);
            addComplex(&t1, &t2, cxAt(a, n, k, j), ctx); // c*u + s*w

            cxConj(&s, &cs2);
            mulComplexComplex(&cs2, &u, &t1, ctx);
            mulComplexReal(&w, &c, &t2, ctx);
            subComplex(&t2, &t1, cxAt(a, n, k + 1, j), ctx); // c*w - conj(s)*u
        }
    }

    // RQ: apply the rotations from the right
    k = lo;
    while (k < hi) : (k += 1) {
        const c: real_t = cs[k];
        var s: cplx_t = undefined;
        var cs2: cplx_t = undefined;

        cxCopy(&sn[k], &s);
        cxConj(&s, &cs2);
        const last: u16 = if (k + 2 <= hi) k + 2 else hi;

        i = lo;
        while (i <= last) : (i += 1) {
            var t1: cplx_t = undefined;
            var t2: cplx_t = undefined;
            var u: cplx_t = undefined;
            var w: cplx_t = undefined;

            cxCopy(cxAt(a, n, i, k), &u);
            cxCopy(cxAt(a, n, i, k + 1), &w);

            mulComplexReal(&u, &c, &t1, ctx);
            mulComplexComplex(&cs2, &w, &t2, ctx);
            addComplex(&t1, &t2, cxAt(a, n, i, k), ctx); // c*u + conj(s)*w

            mulComplexComplex(&s, &u, &t1, ctx);
            mulComplexReal(&w, &c, &t2, ctx);
            subComplex(&t2, &t1, cxAt(a, n, i, k + 1), ctx); // c*w - s*u
        }
    }

    i = lo;
    while (i <= hi) : (i += 1) {
        addComplex(cxAt(a, n, i, i), shift, cxAt(a, n, i, i), ctx);
    }
}

// Both eigenvalues of the trailing 2x2 of the active window, [[p,q],[rr,s]] at
// rows hi-1 and hi, from its trace and determinant.
fn cxEig2x2Old(a: [*]const cplx_t, n: u16, hi: u16, l1: *cplx_t, l2: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    const p = cxAt(a, n, hi - 1, hi - 1);
    const q = cxAt(a, n, hi - 1, hi);
    const rr = cxAt(a, n, hi, hi - 1);
    const s = cxAt(a, n, hi, hi);
    var tr: cplx_t = undefined;
    var det: cplx_t = undefined;
    var disc: cplx_t = undefined;
    var t1: cplx_t = undefined;
    var t2: cplx_t = undefined;

    addComplex(p, s, &tr, ctx);
    mulComplexComplex(p, s, &t1, ctx);
    mulComplexComplex(q, rr, &t2, ctx);
    subComplex(&t1, &t2, &det, ctx);

    mulComplexComplex(&tr, &tr, &disc, ctx);
    mulComplexReal(&det, const_4(), &t1, ctx);
    subComplex(&disc, &t1, &disc, ctx);
    cxSqrt(&disc, &disc, ctx);

    addComplex(&tr, &disc, l1, ctx);
    mulComplexReal(l1, const_1on2(), l1, ctx);
    subComplex(&tr, &disc, l2, ctx);
    mulComplexReal(l2, const_1on2(), l2, ctx);
}

fn cxEig2x2(a: [*]const cplx_t, n: u16, hi: u16, l1: *cplx_t, l2: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    const p = cxAt(a, n, hi - 1, hi - 1);
    const q = cxAt(a, n, hi - 1, hi);
    const rr = cxAt(a, n, hi, hi - 1);
    const s = cxAt(a, n, hi, hi);
    var x: cplx_t = undefined;
    var u_2: cplx_t = undefined;
    var y: cplx_t = undefined;
    var d: cplx_t = undefined;
    var t: cplx_t = undefined;
    var r1: real_t = undefined;
    var r2: real_t = undefined;

    // LAPACK zlahqr's Wilkinson shift: with x = (p - s) / 2 and u_2 = q r,
    // y = sqrt(x^2 + u_2) takes the sign that makes x + y the larger of x -+ y,
    // and the roots are p + u_2 / (x + y) and s - u_2 / (x + y). Neither subtracts
    // two nearly equal numbers, where (tr - sqrt(tr^2 - 4 det)) / 2 cancels to 0
    // for a root many orders below the other. l1 keeps (tr + sqrt) / 2, l2
    // (tr - sqrt) / 2.
    subComplex(p, s, &x, ctx);
    mulComplexReal(&x, const_1on2(), &x, ctx);
    mulComplexComplex(q, rr, &u_2, ctx);
    mulComplexComplex(&x, &x, &y, ctx);
    addComplex(&y, &u_2, &y, ctx);
    cxSqrt(&y, &y, ctx);
    realMultiply(&x.Real, &y.Real, &r1, ctx);
    realFMA(&x.Imag, &y.Imag, &r1, &r2, ctx);
    const flipped = realIsNegativeA(&r2) and !realIsZeroA(&r2);
    if (flipped) {
        realChangeSign(&y.Real);
        realChangeSign(&y.Imag);
    }
    addComplex(&x, &y, &d, ctx);
    if (cxIsZero(&d)) { // x = y = 0: p = s and q r = 0, a double root
        cxCopy(p, l1);
        cxCopy(s, l2);
        return;
    }
    math_division_cells.divComplexComplex(&u_2, &d, &t, ctx);
    if (flipped) {
        subComplex(s, &t, l1, ctx);
        addComplex(p, &t, l2, ctx);
    } else {
        addComplex(p, &t, l1, ctx);
        subComplex(s, &t, l2, ctx);
    }
}

// Wilkinson shift: the eigenvalue of that 2x2 nearer its trailing entry.
fn wilkinsonShift(a: [*]const cplx_t, n: u16, hi: u16, shift: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    const s = cxAt(a, n, hi, hi);
    var t1: cplx_t = undefined;
    var t2: cplx_t = undefined;
    var l1: cplx_t = undefined;
    var l2: cplx_t = undefined;
    var d1: real_t = undefined;
    var d2: real_t = undefined;

    cxEig2x2Old(a, n, hi, &l1, &l2, ctx);

    subComplex(&l1, s, &t1, ctx);
    complexMagnitude(&t1, &d1, ctx);
    subComplex(&l2, s, &t2, ctx);
    complexMagnitude(&t2, &d2, ctx);

    cxCopy(if (math_comparison_reals.realCompareLessThan(&d1, &d2)) &l1 else &l2, shift);
}

// Eigenvalues of a general complex matrix, n > 3. a is destroyed. On success
// the eigenvalues are written to the diagonal of eig, which is zeroed first.
// scratch1 holds 2n complex, scratch2 n reals and then n complex. Returns false
// when the iteration does not converge.
fn eigenHessenbergQr(a: [*]cplx_t, eig: [*]cplx_t, scratch1: [*]cplx_t, scratch2: [*]real_t, n: u16, ctx: *realContext_t) linksection(runtime.code_section) bool {
    var inputWasReal = true;
    var scale: real_t = undefined;
    const v = scratch1; // n complex
    const w = scratch1 + n; // n complex
    const cs = scratch2; // n real
    const sn: [*]cplx_t = @ptrCast(scratch2 + n); // n complex
    var eps: real_t = undefined;
    var tmp: real_t = undefined;
    var t1: real_t = undefined;
    var t2: real_t = undefined;
    var w1: real_t = undefined;
    var w2: real_t = undefined;
    var shift: cplx_t = undefined;
    var sweeps: u32 = 0;
    var sinceDeflation: u32 = 0;
    const itmax: u32 = 30 * @max(@as(u32, n), 10); // LAPACK dlaqr0: MAX(30, 2*KEXSH) * MAX(10, nh)

    // LAPACK WILK1 = 0.75 and WILK2 = -7/16, built once per call from the
    // generated constants; both are exact in decimal arithmetic
    realAdd(const_1on2(), const_1on4(), &w1, ctx);
    realMultiply(const_1on4(), const_1on4(), &w2, ctx);
    realMultiply(&w2, const_7(), &w2, ctx);
    realChangeSign(&w2);
    realSetOne(&eps);
    const eigen_tolerance = eigenTolerance();
    eps.exponent -= if (eigen_tolerance > 3) eigen_tolerance - 3 else eigen_tolerance;

    realSetZero(&scale);
    var i: u16 = 0;
    while (i < n) : (i += 1) {
        var j: u16 = 0;
        while (j < n) : (j += 1) {
            if (!realIsZeroA(&cxAt(a, n, i, j).Imag)) {
                inputWasReal = false;
            }
            complexMagnitude(cxAt(a, n, i, j), &tmp, ctx);
            if (math_comparison_reals.realCompareGreaterThan(&tmp, &scale)) {
                realCopy(&tmp, &scale);
            }
        }
    }

    hessenbergReduce(a, n, v, w, ctx);

    var hi: u16 = n - 1;
    while (hi > 0) {
        if (sweeps >= itmax) {
            return false; // the caller reports it: no silent wrong answer
        }
        sweeps += 1;

        // deflate every negligible subdiagonal in the active window
        i = hi;
        while (i >= 1) : (i -= 1) {
            cxAbs1(cxAt(a, n, i, i - 1), &tmp, ctx);
            cxAbs1(cxAt(a, n, i - 1, i - 1), &t1, ctx);
            cxAbs1(cxAt(a, n, i, i), &t2, ctx);
            realAdd(&t1, &t2, &t1, ctx);
            realMultiply(&t1, &eps, &t1, ctx);
            if (realIsZeroA(&tmp)) {
                cxSetZero(cxAt(a, n, i, i - 1));
            } else if (math_comparison_reals.realCompareLessThan(&tmp, &t1)) {
                // Ahues and Tisseur, the criterion dlahqr adopted: a subdiagonal
                // small beside its own two diagonal entries is not on its own
                // grounds to deflate. Where the two differ by orders of magnitude
                // the naive test drops the coupling and reports the diagonal
                // entry, so [[1E3000,1],[1,1E-3000]] yields 1E-3000 in place of
                // the 0 the entries express. Compare the two off-diagonals against
                // the separation instead.
                var ab: real_t = undefined;
                var ba: real_t = undefined;
                var aa: real_t = undefined;
                var bb: real_t = undefined;
                var ss: real_t = undefined;
                var lhs: real_t = undefined;
                var rhs: real_t = undefined;
                var dif: cplx_t = undefined;

                cxAbs1(cxAt(a, n, i - 1, i), &ba, ctx);
                realCopy(&tmp, &ab);
                if (math_comparison_reals.realCompareLessThan(&ab, &ba)) {
                    realCopy(&tmp, &t2);
                    realCopy(&ba, &ab);
                    realCopy(&t2, &ba);
                }
                subComplex(cxAt(a, n, i - 1, i - 1), cxAt(a, n, i, i), &dif, ctx);
                cxAbs1(&dif, &bb, ctx);
                cxAbs1(cxAt(a, n, i, i), &aa, ctx);
                if (math_comparison_reals.realCompareLessThan(&aa, &bb)) {
                    realCopy(&aa, &t2);
                    realCopy(&bb, &aa);
                    realCopy(&t2, &bb);
                }
                realAdd(&aa, &ab, &ss, ctx);
                if (!realIsZeroA(&ss)) {
                    realDivide(&ab, &ss, &lhs, ctx);
                    realMultiply(&ba, &lhs, &lhs, ctx);
                    realDivide(&aa, &ss, &rhs, ctx);
                    realMultiply(&bb, &rhs, &rhs, ctx);
                    realMultiply(&rhs, &eps, &rhs, ctx);
                    if (math_comparison_reals.realCompareLessThan(&lhs, &rhs) or math_comparison_reals.realCompareEqual(&lhs, &rhs)) {
                        cxSetZero(cxAt(a, n, i, i - 1));
                    }
                } else {
                    cxSetZero(cxAt(a, n, i, i - 1));
                }
            }
            if (i == 1) {
                break;
            }
        }

        if (cxIsZero(cxAt(a, n, hi, hi - 1))) {
            hi -= 1; // a[hi][hi] is an eigenvalue
            sinceDeflation = 0;
            continue;
        }

        // A trailing 2x2 is solved from its own trace and determinant rather
        // than iterated, as dlahqr hands one to dlanv2. Iterating it converges
        // to a rounding of the pair instead of the pair: on
        // [[1E3000,1],[1,1E-3000]] the quadratic gives the exact 0 that the
        // entries express, where a sweep leaves 1E-3000 behind.
        if (hi == 1 or cxIsZero(cxAt(a, n, hi - 1, hi - 2))) {
            var l1: cplx_t = undefined;
            var l2: cplx_t = undefined;

            cxEig2x2Old(a, n, hi, &l1, &l2, ctx);
            if (cxIsZero(&l1) or cxIsZero(&l2)) {
                // (tr - sqrt(tr^2 - 4 det)) / 2 cancelled to 0: take zlahqr's
                // form, which keeps a root many orders below the other
                cxEig2x2(a, n, hi, &l1, &l2, ctx);
            }

            cxCopy(&l1, cxAt(a, n, hi - 1, hi - 1));
            cxCopy(&l2, cxAt(a, n, hi, hi));
            cxSetZero(cxAt(a, n, hi, hi - 1));
            hi = if (hi >= 2) hi - 2 else 0; // hi == 1 means the block is the leading one: stop rather than wrap
            sinceDeflation = 0;
            continue;
        }

        // start of the active block: the first non-negligible subdiagonal above hi
        {
            var lo: u16 = hi;
            while (lo > 0 and !cxIsZero(cxAt(a, n, lo, lo - 1))) {
                lo -= 1;
            }

            // Break a cycle the trailing 2x2 cannot see: every KEXSH sweeps
            // without a deflation, take the shift from a 2x2 built on the last
            // two subdiagonals, as LAPACK's dlaqr0 forms it. WILK2 is negative,
            // so that 2x2 has a complex pair and the shift carries the
            // iteration off a symmetric stall.
            sinceDeflation += 1;
            if (sinceDeflation % 10 == 0) {
                var ss: real_t = undefined;
                var bb: cplx_t = undefined;
                var cc: cplx_t = undefined;
                var disc: cplx_t = undefined;
                var aa: cplx_t = undefined;

                complexMagnitude(cxAt(a, n, hi, hi - 1), &ss, ctx);
                if (hi >= lo + 2) {
                    complexMagnitude(cxAt(a, n, hi - 1, hi - 2), &tmp, ctx);
                    realAdd(&ss, &tmp, &ss, ctx);
                }
                realMultiply(&ss, &w1, &aa.Real, ctx);
                realSetZero(&aa.Imag);
                addComplex(&aa, cxAt(a, n, hi, hi), &aa, ctx); // AA = WILK1*SS + H(hi,hi)
                realCopy(&ss, &bb.Real);
                realSetZero(&bb.Imag); // BB = SS
                realMultiply(&ss, &w2, &cc.Real, ctx);
                realSetZero(&cc.Imag); // CC = WILK2*SS
                mulComplexComplex(&bb, &cc, &disc, ctx);
                cxSqrt(&disc, &disc, ctx);
                addComplex(&aa, &disc, &shift, ctx); // an eigenvalue of [[AA,BB],[CC,AA]]
            } else {
                wilkinsonShift(a, n, hi, &shift, ctx);
            }

            hessenbergQrSweep(a, n, lo, hi, &shift, cs, sn, ctx);
        }
    }

    // A real matrix has a real characteristic polynomial, so its eigenvalues are
    // real or exact conjugate pairs. An imaginary part far below the
    // eigenvalue's own scale is therefore convergence residue and not a feature
    // the input could encode: the same reasoning SLVP applies to its roots.
    // Left in place it would type a real spectrum as complex.
    if (inputWasReal) {
        i = 0;
        while (i < n) : (i += 1) {
            const d = cxAt(a, n, i, i);
            if (!realIsZeroA(&d.Imag)) {
                const top: i32 = if (realIsZeroA(&d.Real)) realGetExponent(&scale) else realGetExponent(&d.Real);
                if (realGetExponent(&d.Imag) < top - toleranceDigits()) {
                    realSetZero(&d.Imag);
                }
            }
        }
    }

    i = 0;
    while (i < n) : (i += 1) {
        var j: u16 = 0;
        while (j < n) : (j += 1) {
            cxSetZero(cxAt(eig, n, i, j));
        }
    }
    i = 0;
    while (i < n) : (i += 1) {
        cxCopy(cxAt(a, n, i, i), cxAt(eig, n, i, i));
    }
    return true;
}

// The QR iteration did not converge. LAPACK reports which eigenvalues converged
// and returns; it does not retry with a weaker algorithm.
fn qrDidNotConverge(size: u16) linksection(runtime.code_section) void {
    runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        var buf: [64]u8 = undefined;
        const m = bufPrintZ(&buf, "QR did not converge for a {d} x {d} matrix", .{ size, size }) catch "QR did not converge";
        runtime.moreInfoOnError("In function calculateEigenvalues:", m, null, null);
    }
}

// ===========================================================================
// calculateEigenvalues -- eigenvalues of a size x size matrix in cplx_t
// arrays; the results land on the diagonal of eig. Size 2 and 3 use the
// closed-form solvers. A larger exact real symmetric matrix takes cyclic Jacobi
// rotations; one that is diagonal to the deep tolerance is taken as it is; any
// other runs eigenHessenbergQr, which destroys a. scratch holds the engine's
// 7 * size reals. On non-convergence ERROR_NO_ROOT_FOUND is raised and the
// caller writes no result.
// ===========================================================================
// SLVP feeds its companion matrix through here (upstream drops the `static` on
// matrix.c's copy when OPTION_SLVP_POLY is on); slvp.zig shares this object, so the
// Zig side needs `pub`, not a C-ABI export.
pub fn calculateEigenvalues(a: [*]cplx_t, scratch: [*]cplx_t, eig: [*]cplx_t, size: u16, shifted: bool, reducedSignificantDigits: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = shifted;
    const sz: usize = size;
    const tolerance_digits = toleranceDigits();
    const eigen_tolerance = eigenTolerance();
    var converged: bool = false;
    // The engine's real_t scratch follows the 2 * size cplx_t of its own.
    const scratch2: [*]real_t = @ptrCast(&scratch[sz * 2].Real);

    const is_real_symmetric = isRealSymmetric(a, size, realContext);

    // Initialize eig to zero, then copy the input matrix to it.
    {
        var k: usize = 0;
        while (k < sz * sz) : (k += 1) {
            realSetZero(&eig[k].Real);
            realSetZero(&eig[k].Imag);
        }
        var ii: usize = 0;
        while (ii < sz) : (ii += 1) {
            var jj: usize = 0;
            while (jj < sz) : (jj += 1) {
                realCopy(&a[ii * sz + jj].Real, &eig[ii * sz + jj].Real);
                realCopy(&a[ii * sz + jj].Imag, &eig[ii * sz + jj].Imag);
            }
        }
    }

    // The epilogue decrement runs on every path, so the increment belongs here
    // and not in the QR branch only: otherwise each analytic 2x2/3x3 solve
    // underflows the depth and FLAG_SOLVING never clears.
    currentKeyCode = 255;
    currentSolverNestingDepth += 1;
    runtime.setSystemFlag(@intCast(FLAG_SOLVING));

    if (size == 2) {
        calculateEigenvalues22(a, size, &eig[0], &eig[3], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, 39);
    } else if (size == 3) {
        calculateEigenvalues33(a, size, &eig[0], &eig[4], &eig[8], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, 39);
    } else done: {
        if (is_real_symmetric and calculateSymmetricEigenvalues(eig, size, realContext)) {
            sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
            dropNoise(eig, size, 39);
            break :done;
        }

        var tol: real_t = undefined;
        if (reducedSignificantDigits) {
            if (tolerance_digits >= 34 or tolerance_digits == 0) {
                realSetOne(&tol);
                tol.exponent -= eigen_tolerance;
            } else {
                realSetOne(&tol);
                tol.exponent -= tolerance_digits;
            }
        } else {
            realSetOne(&tol);
            tol.exponent -= eigen_tolerance;
        }

        if (isMatrixDiagonal(a, size, &tol, realContext)) {
            var k: usize = 0;
            while (k < sz * sz) : (k += 1) {
                realCopy(&a[k].Real, &eig[k].Real);
                realCopy(&a[k].Imag, &eig[k].Imag);
            }
            converged = true;
        }

        // Destroys a. On non-convergence the caller raises ERROR_NO_ROOT_FOUND
        // and writes no result.
        if (!converged and runtime.lastErrorCode == runtime.ERROR_NONE) {
            if (eigenHessenbergQr(a, eig, scratch, scratch2, size, realContext)) {
                converged = true;
            } else {
                qrDidNotConverge(size);
            }
        }

        // POST_QR_RELATIVE_BLOCK_CHECK: the block threshold is relative to the
        // average diagonal magnitude.
        var diag_sum: real_t = undefined;
        var avg_diag: real_t = undefined;
        var rel_threshold: real_t = undefined;
        var matrixSize: real_t = undefined;
        sumOfSubSupDiagonalAll("", eig, null, size, size, DIAG, &diag_sum, true, realContext);
        runtime.int32ToReal(size, &matrixSize);
        realDivide(&diag_sum, &matrixSize, &avg_diag, realContext);
        realCopy(&avg_diag, &rel_threshold);
        rel_threshold.exponent -= finalBlockTolerance;

        // Solve each block of the quasi-triangular eig on its own: solveEigenBlock
        // writes the eigenvalues of a 2x2 or 3x3 block on the diagonal of a. A
        // subdiagonal element under the threshold ends a block and a 1x1 block
        // keeps the diagonal of a. A longer block, or one with an element below
        // it at the threshold or above, sends the whole matrix to the engine
        // unless an error is already set. eigenHessenbergQr returns a diagonal
        // eig, so its blocks are all 1x1; the diagonal shortcut above copies a
        // whole matrix whose off-diagonals are merely under the deep tolerance,
        // and it is that path this scan solves rather than checks.
        {
            var blockThreshold: real_t = undefined;
            var mag: real_t = undefined;
            var solveWhole = false;
            realCopy(&rel_threshold, &blockThreshold);

            var i: usize = 0;
            var j: usize = 0;
            while (i < sz) : (i = j + 1) {
                var coupled = false;
                j = i;
                while (j + 1 < sz) : (j += 1) { // j stops on the last row of the block that starts on row i
                    var offdiag_mag: real_t = undefined;
                    complexMagnitude(&eig[(j + 1) * sz + j], &offdiag_mag, realContext);
                    if (realIsZeroA(&offdiag_mag) or realCompareLessThan(&offdiag_mag, &blockThreshold)) break;
                }

                var row: usize = j + 1;
                while (row < sz and !coupled) : (row += 1) {
                    var col: usize = i;
                    while (col <= j and !coupled) : (col += 1) {
                        complexMagnitude(&eig[row * sz + col], &mag, realContext);
                        coupled = !realIsZeroA(&mag) and !realCompareLessThan(&mag, &blockThreshold);
                    }
                }
                if (!coupled and (j == i + 1 or j == i + 2)) {
                    solveEigenBlock(a, eig, size, @intCast(i), @intCast(j), is_real_symmetric, realContext);
                } else if ((coupled or j > i + 2) and runtime.lastErrorCode == runtime.ERROR_NONE) {
                    solveWhole = true;
                }
            }
            if (solveWhole) {
                // The diagonal shortcut took couplings no 2x2 or 3x3 block solver
                // takes: eig still holds the input, so solve the whole matrix.
                var k: usize = 0;
                while (k < sz * sz) : (k += 1) {
                    realCopy(&eig[k].Real, &a[k].Real);
                    realCopy(&eig[k].Imag, &a[k].Imag);
                }
                if (!eigenHessenbergQr(a, eig, scratch, scratch2, size, realContext)) {
                    qrDidNotConverge(size);
                }
            }
        }

        // Copy from a to eig before sorting (in case a was updated by block solvers)
        {
            var i: usize = 0;
            while (i < sz) : (i += 1) {
                realCopy(&a[i * sz + i].Real, &eig[i * sz + i].Real);
                realCopy(&a[i * sz + i].Imag, &eig[i * sz + i].Imag);
            }
        }

        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);

        // Give a conjugate pair one real part and the positive imaginary part
        // first. The two members are computed at different deflation steps, so
        // the sort above ranks them by magnitudes that agree only to within a
        // few ulp, and their real parts carry the residue of each. Identify the
        // pair by a real difference and an imaginary sum both under the
        // tolerance, then order it by sign.
        {
            var i: usize = 0;
            while (i + 1 < sz) : (i += 1) {
                const u = &eig[i * sz + i];
                const v = &eig[(i + 1) * sz + (i + 1)];
                var du: real_t = undefined;
                var dv: real_t = undefined;
                var t: real_t = undefined;
                var mean: real_t = undefined;

                if (realIsZeroA(&u.Imag) or realIsZeroA(&v.Imag) or realIsNegativeA(&u.Imag) == realIsNegativeA(&v.Imag)) {
                    continue;
                }
                realSubtract(&u.Real, &v.Real, &du, realContext);
                realAdd(&u.Imag, &v.Imag, &dv, realContext);
                realCopyAbs(&du, &du);
                realCopyAbs(&dv, &dv);
                // Scale by the pair's own magnitude: a pair on the imaginary axis
                // has a zero real part, and nothing is below a tolerance scaled by
                // that.
                complexMagnitude(u, &t, realContext);
                t.exponent -= tolerance_digits;
                if (realCompareLessThan(&du, &t) and realCompareLessThan(&dv, &t)) {
                    // A real matrix has a real characteristic polynomial, so the
                    // two members share a real part exactly; the mean is that
                    // value where they agree and drops the residue where they do
                    // not.
                    realAdd(&u.Real, &v.Real, &mean, realContext);
                    realMultiply(&mean, const_1on2(), &mean, realContext);
                    realCopy(&mean, &u.Real);
                    realCopy(&mean, &v.Real);
                    if (realIsNegativeA(&u.Imag)) {
                        var swap: cplx_t = undefined;
                        realCopy(&u.Real, &swap.Real);
                        realCopy(&u.Imag, &swap.Imag);
                        realCopy(&v.Real, &u.Real);
                        realCopy(&v.Imag, &u.Imag);
                        realCopy(&swap.Real, &v.Real);
                        realCopy(&swap.Imag, &v.Imag);
                    }
                }
            }
        }

        dropNoise(eig, size, 39);
    } // size > 3

    // The prologue increments for every size, so this pairs off exactly; keep
    // the wrapping form anyway, the counter is a plain C uint16_t.
    currentSolverNestingDepth -%= 1;
    if (currentSolverNestingDepth == 0) {
        runtime.clearSystemFlag(@intCast(FLAG_SOLVING));
    }
}

// ===========================================================================
// realEigenvalues / complexEigenvalues -- register-matrix wrappers: convert the
// real34 register matrix to a cplx_t bulk, run calculateEigenvalues, and write
// the diagonal eigenvalues back. eigenContext is &ctxtReal75.
// ===========================================================================
fn ramFull(comptime where: [*:0]const u8, comptime tag: [*:0]const u8) linksection(runtime.code_section) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(where, tag, null, null);
    }
}

fn realEigenvalues(matrix: *const real34Matrix_t, res: *real34Matrix_t, ires: ?*real34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 2 * 2 + sz * 7);
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    if (allocCplx(bulkSize)) |bulk| {
        const a = bulk;
        const eig = bulk + sz * sz;
        const scratch = bulk + sz * sz * 2;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i].Real);
            realSetZero(&a[i].Imag);
        }
        calculateEigenvalues(a, scratch, eig, size, true, true, &runtime.ctxtReal75);
        // Mutually conjugate complex roots are possible in real quadratic equations.
        var isComplex = false;
        i = 0;
        while (i < sz) : (i += 1) {
            if (!realIsZeroA(&eig[i * sz + i].Imag)) {
                isComplex = true;
                break;
            }
        }
        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.realMatrixInit(res, size, size)) {
            const resElems: [*]real34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz) : (i += 1) runtime.realToReal34(&eig[i * sz + i].Real, &resElems[i * sz + i]);
            if (isComplex and ires != null) {
                if (@intFromPtr(matrix) == @intFromPtr(ires.?) or @intFromPtr(res) == @intFromPtr(ires.?) or runtime.realMatrixInit(ires.?, size, size)) {
                    const iresElems: [*]real34_t = @ptrCast(ires.?.matrixElements);
                    i = 0;
                    while (i < sz) : (i += 1) runtime.realToReal34(&eig[i * sz + i].Imag, &iresElems[i * sz + i]);
                } else {
                    ramFull("In function realEigenvalues:", "Ram full, 1ax");
                }
            }
        } else {
            ramFull("In function realEigenvalues:", "Ram full, 2ay");
        }
        freeC47Blocks(bulk, bulkSize);
    } else {
        ramFull("In function realEigenvalues:", "Ram full, 3az");
    }
}

fn complexEigenvalues(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 2 * 2 + sz * 7);
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    if (allocCplx(bulkSize)) |bulk| {
        const a = bulk;
        const eig = bulk + sz * sz;
        const scratch = bulk + sz * sz * 2;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i].Real);
            runtime.real34ToReal(&elems[i].imag, &a[i].Imag);
        }
        calculateEigenvalues(a, scratch, eig, size, true, true, &runtime.ctxtReal75);
        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.complexMatrixInit(res, size, size)) {
            const resElems: [*]runtime.complex34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz) : (i += 1) {
                runtime.realToReal34(&eig[i * sz + i].Real, &resElems[i * sz + i].real);
                runtime.realToReal34(&eig[i * sz + i].Imag, &resElems[i * sz + i].imag);
            }
        } else {
            ramFull("In function complexEigenvalues:", "Ram full, 1ba");
        }
        freeC47Blocks(bulk, bulkSize);
    } else {
        ramFull("In function complexEigenvalues:", "Ram full, 2bb");
    }
}

// ===========================================================================
// fnEigenvalues (EIGVAL) -- the public command. Links X (real/complex matrix),
// runs the eigenvalue wrapper, writes the eigenvalue matrix to X plus a row
// vector of the eigenvalues lifted onto the stack. Pushed through the same
// stack-lift / adjustResult sequence as upstream.
// ===========================================================================
pub export fn fnEigenvalues(unusedParamButMandatory: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedParamButMandatory;
    // Empty body upstream under `#if !defined(OPTION_EIGEN)`: EIGVAL returns
    // without touching the stack and raises no error on the packages that drop
    // the option.
    if (comptime !runtime.option_eigen) return;
    var doneAdjusting = false;
    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
                runtime.moreInfoOnError("In function fnEigenvalues:", m, null, null);
            }
            return;
        }
        if (!runtime.saveLastX()) return;
        if (x.header.matrixRows == 1 and x.header.matrixColumns == 1) {
            fnRecallVElement(1);
        } else {
            runtime.setSystemFlag(FLAG_ASLIFT);
            runtime.liftStack();
            runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &x);
            var res: real34Matrix_t = undefined;
            var ires: real34Matrix_t = undefined;
            ires.header.matrixRows = 0;
            ires.header.matrixColumns = 0;
            ires.matrixElements = null;
            res.matrixElements = null;
            realEigenvalues(&x, &res, &ires);
            if (runtime.lastErrorCode == runtime.ERROR_NONE or runtime.lastErrorCode == ERROR_SOLVER_ABORT) {
                if (ires.matrixElements != null) {
                    var cres: complex34Matrix_t = undefined;
                    if (runtime.complexMatrixInit(&cres, res.header.matrixRows, res.header.matrixColumns)) {
                        const resElems: [*]real34_t = @ptrCast(res.matrixElements);
                        const iresElems: [*]real34_t = @ptrCast(ires.matrixElements);
                        const cresElems: [*]runtime.complex34_t = @ptrCast(cres.matrixElements);
                        const n: usize = @as(usize, x.header.matrixRows) * x.header.matrixColumns;
                        var i: usize = 0;
                        while (i < n) : (i += 1) {
                            cresElems[i].real = resElems[i];
                            cresElems[i].imag = iresElems[i];
                        }
                        runtime.convertComplex34MatrixToComplex34MatrixRegister(&cres, runtime.REGISTER_X);
                        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
                        doneAdjusting = true;
                        var cresRow: complex34Matrix_t = undefined;
                        extractDiagonalToRowComplex34Matrix(&cres, &cresRow);
                        if (cresRow.matrixElements != null) {
                            runtime.setSystemFlag(FLAG_ASLIFT);
                            runtime.liftStack();
                            runtime.convertComplex34MatrixToComplex34MatrixRegister(&cresRow, runtime.REGISTER_X);
                            runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
                            runtime.complexMatrixFree(&cresRow);
                        }
                        runtime.realMatrixFree(&ires);
                        runtime.complexMatrixFree(&cres);
                    } else {
                        ramFull("In function fnEigenvalues:", "Ram full");
                    }
                } else {
                    runtime.convertReal34MatrixToReal34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
                    doneAdjusting = true;
                    var resRow: real34Matrix_t = undefined;
                    extractDiagonalToRowReal34Matrix(&res, &resRow);
                    if (resRow.matrixElements != null) {
                        runtime.setSystemFlag(FLAG_ASLIFT);
                        runtime.liftStack();
                        runtime.convertReal34MatrixToReal34MatrixRegister(&resRow, runtime.REGISTER_X);
                        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
                        runtime.realMatrixFree(&resRow);
                    }
                }
                runtime.realMatrixFree(&res);
            }
            // Unhandled error code (e.g. complex eigenvalues with FL_CPXRES clear)
            // skips the block above; realEigenvalues already allocated res/ires.
            // On the handled paths these are already freed and NULL -> no-ops.
            if (res.matrixElements != null) {
                runtime.realMatrixFree(&res);
            }
            if (ires.matrixElements != null) {
                runtime.realMatrixFree(&ires);
            }
        }
        if (!doneAdjusting) runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
        return;
    } else if (dt == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
                runtime.moreInfoOnError("In function fnEigenvalues:", m, null, null);
            }
            return;
        }
        if (!runtime.saveLastX()) return;
        if (x.header.matrixRows == 1 and x.header.matrixColumns == 1) {
            fnRecallVElement(1);
        } else {
            runtime.setSystemFlag(FLAG_ASLIFT);
            runtime.liftStack();
            var res: complex34Matrix_t = undefined;
            res.matrixElements = null;
            complexEigenvalues(&x, &res);
            // After an error no result is written, as on the real path.
            if (res.matrixElements != null and runtime.lastErrorCode != runtime.ERROR_NONE and runtime.lastErrorCode != ERROR_SOLVER_ABORT) {
                runtime.complexMatrixFree(&res);
            }
            if (res.matrixElements != null) {
                runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
                runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
                doneAdjusting = true;
                var resRow: complex34Matrix_t = undefined;
                extractDiagonalToRowComplex34Matrix(&res, &resRow);
                if (resRow.matrixElements != null) {
                    runtime.setSystemFlag(FLAG_ASLIFT);
                    runtime.liftStack();
                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&resRow, runtime.REGISTER_X);
                    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
                    runtime.complexMatrixFree(&resRow);
                }
                runtime.complexMatrixFree(&res);
            }
        }
        if (!doneAdjusting) runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
        return;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buf: [48]u8 = undefined;
            const m = bufPrintZ(&buf, "DataType {d}", .{dt}) catch "DataType";
            runtime.moreInfoOnError("In function fnEigenvalues:", m, "is not a matrix.", "");
        }
        return;
    }
}

// Extract the diagonal of a square matrix into a 1xN row vector (the eigenvalue
// list pushed onto the stack by fnEigenvalues). real34Plus rounds at ctxtReal34.
fn extractDiagonalToRowReal34Matrix(source: *const real34Matrix_t, dest: *real34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = source.header.matrixRows;
    const sz: usize = size;
    if (runtime.realMatrixInit(dest, 1, size)) {
        const srcElems: [*]const real34_t = @ptrCast(source.matrixElements);
        const dstElems: [*]real34_t = @ptrCast(dest.matrixElements);
        var i: usize = 0;
        while (i < sz) : (i += 1) {
            real34Plus(&srcElems[i * sz + i], &dstElems[i]);
        }
    } else {
        ramFull("In function extractDiagonalToRowReal34Matrix:", "Ram full");
    }
}

fn extractDiagonalToRowComplex34Matrix(source: *const complex34Matrix_t, dest: *complex34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = source.header.matrixRows;
    const sz: usize = size;
    if (runtime.complexMatrixInit(dest, 1, size)) {
        const srcElems: [*]const runtime.complex34_t = @ptrCast(source.matrixElements);
        const dstElems: [*]runtime.complex34_t = @ptrCast(dest.matrixElements);
        var i: usize = 0;
        while (i < sz) : (i += 1) {
            real34Plus(&srcElems[i * sz + i].real, &dstElems[i].real);
            real34Plus(&srcElems[i * sz + i].imag, &dstElems[i].imag);
        }
    } else {
        ramFull("In function extractDiagonalToRowComplex34Matrix:", "Ram full");
    }
}

// ===========================================================================
// cpxLinearEqn (static) -- solve A x = b for complex dense A by inverting A in
// place (invCpxMat) and multiplying. Singular A -> ERROR_SINGULAR_MATRIX. A pivot
// below 10^toleranceExponent of the matrix's scale counts as zero.
// ===========================================================================
// Exported (was file-local) so the linear-equation solver owner can share it;
// cpxLinearEqn is static in matrix.c, so the Zig global does not clash.
pub export fn cpxLinearEqn(a: [*]const cplx_t, b: [*]const cplx_t, r: [*]cplx_t, size: u16, toleranceExponent: i32, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const blocks: usize = @as(usize, size) * size * realSizeInBlocks(75) * 2;
    if (allocCplx(blocks)) |inv_a| {
        _ = runtime.xcopy(@ptrCast(inv_a), @ptrCast(a), @intCast(blocks << 2)); // TO_BYTES, BPB=2
        if (math_matrix_complex_core.invCpxMat(inv_a, size, toleranceExponent, realContext)) {
            math_matrix_complex_core.mulCpxMat(inv_a, b, size, size, 1, r, realContext);
        } else if (runtime.lastErrorCode != runtime.ERROR_RAM_FULL) {
            runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function cpxLinearEqn:", "attempt to invert a singular matrix", null, null);
        }
        freeC47Blocks(inv_a, blocks);
    } else {
        ramFull("In function cpxLinearEqn:", "Ram full");
    }
}

// Hold (A - lambda I) v to eps3 times the largest entry of v. The augmented
// system fixes unknowns to break a singular solve, and a choice that fixes the
// wrong ones meets the augmented rows while leaving the original ones unmet, so
// the vector it returns solves a different problem. LAPACK zlaein sets INFO
// instead, when inverse iteration does not reach its growth test.
fn solvesTheEigenProblem(matrix: *const real34Matrix_t, isComplex: bool, v: [*]const cplx_t, lambda: *const cplx_t, size: u16, eps3: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    const rElems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    const cElems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
    var acc: cplx_t = undefined;
    var elem: cplx_t = undefined;
    var prod: cplx_t = undefined;
    var mag: real_t = undefined;
    var resid: real_t = undefined;
    var vmax: real_t = undefined;
    var bound: real_t = undefined;

    realSetZero(&resid);
    realSetZero(&vmax);
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        complexMagnitude(&v[i], &mag, realContext);
        if (realCompareGreaterThan(&mag, &vmax)) {
            realCopy(&mag, &vmax);
        }
    }
    if (realIsZeroA(&vmax)) {
        return false;
    }

    i = 0;
    while (i < sz) : (i += 1) {
        realSetZero(&acc.Real);
        realSetZero(&acc.Imag);
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            if (isComplex) {
                runtime.real34ToReal(&cElems[i * sz + j].real, &elem.Real);
                runtime.real34ToReal(&cElems[i * sz + j].imag, &elem.Imag);
            } else {
                runtime.real34ToReal(&rElems[i * sz + j], &elem.Real);
                realSetZero(&elem.Imag);
            }
            if (i == j) {
                realSubtract(&elem.Real, &lambda.Real, &elem.Real, realContext);
                realSubtract(&elem.Imag, &lambda.Imag, &elem.Imag, realContext);
            }
            mulComplexComplex(&elem, &v[j], &prod, realContext);
            realAdd(&acc.Real, &prod.Real, &acc.Real, realContext);
            realAdd(&acc.Imag, &prod.Imag, &acc.Imag, realContext);
        }
        complexMagnitude(&acc, &mag, realContext);
        if (realCompareGreaterThan(&mag, &resid)) {
            realCopy(&mag, &resid);
        }
    }
    realMultiply(eps3, &vmax, &bound, realContext);
    return realCompareLessThan(&resid, &bound) or realCompareEqual(&resid, &bound);
}

// Report whether v is in the span of the m orthonormal columns of basis. When it
// is not, its remainder, normalised, is written as column m of basis for the
// caller to keep. Eigenvectors of distinct eigenvalues are independent, so a
// vector in the span of the earlier columns, a multiple of one of them or a
// combination of several, leaves a rank deficient set. Projecting the columns
// out twice keeps them orthogonal to working precision (Giraud, Langou and
// Rozloznik, 2005), and the remainder is compared against v at
// 10^-(toleranceDigits/2): a defective multiple eigenvalue splits by about a
// root of the working precision, so the vectors of its copies agree to about
// half the digits.
fn isInSpanOfColumns(v: [*]const cplx_t, basis: [*]cplx_t, size: u16, m: u16, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    const w = basis + @as(usize, m) * sz;
    var t: real_t = undefined;
    var vNorm: real_t = undefined;
    var wNorm: real_t = undefined;
    var dot: cplx_t = undefined;
    var bConj: cplx_t = undefined;
    var prod: cplx_t = undefined;

    var i: usize = 0;
    while (i < sz) : (i += 1) {
        realCopy(&v[i].Real, &w[i].Real);
        realCopy(&v[i].Imag, &w[i].Imag);
    }
    var round: u16 = 0;
    while (round < 2) : (round += 1) {
        var j: usize = 0;
        while (j < m) : (j += 1) {
            const b = basis + j * sz;
            realSetZero(&dot.Real);
            realSetZero(&dot.Imag);
            i = 0;
            while (i < sz) : (i += 1) { // b^H w
                realCopy(&b[i].Real, &bConj.Real);
                realCopy(&b[i].Imag, &bConj.Imag);
                realChangeSign(&bConj.Imag);
                mulComplexComplex(&bConj, &w[i], &prod, realContext);
                realAdd(&dot.Real, &prod.Real, &dot.Real, realContext);
                realAdd(&dot.Imag, &prod.Imag, &dot.Imag, realContext);
            }
            i = 0;
            while (i < sz) : (i += 1) {
                mulComplexComplex(&dot, &b[i], &prod, realContext);
                realSubtract(&w[i].Real, &prod.Real, &w[i].Real, realContext);
                realSubtract(&w[i].Imag, &prod.Imag, &w[i].Imag, realContext);
            }
        }
    }

    realSetZero(&vNorm);
    realSetZero(&wNorm);
    i = 0;
    while (i < sz) : (i += 1) {
        realMultiply(&v[i].Real, &v[i].Real, &t, realContext);
        realAdd(&vNorm, &t, &vNorm, realContext);
        realMultiply(&w[i].Real, &w[i].Real, &t, realContext);
        realAdd(&wNorm, &t, &wNorm, realContext);
        realMultiply(&v[i].Imag, &v[i].Imag, &t, realContext);
        realAdd(&vNorm, &t, &vNorm, realContext);
        realMultiply(&w[i].Imag, &w[i].Imag, &t, realContext);
        realAdd(&wNorm, &t, &wNorm, realContext);
    }
    realSquareRoot(&vNorm, &vNorm, realContext);
    realSquareRoot(&wNorm, &wNorm, realContext);
    realCopy(&vNorm, &t);
    t.exponent -= @divTrunc(toleranceDigits(), 2);
    if (!realCompareGreaterThan(&wNorm, &t)) {
        return true;
    }
    i = 0;
    while (i < sz) : (i += 1) {
        divComplexReal(&w[i], &wNorm, &w[i], realContext);
    }
    return false;
}

// LAPACK zhsein compares CABS1(w(i) - wk), the sum of the absolute parts,
// against EPS3 rather than testing equality.
fn isRepeatedEigenvalue(u: *const cplx_t, v: *const cplx_t, eps3: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var re_part: real_t = undefined;
    var im_part: real_t = undefined;
    realSubtract(&u.Real, &v.Real, &re_part, realContext);
    realSubtract(&u.Imag, &v.Imag, &im_part, realContext);
    realCopyAbs(&re_part, &re_part);
    realCopyAbs(&im_part, &im_part);
    realAdd(&re_part, &im_part, &re_part, realContext);
    return realCompareLessThan(&re_part, eps3);
}

// Reduce A - lambda I in b by Gaussian elimination with partial pivoting, the
// columns taken from the last to the first, and return its nullity. A column
// whose pivot candidates are all below 10^-(toleranceDigits/2) of the norm of A
// has no pivot: its index goes to freeCol, in ascending order, and each row
// left without a pivot goes to zeroRow. The pivots taken from the right leave
// the leading columns free, so fixing the unknowns of freeCol to the d-th unit
// vector, with a slack on each row of zeroRow, gives the null vector whose free
// coordinates are the d-th unit vector: sympy nullspace of A - lambda I with
// its columns reversed, read back in the original order. The Schur complement
// of that augmented system is -I, so it is not singular. Golub and Wilkinson
// (1976) take the SVD for the rank: a pivot misjudged here gives a vector that
// fails solvesTheEigenProblem, or a copy with no vector, and both are reported
// as a defective matrix.
fn nullSpaceOfShiftedMatrix(matrix: *const real34Matrix_t, isComplex: bool, lambda: *const cplx_t, size: u16, eps3: *const real_t, b: [*]cplx_t, freeCol: [*]u16, zeroRow: [*]u16, realContext: *realContext_t) linksection(runtime.code_section) u16 {
    const sz: usize = size;
    const rElems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    const cElems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
    var rank: u16 = 0;
    var nullity: u16 = 0;
    var tol: real_t = undefined;
    var best: real_t = undefined;
    var mag: real_t = undefined;
    var fac: cplx_t = undefined;
    var prod: cplx_t = undefined;

    var i: usize = 0;
    while (i < sz) : (i += 1) {
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            if (isComplex) {
                runtime.real34ToReal(&cElems[i * sz + j].real, &b[i * sz + j].Real);
                runtime.real34ToReal(&cElems[i * sz + j].imag, &b[i * sz + j].Imag);
            } else {
                runtime.real34ToReal(&rElems[i * sz + j], &b[i * sz + j].Real);
                realSetZero(&b[i * sz + j].Imag);
            }
        }
        realSubtract(&b[i * sz + i].Real, &lambda.Real, &b[i * sz + i].Real, realContext);
        realSubtract(&b[i * sz + i].Imag, &lambda.Imag, &b[i * sz + i].Imag, realContext);
        zeroRow[i] = @intCast(i);
    }
    realCopy(eps3, &tol);
    tol.exponent += 33 - @divTrunc(toleranceDigits(), 2); // EPS3 is 1E-33 of the norm of A

    var c: usize = 0;
    while (c < sz) : (c += 1) {
        const col = sz - 1 - c;
        realSetZero(&best);
        var p: usize = rank;
        i = rank;
        while (i < sz) : (i += 1) {
            complexMagnitude(&b[i * sz + col], &mag, realContext);
            if (realCompareGreaterThan(&mag, &best)) {
                realCopy(&mag, &best);
                p = i;
            }
        }
        if (!realCompareGreaterThan(&best, &tol)) {
            freeCol[nullity] = @intCast(col);
            nullity += 1;
            continue;
        }
        const rk: usize = rank;
        if (p != rk) {
            var j: usize = 0;
            while (j <= col) : (j += 1) {
                realCopy(&b[p * sz + j].Real, &mag);
                realCopy(&b[rk * sz + j].Real, &b[p * sz + j].Real);
                realCopy(&mag, &b[rk * sz + j].Real);
                realCopy(&b[p * sz + j].Imag, &mag);
                realCopy(&b[rk * sz + j].Imag, &b[p * sz + j].Imag);
                realCopy(&mag, &b[rk * sz + j].Imag);
            }
            const swapRow = zeroRow[p];
            zeroRow[p] = zeroRow[rk];
            zeroRow[rk] = swapRow;
        }
        i = rk + 1;
        while (i < sz) : (i += 1) {
            divComplexComplex(&b[i * sz + col], &b[rk * sz + col], &fac, realContext);
            var j: usize = 0;
            while (j <= col) : (j += 1) {
                mulComplexComplex(&fac, &b[rk * sz + j], &prod, realContext);
                realSubtract(&b[i * sz + j].Real, &prod.Real, &b[i * sz + j].Real, realContext);
                realSubtract(&b[i * sz + j].Imag, &prod.Imag, &b[i * sz + j].Imag, realContext);
            }
        }
        rank += 1;
    }

    i = 0;
    while (i < nullity) : (i += 1) {
        zeroRow[i] = zeroRow[@as(usize, rank) + i];
    }
    i = 0;
    while (i < nullity / 2) : (i += 1) {
        const swapCol = freeCol[i];
        freeCol[i] = freeCol[nullity - 1 - i];
        freeCol[nullity - 1 - i] = swapCol;
    }
    return nullity;
}

// ===========================================================================
// calculateEigenvectors (static) -- given the eigenvalues on the diagonal of
// eig, solve (A - lambda I) v = 0 per eigenvalue via the augmented-system
// technique, storing the eigenvectors column-wise into r. Diagonal A takes the
// permuted-unit-vector fast path. matrix_any aliases real34Matrix_t /
// complex34Matrix_t (shared header); the C copy stays file-local so the Zig
// signature is chosen for convenience.
// ===========================================================================
fn calculateEigenvectors(matrix: *const real34Matrix_t, isComplex: bool, a: [*]cplx_t, q: [*]cplx_t, r: [*]cplx_t, eig: [*]cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    // Call after the eigenvalues are calculated. real34Matrix_t and
    // complex34Matrix_t share the {header, matrixElements} layout; the complex
    // element view reinterprets the same element pointer.
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;

    const rElems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    const cElems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);

    var i: usize = 0;
    while (i < sz * sz) : (i += 1) {
        realSetZero(&r[i].Real);
        realSetZero(&r[i].Imag);
    }
    // The digits past the 34th are residue of the iteration. Rounding them away
    // makes an exact eigenvalue exact, so dependent rows of A - lambda I cancel
    // in the solve.
    dropNoise(eig, size, 34);

    // Fast path: a diagonal matrix has unit eigenvectors permuted to match the
    // eigenvalue ordering. The augmented-system technique below fails on a
    // diagonal A because A - lambda I then has a zero row for any eigenvalue,
    // which makes the augmented matrix singular.
    var isDiagonal = true;
    {
        var ii: usize = 0;
        outer: while (ii < sz) : (ii += 1) {
            var jj: usize = 0;
            while (jj < sz) : (jj += 1) {
                if (ii != jj) {
                    if (isComplex) {
                        if (!runtime.real34IsZero(&cElems[ii * sz + jj].real) or !runtime.real34IsZero(&cElems[ii * sz + jj].imag)) {
                            isDiagonal = false;
                            break :outer;
                        }
                    } else {
                        if (!runtime.real34IsZero(&rElems[ii * sz + jj])) {
                            isDiagonal = false;
                            break :outer;
                        }
                    }
                }
            }
        }
    }
    var k: usize = 0;
    if (isDiagonal) {
        // For each eigenvalue eig[k], the first unclaimed diagonal position j
        // where A[j][j] == eig[k] gets r[j][k] = 1, so repeated eigenvalues land
        // in distinct columns; r itself records the claims.
        while (k < sz) : (k += 1) {
            var j: usize = 0;
            while (j < sz) : (j += 1) {
                var alreadyUsed = false;
                var kPrev: usize = 0;
                while (kPrev < k) : (kPrev += 1) {
                    if (!realIsZeroA(&r[j * sz + kPrev].Real)) {
                        alreadyUsed = true;
                        break;
                    }
                }
                if (alreadyUsed) continue;
                // |eig[k] - A[j][j]| <= max(|eig|, |A[j][j]|, 1) * 1e-30: an exact
                // test fails on the residue QR leaves on an exact eigenvalue.
                var diag: cplx_t = undefined;
                if (isComplex) {
                    runtime.real34ToReal(&cElems[j * sz + j].real, &diag.Real);
                    runtime.real34ToReal(&cElems[j * sz + j].imag, &diag.Imag);
                } else {
                    runtime.real34ToReal(&rElems[j * sz + j], &diag.Real);
                    realSetZero(&diag.Imag);
                }
                var diff_r: real_t = undefined;
                var diff_i: real_t = undefined;
                var mag_eig: real_t = undefined;
                var mag_diag: real_t = undefined;
                var scale: real_t = undefined;
                var tol: real_t = undefined;
                realSubtract(&eig[k * sz + k].Real, &diag.Real, &diff_r, realContext);
                realSubtract(&eig[k * sz + k].Imag, &diag.Imag, &diff_i, realContext);
                complexMagnitude(&eig[k * sz + k], &mag_eig, realContext);
                complexMagnitude(&diag, &mag_diag, realContext);
                realCopy(&mag_eig, &scale);
                if (realCompareLessThan(&scale, &mag_diag)) realCopy(&mag_diag, &scale);
                if (realCompareLessThan(&scale, const_1())) realCopy(const_1(), &scale);
                realMultiply(&scale, const_1e_30(), &tol, realContext);
                if (isElementWithinTolerance(&diff_r, &diff_i, &tol, realContext)) {
                    realCopy(const_1(), &r[j * sz + k].Real);
                    break;
                }
            }
        }
        return;
    }

    // An eigenvalue within EPS3 = ULP * norm(A) of an earlier one is the same
    // eigenvalue, as in LAPACK zhsein, which perturbs such a root by EPS3 before
    // inverse iteration and compares every earlier eigenvalue rather than the
    // previous one alone. The eigenvalues are rounded to 34 digits above, so ULP
    // is 1E-33. A defective multiple eigenvalue leaves the QR iteration split by
    // about the square root of the working precision, 1E-38 at 75 digits:
    // equality misses the repeat, and each copy then solves a system of its own
    // and returns the same eigenvector again.
    var eps3: real_t = undefined;
    var rowSum: real_t = undefined;
    var mag: cplx_t = undefined;
    realSetZero(&eps3);
    i = 0;
    while (i < sz) : (i += 1) {
        realSetZero(&rowSum);
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            if (isComplex) {
                runtime.real34ToReal(&cElems[i * sz + j].real, &mag.Real);
                runtime.real34ToReal(&cElems[i * sz + j].imag, &mag.Imag);
                var magnitude: real_t = undefined;
                complexMagnitude(&mag, &magnitude, realContext);
                realCopy(&magnitude, &mag.Real);
            } else {
                runtime.real34ToReal(&rElems[i * sz + j], &mag.Real);
                realCopyAbs(&mag.Real, &mag.Real);
            }
            realAdd(&rowSum, &mag.Real, &rowSum, realContext);
        }
        if (realCompareGreaterThan(&rowSum, &eps3)) {
            realCopy(&rowSum, &eps3);
        }
    }
    if (realIsZeroA(&eps3)) {
        realSetOne(&eps3); // zhsein takes SMLNUM when the norm is zero
    }
    eps3.exponent -= 33;

    var freeUnknowns: u16 = 1;
    var duplicateEigenvalueCount: u16 = 0;
    var rep: u16 = 0;
    var systemBuiltFor: u16 = 0;
    var rebuildSystem = true;
    var acceptedVector = false;
    var repeated = false;
    var pairedSlack = false;
    var basisSize: u16 = 0;
    const utBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
    if (allocC47Blocks(utBlocks)) |utBuf| {
        const unknownsToFill: [*]u16 = @ptrCast(@alignCast(utBuf));
        const slackRow = unknownsToFill + sz;
        const basis = q + sz * sz * 2; // the right-hand side and the elimination use the first half of q
        k = 0;
        while (k < sz and runtime.lastErrorCode != runtime.ERROR_RAM_FULL) : (k += 1) { // a full RAM stops the remaining columns
            rep = @intCast(k);
            duplicateEigenvalueCount = 0;
            repeated = false;
            var jr: usize = 0;
            while (jr < sz) : (jr += 1) {
                if (jr != k and isRepeatedEigenvalue(&eig[jr * sz + jr], &eig[k * sz + k], &eps3, realContext)) {
                    repeated = true;
                    if (jr < k) {
                        if (duplicateEigenvalueCount == 0) {
                            rep = @intCast(jr); // the first copy of this eigenvalue: its system is the one to solve again
                        }
                        duplicateEigenvalueCount += 1;
                    }
                }
            }
            rebuildSystem = (duplicateEigenvalueCount == 0) or (rep != systemBuiltFor);
            if (rebuildSystem) {
                systemBuiltFor = rep;
                pairedSlack = false;
                if (repeated) { // copy d of a repeated eigenvalue takes the d-th null vector
                    freeUnknowns = nullSpaceOfShiftedMatrix(matrix, isComplex, &eig[@as(usize, rep) * sz + rep], size, &eps3, q, unknownsToFill, slackRow, realContext);
                } else {
                    freeUnknowns = 1;
                    unknownsToFill[0] = 0;
                }
            }
            acceptedVector = false;
            const vBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
            if (allocCplx(vBlocks)) |v| {
                while (duplicateEigenvalueCount < freeUnknowns) { // a copy beyond the nullity has no eigenvector of its own
                    var j: usize = 0;
                    while (j < sz * 2) : (j += 1) {
                        realSetNaN(&v[j].Real);
                        realSetNaN(&v[j].Imag);
                    }
                    if (!repeated) {
                        slackRow[0] = if (pairedSlack) unknownsToFill[0] else 0;
                    }

                    const stride: usize = sz + freeUnknowns;
                    if (rebuildSystem) {
                        // Restore the original matrix
                        var ii: usize = 0;
                        while (ii < sz) : (ii += 1) {
                            var jj: usize = 0;
                            while (jj < sz) : (jj += 1) {
                                if (isComplex) {
                                    runtime.real34ToReal(&cElems[ii * sz + jj].real, &a[ii * stride + jj].Real);
                                    runtime.real34ToReal(&cElems[ii * sz + jj].imag, &a[ii * stride + jj].Imag);
                                } else {
                                    runtime.real34ToReal(&rElems[ii * sz + jj], &a[ii * stride + jj].Real);
                                    realSetZero(&a[ii * stride + jj].Imag);
                                }
                            }
                            jj = 0;
                            while (jj < freeUnknowns) : (jj += 1) {
                                realCopy(if (slackRow[jj] == ii) const_1() else const_0(), &a[ii * stride + jj + sz].Real);
                                realSetZero(&a[ii * stride + jj + sz].Imag);
                            }
                        }
                        ii = 0;
                        while (ii < freeUnknowns) : (ii += 1) {
                            var jj: usize = 0;
                            while (jj < sz) : (jj += 1) {
                                realCopy(if (jj == unknownsToFill[ii]) const_1() else const_0(), &a[(ii + sz) * stride + jj].Real);
                                realSetZero(&a[(ii + sz) * stride + jj].Imag);
                            }
                            jj = 0;
                            while (jj < freeUnknowns) : (jj += 1) {
                                realCopy(if (jj == ii) const_1() else const_0(), &a[(ii + sz) * stride + jj + sz].Real);
                                realSetZero(&a[(ii + sz) * stride + jj + sz].Imag);
                            }
                        }
                        // Subtract an eigenvalue
                        const rp: usize = rep;
                        var jd: usize = 0;
                        while (jd < sz) : (jd += 1) {
                            realSubtract(&a[jd * stride + jd].Real, &eig[rp * sz + rp].Real, &a[jd * stride + jd].Real, realContext);
                            realSubtract(&a[jd * stride + jd].Imag, &eig[rp * sz + rp].Imag, &a[jd * stride + jd].Imag, realContext);
                        }
                    }
                    if (duplicateEigenvalueCount != 0) {
                        rebuildSystem = false; // a further copy solves the system the first copy built, for the next null-space vector
                    }

                    // Make the equation matrices
                    var jq: usize = 0;
                    while (jq < stride) : (jq += 1) {
                        realCopy(if (jq == @as(usize, duplicateEigenvalueCount) + sz) const_1() else const_0(), &q[jq].Real);
                        realSetZero(&q[jq].Imag);
                    }

                    // Solve linear equations from the submatrix
                    runtime.lastErrorCode = runtime.ERROR_NONE;
                    cpxLinearEqn(a, q, v, @intCast(stride), 2 - 34, realContext); // a 34-digit eigenvalue is off by up to half a unit in its 34th digit
                    if (runtime.lastErrorCode != runtime.ERROR_SINGULAR_MATRIX) {
                        var usable = solvesTheEigenProblem(matrix, isComplex, v, &eig[k * sz + k], size, &eps3, realContext);
                        if (usable) {
                            usable = !isInSpanOfColumns(v, basis, size, basisSize, realContext);
                        }
                        if (usable) {
                            basisSize += 1; // isInSpanOfColumns wrote the remainder of v as this column of basis
                            acceptedVector = true;
                            break;
                        }
                    }

                    // Build the matrix again on every retry: unknownsToFill moves
                    // the fixed unknowns, pairedSlack moves the slack and
                    // freeUnknowns is the row stride, so a retry that keeps the old
                    // matrix reads elements never written at the new stride.
                    rebuildSystem = true;
                    if (repeated) {
                        break; // the null space gives the only choice of unknowns and slacks
                    }

                    // Next choice for a simple eigenvalue: the fixed unknown moves
                    // down the rows with its slack on the first row, then again with
                    // the slack on its own row. One of the latter is not singular:
                    // adj(A - lambda I) is c x y^T with y^T x not 0, so some row u
                    // has x_u y_u not 0. Two fixed unknowns would only reach the same
                    // null vector again.
                    unknownsToFill[0] += 1;
                    if (unknownsToFill[0] == size) {
                        if (pairedSlack) {
                            break;
                        }
                        pairedSlack = true;
                        unknownsToFill[0] = 0;
                    }
                }
                if (!acceptedVector) {
                    // Zero-fill on failure. The caller (realEigenvectors /
                    // complexEigenvectors) detects zero columns and reports the
                    // defective-matrix error to the user.
                    var ii: usize = 0;
                    while (ii < sz) : (ii += 1) {
                        realSetZero(&v[ii].Real);
                        realSetZero(&v[ii].Imag);
                    }
                    if (runtime.lastErrorCode == runtime.ERROR_SINGULAR_MATRIX) {
                        // Clear only the singular solve the retries expect; any
                        // other error reaches the caller, which reports it
                        runtime.lastErrorCode = runtime.ERROR_NONE;
                    }
                }
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    realCopy(&v[ii].Real, &r[ii * sz + k].Real);
                    realCopy(&v[ii].Imag, &r[ii * sz + k].Imag);
                }
                freeC47Blocks(v, vBlocks);
            } else {
                ramFull("In function calculateEigenvectors:", "Ram full, 1av");
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    realSetNaN(&r[ii * sz + k].Real);
                    realSetNaN(&r[ii * sz + k].Imag);
                }
            }
        }
        freeC47Blocks(utBuf, utBlocks);
    } else {
        ramFull("In function calculateEigenvectors:", "Ram full, 2aw");
        var ii: usize = 0;
        while (ii < sz) : (ii += 1) {
            realSetNaN(&r[ii * sz + k].Real);
            realSetNaN(&r[ii * sz + k].Imag);
        }
    }
}

// ===========================================================================
// realEigenvectors (static) -- eigenvectors of a real square matrix: compute
// eigenvalues, solve for each eigenvector, detect defective (zero) columns,
// normalize each column, and write real (res) + imaginary (ires) parts back.
// ===========================================================================
// Scale every real or complex column to Euclidean unit norm.
fn normaliseEigenvectorColumns(vectors: [*]cplx_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) void {
    const sz: usize = size;
    var column: usize = 0;
    while (column < sz) : (column += 1) {
        var sum: real_t = undefined;
        realSetZero(&sum);
        var row: usize = 0;
        while (row < sz) : (row += 1) {
            var term: real_t = undefined;
            realFMA(&vectors[row * sz + column].Real, &vectors[row * sz + column].Real, &sum, &term, realContext);
            realCopy(&term, &sum);
            realFMA(&vectors[row * sz + column].Imag, &vectors[row * sz + column].Imag, &sum, &term, realContext);
            realCopy(&term, &sum);
        }
        realSquareRoot(&sum, &sum, realContext);
        if (!realIsZeroA(&sum) and !realIsSpecial(&sum)) {
            row = 0;
            while (row < sz) : (row += 1) {
                realDivide(&vectors[row * sz + column].Real, &sum, &vectors[row * sz + column].Real, realContext);
                realDivide(&vectors[row * sz + column].Imag, &sum, &vectors[row * sz + column].Imag, realContext);
            }
        }
    }
}

// A column calculateEigenvectors zero-filled: it found no linearly independent
// eigenvector there. A genuine eigenvector is never zero.
fn hasZeroColumn(r: [*]const cplx_t, size: u16) linksection(runtime.code_section) bool {
    const sz: usize = size;
    var j: usize = 0;
    while (j < sz) : (j += 1) {
        var allZero = true;
        var i: usize = 0;
        while (i < sz) : (i += 1) {
            if (!realIsZeroA(&r[i * sz + j].Real) or !realIsZeroA(&r[i * sz + j].Imag)) {
                allZero = false;
                break;
            }
        }
        if (allZero) return true;
    }
    return false;
}

fn realEigenvectors(matrix: *const real34Matrix_t, res: *real34Matrix_t, ires: ?*real34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 4 * 2 * 4 + sz * 7);
    if (allocCplx(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4;
        const r = bulk + sz * sz * 4 * 2;
        const eig = bulk + sz * sz * 4 * 3;
        const scratch = bulk + sz * sz * 4 * 4;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i].Real);
            realSetZero(&a[i].Imag);
        }
        calculateEigenvalues(a, scratch, eig, size, true, false, &runtime.ctxtReal75);
        if (runtime.lastErrorCode == ERROR_NO_ROOT_FOUND) { // the eigenvalues did not converge, so no eigenvectors are returned
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }
        calculateEigenvectors(matrix, false, a, q, r, eig, &runtime.ctxtReal75);
        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) { // RAM is full, so no eigenvectors are returned
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }
        // No linearly independent eigenvector for a column: fnEigenvectors raises
        // ERROR_SINGULAR_MATRIX, fnMatrixSquareRoot's eigen path falls back.
        if (hasZeroColumn(r, size)) {
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }

        // Mutually conjugate complex roots are possible in real quadratic equations.
        var isComplex = false;
        i = 0;
        while (i < sz * sz) : (i += 1) {
            if (!realIsZeroA(&r[i].Imag)) {
                isComplex = true;
                break;
            }
        }

        normaliseEigenvectorColumns(r, size, &runtime.ctxtReal75);

        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.realMatrixInit(res, size, size)) {
            const resElems: [*]real34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz * sz) : (i += 1) runtime.realToReal34(&r[i].Real, &resElems[i]);
            if (isComplex and ires != null) {
                if (@intFromPtr(matrix) == @intFromPtr(ires.?) or @intFromPtr(res) == @intFromPtr(ires.?) or runtime.realMatrixInit(ires.?, size, size)) {
                    const iresElems: [*]real34_t = @ptrCast(ires.?.matrixElements);
                    i = 0;
                    while (i < sz * sz) : (i += 1) runtime.realToReal34(&r[i].Imag, &iresElems[i]);
                } else {
                    ramFull("In function realEigenvectors:", "Ram full, 1bc");
                    if (@intFromPtr(matrix) != @intFromPtr(res)) {
                        runtime.realMatrixFree(res);
                    }
                }
            }
        } else {
            ramFull("In function realEigenvectors:", "Ram full, 2be");
        }
        freeC47Blocks(bulk, bulkSize);
    } else {
        ramFull("In function realEigenvectors:", "Ram full, 3bf");
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

// ===========================================================================
// complexEigenvectors (static) -- eigenvectors of a complex square matrix.
// ===========================================================================
fn complexEigenvectors(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 4 * 2 * 4 + sz * 7);
    if (allocCplx(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4;
        const r = bulk + sz * sz * 4 * 2;
        const eig = bulk + sz * sz * 4 * 3;
        const scratch = bulk + sz * sz * 4 * 4;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i].Real);
            runtime.real34ToReal(&elems[i].imag, &a[i].Imag);
        }
        calculateEigenvalues(a, scratch, eig, size, true, false, &runtime.ctxtReal75);
        if (runtime.lastErrorCode == ERROR_NO_ROOT_FOUND) { // the eigenvalues did not converge, so no eigenvectors are returned
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }
        calculateEigenvectors(@ptrCast(matrix), true, a, q, r, eig, &runtime.ctxtReal75);
        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) { // RAM is full, so no eigenvectors are returned
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }
        if (hasZeroColumn(r, size)) {
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
            freeC47Blocks(bulk, bulkSize);
            return;
        }

        normaliseEigenvectorColumns(r, size, &runtime.ctxtReal75);

        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.complexMatrixInit(res, size, size)) {
            const resElems: [*]runtime.complex34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz * sz) : (i += 1) {
                runtime.realToReal34(&r[i].Real, &resElems[i].real);
                runtime.realToReal34(&r[i].Imag, &resElems[i].imag);
            }
        } else {
            ramFull("In function complexEigenvectors:", "Ram full, 1");
        }
        freeC47Blocks(bulk, bulkSize);
    } else {
        ramFull("In function complexEigenvectors:", "Ram full, 2bg");
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

// createEigenVectorIf1x1 (static) -- 1x1 matrices have the trivial eigenvector
// [1]; build it directly. Returns 1 (handled), 255 (alloc failed), 0 (not 1x1).
fn createEigenVectorIf1x1(rows: u16, cols: u16, isComplex: bool) linksection(runtime.code_section) u8 {
    if (rows == 1 and cols == 1) {
        runtime.setSystemFlag(FLAG_ASLIFT);
        runtime.liftStack();
        if (!runtime.initMatrixRegister(runtime.REGISTER_X, 1, 1, isComplex)) {
            runtime.fnDrop(runtime.NOPARAM);
            runtime.displayCalcErrorMessage(runtime.ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function createEigenVectorIf1x1:", "Not enough memory for a 1\x80\xd71 matrix", null, null);
            return 255;
        }
        if (isComplex) {
            // consume incoming X = [n+mi]
            runtime.fnDrop(runtime.NOPARAM);
            var cmatrix: complex34Matrix_t = undefined;
            runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &cmatrix);
            const ce: [*]runtime.complex34_t = @ptrCast(cmatrix.matrixElements);
            runtime.realToReal34(@alignCast(const_1()), &ce[0].real);
            runtime.real34SetZero(&ce[0].imag);
        } else {
            // consume incoming X = [n]
            runtime.fnDrop(runtime.NOPARAM);
            var rmatrix: real34Matrix_t = undefined;
            runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &rmatrix);
            const re: [*]real34_t = @ptrCast(rmatrix.matrixElements);
            runtime.realToReal34(@alignCast(const_1()), &re[0]);
        }
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return 1;
    }
    return 0;
}

// ===========================================================================
// fnEigenvectors (EIGVEC) -- the public command. Eigenvectors of X as columns;
// complex results lift onto the stack. Defective matrices raise SINGULAR.
// ===========================================================================
pub export fn fnEigenvectors(unusedParamButMandatory: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedParamButMandatory;
    // Empty body upstream under `#if !defined(OPTION_EIGEN)`: EIGVEC returns
    // without touching the stack and raises no error on the packages that drop
    // the option.
    if (comptime !runtime.option_eigen) return;
    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
                runtime.moreInfoOnError("In function fnEigenvectors:", m, null, null);
            }
            return;
        }
        if (!runtime.saveLastX()) return;
        switch (createEigenVectorIf1x1(x.header.matrixRows, x.header.matrixColumns, false)) {
            1 => {},
            255 => return,
            else => {
                var res: real34Matrix_t = undefined;
                var ires: real34Matrix_t = undefined;
                ires.header.matrixRows = 0;
                ires.header.matrixColumns = 0;
                ires.matrixElements = null;
                // realEigenvectors leaves res untouched when its bulk
                // allocation fails, so the NULL that reports "no result" has to
                // be in place before the call.
                res.matrixElements = null;
                realEigenvectors(&x, &res, &ires);
                if (res.matrixElements != null) {
                    // Success: lift the stack removed upstream; install the result.
                    if (ires.matrixElements != null) {
                        var cres: complex34Matrix_t = undefined;
                        if (runtime.complexMatrixInit(&cres, res.header.matrixRows, res.header.matrixColumns)) {
                            const resElems: [*]real34_t = @ptrCast(res.matrixElements);
                            const iresElems: [*]real34_t = @ptrCast(ires.matrixElements);
                            const cresElems: [*]runtime.complex34_t = @ptrCast(cres.matrixElements);
                            const n: usize = @as(usize, x.header.matrixRows) * x.header.matrixColumns;
                            var i: usize = 0;
                            while (i < n) : (i += 1) {
                                cresElems[i].real = resElems[i];
                                cresElems[i].imag = iresElems[i];
                            }
                            runtime.convertComplex34MatrixToComplex34MatrixRegister(&cres, runtime.REGISTER_X);
                            runtime.realMatrixFree(&ires);
                            runtime.complexMatrixFree(&cres);
                        } else {
                            runtime.realMatrixFree(&ires);
                            ramFull("In function fnEigenvectors:", "Ram full");
                        }
                    } else {
                        runtime.convertReal34MatrixToReal34MatrixRegister(&res, runtime.REGISTER_X);
                    }
                    runtime.realMatrixFree(&res);
                } else {
                    // The error is already displayed.
                    if (runtime.lastErrorCode == ERROR_NO_ROOT_FOUND or runtime.lastErrorCode == runtime.ERROR_RAM_FULL) return;
                    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnEigenvectors:", "matrix is defective: no full set of linearly independent eigenvectors", null, null);
                    return;
                }
            },
        }
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    } else if (dt == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
                runtime.moreInfoOnError("In function fnEigenvectors:", m, null, null);
            }
            return;
        }
        if (!runtime.saveLastX()) return;
        switch (createEigenVectorIf1x1(x.header.matrixRows, x.header.matrixColumns, true)) {
            1 => {},
            255 => return,
            else => {
                var res: complex34Matrix_t = undefined;
                // complexEigenvectors leaves res untouched when its bulk
                // allocation fails, so the NULL that reports "no result" has to
                // be in place before the call.
                res.matrixElements = null;
                complexEigenvectors(&x, &res);
                if (res.matrixElements != null) {
                    // Success: lift the stack removed upstream; install the result.
                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.complexMatrixFree(&res);
                } else {
                    // The error is already displayed.
                    if (runtime.lastErrorCode == ERROR_NO_ROOT_FOUND or runtime.lastErrorCode == runtime.ERROR_RAM_FULL) return;
                    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnEigenvectors:", "matrix is defective: no full set of linearly independent eigenvectors", null, null);
                    return;
                }
            },
        }
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buf: [48]u8 = undefined;
            const m = bufPrintZ(&buf, "DataType {d}", .{dt}) catch "DataType";
            runtime.moreInfoOnError("In function fnEigenvectors:", m, "is not a matrix.", "");
        }
        return;
    }
}

// ===========================================================================
// Matrix square root (M.SQRT). MATRIX_SQRT_USE_EIGEN==1 default: A = Q L Q^-1,
// sqrt(A) = Q sqrt(L) Q^-1. All helpers are static in matrix.c; only
// fnMatrixSquareRoot is exported as the public command.
// ===========================================================================

fn isRealMatrixDiagonal(matrix: *const real34Matrix_t) linksection(runtime.code_section) bool {
    const rows = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    var i: usize = 0;
    while (i < rows) : (i += 1) {
        var j: usize = 0;
        while (j < cols) : (j += 1) {
            if (i != j and !runtime.real34IsZero(&elems[i * cols + j])) return false;
        }
    }
    return true;
}

fn isComplexMatrixDiagonal(matrix: *const complex34Matrix_t) linksection(runtime.code_section) bool {
    const rows = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
    var i: usize = 0;
    while (i < rows) : (i += 1) {
        var j: usize = 0;
        while (j < cols) : (j += 1) {
            if (i != j and (!runtime.real34IsZero(&elems[i * cols + j].real) or !runtime.real34IsZero(&elems[i * cols + j].imag))) return false;
        }
    }
    return true;
}

// verifySqrtMatrix -- confirm Y^2 == matrix below ||matrix||_F * 1e-30, run in
// complex for both paths (catches spurious roots like [[0,0],[1,0]]).
fn verifySqrtMatrix(inputReal: ?*const real34Matrix_t, resultReal: ?*const real34Matrix_t, inputComplex: ?*const complex34Matrix_t, resultComplex: ?*const complex34Matrix_t) linksection(runtime.code_section) bool {
    const isComplex = inputComplex != null;
    const rows: u16 = if (isComplex) inputComplex.?.header.matrixRows else inputReal.?.header.matrixRows;
    const cols: u16 = if (isComplex) inputComplex.?.header.matrixColumns else inputReal.?.header.matrixColumns;
    const total: usize = @as(usize, rows) * cols;
    var verified = false;

    var inputCopy = std.mem.zeroes(complex34Matrix_t);
    var resultCopy = std.mem.zeroes(complex34Matrix_t);
    var residual = std.mem.zeroes(complex34Matrix_t);

    if (runtime.complexMatrixInit(&inputCopy, rows, cols) and runtime.complexMatrixInit(&resultCopy, rows, cols)) {
        const inC: [*]runtime.complex34_t = @ptrCast(inputCopy.matrixElements);
        const reC: [*]runtime.complex34_t = @ptrCast(resultCopy.matrixElements);
        var i: usize = 0;
        while (i < total) : (i += 1) {
            if (isComplex) {
                const ie: [*]const runtime.complex34_t = @ptrCast(inputComplex.?.matrixElements);
                const re: [*]const runtime.complex34_t = @ptrCast(resultComplex.?.matrixElements);
                inC[i].real = ie[i].real;
                inC[i].imag = ie[i].imag;
                reC[i].real = re[i].real;
                reC[i].imag = re[i].imag;
            } else {
                const ie: [*]const real34_t = @ptrCast(inputReal.?.matrixElements);
                const re: [*]const real34_t = @ptrCast(resultReal.?.matrixElements);
                inC[i].real = ie[i];
                reC[i].real = re[i];
                runtime.real34SetZero(&inC[i].imag);
                runtime.real34SetZero(&reC[i].imag);
            }
        }

        math_matrix_product.multiplyComplexMatrices(&resultCopy, &resultCopy, &residual);
        if (residual.matrixElements != null) {
            runtime.subtractComplexMatrices(&residual, &inputCopy, &residual);
            var residualNorm34: real34_t = undefined;
            var inputNorm34: real34_t = undefined;
            runtime.euclideanNormComplexMatrix(&residual, 2, &residualNorm34);
            runtime.euclideanNormComplexMatrix(&inputCopy, 2, &inputNorm34);
            var residualNorm: real_t = undefined;
            var inputNorm: real_t = undefined;
            var tolerance: real_t = undefined;
            runtime.real34ToReal(&residualNorm34, &residualNorm);
            runtime.real34ToReal(&inputNorm34, &inputNorm);
            realMultiply(&inputNorm, const_1e_30(), &tolerance, &runtime.ctxtReal39);
            verified = math_comparison_reals.realCompareLessEqual(&residualNorm, &tolerance);
            runtime.complexMatrixFree(&residual);
        }
    }
    if (inputCopy.matrixElements != null) runtime.complexMatrixFree(&inputCopy);
    if (resultCopy.matrixElements != null) runtime.complexMatrixFree(&resultCopy);
    return verified;
}

// The principal square root of a symmetric positive-semidefinite 2 by 2 real
// matrix: for A with determinant d it is (A + sqrt(d) I) / sqrt(trace(A) +
// 2 sqrt(d)). True when the direct formula applies and storage succeeds.
fn sqrtSymmetricRealMatrix2x2(matrix: *const real34Matrix_t, res: *real34Matrix_t) linksection(runtime.code_section) bool {
    const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    var a: real_t = undefined;
    var b: real_t = undefined;
    var d: real_t = undefined;
    var determinant: real_t = undefined;
    var negativeB: real_t = undefined;
    var rootDeterminant: real_t = undefined;
    var denominator: real_t = undefined;
    var value: real_t = undefined;

    if (!real34CompareEqual(&elems[1], &elems[2])) {
        return false;
    }

    runtime.real34ToReal(&elems[0], &a);
    runtime.real34ToReal(&elems[1], &b);
    runtime.real34ToReal(&elems[3], &d);
    if (realIsNegativeA(&a) or realIsNegativeA(&d) or realIsSpecial(&a) or realIsSpecial(&b) or realIsSpecial(&d)) {
        return false;
    }

    realCopy(&b, &negativeB);
    realChangeSign(&negativeB);
    math_vector_dot_scalar.dotCplx(&a, &b, &d, &negativeB, &determinant, &runtime.ctxtReal39);
    if (realIsNegativeA(&determinant) or realIsSpecial(&determinant)) {
        return false;
    }
    realSquareRoot(&determinant, &rootDeterminant, &runtime.ctxtReal39);
    realAdd(&a, &d, &denominator, &runtime.ctxtReal39);
    realAdd(&rootDeterminant, &rootDeterminant, &value, &runtime.ctxtReal39);
    realAdd(&denominator, &value, &denominator, &runtime.ctxtReal39);
    if (!realCompareGreaterThan(&denominator, const_0())) {
        return false;
    }
    realSquareRoot(&denominator, &denominator, &runtime.ctxtReal39);
    if (!runtime.realMatrixInit(res, 2, 2)) {
        return false;
    }

    const re: [*]real34_t = @ptrCast(res.matrixElements);
    realAdd(&a, &rootDeterminant, &value, &runtime.ctxtReal39);
    realDivide(&value, &denominator, &value, &runtime.ctxtReal39);
    runtime.realToReal34(&value, &re[0]);
    realDivide(&b, &denominator, &value, &runtime.ctxtReal39);
    runtime.realToReal34(&value, &re[1]);
    runtime.realToReal34(&value, &re[2]);
    realAdd(&d, &rootDeterminant, &value, &runtime.ctxtReal39);
    realDivide(&value, &denominator, &value, &runtime.ctxtReal39);
    runtime.realToReal34(&value, &re[3]);
    return true;
}

fn sqrtRealMatrixEigen(matrix: *const real34Matrix_t, res: *real34Matrix_t) linksection(runtime.code_section) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    var Lambda = std.mem.zeroes(real34Matrix_t);
    var LambdaImag = std.mem.zeroes(real34Matrix_t);
    var Q = std.mem.zeroes(real34Matrix_t);
    var QImag = std.mem.zeroes(real34Matrix_t);
    var Qinv = std.mem.zeroes(real34Matrix_t);
    var tmp = std.mem.zeroes(real34Matrix_t);
    var failed = false;

    blk: {
        realEigenvalues(matrix, &Lambda, &LambdaImag);
        if (Lambda.matrixElements == null) {
            failed = true;
            break :blk;
        }
        if (LambdaImag.matrixElements != null) {
            var inputNorm34: real34_t = undefined;
            var tol: real_t = undefined;
            var val: real_t = undefined;
            var scale: real_t = undefined;
            runtime.euclideanNormRealMatrix(matrix, 2, &inputNorm34);
            runtime.real34ToReal(&inputNorm34, &scale);
            realMultiply(&scale, const_1e_34(), &tol, &runtime.ctxtReal39);
            const li: [*]const real34_t = @ptrCast(LambdaImag.matrixElements);
            var hasGenuine = false;
            var i: usize = 0;
            while (i < nn) : (i += 1) {
                runtime.real34ToReal(&li[i * nn + i], &val);
                if (runtime.realIsNegative(&val)) runtime.realChangeSign(&val);
                if (math_comparison_reals.realCompareGreaterThan(&val, &tol)) {
                    hasGenuine = true;
                    break;
                }
            }
            if (hasGenuine) {
                failed = true;
                break :blk;
            }
        }

        const lam: [*]real34_t = @ptrCast(Lambda.matrixElements);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            var a: real_t = undefined;
            runtime.real34ToReal(&lam[i * nn + i], &a);
            if (runtime.realIsNegative(&a)) {
                failed = true;
                break :blk;
            }
            realSquareRoot(&a, &a, &runtime.ctxtReal39);
            runtime.realToReal34(&a, &lam[i * nn + i]);
        }

        realEigenvectors(matrix, &Q, &QImag);
        if (Q.matrixElements == null) {
            failed = true;
            break :blk;
        }
        if (QImag.matrixElements != null) {
            var inputNorm34: real34_t = undefined;
            var tol: real_t = undefined;
            var val: real_t = undefined;
            var scale: real_t = undefined;
            runtime.euclideanNormRealMatrix(matrix, 2, &inputNorm34);
            runtime.real34ToReal(&inputNorm34, &scale);
            realMultiply(&scale, const_1e_34(), &tol, &runtime.ctxtReal39);
            const qi: [*]const real34_t = @ptrCast(QImag.matrixElements);
            var hasGenuine = false;
            var k: usize = 0;
            while (k < nn * nn) : (k += 1) {
                runtime.real34ToReal(&qi[k], &val);
                if (runtime.realIsNegative(&val)) runtime.realChangeSign(&val);
                if (math_comparison_reals.realCompareGreaterThan(&val, &tol)) {
                    hasGenuine = true;
                    break;
                }
            }
            if (hasGenuine) {
                failed = true;
                break :blk;
            }
        }

        runtime.invertRealMatrix(&Q, &Qinv);
        if (Qinv.matrixElements == null) {
            failed = true;
            break :blk;
        }
        math_matrix_product.multiplyRealMatrices(&Q, &Lambda, &tmp);
        if (tmp.matrixElements == null) {
            failed = true;
            break :blk;
        }
        math_matrix_product.multiplyRealMatrices(&tmp, &Qinv, res);
        if (res.matrixElements == null) {
            failed = true;
            break :blk;
        }
    }

    if (Lambda.matrixElements != null) runtime.realMatrixFree(&Lambda);
    if (LambdaImag.matrixElements != null) runtime.realMatrixFree(&LambdaImag);
    if (Q.matrixElements != null) runtime.realMatrixFree(&Q);
    if (QImag.matrixElements != null) runtime.realMatrixFree(&QImag);
    if (Qinv.matrixElements != null) runtime.realMatrixFree(&Qinv);
    if (tmp.matrixElements != null) runtime.realMatrixFree(&tmp);

    if (failed) {
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

fn sqrtComplexMatrixEigen(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) linksection(runtime.code_section) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    var Lambda = std.mem.zeroes(complex34Matrix_t);
    var Q = std.mem.zeroes(complex34Matrix_t);
    var Qinv = std.mem.zeroes(complex34Matrix_t);
    var tmp = std.mem.zeroes(complex34Matrix_t);
    var failed = false;

    blk: {
        complexEigenvalues(matrix, &Lambda);
        if (Lambda.matrixElements == null) {
            failed = true;
            break :blk;
        }
        const lam: [*]runtime.complex34_t = @ptrCast(Lambda.matrixElements);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            var a: cplx_t = undefined;
            var sq: cplx_t = undefined;
            runtime.real34ToReal(&lam[i * nn + i].real, &a.Real);
            runtime.real34ToReal(&lam[i * nn + i].imag, &a.Imag);
            runtime.sqrtComplex(&a, &sq, &runtime.ctxtReal39);
            runtime.realToReal34(&sq.Real, &lam[i * nn + i].real);
            runtime.realToReal34(&sq.Imag, &lam[i * nn + i].imag);
        }

        complexEigenvectors(matrix, &Q);
        if (Q.matrixElements == null) {
            failed = true;
            break :blk;
        }
        runtime.invertComplexMatrix(&Q, &Qinv);
        if (Qinv.matrixElements == null) {
            failed = true;
            break :blk;
        }
        math_matrix_product.multiplyComplexMatrices(&Q, &Lambda, &tmp);
        if (tmp.matrixElements == null) {
            failed = true;
            break :blk;
        }
        math_matrix_product.multiplyComplexMatrices(&tmp, &Qinv, res);
        if (res.matrixElements == null) {
            failed = true;
            break :blk;
        }
    }

    if (Lambda.matrixElements != null) runtime.complexMatrixFree(&Lambda);
    if (Q.matrixElements != null) runtime.complexMatrixFree(&Q);
    if (Qinv.matrixElements != null) runtime.complexMatrixFree(&Qinv);
    if (tmp.matrixElements != null) runtime.complexMatrixFree(&tmp);

    if (failed) {
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

fn sqrtRealMatrix(matrix: *const real34Matrix_t, res: *real34Matrix_t) linksection(runtime.code_section) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;

    const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    var a: real_t = undefined;

    if (n == 1) {
        runtime.real34ToReal(&elems[0], &a);
        if (runtime.realIsNegative(&a)) return;
        if (!runtime.realMatrixInit(res, 1, 1)) return;
        realSquareRoot(&a, &a, &runtime.ctxtReal39);
        const re: [*]real34_t = @ptrCast(res.matrixElements);
        runtime.realToReal34(&a, &re[0]);
        return;
    }

    if (isRealMatrixDiagonal(matrix)) {
        if (!runtime.realMatrixInit(res, n, n)) return;
        const re: [*]real34_t = @ptrCast(res.matrixElements);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            runtime.real34ToReal(&elems[i * nn + i], &a);
            if (runtime.realIsNegative(&a)) {
                runtime.realMatrixFree(res);
                res.matrixElements = null;
                res.header.matrixRows = 0;
                res.header.matrixColumns = 0;
                return;
            }
            realSquareRoot(&a, &a, &runtime.ctxtReal39);
            runtime.realToReal34(&a, &re[i * nn + i]);
        }
        return;
    }

    if (n == 2 and sqrtSymmetricRealMatrix2x2(matrix, res)) {
        if (!verifySqrtMatrix(matrix, res, null, null)) {
            runtime.realMatrixFree(res);
            res.matrixElements = null;
            res.header.matrixRows = 0;
            res.header.matrixColumns = 0;
        }
        return;
    }

    sqrtRealMatrixEigen(matrix, res);
    if (res.matrixElements != null and !verifySqrtMatrix(matrix, res, null, null)) {
        runtime.realMatrixFree(res);
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

fn sqrtComplexMatrix(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) linksection(runtime.code_section) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;

    if (isComplexMatrixDiagonal(matrix)) {
        if (!runtime.complexMatrixInit(res, n, n)) return;
        const me: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
        const re: [*]runtime.complex34_t = @ptrCast(res.matrixElements);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            var a: cplx_t = undefined;
            var sq: cplx_t = undefined;
            runtime.real34ToReal(&me[i * nn + i].real, &a.Real);
            runtime.real34ToReal(&me[i * nn + i].imag, &a.Imag);
            runtime.sqrtComplex(&a, &sq, &runtime.ctxtReal39);
            runtime.realToReal34(&sq.Real, &re[i * nn + i].real);
            runtime.realToReal34(&sq.Imag, &re[i * nn + i].imag);
        }
        return;
    }

    sqrtComplexMatrixEigen(matrix, res);
    if (res.matrixElements != null and !verifySqrtMatrix(null, null, matrix, res)) {
        runtime.complexMatrixFree(res);
        res.matrixElements = null;
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
    }
}

fn sqrtNoConverge() linksection(runtime.code_section) void {
    runtime.temporaryInformation = runtime.TI_NO_INFO;
    if (runtime.programRunStop == runtime.PGM_WAITING) runtime.programRunStop = runtime.PGM_STOPPED;
}

// ===========================================================================
// fnMatrixSquareRoot (M.SQRT) -- the public command. Real input falls back to a
// complex root (and auto-downgrades to real) when FL_CPXRES is set.
// ===========================================================================
pub export fn fnMatrixSquareRoot(unusedParamButMandatory: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedParamButMandatory;
    // Empty body upstream under `#if !defined(OPTION_EIGEN)`: MSQRT returns
    // without saving LastX and raises no error on the packages that drop the
    // option. squareRoot.c's fnSquareRoot is the one that refuses the operand
    // there, in its own #else arm, before it would reach this call.
    if (comptime !runtime.option_eigen) return;
    if (!runtime.saveLastX()) return;

    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [64]u8 = undefined;
                const m = bufPrintZ(&buf, "not a square matrix ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not square";
                runtime.moreInfoOnError("In function fnMatrixSquareRoot:", m, null, null);
            }
        } else {
            var res: real34Matrix_t = undefined;
            sqrtRealMatrix(&x, &res);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                if (res.matrixElements != null) {
                    runtime.convertReal34MatrixToReal34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.realMatrixFree(&res);
                    runtime.setSystemFlag(FLAG_ASLIFT);
                } else if (runtime.getSystemFlag(runtime.FLAG_CPXRES)) {
                    var cx = std.mem.zeroes(complex34Matrix_t);
                    var cres: complex34Matrix_t = undefined;
                    runtime.convertReal34MatrixToComplex34Matrix(&x, &cx);
                    if (cx.matrixElements != null) {
                        sqrtComplexMatrix(&cx, &cres);
                        runtime.complexMatrixFree(&cx);
                        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                            if (cres.matrixElements != null) {
                                const total: usize = @as(usize, cres.header.matrixRows) * cres.header.matrixColumns;
                                const ce: [*]runtime.complex34_t = @ptrCast(cres.matrixElements);
                                var allRealResult = true;
                                var i: usize = 0;
                                while (i < total) : (i += 1) {
                                    if (!runtime.real34IsZero(&ce[i].imag)) {
                                        allRealResult = false;
                                        break;
                                    }
                                }
                                if (allRealResult) {
                                    var rres: real34Matrix_t = undefined;
                                    if (runtime.realMatrixInit(&rres, cres.header.matrixRows, cres.header.matrixColumns)) {
                                        const re: [*]real34_t = @ptrCast(rres.matrixElements);
                                        i = 0;
                                        while (i < total) : (i += 1) re[i] = ce[i].real;
                                        runtime.convertReal34MatrixToReal34MatrixRegister(&rres, runtime.REGISTER_X);
                                        runtime.realMatrixFree(&rres);
                                    } else {
                                        runtime.convertComplex34MatrixToComplex34MatrixRegister(&cres, runtime.REGISTER_X);
                                    }
                                } else {
                                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&cres, runtime.REGISTER_X);
                                }
                                runtime.complexMatrixFree(&cres);
                                runtime.setSystemFlag(FLAG_ASLIFT);
                            } else {
                                runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE);
                                if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnMatrixSquareRoot:", "matrix has no square root, or iteration failed to converge", null, null);
                            }
                        } else {
                            sqrtNoConverge();
                        }
                    }
                } else {
                    runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnMatrixSquareRoot:", "matrix has no real square root, or iteration failed to converge", null, null);
                }
            } else {
                sqrtNoConverge();
            }
        }
    } else if (dt == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buf: [64]u8 = undefined;
                const m = bufPrintZ(&buf, "not a square matrix ({d}\x80\xd7{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not square";
                runtime.moreInfoOnError("In function fnMatrixSquareRoot:", m, null, null);
            }
        } else {
            var res: complex34Matrix_t = undefined;
            sqrtComplexMatrix(&x, &res);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                if (res.matrixElements != null) {
                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.complexMatrixFree(&res);
                    runtime.setSystemFlag(FLAG_ASLIFT);
                } else {
                    runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnMatrixSquareRoot:", "matrix has no square root, or iteration failed to converge", null, null);
                }
            } else {
                sqrtNoConverge();
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buf: [48]u8 = undefined;
            const m = bufPrintZ(&buf, "DataType {d}", .{dt}) catch "DataType";
            runtime.moreInfoOnError("In function fnMatrixSquareRoot:", m, "is not a (real or complex) matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}

// ===========================================================================
// real_QR_decomposition / complex_QR_decomposition (public) -- register-level
// QR wrappers around QR_decomposition_householder. Convert the real34/complex34
// input to cplx_t scratch, run Householder QR at ctxtReal75, write Q and R
// back. fnQrDecomposition (Zig) drives these.
// ===========================================================================
pub export fn real_QR_decomposition(matrix: *const real34Matrix_t, q: *real34Matrix_t, r: *real34Matrix_t) linksection(runtime.code_section) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const n2: usize = @as(usize, rows) * matrix.header.matrixColumns;
    const blocks: usize = n2 * realSizeInBlocks(75) * 2 * 3;
    if (allocCplx(blocks)) |mat| {
        const matq = mat + n2;
        const matr = mat + n2 * 2;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
        var i: usize = 0;
        while (i < n2) : (i += 1) {
            runtime.real34ToReal(&elems[i], &mat[i].Real);
            realSetZero(&mat[i].Imag);
        }
        QR_decomposition_householder(mat, rows, matq, matr, &runtime.ctxtReal75);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            const rr: usize = @as(usize, rows) * rows;
            if (runtime.realMatrixInit(q, rows, rows)) {
                const qe: [*]real34_t = @ptrCast(q.matrixElements);
                i = 0;
                while (i < rr) : (i += 1) runtime.realToReal34(&matq[i].Real, &qe[i]);
                if (runtime.realMatrixInit(r, rows, rows)) {
                    const re: [*]real34_t = @ptrCast(r.matrixElements);
                    i = 0;
                    while (i < rr) : (i += 1) runtime.realToReal34(&matr[i].Real, &re[i]);
                } else {
                    ramFull("In function real_QR_decomposition:", "Ram full, 1ao");
                }
            } else {
                ramFull("In function real_QR_decomposition:", "Ram full, 2ap");
            }
        } else {
            ramFull("In function real_QR_decomposition:", "Ram full, 2aq");
        }
        freeC47Blocks(mat, blocks);
    } else {
        ramFull("In function real_QR_decomposition:", "Ram full, 3ar");
    }
}

pub export fn complex_QR_decomposition(matrix: *const complex34Matrix_t, q: *complex34Matrix_t, r: *complex34Matrix_t) linksection(runtime.code_section) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const n2: usize = @as(usize, rows) * matrix.header.matrixColumns;
    const blocks: usize = n2 * realSizeInBlocks(75) * 2 * 3;
    if (allocCplx(blocks)) |mat| {
        const matq = mat + n2;
        const matr = mat + n2 * 2;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
        var i: usize = 0;
        while (i < n2) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &mat[i].Real);
            runtime.real34ToReal(&elems[i].imag, &mat[i].Imag);
        }
        QR_decomposition_householder(mat, rows, matq, matr, &runtime.ctxtReal75);
        if (runtime.complexMatrixInit(q, rows, rows)) {
            const qe: [*]runtime.complex34_t = @ptrCast(q.matrixElements);
            i = 0;
            while (i < n2) : (i += 1) {
                runtime.realToReal34(&matq[i].Real, &qe[i].real);
                runtime.realToReal34(&matq[i].Imag, &qe[i].imag);
            }
            if (runtime.complexMatrixInit(r, rows, rows)) {
                const re: [*]runtime.complex34_t = @ptrCast(r.matrixElements);
                i = 0;
                while (i < n2) : (i += 1) {
                    runtime.realToReal34(&matr[i].Real, &re[i].real);
                    runtime.realToReal34(&matr[i].Imag, &re[i].imag);
                }
            } else {
                ramFull("In function complex_QR_decomposition:", "Ram full, 1as");
            }
        } else {
            ramFull("In function complex_QR_decomposition:", "Ram full, 2at");
        }
        freeC47Blocks(mat, blocks);
    } else {
        ramFull("In function complex_QR_decomposition:", "Ram full, 3au");
    }
}
