const std = @import("std");
const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

// MAX_LONG_INTEGER_SIZE_IN_BITS (defines.h).
const MAX_LONG_INTEGER_SIZE_IN_BITS: u16 = 3328;

// decQuad limits (decQuad.h): the smallest exponent a Real34 unit in the last
// place can take.
const DECQUAD_Emin: i32 = -6143;
const DECQUAD_Pmax: i32 = 34;

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

// TMP_STR_LENGTH (defines.h): the size of the shared tmpString buffer.
const TMP_STR_LENGTH = 2560;

// The mantissa of a long integer: its decimal digits with the exponent that puts
// the point after the first one, parsed once into the Real34 of X. The longest
// long integer is about a thousand digits, well inside tmpString.
fn mantLonI() void {
    var x: runtime.mpz_struct = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x);
    defer runtime.__gmpz_clear(&x);
    const buffer = runtime.tmpString[0..TMP_STR_LENGTH];
    runtime.longIntegerToAllocatedString(&x, buffer.ptr, TMP_STR_LENGTH);
    const length = std.mem.indexOfScalar(u8, buffer, 0).?;
    const digits = length - @intFromBool(buffer[0] == '-');
    const exponent: i32 = 1 - @as(i32, @intCast(digits));
    const suffix = runtime.bufPrintZ(buffer[length..], "e{d}", .{exponent}) catch unreachable;
    const text: [:0]const u8 = buffer[0 .. length + suffix.len :0];
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, runtime.REAL34_SIZE_IN_BLOCKS, runtime.amNone);
    runtime.stringToReal34(text.ptr, runtime.registerReal34Ptr(runtime.REGISTER_X));
}

fn mantReal() void {
    if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
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
    var rounded: runtime.mpz_struct = undefined;
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);

    if (runtime.real34IsNaN(x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use NaN as X input of ROUNDI", null, null);
        return;
    }

    if (runtime.real34IsInfinite(x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use \xc2\xb1\xe2\x88\x9e as an input of ROUNDI", null, null);
        return;
    }

    runtime.convertReal34ToLongInteger(x, &rounded, runtime.DEC_ROUND_HALF_UP);
    defer runtime.__gmpz_clear(&rounded);
    const bits = runtime.__gmpz_sizeinbase(&rounded, 2);
    if (bits > MAX_LONG_INTEGER_SIZE_IN_BITS) {
        const error_code = if (runtime.real34IsNegative(x)) runtime.ERROR_OVERFLOW_MINUS_INF else runtime.ERROR_OVERFLOW_PLUS_INF;
        runtime.displayCalcErrorMessage(error_code, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
            const message = runtime.bufPrintZ(&buffer, "The rounded integer needs {d} bits, exceeding the {d} bit limit!", .{ bits, MAX_LONG_INTEGER_SIZE_IN_BITS }) catch "";
            // Empty strings, not null, for m3/m4: upstream passes "", "", which
            // is what selects moreInfoOnError's four-line branch.
            runtime.moreInfoOnError("In function roundiReal:", message, "", "");
        }
        return;
    }

    runtime.convertLongIntegerToLongIntegerRegister(&rounded, runtime.REGISTER_X);
}

// Every element of a real matrix rounded half up to an integer; a special
// element refuses the whole matrix before any element is touched.
fn roundiRema() void {
    var x: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
    const elements: u32 = @as(u32, x.header.matrixRows) * @as(u32, x.header.matrixColumns);

    const elements_ptr: [*]runtime.real34_t = abi.matrixRealElems(&x);
    var i: u32 = 0;
    while (i < elements) : (i += 1) {
        if (runtime.real34IsSpecial(&elements_ptr[i])) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            return;
        }
    }

    i = 0;
    while (i < elements) : (i += 1) {
        runtime.real34ToIntegralValue(&elements_ptr[i], &elements_ptr[i], runtime.DEC_ROUND_HALF_UP);
    }
}

fn ulpLongInteger() void {
    runtime.z47_math_wrappers_build_sign_result(1);
}

fn ulpShortInteger() void {
    runtime.convertUInt64ToShortIntegerRegister(0, 1, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

// The unit in the last place of a Real34: one at the exponent of its last
// digit, never below the smallest subnormal. False when X is infinite, which
// is refused before the result is adjusted.
fn ulpReal() bool {
    var ulp: runtime.real_t = undefined;
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);

    if (runtime.real34IsInfinite(x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function fnUlp:", "cannot use \xc2\xb1\xe2\x88\x9e input of ULP?", null, null);
        return false;
    }

    if (!runtime.real34IsNaN(x)) {
        runtime.real34ToReal(x, &ulp);
        var exponent: i32 = if (runtime.realIsZero(&ulp)) DECQUAD_Emin - DECQUAD_Pmax + 1 else ulp.exponent + ulp.digits - DECQUAD_Pmax;
        if (exponent < DECQUAD_Emin - DECQUAD_Pmax + 1) {
            exponent = DECQUAD_Emin - DECQUAD_Pmax + 1;
        }
        runtime.realSetOne(&ulp);
        ulp.exponent = exponent;
        runtime.convertRealToReal34ResultRegister(&ulp, runtime.REGISTER_X);
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    return true;
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
        runtime.dtReal34 => {
            if (!ulpReal()) {
                return;
            }
        },
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
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
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
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
        runtime.dtReal34Matrix => roundiRema(),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
            reportTypeError("In function roundiError:", "cannot calculate ROUNDI for {s}");
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}
