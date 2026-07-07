// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix register-linking helpers of
// src/c47/mathematics/matrix.c: linkToRealMatrixRegister and
// linkToComplexMatrixRegister point a stack-local matrix descriptor at a
// register's in-place data (header + elements) without copying. The register
// store, allocation and the rest of the engine stay in the matrix bridge.

const abi = @import("abi");
const runtime = @import("math_command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const matrixHeader_t = runtime.matrixHeader_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

// REGISTER_MATRIX_HEADER(a) == (matrixHeader_t *)getRegisterDataPointer(a);
// the element arrays start sizeof(matrixHeader_t) bytes after the header.
inline fn registerHeader(regist: calcRegister_t) *matrixHeader_t {
    return @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?));
}
inline fn registerBytes(regist: calcRegister_t) [*]u8 {
    return abi.registerBytes(regist);
}

// isMatrixVector(rows, cols) (defines.h): a 2D or 3D row/column vector.
inline fn isMatrixVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1) or
        (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}

pub export fn linkToRealMatrixRegister(regist: calcRegister_t, linked_matrix: *real34Matrix_t) callconv(.c) void {
    const header = registerHeader(regist);
    linked_matrix.header.matrixRows = header.matrixRows;
    linked_matrix.header.matrixColumns = header.matrixColumns;
    if ((runtime.REGISTER_X <= regist and regist <= runtime.REGISTER_T) and
        isMatrixVector(linked_matrix.header.matrixRows, linked_matrix.header.matrixColumns))
    {
        // Read straight from the (global) register; used only for X-T display.
        linked_matrix.header.mtag = @truncate(runtime.getRegisterTag(regist));
    }
    const elements = registerBytes(regist) + @sizeOf(matrixHeader_t);
    linked_matrix.matrixElements = @ptrCast(@alignCast(elements));
}

pub export fn linkToComplexMatrixRegister(regist: calcRegister_t, linked_matrix: *complex34Matrix_t) callconv(.c) void {
    const header = registerHeader(regist);
    linked_matrix.header.matrixRows = header.matrixRows;
    linked_matrix.header.matrixColumns = header.matrixColumns;
    const elements = registerBytes(regist) + @sizeOf(matrixHeader_t);
    linked_matrix.matrixElements = @ptrCast(@alignCast(elements));
}
