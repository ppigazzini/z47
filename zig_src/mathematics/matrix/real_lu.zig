// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const math_real_predicates = @import("math_real_predicates.zig");
const consts = abi.constants;
// Zig port of WP34S_LU_decomposition from src/c47/mathematics/matrix.c: the real
// partial-pivoting LU decomposition, packing the matrix into a plain real_t
// scratch array, running Gaussian elimination with pivoting and writing the
// combined L/U factors back into the result matrix (the pivot vector is filled
// in for the caller). complex_LU_decomposition stays in the matrix bridge.

const runtime = @import("math_command_wrappers_runtime.zig");
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == 15; the real scratch is non-interleaved.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

inline fn const_1e_37() *const real_t {
    return consts.c4436();
}

const realElems = abi.matrixRealElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
// realCopyAbs == decNumberCopyAbs: copy then force a positive sign.
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
    runtime.realSetPositiveSign(destination);
}

const samePtr = math_real_predicates.samePtr;

fn reportRamFull(comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function WP34S_LU_decomposition:", info, null, null);
    }
}

pub export fn WP34S_LU_decomposition(matrix: *const real34Matrix_t, lu: *real34Matrix_t, p: [*]u16) callconv(.c) void {
    const m = matrix.header.matrixRows;
    const n = matrix.header.matrixColumns;

    if (matrix.header.matrixRows != matrix.header.matrixColumns) {
        if (!samePtr(matrix, lu)) {
            lu.matrixElements = null; // Matrix is not square
            lu.header.matrixRows = 0;
            lu.header.matrixColumns = 0;
        }
        return;
    }

    const blocks = @as(usize, m) * n * real_size_in_blocks;
    if (runtime.allocC47Blocks(blocks)) |tmp_raw| {
        const tmp_mat: [*]real_t = @ptrCast(@alignCast(tmp_raw));
        if (!samePtr(matrix, lu)) {
            runtime.copyRealMatrix(matrix, lu);
        }

        if (lu.matrixElements != null) {
            const lu_elems = realElems(lu);
            const nn: usize = @as(usize, n) * n;
            var idx: usize = 0;
            while (idx < nn) : (idx += 1) {
                runtime.real34ToReal(&lu_elems[idx], &tmp_mat[idx]);
            }

            var max: real_t = undefined;
            var t: real_t = undefined;
            var u: real_t = undefined;
            const nz: usize = n;
            var k: usize = 0;
            while (k < nz) : (k += 1) {
                // Find the pivot row.
                var pvt: usize = k;
                realCopy(&tmp_mat[k * nz + k], &u);
                realCopyAbs(&u, &max);
                var j: usize = k + 1;
                while (j < nz) : (j += 1) {
                    realCopy(&tmp_mat[j * nz + k], &t);
                    realCopyAbs(&t, &u);
                    if (math_comparison_reals.realCompareGreaterThan(&u, &max)) {
                        realCopy(&u, &max);
                        pvt = j;
                    }
                }
                p[k] = @intCast(pvt);

                // Pivot if required.
                if (pvt != k) {
                    var i: usize = 0;
                    while (i < nz) : (i += 1) {
                        realCopy(&tmp_mat[k * nz + i], &t);
                        realCopy(&tmp_mat[pvt * nz + i], &tmp_mat[k * nz + i]);
                        realCopy(&t, &tmp_mat[pvt * nz + i]);
                    }
                }

                // Check for singular.
                realCopy(&tmp_mat[k * nz + k], &t);
                if (runtime.realIsZero(&t)) {
                    runtime.realMatrixFree(lu);
                    runtime.freeC47Blocks(tmp_raw, blocks);
                    return;
                }

                // Lower triangular elements for column k.
                var i: usize = k + 1;
                while (i < nz) : (i += 1) {
                    realCopy(&tmp_mat[k * nz + k], &t);
                    realCopy(&tmp_mat[i * nz + k], &u);
                    runtime.realDivide(&u, &t, &max, &runtime.ctxtReal39);
                    realCopy(&max, &tmp_mat[i * nz + k]);
                }
                // Update the upper triangular elements.
                i = k + 1;
                while (i < nz) : (i += 1) {
                    j = k + 1;
                    while (j < nz) : (j += 1) {
                        realCopy(&tmp_mat[i * nz + k], &t);
                        realCopy(&tmp_mat[k * nz + j], &u);
                        runtime.realMultiply(&t, &u, &max, &runtime.ctxtReal39);
                        realCopy(&tmp_mat[i * nz + j], &t);
                        runtime.realSubtract(&t, &max, &u, &runtime.ctxtReal39);
                        runtime.realDivide(&u, &t, &max, &runtime.ctxtReal39); // condition number
                        if (math_comparison_reals.realCompareAbsLessThan(&max, const_1e_37())) {
                            runtime.realSetZero(&tmp_mat[i * nz + j]);
                        } else {
                            realCopy(&u, &tmp_mat[i * nz + j]);
                        }
                    }
                }
            }

            idx = 0;
            while (idx < nn) : (idx += 1) {
                runtime.realToReal34(&tmp_mat[idx], &lu_elems[idx]);
            }
        } else {
            reportRamFull("Ram full, 1k");
        }

        runtime.freeC47Blocks(tmp_raw, blocks);
    } else {
        if (!samePtr(matrix, lu)) {
            lu.matrixElements = null;
            lu.header.matrixRows = 0;
            lu.header.matrixColumns = 0;
        }
        reportRamFull("Ram full, 2l");
    }
}
