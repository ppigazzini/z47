const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn decompError() void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name}) catch "cannot calculate Decomp";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
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
    var fraction_sign: i16 = 0;
    var fraction_int_part: u64 = 0;
    var numer: u64 = 0;
    var denom: u64 = 0;
    var less_equal_greater: i16 = 0;
    var abs_x: runtime.real34_t = undefined;
    var int_part: runtime.real34_t = undefined;
    var frac_part: runtime.real34_t = undefined;
    var value: runtime.longInteger_t = undefined;

    // The integer part is split off first, so that fraction() only approximates
    // the fractional part and the integer part is carried exactly.
    // real34CopyAbs is a decQuad macro: the copy with its sign bit cleared.
    abs_x = x_value;
    abs_x.bytes[15] &= 0x7f;
    runtime.real34ToIntegralValue(&abs_x, &int_part, runtime.DEC_ROUND_DOWN);
    runtime.real34Subtract(&abs_x, &int_part, &frac_part);
    runtime.registerReal34Ptr(runtime.REGISTER_Y).* = frac_part;

    runtime.clearSystemFlag(runtime.FLAG_PROPFR);
    _ = runtime.fraction(runtime.REGISTER_Y, &fraction_sign, &fraction_int_part, &numer, &denom, &less_equal_greater);
    runtime.systemFlags0 = saved_system_flags0;
    runtime.systemFlags1 = saved_system_flags1;

    // convertReal34ToLongInteger initialises its result.
    runtime.convertReal34ToLongInteger(&int_part, &value[0], runtime.DEC_ROUND_DOWN);
    defer runtime.__gmpz_clear(&value[0]);

    // Both parts go out through a uint32_t, so the 64-bit accumulation above is
    // truncated to its low 32 bits rather than widened by the host's word size.
    runtime.__gmpz_mul_ui(&value[0], &value[0], @as(u32, @truncate(denom)));
    runtime.__gmpz_add_ui(&value[0], &value[0], @as(u32, @truncate(numer)));
    if (runtime.real34IsNegative(&x_value)) {
        value[0]._mp_size = -@as(c_int, @intCast(@abs(value[0]._mp_size)));
    }
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_Y);

    runtime.__gmpz_set_ui(&value[0], @as(u32, @truncate(denom)));
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
