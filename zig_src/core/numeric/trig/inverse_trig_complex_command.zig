const ln_complex_owned = @import("../ln_complex.zig");
const inverse_trig_command_owned = @import("inverse_trig_command.zig");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn negateReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realChangeSign(destination);
}

pub fn arcsinCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

pub fn arccosCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    negateReal(&real_value, &b);
    runtime.sqrt1Px2Complex(&real_value, &a, &imag_value, &real_value, &runtime.ctxtReal39);
    runtime.realChangeSign(&real_value);
    runtime.realAdd(&a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realAdd(&b, &imag_value, &imag_value, &runtime.ctxtReal39);
    ln_complex_owned.lnComplex(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);

    negateReal(&a, &real_value);
    copyReal(&b, &imag_value);
    runtime.convertComplexToResultRegister(&b, &a, runtime.REGISTER_X);
}

pub fn arctanCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = inverse_trig_command_owned.ArctanComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

pub fn arcsinhCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinhComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

pub fn arccoshCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.realMultiply(&b, &b, &real_value, &runtime.ctxtReal39);
    runtime.realChangeSign(&real_value);
    runtime.realFMA(&a, &a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realMultiply(&a, &b, &imag_value, &runtime.ctxtReal39);
    runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_2(), &imag_value, &runtime.ctxtReal39);
    runtime.realSubtract(&real_value, runtime.z47_math_wrappers_const_1(), &real_value, &runtime.ctxtReal39);
    runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
    runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_1on2(), &imag_value, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.realAdd(&a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realAdd(&b, &imag_value, &imag_value, &runtime.ctxtReal39);
    ln_complex_owned.lnComplex(&real_value, &imag_value, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub fn arctanhCplx() callconv(.c) void {
    var numer_real: runtime.real_t = undefined;
    var denom_real: runtime.real_t = undefined;
    var numer_imag: runtime.real_t = undefined;
    var denom_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &denom_imag, &numer_imag)) {
        return;
    }

    runtime.realAdd(&denom_imag, runtime.z47_math_wrappers_const_1(), &numer_real, &runtime.ctxtReal39);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &denom_imag, &denom_real, &runtime.ctxtReal39);
    negateReal(&denom_imag, &numer_imag);
    runtime.divComplexComplex(&numer_real, &numer_imag, &denom_real, &denom_imag, &numer_real, &numer_imag, &runtime.ctxtReal39);
    ln_complex_owned.lnComplex(&numer_real, &numer_imag, &numer_real, &numer_imag, &runtime.ctxtReal39);
    runtime.realMultiply(&numer_real, runtime.z47_math_wrappers_const_1on2(), &numer_real, &runtime.ctxtReal39);
    runtime.realMultiply(&numer_imag, runtime.z47_math_wrappers_const_1on2(), &numer_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&numer_real, &numer_imag, runtime.REGISTER_X);
}
