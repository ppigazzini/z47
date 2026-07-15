const runtime = @import("../command_wrappers/runtime.zig");

fn invertReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = if (runtime.realIsNegative(&x))
                runtime.z47_math_wrappers_const_minus_infinity()
            else
                runtime.z47_math_wrappers_const_plus_infinity();
        } else {
            runtime.z47_math_wrappers_report_invert_real_divide_by_zero_error();
            return;
        }
    } else if (runtime.realIsInfinite(&x)) {
        const set_negative_zero = runtime.realIsNegative(&x) and runtime.getSystemFlag(runtime.FLAG_SPCRES);

        runtime.realSetZero(&x);
        if (set_negative_zero) {
            runtime.realChangeSign(&x);
        }
    } else if (runtime.realCompareAbsEqual(&x, runtime.z47_math_wrappers_const_1())) {
        return;
    } else {
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn invertCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.divRealComplex(runtime.z47_math_wrappers_const_1(), &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub fn invert(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        runtime.fnInvertMatrix(0);
        return;
    }

    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&invertReal, &invertCplx);
}
