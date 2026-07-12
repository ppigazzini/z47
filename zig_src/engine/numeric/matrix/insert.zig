// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix row/column insert cluster of
// src/c47/mathematics/matrix.c: insRowRealMatrix / insColRealMatrix and
// insRowComplexMatrix / insColComplexMatrix (grow the matrix by one row or
// column, zero-filling the inserted line). The row/column delete cluster and
// the rest of the engine stay in the matrix bridge until the later B clusters.

const runtime = @import("../math_command_wrappers_runtime.zig");
const abi = @import("abi");
const math_matrix_lifecycle = @import("lifecycle.zig"); // M-callconv: Zig-to-Zig

const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// Owned by math_matrix_lifecycle.zig (B1).
extern fn decQuadZero(result: *real34_t) callconv(.c) *real34_t;

const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

// real34Copy / complex34Copy upstream are raw element copies (defines.h);
// real34Copy(const34_0, dst) zero-fills, equivalent to decQuadZero.
inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}
inline fn complex34Copy(source: *const complex34_t, destination: *complex34_t) void {
    destination.* = source.*;
}
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

pub export fn insRowRealMatrix(matrix: *real34Matrix_t, before_row_no: u16, add: bool) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const before: usize = if (add) rows else before_row_no;

    var new_mat: real34Matrix_t = undefined;
    if (math_matrix_lifecycle.realMatrixInit(&new_mat, rows + 1, cols)) {
        const src = realElems(matrix);
        const dst = realElems(&new_mat);
        var i: usize = 0;
        while (i < before * cols) : (i += 1) {
            real34Copy(&src[i], &dst[i]);
        }
        i = 0;
        while (i < cols) : (i += 1) {
            real34SetZero(&dst[before * cols + i]);
        }
        i = before * cols;
        while (i < @as(usize, cols) * rows) : (i += 1) {
            real34Copy(&src[i], &dst[i + cols]);
        }
        math_matrix_lifecycle.realMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function insRowRealMatrix:");
    }
}

pub export fn insColRealMatrix(matrix: *real34Matrix_t, before_col_no: u16, add: bool) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const before: usize = if (add) cols else before_col_no;

    var new_mat: real34Matrix_t = undefined;
    if (math_matrix_lifecycle.realMatrixInit(&new_mat, rows, cols + 1)) {
        const src = realElems(matrix);
        const dst = realElems(&new_mat);
        var j: usize = 0;
        while (j < before) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                real34Copy(&src[j + i * cols], &dst[j + i * (cols + 1)]);
            }
        }
        var i: usize = 0;
        while (i < rows) : (i += 1) {
            real34SetZero(&dst[before + i * (cols + 1)]);
        }
        j = before;
        while (j < @as(usize, cols) + 1) : (j += 1) {
            i = 0;
            while (i < rows) : (i += 1) {
                real34Copy(&src[j + i * cols], &dst[(j + 1) + i * (cols + 1)]);
            }
        }
        math_matrix_lifecycle.realMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function insColRealMatrix:");
    }
}

pub export fn insRowComplexMatrix(matrix: *complex34Matrix_t, before_row_no: u16, add: bool) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const before: usize = if (add) rows else before_row_no;

    var new_mat: complex34Matrix_t = undefined;
    if (math_matrix_lifecycle.complexMatrixInit(&new_mat, rows + 1, cols)) {
        const src = complexElems(matrix);
        const dst = complexElems(&new_mat);
        var i: usize = 0;
        while (i < before * cols) : (i += 1) {
            complex34Copy(&src[i], &dst[i]);
        }
        i = 0;
        while (i < cols) : (i += 1) {
            real34SetZero(&dst[before * cols + i].real);
            real34SetZero(&dst[before * cols + i].imag);
        }
        i = before * cols;
        while (i < @as(usize, cols) * rows) : (i += 1) {
            complex34Copy(&src[i], &dst[i + cols]);
        }
        math_matrix_lifecycle.complexMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function insRowComplexMatrix:");
    }
}

pub export fn insColComplexMatrix(matrix: *complex34Matrix_t, before_col_no: u16, add: bool) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const before: usize = if (add) cols else before_col_no;

    var new_mat: complex34Matrix_t = undefined;
    if (math_matrix_lifecycle.complexMatrixInit(&new_mat, rows, cols + 1)) {
        const src = complexElems(matrix);
        const dst = complexElems(&new_mat);
        var j: usize = 0;
        while (j < before) : (j += 1) {
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                complex34Copy(&src[j + i * cols], &dst[j + i * (cols + 1)]);
            }
        }
        var i: usize = 0;
        while (i < rows) : (i += 1) {
            real34SetZero(&dst[before + i * (cols + 1)].real);
            real34SetZero(&dst[before + i * (cols + 1)].imag);
        }
        j = before;
        while (j < @as(usize, cols) + 1) : (j += 1) {
            i = 0;
            while (i < rows) : (i += 1) {
                complex34Copy(&src[j + i * cols], &dst[(j + 1) + i * (cols + 1)]);
            }
        }
        math_matrix_lifecycle.complexMatrixFree(matrix);
        matrix.header.matrixRows = new_mat.header.matrixRows;
        matrix.header.matrixColumns = new_mat.header.matrixColumns;
        matrix.matrixElements = new_mat.matrixElements;
    } else {
        reportRamFull("In function insColComplexMatrix:");
    }
}
