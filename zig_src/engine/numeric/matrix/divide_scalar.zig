// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix-by-scalar divide cluster of
// src/c47/mathematics/matrix.c: divideRealMatrix / _divideRealMatrix and
// divideComplexMatrix / _divideComplexMatrix (each element divided by a
// real34/real or complex scalar), plus the reciprocal divideByRealMatrix /
// _divideByRealMatrix and divideByComplexMatrix / _divideByComplexMatrix
// (a real34/real or complex scalar divided elementwise by each matrix
// element). The matrix-by-matrix divide (which needs the linear-algebra
// solver) and the rest of the engine live in other matrix owners, not in
// this scalar-divide owner.

const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const abi = @import("abi");
const math_real_predicates = @import("../compare/real_predicates.zig");
const math_matrix_lifecycle = @import("lifecycle.zig");
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real_t = runtime.real_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// Owned by math_matrix_lifecycle.zig.

const realElems = abi.matrixRealElems;
const constRealElems = abi.matrixConstRealElems;
const complexElems = abi.matrixComplexElems;
const constComplexElems = abi.matrixConstComplexElems;

const samePtr = math_real_predicates.samePtr;

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

pub export fn divideRealMatrix(matrix: *const real34Matrix_t, x: *const real34_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            runtime.real34Divide(&me[i], x, &re[i]);
        }
    } else {
        reportRamFull("In function divideRealMatrix:");
    }
}

pub export fn _divideRealMatrix(matrix: *const real34Matrix_t, x: *const real_t, res: *real34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var y: real_t = undefined;
            runtime.real34ToReal(&me[i], &y);
            runtime.realDivide(&y, x, &y, real_context);
            runtime.realToReal34(&y, &re[i]);
        }
    } else {
        reportRamFull("In function _divideRealMatrix:");
    }
}

pub export fn divideComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real34_t, xi: *const real34_t, res: *complex34Matrix_t) callconv(.c) void {
    var real_xr: real_t = undefined;
    var real_xi: real_t = undefined;
    runtime.real34ToReal(xr, &real_xr);
    runtime.real34ToReal(xi, &real_xi);
    _divideComplexMatrix(matrix, &real_xr, &real_xi, res, &runtime.ctxtReal39);
}

pub export fn _divideComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real_t, xi: *const real_t, res: *complex34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.complexMatrixInit(res, rows, cols)) {
        const me = constComplexElems(matrix);
        const re = complexElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var yr: real_t = undefined;
            var yi: real_t = undefined;
            runtime.real34ToReal(&me[i].real, &yr);
            runtime.real34ToReal(&me[i].imag, &yi);
            runtime.divComplexComplex(&yr, &yi, xr, xi, &yr, &yi, real_context);
            runtime.realToReal34(&yr, &re[i].real);
            runtime.realToReal34(&yi, &re[i].imag);
        }
    } else {
        reportRamFull("In function divideComplexMatrix:");
    }
}

pub export fn divideByRealMatrix(y: *const real34_t, matrix: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            runtime.real34Divide(y, &me[i], &re[i]);
        }
    } else {
        reportRamFull("In function divideByRealMatrix:");
    }
}

pub export fn _divideByRealMatrix(y: *const real_t, matrix: *const real34Matrix_t, res: *real34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var x: real_t = undefined;
            runtime.real34ToReal(&me[i], &x);
            runtime.realDivide(y, &x, &x, real_context);
            runtime.realToReal34(&x, &re[i]);
        }
    } else {
        reportRamFull("In function _divideByRealMatrix:");
    }
}

pub export fn divideByComplexMatrix(yr: *const real34_t, yi: *const real34_t, matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    var real_yr: real_t = undefined;
    var real_yi: real_t = undefined;
    runtime.real34ToReal(yr, &real_yr);
    runtime.real34ToReal(yi, &real_yi);
    _divideByComplexMatrix(&real_yr, &real_yi, matrix, res, &runtime.ctxtReal39);
}

pub export fn _divideByComplexMatrix(yr: *const real_t, yi: *const real_t, matrix: *const complex34Matrix_t, res: *complex34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or math_matrix_lifecycle.complexMatrixInit(res, rows, cols)) {
        const me = constComplexElems(matrix);
        const re = complexElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var xr: real_t = undefined;
            var xi: real_t = undefined;
            runtime.real34ToReal(&me[i].real, &xr);
            runtime.real34ToReal(&me[i].imag, &xi);
            runtime.divComplexComplex(yr, yi, &xr, &xi, &xr, &xi, real_context);
            runtime.realToReal34(&xr, &re[i].real);
            runtime.realToReal34(&xi, &re[i].imag);
        }
    } else {
        reportRamFull("In function _divideByComplexMatrix:");
    }
}
