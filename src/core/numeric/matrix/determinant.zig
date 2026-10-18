// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
// Zig port of the determinant cluster of src/c47/mathematics/matrix.c:
// detRealMatrix / detComplexMatrix, with their static workers. A real matrix is
// first eliminated fraction-free (detRealMatExact), which is exact while every
// minor fits in 75 digits and so gives an exactly singular matrix exactly zero;
// where a step rounds, both kinds fall back to detCpxMat, which packs the matrix
// into a cplx_t scratch array, runs the shared partial-pivoting complex LU
// (luCpxMat in complex_core), multiplies the diagonal and flips the sign per
// pivot swap. realMatExactlySingular is the exact test the LU, inverse, divide
// and linear-equation owners consult before they factor a real matrix.

const runtime = @import("../command_wrappers/runtime.zig");
// The one complex LU worker, reached by its exported name rather than by
// @import: complex_core sits above this owner in the module graph and importing
// it closes a 38-file cycle through the command-wrapper dispatcher.
extern fn luCpxMat(tmp_mat: [*]runtime.cplx_t, size: u16, p: ?[*]u16, tolerance_exponent: i32, real_context: *runtime.realContext_t) bool;
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == TO_BLOCKS(sizeof(real_t)) == 15; a packed real_t
// occupies exactly that, so the scratch arrays index cplx_t with native stride.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

// decContext.h: the status bit a rounded operation raises.
const DEC_Inexact: u32 = 0x00000020;

// matrix.c block allocator.
extern fn allocC47Blocks(size_in_blocks: usize) callconv(.c) ?*anyopaque;
extern fn freeC47Blocks(ptr: ?*anyopaque, size_in_blocks: usize) callconv(.c) void;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime function_name: [*:0]const u8, comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, info, null, null);
    }
}

// Determinant of a cplx_t size*size matrix. Mirrors the static detCpxMat in
// matrix.c.
fn detCpxMat(matrix: [*]const cplx_t, size: u16, res: *cplx_t, real_context: *realContext_t) void {
    const n: usize = size;
    const lu_blocks = n * n * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]cplx_t = @ptrCast(@alignCast(lu_raw));
        @memcpy(lu[0 .. n * n], matrix[0 .. n * n]);
        const p_blocks = (n * @sizeOf(u16) + 3) >> 2;
        if (allocC47Blocks(p_blocks)) |p_raw| {
            const p: [*]u16 = @ptrCast(@alignCast(p_raw));
            var t: cplx_t = undefined;
            runtime.realSetOne(&t.Real);
            runtime.realSetZero(&t.Imag);
            if (luCpxMat(lu, size, p, 0, real_context)) {
                var i: usize = 0;
                while (i < n) : (i += 1) {
                    runtime.mulComplexComplex(&t, &lu[i * n + i], &t, real_context);
                }
                i = 0;
                while (i < n) : (i += 1) {
                    if (p[i] != @as(u16, @intCast(i))) {
                        runtime.realChangeSign(&t.Real);
                        runtime.realChangeSign(&t.Imag);
                    }
                }
                realCopy(&t.Real, &res.Real);
                realCopy(&t.Imag, &res.Imag);
            } else { // singular
                runtime.realSetZero(&res.Real);
                runtime.realSetZero(&res.Imag);
            }
            freeC47Blocks(p_raw, p_blocks);
        } else {
            reportRamFull("In function detCpxMat:", "Ram full, 1o");
            runtime.realSetNaN(&res.Real);
            runtime.realSetNaN(&res.Imag);
        }
        freeC47Blocks(lu_raw, lu_blocks);
    } else {
        reportRamFull("In function detCpxMat:", "Ram full, 2p");
        runtime.realSetNaN(&res.Real);
        runtime.realSetNaN(&res.Imag);
    }
}

// Determinant of a real matrix by fraction-free (Bareiss) elimination, and
// whether it is exact.
//
// After step k each element below and right of the pivot is a minor of order
// k + 2, and the division by the previous pivot is exact. The difference of two
// products before it is the new minor times the previous pivot, at most 150
// digits in the 159 of its context, so no step rounds while every minor fits in
// 75 digits, and an exactly singular matrix gives exactly zero. A zero pivot is
// replaced by adding the first later row with a nonzero element in its column,
// which changes the minors but not the determinant.
//
// `matrix` is the work matrix, with zero imaginary parts; its real parts are
// overwritten. `size` is at least two. `res` is set when the return is true.
// Returns false for a NaN or infinite element, or as soon as a step rounds.
fn detRealMatExact(matrix: [*]cplx_t, size: u16, res: *real_t) bool {
    var context: realContext_t = runtime.ctxtReal75;
    var difference: abi.Real159 = undefined;
    const n: usize = size;
    const end: usize = n * n;
    var pivot: *const real_t = runtime.z47_math_wrappers_const_1();

    var e: usize = 0;
    while (e < end) : (e += 1) {
        if (runtime.realIsSpecial(&matrix[e].Real)) {
            return false;
        }
    }
    context.status = 0;
    var k: usize = 0;
    while (k < n) : (k += 1) { // k is the offset of the pivot column in a row
        const row_k: usize = k * n;
        var row_p: usize = row_k;
        while (runtime.realIsZero(&matrix[row_p + k].Real)) {
            row_p += n;
            if (row_p == end) {
                runtime.realSetZero(res);
                return true;
            }
        }
        if (row_p != row_k) {
            var j: usize = k;
            while (j < n) : (j += 1) {
                runtime.realAdd(&matrix[row_k + j].Real, &matrix[row_p + j].Real, &matrix[row_k + j].Real, &context);
            }
        }
        var row_i: usize = row_k + n;
        while (row_i < end) : (row_i += n) {
            runtime.realChangeSign(&matrix[row_i + k].Real);
            var j: usize = k + 1;
            while (j < n) : (j += 1) {
                context.digits = 159;
                runtime.realMultiply(&matrix[row_i + j].Real, &matrix[row_k + k].Real, difference.ptr(), &context);
                runtime.realFMA(&matrix[row_i + k].Real, &matrix[row_k + j].Real, difference.ptr(), difference.ptr(), &context);
                context.digits = 75;
                runtime.realDivide(difference.ptr(), pivot, &matrix[row_i + j].Real, &context);
            }
        }
        if (context.status & DEC_Inexact != 0) {
            return false;
        }
        pivot = &matrix[row_k + k].Real;
    }
    realCopy(pivot, res);
    return true;
}

/// Whether a real matrix is exactly singular, by the fraction-free elimination
/// of detRealMatExact.
///
/// An LU of a matrix of 34-digit numbers that is singular to the last digit can
/// leave a residue where the pivot is zero, about 1E-72 of the matrix at 75
/// digits, and then accepts the matrix. Where every minor fits in 75 digits the
/// elimination is exact and gives exactly zero for it. Where a step rounds, the
/// LU takes over. False for a matrix of order one, where a step rounds, or where
/// its work matrix cannot be allocated.
pub fn realMatExactlySingular(matrix: *const real34Matrix_t) bool {
    const n: u16 = matrix.header.matrixColumns;
    const nn: usize = @as(usize, n) * n;
    const work_blocks = nn * real_size_in_blocks * 2;
    var det: real_t = undefined;
    var singular = false;

    if (n > 1) {
        if (allocC47Blocks(work_blocks)) |work_raw| {
            const work: [*]cplx_t = @ptrCast(@alignCast(work_raw));
            const me = constRealElems(matrix);
            var i: usize = 0;
            while (i < nn) : (i += 1) {
                runtime.real34ToReal(&me[i], &work[i].Real);
                runtime.realSetZero(&work[i].Imag);
            }
            singular = detRealMatExact(work, n, &det) and runtime.realIsZero(&det);
            freeC47Blocks(work_raw, work_blocks);
        }
    }
    return singular;
}

pub export fn detRealMatrix(matrix: *const real34Matrix_t, res: *real34_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;
    if (matrix.header.matrixRows != n) {
        runtime.realToReal34(runtime.const_NaN, res);
        return;
    }
    const me = constRealElems(matrix);
    if (n == 1) {
        real34Copy(&me[0], res);
        return;
    }

    const nn = @as(usize, n) * @as(usize, n);
    const lu_blocks = nn * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]cplx_t = @ptrCast(@alignCast(lu_raw));
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            runtime.real34ToReal(&me[i], &lu[i].Real);
            runtime.realSetZero(&lu[i].Imag);
        }
        var det: cplx_t = undefined;
        if (!detRealMatExact(lu, n, &det.Real)) {
            i = 0;
            while (i < nn) : (i += 1) {
                runtime.real34ToReal(&me[i], &lu[i].Real);
            }
            detCpxMat(lu, n, &det, &runtime.ctxtReal75);
        }
        freeC47Blocks(lu_raw, lu_blocks);
        runtime.realToReal34(&det.Real, res);
    } else {
        reportRamFull("In function detRealMatrix:", "Ram full");
        runtime.realToReal34(runtime.const_NaN, res);
    }
}

pub export fn detComplexMatrix(matrix: *const complex34Matrix_t, res_r: *real34_t, res_i: *real34_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;
    if (matrix.header.matrixRows != n) {
        runtime.realToReal34(runtime.const_NaN, res_r);
        runtime.realToReal34(runtime.const_NaN, res_i);
        return;
    }
    const me = constComplexElems(matrix);
    if (n == 1) {
        real34Copy(&me[0].real, res_r);
        real34Copy(&me[0].imag, res_i);
        return;
    }

    const nn = @as(usize, n) * @as(usize, n);
    const lu_blocks = nn * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]cplx_t = @ptrCast(@alignCast(lu_raw));
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            runtime.real34ToReal(&me[i].real, &lu[i].Real);
            runtime.real34ToReal(&me[i].imag, &lu[i].Imag);
        }
        var det: cplx_t = undefined;
        detCpxMat(lu, n, &det, &runtime.ctxtReal75);
        freeC47Blocks(lu_raw, lu_blocks);
        runtime.realToReal34(&det.Real, res_r);
        runtime.realToReal34(&det.Imag, res_i);
    } else {
        reportRamFull("In function detComplexMatrix:", "Ram full");
        runtime.realToReal34(runtime.const_NaN, res_r);
        runtime.realToReal34(runtime.const_NaN, res_i);
    }
}
