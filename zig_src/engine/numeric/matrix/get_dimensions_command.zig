// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnGetMatrixDimensions / fnGetMatrixDimensions42 commands of
// src/c47/mathematics/matrix.c (with their shared static worker
// getMatrixDimensionsToStack): push the row and column counts of a register
// matrix onto the stack as long integers (Y = rows, X = columns). The register
// and long-integer surface stays in the bridge / runtime.

const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;

const nim_register_line = runtime.REGISTER_X;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

fn getMatrixDimensionsToStack(regist: calcRegister_t, consume_x: bool) void {
    if (runtime.getRegisterDataType(regist) == runtime.dtReal34Matrix or
        runtime.getRegisterDataType(regist) == runtime.dtComplex34Matrix)
    {
        const header = runtime.registerMatrixHeader(regist);
        const rows = header.matrixRows;
        const cols = header.matrixColumns;
        var li: runtime.longInteger_t = undefined;

        if (consume_x) {
            runtime.fnDrop(runtime.NOPARAM);
        }
        runtime.liftStack();
        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
        runtime.liftStack();
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.reallocateRegister(runtime.REGISTER_Y, runtime.dtReal34, 0, runtime.amNone);
        _ = runtime.__gmpz_init(&li[0]);
        _ = runtime.__gmpz_set_ui(&li[0], rows);
        runtime.convertLongIntegerToLongIntegerRegister(&li[0], runtime.REGISTER_Y);
        _ = runtime.__gmpz_set_ui(&li[0], cols);
        runtime.convertLongIntegerToLongIntegerRegister(&li[0], runtime.REGISTER_X);
        runtime.__gmpz_clear(&li[0]);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{runtime.getRegisterDataType(regist)}) catch "DataType";
            runtime.moreInfoOnError("In function fnGetMatrixDimensions:", message, "is not a matrix.", "");
        }
    }
}

pub export fn fnGetMatrixDimensions(regist: u16) callconv(.c) void {
    const reg: calcRegister_t = @intCast(regist);
    if (reg == runtime.REGISTER_X and !runtime.saveLastX()) {
        return;
    }
    getMatrixDimensionsToStack(reg, false);
}

pub export fn fnGetMatrixDimensions42(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (!runtime.saveLastX()) {
        return;
    }
    getMatrixDimensionsToStack(runtime.REGISTER_X, true);
}
