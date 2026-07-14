const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

fn shiftDigitsError(function_name: [:0]const u8, operation_name: []const u8) void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot {s} {s}", .{ operation_name, type_name }) catch "cannot shift digits";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message, null, null);
}

pub fn sdl(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        var real_value: runtime.real_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
        real_value.exponent += @as(i32, @intCast(unused_but_mandatory_parameter));
        runtime.convertRealToReal34ResultRegister(&real_value, runtime.REGISTER_X);
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtLongInteger) {
        var x_value: runtime.longInteger_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
        defer runtime.__gmpz_clear(&x_value[0]);

        for (0..unused_but_mandatory_parameter) |_| {
            runtime.__gmpz_mul_ui(&x_value[0], &x_value[0], 10);
        }

        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
        return;
    }

    shiftDigitsError("In function fnSdl:", "SDL");
}

pub fn sdr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        var real_value: runtime.real_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
        real_value.exponent -= @as(i32, @intCast(unused_but_mandatory_parameter));
        runtime.convertRealToReal34ResultRegister(&real_value, runtime.REGISTER_X);
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtLongInteger) {
        var x_value: runtime.longInteger_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
        defer runtime.__gmpz_clear(&x_value[0]);

        for (0..unused_but_mandatory_parameter) |_| {
            _ = runtime.__gmpz_tdiv_q_ui(&x_value[0], &x_value[0], 10);
            if (runtime.__gmpz_cmp_ui(&x_value[0], 0) == 0) {
                break;
            }
        }

        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
        return;
    }

    shiftDigitsError("In function fnSdr:", "SDR");
}
