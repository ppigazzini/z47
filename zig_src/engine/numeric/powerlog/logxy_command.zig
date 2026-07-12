const logxy_owned = @import("logxy.zig");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const transcendental_command_owned = @import("../special/transcendental_command.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn logXYComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    y_real: *const runtime.real_t,
    y_imag: *const runtime.real_t,
    result_real: *runtime.real_t,
    result_imag: *runtime.real_t,
) void {
    var ln_x_real: runtime.real_t = undefined;
    var ln_x_imag: runtime.real_t = undefined;

    @import("../ln_complex.zig").lnComplex(y_real, y_imag, result_real, result_imag, &runtime.ctxtReal39);
    @import("../ln_complex.zig").lnComplex(x_real, x_imag, &ln_x_real, &ln_x_imag, &runtime.ctxtReal39);
    runtime.divComplexComplex(result_real, result_imag, &ln_x_real, &ln_x_imag, result_real, result_imag, &runtime.ctxtReal39);
}

fn logXYArgsHandled(x_real: *const runtime.real_t, x_imag: ?*const runtime.real_t, y_real: *const runtime.real_t, y_imag: ?*const runtime.real_t) bool {
    const x_zero = runtime.realIsZero(x_real) and (x_imag == null or runtime.realIsZero(x_imag.?));
    const y_zero = runtime.realIsZero(y_real) and (y_imag == null or runtime.realIsZero(y_imag.?));

    if (x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_PLUS_INF, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("checkArgs", "cannot calculate LogXY with x=0 and y=0", null, null);
        }
        return true;
    }

    if (!x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_minus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_MINUS_INF, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("checkArgs", "cannot calculate LogXY with x=0 and y!=0", null, null);
        }
        return true;
    }

    if (x_zero and !y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
        return true;
    }

    return false;
}

fn logxyRealCore(x_real: *const runtime.real_t, y_real: *const runtime.real_t, real_context: *runtime.realContext_t) void {
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (logXYArgsHandled(x_real, null, y_real, null)) {
        return;
    }

    if (runtime.realIsNegative(x_real) or runtime.realIsNegative(y_real)) {
        logXYComplex(x_real, runtime.z47_math_wrappers_const_0(), y_real, runtime.z47_math_wrappers_const_0(), &result_real, &result_imag);

        if (!runtime.realIsZero(&result_imag)) {
            if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
                runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
                return;
            }

            if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
                runtime.realSetNaN(&result_real);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError("logxy", "cannot calculate LogXY with x<0 or y<0 when flag I is not set", null, null);
                return;
            }
        }
    } else {
        logxy_owned.logxyRealValue(y_real, x_real, &result_real, real_context);
    }

    runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
}

fn logXYLongInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.convertReal34ToLongIntegerRegister(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.REGISTER_X, runtime.DEC_ROUND_DOWN);
    }
}

fn logXYShortInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    const base = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("logxy", "cannot calculate LogXY with x=0", null, null);
            return;
        }

        if (runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
            runtime.clearSystemFlag(runtime.FLAG_CARRY);
        } else {
            runtime.setSystemFlag(runtime.FLAG_CARRY);
        }

        runtime.fnChangeBase(@intCast(base));
    }
}

fn logXYReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);
}

fn logXYCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    if (logXYArgsHandled(&x_real, &x_imag, &y_real, &y_imag)) {
        return;
    }

    logXYComplex(&x_real, &x_imag, &y_real, &y_imag, &result_real, &result_imag);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

pub fn fnLogXY(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&logXYReal, &logXYCplx, &logXYShortInt, &logXYLongInt);
}

pub fn logxyReal(denom: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &a)) {
        return;
    }

    if (runtime.realIsZero(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&a, runtime.z47_math_wrappers_const_minus_infinity());
    } else if (runtime.realIsInfinite(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            if (!runtime.realIsNegative(&a)) {
                copyReal(&a, runtime.z47_math_wrappers_const_plus_infinity());
            } else {
                runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &a, &runtime.ctxtReal39);
                runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), &a, runtime.REGISTER_X);
                return;
            }
        } else {
            runtime.realSetNaN(&a);
        }
    } else if (!runtime.realIsNegative(&a)) {
        transcendental_command_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        transcendental_command_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &b, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
        return;
    } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetNaN(&a);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
}

pub fn logxyCplx(denom: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    if (runtime.realIsZero(&a) and runtime.realIsZero(&b)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&a, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&b);
    } else {
        runtime.realRectangularToPolar(&a, &b, &a, &b, &runtime.ctxtReal39);
        transcendental_command_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        runtime.realDivide(&b, denom, &b, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub fn logxyLonI(denom: *const runtime.real_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNegative(&x) or runtime.realIsZero(&x)) {
        logxyReal(denom);
        return;
    }

    transcendental_command_owned.lnRealValue(&x, &x, &runtime.ctxtReal39);
    runtime.realDivide(&x, denom, &x, &runtime.ctxtReal34);
    if (!runtime.realIsAnInteger(&x)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.convertRealToLongIntegerRegister(&x, runtime.REGISTER_X, runtime.DEC_ROUND_HALF_EVEN);
    }
}
