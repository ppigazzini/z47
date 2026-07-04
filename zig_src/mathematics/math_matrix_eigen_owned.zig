// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
const const_1on2 = consts.const_1on2;
const const_1e_6 = consts.const_1e_6;
const const_1e_32 = consts.const_1e_32;
const const_1e_30 = consts.const_1e_30;
const const_1e_34 = consts.const_1e_34;
// Zig port of the eigenvalue/eigenvector engine of src/c47/mathematics/matrix.c
// (the static numeric workers behind fnEigenvalues/fnEigenvectors/
// fnMatrixSquareRoot). OPTION_EIGEN_159 is defined on every z47 build, so the
// internal scratch runs at 159 decimal digits via BigReal(159) (the Zig
// equivalent of upstream's REAL_T_PTR(name, 159) stack buffer).
//
// The workers are pub-exported so the file is fully analysed before the public
// commands are wired (the upstream copies are file-static, so the global Zig
// symbols never clash). The arithmetic is translated 1:1 against the decNumber
// primitives and the already-Zig-owned solveQuadraticEquation159 (math_slvq);
// the whole chain is verified by the Wolfram-referenced eigenvalue cases in the
// testSuite's matrix.txt once fnEigenvalues lands.
//
// This owner mirrors the real-op + BigReal scaffolding of math_slvq_owned.zig.

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

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
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
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
extern fn realCompareLessThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn divComplexComplex(nr: *align(1) const real_t, ni: *align(1) const real_t, dr: *align(1) const real_t, di: *align(1) const real_t, qr: *align(1) real_t, qi: *align(1) real_t, ctxt: *realContext_t) void;
extern fn realRectangularToPolar(re: *align(1) const real_t, im: *align(1) const real_t, magnitude: *align(1) real_t, theta: *align(1) real_t, ctxt: *realContext_t) void;
extern fn realPolarToRectangular(magnitude: *align(1) const real_t, theta: *align(1) const real_t, re: *align(1) real_t, im: *align(1) real_t, ctxt: *realContext_t) void;
// mulCpxMat is the math_matrix_complex_core-owned interleaved-complex matmul.
extern fn mulCpxMat(y: [*]align(1) const real_t, x: [*]align(1) const real_t, size_y: u16, size_yx: u16, size_x: u16, res: [*]align(1) real_t, ctxt: *realContext_t) void;
extern fn allocC47Blocks(size_in_blocks: usize) ?[*]align(4) real_t;
extern fn freeC47Blocks(ptr: ?[*]align(4) real_t, size_in_blocks: usize) void;
extern fn decNumberCopyAbs(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn realCompareGreaterThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareEqual(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn complexMagnitude(re: *align(1) const real_t, im: *align(1) const real_t, magnitude: *align(1) real_t, ctxt: *realContext_t) void;
extern fn realGetExponentComp(val: *align(1) const real_t) i32;
extern fn realCompareAbsLessThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn exitKeyWaiting() bool;
extern var currentKeyCode: u8;
extern var currentSolverNestingDepth: u16;
extern var significantDigits: u8;

inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}

// Eigen iteration tuning (matrix.c / defines.h).
const maxEigenIter: u16 = 10000;
const extraDigits: i32 = 3;
const blockDetectionTolerance: i32 = 40;
const eigenNoiseThreshold: i32 = 70;
const FLAG_SOLVING: i32 = 0xc026;
const ERROR_SOLVER_ABORT: u8 = 60;

inline fn realCopyAbs(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realIsSpecial(source: *align(1) const real_t) bool {
    // decNumberIsSpecial: any of the Inf/NaN/sNaN bits (DECSPECIAL = 0x70).
    return (source.bits & 0x70) != 0;
}

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
extern fn mulComplexComplex(f1r: *align(1) const real_t, f1i: *align(1) const real_t, f2r: *align(1) const real_t, f2i: *align(1) const real_t, pr: *align(1) real_t, pi: *align(1) real_t, ctxt: *realContext_t) void;

// math_slvq-owned quadratic solvers (Zig exports).
extern fn solveQuadraticEquation159(
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
) void;
extern fn solveCubicEquation159(
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
) void;

// Eigen iteration monitoring flag (matrix.c suppresses the keyboard monitor).
extern var blockMonitoring: bool;

// --- blob constants -------------------------------------------------------

// Matrix-product owners + a real comparison, used by the matrix-sqrt engine.
extern fn multiplyRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
extern fn multiplyComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
extern fn realCompareLessEqual(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
const ERROR_NO_ROOT_FOUND: u8 = 20;

// Complex dense inverse (math_matrix_complex_core_owned.zig) + NaN setter, both
// taken at align(1) so the packed interleaved-complex bulk scratch passes.
extern fn invCpxMat(matrix: [*]align(1) real_t, n: u16, ctxt: *realContext_t) bool;
extern fn realSetNaN(value: *align(1) real_t) void;

// --- BigReal(159): REAL_T_PTR(name, 159) stack scratch -------------------
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
// calculateEigenvalues22 -- eigenvalues of the bottom-right 2x2 sub-matrix of
// the interleaved-complex real_t array `mat` (2 reals per element). Uses
// 159-digit precision internally then rounds back into realContext, matching
// upstream's OPTION_EIGEN_159 path.
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
    ctx159.digits = 159;

    var trR_b = BigReal(159){};
    var trI_b = BigReal(159){};
    var detR_b = BigReal(159){};
    var detI_b = BigReal(159){};
    var discrR_b = BigReal(159){};
    var discrI_b = BigReal(159){};
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
        mulComplexComplex(ar, ai, dr, di, detR, detI, &ctx159);
        mulComplexComplex(br, bi, cr, ci, trR, trI, &ctx159);
        realSubtract(detR, trR, detR, &ctx159);
        realSubtract(detI, trI, detI, &ctx159);
    }

    // negative trace -(a + d)
    realAdd(ar, dr, trR, &ctx159);
    realAdd(ai, di, trI, &ctx159);
    realChangeSign(trR);
    realChangeSign(trI);

    blockMonitoring = true;
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
    solveQuadraticEquation159(const_1(), const_0(), trR, trI, detR, detI, discrR, discrI, t1rH, t1iH, t2rH, t2iH, &ctx159);
    realPlus(t1rH, t1r, realContext);
    realPlus(t1iH, t1i, realContext);
    realPlus(t2rH, t2r, realContext);
    realPlus(t2iH, t2i, realContext);
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
fn adjCpxMat(x: [*]align(1) const real_t, size: u16, res: [*]align(1) real_t) void {
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
                realRectangularToPolar(&v[0], &v[1], &m, &t, realContext);
                blockMonitoring = true;
                realPolarToRectangular(&sum, &t, &m, &t, realContext);
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
                if (realCompareLessThan(&sum, &min_norm)) {
                    realCopy(&v[i * 2], &m);
                    realCopy(&v[i * 2 + 1], &t);
                } else if (realIsZeroA(&v[i * 2 + 1])) {
                    realDivide(&v[i * 2], &sum, &m, realContext);
                    realSetZero(&t);
                } else {
                    divComplexComplex(&v[i * 2], &v[i * 2 + 1], &sum, const_0(), &m, &t, realContext);
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
                        mulComplexComplex(&v[i * 2], &v[i * 2 + 1], &v[k * 2], &sum, &m, &t, realContext);
                    }
                    realMultiply(&m, const_2(), &m, realContext);
                    realMultiply(&t, const_2(), &t, realContext);
                    realSubtract(&qq[qe * 2], &m, &qq[qe * 2], realContext);
                    realSubtract(&qq[qe * 2 + 1], &t, &qq[qe * 2 + 1], realContext);
                }
            }

            // R = qq * matr.
            mulCpxMat(qq, matr, size, size, size, newMat, realContext);
            i = 0;
            while (i < sz * sz) : (i += 1) {
                realCopy(&newMat[i * 2], &matr[i * 2]);
                realCopy(&newMat[i * 2 + 1], &matr[i * 2 + 1]);
            }
            // Q = matq * qq*.
            adjCpxMat(qq, size, qt);
            mulCpxMat(matq, qt, size, size, size, newMat, realContext);
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
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function QR_decomposition_householder:", "Ram full", null, null);
        }
    }
}

// ===========================================================================
// calculateEigenvalues33 -- closed-form eigenvalues of the bottom-right 3x3
// sub-matrix via its characteristic cubic, solved at 159 digits by the
// already-Zig-owned solveCubicEquation159 (math_slvc), then rounded back.
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
    ctx159.digits = 159;

    var aekr_b = BigReal(159){};
    var aeki_b = BigReal(159){};
    var bfgr_b = BigReal(159){};
    var bfgi_b = BigReal(159){};
    var cdhr_b = BigReal(159){};
    var cdhi_b = BigReal(159){};
    var cegr_b = BigReal(159){};
    var cegi_b = BigReal(159){};
    var bdkr_b = BigReal(159){};
    var bdki_b = BigReal(159){};
    var afhr_b = BigReal(159){};
    var afhi_b = BigReal(159){};
    var br_b = BigReal(159){};
    var bi_b = BigReal(159){};
    var cr_b = BigReal(159){};
    var ci_b = BigReal(159){};
    var dr_b = BigReal(159){};
    var di_b = BigReal(159){};
    var discrR_b = BigReal(159){};
    var discrI_b = BigReal(159){};
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
    mulComplexComplex(mr[0], mi[0], mr[4], mi[4], aekr, aeki, &ctx159);
    mulComplexComplex(mr[1], mi[1], mr[3], mi[3], bdkr, bdki, &ctx159);
    mulComplexComplex(mr[0], mi[0], mr[8], mi[8], cdhr, cdhi, &ctx159);
    mulComplexComplex(mr[2], mi[2], mr[6], mi[6], cegr, cegi, &ctx159);
    mulComplexComplex(mr[4], mi[4], mr[8], mi[8], bfgr, bfgi, &ctx159);
    mulComplexComplex(mr[5], mi[5], mr[7], mi[7], afhr, afhi, &ctx159);
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
    mulComplexComplex(aekr, aeki, mr[8], mi[8], aekr, aeki, &ctx159);
    mulComplexComplex(mr[1], mi[1], mr[5], mi[5], bfgr, bfgi, &ctx159);
    mulComplexComplex(bfgr, bfgi, mr[6], mi[6], bfgr, bfgi, &ctx159);
    mulComplexComplex(mr[2], mi[2], mr[3], mi[3], cdhr, cdhi, &ctx159);
    mulComplexComplex(cdhr, cdhi, mr[7], mi[7], cdhr, cdhi, &ctx159);
    mulComplexComplex(cegr, cegi, mr[4], mi[4], cegr, cegi, &ctx159);
    mulComplexComplex(bdkr, bdki, mr[8], mi[8], bdkr, bdki, &ctx159);
    mulComplexComplex(afhr, afhi, mr[0], mi[0], afhr, afhi, &ctx159);
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

    solveCubicEquation159(br, bi, cr, ci, dr, di, discrR, discrI, t1rH, t1iH, t2rH, t2iH, t3rH, t3iH, &ctx159);

    realPlus(t1rH, t1r, realContext);
    realPlus(t1iH, t1i, realContext);
    realPlus(t2rH, t2r, realContext);
    realPlus(t2iH, t2i, realContext);
    realPlus(t3rH, t3r, realContext);
    realPlus(t3iH, t3i, realContext);
    blockMonitoring = false;

    if (is_real_symmetric) {
        realSetZero(t1i);
        realSetZero(t2i);
        realSetZero(t3i);
    }
}

// ===========================================================================
// QR-iteration support workers (all pub-exported so they compile now; dead
// until calculateEigenvalues drives them).
// ===========================================================================

// Wilkinson-style shift from the bottom-right 2x2 block.
pub export fn calculateQrShift(mat: [*]align(1) const real_t, size: u16, re: *align(1) real_t, im: *align(1) real_t, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
    _ = is_real_symmetric;
    if (size < 2) {
        realSetZero(re);
        realSetZero(im);
        return;
    }
    const sz: usize = size;
    const a_nn_re = &mat[((sz - 1) * sz + (sz - 1)) * 2];
    const a_nn_im = &mat[((sz - 1) * sz + (sz - 1)) * 2 + 1];
    const a_mm_re = &mat[((sz - 2) * sz + (sz - 2)) * 2];
    const a_mm_im = &mat[((sz - 2) * sz + (sz - 2)) * 2 + 1];
    const a_mn_re = &mat[((sz - 1) * sz + (sz - 2)) * 2];
    const a_mn_im = &mat[((sz - 1) * sz + (sz - 2)) * 2 + 1];

    var delta_re: real_t = undefined;
    var delta_im: real_t = undefined;
    realSubtract(a_mm_re, a_nn_re, &delta_re, realContext);
    realSubtract(a_mm_im, a_nn_im, &delta_im, realContext);
    realMultiply(&delta_re, const_1on2(), &delta_re, realContext);
    realMultiply(&delta_im, const_1on2(), &delta_im, realContext);

    var b_sq: real_t = undefined;
    var temp: real_t = undefined;
    realMultiply(a_mn_re, a_mn_re, &b_sq, realContext);
    realMultiply(a_mn_im, a_mn_im, &temp, realContext);
    realAdd(&b_sq, &temp, &b_sq, realContext);

    var delta_sq: real_t = undefined;
    realMultiply(&delta_re, &delta_re, &delta_sq, realContext);
    realMultiply(&delta_im, &delta_im, &temp, realContext);
    realAdd(&delta_sq, &temp, &delta_sq, realContext);

    var sum: real_t = undefined;
    var sqrt_term: real_t = undefined;
    realAdd(&delta_sq, &b_sq, &sum, realContext);
    realSquareRoot(&sum, &sqrt_term, realContext);

    var sign_term: real_t = undefined;
    var abs_delta_re: real_t = undefined;
    realCopy(&sqrt_term, &sign_term);
    realCopyAbs(&delta_re, &abs_delta_re);

    var threshold: real_t = undefined;
    realMultiply(&sqrt_term, const_1e_6(), &threshold, realContext);
    if (realIsNegativeA(&delta_re) and realCompareGreaterThan(&abs_delta_re, &threshold)) {
        realChangeSign(&sign_term);
    }

    var denom: real_t = undefined;
    realSquareRoot(&delta_sq, &temp, realContext);
    realAdd(&temp, &sign_term, &denom, realContext);

    if (!realIsZeroA(&denom) and !realIsZeroA(&b_sq)) {
        var ratio: real_t = undefined;
        realDivide(&b_sq, &denom, &ratio, realContext);
        realSubtract(a_nn_re, &ratio, re, realContext);
        realCopy(a_nn_im, im);
    } else {
        realCopy(a_nn_re, re);
        realCopy(a_nn_im, im);
    }

    if (realIsSpecial(re) or realIsSpecial(im)) {
        realSetZero(re);
        realSetZero(im);
    }
}

// Merge-sort the computed eigenvalues (stored on the diagonal of eig) by
// descending magnitude, using the (i+1)/(i+2) off-diagonal slots as scratch.
pub export fn sortEigenvalues(eig: [*]align(1) real_t, size: u16, begin_a: u16, begin_b: u16, end_b: u16, realContext: *realContext_t) callconv(.c) void {
    const end_a: u16 = begin_b - 1;
    const sz: usize = size;

    if (size < 2) {
        return;
    } else if (begin_a == end_b) {
        return;
    } else if (size == 2) {
        complexMagnitude(&eig[0], &eig[1], &eig[2], realContext);
        complexMagnitude(&eig[6], &eig[7], &eig[4], realContext);
        if (realCompareLessThan(&eig[2], &eig[4])) {
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
            complexMagnitude(&eig[(ii * sz + ii) * 2], &eig[(ii * sz + ii) * 2 + 1], &eig[(ii * sz + (ii + 1) % sz) * 2], realContext);
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
            } else if (realCompareLessThan(&eig[(@as(usize, a) * sz + (@as(usize, a) + 1) % sz) * 2], &eig[(@as(usize, b) * sz + (@as(usize, b) + 1) % sz) * 2])) {
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

// Final 2x2 deflation block: eigenvalues straight onto the diagonal.
pub export fn solve2x2Block(a: [*]align(1) real_t, eig: [*]align(1) real_t, size: u16, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
    const sz: usize = size;
    var block: [8]real_t = undefined;
    for (0..2) |i| {
        for (0..2) |j| {
            realCopy(&a[(i * sz + j) * 2], &block[(i * 2 + j) * 2]);
            realCopy(&a[(i * sz + j) * 2 + 1], &block[(i * 2 + j) * 2 + 1]);
        }
    }
    calculateEigenvalues22(&block, 2, &a[0], &a[1], &a[(sz + 1) * 2], &a[(sz + 1) * 2 + 1], is_real_symmetric, realContext);
    for (0..2) |i| {
        realCopy(&a[(i * sz + i) * 2], &eig[(i * sz + i) * 2]);
        realCopy(&a[(i * sz + i) * 2 + 1], &eig[(i * sz + i) * 2 + 1]);
    }
}

// Final 3x3 deflation block.
pub export fn solve3x3Block(a: [*]align(1) real_t, eig: [*]align(1) real_t, size: u16, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
    const sz: usize = size;
    var block: [18]real_t = undefined;
    for (0..3) |i| {
        for (0..3) |j| {
            realCopy(&a[(i * sz + j) * 2], &block[(i * 3 + j) * 2]);
            realCopy(&a[(i * sz + j) * 2 + 1], &block[(i * 3 + j) * 2 + 1]);
        }
    }
    calculateEigenvalues33(&block, 3, &a[0], &a[1], &a[(sz + 1) * 2], &a[(sz + 1) * 2 + 1], &a[(sz + 1) * 4], &a[(sz + 1) * 4 + 1], is_real_symmetric, realContext);
    for (0..3) |i| {
        realCopy(&a[(i * sz + i) * 2], &eig[(i * sz + i) * 2]);
        realCopy(&a[(i * sz + i) * 2 + 1], &eig[(i * sz + i) * 2 + 1]);
    }
}

// True when every off-diagonal element has magnitude below tol.
pub export fn isMatrixDiagonal(matrix: [*]align(1) const real_t, size: u16, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    const sz: usize = size;
    for (0..sz) |i| {
        for (0..sz) |j| {
            if (i != j) {
                var offdiag_mag: real_t = undefined;
                complexMagnitude(&matrix[(i * sz + j) * 2], &matrix[(i * sz + j) * 2 + 1], &offdiag_mag, realContext);
                if (!realCompareLessThan(&offdiag_mag, tol)) {
                    return false;
                }
            }
        }
    }
    return true;
}

// ===========================================================================
// Convergence / matrix-property helpers (pub-exported, dead until
// calculateEigenvalues drives them). CONV_SUM_159 and ABS_SUMS are undef on
// every z47 build, so the diagonal sums accumulate sum-of-squares directly.
// ===========================================================================

pub export fn sumOfSubSupDiagonalAll(heading: [*:0]const u8, matrix: [*]align(1) const real_t, previousDiagonal: [*]align(1) real_t, size: u16, activeSize: u16, mode: c_int, sum: *align(1) real_t, firstCall: bool, realContext: *realContext_t) callconv(.c) void {
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
                    if (firstCall) {
                        realCopy(&elemRe, &previousDiagonal[ii * 2]);
                        realCopy(&elemIm, &previousDiagonal[ii * 2 + 1]);
                        continue;
                    } else {
                        var prevRe: real_t = undefined;
                        var prevIm: real_t = undefined;
                        var changeRe: real_t = undefined;
                        var changeIm: real_t = undefined;
                        realCopy(&previousDiagonal[ii * 2], &prevRe);
                        realCopy(&previousDiagonal[ii * 2 + 1], &prevIm);
                        realSubtract(&elemRe, &prevRe, &changeRe, realContext);
                        realSubtract(&elemIm, &prevIm, &changeIm, realContext);
                        realSetPositiveSign(&changeRe);
                        realSetPositiveSign(&changeIm);
                        realCopy(&elemRe, &previousDiagonal[ii * 2]);
                        realCopy(&elemIm, &previousDiagonal[ii * 2 + 1]);
                        elemRe = changeRe;
                        elemIm = changeIm;
                    }
                } else {
                    realSetPositiveSign(&elemRe);
                    realSetPositiveSign(&elemIm);
                }
                // Upstream defaults to ABS_SUMS (matrix.c:22): accumulate the
                // sum of absolute values, NOT the sum of squares. The eigen
                // convergence/stagnation thresholds (eigenTolerance,
                // blockDetectionTolerance, toleranceDigits) are calibrated for
                // this scaling; summing squares doubles the metric's exponent
                // and makes the stagnation detector give up prematurely.
                realAdd(&elemRe, sum, sum, realContext);
                realAdd(&elemIm, sum, sum, realContext);
            }
        }
    }
}

pub export fn dropNoise(eig: [*]align(1) real_t, size: u16, dig: u16) callconv(.c) void {
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

fn isElementWithinTolerance(value_re: *align(1) const real_t, value_im: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) bool {
    var mag: real_t = undefined;
    complexMagnitude(value_re, value_im, &mag, realContext);
    return realCompareLessThan(&mag, tol);
}

pub export fn checkMatrixProperties(a: [*]align(1) const real_t, size: u16, checkTridiagonal: bool, realContext: *realContext_t) callconv(.c) bool {
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
            const diff: i32 = @as(i32, j) - @as(i32, i);
            if (checkTridiagonal and diff > 1) {
                if (!isElementWithinTolerance(a_ij_re, a_ij_im, &tol, realContext)) {
                    return false;
                }
            }
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

pub export fn isSymmetricTridiagonal(a: [*]align(1) const real_t, size: u16, realContext: *realContext_t) callconv(.c) bool {
    return checkMatrixProperties(a, size, true, realContext);
}

pub export fn isRealSymmetric(a: [*]align(1) const real_t, size: u16, realContext: *realContext_t) callconv(.c) bool {
    return checkMatrixProperties(a, size, false, realContext);
}

pub export fn solveEigenBlock(a: [*]align(1) real_t, eig: [*]align(1) real_t, size: u16, first_unconverged: c_int, last_unconverged: c_int, is_real_symmetric: bool, realContext: *realContext_t) callconv(.c) void {
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

// Detect a circulant companion matrix (x^n - c), which the Householder QR
// cannot handle; calculateEigenvalues raises ERROR_OUT_OF_RANGE for it.
pub export fn isProblematicMatrix(matrix: [*]align(1) const real_t, size: u16) callconv(.c) bool {
    const sz: usize = size;
    var isCompanion = true;
    var i: usize = 0;
    while (i + 1 < sz) : (i += 1) {
        if (!realCompareEqual(&matrix[(i * sz + (i + 1)) * 2], const_1()) or
            !realIsZeroA(&matrix[(i * sz + (i + 1)) * 2 + 1]))
        {
            isCompanion = false;
            break;
        }
    }
    if (!isCompanion) return false;
    var isCirculant = true;
    if (realIsZeroA(&matrix[((sz - 1) * sz + 0) * 2])) isCirculant = false;
    var j: usize = 1;
    while (j < sz) : (j += 1) {
        if (!realIsZeroA(&matrix[((sz - 1) * sz + j) * 2])) {
            isCirculant = false;
            break;
        }
    }
    return isCirculant;
}

// ===========================================================================
// calculateEigenvalues -- the shifted QR-iteration driver. size 2/3 use the
// closed-form solvers; size > 3 runs the Householder QR loop with deflation,
// stagnation detection and final block solves. The on-device half-second
// progress display (checkHalfSec / formatDoubleWidth / progressHalfSecUpdate)
// is a pure UI side effect with no calc-state impact and is not exercised by
// the testSuite, so it is omitted here; the user-interrupt path is kept.
// ===========================================================================
pub export fn calculateEigenvalues(a: [*]align(1) real_t, q: [*]align(1) real_t, r: [*]align(1) real_t, eig: [*]align(1) real_t, previousDiagonal: [*]align(1) real_t, size: u16, shifted_in: bool, reducedSignificantDigits: bool, realContext: *realContext_t) callconv(.c) void {
    var shifted = shifted_in;
    const sz: usize = size;

    const significantDigitsVal: i32 = significantDigits;
    const toleranceDigits: i32 = if (runtime.is_testsuite_build)
        (34 + extraDigits)
    else
        ((if (significantDigitsVal == 0) @as(i32, 34) else significantDigitsVal) + extraDigits);
    const eigenTolerance: i32 = @min(70, toleranceDigits * 2);

    var changeDiagonalSum: real_t = undefined;
    var previousChangeDiagonalSum: real_t = undefined;
    var currentOffDiagonalSum: real_t = undefined;
    var changeOffDiagonalSum: real_t = undefined;
    var previousOffDiagonalSum: real_t = undefined;
    var offdiag_no_improvement_count: u16 = 0;
    var shiftRe: real_t = undefined;
    var shiftIm: real_t = undefined;
    var last_check_iter: u16 = 0;
    var no_improvement_count: u16 = 0;
    var iteration: u16 = 0;
    var activeSize: u16 = size;
    var converged: bool = false;

    if (isProblematicMatrix(a, size)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [96]u8 = undefined;
            const m = bufPrintZ(&buf, "Cannot execute: destination matrix is out of range, or the wrong type for the Householder QR: {d}", .{runtime.matrixIndex}) catch "QR out of range";
            runtime.moreInfoOnError("In function calculateEigenvalues:", m, null, null);
        }
    }

    const is_real_symmetric = isRealSymmetric(a, size, realContext);

    realSetZero(&currentOffDiagonalSum);
    realSetZero(&changeOffDiagonalSum);
    realSetZero(&previousOffDiagonalSum);
    realSetZero(&shiftRe);
    realSetZero(&shiftIm);
    realSetZero(&changeDiagonalSum);
    realSetZero(&previousChangeDiagonalSum);

    {
        var k: usize = 0;
        while (k < sz * sz * 2) : (k += 1) {
            realSetZero(&eig[k]);
            realSetZero(&q[k]);
            realSetZero(&r[k]);
            realSetZero(&previousDiagonal[k]);
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

    if (size == 2) {
        calculateEigenvalues22(a, size, &eig[0], &eig[1], &eig[6], &eig[7], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, @intCast(toleranceDigits));
    } else if (size == 3) {
        calculateEigenvalues33(a, size, &eig[0], &eig[1], &eig[8], &eig[9], &eig[16], &eig[17], is_real_symmetric, realContext);
        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        dropNoise(eig, size, @intCast(toleranceDigits));
    } else {
        var tol: real_t = undefined;
        var maxM: real_t = undefined;
        var minM: real_t = undefined;
        var tmpM: real_t = undefined;
        if (reducedSignificantDigits) {
            if (toleranceDigits >= 34 or toleranceDigits == 0) {
                realSetOne(&tol);
                tol.exponent -= eigenTolerance;
            } else {
                realSetOne(&tol);
                tol.exponent -= toleranceDigits;
            }
        } else {
            realSetOne(&tol);
            tol.exponent -= eigenTolerance;
        }

        const is_sym_tridiag = isSymmetricTridiagonal(a, size, realContext);

        if (isMatrixDiagonal(a, size, &tol, realContext)) {
            var k: usize = 0;
            while (k < sz * sz * 2) : (k += 1) realCopy(&a[k], &eig[k]);
            converged = true;
        }

        currentKeyCode = 255;
        currentSolverNestingDepth += 1;
        runtime.setSystemFlag(@intCast(FLAG_SOLVING));

        // ==== MAIN QR LOOP ====
        while (!converged and iteration < maxEigenIter and activeSize > 1 and runtime.lastErrorCode == runtime.ERROR_NONE) {
            iteration += 1;

            if (exitKeyWaiting()) {
                runtime.displayCalcErrorMessage(ERROR_SOLVER_ABORT, runtime.REGISTER_T, runtime.REGISTER_X);
                if (runtime.extra_info_on_calc_error) {
                    runtime.moreInfoOnError("In function calculateEigenvalues:", "Exit while calculating", null, null);
                }
            }

            if (shifted) {
                calculateQrShift(a, size, &shiftRe, &shiftIm, is_real_symmetric, realContext);
                if ((realIsZeroA(&shiftRe) and realIsZeroA(&shiftIm)) or realIsSpecial(&shiftRe) or realIsSpecial(&shiftIm)) {
                    shifted = false;
                } else {
                    var ii: usize = 0;
                    while (ii < sz) : (ii += 1) {
                        realSubtract(&a[(ii * sz + ii) * 2], &shiftRe, &a[(ii * sz + ii) * 2], realContext);
                        realSubtract(&a[(ii * sz + ii) * 2 + 1], &shiftIm, &a[(ii * sz + ii) * 2 + 1], realContext);
                    }
                }
            }

            QR_decomposition_householder(a, size, q, r, realContext);
            mulCpxMat(r, q, size, size, size, eig, realContext);

            if (shifted) {
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    realAdd(&a[(ii * sz + ii) * 2], &shiftRe, &a[(ii * sz + ii) * 2], realContext);
                    realAdd(&a[(ii * sz + ii) * 2 + 1], &shiftIm, &a[(ii * sz + ii) * 2 + 1], realContext);
                    realAdd(&eig[(ii * sz + ii) * 2], &shiftRe, &eig[(ii * sz + ii) * 2], realContext);
                    realAdd(&eig[(ii * sz + ii) * 2 + 1], &shiftIm, &eig[(ii * sz + ii) * 2 + 1], realContext);
                }
            }

            // ---- convergence / stagnation check ----
            if (iteration - last_check_iter >= 20 or iteration == 1) {
                var deltaChangeDiagonalSum: real_t = undefined;
                realSetZero(&deltaChangeDiagonalSum);
                if (iteration == 1) {
                    sumOfSubSupDiagonalAll("", eig, previousDiagonal, size, activeSize, CHDIAG, &changeDiagonalSum, true, &runtime.ctxtReal39);
                }
                sumOfSubSupDiagonalAll("", eig, previousDiagonal, size, activeSize, CHDIAG, &changeDiagonalSum, false, &runtime.ctxtReal39);

                if (realGetExponentComp(&changeDiagonalSum) < -blockDetectionTolerance and iteration > 5) {
                    sumOfSubSupDiagonalAll("", eig, previousDiagonal, size, activeSize, NONDIAG, &currentOffDiagonalSum, false, &runtime.ctxtReal75);
                    if (realGetExponentComp(&currentOffDiagonalSum) < -blockDetectionTolerance and iteration > 5) {
                        converged = true;
                        break;
                    }
                }

                converged = false;
                if (realGetExponentComp(&changeDiagonalSum) < -toleranceDigits and iteration != 1) {
                    converged = true;
                } else {
                    realSubtract(&changeDiagonalSum, &previousChangeDiagonalSum, &deltaChangeDiagonalSum, realContext);
                    if (realGetExponentComp(&changeDiagonalSum) < -(toleranceDigits - extraDigits) and realIsZeroA(&deltaChangeDiagonalSum) and iteration != 1) {
                        converged = true;
                    }
                }

                if (!converged) {
                    if (!realIsNegativeA(&deltaChangeDiagonalSum)) {
                        no_improvement_count += 1;
                        const max_no_improvement: u16 = if (is_sym_tridiag) 5 + 3 else 3 + 2;
                        if (no_improvement_count >= max_no_improvement) {
                            converged = true;
                        }
                    } else {
                        no_improvement_count = 0;
                    }
                }

                if (converged) {
                    sumOfSubSupDiagonalAll("", eig, previousDiagonal, size, activeSize, SUPSUBDIAG, &currentOffDiagonalSum, false, &runtime.ctxtReal75);
                    realSubtract(&currentOffDiagonalSum, &previousOffDiagonalSum, &changeOffDiagonalSum, &runtime.ctxtReal75);
                    if (realGetExponentComp(&currentOffDiagonalSum) <= -eigenTolerance) {
                        // off-diagonals tiny: accept
                    } else if (realIsNegativeA(&changeOffDiagonalSum)) {
                        if (realGetExponentComp(&changeOffDiagonalSum) > -(eigenTolerance - extraDigits)) {
                            converged = false;
                            offdiag_no_improvement_count = 0;
                        } else {
                            converged = false;
                            offdiag_no_improvement_count += 1;
                        }
                    } else {
                        converged = false;
                        offdiag_no_improvement_count += 1;
                    }
                    if (offdiag_no_improvement_count >= (if (is_sym_tridiag) @as(u16, 7) else 5)) {
                        break;
                    }
                }

                realCopy(&currentOffDiagonalSum, &previousOffDiagonalSum);
                realCopy(&changeDiagonalSum, &previousChangeDiagonalSum);
                last_check_iter = iteration;
            }

            // ---- deflation ----
            if (iteration > 2 and (iteration % 5) == 0) {
                var deflated = true;
                while (deflated and activeSize > 2) {
                    deflated = false;
                    var id: u16 = activeSize - 1;
                    while (id >= 1) : (id -= 1) {
                        const i: usize = id;
                        var subdiag_mag: real_t = undefined;
                        var threshold: real_t = undefined;
                        complexMagnitude(&eig[(i * sz + (i - 1)) * 2], &eig[(i * sz + (i - 1)) * 2 + 1], &subdiag_mag, realContext);
                        realSetOne(&threshold);
                        threshold.exponent -= blockDetectionTolerance;
                        if (realCompareLessThan(&subdiag_mag, &threshold)) {
                            realSetZero(&eig[(i * sz + (i - 1)) * 2]);
                            realSetZero(&eig[(i * sz + (i - 1)) * 2 + 1]);
                            if (activeSize == 3 and id == 1) {
                                solveEigenBlock(a, eig, size, @intCast(id), @intCast(id + 1), is_real_symmetric, realContext);
                            }
                            activeSize = id;
                            deflated = true;
                            break;
                        }
                    }
                }
            }

            {
                var k: usize = 0;
                while (k < sz * sz * 2) : (k += 1) realCopy(&eig[k], &a[k]);
            }

            if (is_real_symmetric) {
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) realSetZero(&a[(ii * sz + ii) * 2 + 1]);
            }

            {
                var ii: usize = 0;
                while (ii < sz) : (ii += 1) {
                    var jj: usize = 0;
                    while (jj < sz) : (jj += 1) {
                        const idx = ii * sz + jj;
                        realPlus(&a[idx * 2], &a[idx * 2], &runtime.ctxtReal51); // ctxtTruncate
                        realPlus(&a[idx * 2 + 1], &a[idx * 2 + 1], &runtime.ctxtReal51);
                        if (is_sym_tridiag and ii == jj) continue;
                        if (!realIsSpecial(&a[idx * 2])) {
                            if (realGetExponent(&a[idx * 2]) < -eigenNoiseThreshold) realSetZero(&a[idx * 2]);
                        } else {
                            realSetZero(&a[idx * 2]);
                        }
                        if (!realIsSpecial(&a[idx * 2 + 1])) {
                            if (realGetExponent(&a[idx * 2 + 1]) < -eigenNoiseThreshold) realSetZero(&a[idx * 2 + 1]);
                        } else {
                            realSetZero(&a[idx * 2 + 1]);
                        }
                    }
                }
            }

            if (converged) {
                break;
            } else {
                var k: usize = 0;
                while (k < sz * sz * 2) : (k += 1) realCopy(&eig[k], &a[k]);
            }
        } // end main loop

        // POST_QR_RELATIVE_BLOCK_CHECK: compute relative threshold based on
        // average diagonal magnitude (matrix.c ~7320-7329). Active #if branch.
        var diag_sum: real_t = undefined;
        var avg_diag: real_t = undefined;
        var rel_threshold: real_t = undefined;
        sumOfSubSupDiagonalAll("", eig, previousDiagonal, size, size, DIAG, &diag_sum, true, realContext);
        // avg_diag = diag_sum / size
        realCopy(&diag_sum, &avg_diag);
        avg_diag.exponent -= @as(i32, size); // divide by size
        realCopy(&avg_diag, &rel_threshold);
        rel_threshold.exponent -= 10;

        // ---- dedicated 2x2 block scan ----
        var first_unconverged: i32 = -1;
        var last_unconverged: i32 = -1;
        {
            var i: usize = 0;
            while (i + 1 < sz) : (i += 1) {
                var offdiag_mag: real_t = undefined;
                complexMagnitude(&eig[((i + 1) * sz + i) * 2], &eig[((i + 1) * sz + i) * 2 + 1], &offdiag_mag, realContext);
                // POST_QR_RELATIVE_BLOCK_CHECK active branch: use rel_threshold
                if (!realCompareLessThan(&offdiag_mag, &rel_threshold)) {
                    if (first_unconverged == -1) first_unconverged = @intCast(i);
                    last_unconverged = @intCast(i + 1);
                }
            }
        }
        if (first_unconverged != -1) {
            const block_size = last_unconverged - first_unconverged + 1;
            if (block_size == 2) {
                const fu: usize = @intCast(first_unconverged);
                var im1: real_t = undefined;
                var im2: real_t = undefined;
                realCopy(&eig[(fu * sz + fu) * 2 + 1], &im1);
                realCopy(&eig[((fu + 1) * sz + (fu + 1)) * 2 + 1], &im2);
                var is_conjugate_pair = false;
                if (!realIsZeroA(&im1) and !realIsZeroA(&im2)) {
                    var re_diff: real_t = undefined;
                    var im_sum: real_t = undefined;
                    realSubtract(&eig[(fu * sz + fu) * 2], &eig[((fu + 1) * sz + (fu + 1)) * 2], &re_diff, realContext);
                    realAdd(&im1, &im2, &im_sum, realContext);
                    if (realCompareAbsLessThan(&re_diff, const_1e_32()) and realCompareAbsLessThan(&im_sum, const_1e_32())) {
                        is_conjugate_pair = true;
                    }
                }
                if (!is_conjugate_pair) {
                    solveEigenBlock(a, eig, size, first_unconverged, first_unconverged + 1, is_real_symmetric, realContext);
                    var i: usize = 0;
                    while (i < 2) : (i += 1) {
                        const pos = fu + i;
                        realCopy(&a[(pos * sz + pos) * 2], &eig[(pos * sz + pos) * 2]);
                        realCopy(&a[(pos * sz + pos) * 2 + 1], &eig[(pos * sz + pos) * 2 + 1]);
                    }
                    realSetZero(&eig[((fu + 1) * sz + fu) * 2]);
                    realSetZero(&eig[((fu + 1) * sz + fu) * 2 + 1]);
                    realSetZero(&eig[(fu * sz + (fu + 1)) * 2]);
                    realSetZero(&eig[(fu * sz + (fu + 1)) * 2 + 1]);
                }
            }
        }

        // ---- smart remaining-block detection ----
        first_unconverged = -1;
        last_unconverged = -1;
        {
            var i: usize = 0;
            while (i + 1 < sz) : (i += 1) {
                var offdiag_mag: real_t = undefined;
                complexMagnitude(&eig[((i + 1) * sz + i) * 2], &eig[((i + 1) * sz + i) * 2 + 1], &offdiag_mag, realContext);
                // POST_QR_RELATIVE_BLOCK_CHECK active branch: use rel_threshold
                if (!realCompareLessThan(&offdiag_mag, &rel_threshold)) {
                    if (first_unconverged == -1) first_unconverged = @intCast(i);
                    last_unconverged = @intCast(i + 1);
                }
            }
        }
        if (first_unconverged != -1) {
            const block_size = last_unconverged - first_unconverged + 1;
            if (block_size == 3 or block_size == 2) {
                solveEigenBlock(a, eig, size, first_unconverged, last_unconverged, is_real_symmetric, realContext);
            }
        }

        // ---- activeSize handling ----
        if (activeSize == 1) {
            realCopy(&a[0], &eig[0]);
            realCopy(&a[1], &eig[1]);
        } else if (activeSize > 1 and activeSize < size) {
            var i: usize = 0;
            while (i < activeSize) : (i += 1) {
                realCopy(&a[(i * sz + i) * 2], &eig[(i * sz + i) * 2]);
                realCopy(&a[(i * sz + i) * 2 + 1], &eig[(i * sz + i) * 2 + 1]);
            }
        }

        if (activeSize == 3) {
            solve3x3Block(a, eig, size, is_real_symmetric, realContext);
        } else if (activeSize == 2) {
            var offdiag_01: real_t = undefined;
            var offdiag_10: real_t = undefined;
            complexMagnitude(&eig[(1 * sz + 0) * 2], &eig[(1 * sz + 0) * 2 + 1], &offdiag_01, realContext);
            complexMagnitude(&eig[(0 * sz + 1) * 2], &eig[(0 * sz + 1) * 2 + 1], &offdiag_10, realContext);
            if (!realCompareLessThan(&offdiag_01, &tol) or !realCompareLessThan(&offdiag_10, &tol)) {
                solve2x2Block(a, eig, size, is_real_symmetric, realContext);
            }
        } else if (activeSize == 1) {
            realCopy(&a[0], &eig[0]);
            realCopy(&a[1], &eig[1]);
        }
        shifted = false;

        {
            var i: usize = 0;
            while (i < sz) : (i += 1) {
                realCopy(&a[(i * sz + i) * 2], &eig[(i * sz + i) * 2]);
                realCopy(&a[(i * sz + i) * 2 + 1], &eig[(i * sz + i) * 2 + 1]);
            }
        }

        sortEigenvalues(eig, size, 0, (size + 1) / 2, size - 1, realContext);
        complexMagnitude(&eig[0], &eig[1], &maxM, realContext);

        // ---- condition-number cleanup ----
        {
            var i: usize = 1;
            while (i < sz) : (i += 1) {
                complexMagnitude(&eig[(i * sz + i) * 2], &eig[(i * sz + i) * 2 + 1], &tmpM, realContext);
                if (!realIsZeroA(&tmpM) and !realIsZeroA(&maxM) and realCompareLessThan(&tmpM, &tol)) {
                    realMultiply(&maxM, &tol, &minM, realContext);
                    var j: usize = 1;
                    while (j < sz) : (j += 1) {
                        complexMagnitude(&eig[(j * sz + j) * 2], &eig[(j * sz + j) * 2 + 1], &tmpM, realContext);
                        if (realCompareLessThan(&tmpM, &minM)) {
                            realSetZero(&eig[(j * sz + j) * 2]);
                            realSetZero(&eig[(j * sz + j) * 2 + 1]);
                        }
                    }
                }
            }
        }

        dropNoise(eig, size, @intCast(toleranceDigits - extraDigits));
    } // size > 3

    // Upstream increments currentSolverNestingDepth only in the size>3 branch
    // but decrements it for every size; for size 2/3 that is an unsigned wrap in
    // C (harmless -- the result is non-zero so the flag is not cleared). Match
    // the wrap so a future size-2/3 caller does not panic.
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
fn ramFull(comptime where: [*:0]const u8, comptime tag: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(where, tag, null, null);
    }
}

pub export fn realEigenvalues(matrix: *const real34Matrix_t, res: *real34Matrix_t, ires: ?*real34Matrix_t) callconv(.c) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 2 * 4 + sz * 2);
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 2;
        const r = bulk + sz * sz * 2 * 2;
        const eig = bulk + sz * sz * 2 * 3;
        const previousDiagonal = bulk + sz * sz * 2 * 4;
        const elems: [*]const real34_t = @ptrCast(matrix.matrixElements);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i * 2]);
            realSetZero(&a[i * 2 + 1]);
        }
        calculateEigenvalues(a, q, r, eig, previousDiagonal, size, true, true, &runtime.ctxtReal75);
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

pub export fn complexEigenvalues(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 2 * 4 + sz * 2);
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 2;
        const r = bulk + sz * sz * 2 * 2;
        const eig = bulk + sz * sz * 2 * 3;
        const previousDiagonal = bulk + sz * sz * 2 * 4;
        const elems: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);
        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i * 2]);
            runtime.real34ToReal(&elems[i].imag, &a[i * 2 + 1]);
        }
        calculateEigenvalues(a, q, r, eig, previousDiagonal, size, true, true, &runtime.ctxtReal75);
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
pub export fn fnEigenvalues(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    var doneAdjusting = false;
    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnEigenvalues:", "", null, null);
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
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\xc3\x97{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
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
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
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
pub export fn extractDiagonalToRowReal34Matrix(source: *const real34Matrix_t, dest: *real34Matrix_t) callconv(.c) void {
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

pub export fn extractDiagonalToRowComplex34Matrix(source: *const complex34Matrix_t, dest: *complex34Matrix_t) callconv(.c) void {
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
pub export fn cpxLinearEqn(a: [*]align(1) const real_t, b: [*]align(1) const real_t, r: [*]align(1) real_t, size: u16, realContext: *realContext_t) callconv(.c) void {
    const blocks: usize = @as(usize, size) * size * realSizeInBlocks(75) * 2;
    if (allocC47Blocks(blocks)) |inv_a| {
        _ = runtime.xcopy(@ptrCast(inv_a), @ptrCast(a), @intCast(blocks << 2)); // TO_BYTES, BPB=2
        if (invCpxMat(inv_a, size, realContext)) {
            mulCpxMat(inv_a, b, size, size, 1, r, realContext);
        } else if (runtime.lastErrorCode != runtime.ERROR_RAM_FULL) {
            runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function cpxLinearEqn:", "attempt to invert a singular matrix", null, null);
        }
        freeC47Blocks(inv_a, blocks);
    } else {
        ramFull("In function cpxLinearEqn:", "Ram full");
    }
}

// ===========================================================================
// calculateEigenvectors (static) -- given the eigenvalues on the diagonal of
// eig, solve (A - lambda I) v = 0 per eigenvalue via the augmented-system
// technique, storing the eigenvectors column-wise into r. Diagonal A takes the
// permuted-unit-vector fast path. matrix_any aliases real34Matrix_t /
// complex34Matrix_t (shared header); the C copy stays file-local so the Zig
// signature is chosen for convenience (no bridge rename).
// ===========================================================================
pub export fn calculateEigenvectors(matrix: *const real34Matrix_t, isComplex: bool, a: [*]align(1) real_t, q: [*]align(1) real_t, r: [*]align(1) real_t, eig: [*]align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    // real34Matrix_t and complex34Matrix_t share the {header, matrixElements}
    // layout; the complex element view reinterprets the same element pointer.
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;

    const rElems: [*]const real34_t = @ptrCast(matrix.matrixElements);
    const cElems: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);

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
                complexMagnitude(&eig[(k * sz + k) * 2], &eig[(k * sz + k) * 2 + 1], &mag_eig, realContext);
                complexMagnitude(&diagR, &diagI, &mag_diag, realContext);
                realCopy(&mag_eig, &scale);
                if (realCompareLessThan(&scale, &mag_diag)) realCopy(&mag_diag, &scale);
                if (realCompareLessThan(&scale, const_1())) realCopy(const_1(), &scale);
                realMultiply(&scale, const_1e_30(), &tol, realContext);
                if (isElementWithinTolerance(&diff_r, &diff_i, &tol, realContext)) {
                    realCopy(const_1(), &r[(j * sz + k) * 2]);
                    break;
                }
            }
        }
        return;
    }

    var freeUnknowns: u16 = 1;
    var duplicateEigenvalueCount: u16 = 0;
    const utBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
    if (allocC47Blocks(utBlocks)) |utBuf| {
        const unknownsToFill: [*]u16 = @ptrCast(utBuf);
        k = 0;
        while (k < sz) : (k += 1) {
            if (k > 0 and realCompareEqual(&eig[(k * sz + k) * 2], &eig[((k - 1) * sz + (k - 1)) * 2]) and realCompareEqual(&eig[(k * sz + k) * 2 + 1], &eig[((k - 1) * sz + (k - 1)) * 2 + 1])) {
                duplicateEigenvalueCount += 1;
                if (freeUnknowns > size) freeUnknowns = size;
            } else {
                duplicateEigenvalueCount = 0;
                freeUnknowns = 1;
                unknownsToFill[0] = 0;
            }
            const vBlocks: usize = sz * 2 * realSizeInBlocks(75) * 2;
            if (allocC47Blocks(vBlocks)) |vBuf| {
                const v: [*]align(1) real_t = @ptrCast(vBuf);
                while (true) {
                    var j: usize = 0;
                    while (j < sz * 2 * 2) : (j += 1) realSetNaN(&v[j]);

                    if (duplicateEigenvalueCount == 0) {
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
                                realCopy(if (jj == ii) const_1() else const_0(), &a[(ii * stride + jj + sz) * 2]);
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
                        var jd: usize = 0;
                        while (jd < sz) : (jd += 1) {
                            realSubtract(&a[(jd * stride + jd) * 2], &eig[(k * sz + k) * 2], &a[(jd * stride + jd) * 2], realContext);
                            realSubtract(&a[(jd * stride + jd) * 2 + 1], &eig[(k * sz + k) * 2 + 1], &a[(jd * stride + jd) * 2 + 1], realContext);
                        }
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
                    if (runtime.lastErrorCode != runtime.ERROR_SINGULAR_MATRIX) break;

                    // Advance unknownsToFill to the next free-unknown selection.
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
                        freeUnknowns += 1;
                        var ic: u16 = 0;
                        while (ic < size) : (ic += 1) unknownsToFill[ic] = ic;
                    }
                    if (freeUnknowns > size) break;
                }
                if (runtime.lastErrorCode == runtime.ERROR_SINGULAR_MATRIX) {
                    var ii: usize = 0;
                    while (ii < sz) : (ii += 1) {
                        realSetZero(&v[ii * 2]);
                        realSetZero(&v[ii * 2 + 1]);
                    }
                    runtime.lastErrorCode = runtime.ERROR_NONE;
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
pub export fn realEigenvectors(matrix: *const real34Matrix_t, res: *real34Matrix_t, ires: ?*real34Matrix_t) callconv(.c) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 4 * 2 * 4 + sz * sz * 2);
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4 * 2;
        const r = bulk + sz * sz * 4 * 2 * 2;
        const eig = bulk + sz * sz * 4 * 2 * 3;
        const previousDiagonal = bulk + sz * sz * 4 * 2 * 4;
        const elems: [*]const real34_t = @ptrCast(matrix.matrixElements);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i], &a[i * 2]);
            realSetZero(&a[i * 2 + 1]);
        }
        calculateEigenvalues(a, q, r, eig, previousDiagonal, size, true, false, &runtime.ctxtReal75);
        calculateEigenvectors(matrix, false, a, q, r, eig, &runtime.ctxtReal75);

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
                }
            }
        } else {
            ramFull("In function realEigenvectors:", "Ram full, 2be");
        }
        freeC47Blocks(bulk, bulkSize);
    } else {
        ramFull("In function realEigenvectors:", "Ram full, 3bf");
    }
}

// ===========================================================================
// complexEigenvectors (static) -- eigenvectors of a complex square matrix.
// ===========================================================================
pub export fn complexEigenvectors(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const size: u16 = matrix.header.matrixRows;
    const sz: usize = size;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const bulkSize: usize = realSizeInBlocks(75) * (sz * sz * 4 * 2 * 4 + sz * sz * 2);
    if (allocC47Blocks(bulkSize)) |bulk| {
        const a = bulk;
        const q = bulk + sz * sz * 4 * 2;
        const r = bulk + sz * sz * 4 * 2 * 2;
        const eig = bulk + sz * sz * 4 * 2 * 3;
        const previousDiagonal = bulk + sz * sz * 4 * 2 * 4;
        const elems: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);

        var i: usize = 0;
        while (i < sz * sz) : (i += 1) {
            runtime.real34ToReal(&elems[i].real, &a[i * 2]);
            runtime.real34ToReal(&elems[i].imag, &a[i * 2 + 1]);
        }
        calculateEigenvalues(a, q, r, eig, previousDiagonal, size, true, false, &runtime.ctxtReal75);
        calculateEigenvectors(@ptrCast(matrix), true, a, q, r, eig, &runtime.ctxtReal75);

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
    }
}

// createEigenVectorIf1x1 (static) -- 1x1 matrices have the trivial eigenvector
// [1]; build it directly. Returns 1 (handled), 255 (alloc failed), 0 (not 1x1).
fn createEigenVectorIf1x1(rows: u16, cols: u16, isComplex: bool) u8 {
    if (rows == 1 and cols == 1) {
        runtime.setSystemFlag(FLAG_ASLIFT);
        runtime.liftStack();
        if (!runtime.initMatrixRegister(runtime.REGISTER_X, 1, 1, isComplex)) {
            runtime.fnDrop(runtime.NOPARAM);
            runtime.displayCalcErrorMessage(runtime.ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function createEigenVectorIf1x1:", "Not enough memory for a 1\xc3\x971 matrix", null, null);
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
pub export fn fnEigenvectors(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\xc3\x97{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
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
                    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
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
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buf: [80]u8 = undefined;
                const m = bufPrintZ(&buf, "rectangular or single-element matrix or ({d}\xc3\x97{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "rectangular matrix";
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
                complexEigenvectors(&x, &res);
                if (res.matrixElements != null) {
                    // Success: lift the stack removed upstream; install the result.
                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.complexMatrixFree(&res);
                } else {
                    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnEigenvectors:", "matrix is defective: no full set of linearly independent eigenvectors", null, null);
                    return;
                }
            },
        }
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
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
// sqrt(A) = Q sqrt(L) Q^-1. All helpers are static in matrix.c; only the public
// fnMatrixSquareRoot is bridge-renamed.
// ===========================================================================

fn isRealMatrixDiagonal(matrix: *const real34Matrix_t) bool {
    const rows = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const elems: [*]const real34_t = @ptrCast(matrix.matrixElements);
    var i: usize = 0;
    while (i < rows) : (i += 1) {
        var j: usize = 0;
        while (j < cols) : (j += 1) {
            if (i != j and !runtime.real34IsZero(&elems[i * cols + j])) return false;
        }
    }
    return true;
}

fn isComplexMatrixDiagonal(matrix: *const complex34Matrix_t) bool {
    const rows = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const elems: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);
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
fn verifySqrtMatrix(inputReal: ?*const real34Matrix_t, resultReal: ?*const real34Matrix_t, inputComplex: ?*const complex34Matrix_t, resultComplex: ?*const complex34Matrix_t) bool {
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

        multiplyComplexMatrices(&resultCopy, &resultCopy, &residual);
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
            verified = realCompareLessEqual(&residualNorm, &tolerance);
            runtime.complexMatrixFree(&residual);
        }
    }
    if (inputCopy.matrixElements != null) runtime.complexMatrixFree(&inputCopy);
    if (resultCopy.matrixElements != null) runtime.complexMatrixFree(&resultCopy);
    return verified;
}

fn sqrtRealMatrixEigen(matrix: *const real34Matrix_t, res: *real34Matrix_t) void {
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
                if (realCompareGreaterThan(&val, &tol)) {
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
                if (realCompareGreaterThan(&val, &tol)) {
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
        multiplyRealMatrices(&Q, &Lambda, &tmp);
        if (tmp.matrixElements == null) {
            failed = true;
            break :blk;
        }
        multiplyRealMatrices(&tmp, &Qinv, res);
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

fn sqrtComplexMatrixEigen(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) void {
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
        multiplyComplexMatrices(&Q, &Lambda, &tmp);
        if (tmp.matrixElements == null) {
            failed = true;
            break :blk;
        }
        multiplyComplexMatrices(&tmp, &Qinv, res);
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

pub export fn sqrtRealMatrix(matrix: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;

    const elems: [*]const real34_t = @ptrCast(matrix.matrixElements);
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

pub export fn sqrtComplexMatrix(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const n = matrix.header.matrixRows;
    const nn: usize = n;
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;

    if (isComplexMatrixDiagonal(matrix)) {
        if (!runtime.complexMatrixInit(res, n, n)) return;
        const me: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);
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

fn sqrtNoConverge() void {
    runtime.temporaryInformation = runtime.TI_NO_INFO;
    if (runtime.programRunStop == runtime.PGM_WAITING) runtime.programRunStop = runtime.PGM_STOPPED;
}

// ===========================================================================
// fnMatrixSquareRoot (M.SQRT) -- the public command. Real input falls back to a
// complex root (and auto-downgrades to real) when FL_CPXRES is set.
// ===========================================================================
pub export fn fnMatrixSquareRoot(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    if (!runtime.saveLastX()) return;

    const dt = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (dt == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buf: [64]u8 = undefined;
                const m = bufPrintZ(&buf, "not a square matrix ({d}\xc3\x97{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not square";
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
                                runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnMatrixSquareRoot:", "matrix has no square root, or iteration failed to converge", null, null);
                            }
                        } else {
                            sqrtNoConverge();
                        }
                    }
                } else {
                    runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
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
            runtime.displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buf: [64]u8 = undefined;
                const m = bufPrintZ(&buf, "not a square matrix ({d}\xc3\x97{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not square";
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
                    runtime.displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnMatrixSquareRoot:", "matrix has no square root, or iteration failed to converge", null, null);
                }
            } else {
                sqrtNoConverge();
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
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
pub export fn real_QR_decomposition(matrix: *const real34Matrix_t, q: *real34Matrix_t, r: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const n2: usize = @as(usize, rows) * matrix.header.matrixColumns;
    const blocks: usize = n2 * realSizeInBlocks(75) * 2 * 3;
    if (allocC47Blocks(blocks)) |mat| {
        const matq = mat + n2 * 2;
        const matr = mat + n2 * 2 * 2;
        const elems: [*]const real34_t = @ptrCast(matrix.matrixElements);
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

pub export fn complex_QR_decomposition(matrix: *const complex34Matrix_t, q: *complex34Matrix_t, r: *complex34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    if (matrix.header.matrixRows != matrix.header.matrixColumns) return;
    const n2: usize = @as(usize, rows) * matrix.header.matrixColumns;
    const blocks: usize = n2 * realSizeInBlocks(75) * 2 * 3;
    if (allocC47Blocks(blocks)) |mat| {
        const matq = mat + n2 * 2;
        const matr = mat + n2 * 2 * 2;
        const elems: [*]const runtime.complex34_t = @ptrCast(matrix.matrixElements);
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
