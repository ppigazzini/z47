// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the named-matrix helpers of src/c47/mathematics/matrix.c:
// allocateNamedMatrix finds-or-allocates a named variable and redimensions it
// to a matrix; appendRowAtMatrixRegister grows a matrix register by one row.
// Both delegate to the still-bridged redimMatrixRegister.

const runtime = @import("../command_wrappers/runtime.zig");

const calcRegister_t = runtime.calcRegister_t;

// Item code (items.h) selecting the normal redimension mode.
const ITM_M_DIM: u16 = 1526;

pub export fn allocateNamedMatrix(name: [*:0]const u8, rows: u16, cols: u16) callconv(.c) calcRegister_t {
    const regist = runtime.findOrAllocateNamedVariable(name);
    if (regist == runtime.INVALID_VARIABLE) {
        return runtime.INVALID_VARIABLE;
    } else if (runtime.redimMatrixRegister(regist, rows, cols, ITM_M_DIM)) {
        return regist;
    } else {
        return runtime.INVALID_VARIABLE;
    }
}

pub export fn appendRowAtMatrixRegister(regist: calcRegister_t) callconv(.c) bool {
    const header = runtime.registerMatrixHeader(regist);
    const rows = header.matrixRows;
    const cols = header.matrixColumns;
    if (regist == runtime.INVALID_VARIABLE) {
        return false;
    } else if (runtime.getRegisterDataType(regist) == runtime.dtReal34Matrix or
        runtime.getRegisterDataType(regist) == runtime.dtComplex34Matrix)
    {
        return runtime.redimMatrixRegister(regist, rows + 1, cols, ITM_M_DIM);
    } else {
        return false;
    }
}
