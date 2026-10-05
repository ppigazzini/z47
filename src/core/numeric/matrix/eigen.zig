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
// OPTION_EIGEN on DM42 packages 1, 2 and 4.
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
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

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
extern fn decNumberFromString(res: *align(1) real_t, source: [*:0]const u8, ctxt: *realContext_t) *align(1) real_t;
extern fn realSetOne(r: *align(1) real_t) void;
// mulCpxMat is the math_matrix_complex_core-owned interleaved-complex matmul.
extern fn allocC47Blocks(size_in_blocks: usize) ?[*]align(4) real_t;
extern fn freeC47Blocks(ptr: ?[*]align(4) real_t, size_in_blocks: usize) void;
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
inline fn stringToReal(source: [*:0]const u8, destination: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
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

// Matrix-product owners + a real comparison, used by the matrix-sqrt engine.
const ERROR_NO_ROOT_FOUND: u8 = 20;

// Complex dense inverse (math_matrix_complex_core.zig) + NaN setter, both
// taken at align(1) so the packed interleaved-complex bulk scratch passes.
extern fn realSetNaN(value: *align(1) real_t) void;

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
// each of them an `#if defined(OPTION_EIGEN_159)` / `#else` pair: 159 digits of
// scratch plus a realPlus round-back through the caller's context with the
// option, 75 digits written straight into the caller's outputs without it.
// defines.h #undef's OPTION_EIGEN_159 in the block common to packages 1-4, so
// package 3 -- the only DM42 package that keeps OPTION_EIGEN -- runs at 75.
const eigen_block_digits: u32 = if (runtime.option_eigen_159) 159 else 75;

// ===========================================================================
// calculateEigenvalues22 -- eigenvalues of the bottom-right 2x2 sub-matrix of
// the interleaved-complex real_t array `mat` (2 reals per element).
// ===========================================================================
pub export fn calculateEigenvalues22(
    mat: [*]align(1) const real_t,
    size: u16,
    t1r: *align(1) real_t,
    t1i: *align(1) real_t,
    t2r: *align(1) real_t,
    t2i: *align(1) real_t,
    is_real_symmetric: bool,
    realContext: *realContext_t,
) callconv(.c) void {
    var ctx159: realContext_t = runtime.ctxtReal75;
    ctx159.digits = eigen_block_digits;

    var trR_b = BigReal(eigen_block_digits){};
    var trI_b = BigReal(eigen_block_digits){};
    var detR_b = BigReal(eigen_block_digits){};
    var detI_b = BigReal(eigen_block_digits){};
    var discrR_b = BigReal(eigen_block_digits){};
    var discrI_b = BigReal(eigen_block_digits){};
    const trR = trR_b.ptr();
    const trI = trI_b.ptr();
    const detR = detR_b.ptr();
    const detI = detI_b.ptr();
    const discrR = discrR_b.ptr();
    const discrI = discrI_b.ptr();

    realSetZero(trR);
    realSetZero(trI);
    realSetZero(detR);
    realSetZero(detI);
    realSetZero(discrR);
    realSetZero(discrI);

    const sz: usize = size;
    const ar = &mat[((sz - 2) * sz + (sz - 2)) * 2];
    const ai = &mat[((sz - 2) * sz + (sz - 2)) * 2 + 1];
    const br = &mat[((sz - 2) * sz + (sz - 1)) * 2];
    const bi = &mat[((sz - 2) * sz + (sz - 1)) * 2 + 1];
    const cr = &mat[((sz - 1) * sz + (sz - 2)) * 2];
    const ci = &mat[((sz - 1) * sz + (sz - 2)) * 2 + 1];
    const dr = &mat[((sz - 1) * sz + (sz - 1)) * 2];
    const di = &mat[((sz - 1) * sz + (sz - 1)) * 2 + 1];

    // determinant ad - bc
    if (realIsZeroA(ai) and realIsZeroA(bi) and realIsZeroA(ci) and realIsZeroA(di)) {
        realMultiply(ar, dr, detR, &ctx159);
        realMultiply(br, cr, trR, &ctx159); // reuse trR as temp
        realSubtract(detR, trR, detR, &ctx159);
        realSetZero(detI);
    } else {
        math_multiplication_cells.mulComplexComplex(@alignCast(ar), @alignCast(ai), @alignCast(dr), @alignCast(di), @alignCast(detR), @alignCast(detI), &ctx159);
        math_multiplication_cells.mulComplexComplex(@alignCast(br), @alignCast(bi), @alignCast(cr), @alignCast(ci), @alignCast(trR), @alignCast(trI), &ctx159);
        realSubtract(detR, trR, detR, &ctx159);
        realSubtract(detI, trI, detI, &ctx159);
    }

    // negative trace -(a + d)
    realAdd(ar, dr, trR, &ctx159);
    realAdd(ai, di, trI, &ctx159);
    realChangeSign(trR);
    realChangeSign(trI);

    blockMonitoring = true;
    if (runtime.option_eigen_159) {
        var t1rH_b = BigReal(159){};
        var t1iH_b = BigReal(159){};
        var t2rH_b = BigReal(159){};
        var t2iH_b = BigReal(159){};
        const t1rH = t1rH_b.ptr();
        const t1iH = t1iH_b.ptr();
        const t2rH = t2rH_b.ptr();
        const t2iH = t2iH_b.ptr();
        realSetZero(t1rH);
        realSetZero(t1iH);
        realSetZero(t2rH);
        realSetZero(t2iH);
        math_slvq.solveQuadraticEquation159(const_1(), const_0(), trR, trI, detR, detI, discrR, discrI, t1rH, t1iH, t2rH, t2iH, &ctx159);
        // Round the 159-digit roots back through the caller's context.
        realPlus(t1rH, t1r, realContext);
        realPlus(t1iH, t1i, realContext);
        realPlus(t2rH, t2r, realContext);
        realPlus(t2iH, t2i, realContext);
    } else {
        // No high-precision temporaries and no round-back: the 75-digit solver
        // writes the caller's outputs directly.
        math_slvq.solveQuadraticEquation(const_1(), const_0(), trR, trI, detR, detI, discrR, discrI, t1r, t1i, t2r, t2i, &ctx159);
    }
    blockMonitoring = false;

    if (is_real_symmetric) {
        realSetZero(t1i);
        realSetZero(t2i);
    }
}

inline fn realSizeInBlocks(comptime digits: u32) u32 {
    return (realSizeInBytes(digits) + 3) / 4;
}

// adjCpxMat: conjugate transpose of a size x size interleaved-complex matrix.
fn adjCpxMat(x: [*]align(1) const real_t, size: u16, res: [*]align(1) real_t) linksection(runtime.code_section) void {
    const sz: usize = size;
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            realCopy(&x[(i * sz + j) * 2], &res[(j * sz + i) * 2]);
            realCopy(&x[(i * sz + j) * 2 + 1], &res[(j * sz + i) * 2 + 1]);
            realChangeSign(&res[(j * sz + i) * 2 + 1]);
        }
    }
}

// ===========================================================================
// QR_decomposition_householder -- Householder QR of the interleaved-complex
// size x size matrix `mat`, producing q and r (also interleaved complex). Uses
// a single C47-block bulk allocation for all scratch, matching upstream.
// ===========================================================================
pub export fn QR_decomposition_householder(
    mat: [*]align(1) const real_t,
    size: u16,
    q: [*]align(1) real_t,
    r: [*]align(1) real_t,
    realContext: *realContext_t,
) callconv(.c) void {
    const sz: usize = size;
    const n2: usize = sz * sz * 2; // real_t slots per matrix
    const bulkSize: usize = (sz * sz * 5 + sz) * realSizeInBlocks(75) * 2;

    if (allocC47Blocks(bulkSize)) |bulk| {
        // Zero the entire bulk allocation.
        {
            var z: usize = 0;
            const total = (sz * sz * 5 + sz) * 2;
            while (z < total) : (z += 1) realSetZero(&bulk[z]);
        }

        const matr = bulk;
        const matq = bulk + n2;
        const qq = bulk + 2 * n2;
        const qt = bulk + 3 * n2;
        const newMat = bulk + 4 * n2;
        const v = bulk + 5 * n2;

        var sum: real_t = undefined;
        var m: real_t = undefined;
        var t: real_t = undefined;

        // Copy mat -> matr.
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            realCopy(&mat[i * 2], &matr[i * 2]);
            realCopy(&mat[i * 2 + 1], &matr[i * 2 + 1]);
        }
        // Initialize Q to identity.
        i = 0;
        while (i < sz * sz) : (i += 1) {
            realSetZero(&matq[i * 2]);
            realSetZero(&matq[i * 2 + 1]);
        }
        i = 0;
        while (i < sz) : (i += 1) realSetOne(&matq[(i * sz + i) * 2]);

        var j: usize = 0;
        while (j < sz - 1) : (j += 1) {
            // Column vector of the sub-matrix + its norm.
            realSetZero(&sum);
            i = 0;
            while (i < sz - j) : (i += 1) {
                realCopy(&matr[((i + j) * sz + j) * 2], &v[i * 2]);
                realCopy(&matr[((i + j) * sz + j) * 2 + 1], &v[i * 2 + 1]);
                var temp_v1: real_t = undefined;
                var temp_v2: real_t = undefined;
                realFMA(&v[i * 2], &v[i * 2], &sum, &temp_v1, realContext);
                realCopy(&temp_v1, &sum);
                realFMA(&v[i * 2 + 1], &v[i * 2 + 1], &sum, &temp_v2, realContext);
                realCopy(&temp_v2, &sum);
            }
            realSquareRoot(&sum, &sum, realContext);

            // u = x - alpha e1 with the stable sign choice.
            if (realIsZeroA(&v[1])) {
                if (!realIsNegativeA(&v[0])) {
                    realChangeSign(&sum);
                }
                realSubtract(&v[0], &sum, &v[0], realContext);
            } else {
                blockMonitoring = true;
                math_transform_complex_helpers.realRectangularToPolar(&v[0], &v[1], &m, &t, realContext);
                blockMonitoring = true;
                math_transform_complex_helpers.realPolarToRectangular(&sum, &t, &m, &t, realContext);
                blockMonitoring = false;
                realAdd(&v[0], &m, &v[0], realContext);
                realAdd(&v[1], &t, &v[1], realContext);
            }

            // Norm of u.
            realSetZero(&sum);
            i = 0;
            while (i < sz - j) : (i += 1) {
                var temp_v1: real_t = undefined;
                var temp_v2: real_t = undefined;
                realFMA(&v[i * 2], &v[i * 2], &sum, &temp_v1, realContext);
                realCopy(&temp_v1, &sum);
                realFMA(&v[i * 2 + 1], &v[i * 2 + 1], &sum, &temp_v2, realContext);
                realCopy(&temp_v2, &sum);
            }
            realSquareRoot(&sum, &sum, realContext);

            // v = u / ||u|| with a precision-relative minimum threshold.
            var min_norm: real_t = undefined;
            var threshold_buf: [24]u8 = undefined;
            const threshold_str = bufPrintZ(&threshold_buf, "1E-{d}", .{realContext.digits}) catch "1E-75";
            stringToReal(threshold_str, &min_norm, realContext);
            i = 0;
            while (i < sz - j) : (i += 1) {
                if (math_comparison_reals.realCompareLessThan(&sum, &min_norm)) {
                    realCopy(&v[i * 2], &m);
                    realCopy(&v[i * 2 + 1], &t);
                } else if (realIsZeroA(&v[i * 2 + 1])) {
                    realDivide(&v[i * 2], &sum, &m, realContext);
                    realSetZero(&t);
                } else {
                    math_division_cells.divComplexComplex(&v[i * 2], &v[i * 2 + 1], &sum, const_0(), &m, &t, realContext);
                }
                realCopy(&m, &v[i * 2]);
                realCopy(&t, &v[i * 2 + 1]);
            }

            // qq = I.
            i = 0;
            while (i < sz * sz) : (i += 1) {
                realSetZero(&qq[i * 2]);
                realSetZero(&qq[i * 2 + 1]);
            }
            i = 0;
            while (i < sz) : (i += 1) realSetOne(&qq[(i * sz + i) * 2]);

            // qq -= 2 v v*.
            i = 0;
            while (i < sz - j) : (i += 1) {
                var k: usize = 0;
                while (k < sz - j) : (k += 1) {
                    const qe = (i + j) * sz + k + j;
                    realSubtract(const_0(), &v[k * 2 + 1], &sum, realContext);
                    if (realIsZeroA(&v[i * 2 + 1]) and realIsZeroA(&sum)) {
                        realMultiply(&v[i * 2], &v[k * 2], &m, realContext);
                        realSetZero(&t);
                    } else {
                        math_multiplication_cells.mulComplexComplex(&v[i * 2], &v[i * 2 + 1], &v[k * 2], &sum, &m, &t, realContext);
                    }
                    realMultiply(&m, const_2(), &m, realContext);
                    realMultiply(&t, const_2(), &t, realContext);
                    realSubtract(&qq[qe * 2], &m, &qq[qe * 2], realContext);
                    realSubtract(&qq[qe * 2 + 1], &t, &qq[qe * 2 + 1], realContext);
                }
            }

            // R = qq * matr.
            math_matrix_complex_core.mulCpxMat(qq, matr, size, size, size, newMat, realContext);
            i = 0;
            while (i < sz * sz) : (i += 1) {
                realCopy(&newMat[i * 2], &matr[i * 2]);
                realCopy(&newMat[i * 2 + 1], &matr[i * 2 + 1]);
            }
            // Q = matq * qq*.
            adjCpxMat(qq, size, qt);
            math_matrix_complex_core.mulCpxMat(matq, qt, size, size, size, newMat, realContext);
            i = 0;
            while (i < sz * sz) : (i += 1) {
                realCopy(&newMat[i * 2], &matq[i * 2]);
                realCopy(&newMat[i * 2 + 1], &matq[i * 2 + 1]);
            }
        }

        // Force R lower part to zero.
        j = 0;
        while (j < sz - 1) : (j += 1) {
            i = j + 1;
            while (i < sz) : (i += 1) {
                realSetZero(&matr[(i * sz + j) * 2]);
                realSetZero(&matr[(i * sz + j) * 2 + 1]);
            }
        }

        // Copy results out.
        i = 0;
        while (i < sz * sz) : (i += 1) {
            realCopy(&matq[i * 2], &q[i * 2]);
            realCopy(&matq[i * 2 + 1], &q[i * 2 + 1]);
            realCopy(&matr[i * 2], &r[i * 2]);
            realCopy(&matr[i * 2 + 1], &r[i * 2 + 1]);
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
pub export fn calculateEigenvalues33(
    mat: [*]align(1) const real_t,
    size: u16,
    t1r: *align(1) real_t,
    t1i: *align(1) real_t,
    t2r: *align(1) real_t,
    t2i: *align(1) real_t,
    t3r: *align(1) real_t,
    t3i: *align(1) real_t,
    is_real_symmetric: bool,
    realContext: *realContext_t,
) callconv(.c) void {
    var ctx159: realContext_t = runtime.ctxtReal75;
    ctx159.digits = eigen_block_digits;

    var aekr_b = BigReal(eigen_block_digits){};
    var aeki_b = BigReal(eigen_block_digits){};
    var bfgr_b = BigReal(eigen_block_digits){};
    var bfgi_b = BigReal(eigen_block_digits){};
    var cdhr_b = BigReal(eigen_block_digits){};
    var cdhi_b = BigReal(eigen_block_digits){};
    var cegr_b = BigReal(eigen_block_digits){};
    var cegi_b = BigReal(eigen_block_digits){};
    var bdkr_b = BigReal(eigen_block_digits){};
    var bdki_b = BigReal(eigen_block_digits){};
    var afhr_b = BigReal(eigen_block_digits){};
    var afhi_b = BigReal(eigen_block_digits){};
    var br_b = BigReal(eigen_block_digits){};
    var bi_b = BigReal(eigen_block_digits){};
    var cr_b = BigReal(eigen_block_digits){};
    var ci_b = BigReal(eigen_block_digits){};
    var dr_b = BigReal(eigen_block_digits){};
    var di_b = BigReal(eigen_block_digits){};
    var discrR_b = BigReal(eigen_block_digits){};
    var discrI_b = BigReal(eigen_block_digits){};
    const aekr = aekr_b.ptr();
    const aeki = aeki_b.ptr();
    const bfgr = bfgr_b.ptr();
    const bfgi = bfgi_b.ptr();
    const cdhr = cdhr_b.ptr();
    const cdhi = cdhi_b.ptr();
    const cegr = cegr_b.ptr();
    const cegi = cegi_b.ptr();
    const bdkr = bdkr_b.ptr();
    const bdki = bdki_b.ptr();
    const afhr = afhr_b.ptr();
    const afhi = afhi_b.ptr();
    const br = br_b.ptr();
    const bi = bi_b.ptr();
    const cr = cr_b.ptr();
    const ci = ci_b.ptr();
    const dr = dr_b.ptr();
    const di = di_b.ptr();
    const discrR = discrR_b.ptr();
    const discrI = discrI_b.ptr();

    const sz: usize = size;
    var mr: [9]*align(1) const real_t = undefined;
    var mi: [9]*align(1) const real_t = undefined;
    const b0 = ((sz - 3) * sz + (sz - 3)) * 2;
    const b3 = ((sz - 2) * sz + (sz - 3)) * 2;
    const b6 = ((sz - 1) * sz + (sz - 3)) * 2;
    const idx = [9]usize{ b0, b0 + 2, b0 + 4, b3, b3 + 2, b3 + 4, b6, b6 + 2, b6 + 4 };
    for (0..9) |i| {
        mr[i] = &mat[idx[i]];
        mi[i] = &mat[idx[i] + 1];
    }

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
    realAdd(mr[0], mr[4], br, &ctx159);
    realAdd(mi[0], mi[4], bi, &ctx159);
    realAdd(br, mr[8], br, &ctx159);
    realAdd(bi, mi[8], bi, &ctx159);
    realChangeSign(br);
    realChangeSign(bi);

    // linear coefficient: sum of principal 2x2 minors
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[0]), @alignCast(mi[0]), @alignCast(mr[4]), @alignCast(mi[4]), @alignCast(aekr), @alignCast(aeki), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[1]), @alignCast(mi[1]), @alignCast(mr[3]), @alignCast(mi[3]), @alignCast(bdkr), @alignCast(bdki), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[0]), @alignCast(mi[0]), @alignCast(mr[8]), @alignCast(mi[8]), @alignCast(cdhr), @alignCast(cdhi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[2]), @alignCast(mi[2]), @alignCast(mr[6]), @alignCast(mi[6]), @alignCast(cegr), @alignCast(cegi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[4]), @alignCast(mi[4]), @alignCast(mr[8]), @alignCast(mi[8]), @alignCast(bfgr), @alignCast(bfgi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[5]), @alignCast(mi[5]), @alignCast(mr[7]), @alignCast(mi[7]), @alignCast(afhr), @alignCast(afhi), &ctx159);
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
    math_multiplication_cells.mulComplexComplex(@alignCast(aekr), @alignCast(aeki), @alignCast(mr[8]), @alignCast(mi[8]), @alignCast(aekr), @alignCast(aeki), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[1]), @alignCast(mi[1]), @alignCast(mr[5]), @alignCast(mi[5]), @alignCast(bfgr), @alignCast(bfgi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(bfgr), @alignCast(bfgi), @alignCast(mr[6]), @alignCast(mi[6]), @alignCast(bfgr), @alignCast(bfgi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(mr[2]), @alignCast(mi[2]), @alignCast(mr[3]), @alignCast(mi[3]), @alignCast(cdhr), @alignCast(cdhi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(cdhr), @alignCast(cdhi), @alignCast(mr[7]), @alignCast(mi[7]), @alignCast(cdhr), @alignCast(cdhi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(cegr), @alignCast(cegi), @alignCast(mr[4]), @alignCast(mi[4]), @alignCast(cegr), @alignCast(cegi), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(bdkr), @alignCast(bdki), @alignCast(mr[8]), @alignCast(mi[8]), @alignCast(bdkr), @alignCast(bdki), &ctx159);
    math_multiplication_cells.mulComplexComplex(@alignCast(afhr), @alignCast(afhi), @alignCast(mr[0]), @alignCast(mi[0]), @alignCast(afhr), @alignCast(afhi), &ctx159);
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
    if (runtime.option_eigen_159) {
        var t1rH_b = BigReal(159){};
        var t1iH_b = BigReal(159){};
        var t2rH_b = BigReal(159){};
        var t2iH_b = BigReal(159){};
        var t3rH_b = BigReal(159){};
        var t3iH_b = BigReal(159){};
        const t1rH = t1rH_b.ptr();
        const t1iH = t1iH_b.ptr();
        const t2rH = t2rH_b.ptr();
        const t2iH = t2iH_b.ptr();
        const t3rH = t3rH_b.ptr();
        const t3iH = t3iH_b.ptr();
        realSetZero(t1rH);
        realSetZero(t1iH);
        realSetZero(t2rH);
        realSetZero(t2iH);
        realSetZero(t3rH);
        realSetZero(t3iH);

        math_slvc.solveCubicEquation159(br, bi, cr, ci, dr, di, discrR, discrI, t1rH, t1iH, t2rH, t2iH, t3rH, t3iH, &ctx159);

        // Round the 159-digit roots back through the caller's context.
        realPlus(t1rH, t1r, realContext);
        realPlus(t1iH, t1i, realContext);
        realPlus(t2rH, t2r, realContext);
        realPlus(t2iH, t2i, realContext);
        realPlus(t3rH, t3r, realContext);
        realPlus(t3iH, t3i, realContext);
    } else {
        // No high-precision temporaries and no round-back: the 75-digit solver
        // writes the caller's outputs directly.
        math_slvc.solveCubicEquation(br, bi, cr, ci, dr, di, discrR, discrI, t1r, t1i, t2r, t2i, t3r, t3i, &ctx159);
    }
    blockMonitoring = false;

    if (is_real_symmetric) {
        realSetZero(t1i);
        realSetZero(t2i);
        realSetZero(t3i);
    }
}

// ===========================================================================
// Eigenvalue ordering and matrix-shape helpers.
// ===========================================================================

// Merge-sort the computed eigenvalues (stored on the diagonal of eig) by
// descending magnitude, using the (i+1)/(i+2) off-diagonal slots as scratch.
fn sortEigenvalues(eig: [*]align(1) real_t, size: u16, begin_a: u16, begin_b: u16, end_b: u16, realContext: *realContext_t) linksection(runtime.code_section) void {
    const end_a: u16 = begin_b - 1;
    const sz: usize = size;

    if (size < 2) {
        return;
    } else if (begin_a == end_b) {
        return;
    } else if (size == 2) {
        math_runtime_helpers.complexMagnitude(@alignCast(&eig[0]), @alignCast(&eig[1]), @alignCast(&eig[2]), realContext);
        math_runtime_helpers.complexMagnitude(@alignCast(&eig[6]), @alignCast(&eig[7]), @alignCast(&eig[4]), realContext);
        if (math_comparison_reals.realCompareLessThan(@alignCast(&eig[2]), @alignCast(&eig[4]))) {
            realCopy(&eig[0], &eig[2]);
            realCopy(&eig[1], &eig[3]);
            realCopy(&eig[6], &eig[0]);
            realCopy(&eig[7], &eig[1]);
            realCopy(&eig[2], &eig[6]);
            realCopy(&eig[1], &eig[7]);
        }
    } else {
        var a: u16 = begin_a;
        var b: u16 = begin_b;
        sortEigenvalues(eig, size, begin_a, @intCast((@as(u32, begin_a) + end_a + 2) / 2), end_a, realContext);
        sortEigenvalues(eig, size, begin_b, @intCast((@as(u32, begin_b) + end_b + 2) / 2), end_b, realContext);
        var i: u16 = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            math_runtime_helpers.complexMagnitude(@alignCast(&eig[(ii * sz + ii) * 2]), @alignCast(&eig[(ii * sz + ii) * 2 + 1]), @alignCast(&eig[(ii * sz + (ii + 1) % sz) * 2]), realContext);
        }
        i = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            const dst = (ii * sz + (ii + 2) % sz) * 2;
            if (a > end_a) {
                const bb: usize = b;
                realCopy(&eig[(bb * sz + bb) * 2], &eig[dst]);
                realCopy(&eig[(bb * sz + bb) * 2 + 1], &eig[dst + 1]);
                b += 1;
            } else if (b > end_b) {
                const aa: usize = a;
                realCopy(&eig[(aa * sz + aa) * 2], &eig[dst]);
                realCopy(&eig[(aa * sz + aa) * 2 + 1], &eig[dst + 1]);
                a += 1;
            } else if (math_comparison_reals.realCompareLessThan(@alignCast(&eig[(@as(usize, a) * sz + (@as(usize, a) + 1) % sz) * 2]), @alignCast(&eig[(@as(usize, b) * sz + (@as(usize, b) + 1) % sz) * 2]))) {
                const bb: usize = b;
                realCopy(&eig[(bb * sz + bb) * 2], &eig[dst]);
                realCopy(&eig[(bb * sz + bb) * 2 + 1], &eig[dst + 1]);
                b += 1;
            } else {
                const aa: usize = a;
                realCopy(&eig[(aa * sz + aa) * 2], &eig[dst]);
                realCopy(&eig[(aa * sz + aa) * 2 + 1], &eig[dst + 1]);
                a += 1;
            }
        }
        i = begin_a;
        while (i <= end_b) : (i += 1) {
            const ii: usize = i;
            realCopy(&eig[(ii * sz + (ii + 2) % sz) * 2], &eig[(ii * sz + ii) * 2]);
            realCopy(&eig[(ii * sz + (ii + 2) % sz) * 2 + 1], &eig[(ii * sz + ii) * 2 + 1]);
        }
    }
}

// True when every off-diagonal element has magnitude below tol.
fn isMatrixDiagonal(matrix: [*]align(1) const real_t, size: u16, tol: *align(1) const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    for (0..sz) |i| {
        for (0..sz) |j| {
            if (i != j) {
                var offdiag_mag: real_t = undefined;
                math_runtime_helpers.complexMagnitude(@alignCast(&matrix[(i * sz + j) * 2]), @alignCast(&matrix[(i * sz + j) * 2 + 1]), &offdiag_mag, realContext);
                if (!math_comparison_reals.realCompareLessThan(&offdiag_mag, @alignCast(tol))) {
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

fn sumOfSubSupDiagonalAll(heading: [*:0]const u8, matrix: [*]align(1) const real_t, previousDiagonal: ?[*]align(1) real_t, size: u16, activeSize: u16, mode: c_int, sum: *align(1) real_t, firstCall: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = heading;
    var elemRe: real_t = undefined;
    var elemIm: real_t = undefined;
    realSetZero(sum);
    const sz: usize = size;
    var i: u16 = 0;
    while (i < activeSize) : (i += 1) {
        var j: u16 = 0;
        while (j < activeSize) : (j += 1) {
            var include = false;
            switch (mode) {
                DIAG => {
                    include = (i == j);
                },
                SUPSUBDIAG => {
                    include = (i == j + 1) or (j == i + 1);
                },
                NONDIAG => {
                    include = (i != j);
                },
                CHDIAG => {
                    include = (i == j);
                },
                else => {},
            }
            if (include) {
                const ii: usize = i;
                const jj: usize = j;
                realCopy(&matrix[(ii * sz + jj) * 2], &elemRe);
                realCopy(&matrix[(ii * sz + jj) * 2 + 1], &elemIm);
                if (mode == CHDIAG) {
                    const previous = previousDiagonal.?;
                    if (firstCall) {
                        realCopy(&elemRe, &previous[ii * 2]);
                        realCopy(&elemIm, &previous[ii * 2 + 1]);
                        continue;
                    } else {
                        var prevRe: real_t = undefined;
                        var prevIm: real_t = undefined;
                        var changeRe: real_t = undefined;
                        var changeIm: real_t = undefined;
                        realCopy(&previous[ii * 2], &prevRe);
                        realCopy(&previous[ii * 2 + 1], &prevIm);
                        realSubtract(&elemRe, &prevRe, &changeRe, realContext);
                        realSubtract(&elemIm, &prevIm, &changeIm, realContext);
                        realSetPositiveSign(&changeRe);
                        realSetPositiveSign(&changeIm);
                        realCopy(&elemRe, &previous[ii * 2]);
                        realCopy(&elemIm, &previous[ii * 2 + 1]);
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

pub export fn dropNoise(eig: [*]align(1) real_t, size: u16, dig: u16) linksection(runtime.code_section) callconv(.c) void {
    var c: realContext_t = runtime.ctxtReal39;
    c.digits = dig;
    c.round = runtime.DEC_ROUND_HALF_UP;
    const sz: usize = size;
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        const ptr = &eig[(i * sz + i) * 2];
        realPlus(ptr, ptr, &c);
        const ptr2 = &eig[(i * sz + i) * 2 + 1];
        realPlus(ptr2, ptr2, &c);
    }
}

fn isElementWithinTolerance(value_re: *align(1) const real_t, value_im: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var mag: real_t = undefined;
    // Copy the align(1) blob operands into naturally-aligned locals before the
    // naturally-aligned complexMagnitude call; @alignCast on a constant-pool
    // pointer aborts on strict-alignment targets (macOS/aarch64) whenever the
    // blob base lands at an under-aligned address.
    var value_re_local: real_t = value_re.*;
    var value_im_local: real_t = value_im.*;
    math_runtime_helpers.complexMagnitude(&value_re_local, &value_im_local, &mag, realContext);
    return math_comparison_reals.realCompareLessThan(&mag, @alignCast(tol));
}

// Real symmetric: every imaginary part on and above the diagonal, and every
// a[i][j] - a[j][i], is within 1E-symmetricTolerance.
fn checkMatrixProperties(a: [*]align(1) const real_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var tol: real_t = undefined;
    realSetOne(&tol);
    tol.exponent -= symmetricTolerance;
    const sz: usize = size;
    var i: u16 = 0;
    while (i < size) : (i += 1) {
        var j: u16 = i;
        while (j < size) : (j += 1) {
            const ii: usize = i;
            const jj: usize = j;
            const a_ij_re = &a[(ii * sz + jj) * 2];
            const a_ij_im = &a[(ii * sz + jj) * 2 + 1];
            const a_ji_re = &a[(jj * sz + ii) * 2];
            if (!isElementWithinTolerance(a_ij_im, const_0(), &tol, realContext)) {
                return false;
            }
            if (i < j) {
                var diff_val: real_t = undefined;
                realSubtract(a_ij_re, a_ji_re, &diff_val, realContext);
                if (!isElementWithinTolerance(&diff_val, const_0(), &tol, realContext)) {
                    return false;
                }
            }
        }
    }
    return true;
}

pub export fn isRealSymmetric(a: [*]align(1) const real_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) bool {
    return checkMatrixProperties(a, size, realContext);
}

fn solveEigenBlock(a: [*]align(1) real_t, eig: [*]align(1) real_t, size: u16, first_unconverged: c_int, last_unconverged: c_int, is_real_symmetric: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    const n = last_unconverged - first_unconverged + 1;
    if (n < 2 or n > 3) {
        return;
    }
    var block: [18]real_t = undefined;
    const sz: usize = size;
    const nn: usize = @intCast(n);
    const fu: usize = @intCast(first_unconverged);
    var row: usize = 0;
    while (row < nn) : (row += 1) {
        var col: usize = 0;
        while (col < nn) : (col += 1) {
            const src_row = fu + row;
            const src_col = fu + col;
            realCopy(&eig[(src_row * sz + src_col) * 2], &block[(row * nn + col) * 2]);
            realCopy(&eig[(src_row * sz + src_col) * 2 + 1], &block[(row * nn + col) * 2 + 1]);
        }
    }
    var ev_re: [3]real_t = undefined;
    var ev_im: [3]real_t = undefined;
    if (n == 2) {
        calculateEigenvalues22(&block, 2, &ev_re[0], &ev_im[0], &ev_re[1], &ev_im[1], is_real_symmetric, realContext);
    } else if (n == 3) {
        calculateEigenvalues33(&block, 3, &ev_re[0], &ev_im[0], &ev_re[1], &ev_im[1], &ev_re[2], &ev_im[2], is_real_symmetric, realContext);
    }
    var i: usize = 0;
    while (i < nn) : (i += 1) {
        const pos = fu + i;
        realCopy(&ev_re[i], &a[(pos * sz + pos) * 2]);
        realCopy(&ev_im[i], &a[(pos * sz + pos) * 2 + 1]);
    }
}

// ===========================================================================
// Eigenvalues of a general complex matrix of size > 3, by the scheme LAPACK's
// dlahqr uses: reduce to upper Hessenberg once, then run shifted QR on that
// form with Givens rotations. A sweep costs O(n^2) and neither Q nor R is
// formed. The shift is a single complex one, so a complex eigenvalue deflates
// as a 1x1 and no real 2x2 block machinery is needed.
// ===========================================================================

// The engine walks the caller's pool bulk as cplx_t. The bulk is untyped memory
// from allocC47Blocks sized in real_t, so the two views have to agree exactly:
// a cplx_t is two real_t with nothing between them and nothing after them.
const cplx_t = abi.Complex;
comptime {
    std.debug.assert(@sizeOf(cplx_t) == 2 * @sizeOf(real_t));
    std.debug.assert(@offsetOf(cplx_t, "Imag") == @sizeOf(real_t));
}

// The bulk, or a part of it, viewed as the cplx_t pairs or the plain real_t the
// engine walks. The pool hands out 4-aligned blocks, which both views need.
inline fn cxView(bulk: [*]align(1) real_t) [*]cplx_t {
    return @ptrCast(@alignCast(bulk));
}
inline fn realView(bulk: [*]align(1) real_t) [*]real_t {
    return @alignCast(bulk);
}

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

fn cxAdd(x: *const cplx_t, y: *const cplx_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    realAdd(&x.Real, &y.Real, &z.Real, ctx);
    realAdd(&x.Imag, &y.Imag, &z.Imag, ctx);
}

fn cxSub(x: *const cplx_t, y: *const cplx_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    realSubtract(&x.Real, &y.Real, &z.Real, ctx);
    realSubtract(&x.Imag, &y.Imag, &z.Imag, ctx);
}

fn cxMulReal(x: *const cplx_t, y: *const real_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    realMultiply(&x.Real, y, &z.Real, ctx);
    realMultiply(&x.Imag, y, &z.Imag, ctx);
}

fn cxDivReal(x: *const cplx_t, y: *const real_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    realDivide(&x.Real, y, &z.Real, ctx);
    realDivide(&x.Imag, y, &z.Imag, ctx);
}

fn cxMul(x: *const cplx_t, y: *const cplx_t, z: *cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var zr: real_t = undefined;
    var zi: real_t = undefined;
    math_multiplication_cells.mulComplexComplex(&x.Real, &x.Imag, &y.Real, &y.Imag, &zr, &zi, ctx);
    realCopy(&zr, &z.Real);
    realCopy(&zi, &z.Imag);
}

fn cxConj(x: *const cplx_t, z: *cplx_t) linksection(runtime.code_section) void {
    realCopy(&x.Real, &z.Real);
    realCopy(&x.Imag, &z.Imag);
    if (!realIsZeroA(&z.Imag)) {
        realChangeSign(&z.Imag);
    }
}

fn cxAbs(x: *const cplx_t, r: *real_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    math_runtime_helpers.complexMagnitude(&x.Real, &x.Imag, r, ctx);
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
    math_transform_complex_helpers.realRectangularToPolar(&x.Real, &x.Imag, &m, &t, ctx);
    blockMonitoring = false;
    realSquareRoot(&m, &m, ctx);
    realMultiply(&t, const_1on2(), &t, ctx);
    blockMonitoring = true;
    math_transform_complex_helpers.realPolarToRectangular(&m, &t, &z.Real, &z.Imag, ctx);
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
            cxAbs(cxAt(a, n, i, k), &tmp, ctx);
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
        cxAbs(&v[k + 1], &alpha, ctx);
        if (realIsZeroA(&alpha)) {
            realAdd(&v[k + 1].Real, &nrm, &v[k + 1].Real, ctx);
        } else {
            var phase: cplx_t = undefined;
            realDivide(&nrm, &alpha, &tmp, ctx); // ||x|| / |x0|
            cxMulReal(&v[k + 1], &tmp, &phase, ctx);
            cxAdd(&v[k + 1], &phase, &v[k + 1], ctx);
        }

        realSetZero(&nrm);
        i = k + 1;
        while (i < n) : (i += 1) {
            cxAbs(&v[i], &tmp, ctx);
            realFMA(&tmp, &tmp, &nrm, &nrm, ctx);
        }
        realSquareRoot(&nrm, &nrm, ctx);
        if (realIsZeroA(&nrm)) {
            continue;
        }
        i = k + 1;
        while (i < n) : (i += 1) {
            cxDivReal(&v[i], &nrm, &v[i], ctx);
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
                cxMul(&cv, cxAt(a, n, i, j), &prod, ctx);
                cxAdd(&acc, &prod, &acc, ctx);
            }
            cxMulReal(&acc, &two, &acc, ctx);
            cxCopy(&acc, &w[j]);
        }
        i = k + 1;
        while (i < n) : (i += 1) {
            j = 0;
            while (j < n) : (j += 1) {
                var prod: cplx_t = undefined;
                cxMul(&v[i], &w[j], &prod, ctx);
                cxSub(cxAt(a, n, i, j), &prod, cxAt(a, n, i, j), ctx);
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
                cxMul(cxAt(a, n, i, j), &v[j], &prod, ctx);
                cxAdd(&acc, &prod, &acc, ctx);
            }
            cxMulReal(&acc, &two, &acc, ctx);
            cxCopy(&acc, &w[i]);
        }
        i = 0;
        while (i < n) : (i += 1) {
            j = k + 1;
            while (j < n) : (j += 1) {
                var cv: cplx_t = undefined;
                var prod: cplx_t = undefined;
                cxConj(&v[j], &cv);
                cxMul(&w[i], &cv, &prod, ctx);
                cxSub(cxAt(a, n, i, j), &prod, cxAt(a, n, i, j), ctx);
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

    cxAbs(f, &af, ctx);
    cxAbs(g, &ag, ctx);

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
        cxDivReal(f, &af, &phase, ctx); // phase = f / |f|
        cxConj(g, &cg);
        cxMul(&phase, &cg, s, ctx);
        cxDivReal(s, &t, s, ctx); // s = phase * conj(g) / t
        cxMulReal(&phase, &t, r, ctx); // r = phase * t
    }
}

// One explicit shifted QR sweep on the active Hessenberg window [lo..hi].
// Rotations are kept in cs (n reals) and sn (n complex).
fn hessenbergQrSweep(a: [*]cplx_t, n: u16, lo: u16, hi: u16, shift: *const cplx_t, cs: [*]real_t, sn: [*]cplx_t, ctx: *realContext_t) linksection(runtime.code_section) void {
    var i: u16 = lo;
    while (i <= hi) : (i += 1) {
        cxSub(cxAt(a, n, i, i), shift, cxAt(a, n, i, i), ctx);
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

            cxMulReal(&u, &c, &t1, ctx);
            cxMul(&s, &w, &t2, ctx);
            cxAdd(&t1, &t2, cxAt(a, n, k, j), ctx); // c*u + s*w

            cxConj(&s, &cs2);
            cxMul(&cs2, &u, &t1, ctx);
            cxMulReal(&w, &c, &t2, ctx);
            cxSub(&t2, &t1, cxAt(a, n, k + 1, j), ctx); // c*w - conj(s)*u
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

            cxMulReal(&u, &c, &t1, ctx);
            cxMul(&cs2, &w, &t2, ctx);
            cxAdd(&t1, &t2, cxAt(a, n, i, k), ctx); // c*u + conj(s)*w

            cxMul(&s, &u, &t1, ctx);
            cxMulReal(&w, &c, &t2, ctx);
            cxSub(&t2, &t1, cxAt(a, n, i, k + 1), ctx); // c*w - s*u
        }
    }

    i = lo;
    while (i <= hi) : (i += 1) {
        cxAdd(cxAt(a, n, i, i), shift, cxAt(a, n, i, i), ctx);
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

    cxAdd(p, s, &tr, ctx);
    cxMul(p, s, &t1, ctx);
    cxMul(q, rr, &t2, ctx);
    cxSub(&t1, &t2, &det, ctx);

    cxMul(&tr, &tr, &disc, ctx);
    cxMulReal(&det, const_4(), &t1, ctx);
    cxSub(&disc, &t1, &disc, ctx);
    cxSqrt(&disc, &disc, ctx);

    cxAdd(&tr, &disc, l1, ctx);
    cxMulReal(l1, const_1on2(), l1, ctx);
    cxSub(&tr, &disc, l2, ctx);
    cxMulReal(l2, const_1on2(), l2, ctx);
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
    cxSub(p, s, &x, ctx);
    cxMulReal(&x, const_1on2(), &x, ctx);
    cxMul(q, rr, &u_2, ctx);
    cxMul(&x, &x, &y, ctx);
    cxAdd(&y, &u_2, &y, ctx);
    cxSqrt(&y, &y, ctx);
    realMultiply(&x.Real, &y.Real, &r1, ctx);
    realFMA(&x.Imag, &y.Imag, &r1, &r2, ctx);
    const flipped = realIsNegativeA(&r2) and !realIsZeroA(&r2);
    if (flipped) {
        realChangeSign(&y.Real);
        realChangeSign(&y.Imag);
    }
    cxAdd(&x, &y, &d, ctx);
    if (cxIsZero(&d)) { // x = y = 0: p = s and q r = 0, a double root
        cxCopy(p, l1);
        cxCopy(s, l2);
        return;
    }
    math_division_cells.divComplexComplex(&u_2.Real, &u_2.Imag, &d.Real, &d.Imag, &t.Real, &t.Imag, ctx);
    if (flipped) {
        cxSub(s, &t, l1, ctx);
        cxAdd(p, &t, l2, ctx);
    } else {
        cxAdd(p, &t, l1, ctx);
        cxSub(s, &t, l2, ctx);
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

    cxSub(&l1, s, &t1, ctx);
    cxAbs(&t1, &d1, ctx);
    cxSub(&l2, s, &t2, ctx);
    cxAbs(&t2, &d2, ctx);

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
            cxAbs(cxAt(a, n, i, j), &tmp, ctx);
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
                cxSub(cxAt(a, n, i - 1, i - 1), cxAt(a, n, i, i), &dif, ctx);
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

                cxAbs(cxAt(a, n, hi, hi - 1), &ss, ctx);
                if (hi >= lo + 2) {
                    cxAbs(cxAt(a, n, hi - 1, hi - 2), &tmp, ctx);
                    realAdd(&ss, &tmp, &ss, ctx);
                }
                realMultiply(&ss, &w1, &aa.Real, ctx);
                realSetZero(&aa.Imag);
                cxAdd(&aa, cxAt(a, n, hi, hi), &aa, ctx); // AA = WILK1*SS + H(hi,hi)
                realCopy(&ss, &bb.Real);
                realSetZero(&bb.Imag); // BB = SS
                realMultiply(&ss, &w2, &cc.Real, ctx);
                realSetZero(&cc.Imag); // CC = WILK2*SS
                cxMul(&bb, &cc, &disc, ctx);
                cxSqrt(&disc, &disc, ctx);
                cxAdd(&aa, &disc, &shift, ctx); // an eigenvalue of [[AA,BB],[CC,AA]]
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
// calculateEigenvalues -- eigenvalues of a size x size matrix held as
// interleaved re/im real_t arrays; the results land on the diagonal of eig.
// Size 2 and 3 use the closed-form solvers. A larger matrix that is diagonal to
// the deep tolerance is taken as it is; any other runs eigenHessenbergQr, which
// destroys a. scratch holds the engine's 7 * size reals. On non-convergence
// ERROR_NO_ROOT_FOUND is raised and the caller writes no result.
// ===========================================================================
// SLVP feeds its companion matrix through here (upstream drops the `static` on
// matrix.c's copy when OPTION_SLVP_POLY is on); slvp.zig shares this object, so the
// Zig side needs `pub`, not a C-ABI export.
pub fn calculateEigenvalues(a: [*]align(1) real_t, scratch: [*]align(1) real_t, eig: [*]align(1) real_t, size: u16, shifted: bool, reducedSignificantDigits: bool, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = shifted;
    const sz: usize = size;
    const tolerance_digits = toleranceDigits();
    const eigen_tolerance = eigenTolerance();
    var converged: bool = false;

    const is_real_symmetric = isRealSymmetric(a, size, realContext);

    // Initialize eig (size*size*2 reals) to zero, then copy the input matrix to it.
    {
        var k: usize = 0;
        while (k < sz * sz * 2) : (k += 1) {
            realSetZero(&eig[k]);
        }
        var ii: usize = 0;
        while (ii < sz) : (ii += 1) {
            var jj: usize = 0;
            while (jj < sz) : (jj += 1) {
                realCopy(&a[(ii * sz + jj) * 2], &eig[(ii * sz + jj) * 2]);
                realCopy(&a[(ii * sz + jj) * 2 + 1], &eig[(ii * sz + jj) * 2 + 1]);
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
        calculateEigenvalues22(a, size, &eig[0], &eig[1], &eig[6], &eig[7], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, @intCast(tolerance_digits));
    } else if (size == 3) {
        calculateEigenvalues33(a, size, &eig[0], &eig[1], &eig[8], &eig[9], &eig[16], &eig[17], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, @intCast(tolerance_digits));
    } else {
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
            while (k < sz * sz * 2) : (k += 1) realCopy(&a[k], &eig[k]);
            converged = true;
        }

        // Destroys a. On non-convergence the caller raises ERROR_NO_ROOT_FOUND
        // and writes no result.
        if (!converged and runtime.lastErrorCode == runtime.ERROR_NONE) {
            if (eigenHessenbergQr(cxView(a), cxView(eig), cxView(scratch), realView(scratch + sz * 4), size, realContext)) {
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
        sumOfSubSupDiagonalAll("", eig, null, size, size, DIAG, &diag_sum, true, realContext);
        // avg_diag = diag_sum / size
        realCopy(&diag_sum, &avg_diag);
        avg_diag.exponent -= @as(i32, size); // divide by size
        realCopy(&avg_diag, &rel_threshold);
        rel_threshold.exponent -= 10;

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
                    math_runtime_helpers.complexMagnitude(@alignCast(&eig[((j + 1) * sz + j) * 2]), @alignCast(&eig[((j + 1) * sz + j) * 2 + 1]), &offdiag_mag, realContext);
                    if (realIsZeroA(&offdiag_mag) or math_comparison_reals.realCompareLessThan(&offdiag_mag, &blockThreshold)) break;
                }

                var row: usize = j + 1;
                while (row < sz and !coupled) : (row += 1) {
                    var col: usize = i;
                    while (col <= j and !coupled) : (col += 1) {
                        math_runtime_helpers.complexMagnitude(@alignCast(&eig[(row * sz + col) * 2]), @alignCast(&eig[(row * sz + col) * 2 + 1]), &mag, realContext);
                        coupled = !realIsZeroA(&mag) and !math_comparison_reals.realCompareLessThan(&mag, &blockThreshold);
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
                while (k < sz * sz * 2) : (k += 1) realCopy(&eig[k], &a[k]);
                if (!eigenHessenbergQr(cxView(a), cxView(eig), cxView(scratch), realView(scratch + sz * 4), size, realContext)) {
                    qrDidNotConverge(size);
                }
            }
        }

        // Copy from a to eig before sorting (in case a was updated by block solvers)
        {
            var i: usize = 0;
            while (i < sz) : (i += 1) {
                realCopy(&a[(i * sz + i) * 2], &eig[(i * sz + i) * 2]);
                realCopy(&a[(i * sz + i) * 2 + 1], &eig[(i * sz + i) * 2 + 1]);
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
                const u = eig + (i * sz + i) * 2;
                const v = eig + ((i + 1) * sz + (i + 1)) * 2;
                var du: real_t = undefined;
                var dv: real_t = undefined;
                var t: real_t = undefined;
                var mean: real_t = undefined;

                if (realIsZeroA(&u[1]) or realIsZeroA(&v[1]) or realIsNegativeA(&u[1]) == realIsNegativeA(&v[1])) {
                    continue;
                }
                realSubtract(&u[0], &v[0], &du, realContext);
                realAdd(&u[1], &v[1], &dv, realContext);
                realCopyAbs(&du, &du);
                realCopyAbs(&dv, &dv);
                // Scale by the pair's own magnitude: a pair on the imaginary axis
                // has a zero real part, and nothing is below a tolerance scaled by
                // that.
                math_runtime_helpers.complexMagnitude(@alignCast(&u[0]), @alignCast(&u[1]), &t, realContext);
                t.exponent -= tolerance_digits;
                if (math_comparison_reals.realCompareLessThan(&du, &t) and math_comparison_reals.realCompareLessThan(&dv, &t)) {
                    // A real matrix has a real characteristic polynomial, so the
                    // two members share a real part exactly; the mean is that
                    // value where they agree and drops the residue where they do
                    // not.
                    realAdd(&u[0], &v[0], &mean, realContext);
                    realMultiply(&mean, const_1on2(), &mean, realContext);
                    realCopy(&mean, &u[0]);
                    realCopy(&mean, &v[0]);
                    if (realIsNegativeA(&u[1])) {
                        var swap: [2]real_t = undefined;
                        realCopy(&u[0], &swap[0]);
                        realCopy(&u[1], &swap[1]);
                        realCopy(&v[0], &u[0]);
                        realCopy(&v[1], &u[1]);
                        realCopy(&swap[0], &v[0]);
                        realCopy(&swap[1], &v[1]);
                    }
                }
            }
        }

        dropNoise(eig, size, @intCast(tolerance_digits - extraDigits));
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
// real34 register matrix to an interleaved-complex real_t bulk, run
// calculateEigenvalues, and write the diagonal eigenvalues back. eigenContext is
// &ctxtReal75. pub-exported, dead until fnEigenvalues wires them.
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
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const eig = bulk + sz * sz * 2;
        const scratch = bulk + sz * sz * 2 * 2;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i * 2]);
            realSetZero(&a[i * 2 + 1]);
        }
        calculateEigenvalues(a, scratch, eig, size, true, true, &runtime.ctxtReal75);
        var isComplex = false;
        i = 0;
        while (i < sz) : (i += 1) {
            if (!realIsZeroA(&eig[(i * sz + i) * 2 + 1])) {
                isComplex = true;
                break;
            }
        }
        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.realMatrixInit(res, size, size)) {
            const resElems: [*]real34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz) : (i += 1) runtime.realToReal34(&eig[(i * sz + i) * 2], &resElems[i * sz + i]);
            if (isComplex and ires != null) {
                if (@intFromPtr(matrix) == @intFromPtr(ires.?) or @intFromPtr(res) == @intFromPtr(ires.?) or runtime.realMatrixInit(ires.?, size, size)) {
                    const iresElems: [*]real34_t = @ptrCast(ires.?.matrixElements);
                    i = 0;
                    while (i < sz) : (i += 1) runtime.realToReal34(&eig[(i * sz + i) * 2 + 1], &iresElems[i * sz + i]);
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
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const eig = bulk + sz * sz * 2;
        const scratch = bulk + sz * sz * 2 * 2;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i * 2]);
            runtime.real34ToReal(&elems[i].imag, &a[i * 2 + 1]);
        }
        calculateEigenvalues(a, scratch, eig, size, true, true, &runtime.ctxtReal75);
        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.complexMatrixInit(res, size, size)) {
            const resElems: [*]runtime.complex34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz) : (i += 1) {
                runtime.realToReal34(&eig[(i * sz + i) * 2], &resElems[i * sz + i].real);
                runtime.realToReal34(&eig[(i * sz + i) * 2 + 1], &resElems[i * sz + i].imag);
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
// place (invCpxMat) and multiplying. Singular A -> ERROR_SINGULAR_MATRIX.
// ===========================================================================
// Exported (was file-local) so the linear-equation solver owner can share it;
// cpxLinearEqn is static in matrix.c, so the Zig global does not clash.
pub export fn cpxLinearEqn(a: [*]align(1) const real_t, b: [*]align(1) const real_t, r: [*]align(1) real_t, size: u16, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const blocks: usize = @as(usize, size) * size * realSizeInBlocks(75) * 2;
    if (allocC47Blocks(blocks)) |inv_a| {
        _ = runtime.xcopy(@ptrCast(inv_a), @ptrCast(a), @intCast(blocks << 2)); // TO_BYTES, BPB=2
        if (math_matrix_complex_core.invCpxMat(inv_a, size, realContext)) {
            math_matrix_complex_core.mulCpxMat(inv_a, @alignCast(b), size, size, 1, @alignCast(r), realContext);
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
fn solvesTheEigenProblem(matrix: *const real34Matrix_t, isComplex: bool, v: [*]align(1) const real_t, lambda: [*]align(1) const real_t, size: u16, eps3: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    const rElems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    const cElems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
    var accRe: real_t = undefined;
    var accIm: real_t = undefined;
    var elemRe: real_t = undefined;
    var elemIm: real_t = undefined;
    var prodRe: real_t = undefined;
    var prodIm: real_t = undefined;
    var mag: real_t = undefined;
    var resid: real_t = undefined;
    var vmax: real_t = undefined;
    var bound: real_t = undefined;

    realSetZero(&resid);
    realSetZero(&vmax);
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        math_runtime_helpers.complexMagnitude(@alignCast(&v[i * 2]), @alignCast(&v[i * 2 + 1]), &mag, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&mag, &vmax)) {
            realCopy(&mag, &vmax);
        }
    }
    if (realIsZeroA(&vmax)) {
        return false;
    }

    i = 0;
    while (i < sz) : (i += 1) {
        realSetZero(&accRe);
        realSetZero(&accIm);
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            if (isComplex) {
                runtime.real34ToReal(&cElems[i * sz + j].real, &elemRe);
                runtime.real34ToReal(&cElems[i * sz + j].imag, &elemIm);
            } else {
                runtime.real34ToReal(&rElems[i * sz + j], &elemRe);
                realSetZero(&elemIm);
            }
            if (i == j) {
                realSubtract(&elemRe, &lambda[0], &elemRe, realContext);
                realSubtract(&elemIm, &lambda[1], &elemIm, realContext);
            }
            math_multiplication_cells.mulComplexComplex(&elemRe, &elemIm, @alignCast(&v[j * 2]), @alignCast(&v[j * 2 + 1]), &prodRe, &prodIm, realContext);
            realAdd(&accRe, &prodRe, &accRe, realContext);
            realAdd(&accIm, &prodIm, &accIm, realContext);
        }
        math_runtime_helpers.complexMagnitude(&accRe, &accIm, &mag, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&mag, &resid)) {
            realCopy(&mag, &resid);
        }
    }
    realMultiply(eps3, &vmax, &bound, realContext);
    return math_comparison_reals.realCompareLessThan(&resid, &bound) or math_comparison_reals.realCompareEqual(&resid, &bound);
}

// Report whether v is a multiple of column col of r. Eigenvectors of distinct
// eigenvalues are independent, and a further copy of a repeated one re-solves
// the system its first copy built, so a vector that is a multiple of an earlier
// column is a rank-deficient set rather than a basis. LAPACK zhsein keeps them
// apart by perturbing the shift of each further copy by EPS3. The comparison is
// scale invariant: divide out the ratio at the column's largest entry and
// measure what is left against v's own size.
fn isMultipleOfColumn(v: [*]align(1) const real_t, r: [*]align(1) const real_t, size: u16, col: u16, realContext: *realContext_t) linksection(runtime.code_section) bool {
    const sz: usize = size;
    const cl: usize = col;
    var m: usize = 0;
    var best: real_t = undefined;
    var mag: real_t = undefined;
    var ratioRe: real_t = undefined;
    var ratioIm: real_t = undefined;
    var prodRe: real_t = undefined;
    var prodIm: real_t = undefined;
    var difRe: real_t = undefined;
    var difIm: real_t = undefined;
    var resid: real_t = undefined;
    var vmax: real_t = undefined;
    var tol: real_t = undefined;

    realSetZero(&best);
    var i: usize = 0;
    while (i < sz) : (i += 1) {
        const w = r + (i * sz + cl) * 2;
        math_runtime_helpers.complexMagnitude(@alignCast(&w[0]), @alignCast(&w[1]), &mag, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&mag, &best)) {
            realCopy(&mag, &best);
            m = i;
        }
    }
    if (realIsZeroA(&best)) {
        return false; // an all-zero column is already the failure signal
    }
    const wm = r + (m * sz + cl) * 2;
    math_division_cells.divComplexComplex(@alignCast(&v[m * 2]), @alignCast(&v[m * 2 + 1]), @alignCast(&wm[0]), @alignCast(&wm[1]), &ratioRe, &ratioIm, realContext);

    realSetZero(&resid);
    realSetZero(&vmax);
    i = 0;
    while (i < sz) : (i += 1) {
        const w = r + (i * sz + cl) * 2;
        math_multiplication_cells.mulComplexComplex(&ratioRe, &ratioIm, @alignCast(&w[0]), @alignCast(&w[1]), &prodRe, &prodIm, realContext);
        realSubtract(&v[i * 2], &prodRe, &difRe, realContext);
        realSubtract(&v[i * 2 + 1], &prodIm, &difIm, realContext);
        math_runtime_helpers.complexMagnitude(&difRe, &difIm, &mag, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&mag, &resid)) {
            realCopy(&mag, &resid);
        }
        math_runtime_helpers.complexMagnitude(@alignCast(&v[i * 2]), @alignCast(&v[i * 2 + 1]), &mag, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&mag, &vmax)) {
            realCopy(&mag, &vmax);
        }
    }
    if (realIsZeroA(&vmax)) {
        return false;
    }
    realDivide(&resid, &vmax, &mag, realContext);
    realSetOne(&tol);
    // A defective multiple eigenvalue splits by about the square root of the
    // working precision, so its copies agree to half the digits.
    tol.exponent -= @divTrunc(toleranceDigits(), 2);
    return math_comparison_reals.realCompareLessThan(&mag, &tol);
}

// LAPACK zhsein compares CABS1(w(i) - wk), the sum of the absolute parts,
// against EPS3 rather than testing equality.
fn isRepeatedEigenvalue(u: [*]align(1) const real_t, v: [*]align(1) const real_t, eps3: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var re: real_t = undefined;
    var im: real_t = undefined;
    realSubtract(&u[0], &v[0], &re, realContext);
    realSubtract(&u[1], &v[1], &im, realContext);
    realCopyAbs(&re, &re);
    realCopyAbs(&im, &im);
    realAdd(&re, &im, &re, realContext);
    return math_comparison_reals.realCompareLessThan(&re, eps3);
}

// ===========================================================================
// calculateEigenvectors (static) -- given the eigenvalues on the diagonal of
// eig, solve (A - lambda I) v = 0 per eigenvalue via the augmented-system
// technique, storing the eigenvectors column-wise into r. Diagonal A takes the
// permuted-unit-vector fast path. matrix_any aliases real34Matrix_t /
// complex34Matrix_t (shared header); the C copy stays file-local so the Zig
// signature is chosen for convenience.
// ===========================================================================
fn calculateEigenvectors(matrix: *const real34Matrix_t, isComplex: bool, a: [*]align(1) real_t, q: [*]align(1) real_t, r: [*]align(1) real_t, eig: [*]align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    // real34Matrix_t and complex34Matrix_t share the {header, matrixElements}
    // layout; the complex element view reinterprets the same element pointer.
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;

    const rElems: [*]const real34_t = abi.matrixConstRealElems(matrix);
    const cElems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);

    var i: usize = 0;
    while (i < sz * sz * 2) : (i += 1) realSetZero(&r[i]);
    var k: usize = 0;
    while (k < sz) : (k += 1) {
        realPlus(&eig[(k * sz + k) * 2], &eig[(k * sz + k) * 2], &runtime.ctxtReal34);
        realPlus(&eig[(k * sz + k) * 2 + 1], &eig[(k * sz + k) * 2 + 1], &runtime.ctxtReal34);
    }

    // Fast path: diagonal A has permuted unit eigenvectors.
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
    if (isDiagonal) {
        k = 0;
        while (k < sz) : (k += 1) {
            var j: usize = 0;
            while (j < sz) : (j += 1) {
                var alreadyUsed = false;
                var kPrev: usize = 0;
                while (kPrev < k) : (kPrev += 1) {
                    if (!realIsZeroA(&r[(j * sz + kPrev) * 2])) {
                        alreadyUsed = true;
                        break;
                    }
                }
                if (alreadyUsed) continue;
                var diagR: real_t = undefined;
                var diagI: real_t = undefined;
                if (isComplex) {
                    runtime.real34ToReal(&cElems[j * sz + j].real, &diagR);
                    runtime.real34ToReal(&cElems[j * sz + j].imag, &diagI);
                } else {
                    runtime.real34ToReal(&rElems[j * sz + j], &diagR);
                    realSetZero(&diagI);
                }
                var diff_r: real_t = undefined;
                var diff_i: real_t = undefined;
                var mag_eig: real_t = undefined;
                var mag_diag: real_t = undefined;
                var scale: real_t = undefined;
                var tol: real_t = undefined;
                realSubtract(&eig[(k * sz + k) * 2], &diagR, &diff_r, realContext);
                realSubtract(&eig[(k * sz + k) * 2 + 1], &diagI, &diff_i, realContext);
                math_runtime_helpers.complexMagnitude(@alignCast(&eig[(k * sz + k) * 2]), @alignCast(&eig[(k * sz + k) * 2 + 1]), &mag_eig, realContext);
                math_runtime_helpers.complexMagnitude(&diagR, &diagI, &mag_diag, realContext);
                realCopy(&mag_eig, &scale);
                if (math_comparison_reals.realCompareLessThan(&scale, &mag_diag)) realCopy(&mag_diag, &scale);
                if (math_comparison_reals.realCompareLessThan(&scale, const_1())) realCopy(const_1(), &scale);
                realMultiply(&scale, const_1e_30(), &tol, realContext);
                if (isElementWithinTolerance(&diff_r, &diff_i, &tol, realContext)) {
                    realCopy(const_1(), &r[(j * sz + k) * 2]);
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
    var mag: real_t = undefined;
    var magIm: real_t = undefined;
    realSetZero(&eps3);
    i = 0;
    while (i < sz) : (i += 1) {
        realSetZero(&rowSum);
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            if (isComplex) {
                runtime.real34ToReal(&cElems[i * sz + j].real, &mag);
                runtime.real34ToReal(&cElems[i * sz + j].imag, &magIm);
                math_runtime_helpers.complexMagnitude(&mag, &magIm, &mag, realContext);
            } else {
                runtime.real34ToReal(&rElems[i * sz + j], &mag);
                realCopyAbs(&mag, &mag);
            }
            realAdd(&rowSum, &mag, &rowSum, realContext);
        }
        if (math_comparison_reals.realCompareGreaterThan(&rowSum, &eps3)) {
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
    var pairedSlack = false;
    const utBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
    if (allocC47Blocks(utBlocks)) |utBuf| {
        const unknownsToFill: [*]u16 = @ptrCast(utBuf);
        k = 0;
        while (k < sz and runtime.lastErrorCode != runtime.ERROR_RAM_FULL) : (k += 1) { // a full RAM stops the remaining columns
            rep = @intCast(k);
            duplicateEigenvalueCount = 0;
            var jr: usize = 0;
            while (jr < k) : (jr += 1) {
                if (isRepeatedEigenvalue(eig + (jr * sz + jr) * 2, eig + (k * sz + k) * 2, &eps3, realContext)) {
                    if (duplicateEigenvalueCount == 0) {
                        rep = @intCast(jr); // the first copy of this eigenvalue: its system is the one to solve again
                    }
                    duplicateEigenvalueCount += 1;
                }
            }
            rebuildSystem = (duplicateEigenvalueCount == 0) or (rep != systemBuiltFor);
            if (rebuildSystem) {
                freeUnknowns = 1;
                unknownsToFill[0] = 0;
                systemBuiltFor = rep;
                pairedSlack = false;
            } else if (freeUnknowns > size) {
                freeUnknowns = size; // just in case
            }
            acceptedVector = false;
            const vBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
            if (allocC47Blocks(vBlocks)) |vBuf| {
                const v: [*]align(1) real_t = @ptrCast(vBuf);
                while (true) {
                    var j: usize = 0;
                    while (j < sz * 2 * 2) : (j += 1) realSetNaN(&v[j]);

                    if (rebuildSystem) {
                        const stride: usize = @as(usize, size) + freeUnknowns;
                        var ii: usize = 0;
                        while (ii < sz) : (ii += 1) {
                            var jj: usize = 0;
                            while (jj < sz) : (jj += 1) {
                                if (isComplex) {
                                    runtime.real34ToReal(&cElems[ii * sz + jj].real, @alignCast(&a[(ii * stride + jj) * 2]));
                                    runtime.real34ToReal(&cElems[ii * sz + jj].imag, @alignCast(&a[(ii * stride + jj) * 2 + 1]));
                                } else {
                                    runtime.real34ToReal(&rElems[ii * sz + jj], @alignCast(&a[(ii * stride + jj) * 2]));
                                    realSetZero(&a[(ii * stride + jj) * 2 + 1]);
                                }
                            }
                            jj = 0;
                            while (jj < freeUnknowns) : (jj += 1) {
                                realCopy(if ((if (pairedSlack) unknownsToFill[jj] else jj) == ii) const_1() else const_0(), &a[(ii * stride + jj + sz) * 2]);
                                realSetZero(&a[(ii * stride + jj + sz) * 2 + 1]);
                            }
                        }
                        ii = 0;
                        while (ii < freeUnknowns) : (ii += 1) {
                            var jj: usize = 0;
                            while (jj < sz) : (jj += 1) {
                                realCopy(if (jj == unknownsToFill[ii]) const_1() else const_0(), &a[((ii + sz) * stride + jj) * 2]);
                                realSetZero(&a[((ii + sz) * stride + jj) * 2 + 1]);
                            }
                            jj = 0;
                            while (jj < freeUnknowns) : (jj += 1) {
                                realCopy(if (jj == ii) const_1() else const_0(), &a[((ii + sz) * stride + jj + sz) * 2]);
                                realSetZero(&a[((ii + sz) * stride + jj + sz) * 2 + 1]);
                            }
                        }
                        // Subtract the eigenvalue from the leading diagonal.
                        const rp: usize = rep;
                        var jd: usize = 0;
                        while (jd < sz) : (jd += 1) {
                            realSubtract(&a[(jd * stride + jd) * 2], &eig[(rp * sz + rp) * 2], &a[(jd * stride + jd) * 2], realContext);
                            realSubtract(&a[(jd * stride + jd) * 2 + 1], &eig[(rp * sz + rp) * 2 + 1], &a[(jd * stride + jd) * 2 + 1], realContext);
                        }
                    }
                    if (duplicateEigenvalueCount != 0) {
                        rebuildSystem = false; // a further copy solves the system the first copy built, for the next null-space vector
                    }

                    // Make the RHS unit vector.
                    const stride: usize = @as(usize, size) + freeUnknowns;
                    var jq: usize = 0;
                    while (jq < stride) : (jq += 1) {
                        realCopy(if (jq == @as(usize, duplicateEigenvalueCount) + sz) const_1() else const_0(), &q[jq * 2]);
                        realSetZero(&q[jq * 2 + 1]);
                    }

                    runtime.lastErrorCode = runtime.ERROR_NONE;
                    cpxLinearEqn(a, q, v, @intCast(stride), realContext);
                    if (runtime.lastErrorCode != runtime.ERROR_SINGULAR_MATRIX) {
                        var usable = solvesTheEigenProblem(matrix, isComplex, v, eig + (k * sz + k) * 2, size, &eps3, realContext);
                        var jc: u16 = 0;
                        while (jc < k and usable) : (jc += 1) {
                            usable = !isMultipleOfColumn(v, r, size, jc, realContext);
                        }
                        if (usable) {
                            acceptedVector = true;
                            break;
                        }
                    }

                    // Build the matrix again on every retry: unknownsToFill moves
                    // the fixed unknowns, pairedSlack moves the slack and
                    // freeUnknowns is the row stride, so a retry that keeps the old
                    // matrix reads elements never written at the new stride.
                    rebuildSystem = true;
                    unknownsToFill[freeUnknowns - 1] += 1;
                    var ia: u16 = 1;
                    while (ia <= freeUnknowns - 1) : (ia += 1) {
                        if (unknownsToFill[freeUnknowns - 1] >= size) {
                            unknownsToFill[freeUnknowns - ia - 1] += 1;
                            var jb: usize = freeUnknowns - ia;
                            while (jb <= freeUnknowns - 1) : (jb += 1) {
                                unknownsToFill[freeUnknowns + jb] = unknownsToFill[freeUnknowns + jb - 1];
                            }
                        } else break;
                    }
                    if (unknownsToFill[freeUnknowns - 1] >= size) {
                        // No choice of fixed unknowns works with the slack on
                        // the first rows: the same choices come again with the
                        // slack on the rows of the fixed unknowns, which reaches
                        // an eigenvector whose dependent row is further down,
                        // and only then one more unknown is fixed.
                        if (pairedSlack) {
                            pairedSlack = false;
                            freeUnknowns += 1;
                        } else {
                            pairedSlack = true;
                        }
                        var ic: u16 = 0;
                        while (ic < size) : (ic += 1) unknownsToFill[ic] = ic;
                    }
                    if (freeUnknowns > size) break;
                }
                if (!acceptedVector) {
                    // Zero-fill on failure. The caller (realEigenvectors /
                    // complexEigenvectors) detects zero columns and reports the
                    // defective-matrix error to the user.
                    var ii: usize = 0;
                    while (ii < sz) : (ii += 1) {
                        realSetZero(&v[ii * 2]);
                        realSetZero(&v[ii * 2 + 1]);
                    }
                    if (runtime.lastErrorCode == runtime.ERROR_SINGULAR_MATRIX) {
                        // Clear only the singular solve the retries expect; any
                        // other error reaches the caller, which reports it
                        runtime.lastErrorCode = runtime.ERROR_NONE;
                    }
                }
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    realCopy(&v[ii * 2], &r[(ii * sz + k) * 2]);
                    realCopy(&v[ii * 2 + 1], &r[(ii * sz + k) * 2 + 1]);
                }
                freeC47Blocks(vBuf, vBlocks);
            } else {
                ramFull("In function calculateEigenvectors:", "Ram full, 1av");
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    realSetNaN(&r[(ii * sz + k) * 2]);
                    realSetNaN(&r[(ii * sz + k) * 2 + 1]);
                }
            }
        }
        freeC47Blocks(utBuf, utBlocks);
    } else {
        ramFull("In function calculateEigenvectors:", "Ram full, 2aw");
        var ii: usize = 0;
        while (ii < sz) : (ii += 1) {
            realSetNaN(&r[(ii * sz + k) * 2]);
            realSetNaN(&r[(ii * sz + k) * 2 + 1]);
        }
    }
}

// ===========================================================================
// realEigenvectors (static) -- eigenvectors of a real square matrix: compute
// eigenvalues, solve for each eigenvector, detect defective (zero) columns,
// normalize each column, and write real (res) + imaginary (ires) parts back.
// ===========================================================================
fn realEigenvectors(matrix: *const real34Matrix_t, res: *real34Matrix_t, ires: ?*real34Matrix_t) linksection(runtime.code_section) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 4 * 2 * 4 + sz * 7);
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4 * 2;
        const r = bulk + sz * sz * 4 * 2 * 2;
        const eig = bulk + sz * sz * 4 * 2 * 3;
        const scratch = bulk + sz * sz * 4 * 2 * 4;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i * 2]);
            realSetZero(&a[i * 2 + 1]);
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

        // Defective-matrix detection: a genuine eigenvector is never all-zero.
        var j: usize = 0;
        while (j < sz) : (j += 1) {
            var allZero = true;
            i = 0;
            while (i < sz) : (i += 1) {
                if (!realIsZeroA(&r[(i * sz + j) * 2]) or !realIsZeroA(&r[(i * sz + j) * 2 + 1])) {
                    allZero = false;
                    break;
                }
            }
            if (allZero) {
                res.matrixElements = null;
                res.header.matrixRows = 0;
                res.header.matrixColumns = 0;
                freeC47Blocks(bulk, bulkSize);
                return;
            }
        }

        var isComplex = false;
        i = 0;
        while (i < sz * sz) : (i += 1) {
            if (!realIsZeroA(&r[i * 2 + 1])) {
                isComplex = true;
                break;
            }
        }

        // Normalize each eigenvector column.
        j = 0;
        while (j < sz) : (j += 1) {
            var sum: real_t = undefined;
            realSetZero(&sum);
            i = 0;
            while (i < sz) : (i += 1) {
                var t1: real_t = undefined;
                var t2: real_t = undefined;
                realFMA(&r[(i * sz + j) * 2], &r[(i * sz + j) * 2], &sum, &t1, &runtime.ctxtReal75);
                realCopy(&t1, &sum);
                realFMA(&r[(i * sz + j) * 2 + 1], &r[(i * sz + j) * 2 + 1], &sum, &t2, &runtime.ctxtReal75);
                realCopy(&t2, &sum);
            }
            realSquareRoot(&sum, &sum, &runtime.ctxtReal75);
            if (!realIsZeroA(&sum) and !realIsSpecial(&sum)) {
                i = 0;
                while (i < sz) : (i += 1) {
                    realDivide(&r[(i * sz + j) * 2], &sum, &r[(i * sz + j) * 2], &runtime.ctxtReal75);
                    realDivide(&r[(i * sz + j) * 2 + 1], &sum, &r[(i * sz + j) * 2 + 1], &runtime.ctxtReal75);
                }
            }
        }

        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.realMatrixInit(res, size, size)) {
            const resElems: [*]real34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz * sz) : (i += 1) runtime.realToReal34(&r[i * 2], &resElems[i]);
            if (isComplex and ires != null) {
                if (@intFromPtr(matrix) == @intFromPtr(ires.?) or @intFromPtr(res) == @intFromPtr(ires.?) or runtime.realMatrixInit(ires.?, size, size)) {
                    const iresElems: [*]real34_t = @ptrCast(ires.?.matrixElements);
                    i = 0;
                    while (i < sz * sz) : (i += 1) runtime.realToReal34(&r[i * 2 + 1], &iresElems[i]);
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
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4 * 2;
        const r = bulk + sz * sz * 4 * 2 * 2;
        const eig = bulk + sz * sz * 4 * 2 * 3;
        const scratch = bulk + sz * sz * 4 * 2 * 4;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i * 2]);
            runtime.real34ToReal(&elems[i].imag, &a[i * 2 + 1]);
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

        var j: usize = 0;
        while (j < sz) : (j += 1) {
            var allZero = true;
            i = 0;
            while (i < sz) : (i += 1) {
                if (!realIsZeroA(&r[(i * sz + j) * 2]) or !realIsZeroA(&r[(i * sz + j) * 2 + 1])) {
                    allZero = false;
                    break;
                }
            }
            if (allZero) {
                res.matrixElements = null;
                res.header.matrixRows = 0;
                res.header.matrixColumns = 0;
                freeC47Blocks(bulk, bulkSize);
                return;
            }
        }

        if (@intFromPtr(matrix) == @intFromPtr(res) or runtime.complexMatrixInit(res, size, size)) {
            const resElems: [*]runtime.complex34_t = @ptrCast(res.matrixElements);
            i = 0;
            while (i < sz * sz) : (i += 1) {
                runtime.realToReal34(&r[i * 2], &resElems[i].real);
                runtime.realToReal34(&r[i * 2 + 1], &resElems[i].imag);
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
            var aReal: real_t = undefined;
            var aImag: real_t = undefined;
            var sqrtR: real_t = undefined;
            var sqrtI: real_t = undefined;
            runtime.real34ToReal(&lam[i * nn + i].real, &aReal);
            runtime.real34ToReal(&lam[i * nn + i].imag, &aImag);
            runtime.sqrtComplex(&aReal, &aImag, &sqrtR, &sqrtI, &runtime.ctxtReal39);
            runtime.realToReal34(&sqrtR, &lam[i * nn + i].real);
            runtime.realToReal34(&sqrtI, &lam[i * nn + i].imag);
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
            var aReal: real_t = undefined;
            var aImag: real_t = undefined;
            var sqrtR: real_t = undefined;
            var sqrtI: real_t = undefined;
            runtime.real34ToReal(&me[i * nn + i].real, &aReal);
            runtime.real34ToReal(&me[i * nn + i].imag, &aImag);
            runtime.sqrtComplex(&aReal, &aImag, &sqrtR, &sqrtI, &runtime.ctxtReal39);
            runtime.realToReal34(&sqrtR, &re[i * nn + i].real);
            runtime.realToReal34(&sqrtI, &re[i * nn + i].imag);
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
// QR wrappers around the now-ported QR_decomposition_householder. Convert the
// real34/complex34 input to interleaved-complex real_t scratch, run Householder
// QR at ctxtReal39, write Q and R back. fnQrDecomposition (Zig) drives these.
// ===========================================================================
pub export fn real_QR_decomposition(matrix: *const real34Matrix_t, q: *real34Matrix_t, r: *real34Matrix_t) linksection(runtime.code_section) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const n2: usize = @as(usize, rows) * matrix.header.matrixColumns;
    const blocks: usize = n2 * realSizeInBlocks(75) * 2 * 3;
    if (allocC47Blocks(blocks)) |mat| {
        const matq = mat + n2 * 2;
        const matr = mat + n2 * 2 * 2;
        const elems: [*]const real34_t = abi.matrixConstRealElems(matrix);
        var i: usize = 0;
        while (i < n2) : (i += 1) {
            runtime.real34ToReal(&elems[i], &mat[i * 2]);
            realSetZero(&mat[i * 2 + 1]);
        }
        QR_decomposition_householder(mat, rows, matq, matr, &runtime.ctxtReal39);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            const rr: usize = @as(usize, rows) * rows;
            if (runtime.realMatrixInit(q, rows, rows)) {
                const qe: [*]real34_t = @ptrCast(q.matrixElements);
                i = 0;
                while (i < rr) : (i += 1) runtime.realToReal34(&matq[i * 2], &qe[i]);
                if (runtime.realMatrixInit(r, rows, rows)) {
                    const re: [*]real34_t = @ptrCast(r.matrixElements);
                    i = 0;
                    while (i < rr) : (i += 1) runtime.realToReal34(&matr[i * 2], &re[i]);
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
    if (allocC47Blocks(blocks)) |mat| {
        const matq = mat + n2 * 2;
        const matr = mat + n2 * 2 * 2;
        const elems: [*]const runtime.complex34_t = abi.matrixConstComplexElems(matrix);
        var i: usize = 0;
        while (i < n2) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &mat[i * 2]);
            runtime.real34ToReal(&elems[i].imag, &mat[i * 2 + 1]);
        }
        QR_decomposition_householder(mat, rows, matq, matr, &runtime.ctxtReal39);
        if (runtime.complexMatrixInit(q, rows, rows)) {
            const qe: [*]runtime.complex34_t = @ptrCast(q.matrixElements);
            i = 0;
            while (i < n2) : (i += 1) {
                runtime.realToReal34(&matq[i * 2], &qe[i].real);
                runtime.realToReal34(&matq[i * 2 + 1], &qe[i].imag);
            }
            if (runtime.complexMatrixInit(r, rows, rows)) {
                const re: [*]runtime.complex34_t = @ptrCast(r.matrixElements);
                i = 0;
                while (i < n2) : (i += 1) {
                    runtime.realToReal34(&matr[i * 2], &re[i].real);
                    runtime.realToReal34(&matr[i * 2 + 1], &re[i].imag);
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
