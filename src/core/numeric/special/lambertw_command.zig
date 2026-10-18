const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

// -1/e, the branch point below which W has no real value.
fn get_1oneE(a: *real_t) *real_t {
    copyReal(a, runtime.z47_math_wrappers_const_1oneE());
    a.bits |= 0x80; // DECNEG
    return a;
}

fn wInvReal() callconv(.c) void {
    var x: real_t = undefined;
    var res: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_InverseW(&x, &res, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&res, runtime.REGISTER_X, runtime.amNone);
}

fn wInvCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var res: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_InverseComplexW(&x, &res, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&res, runtime.REGISTER_X);
}

fn wPosReal() callconv(.c) void {
    var x: real_t = undefined;
    var res: cplx_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function wPosReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of W when flag SPCRES is not set", null, null);
        }
        return;
    }

    _ = get_1oneE(&res.Real);
    if (runtime.realIsNaN(&x) or runtime.realCompareGreaterEqual(&x, &res.Real)) {
        runtime.WP34S_LambertW(&x, &res.Real, false, &runtime.ctxtReal75);
        runtime.convertRealToResultRegister(&res.Real, runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.getSystemFlag(runtime.FLAG_CPXRES)) {
        var z: cplx_t = undefined;

        copyReal(&z.Real, &x);
        runtime.realSetZero(&z.Imag);
        runtime.WP34S_ComplexLambertW(&z, &res, &runtime.ctxtReal75);
        runtime.convertComplexToResultRegister(&res, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function wPosReal:", "X < -e^(-1)", "and CPXRES is not set!", null);
        }
    }
}

fn wPosCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var res: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if ((runtime.realIsInfinite(&x.Real) or runtime.realIsInfinite(&x.Imag)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function wPosCplx:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of W when flag SPCRES is not set", null, null);
        }
        return;
    }

    runtime.WP34S_ComplexLambertW(&x, &res, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&res, runtime.REGISTER_X);
}

fn wNegReal() callconv(.c) void {
    var x: real_t = undefined;
    var res: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNaN(&x) or (runtime.realCompareGreaterEqual(&x, get_1oneE(&res)) and runtime.realCompareLessEqual(&x, runtime.z47_math_wrappers_const_0()))) {
        runtime.WP34S_LambertW(&x, &res, true, &runtime.ctxtReal75);
        runtime.convertRealToResultRegister(&res, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function wNegReal:", "X < -e^(-1) || 0 < X", null, null);
        }
    }
}

fn wNegCplx() callconv(.c) void {
    var res: real_t = undefined;
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNaN(&x.Real) or runtime.realIsNaN(&x.Imag)) {
        runtime.realSetNaN(&res);
        runtime.convertComplexPartsToResultRegister(&res, &res, runtime.REGISTER_X);
    } else if (runtime.realIsZero(&x.Imag)) {
        if (runtime.realCompareGreaterEqual(&x.Real, get_1oneE(&res)) and runtime.realCompareLessEqual(&x.Real, runtime.z47_math_wrappers_const_0())) {
            runtime.WP34S_LambertW(&x.Real, &res, true, &runtime.ctxtReal75);
            runtime.convertComplexPartsToResultRegister(&res, runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function wNegCplx:", "X < -e^(-1) || 0 < X", null, null);
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function wNegCplx:", "Cannot calculate Wm for complex number with non-zero imaginary part", null, null);
        }
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
