// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnVectorAngle command of src/c47/mathematics/matrix.c: replace
// register X by the angle between the 2D/3D real vectors in Y and X. The numeric
// vectorAngle is already Zig-owned; this command-level wrapper links the
// registers, validates the operands, converts the radian result to the current
// angular mode and stores it.

const std = @import("std");
const runtime = @import("../math_command_wrappers_runtime.zig");

const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn fnVectorAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix and
        runtime.getRegisterDataType(runtime.REGISTER_Y) == runtime.dtReal34Matrix)
    {
        var x: real34Matrix_t = undefined;
        var y: real34Matrix_t = undefined;
        var res: real34_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y);

        if (runtime.realVectorSize(&y) < 2 or runtime.realVectorSize(&x) < 2 or
            runtime.realVectorSize(&y) > 3 or runtime.realVectorSize(&x) > 3 or
            runtime.realVectorSize(&y) != runtime.realVectorSize(&x))
        {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            if (runtime.extra_info_on_calc_error) {
                var buffer: [96]u8 = undefined;
                const message = bufPrintZ(&buffer, "invalid numbers of elements of {d}" ++ std_cross ++ "{d}-matrix to {d}" ++ std_cross ++ "{d}-matrix", .{ x.header.matrixRows, x.header.matrixColumns, y.header.matrixRows, y.header.matrixColumns }) catch "invalid numbers of elements";
                runtime.moreInfoOnError("In function fnVectorAngle:", message, null, null);
            }
        } else {
            runtime.vectorAngle(&y, &x, &res);
            runtime.convertAngle34FromTo(&res, runtime.amRadian, runtime.currentAngularMode);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
            real34Copy(&res, runtime.registerReal34Data(runtime.REGISTER_X));
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{runtime.getRegisterDataType(runtime.REGISTER_X)}) catch "DataType";
            runtime.moreInfoOnError("In function fnVectorAngle:", message, "is not a real matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, -1);
}
