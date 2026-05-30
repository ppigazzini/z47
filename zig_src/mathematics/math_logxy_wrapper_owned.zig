const runtime = @import("math_command_wrappers_runtime.zig");
const transcendental_wrapper_owned = @import("math_transcendental_wrapper_owned.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
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
        transcendental_wrapper_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        transcendental_wrapper_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
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
        transcendental_wrapper_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
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

    transcendental_wrapper_owned.lnRealValue(&x, &x, &runtime.ctxtReal39);
    runtime.realDivide(&x, denom, &x, &runtime.ctxtReal34);
    if (!runtime.realIsAnInteger(&x)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.convertRealToLongIntegerRegister(&x, runtime.REGISTER_X, runtime.DEC_ROUND_HALF_EVEN);
    }
}
