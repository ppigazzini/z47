// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnTranspose command of src/c47/mathematics/matrix.c: transpose
// the matrix in register X in place (real or complex), updating the register
// header dimensions. The numeric transpose primitive is the already Zig-owned
// transposeRealMatrix / transposeComplexMatrix; this is the command-level
// wrapper that links the register, drives it and reports type errors.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
// STD_CROSS (fonts.h) is the "x" glyph used in the dimension diagnostics.
const std_cross = "\x80\xd7";

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn fnTranspose(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (!runtime.saveLastX()) {
        return;
    }

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        runtime.transposeRealMatrix(&x, &x);
        const header = runtime.registerMatrixHeader(runtime.REGISTER_X);
        header.matrixRows = x.header.matrixRows;
        header.matrixColumns = x.header.matrixColumns;
    } else if (data_type == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
        runtime.transposeComplexMatrix(&x, &x);
        const header = runtime.registerMatrixHeader(runtime.REGISTER_X);
        header.matrixRows = x.header.matrixRows;
        header.matrixColumns = x.header.matrixColumns;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function fnTranspose:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}
