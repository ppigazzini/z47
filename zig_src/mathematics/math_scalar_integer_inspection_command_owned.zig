const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn mantLonI() void {
    var x_value: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    x_value.exponent = 1 - x_value.digits;
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
}

fn mantReal() void {
    if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function mantReal:", "cannot use NaN as X input of MANT", null, null);
        return;
    }

    var result: runtime.real_t = undefined;
    _ = runtime.decimal128ToNumber(runtime.registerReal34Ptr(runtime.REGISTER_X), &result);
    result.exponent = 1 - result.digits;
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn roundiReal() callconv(.c) void {
    if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use NaN as X input of ROUNDI", null, null);
        return;
    }

    if (runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use +/-inf as an input of ROUNDI", null, null);
        return;
    }

    const exponent = runtime.real34GetExponent(runtime.registerReal34Ptr(runtime.REGISTER_X));
    if (exponent > 1001) {
        const error_code = if (runtime.decQuadIsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == 0)
            runtime.ERROR_OVERFLOW_PLUS_INF
        else
            runtime.ERROR_OVERFLOW_MINUS_INF;
        runtime.displayCalcErrorMessage(error_code, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "real exponent exceeds long-integer range", null, null);
        return;
    }

    runtime.convertReal34ToLongIntegerRegister(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_UP);
}

fn ulpLongInteger() void {
    runtime.z47_math_wrappers_build_sign_result(1);
}

fn ulpShortInteger() void {
    runtime.convertUInt64ToShortIntegerRegister(0, 1, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

fn ulpReal() void {
    var next_value: runtime.real34_t = undefined;

    if (runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnUlp:", "cannot use +/-inf input of ULP", null, null);
    }

    runtime.real34NextPlus(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value);
    if (runtime.real34IsInfinite(&next_value)) {
        runtime.real34NextMinus(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value);
        runtime.real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value, runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        runtime.real34Subtract(&next_value, runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn decompError() void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name}) catch "cannot calculate Decomp";

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

pub fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger => ulpLongInteger(),
        runtime.dtShortInteger => ulpShortInteger(),
        runtime.dtReal34 => ulpReal(),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function fnUlp:", "cannot calculate ULP for current X type", null, null);
            return;
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => mantLonI(),
        runtime.dtReal34 => mantReal(),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function mantError:", "cannot calculate MANT for current X type", null, null);
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger, runtime.dtShortInteger => {},
        runtime.dtReal34 => roundiReal(),
        runtime.dtReal34Matrix => runtime.elementwiseRema(&roundiReal),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function roundiError:", "cannot calculate ROUNDI for current X type", null, null);
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtShortInteger) {
        runtime.retained.z47_math_wrappers_retained_fnRound(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
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
