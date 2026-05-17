const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub export fn sinComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;

    runtime.C47_WP34S_Cvt2RadSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(imag, &sinhb, &coshb, real_context);
    runtime.realMultiply(&sina, &coshb, res_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, res_imag, real_context);
}

pub export fn cosComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;

    runtime.C47_WP34S_Cvt2RadSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(imag, &sinhb, &coshb, real_context);
    runtime.realMultiply(&cosa, &coshb, res_real, real_context);
    runtime.realMultiply(&sina, &sinhb, res_imag, real_context);
    runtime.realChangeSign(res_imag);
}

pub export fn sinCosReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: runtime.real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = undefined;

    if (!runtime.getRegisterAsRealAngle(runtime.REGISTER_X, &x, &x_angular_mode, runtime.ifLongIntegerDoAngleReduction)) {
        return;
    }

    if (runtime.realIsSpecial(&x)) {
        runtime.realSetNaN(&x);
    } else if (trig_type == runtime.trigSin) {
        runtime.C47_WP34S_Cvt2RadSinCosTan(&x, x_angular_mode, &x, null, null, &runtime.ctxtReal75);
    } else {
        runtime.C47_WP34S_Cvt2RadSinCosTan(&x, x_angular_mode, null, &x, null, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn sinCosCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    if (trig_type == runtime.trigSin) {
        sinComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    } else {
        cosComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub export fn sinhCoshReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_sinh_cosh_real_domain_error();
        return;
    }

    if (trig_type == runtime.trigSin) {
        runtime.WP34S_SinhCosh(&x, &x, null, &runtime.ctxtReal39);
    } else {
        runtime.WP34S_SinhCosh(&x, null, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn sinhCoshCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var sinha: runtime.real_t = undefined;
    var cosha: runtime.real_t = undefined;
    var sinb: runtime.real_t = undefined;
    var cosb: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.WP34S_SinhCosh(&a, &sinha, &cosha, &runtime.ctxtReal39);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&b, runtime.amRadian, &sinb, &cosb, null, &runtime.ctxtReal39);

    if (trig_type == runtime.trigSin) {
        runtime.realMultiply(&sinha, &cosb, &a, &runtime.ctxtReal39);
        runtime.realMultiply(&cosha, &sinb, &b, &runtime.ctxtReal39);
    } else {
        runtime.realMultiply(&cosha, &cosb, &a, &runtime.ctxtReal39);
        runtime.realMultiply(&sinha, &sinb, &b, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub export fn TanComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;
    var numer_real: runtime.real_t = undefined;
    var numer_imag: runtime.real_t = undefined;
    var denom_real: runtime.real_t = undefined;
    var denom_imag: runtime.real_t = undefined;

    runtime.C47_WP34S_Cvt2RadSinCosTan(x_real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(x_imag, &sinhb, &coshb, real_context);

    runtime.realMultiply(&sina, &coshb, &numer_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, &numer_imag, real_context);
    runtime.realMultiply(&cosa, &coshb, &denom_real, real_context);
    runtime.realMultiply(&sina, &sinhb, &denom_imag, real_context);
    runtime.realChangeSign(&denom_imag);

    runtime.divComplexComplex(&numer_real, &numer_imag, &denom_real, &denom_imag, r_real, r_imag, real_context);
    return runtime.ERROR_NONE;
}

fn ceilReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_CEILING);
}

fn ceilCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_CEILING);
}

fn floorReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_FLOOR);
}

fn floorCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_FLOOR);
}

fn integerPartNoOpForward() callconv(.c) void {
    runtime.integerPartNoOp();
}

fn coshReal() callconv(.c) void {
    sinhCoshReal(runtime.trigCos);
}

fn coshCplx() callconv(.c) void {
    sinhCoshCplx(runtime.trigCos);
}

fn sinReal() callconv(.c) void {
    sinCosReal(runtime.trigSin);
}

fn sinCplx() callconv(.c) void {
    sinCosCplx(runtime.trigSin);
}

fn cosReal() callconv(.c) void {
    sinCosReal(runtime.trigCos);
}

fn cosCplx() callconv(.c) void {
    sinCosCplx(runtime.trigCos);
}

fn sinhReal() callconv(.c) void {
    sinhCoshReal(runtime.trigSin);
}

fn sinhCplx() callconv(.c) void {
    sinhCoshCplx(runtime.trigSin);
}

fn tanReal() callconv(.c) void {
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;
    var tan_value: runtime.real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = undefined;

    if (!runtime.getRegisterAsRealAngle(runtime.REGISTER_X, &tan_value, &x_angular_mode, runtime.ifLongIntegerDoAngleReduction)) {
        return;
    }

    if (runtime.realIsSpecial(&tan_value)) {
        runtime.realSetNaN(&tan_value);
    } else {
        runtime.C47_WP34S_Cvt2RadSinCosTan(&tan_value, x_angular_mode, &sin_value, &cos_value, &tan_value, &runtime.ctxtReal75);
        if (runtime.realIsZero(&sin_value)) {
            runtime.realSetPositiveSign(&tan_value);
        }

        if (runtime.realIsZero(&cos_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.z47_math_wrappers_report_tan_real_pole_error();
            return;
        }

        if (runtime.realIsZero(&cos_value)) {
            runtime.realSetNaN(&tan_value);
        }
    }

    runtime.convertRealToResultRegister(&tan_value, runtime.REGISTER_X, runtime.amNone);
}

fn tanCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = TanComplex(&x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal51);
    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMin(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMax(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ceilReal,
        &ceilCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &floorReal,
        &floorCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinReal, &sinCplx);
}

pub export fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&cosReal, &cosCplx);
}

pub export fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&tanReal, &tanCplx);
}

pub export fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinhReal, &sinhCplx);
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&coshReal, &coshCplx);
}
