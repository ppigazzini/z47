// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix inverse primitives of src/c47/mathematics/matrix.c:
// invertRealMatrix / invertComplexMatrix invert a square matrix in place into a
// real_t scratch array via the dense core invCpxMat (owned by
// math_matrix_complex_core.zig) and write the result back, copying the
// source first when res differs from the input.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_real_predicates = @import("../compare/real_predicates.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

const constRealElems = abi.matrixConstRealElems;
const realElems = abi.matrixRealElems;
const constComplexElems = abi.matrixConstComplexElems;
const complexElems = abi.matrixComplexElems;

const samePtr = math_real_predicates.samePtr;

fn clearResult(res: anytype) void {
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;
}

fn reportRamFull(comptime function_name: [*:0]const u8, comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, info, null, null);
    }
}

pub export fn invertRealMatrix(matrix: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;

    if (matrix.header.matrixRows != matrix.header.matrixColumns) {
        if (!samePtr(matrix, res)) clearResult(res);
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, nim_register_line);
        return;
    }

    const blocks = @as(usize, n) * n * real_size_in_blocks * 2;
    const count = @as(usize, n) * n;
    if (runtime.allocC47Blocks(blocks)) |tmp_raw| {
        const tmp_mat: [*]real_t = @ptrCast(@alignCast(tmp_raw));
        const me = constRealElems(matrix);
        var k: usize = 0;
        while (k < count) : (k += 1) {
            runtime.real34ToReal(&me[k], &tmp_mat[k * 2]);
            runtime.realSetZero(&tmp_mat[k * 2 + 1]);
        }

        if (runtime.invCpxMat(tmp_mat, n, &runtime.ctxtReal39)) {
            if (!samePtr(matrix, res)) {
                runtime.copyRealMatrix(matrix, res);
            }
            if (res.matrixElements != null) {
                const re = realElems(res);
                k = 0;
                while (k < count) : (k += 1) {
                    runtime.realToReal34(&tmp_mat[k * 2], &re[k]);
                }
            } else {
                reportRamFull("In function invertRealMatrix:", "Ram full, 1u");
            }
        } else { // singular matrix
            if (!samePtr(matrix, res)) clearResult(res);
        }

        runtime.freeC47Blocks(tmp_raw, blocks);
    } else {
        reportRamFull("In function invertRealMatrix:", "Ram full, 2v");
    }
}

pub export fn invertComplexMatrix(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;

    if (matrix.header.matrixRows != matrix.header.matrixColumns) {
        if (!samePtr(matrix, res)) clearResult(res);
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, nim_register_line);
        return;
    }

    const blocks = @as(usize, n) * n * real_size_in_blocks * 2;
    const count = @as(usize, n) * n;
    if (runtime.allocC47Blocks(blocks)) |tmp_raw| {
        const tmp_mat: [*]real_t = @ptrCast(@alignCast(tmp_raw));
        const me = constComplexElems(matrix);
        var k: usize = 0;
        while (k < count) : (k += 1) {
            runtime.real34ToReal(&me[k].real, &tmp_mat[k * 2]);
            runtime.real34ToReal(&me[k].imag, &tmp_mat[k * 2 + 1]);
        }

        if (runtime.invCpxMat(tmp_mat, n, &runtime.ctxtReal39)) {
            if (!samePtr(matrix, res)) {
                runtime.copyComplexMatrix(matrix, res);
            }
            if (res.matrixElements != null) {
                const re = complexElems(res);
                k = 0;
                while (k < count) : (k += 1) {
                    runtime.realToReal34(&tmp_mat[k * 2], &re[k].real);
                    runtime.realToReal34(&tmp_mat[k * 2 + 1], &re[k].imag);
                }
            } else {
                reportRamFull("In function invertComplexMatrix:", "Ram full, 1w");
            }
        } else { // singular matrix
            if (!samePtr(matrix, res)) clearResult(res);
        }

        runtime.freeC47Blocks(tmp_raw, blocks);
    } else {
        reportRamFull("In function invertComplexMatrix:", "Ram full, 2x");
    }
}
