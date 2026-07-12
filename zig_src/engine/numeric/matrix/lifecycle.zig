// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix lifecycle primitives from
// src/c47/mathematics/matrix.c: allocate/free/identity/redim, copy and
// transpose for real34 and complex34 matrices. The register-linking,
// element-arithmetic and command-level matrix functions stay in the matrix
// bridge until the later B clusters land.

const runtime = @import("../command_wrappers_runtime.zig");
const abi = @import("abi");

const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

// BPB = 2 -> BYTES_PER_BLOCK = 4; TO_BLOCKS(n) = (n + 3) >> 2 (defines.h).
const real34_size_in_blocks: usize = (@sizeOf(real34_t) + 3) >> 2;
const complex34_size_in_blocks: usize = (@sizeOf(complex34_t) + 3) >> 2;

// NIM_REGISTER_LINE is hard-defined to REGISTER_X upstream (defines.h).
const nim_register_line = runtime.REGISTER_X;

// matrix.c extern surface: the C47 block allocator and the decQuad element
// setters that back real34SetZero / real34SetOne.
extern fn allocC47Blocks(size_in_blocks: usize) callconv(.c) ?*anyopaque;
extern fn freeC47Blocks(ptr: ?*anyopaque, size_in_blocks: usize) callconv(.c) void;
extern fn isMemoryBlockAvailable(size_in_blocks: usize, num_blocks: u16, extra_fraction: f32) callconv(.c) bool;
extern fn decQuadZero(result: *real34_t) callconv(.c) *real34_t;
extern fn decQuadFromInt32(result: *real34_t, source: i32) callconv(.c) *real34_t;

// matrixElements is a C ([*c], allowzero) pointer; the helpers below take a
// plain many-item pointer derived once the allocation is known non-null.

const realElems = abi.matrixRealElems;

const constRealElems = abi.matrixConstRealElems;

const complexElems = abi.matrixComplexElems;

const constComplexElems = abi.matrixConstComplexElems;

inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}

inline fn real34SetOne(destination: *real34_t) void {
    _ = decQuadFromInt32(destination, 1);
}

// real34Copy / complex34Copy upstream are raw element copies (defines.h).
inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

inline fn complex34Copy(source: *const complex34_t, destination: *complex34_t) void {
    destination.* = source.*;
}

fn reportRamFullInfo(comptime function_name: [*:0]const u8) void {
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

fn reportRamFull(comptime function_name: [*:0]const u8, comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, info, null, null);
    }
}

pub export fn realMatrixInit(matrix: *real34Matrix_t, rows: u16, cols: u16) callconv(.c) bool {
    const needed_size = @as(usize, rows) * @as(usize, cols) * real34_size_in_blocks;
    if (!isMemoryBlockAvailable(needed_size, 2, 0.1)) {
        matrix.header.matrixColumns = 0;
        matrix.header.matrixRows = 0;
        matrix.matrixElements = null;
        reportRamFullInfo("In function realMatrixInit:");
        return false;
    }
    matrix.matrixElements = @ptrCast(@alignCast(allocC47Blocks(needed_size)));
    matrix.header.matrixColumns = @intCast(cols);
    matrix.header.matrixRows = @intCast(rows);

    const elems = realElems(matrix);
    const count = @as(usize, rows) * @as(usize, cols);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        real34SetZero(&elems[i]);
    }
    return true;
}

pub export fn realMatrixFree(matrix: *real34Matrix_t) callconv(.c) void {
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
    freeC47Blocks(matrix.matrixElements, count * real34_size_in_blocks);
    matrix.matrixElements = null;
    matrix.header.matrixRows = 0;
    matrix.header.matrixColumns = 0;
}

pub export fn realMatrixIdentity(matrix: *real34Matrix_t, size: u16) callconv(.c) void {
    if (realMatrixInit(matrix, size, size)) {
        const elems = realElems(matrix);
        var i: usize = 0;
        while (i < size) : (i += 1) {
            real34SetOne(&elems[i * size + i]);
        }
    } else {
        reportRamFull("In function realMatrixIdentity:", "Ram full");
    }
}

pub export fn realMatrixRedim(matrix: *real34Matrix_t, rows: u16, cols: u16) callconv(.c) void {
    var new_matrix: real34Matrix_t = undefined;
    if (realMatrixInit(&new_matrix, rows, cols)) {
        var elements = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
        const new_elements = @as(usize, rows) * @as(usize, cols);
        if (elements > new_elements) {
            elements = new_elements;
        }
        const src = constRealElems(matrix);
        const dst = realElems(&new_matrix);
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            real34Copy(&src[i], &dst[i]);
        }
        realMatrixFree(matrix);
        matrix.header.matrixRows = new_matrix.header.matrixRows;
        matrix.header.matrixColumns = new_matrix.header.matrixColumns;
        matrix.matrixElements = new_matrix.matrixElements;
    } else {
        reportRamFull("In function realMatrixRedim:", "Ram full");
    }
}

pub export fn complexMatrixInit(matrix: *complex34Matrix_t, rows: u16, cols: u16) callconv(.c) bool {
    const needed_size = @as(usize, rows) * @as(usize, cols) * complex34_size_in_blocks;
    if (!isMemoryBlockAvailable(needed_size, 2, 0.1)) {
        matrix.header.matrixColumns = 0;
        matrix.header.matrixRows = 0;
        matrix.matrixElements = null;
        reportRamFullInfo("In function complexMatrixInit:");
        return false;
    }
    matrix.matrixElements = @ptrCast(@alignCast(allocC47Blocks(needed_size)));
    matrix.header.matrixColumns = @intCast(cols);
    matrix.header.matrixRows = @intCast(rows);
    if (matrix.matrixElements == null) { // alloc can fail even when isMemoryBlockAvailable said yes
        matrix.header.matrixColumns = 0;
        matrix.header.matrixRows = 0;
        reportRamFullInfo("In function complexMatrixInit:");
        return false;
    }

    const elems = complexElems(matrix);
    const count = @as(usize, rows) * @as(usize, cols);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        real34SetZero(&elems[i].real);
        real34SetZero(&elems[i].imag);
    }
    return true;
}

pub export fn complexMatrixFree(matrix: *complex34Matrix_t) callconv(.c) void {
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
    freeC47Blocks(matrix.matrixElements, count * complex34_size_in_blocks);
    matrix.matrixElements = null;
    matrix.header.matrixRows = 0;
    matrix.header.matrixColumns = 0;
}

pub export fn complexMatrixIdentity(matrix: *complex34Matrix_t, size: u16) callconv(.c) void {
    if (complexMatrixInit(matrix, size, size)) {
        const elems = complexElems(matrix);
        var i: usize = 0;
        while (i < size) : (i += 1) {
            real34SetOne(&elems[i * size + i].real);
            real34SetZero(&elems[i * size + i].imag);
        }
    } else {
        reportRamFull("In function complexMatrixIdentity:", "Ram full");
    }
}

pub export fn complexMatrixRedim(matrix: *complex34Matrix_t, rows: u16, cols: u16) callconv(.c) void {
    var new_matrix: complex34Matrix_t = undefined;
    if (complexMatrixInit(&new_matrix, rows, cols)) {
        var elements = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
        const new_elements = @as(usize, rows) * @as(usize, cols);
        if (elements > new_elements) {
            elements = new_elements;
        }
        const src = constComplexElems(matrix);
        const dst = complexElems(&new_matrix);
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            complex34Copy(&src[i], &dst[i]);
        }
        complexMatrixFree(matrix);
        matrix.header.matrixRows = new_matrix.header.matrixRows;
        matrix.header.matrixColumns = new_matrix.header.matrixColumns;
        matrix.matrixElements = new_matrix.matrixElements;
    } else {
        reportRamFull("In function complexMatrixRedim:", "Ram full");
    }
}

pub export fn copyRealMatrix(matrix: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    if (realMatrixInit(res, rows, cols)) {
        const src = constRealElems(matrix);
        const dst = realElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            real34Copy(&src[i], &dst[i]);
        }
    } else {
        reportRamFull("In function copyRealMatrix:", "Ram full");
    }
}

pub export fn copyComplexMatrix(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;
    if (complexMatrixInit(res, rows, cols)) {
        const src = constComplexElems(matrix);
        const dst = complexElems(res);
        const count = @as(usize, cols) * @as(usize, rows);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            complex34Copy(&src[i], &dst[i]);
        }
    } else {
        reportRamFull("In function copyComplexMatrix:", "Ram full");
    }
}

pub export fn transposeRealMatrix(matrix: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (@intFromPtr(matrix) != @intFromPtr(res)) {
        if (realMatrixInit(res, cols, rows)) {
            const src = constRealElems(matrix);
            const dst = realElems(res);
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = 0;
                while (j < cols) : (j += 1) {
                    real34Copy(&src[i * cols + j], &dst[j * rows + i]);
                }
            }
        } else {
            reportRamFull("In function transposeRealMatrix:", "Ram full, 1g");
        }
    } else {
        var tmp: real34Matrix_t = undefined;
        copyRealMatrix(matrix, &tmp);
        if (tmp.matrixElements != null) {
            const src = constRealElems(&tmp);
            const dst = realElems(res);
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = 0;
                while (j < cols) : (j += 1) {
                    real34Copy(&src[i * cols + j], &dst[j * rows + i]);
                }
            }
            realMatrixFree(&tmp);
            res.header.matrixRows = @intCast(cols);
            res.header.matrixColumns = @intCast(rows);
        } else {
            reportRamFull("In function transposeRealMatrix:", "Ram full, 2h");
        }
    }
}

pub export fn transposeComplexMatrix(matrix: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const rows = matrix.header.matrixRows;
    const cols = matrix.header.matrixColumns;

    if (@intFromPtr(matrix) != @intFromPtr(res)) {
        if (complexMatrixInit(res, cols, rows)) {
            const src = constComplexElems(matrix);
            const dst = complexElems(res);
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = 0;
                while (j < cols) : (j += 1) {
                    complex34Copy(&src[i * cols + j], &dst[j * rows + i]);
                }
            }
        } else {
            reportRamFull("In function transposeComplexMatrix:", "Ram full, 1i");
        }
    } else {
        var tmp: complex34Matrix_t = undefined;
        copyComplexMatrix(matrix, &tmp);
        if (tmp.matrixElements != null) {
            const src = constComplexElems(&tmp);
            const dst = complexElems(res);
            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = 0;
                while (j < cols) : (j += 1) {
                    complex34Copy(&src[i * cols + j], &dst[j * rows + i]);
                }
            }
            complexMatrixFree(&tmp);
            res.header.matrixRows = @intCast(cols);
            res.header.matrixColumns = @intCast(rows);
        } else {
            reportRamFull("In function transposeComplexMatrix:", "Ram full, 2j");
        }
    }
}
