const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn realCompareGreaterEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    // Faithful to C realCompareGreaterEqual = isPositive(lhs-rhs) || isZero (FALSE for NaN).
    // realCompareLessThan(rhs, lhs) == lhs>rhs strictly; OR Equal gives >=, false for NaN.
    return runtime.realCompareLessThan(rhs, lhs) or runtime.realCompareEqual(lhs, rhs);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
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

pub fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    ixyz();
}
