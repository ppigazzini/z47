const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn getExponent(result: *i32) bool {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return false;
    }

    if (runtime.realIsNaN(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function getExponent:", "cannot use NaN as X input of EXPT", null, null);
        return false;
    }

    if (runtime.realIsInfinite(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function getExponent:", "cannot use +/-inf as an input of EXPT", null, null);
        return false;
    }

    result.* = if (runtime.realIsZero(&x_value)) 0 else x_value.exponent + x_value.digits - 1;
    return true;
}

fn exptReal() callconv(.c) void {
    var exponent: i32 = undefined;
    var x_value: runtime.real_t = undefined;

    if (!getExponent(&exponent)) {
        return;
    }

    runtime.int32ToReal(exponent, &x_value);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn exptLonI() callconv(.c) void {
    var exponent: i32 = undefined;

    if (!getExponent(&exponent)) {
        return;
    }

    runtime.z47_math_wrappers_build_sign_result(exponent);
}

fn bnCommon(bnstar: bool) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.WP34S_Bernoulli(&x_value, &result, bnstar, &runtime.ctxtReal39);
    if (runtime.realIsNaN(&result)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnBn:", if (bnstar) "k must be a non-negative integer" else "k must be a positive integer", null, null);
    } else {
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

pub fn expt(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&exptReal, null, null, &exptLonI);
}

pub fn bn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(false);
}

pub fn bnStar(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(true);
}
