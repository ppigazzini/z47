// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix row/column delete cluster of
// src/c47/mathematics/matrix.c: delRowRealMatrix / delColRealMatrix and
// delRowComplexMatrix / delColComplexMatrix (shrink the matrix by one row or
// column). The rest of the engine stays in the matrix bridge.

const runtime = @import("../command_wrappers_runtime.zig");
const abi = @import("abi");
const math_matrix_lifecycle = @import("lifecycle.zig");
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// Owned by math_matrix_lifecycle.zig.

const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}
inline fn complex34Copy(source: *const complex34_t, destination: *complex34_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

pub export fn delRowRealMatrix(matrix: *real34Matrix_t, before_row_no: u16) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    var new_mat: real34Matrix_t = undefined;
    if (math_matrix_lifecycle.realMatrixInit(&new_mat, rows - 1, cols)) {
        const src = realElems(matrix);
        const dst = realElems(&new_mat);
        var i: usize = 0;
        while (i < @as(usize, before_row_no) * cols) : (i += 1) {
            real34Copy(&src[i], &dst[i]);
        }
        i = (@as(usize, before_row_no) + 1) * cols;
        while (i < @as(usize, cols) * rows) : (i += 1) {
            real34Copy(&src[i], &dst[i - cols]);
        }
        math_matrix_lifecycle.realMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function delRowRealMatrix:");
    }
}

pub export fn delColRealMatrix(matrix: *real34Matrix_t, before_col_no: u16) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    var new_mat: real34Matrix_t = undefined;
    if (math_matrix_lifecycle.realMatrixInit(&new_mat, rows, cols - 1)) {
        const src = realElems(matrix);
        const dst = realElems(&new_mat);
        var j: usize = 0;
        while (j < before_col_no) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                real34Copy(&src[j + i * cols], &dst[j + i * (cols - 1)]);
            }
        }
        j = @as(usize, before_col_no) + 1;
        while (j < cols) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                real34Copy(&src[j + i * cols], &dst[(j - 1) + i * (cols - 1)]);
            }
        }
        math_matrix_lifecycle.realMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function delColRealMatrix:");
    }
}

pub export fn delRowComplexMatrix(matrix: *complex34Matrix_t, before_row_no: u16) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    var new_mat: complex34Matrix_t = undefined;
    if (math_matrix_lifecycle.complexMatrixInit(&new_mat, rows - 1, cols)) {
        const src = complexElems(matrix);
        const dst = complexElems(&new_mat);
        var i: usize = 0;
        while (i < @as(usize, before_row_no) * cols) : (i += 1) {
            complex34Copy(&src[i], &dst[i]);
        }
        i = (@as(usize, before_row_no) + 1) * cols;
        while (i < @as(usize, cols) * rows) : (i += 1) {
            complex34Copy(&src[i], &dst[i - cols]);
        }
        math_matrix_lifecycle.complexMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function delRowComplexMatrix:");
    }
}

pub export fn delColComplexMatrix(matrix: *complex34Matrix_t, before_col_no: u16) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    var new_mat: complex34Matrix_t = undefined;
    if (math_matrix_lifecycle.complexMatrixInit(&new_mat, rows, cols - 1)) {
        const src = complexElems(matrix);
        const dst = complexElems(&new_mat);
        var j: usize = 0;
        while (j < before_col_no) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                complex34Copy(&src[j + i * cols], &dst[j + i * (cols - 1)]);
            }
        }
        j = @as(usize, before_col_no) + 1;
        while (j < cols) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                complex34Copy(&src[j + i * cols], &dst[(j - 1) + i * (cols - 1)]);
            }
        }
        math_matrix_lifecycle.complexMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function delColComplexMatrix:");
    }
}
