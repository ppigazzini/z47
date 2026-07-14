// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnSetMatrixDimensions / fnSetMatrixDimensionsGr commands of
// src/c47/mathematics/matrix.c (and their shared static worker
// _SetMatrixDimensions): redimension the matrix in the given register to the
// dimensions read from the stack, in the normal or grow dimension mode. The
// register redim (redimMatrixRegister) and the dimension argument parsing
// (getDimensionArg) still live in the matrix bridge; this is the command-level
// wrapper that drives them.

const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const std_cross = "\x80\xd7";

// Item codes (items.h) selecting the redimension mode.
const ITM_M_DIM: u16 = 1526;
const ITM_M_DIM_GR: u16 = 1739;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

fn setMatrixDimensions(regist: u16, dim_mode: u16) void {
    var y: u32 = undefined;
    var x: u32 = undefined;
    if (!runtime.getDimensionArg(&y, &x)) {
        // No dimension argument entered.
    } else if (runtime.redimMatrixRegister(@intCast(regist), @intCast(y), @intCast(x), dim_mode)) {
        // Redimensioned successfully.
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [80]u8 = undefined;
            const message = bufPrintZ(&buffer, "Not enough memory for a {d}" ++ std_cross ++ "{d} matrix", .{ y, x }) catch "Not enough memory for a matrix";
            runtime.moreInfoOnError("In function _SetMatrixDimensions:", message, null, null);
        }
        return;
    }
}

pub export fn fnSetMatrixDimensions(regist: u16) callconv(.c) void {
    setMatrixDimensions(regist, ITM_M_DIM);
}

pub export fn fnSetMatrixDimensionsGr(regist: u16) callconv(.c) void {
    setMatrixDimensions(regist, ITM_M_DIM_GR);
}
