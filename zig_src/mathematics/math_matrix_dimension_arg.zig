// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix dimension helpers of src/c47/mathematics/matrix.c:
// getMatrixDims reads a register matrix's dimensions, and getDimensionArg (with
// its static worker getSingleDimension) reads a rows/columns argument pair from
// the X and Y registers as bounded long integers. These feed the matrix
// creation / redimension commands.

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const mpz_struct = runtime.mpz_struct;

const nim_register_line = runtime.REGISTER_X;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub export fn getMatrixDims(regist: calcRegister_t, func_name: [*:0]const u8, rows: *u16, cols: *u16) callconv(.c) bool {
    const data_type = runtime.getRegisterDataType(regist);
    if (data_type == runtime.dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(regist, &x);
        rows.* = x.header.matrixRows;
        cols.* = x.header.matrixColumns;
        return true;
    } else if (data_type == runtime.dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(regist, &x);
        rows.* = x.header.matrixRows;
        cols.* = x.header.matrixColumns;
        return true;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError(func_name, message, "is not a matrix.", "");
        }
        return false;
    }
}

// mpz_sgn(x) <= 0: a long integer is negative or zero when its size field is
// non-positive (GMP stores the sign in _mp_size).
inline fn longIntegerIsNegativeOrZero(value: *const mpz_struct) bool {
    return value._mp_size <= 0;
}

fn getSingleDimension(reg: calcRegister_t, d: *u32) bool {
    var tmp: runtime.longInteger_t = undefined;
    var res = false;

    if (!runtime.getRegisterAsLongInt(reg, &tmp[0], null)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [80]u8 = undefined;
            const which = if (reg == runtime.REGISTER_X) "columns" else "rows";
            const type_name = runtime.getRegisterDataTypeName(reg, true, false);
            const message = bufPrintZ(&buffer, "invalid data type {s} for {s}", .{ type_name, which }) catch "invalid data type";
            runtime.moreInfoOnError("In function getSingleDimension:", message, null, null);
        }
        runtime.__gmpz_clear(&tmp[0]);
        return false;
    }

    if (longIntegerIsNegativeOrZero(&tmp[0]) or runtime.__gmpz_cmp_ui(&tmp[0], 4096) > 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const which = if (reg == runtime.REGISTER_X) "columns" else "rows";
            const message = bufPrintZ(&buffer, "invalid number of {s}", .{which}) catch "invalid number";
            runtime.moreInfoOnError("In function getSingleDimension:", message, null, null);
        }
    } else {
        d.* = @intCast(runtime.__gmpz_get_ui(&tmp[0]));
        res = true;
    }

    runtime.__gmpz_clear(&tmp[0]);
    return res;
}

pub export fn getDimensionArg(rows: *u32, cols: *u32) callconv(.c) bool {
    // Get Size or I&J for STOIJ from REGISTER_X and REGISTER_Y.
    return getSingleDimension(runtime.REGISTER_X, cols) and getSingleDimension(runtime.REGISTER_Y, rows);
}
