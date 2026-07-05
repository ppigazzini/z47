const runtime = @import("math_command_wrappers_runtime.zig");

fn realCompareGreaterEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    // Faithful to C realCompareGreaterEqual = isPositive(lhs-rhs) || isZero (FALSE for NaN).
    // realCompareLessThan(rhs, lhs) == lhs>rhs strictly; OR Equal gives >=, false for NaN.
    return runtime.realCompareLessThan(rhs, lhs) or runtime.realCompareEqual(lhs, rhs);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn minusOneOverE() runtime.real_t {
    var value = runtime.z47_math_wrappers_const_1oneE().*;
    runtime.realChangeSign(&value);
    return value;
}

fn wInvReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    runtime.WP34S_InverseW(&x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn wInvCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.WP34S_InverseComplexW(&real_value, &imag_value, &result_real, &result_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

fn wPosReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (realCompareGreaterEqual(&x_value, &limit)) {
        runtime.WP34S_LambertW(&x_value, &result, false, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.getSystemFlag(runtime.FLAG_CPXRES)) {
        runtime.WP34S_ComplexLambertW(&x_value, runtime.z47_math_wrappers_const_0(), &result, &result_imag, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&result, &result_imag, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wPosReal:", "X < -e^(-1)", "and CPXRES is not set!", null);
    }
}

fn wPosCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.WP34S_ComplexLambertW(&real_value, &imag_value, &result_real, &result_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

fn wNegReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (realCompareGreaterEqual(&x_value, &limit) and realCompareLessEqual(&x_value, runtime.z47_math_wrappers_const_0())) {
        runtime.WP34S_LambertW(&x_value, &result, true, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wNegReal:", "X < -e^(-1) || 0 < X", null, null);
    }
}

fn wNegCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value)) {
        if (realCompareGreaterEqual(&real_value, &limit) and realCompareLessEqual(&real_value, runtime.z47_math_wrappers_const_0())) {
            runtime.WP34S_LambertW(&real_value, &result, true, &runtime.ctxtReal39);
            runtime.convertComplexToResultRegister(&result, runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function wNegCplx:", "X < -e^(-1) || 0 < X", null, null);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wNegCplx:", "Cannot calculate Wm for complex number with non-zero imaginary part", null, null);
    }
}

pub fn fnWpositive(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wPosReal, &wPosCplx);
}

pub fn fnWnegative(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wNegReal, &wNegCplx);
}

pub fn fnWinverse(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wInvReal, &wInvCplx);
}