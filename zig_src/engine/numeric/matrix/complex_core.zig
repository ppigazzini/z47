// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
// Zig port of the complex dense linear-algebra core of
// src/c47/mathematics/matrix.c: invCpxMat (in-place inverse of an
// interleaved-complex matrix via LU + pivoting solve) and mulCpxMat
// (interleaved-complex matrix product), with the shared partial-pivoting LU
// worker luCpxMat (exported for complex_LU_decomposition to reuse) and the
// private complex_matrix_pivoting_solve back-substitution. These back the
// matrix-by-matrix divide and the matrix inverse; both are exported under their
// canonical names so the later divide / invert owners reach them. The upstream
// copies are file-local statics, so no bridge rename is needed.

const runtime = @import("../command_wrappers_runtime.zig");
const math_comparison_reals = @import("../comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("../special/wp34s.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == TO_BLOCKS(sizeof(real_t)) == 15.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

extern var displayFormatDigits: u8;

// const_1e_37 == ((real_t *)(constants + 4436)) in constantPointers.h.
inline fn const_1e_37() *const real_t {
    return consts.c4436();
}

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function invCpxMat:", info, null, null);
    }
}

// In-place partial-pivoting LU of an interleaved-complex size*size matrix.
// Exported so complex_LU_decomposition can reuse it; the upstream copy is a
// file-local static, so the global Zig symbol does not clash with it.
pub export fn luCpxMat(tmp_mat: [*]real_t, size: u16, p: [*]u16, real_context: *runtime.realContext_t) callconv(.c) bool {
    const n: usize = size;
    var max: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;

    var k: usize = 0;
    while (k < n) : (k += 1) {
        var pvt: usize = k;
        runtime.complexMagnitude(&tmp_mat[(k * n + k) * 2], &tmp_mat[(k * n + k) * 2 + 1], &max, real_context);
        var j: usize = k + 1;
        while (j < n) : (j += 1) {
            runtime.complexMagnitude(&tmp_mat[(j * n + k) * 2], &tmp_mat[(j * n + k) * 2 + 1], &u, real_context);
            if (math_comparison_reals.realCompareGreaterThan(&u, &max)) {
                realCopy(&u, &max);
                pvt = j;
            }
        }
        p[k] = @intCast(pvt);

        if (pvt != k) {
            var i: usize = 0;
            while (i < n) : (i += 1) {
                realCopy(&tmp_mat[(k * n + i) * 2], &t);
                realCopy(&tmp_mat[(pvt * n + i) * 2], &tmp_mat[(k * n + i) * 2]);
                realCopy(&t, &tmp_mat[(pvt * n + i) * 2]);
                realCopy(&tmp_mat[(k * n + i) * 2 + 1], &t);
                realCopy(&tmp_mat[(pvt * n + i) * 2 + 1], &tmp_mat[(k * n + i) * 2 + 1]);
                realCopy(&t, &tmp_mat[(pvt * n + i) * 2 + 1]);
            }
        }

        if (runtime.realIsZero(&tmp_mat[(k * n + k) * 2]) and runtime.realIsZero(&tmp_mat[(k * n + k) * 2 + 1])) {
            return false;
        }

        var i: usize = k + 1;
        while (i < n) : (i += 1) {
            runtime.divComplexComplex(&tmp_mat[(i * n + k) * 2], &tmp_mat[(i * n + k) * 2 + 1], &tmp_mat[(k * n + k) * 2], &tmp_mat[(k * n + k) * 2 + 1], &t, &u, real_context);
            realCopy(&t, &tmp_mat[(i * n + k) * 2]);
            realCopy(&u, &tmp_mat[(i * n + k) * 2 + 1]);
        }
        i = k + 1;
        while (i < n) : (i += 1) {
            j = k + 1;
            while (j < n) : (j += 1) {
                runtime.mulComplexComplex(&tmp_mat[(i * n + k) * 2], &tmp_mat[(i * n + k) * 2 + 1], &tmp_mat[(k * n + j) * 2], &tmp_mat[(k * n + j) * 2 + 1], &t, &u, real_context);
                realCopy(&tmp_mat[(i * n + j) * 2], &v);
                realCopy(&tmp_mat[(i * n + j) * 2 + 1], &max);
                runtime.realSubtract(&v, &t, &tmp_mat[(i * n + j) * 2], real_context);
                runtime.realSubtract(&max, &u, &tmp_mat[(i * n + j) * 2 + 1], real_context);
                runtime.realDivide(&tmp_mat[(i * n + j) * 2], &v, &t, &runtime.ctxtReal39);
                runtime.realDivide(&tmp_mat[(i * n + j) * 2 + 1], &max, &u, &runtime.ctxtReal39);
                if (math_comparison_reals.realCompareAbsLessThan(&t, const_1e_37())) {
                    runtime.realSetZero(&tmp_mat[(i * n + j) * 2]);
                }
                if (math_comparison_reals.realCompareAbsLessThan(&u, const_1e_37())) {
                    runtime.realSetZero(&tmp_mat[(i * n + j) * 2 + 1]);
                }
            }
        }
    }
    return true;
}

// Solve A x = b given the LU decomposition and pivot vector (forward then back
// substitution), all on interleaved-complex real_t arrays.
fn complexMatrixPivotingSolve(lu: [*]const real_t, n_in: u16, b: [*]real_t, pivot: [*]const u16, x: [*]real_t, real_context: *runtime.realContext_t) void {
    const n: usize = n_in;
    var rr: real_t = undefined;
    var ri: real_t = undefined;
    var tr: real_t = undefined;
    var ti: real_t = undefined;

    // Solve L y = b.
    var k: usize = 0;
    while (k < n) : (k += 1) {
        if (k != pivot[k]) {
            const pk: usize = pivot[k];
            var swap: real_t = undefined;
            realCopy(&b[k * 2], &swap);
            realCopy(&b[pk * 2], &b[k * 2]);
            realCopy(&swap, &b[pk * 2]);
            realCopy(&b[k * 2 + 1], &swap);
            realCopy(&b[pk * 2 + 1], &b[k * 2 + 1]);
            realCopy(&swap, &b[pk * 2 + 1]);
        }
        realCopy(&b[k * 2], &x[k * 2]);
        realCopy(&b[k * 2 + 1], &x[k * 2 + 1]);
        var i: usize = 0;
        while (i < k) : (i += 1) {
            realCopy(&lu[(k * n + i) * 2], &rr);
            realCopy(&lu[(k * n + i) * 2 + 1], &ri);
            runtime.mulComplexComplex(&rr, &ri, &x[i * 2], &x[i * 2 + 1], &tr, &ti, real_context);
            runtime.realSubtract(&x[k * 2], &tr, &x[k * 2], real_context);
            runtime.realSubtract(&x[k * 2 + 1], &ti, &x[k * 2 + 1], real_context);
        }
    }

    // Solve U x = y.
    var kk: usize = n;
    while (kk > 0) {
        kk -= 1;
        var i: usize = kk + 1;
        while (i < n) : (i += 1) {
            realCopy(&lu[(kk * n + i) * 2], &rr);
            realCopy(&lu[(kk * n + i) * 2 + 1], &ri);
            runtime.mulComplexComplex(&rr, &ri, &x[i * 2], &x[i * 2 + 1], &tr, &ti, real_context);
            runtime.realSubtract(&x[kk * 2], &tr, &x[kk * 2], real_context);
            runtime.realSubtract(&x[kk * 2 + 1], &ti, &x[kk * 2 + 1], real_context);
        }
        realCopy(&lu[(kk * n + kk) * 2], &rr);
        realCopy(&lu[(kk * n + kk) * 2 + 1], &ri);
        runtime.divComplexComplex(&x[kk * 2], &x[kk * 2 + 1], &rr, &ri, &x[kk * 2], &x[kk * 2 + 1], real_context);
    }
}

pub export fn mulCpxMat(y: [*]const real_t, x: [*]const real_t, size_y: u16, size_yx: u16, size_x: u16, res: [*]real_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const sy: usize = size_y;
    const syx: usize = size_yx;
    const sx: usize = size_x;
    var prodr: real_t = undefined;
    var prodi: real_t = undefined;

    var i: usize = 0;
    while (i < sy) : (i += 1) {
        var j: usize = 0;
        while (j < sx) : (j += 1) {
            const sumr = &res[(i * sx + j) * 2];
            const sumi = &res[(i * sx + j) * 2 + 1];
            runtime.realSetZero(sumr);
            runtime.realSetZero(sumi);
            var k: usize = 0;
            while (k < syx) : (k += 1) {
                runtime.mulComplexComplex(&y[(i * syx + k) * 2], &y[(i * syx + k) * 2 + 1], &x[(k * sx + j) * 2], &x[(k * sx + j) * 2 + 1], &prodr, &prodi, real_context);
                runtime.realAdd(sumr, &prodr, sumr, real_context);
                runtime.realAdd(sumi, &prodi, sumi, real_context);
            }
        }
    }
}

pub export fn invCpxMat(matrix: [*]real_t, n_in: u16, real_context: *runtime.realContext_t) callconv(.c) bool {
    const n: usize = n_in;
    const lu_blocks = n * n * real_size_in_blocks * 2;
    const pivot_blocks = (n * @sizeOf(u16) + 3) >> 2;
    const vec_blocks = n * real_size_in_blocks * 2;

    if (runtime.allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]real_t = @ptrCast(@alignCast(lu_raw));
        if (runtime.allocC47Blocks(pivot_blocks)) |pivots_raw| {
            const pivots: [*]u16 = @ptrCast(@alignCast(pivots_raw));
            var i: usize = 0;
            while (i < n * n * 2) : (i += 1) {
                realCopy(&matrix[i], &lu[i]);
            }
            if (!luCpxMat(lu, n_in, pivots, real_context)) {
                runtime.freeC47Blocks(lu_raw, lu_blocks);
                runtime.freeC47Blocks(pivots_raw, pivot_blocks);
                return false;
            }

            {
                var max_val: real_t = undefined;
                var min_val: real_t = undefined;
                var p: real_t = undefined;
                var q: real_t = undefined;
                realCopy(&lu[0], &p);
                realCopy(&lu[1], &q);
                runtime.complexMagnitude(&p, &q, &p, real_context);
                realCopy(&p, &max_val);
                realCopy(&p, &min_val);
                i = 1;
                while (i < n) : (i += 1) {
                    realCopy(&lu[(i * n + i) * 2], &p);
                    realCopy(&lu[(i * n + i) * 2 + 1], &q);
                    runtime.complexMagnitude(&p, &q, &p, real_context);
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
                const x: [*]real_t = @ptrCast(@alignCast(x_raw));
                if (runtime.allocC47Blocks(vec_blocks)) |b_raw| {
                    const b: [*]real_t = @ptrCast(@alignCast(b_raw));
                    i = 0;
                    while (i < n) : (i += 1) {
                        var j: usize = 0;
                        while (j < n) : (j += 1) {
                            if (i == j) {
                                runtime.realSetOne(&b[j * 2]);
                            } else {
                                runtime.realSetZero(&b[j * 2]);
                            }
                            runtime.realSetZero(&b[j * 2 + 1]);
                        }
                        complexMatrixPivotingSolve(lu, n_in, b, pivots, x, real_context);
                        j = 0;
                        while (j < n) : (j += 1) {
                            realCopy(&x[j * 2], &matrix[(j * n + i) * 2]);
                            realCopy(&x[j * 2 + 1], &matrix[(j * n + i) * 2 + 1]);
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
