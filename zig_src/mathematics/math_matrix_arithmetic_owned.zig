// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix elementwise-arithmetic cluster of
// src/c47/mathematics/matrix.c: add/subtract of two matrices and multiply of a
// matrix by a real34/real scalar (real34 and complex34). The matrix*matrix
// products, the divide family and the vector ops stay in the matrix bridge
// until the later B clusters land.

const runtime = @import("math_command_wrappers_runtime.zig");

const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real_t = runtime.real_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// realMatrixInit / complexMatrixInit are owned by
// math_matrix_lifecycle_owned.zig (B1); resolve the canonical symbols here.
extern fn realMatrixInit(matrix: *real34Matrix_t, rows: u16, cols: u16) callconv(.c) bool;
extern fn complexMatrixInit(matrix: *complex34Matrix_t, rows: u16, cols: u16) callconv(.c) bool;

const RealElems = [*]real34_t;
const ConstRealElems = [*]const real34_t;
const ComplexElems = [*]complex34_t;
const ConstComplexElems = [*]const complex34_t;

inline fn realElems(matrix: anytype) RealElems {
    return @ptrCast(matrix.matrixElements);
}
inline fn constRealElems(matrix: anytype) ConstRealElems {
    return @ptrCast(matrix.matrixElements);
}
inline fn complexElems(matrix: anytype) ComplexElems {
    return @ptrCast(matrix.matrixElements);
}
inline fn constComplexElems(matrix: anytype) ConstComplexElems {
    return @ptrCast(matrix.matrixElements);
}

inline fn samePtr(a: anytype, b: anytype) bool {
    return @intFromPtr(a) == @intFromPtr(b);
}

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

fn addSubRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, subtraction: bool, res: *real34Matrix_t) void {
    const rows = y.header.matrixRows;
    const cols = y.header.matrixColumns;

    if (y.header.matrixColumns != x.header.matrixColumns or y.header.matrixRows != x.header.matrixRows) {
        runtime.realMatrixFree(res); // Matrix mismatch: res aliases an owned operand, so free it (clears matrixElements and dims)
        return;
    }

    if (!samePtr(y, res) and !samePtr(x, res)) {
        if (!realMatrixInit(res, rows, cols)) {
            reportRamFull("In function addSubRealMatrices:");
            return;
        }
    }

    const ye = constRealElems(y);
    const xe = constRealElems(x);
    const re = realElems(res);
    const count = @as(usize, cols) * @as(usize, rows);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (subtraction) {
            runtime.real34SubtractMacro(&ye[i], &xe[i], &re[i]);
        } else {
            runtime.real34Add(&ye[i], &xe[i], &re[i]);
        }
    }
}

pub export fn addRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    addSubRealMatrices(y, x, false, res);
}

pub export fn subtractRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    addSubRealMatrices(y, x, true, res);
}

fn addSubComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, subtraction: bool, res: *complex34Matrix_t) void {
    const rows = y.header.matrixRows;
    const cols = y.header.matrixColumns;

    if (y.header.matrixColumns != x.header.matrixColumns or y.header.matrixRows != x.header.matrixRows) {
        runtime.complexMatrixFree(res); // Matrix mismatch: res aliases an owned operand, so free it (clears matrixElements and dims)
        return;
    }

    if (samePtr(y, res) or samePtr(x, res) or complexMatrixInit(res, rows, cols)) {
        const ye = constComplexElems(y);
        const xe = constComplexElems(x);
        const re = complexElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            if (subtraction) {
                runtime.real34SubtractMacro(&ye[i].real, &xe[i].real, &re[i].real);
                runtime.real34SubtractMacro(&ye[i].imag, &xe[i].imag, &re[i].imag);
            } else {
                runtime.real34Add(&ye[i].real, &xe[i].real, &re[i].real);
                runtime.real34Add(&ye[i].imag, &xe[i].imag, &re[i].imag);
            }
        }
    } else {
        reportRamFull("In function addSubComplexMatrices:");
    }
}

pub export fn addComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    addSubComplexMatrices(y, x, false, res);
}

pub export fn subtractComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    addSubComplexMatrices(y, x, true, res);
}

pub export fn multiplyRealMatrix(matrix: *const real34Matrix_t, x: *const real34_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            runtime.real34Multiply(&me[i], x, &re[i]);
        }
    } else {
        reportRamFull("In function multiplyRealMatrix:");
    }
}

pub export fn _multiplyRealMatrix(matrix: *const real34Matrix_t, x: *const real_t, res: *real34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or realMatrixInit(res, rows, cols)) {
        const me = constRealElems(matrix);
        const re = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var y: real_t = undefined;
            runtime.real34ToReal(&me[i], &y);
            runtime.realMultiply(&y, x, &y, real_context);
            runtime.realToReal34(&y, &re[i]);
        }
    } else {
        reportRamFull("In function _multiplyRealMatrix:");
    }
}

pub export fn multiplyComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real34_t, xi: *const real34_t, res: *complex34Matrix_t) callconv(.c) void {
    var real_xr: real_t = undefined;
    var real_xi: real_t = undefined;
    runtime.real34ToReal(xr, &real_xr);
    runtime.real34ToReal(xi, &real_xi);
    _multiplyComplexMatrix(matrix, &real_xr, &real_xi, res, &runtime.ctxtReal39);
}

pub export fn _multiplyComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real_t, xi: *const real_t, res: *complex34Matrix_t, real_context: *runtime.realContext_t) callconv(.c) void {
    _ = real_context;
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (samePtr(matrix, res) or complexMatrixInit(res, rows, cols)) {
        const me = constComplexElems(matrix);
        const re = complexElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var yr: real_t = undefined;
            var yi: real_t = undefined;
            runtime.real34ToReal(&me[i].real, &yr);
            runtime.real34ToReal(&me[i].imag, &yi);
            runtime.mulComplexComplex(&yr, &yi, xr, xi, &yr, &yi, &runtime.ctxtReal39);
            runtime.realToReal34(&yr, &re[i].real);
            runtime.realToReal34(&yi, &re[i].imag);
        }
    } else {
        reportRamFull("In function _multiplyComplexMatrix:");
    }
}
