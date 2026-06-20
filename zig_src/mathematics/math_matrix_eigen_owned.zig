// SPDX-License-Identifier: GPL-3.0-only
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
const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cstR(comptime off: u32) *align(1) const real_t {
    return @ptrCast(constants + off);
}
const OFF_const_0: u32 = 1708;
const OFF_const_1: u32 = 4368;
const OFF_const_2: u32 = 4440;
const OFF_const_1on2: u32 = 4092;
const OFF_const_1e_6: u32 = 4008;
inline fn const_0() *align(1) const real_t {
    return cstR(OFF_const_0);
}
inline fn const_1() *align(1) const real_t {
    return cstR(OFF_const_1);
}
inline fn const_2() *align(1) const real_t {
    return cstR(OFF_const_2);
}
inline fn const_1on2() *align(1) const real_t {
    return cstR(OFF_const_1on2);
}
inline fn const_1e_6() *align(1) const real_t {
    return cstR(OFF_const_1e_6);
}
const OFF_const_1e_32: u32 = 5200;
inline fn const_1e_32() *align(1) const real_t {
    return cstR(OFF_const_1e_32);
}

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

        // ---- dedicated 2x2 block scan ----
        var first_unconverged: i32 = -1;
        var last_unconverged: i32 = -1;
        {
            var i: usize = 0;
            while (i + 1 < sz) : (i += 1) {
                var offdiag_mag: real_t = undefined;
                complexMagnitude(&eig[((i + 1) * sz + i) * 2], &eig[((i + 1) * sz + i) * 2 + 1], &offdiag_mag, realContext);
                var threshold: real_t = undefined;
                realSetOne(&threshold);
                threshold.exponent -= blockDetectionTolerance;
                if (!realCompareLessThan(&offdiag_mag, &threshold)) {
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
                var threshold: real_t = undefined;
                realSetOne(&threshold);
                threshold.exponent -= blockDetectionTolerance;
                if (!realCompareLessThan(&offdiag_mag, &threshold)) {
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
                        runtime.setSystemFlag(FLAG_ASLIFT);
                        runtime.liftStack();
                        runtime.convertComplex34MatrixToComplex34MatrixRegister(&cresRow, runtime.REGISTER_X);
                        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
                        runtime.complexMatrixFree(&cresRow);
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
                    runtime.setSystemFlag(FLAG_ASLIFT);
                    runtime.liftStack();
                    runtime.convertReal34MatrixToReal34MatrixRegister(&resRow, runtime.REGISTER_X);
                    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
                    runtime.realMatrixFree(&resRow);
                }
                runtime.realMatrixFree(&res);
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
            complexEigenvalues(&x, &res);
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
            runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, -1, -1);
            doneAdjusting = true;
            var resRow: complex34Matrix_t = undefined;
            extractDiagonalToRowComplex34Matrix(&res, &resRow);
            runtime.setSystemFlag(FLAG_ASLIFT);
            runtime.liftStack();
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&resRow, runtime.REGISTER_X);
            runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
            runtime.complexMatrixFree(&resRow);
            runtime.complexMatrixFree(&res);
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
