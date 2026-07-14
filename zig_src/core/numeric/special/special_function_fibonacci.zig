const circular_trig_owned = @import("../trig/circular_trig.zig");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
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
    math_command_wrappers.cosComplex(res_real, res_imag, res_real, res_imag, real_context);
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

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&fibReal, &fibCplx, null, &fibLonI);
}
