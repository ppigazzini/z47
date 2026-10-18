const runtime = @import("../command_wrappers/runtime.zig");

// Numerically stable dot product function. Slower but accurate. Declared in
// mathematics/dot.h, so it carries external linkage and takes the caller's
// context. A special operand takes the plain fused sum: the residual pass
// below would turn an infinity into NaN.
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
    if (runtime.realIsSpecial(x_real) or runtime.realIsSpecial(x_imag) or runtime.realIsSpecial(y_real) or runtime.realIsSpecial(y_imag)) {
        result_real.* = temp;
        return;
    }
    runtime.realChangeSign(&product);
    runtime.realFMA(x_real, y_real, &product, result_real, real_context);
    runtime.realAdd(result_real, &temp, result_real, real_context);
}

// A long-integer operand gives the exact scaled product when it fits a Real34;
// two Real34 operands multiply at 34 digits, any other mix at 39.
pub export fn doDotReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var exact_result: runtime.real34_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const real_context: *runtime.realContext_t = if (type_x == runtime.dtReal34 and type_y == runtime.dtReal34) &runtime.ctxtReal34 else &runtime.ctxtReal39;

    if ((type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and runtime.multiplyRegisterValuesToReal34Scaled(runtime.REGISTER_X, runtime.REGISTER_Y, 0, &exact_result)) {
        runtime.convertReal34ToReal34Register(&exact_result, runtime.REGISTER_X);
    } else if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        runtime.realMultiply(&x_value, &y_value, &result, real_context);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }
}

pub export fn doDotCplx() callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var y: runtime.cplx_t = undefined;
    var result_real: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &x) and runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y)) {
        dotCplx(&x.Real, &x.Imag, &y.Real, &y.Imag, &result_real, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
    }
}

pub fn runScalarDot() void {
    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}
