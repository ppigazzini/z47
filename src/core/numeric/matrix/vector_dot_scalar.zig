const runtime = @import("../command_wrappers/runtime.zig");

// Numerically stable dot product function. Slower but accurate. Declared in
// mathematics/dot.h, so it carries external linkage and takes the caller's
// context.
pub export fn dotCplx(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    y_real: *const runtime.real_t,
    y_imag: *const runtime.real_t,
    result_real: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var product: runtime.real_t = undefined;
    var temp: runtime.real_t = undefined;

    runtime.realMultiply(x_real, y_real, &product, real_context);
    runtime.realFMA(x_imag, y_imag, &product, &temp, real_context);
    runtime.realChangeSign(&product);
    runtime.realFMA(x_real, y_real, &product, result_real, real_context);
    runtime.realAdd(result_real, &temp, result_real, real_context);
}

pub export fn doDotReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        runtime.realMultiply(&x_value, &y_value, &result, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }
}

pub export fn doDotCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) and runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        dotCplx(&x_real, &x_imag, &y_real, &y_imag, &result_real, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
    }
}

pub fn runScalarDot() void {
    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}
