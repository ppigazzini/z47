const circular_trig_owned = @import("../trig/circular_trig.zig");
const real_trig_owned = @import("../trig/real_trig.zig");
const runtime = @import("../command_wrappers/runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn sincComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var rr: runtime.real_t = undefined;
    var ii: runtime.real_t = undefined;
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;

    copyReal(&rr, real);
    copyReal(&ii, imag);

    if (runtime.realIsZero(&rr) and runtime.realIsZero(&ii)) {
        runtime.realSetOne(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    var sin_real: runtime.real_t = undefined;
    var sin_imag: runtime.real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(&rr, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(&ii, &sinhb, &coshb, real_context);
    runtime.realMultiply(&sina, &coshb, res_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, res_imag, real_context);
    copyReal(&sin_real, res_real);
    copyReal(&sin_imag, res_imag);
    runtime.divComplexComplex(&sin_real, &sin_imag, &rr, &ii, res_real, res_imag, real_context);
}

fn sincReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var sine: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_0();
        } else {
            runtime.z47_math_wrappers_report_sinc_real_domain_error();
            return;
        }
    } else if (runtime.realIsZero(&x)) {
        result = runtime.z47_math_wrappers_const_1();
    } else {
        if (register_data_type == runtime.dtReal34) {
            const angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
            if (angular_mode != runtime.amNone) {
                runtime.convertAngleFromTo(&x, angular_mode, runtime.amRadian, &runtime.ctxtReal39);
            }
        }
        circular_trig_owned.convertAngleToSinCosTan(&x, runtime.amRadian, &sine, null, null, &runtime.ctxtReal39);
        runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    sincComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn sincpiReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var sine: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_0();
        } else {
            runtime.z47_math_wrappers_report_sincpi_real_domain_error();
            return;
        }
    } else if (runtime.realIsZero(&x)) {
        result = runtime.z47_math_wrappers_const_1();
    } else if (register_data_type != runtime.dtReal34) {
        result = runtime.z47_math_wrappers_const_0();
    } else {
        const angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
        if (angular_mode != runtime.amNone) {
            runtime.convertAngleFromTo(&x, angular_mode, runtime.amRadian, &runtime.ctxtReal75);
        }
        runtime.realMultiply(&x, runtime.z47_math_wrappers_const_pi(), &x, &runtime.ctxtReal75);
        circular_trig_owned.convertAngleToSinCosTan(&x, runtime.amRadian, &sine, null, null, &runtime.ctxtReal75);
        runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincpiComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var rr: runtime.real_t = undefined;
    var ii: runtime.real_t = undefined;
    var remainder: runtime.real_t = undefined;

    copyReal(&rr, real);
    copyReal(&ii, imag);
    runtime.WP34S_Mod(&rr, runtime.z47_math_wrappers_const_1(), &remainder, real_context);

    if (runtime.realIsZero(&rr) and runtime.realIsZero(&ii)) {
        runtime.realSetOne(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    if (runtime.realIsZero(&remainder) and runtime.realIsZero(&ii)) {
        runtime.realSetZero(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;
    var sin_real: runtime.real_t = undefined;
    var sin_imag: runtime.real_t = undefined;

    runtime.realMultiply(&rr, runtime.z47_math_wrappers_const_pi(), &rr, real_context);
    runtime.realMultiply(&ii, runtime.z47_math_wrappers_const_pi(), &ii, real_context);
    circular_trig_owned.convertAngleToSinCosTan(&rr, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(&ii, &sinhb, &coshb, real_context);

    runtime.realMultiply(&sina, &coshb, res_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, res_imag, real_context);
    copyReal(&sin_real, res_real);
    copyReal(&sin_imag, res_imag);
    runtime.divComplexComplex(&sin_real, &sin_imag, &rr, &ii, res_real, res_imag, real_context);
}

fn sincpiCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    sincpiComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub fn fnSinc(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincReal, &sincCplx);
}

pub fn fnSincpi(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincpiReal, &sincpiCplx);
}
