// SPDX-License-Identifier: GPL-3.0-only
// Zig port of complex_LU_decomposition from src/c47/mathematics/matrix.c: the
// complex partial-pivoting LU decomposition, packing the matrix into an
// interleaved-complex real_t scratch array, running the shared Zig-owned
// luCpxMat worker and writing the combined L/U factors back (the pivot vector is
// filled in for the caller).

const runtime = @import("../math_command_wrappers_runtime.zig");
const abi = @import("abi");
const math_real_predicates = @import("../math_real_predicates.zig");

const real_t = runtime.real_t;
const complex34_t = runtime.complex34_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

const complexElems = abi.matrixComplexElems;

const samePtr = math_real_predicates.samePtr;

fn reportRamFull(comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function complex_LU_decomposition:", info, null, null);
    }
}

fn clearNonSquare(matrix: anytype, lu: anytype) void {
    if (!samePtr(matrix, lu)) {
        lu.matrixElements = null;
        lu.header.matrixRows = 0;
        lu.header.matrixColumns = 0;
    }
}

pub export fn complex_LU_decomposition(matrix: *const complex34Matrix_t, lu: *complex34Matrix_t, p: [*]u16) callconv(.c) void {
    const m = matrix.header.matrixRows;
    const n = matrix.header.matrixColumns;

    if (matrix.header.matrixRows != matrix.header.matrixColumns) {
        clearNonSquare(matrix, lu);
        return;
    }

    const blocks = @as(usize, m) * n * real_size_in_blocks * 2;
    if (runtime.allocC47Blocks(blocks)) |tmp_raw| {
        const tmp_mat: [*]real_t = @ptrCast(@alignCast(tmp_raw));
        if (!samePtr(matrix, lu)) {
            runtime.copyComplexMatrix(matrix, lu);
        }

        if (lu.matrixElements != null) {
            const lu_elems = complexElems(lu);
            const nn: usize = @as(usize, n) * n;
            var idx: usize = 0;
            while (idx < nn) : (idx += 1) {
                runtime.real34ToReal(&lu_elems[idx].real, &tmp_mat[idx * 2]);
                runtime.real34ToReal(&lu_elems[idx].imag, &tmp_mat[idx * 2 + 1]);
            }

            if (runtime.luCpxMat(tmp_mat, n, p, &runtime.ctxtReal39)) {
                idx = 0;
                while (idx < nn) : (idx += 1) {
                    runtime.realToReal34(&tmp_mat[idx * 2], &lu_elems[idx].real);
                    runtime.realToReal34(&tmp_mat[idx * 2 + 1], &lu_elems[idx].imag);
                }
            } else {
                runtime.complexMatrixFree(lu);
            }
        } else {
            reportRamFull("Ram full, 1m");
        }

        runtime.freeC47Blocks(tmp_raw, blocks);
    } else {
        clearNonSquare(matrix, lu);
        reportRamFull("Ram full, 2n");
    }
}
