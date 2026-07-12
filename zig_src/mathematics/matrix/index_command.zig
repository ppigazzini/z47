// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix-index helpers of src/c47/mathematics/matrix.c:
// isMatrixIndexed reports whether the INDEX register currently points at a
// matrix, and fnIndexMatrix selects a register as the indexed matrix (resetting
// the I/J row/column pointers and the wrap flags).

const std = @import("std");
const runtime = @import("../math_command_wrappers_runtime.zig");

const nim_register_line = runtime.REGISTER_X;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn isMatrixIndexed() callconv(.c) bool {
    const index_reg: runtime.calcRegister_t = @intCast(runtime.matrixIndex);
    return (runtime.matrixIndex != @as(u16, @intCast(runtime.INVALID_VARIABLE))) and
        runtime.isRegInRange(runtime.matrixIndex) and
        (runtime.getRegisterDataType(index_reg) == runtime.dtReal34Matrix or
            runtime.getRegisterDataType(index_reg) == runtime.dtComplex34Matrix);
}

pub export fn fnIndexMatrix(regist: u16) callconv(.c) void {
    const reg: runtime.calcRegister_t = @intCast(regist);
    if (runtime.getRegisterDataType(reg) == runtime.dtReal34Matrix or
        runtime.getRegisterDataType(reg) == runtime.dtComplex34Matrix)
    {
        runtime.matrixIndex = regist;
        runtime.setIRegisterAsInt(false, 1);
        runtime.setJRegisterAsInt(false, 1);
        runtime.clearSystemFlag(runtime.FLAG_WRAPEDG);
        runtime.clearSystemFlag(runtime.FLAG_WRAPEND);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{runtime.getRegisterDataType(reg)}) catch "DataType";
            runtime.moreInfoOnError("In function fnIndexMatrix:", message, "is not a matrix.", "");
        }
    }
}
