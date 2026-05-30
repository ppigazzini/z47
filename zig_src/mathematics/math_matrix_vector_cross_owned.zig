const diagnostics_owned = @import("math_matrix_vector_diagnostics_owned.zig");
const matrix_owned = @import("math_matrix_vector_cross_matrix_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const validation_owned = @import("math_matrix_vector_validation_owned.zig");

fn crossReal() callconv(.c) void {
    runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.amNone);
}

fn crossCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var temp: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        return;
    }

    runtime.realMultiply(&x_real, &y_imag, &temp, &runtime.ctxtReal75);
    runtime.realChangeSign(&temp);
    runtime.realFMA(&y_real, &x_imag, &temp, &result_real, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
}

pub fn cross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (matrix_owned.tryCrossMatrices()) {
        return;
    }

    if (validation_owned.classifyCurrentOperands().hasAnyMatrix()) {
        diagnostics_owned.crossDotMatrixTypeError("In function fnCross:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&crossReal, &crossCplx);
}
