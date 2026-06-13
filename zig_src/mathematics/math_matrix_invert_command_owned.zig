// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnInvertMatrix command of src/c47/mathematics/matrix.c:
// replace register X by the inverse of the square matrix it holds (real or
// complex). The numeric inverse (invertRealMatrix / invertComplexMatrix) still
// lives in the matrix bridge; this is the command-level wrapper that links the
// register, checks squareness, stores the inverted matrix and handles the
// singular / error paths.

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

fn reportNotSquare(comptime function_name: [*:0]const u8, rows: u16, cols: u16) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buffer: [64]u8 = undefined;
        const message = bufPrintZ(&buffer, "not a square matrix ({d}" ++ std_cross ++ "{d})", .{ rows, cols }) catch "not a square matrix";
        runtime.moreInfoOnError(function_name, message, null, null);
    }
}

fn reportSingular(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "attempt to invert a singular matrix", null, null);
    }
}

fn onComputeError() void {
    runtime.temporaryInformation = runtime.TI_NO_INFO;
    if (runtime.programRunStop == runtime.PGM_WAITING) {
        runtime.programRunStop = runtime.PGM_STOPPED;
    }
}

pub export fn fnInvertMatrix(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (!runtime.saveLastX()) {
        return;
    }

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        var res: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);

        if (x.header.matrixRows != x.header.matrixColumns) {
            reportNotSquare("In function fnInvertMatrix:", x.header.matrixRows, x.header.matrixColumns);
        } else {
            runtime.invertRealMatrix(&x, &res);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                if (res.matrixElements != null) {
                    runtime.convertReal34MatrixToReal34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.realMatrixFree(&res);
                    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                } else {
                    reportSingular("In function fnInvertMatrix:");
                }
            } else {
                onComputeError();
            }
        }
    } else if (data_type == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        var res: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);

        if (x.header.matrixRows != x.header.matrixColumns) {
            reportNotSquare("In function fnInvertMatrix:", x.header.matrixRows, x.header.matrixColumns);
        } else {
            runtime.invertComplexMatrix(&x, &res);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                if (res.matrixElements != null) {
                    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, runtime.REGISTER_X);
                    runtime.complexMatrixFree(&res);
                    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                } else {
                    reportSingular("In function fnInvertMatrix:");
                }
            } else {
                onComputeError();
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function fnInvertMatrix:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}
