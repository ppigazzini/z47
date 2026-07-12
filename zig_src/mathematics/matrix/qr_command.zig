// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnQrDecomposition command of src/c47/mathematics/matrix.c:
// QR-decompose the square matrix in register X (real or complex), leaving the
// orthogonal/unitary Q in Y and the upper-triangular R in X. The numeric
// real_QR_decomposition / complex_QR_decomposition still live in the matrix
// bridge; this is the command-level wrapper that drives them and stores the
// result.

const std = @import("std");
const runtime = @import("../math_command_wrappers_runtime.zig");

const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

fn reportNotSquare(rows: u16, cols: u16) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buffer: [64]u8 = undefined;
        const message = bufPrintZ(&buffer, "not a square matrix ({d}" ++ std_cross ++ "{d})", .{ rows, cols }) catch "not a square matrix";
        runtime.moreInfoOnError("In function fnQrDecomposition:", message, null, null);
    }
}

pub export fn fnQrDecomposition(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (!runtime.saveLastX()) {
        return;
    }

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        var q: real34Matrix_t = undefined;
        var r: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            reportNotSquare(x.header.matrixRows, x.header.matrixColumns);
        } else {
            runtime.real_QR_decomposition(&x, &q, &r);
            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
            runtime.liftStack();
            runtime.convertReal34MatrixToReal34MatrixRegister(&q, runtime.REGISTER_Y);
            runtime.convertReal34MatrixToReal34MatrixRegister(&r, runtime.REGISTER_X);
            runtime.realMatrixFree(&q);
            runtime.realMatrixFree(&r);
        }
    } else if (data_type == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        var q: complex34Matrix_t = undefined;
        var r: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
        if (x.header.matrixRows != x.header.matrixColumns) {
            reportNotSquare(x.header.matrixRows, x.header.matrixColumns);
        } else {
            runtime.complex_QR_decomposition(&x, &q, &r);
            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
            runtime.liftStack();
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&q, runtime.REGISTER_Y);
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&r, runtime.REGISTER_X);
            runtime.complexMatrixFree(&q);
            runtime.complexMatrixFree(&r);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function fnQrDecomposition:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}
