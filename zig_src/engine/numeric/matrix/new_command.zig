// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnNewMatrix command of src/c47/mathematics/matrix.c: allocate
// a fresh zero-filled real matrix of the dimensions read from the stack into
// register X. The register allocation (initMatrixRegister) and the dimension
// argument parsing (getDimensionArg) still live in the matrix bridge; this is
// the command-level wrapper that drives them.

const std = @import("std");
const runtime = @import("../math_command_wrappers_runtime.zig");

const std_cross = "\x80\xd7";

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn fnNewMatrix(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    var rows: u32 = undefined;
    var cols: u32 = undefined;
    if (!runtime.getDimensionArg(&rows, &cols)) {
        return;
    }
    if (!runtime.saveLastX()) {
        return;
    }

    // Initialize memory for the matrix.
    if (runtime.initMatrixRegister(runtime.REGISTER_X, @intCast(rows), @intCast(cols), false)) {
        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [80]u8 = undefined;
            const message = bufPrintZ(&buffer, "Not enough memory for a {d}" ++ std_cross ++ "{d} matrix", .{ rows, cols }) catch "Not enough memory for a matrix";
            runtime.moreInfoOnError("In function fnNewMatrix:", message, null, null);
        }
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, -1);
}
