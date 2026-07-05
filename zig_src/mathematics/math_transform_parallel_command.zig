const runtime = @import("math_command_wrappers_runtime.zig");

fn doParallelReal() callconv(.c) void {
    var y_value: runtime.real_t = undefined;
    var x_value: runtime.real_t = undefined;
    var product: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.realIsZero(&x_value)) {
        runtime.realMultiply(&y_value, &x_value, &product, &runtime.ctxtReal75);
        runtime.realAdd(&y_value, &x_value, &y_value, &runtime.ctxtReal75);
        runtime.realDivide(&product, &y_value, &x_value, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn doParallelComplex() callconv(.c) void {
    var y_real: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var product_real: runtime.real_t = undefined;
    var sum_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var product_imag: runtime.real_t = undefined;
    var sum_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        return;
    }

    if (!runtime.realIsZero(&x_real) or !runtime.realIsZero(&x_imag)) {
        runtime.mulComplexComplex(&y_real, &y_imag, &x_real, &x_imag, &product_real, &product_imag, &runtime.ctxtReal75);
        runtime.realAdd(&y_real, &x_real, &sum_real, &runtime.ctxtReal75);
        runtime.realAdd(&y_imag, &x_imag, &sum_imag, &runtime.ctxtReal75);
        runtime.divComplexComplex(&product_real, &product_imag, &sum_real, &sum_imag, &x_real, &x_imag, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
}

pub fn parallel(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexDyadicFunction(&doParallelReal, &doParallelComplex);
}
