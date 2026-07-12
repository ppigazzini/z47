const runtime = @import("command_wrappers_runtime.zig");
const abi = @import("abi"); // std-only integer primitives (math owners keep abi private via runtime)

fn factReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    runtime.WP34S_Factorial(&x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn factCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.realAdd(&real_value, runtime.z47_math_wrappers_const_1(), &real_value, &runtime.ctxtReal39);
    runtime.WP34S_ComplexGamma(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn factShoI() callconv(.c) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &sign, &value);

    if (sign == 1) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factShoI:", "cannot calculate factorial(short integer)", null, null);
        return;
    }

    if (value > 20) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factShoI:", "cannot calculate factorial(short integer)", null, null);
        return;
    }

    const result = abi.int_math.factorialU64(value); // value <= 20 guaranteed above

    if (result > runtime.shortIntegerMask) {
        runtime.setSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.convertUInt64ToShortIntegerRegister(0, result, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

fn factLonI() callconv(.c) void {
    const max_factorial: u32 = 450;

    var value: runtime.longInteger_t = undefined;
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    if (value[0]._mp_size < 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factLonI:", "cannot calculate factorial(long integer)", null, null);
        return;
    }

    if (runtime.__gmpz_cmp_ui(&value[0], max_factorial) > 0) {
        runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        factReal();
        return;
    }

    const n: u32 = @intCast(runtime.__gmpz_get_ui(&value[0]));
    var result: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_set_ui(&result[0], 1);
    const n_c_ulong: c_ulong = @intCast(n);
    var i: c_ulong = 1;
    while (i <= n_c_ulong) : (i += 1) {
        runtime.__gmpz_mul_ui(&result[0], &result[0], i);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&factReal, &factCplx, &factShoI, &factLonI);
}
