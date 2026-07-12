// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix row/column swap cluster of
// src/c47/mathematics/matrix.c: realMatrixSwapRows / realMatrixSwapColumns and
// complexMatrixSwapRows / complexMatrixSwapColumns (and their shared static
// workers _realMatrixSwap / _complexMatrixSwap). The remaining matrix engine
// stays in the matrix bridge until it is ported.

const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const abi = @import("abi");
const math_real_predicates = @import("../compare/real_predicates.zig");
const math_matrix_lifecycle = @import("lifecycle.zig");
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// Owned by math_matrix_lifecycle.zig.

const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

const samePtr = math_real_predicates.samePtr;

// real34Copy upstream is a raw element copy (defines.h).
inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

fn realMatrixSwap(matrix: *const real34Matrix_t, res: *real34Matrix_t, a: u16, b: u16, is_row: bool, comptime function_name: [*:0]const u8) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const limit = if (is_row) rows else cols;

    if (!samePtr(matrix, res)) {
        math_matrix_lifecycle.copyRealMatrix(matrix, res);
    }
    if (res.matrixElements != null) {
        if ((a < limit) and (b < limit) and (a != b)) {
            const elems = realElems(res);
            const span: usize = if (is_row) cols else rows;
            var i: usize = 0;
            while (i < span) : (i += 1) {
                const ia: usize = if (is_row) @as(usize, a) * cols + i else i * cols + a;
                const ib: usize = if (is_row) @as(usize, b) * cols + i else i * cols + b;
                var t: real34_t = undefined;
                real34Copy(&elems[ia], &t);
                real34Copy(&elems[ib], &elems[ia]);
                real34Copy(&t, &elems[ib]);
            }
        }
    } else {
        reportRamFull(function_name);
    }
}

fn complexMatrixSwap(matrix: *const complex34Matrix_t, res: *complex34Matrix_t, a: u16, b: u16, is_row: bool, comptime function_name: [*:0]const u8) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    const limit = if (is_row) rows else cols;

    if (!samePtr(matrix, res)) {
        math_matrix_lifecycle.copyComplexMatrix(matrix, res);
    }
    if (res.matrixElements != null) {
        if ((a < limit) and (b < limit) and (a != b)) {
            const elems = complexElems(res);
            const span: usize = if (is_row) cols else rows;
            var i: usize = 0;
            while (i < span) : (i += 1) {
                const ia: usize = if (is_row) @as(usize, a) * cols + i else i * cols + a;
                const ib: usize = if (is_row) @as(usize, b) * cols + i else i * cols + b;
                var t: real34_t = undefined;
                real34Copy(&elems[ia].real, &t);
                real34Copy(&elems[ib].real, &elems[ia].real);
                real34Copy(&t, &elems[ib].real);
                real34Copy(&elems[ia].imag, &t);
                real34Copy(&elems[ib].imag, &elems[ia].imag);
                real34Copy(&t, &elems[ib].imag);
            }
        }
    } else {
        reportRamFull(function_name);
    }
}

pub export fn realMatrixSwapRows(matrix: *const real34Matrix_t, res: *real34Matrix_t, a: u16, b: u16) callconv(.c) void {
    realMatrixSwap(matrix, res, a, b, true, "In function _realMatrixSwap:");
}

pub export fn realMatrixSwapColumns(matrix: *const real34Matrix_t, res: *real34Matrix_t, a: u16, b: u16) callconv(.c) void {
    realMatrixSwap(matrix, res, a, b, false, "In function _realMatrixSwap:");
}

pub export fn complexMatrixSwapRows(matrix: *const complex34Matrix_t, res: *complex34Matrix_t, a: u16, b: u16) callconv(.c) void {
    complexMatrixSwap(matrix, res, a, b, true, "In function _complexMatrixSwap:");
}

pub export fn complexMatrixSwapColumns(matrix: *const complex34Matrix_t, res: *complex34Matrix_t, a: u16, b: u16) callconv(.c) void {
    complexMatrixSwap(matrix, res, a, b, false, "In function _complexMatrixSwap:");
}
