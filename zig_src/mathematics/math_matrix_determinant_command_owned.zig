// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnDeterminant command of src/c47/mathematics/matrix.c: replace
// register X by the determinant of the square matrix it holds (real or complex).
// The numeric determinant is the already Zig-owned detRealMatrix /
// detComplexMatrix; this is the command-level wrapper that links the register,
// checks squareness and stores the scalar result.

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

pub export fn fnDeterminant(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (!runtime.saveLastX()) {
        return;
    }

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        var res: real34_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);

        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buffer: [64]u8 = undefined;
                const message = bufPrintZ(&buffer, "not a square matrix ({d}" ++ std_cross ++ "{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not a square matrix";
                runtime.moreInfoOnError("In function fnDeterminant:", message, null, null);
            }
        } else {
            runtime.detRealMatrix(&x, &res);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
                real34Copy(&res, runtime.registerReal34Data(runtime.REGISTER_X));
            }
        }
    } else if (data_type == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        var res_r: real34_t = undefined;
        var res_i: real34_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);

        if (x.header.matrixRows != x.header.matrixColumns) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buffer: [64]u8 = undefined;
                const message = bufPrintZ(&buffer, "not a square matrix ({d}" ++ std_cross ++ "{d})", .{ x.header.matrixRows, x.header.matrixColumns }) catch "not a square matrix";
                runtime.moreInfoOnError("In function fnDeterminant:", message, null, null);
            }
        } else {
            runtime.detComplexMatrix(&x, &res_r, &res_i);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
                real34Copy(&res_r, runtime.registerReal34Data(runtime.REGISTER_X));
                real34Copy(&res_i, runtime.registerImag34Data(runtime.REGISTER_X));
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            // Bug-for-bug: upstream's type-error branch names fnLuDecomposition.
            runtime.moreInfoOnError("In function fnLuDecomposition:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}
