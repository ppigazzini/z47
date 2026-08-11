const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

// MAX_LONG_INTEGER_SIZE_IN_BITS (defines.h).
const MAX_LONG_INTEGER_SIZE_IN_BITS: u16 = 3328;

// The wrong-type refusals of fnUlp / mantError / roundiError, which name the
// data type X actually holds. The three sentences differ, so the format string
// travels with the call site.
fn reportTypeError(function_name: [*:0]const u8, comptime format: []const u8) void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }
    var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&buffer, format, .{type_name}) catch "";
    runtime.moreInfoOnError(function_name, message, null, null);
}

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
        runtime.moreInfoOnError("In function roundiReal:", "cannot use \xc2\xb1\xe2\x88\x9e as an input of ROUNDI", null, null);
        return;
    }

    const exponent = runtime.real34GetExponent(runtime.registerReal34Ptr(runtime.REGISTER_X));
    if (exponent > 1001) {
        const error_code = if (runtime.decQuadIsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == 0)
            runtime.ERROR_OVERFLOW_PLUS_INF
        else
            runtime.ERROR_OVERFLOW_MINUS_INF;
        runtime.displayCalcErrorMessage(error_code, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
            const message = runtime.bufPrintZ(&buffer, "Converting a real exponent of {d} would result in a value exceeding {d} bits!", .{ exponent, MAX_LONG_INTEGER_SIZE_IN_BITS }) catch "";
            // Empty strings, not null, for m3/m4: upstream passes "", "", which
            // is what selects moreInfoOnError's four-line branch.
            runtime.moreInfoOnError("In function roundiReal:", message, "", "");
        }
        // C roundiReal (roundi.c): NO return here — after the overflow error it still
        // falls through to convertReal34ToLongIntegerRegister (unlike NaN/Inf which return).
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
        runtime.moreInfoOnError("In function fnUlp:", "cannot use \xc2\xb1\xe2\x88\x9e input of ULP?", null, null);
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
            reportTypeError("In function fnUlp:", "cannot calculate ULP? with {s} in X");
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
            reportTypeError("In function mantError:", "cannot calculate MANT for {s}");
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
            reportTypeError("In function roundiError:", "cannot calculate ROUNDI for {s}");
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}
