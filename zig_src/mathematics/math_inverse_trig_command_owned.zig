const atan_owned = @import("math_atan_owned.zig");
const inverse_trig_complex_command_owned = @import("math_inverse_trig_complex_command_owned.zig");
const inverse_trig_real_command_owned = @import("math_inverse_trig_real_command_owned.zig");
const ln_complex_owned = @import("math_ln_complex_owned.zig");
const real_trig_owned = @import("math_real_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn negateReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realChangeSign(destination);
}

pub fn ArcsinComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, x_real);
    negateReal(&b, x_imag);

    runtime.sqrt1Px2Complex(&b, &a, r_real, r_imag, real_context);
    runtime.realAdd(r_real, &b, r_real, real_context);
    runtime.realAdd(r_imag, &a, r_imag, real_context);
    ln_complex_owned.lnComplex(r_real, r_imag, &a, &b, real_context);
    runtime.realChangeSign(&a);

    copyReal(r_real, &b);
    copyReal(r_imag, &a);
    return runtime.ERROR_NONE;
}

pub fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var numer: runtime.real_t = undefined;
    var denom: runtime.real_t = undefined;

    copyReal(&a, x_real);
    copyReal(&b, x_imag);

    runtime.realMultiply(&a, &a, &denom, real_context);
    runtime.realFMA(&b, &b, &denom, &denom, real_context);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &denom, &numer, real_context);
    runtime.realChangeSign(&b);
    runtime.realFMA(&b, runtime.z47_math_wrappers_const_2(), &denom, &denom, real_context);
    runtime.realAdd(&denom, runtime.z47_math_wrappers_const_1(), &denom, real_context);
    runtime.realMultiply(&a, runtime.z47_math_wrappers_const_2(), &b, real_context);
    runtime.realChangeSign(&b);
    runtime.realDivide(&numer, &denom, &a, real_context);
    runtime.realDivide(&b, &denom, &b, real_context);
    ln_complex_owned.lnComplex(&a, &b, &a, &b, real_context);
    runtime.realMultiply(&a, runtime.z47_math_wrappers_const_1on2(), &a, real_context);
    runtime.realMultiply(&b, runtime.z47_math_wrappers_const_1on2(), &b, real_context);
    runtime.realChangeSign(&b);

    copyReal(r_real, &b);
    copyReal(r_imag, &a);
    return runtime.ERROR_NONE;
}

pub fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) u8 {
    if (runtime.realIsInfinite(x)) {
        copyReal(res, x);
    } else {
        real_trig_owned.arcsinhReal(x, res, real_context);
    }

    return runtime.ERROR_NONE;
}

pub fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, x_real);
    copyReal(&b, x_imag);

    runtime.realMultiply(&b, &b, r_real, real_context);
    runtime.realChangeSign(r_real);
    runtime.realFMA(&a, &a, r_real, r_real, real_context);
    runtime.realMultiply(&a, &b, r_imag, real_context);
    runtime.realMultiply(r_imag, runtime.z47_math_wrappers_const_2(), r_imag, real_context);
    runtime.realAdd(r_real, runtime.z47_math_wrappers_const_1(), r_real, real_context);
    runtime.realRectangularToPolar(r_real, r_imag, r_real, r_imag, real_context);
    runtime.realSquareRoot(r_real, r_real, real_context);
    runtime.realMultiply(r_imag, runtime.z47_math_wrappers_const_1on2(), r_imag, real_context);
    runtime.realPolarToRectangular(r_real, r_imag, r_real, r_imag, real_context);
    runtime.realAdd(&a, r_real, r_real, real_context);
    runtime.realAdd(&b, r_imag, r_imag, real_context);
    ln_complex_owned.lnComplex(r_real, r_imag, r_real, r_imag, real_context);
    return runtime.ERROR_NONE;
}

pub fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var x_squared: runtime.real_t = undefined;

    runtime.realMultiply(x, x, &x_squared, real_context);
    runtime.realSubtract(&x_squared, runtime.z47_math_wrappers_const_1(), &x_squared, real_context);
    runtime.realSquareRoot(&x_squared, &x_squared, real_context);
    runtime.realAdd(&x_squared, x, res, real_context);
    ln_complex_owned.lnRealValue(res, res, real_context);
}

fn arcsinCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arcsinCplx();
}

fn arcsinReal() callconv(.c) void {
    inverse_trig_real_command_owned.arcsinReal();
}

fn arccosCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arccosCplx();
}

fn arccosReal() callconv(.c) void {
    inverse_trig_real_command_owned.arccosReal();
}

fn arctanReal() callconv(.c) void {
    inverse_trig_real_command_owned.arctanReal();
}

fn arctanCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arctanCplx();
}

fn arcsinhReal() callconv(.c) void {
    inverse_trig_real_command_owned.arcsinhReal();
}

fn arcsinhCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arcsinhCplx();
}

fn arccoshCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arccoshCplx();
}

fn arccoshReal() callconv(.c) void {
    inverse_trig_real_command_owned.arccoshReal();
}

fn arctanhCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arctanhCplx();
}

fn arctanhReal() callconv(.c) void {
    inverse_trig_real_command_owned.arctanhReal();
}

pub fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arcsinReal, &arcsinCplx);
}

pub fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arccosReal, &arccosCplx);
}

pub fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arctanReal, &arctanCplx);
}

pub fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arcsinhReal, &arcsinhCplx);
}

pub fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arccoshReal, &arccoshCplx);
}

pub fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arctanhReal, &arctanhCplx);
}