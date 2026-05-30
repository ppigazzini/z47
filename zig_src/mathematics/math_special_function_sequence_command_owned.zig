const circular_trig_owned = @import("math_circular_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

extern fn cosComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void;

fn realCompareGreaterEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(lhs, rhs);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
}

fn erfReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn erfcReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erfc(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

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

    var result: u64 = 1;
    var remaining = value;

    if (remaining > 1) {
        var multiplier = remaining;
        if ((remaining & 1) != 0) {
            multiplier += remaining;
            remaining -= 1;
        }
        result = multiplier;
        remaining -= 2;
        while (remaining > 0) : (remaining -= 2) {
            multiplier += remaining;
            result *= multiplier;
        }
    }

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
    for (1..n + 1) |i| {
        runtime.__gmpz_mul_ui(&result[0], &result[0], i);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn fibonacciReal(n: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    runtime.realPower(runtime.z47_math_wrappers_const_phi(), n, &a, real_context);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &a, &b, real_context);
    runtime.realMultiply(runtime.z47_math_wrappers_const_pi(), n, res, real_context);
    circular_trig_owned.convertAngleToSinCosTan(res, runtime.amRadian, null, res, null, real_context);
    runtime.realMultiply(&b, res, &b, real_context);
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_5(), res, real_context);
    runtime.realSubtract(&a, &b, &a, real_context);
    runtime.realDivide(&a, res, res, real_context);
}

fn fibonacciComplex(
    n_real: *const runtime.real_t,
    n_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a_real: runtime.real_t = undefined;
    var a_imag: runtime.real_t = undefined;
    var b_real: runtime.real_t = undefined;
    var b_imag: runtime.real_t = undefined;

    _ = runtime.PowerComplex(runtime.z47_math_wrappers_const_phi(), runtime.z47_math_wrappers_const_0(), n_real, n_imag, &a_real, &a_imag, real_context);
    runtime.divRealComplex(runtime.z47_math_wrappers_const_1(), &a_real, &a_imag, &b_real, &b_imag, real_context);
    runtime.mulComplexComplex(runtime.z47_math_wrappers_const_pi(), runtime.z47_math_wrappers_const_0(), n_real, n_imag, res_real, res_imag, real_context);
    cosComplex(res_real, res_imag, res_real, res_imag, real_context);
    runtime.mulComplexComplex(&b_real, &b_imag, res_real, res_imag, &b_real, &b_imag, real_context);
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_5(), res_real, real_context);
    runtime.realSetZero(res_imag);
    runtime.realSubtract(&a_real, &b_real, &a_real, real_context);
    runtime.realSubtract(&a_imag, &b_imag, &a_imag, real_context);
    runtime.divComplexComplex(&a_real, &a_imag, res_real, res_imag, res_real, res_imag, real_context);
}

fn fibReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    fibonacciReal(&value, &value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn fibCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value)) {
        fibonacciReal(&real_value, &real_value, &runtime.ctxtReal39);
    } else {
        fibonacciComplex(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn fibLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var result: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    const neg = value[0]._mp_size < 0;
    if (neg) {
        value[0]._mp_size = -value[0]._mp_size;
    }

    if (runtime.__gmpz_cmp_ui(&value[0], 4791) > 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);

    runtime.z47_math_wrappers_long_integer_fibonacci(@intCast(runtime.__gmpz_get_ui(&value[0])), &result[0]);
    if (neg and (value[0]._mp_size == 0 or (value[0]._mp_d[0] & 1) == 0)) {
        result[0]._mp_size = -result[0]._mp_size;
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn ixyz() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var a_value: runtime.real_t = undefined;
    var b_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &a_value) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &b_value)) {
        if (realCompareGreaterEqual(&x_value, runtime.z47_math_wrappers_const_0()) and
            realCompareLessEqual(&x_value, runtime.z47_math_wrappers_const_1()) and
            realCompareGreaterThan(&a_value, runtime.z47_math_wrappers_const_0()) and
            realCompareGreaterThan(&b_value, runtime.z47_math_wrappers_const_0()))
        {
            runtime.WP34S_betai(&b_value, &a_value, &x_value, &result, &runtime.ctxtReal39);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
            runtime.fnDropY(0);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                runtime.fnDropY(0);
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function fnIxyz:", "not in 0<=x<=1, a>0, b>0", null, null);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnIxyz:", "cannot calculate Ixyz for current X, Y, Z types", null, null);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&erfReal, null);
}

pub fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&erfcReal, null);
}

pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&factReal, &factCplx, &factShoI, &factLonI);
}

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&fibReal, &fibCplx, null, &fibLonI);
}

pub fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    ixyz();
}
