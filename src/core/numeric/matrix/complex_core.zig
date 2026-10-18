// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the complex dense linear-algebra core of
// src/c47/mathematics/matrix.c: invCpxMat (in-place inverse of a cplx_t matrix
// via LU + pivoting solve) and mulCpxMat (cplx_t matrix product), with the
// shared partial-pivoting LU worker luCpxMat (exported for
// complex_LU_decomposition to reuse) and the private
// complex_matrix_pivoting_solve back-substitution. These back the
// matrix-by-matrix divide and the matrix inverse; both are exported under their
// canonical names so the divide / invert owners reach them. The upstream copies
// are file-local statics, so no bridge rename is needed.

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_wp34s = @import("../special/wp34s.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == TO_BLOCKS(sizeof(real_t)) == 15; a cplx_t is two
// of them, so a cplx_t scratch of n elements is n * 15 * 2 blocks.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

extern var displayFormatDigits: u8;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function invCpxMat:", info, null, null);
    }
}

// In-place partial-pivoting LU of a cplx_t size*size matrix. Exported so
// complex_LU_decomposition can reuse it; the upstream copy is a file-local
// static, so the global Zig symbol does not clash with it.
// `p` is the caller's pivot vector, one entry per column; a caller that does not
// want the pivots passes NULL. An update that cancels to below the tolerance
// fraction of its previous value is set to zero: 10^tolerance_exponent when that
// is given, else 10^(2 - digits) of the context.
pub export fn luCpxMat(tmp_mat: [*]cplx_t, size: u16, p: ?[*]u16, tolerance_exponent: i32, real_context: *realContext_t) callconv(.c) bool {
    const n: usize = size;
    var max: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var tolerance: real_t = undefined;
    var prod: cplx_t = undefined;
    var previous: cplx_t = undefined;

    runtime.realSetOne(&tolerance);
    tolerance.exponent = if (tolerance_exponent != 0) tolerance_exponent else 2 - real_context.digits;
    var k: usize = 0;
    while (k < n) : (k += 1) {
        // Find the pivot row.
        var pvt: usize = k;
        runtime.complexMagnitude(&tmp_mat[k * n + k], &max, real_context);
        var j: usize = k + 1;
        while (j < n) : (j += 1) {
            runtime.complexMagnitude(&tmp_mat[j * n + k], &u, real_context);
            if (math_comparison_reals.realCompareGreaterThan(&u, &max)) {
                realCopy(&u, &max);
                pvt = j;
            }
        }
        if (p) |pivots| {
            pivots[k] = @intCast(pvt);
        }

        // Pivot if required.
        if (pvt != k) {
            var i: usize = 0;
            while (i < n) : (i += 1) {
                realCopy(&tmp_mat[k * n + i].Real, &t);
                realCopy(&tmp_mat[pvt * n + i].Real, &tmp_mat[k * n + i].Real);
                realCopy(&t, &tmp_mat[pvt * n + i].Real);
                realCopy(&tmp_mat[k * n + i].Imag, &t);
                realCopy(&tmp_mat[pvt * n + i].Imag, &tmp_mat[k * n + i].Imag);
                realCopy(&t, &tmp_mat[pvt * n + i].Imag);
            }
        }

        // Check for singular.
        if (runtime.realIsZero(&tmp_mat[k * n + k].Real) and runtime.realIsZero(&tmp_mat[k * n + k].Imag)) {
            return false;
        }

        // Lower triangular elements for column k.
        var i: usize = k + 1;
        while (i < n) : (i += 1) {
            runtime.divComplexComplex(&tmp_mat[i * n + k], &tmp_mat[k * n + k], &tmp_mat[i * n + k], real_context);
        }
        // Update the upper triangular elements.
        i = k + 1;
        while (i < n) : (i += 1) {
            j = k + 1;
            while (j < n) : (j += 1) {
                runtime.mulComplexComplex(&tmp_mat[i * n + k], &tmp_mat[k * n + j], &prod, real_context);
                realCopy(&tmp_mat[i * n + j].Real, &previous.Real);
                realCopy(&tmp_mat[i * n + j].Imag, &previous.Imag);
                runtime.realSubtract(&previous.Real, &prod.Real, &tmp_mat[i * n + j].Real, real_context);
                runtime.realSubtract(&previous.Imag, &prod.Imag, &tmp_mat[i * n + j].Imag, real_context);
                runtime.complexMagnitude(&tmp_mat[i * n + j], &t, real_context);
                runtime.complexMagnitude(&previous, &u, real_context);
                runtime.realDivide(&t, &u, &t, real_context); // condition number
                if (math_comparison_reals.realCompareAbsLessThan(&t, &tolerance)) {
                    runtime.realSetZero(&tmp_mat[i * n + j].Real); // prevent ill-conditionedness
                    runtime.realSetZero(&tmp_mat[i * n + j].Imag);
                }
            }
        }
    }
    return true;
}

// Solve A x = b given the LU decomposition and pivot vector (forward then back
// substitution), all on cplx_t arrays.
fn complexMatrixPivotingSolve(lu: [*]const cplx_t, n_in: u16, b: [*]cplx_t, pivot: [*]const u16, x: [*]cplx_t, real_context: *realContext_t) void {
    const n: usize = n_in;
    var r: cplx_t = undefined;
    var t: cplx_t = undefined;

    // Solve L y = b.
    var k: usize = 0;
    while (k < n) : (k += 1) {
        if (k != pivot[k]) {
            const pk: usize = pivot[k];
            var swap: real_t = undefined;
            realCopy(&b[k].Real, &swap);
            realCopy(&b[pk].Real, &b[k].Real);
            realCopy(&swap, &b[pk].Real);
            realCopy(&b[k].Imag, &swap);
            realCopy(&b[pk].Imag, &b[k].Imag);
            realCopy(&swap, &b[pk].Imag);
        }
        realCopy(&b[k].Real, &x[k].Real);
        realCopy(&b[k].Imag, &x[k].Imag);
        var i: usize = 0;
        while (i < k) : (i += 1) {
            realCopy(&lu[k * n + i].Real, &r.Real);
            realCopy(&lu[k * n + i].Imag, &r.Imag);
            runtime.mulComplexComplex(&r, &x[i], &t, real_context);
            runtime.realSubtract(&x[k].Real, &t.Real, &x[k].Real, real_context);
            runtime.realSubtract(&x[k].Imag, &t.Imag, &x[k].Imag, real_context);
        }
    }

    // Solve U x = y.
    var kk: usize = n;
    while (kk > 0) {
        kk -= 1;
        var i: usize = kk + 1;
        while (i < n) : (i += 1) {
            realCopy(&lu[kk * n + i].Real, &r.Real);
            realCopy(&lu[kk * n + i].Imag, &r.Imag);
            runtime.mulComplexComplex(&r, &x[i], &t, real_context);
            runtime.realSubtract(&x[kk].Real, &t.Real, &x[kk].Real, real_context);
            runtime.realSubtract(&x[kk].Imag, &t.Imag, &x[kk].Imag, real_context);
        }
        realCopy(&lu[kk * n + kk].Real, &r.Real);
        realCopy(&lu[kk * n + kk].Imag, &r.Imag);
        runtime.divComplexComplex(&x[kk], &r, &x[kk], real_context);
    }
}

pub export fn mulCpxMat(y: [*]const cplx_t, x: [*]const cplx_t, size_y: u16, size_yx: u16, size_x: u16, res: [*]cplx_t, real_context: *realContext_t) callconv(.c) void {
    const sy: usize = size_y;
    const syx: usize = size_yx;
    const sx: usize = size_x;
    var prod: cplx_t = undefined;

    var i: usize = 0;
    while (i < sy) : (i += 1) {
        var j: usize = 0;
        while (j < sx) : (j += 1) {
            const sum = &res[i * sx + j];
            runtime.realSetZero(&sum.Real);
            runtime.realSetZero(&sum.Imag);
            var k: usize = 0;
            while (k < syx) : (k += 1) {
                // Always the full complex multiplication, for consistency.
                runtime.mulComplexComplex(&y[i * syx + k], &x[k * sx + j], &prod, real_context);
                runtime.realAdd(&sum.Real, &prod.Real, &sum.Real, real_context);
                runtime.realAdd(&sum.Imag, &prod.Imag, &sum.Imag, real_context);
            }
        }
    }
}

// Invert the cplx_t n*n matrix in place, through its LU decomposition and one
// pivoting solve per column. tolerance_exponent is passed on to luCpxMat.
pub export fn invCpxMat(matrix: [*]cplx_t, n_in: u16, tolerance_exponent: i32, real_context: *realContext_t) callconv(.c) bool {
    const n: usize = n_in;
    const lu_blocks = n * n * real_size_in_blocks * 2;
    const pivot_blocks = (n * @sizeOf(u16) + 3) >> 2;
    const vec_blocks = n * real_size_in_blocks * 2;

    if (runtime.allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]cplx_t = @ptrCast(@alignCast(lu_raw));
        if (runtime.allocC47Blocks(pivot_blocks)) |pivots_raw| {
            const pivots: [*]u16 = @ptrCast(@alignCast(pivots_raw));
            var i: usize = 0;
            while (i < n * n) : (i += 1) {
                realCopy(&matrix[i].Real, &lu[i].Real);
                realCopy(&matrix[i].Imag, &lu[i].Imag);
            }
            if (!luCpxMat(lu, n_in, pivots, tolerance_exponent, real_context)) {
                runtime.freeC47Blocks(lu_raw, lu_blocks);
                runtime.freeC47Blocks(pivots_raw, pivot_blocks);
                return false;
            }

            {
                var max_val: real_t = undefined;
                var min_val: real_t = undefined;
                var p: real_t = undefined;
                var q: real_t = undefined;
                runtime.complexMagnitude(&lu[0], &p, real_context);
                realCopy(&p, &max_val);
                realCopy(&p, &min_val);
                i = 1;
                while (i < n) : (i += 1) {
                    runtime.complexMagnitude(&lu[i * n + i], &p, real_context);
                    if (runtime.realCompareLessThan(&p, &min_val)) {
                        realCopy(&p, &min_val);
                    }
                    if (math_comparison_reals.realCompareGreaterThan(&p, &max_val)) {
                        realCopy(&p, &max_val);
                    }
                }
                math_wp34s.WP34S_Log10(&max_val, &p, real_context);
                math_wp34s.WP34S_Log10(&min_val, &q, real_context);
                runtime.realSubtract(&p, &q, &p, real_context);
                runtime.int32ToReal(33 - @as(i32, displayFormatDigits), &q);
                if (math_comparison_reals.realCompareLessEqual(&q, &p)) {
                    runtime.temporaryInformation = runtime.TI_INACCURATE;
                }
            }

            if (runtime.allocC47Blocks(vec_blocks)) |x_raw| {
                const x: [*]cplx_t = @ptrCast(@alignCast(x_raw));
                if (runtime.allocC47Blocks(vec_blocks)) |b_raw| {
                    const b: [*]cplx_t = @ptrCast(@alignCast(b_raw));
                    i = 0;
                    while (i < n) : (i += 1) {
                        var j: usize = 0;
                        while (j < n) : (j += 1) {
                            if (i == j) {
                                runtime.realSetOne(&b[j].Real);
                            } else {
                                runtime.realSetZero(&b[j].Real);
                            }
                            runtime.realSetZero(&b[j].Imag);
                        }
                        complexMatrixPivotingSolve(lu, n_in, b, pivots, x, real_context);
                        j = 0;
                        while (j < n) : (j += 1) {
                            realCopy(&x[j].Real, &matrix[j * n + i].Real);
                            realCopy(&x[j].Imag, &matrix[j * n + i].Imag);
                        }
                    }
                    runtime.freeC47Blocks(b_raw, vec_blocks);
                } else {
                    reportRamFull("Ram full, 1q");
                }
                runtime.freeC47Blocks(x_raw, vec_blocks);
            } else {
                reportRamFull("Ram full, 2r");
            }
            runtime.freeC47Blocks(pivots_raw, pivot_blocks);
        } else {
            reportRamFull("Ram full, 3s");
        }
        runtime.freeC47Blocks(lu_raw, lu_blocks);
    } else {
        reportRamFull("Ram full, 4t");
    }
    return runtime.lastErrorCode == runtime.ERROR_NONE;
}
