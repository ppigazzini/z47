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
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

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

inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
inline fn stringToReal(source: [*:0]const u8, destination: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}
inline fn realIsNegativeA(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}

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
inline fn const_0() *align(1) const real_t {
    return cstR(OFF_const_0);
}
inline fn const_1() *align(1) const real_t {
    return cstR(OFF_const_1);
}
inline fn const_2() *align(1) const real_t {
    return cstR(OFF_const_2);
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
