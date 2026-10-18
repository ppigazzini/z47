const circular_trig_owned = @import("circular_trig.zig");
const real_trig_owned = @import("real_trig.zig");
const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");

fn realGetExponent(source: *const runtime.real_t) i32 {
    return source.digits + source.exponent - 1;
}

// A tiny odd function of x: the series x +- x^3/d rounded once, below 1E-18 where
// the next term is already past 72 digits.
fn isTinyArgument(x: *const runtime.real_t) bool {
    return !runtime.realIsZero(x) and realGetExponent(x) < -18;
}

fn coshReal() callconv(.c) void {
    math_command_wrappers.sinhCoshReal(runtime.trigCos);
}

fn coshCplx() callconv(.c) void {
    math_command_wrappers.sinhCoshCplx(runtime.trigCos);
}

fn sinReal() callconv(.c) void {
    math_command_wrappers.sinCosReal(runtime.trigSin);
}

fn sinCplx() callconv(.c) void {
    math_command_wrappers.sinCosCplx(runtime.trigSin);
}

fn cosReal() callconv(.c) void {
    math_command_wrappers.sinCosReal(runtime.trigCos);
}

fn cosCplx() callconv(.c) void {
    math_command_wrappers.sinCosCplx(runtime.trigCos);
}

fn sinhReal() callconv(.c) void {
    math_command_wrappers.sinhCoshReal(runtime.trigSin);
}

fn sinhCplx() callconv(.c) void {
    math_command_wrappers.sinhCoshCplx(runtime.trigSin);
}

fn tanhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_tanh_real_domain_error();
        return;
    }

    if (!runtime.realIsSpecial(&x) and isTinyArgument(&x)) { // tanh x = x - x^3/3 to 72 digits, below |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, runtime.z47_math_wrappers_const_3(), false, &x, &runtime.ctxtReal75);
    } else {
        real_trig_owned.tanhReal(&x, &x, &runtime.ctxtReal39);
    }
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn tanhCplx() callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var r: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = math_command_wrappers.TanhComplex(&x, &r, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
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
    } else if (x_angular_mode == runtime.amRadian and isTinyArgument(&tan_value)) { // tan x = x + x^3/3 to 72 digits, above |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&tan_value, runtime.z47_math_wrappers_const_3(), true, &tan_value, &runtime.ctxtReal75);
    } else {
        circular_trig_owned.convertAngleToSinCosTan(&tan_value, x_angular_mode, &sin_value, &cos_value, &tan_value, &runtime.ctxtReal34);
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
    var x: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = math_command_wrappers.TanComplex(&x, &x, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

pub fn fnSin(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinReal, &sinCplx);
}

pub fn fnCos(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&cosReal, &cosCplx);
}

pub fn fnTan(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&tanReal, &tanCplx);
}

pub fn fnSinh(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinhReal, &sinhCplx);
}

pub fn fnCosh(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&coshReal, &coshCplx);
}

pub fn fnTanh(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&tanhReal, &tanhCplx);
}
