const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn decompError() void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name}) catch "cannot calculate Decomp";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnDecomp:", message, null, null);
}

fn decompLongInteger() void {
    var value: runtime.longInteger_t = undefined;

    runtime.liftStack();
    runtime.__gmpz_init(&value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_set_ui(&value[0], 1);
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
}

fn decompReal() void {
    const x_value = runtime.registerReal34Ptr(runtime.REGISTER_X).*;

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();

    if (runtime.real34IsNaN(&x_value)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_DOWN);
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_Y, runtime.DEC_ROUND_HALF_DOWN);
        return;
    }

    if (runtime.real34IsInfinite(&x_value)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_DOWN);
        runtime.convertRealToLongIntegerRegister(
            if (runtime.real34IsNegative(&x_value)) runtime.z47_math_wrappers_const_minus_1() else runtime.z47_math_wrappers_const_1(),
            runtime.REGISTER_Y,
            runtime.DEC_ROUND_HALF_DOWN,
        );
        return;
    }

    const saved_system_flags0 = runtime.systemFlags0;
    const saved_system_flags1 = runtime.systemFlags1;
    var sign: i16 = 0;
    var int_part: u64 = 0;
    var numer: u64 = 0;
    var denom: u64 = 0;
    var less_equal_greater: i16 = 0;
    var value: runtime.longInteger_t = undefined;

    runtime.clearSystemFlag(runtime.FLAG_PROPFR);
    _ = runtime.fraction(runtime.REGISTER_Y, &sign, &int_part, &numer, &denom, &less_equal_greater);
    runtime.systemFlags0 = saved_system_flags0;
    runtime.systemFlags1 = saved_system_flags1;

    runtime.__gmpz_init(&value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(numer)));
    if (sign == -1) {
        value[0]._mp_size = -value[0]._mp_size;
    }
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_Y);

    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(denom)));
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
}

pub fn decomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => decompLongInteger(),
        runtime.dtReal34 => decompReal(),
        else => decompError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
    runtime.adjustResult(runtime.REGISTER_Y, false, false, runtime.REGISTER_Y, no_register, no_register);
}
