// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the STATS-matrix undo helpers of src/c47/mathematics/matrix.c:
// saveStatsMatrix backs up the named STATS matrix into a temp register before a
// statistics operation, and recallStatsMatrix restores it on undo. Both delegate
// to the still-bridged initMatrixRegister and the register/named-variable
// surface.

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn saveStatsMatrix() callconv(.c) bool {
    const reg_stats = runtime.findNamedVariable("STATS");

    if (reg_stats != runtime.INVALID_VARIABLE) {
        if (runtime.getRegisterDataType(reg_stats) == runtime.dtReal34Matrix) {
            const header = runtime.registerMatrixHeader(reg_stats);
            const rows = header.matrixRows;
            const cols = header.matrixColumns;

            // Initialize memory for the matrix.
            if (runtime.initMatrixRegister(runtime.TEMP_REGISTER_2_SAVED_STATS, rows, cols, false)) {
                runtime.copySourceRegisterToDestRegister(reg_stats, runtime.TEMP_REGISTER_2_SAVED_STATS);
                return true; // backed up
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                if (runtime.extra_info_on_calc_error) {
                    var buffer: [96]u8 = undefined;
                    const message = bufPrintZ(&buffer, "Not enough memory for STATS undo matrix: rows={d}, cols={d}", .{ rows, cols }) catch "Not enough memory for STATS undo matrix";
                    runtime.moreInfoOnError("In function saveStatsMatrix:", message, null, null);
                }
                return false;
            }
        } else {
            return true; // nothing to backup
        }
    } else {
        return true; // nothing to backup
    }
}

pub export fn recallStatsMatrix() callconv(.c) bool {
    var reg_stats = runtime.TEMP_REGISTER_2_SAVED_STATS;

    if (runtime.getRegisterDataType(reg_stats) == runtime.dtReal34Matrix) {
        const header = runtime.registerMatrixHeader(reg_stats);
        const rows = header.matrixRows;
        const cols = header.matrixColumns;
        if (cols == 2 and rows >= 1) {
            reg_stats = runtime.findNamedVariable("STATS");
            if (reg_stats == runtime.INVALID_VARIABLE) {
                runtime.allocateNamedVariable("STATS", runtime.dtReal34, runtime.REAL34_SIZE_IN_BLOCKS);
                reg_stats = runtime.findNamedVariable("STATS");
            }
            runtime.clearRegister(reg_stats);

            // Initialize memory for the matrix.
            if (runtime.initMatrixRegister(reg_stats, rows, cols, false)) {
                runtime.copySourceRegisterToDestRegister(runtime.TEMP_REGISTER_2_SAVED_STATS, reg_stats);
                runtime.clearRegister(runtime.TEMP_REGISTER_2_SAVED_STATS);
                return true; // restored
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_TI_UNDO_FAILED, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                if (runtime.extra_info_on_calc_error) {
                    var buffer: [128]u8 = undefined;
                    const message = bufPrintZ(&buffer, "Creation of STATS matrix from TEMP2 failed, likely due to insufficient memory: rows={d}, cols={d}", .{ rows, cols }) catch "Creation of STATS matrix from TEMP2 failed";
                    runtime.moreInfoOnError("In function recallStatsMatrix:", message, null, null);
                }
                return false; // not enough memory
            }
        } else {
            return false; // TEMP_REGISTER_2_SAVED_STATS is a non-STATS dimensioned register
        }
    } else {
        return false; // TEMP_REGISTER_2_SAVED_STATS is no real34 matrix
    }
}
