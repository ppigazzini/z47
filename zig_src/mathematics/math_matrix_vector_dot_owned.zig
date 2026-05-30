const diagnostics_owned = @import("math_matrix_vector_diagnostics_owned.zig");
const matrix_owned = @import("math_matrix_vector_dot_matrix_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const validation_owned = @import("math_matrix_vector_validation_owned.zig");

fn dotCplx(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    y_real: *const runtime.real_t,
    y_imag: *const runtime.real_t,
    result_real: *runtime.real_t,
) void {
    var product: runtime.real_t = undefined;
    var temp: runtime.real_t = undefined;

    runtime.realMultiply(x_real, y_real, &product, &runtime.ctxtReal39);
    runtime.realFMA(x_imag, y_imag, &product, &temp, &runtime.ctxtReal39);
    runtime.realChangeSign(&product);
    runtime.realFMA(x_real, y_real, &product, result_real, &runtime.ctxtReal39);
    runtime.realAdd(result_real, &temp, result_real, &runtime.ctxtReal39);
}

fn doDotReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        runtime.realMultiply(&x_value, &y_value, &result, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }
}

fn doDotCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) and runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        dotCplx(&x_real, &x_imag, &y_real, &y_imag, &result_real);
        runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
    }
}

pub fn dot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (matrix_owned.tryDotMatrices()) {
        return;
    }

    if (validation_owned.classifyCurrentOperands().hasAnyMatrix()) {
        diagnostics_owned.crossDotMatrixTypeError("In function fnDot:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}
