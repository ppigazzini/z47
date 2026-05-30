const std = @import("std");
const cross_owned = @import("math_matrix_vector_cross_owned.zig");
const linpol_owned = @import("math_matrix_vector_linpol_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn crossDotMatrixTypeError(function_name: [:0]const u8) void {
    var message1_buffer: [96]u8 = undefined;
    var message2_buffer: [64]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message1 = std.fmt.bufPrintZ(&message1_buffer, "cannot raise {s}", .{y_type_name}) catch "cannot raise current Y type";
    const message2 = std.fmt.bufPrintZ(&message2_buffer, "to {s}", .{x_type_name}) catch "to current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message1, message2, null);
}

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

fn tryCrossMatrices() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real_matrix = type_x == runtime.dtReal34Matrix;
    const x_is_complex_matrix = type_x == runtime.dtComplex34Matrix;
    const y_is_real_matrix = type_y == runtime.dtReal34Matrix;
    const y_is_complex_matrix = type_y == runtime.dtComplex34Matrix;

    if (!(x_is_real_matrix or x_is_complex_matrix or y_is_real_matrix or y_is_complex_matrix)) {
        return false;
    }

    if (!((x_is_real_matrix or x_is_complex_matrix) and (y_is_real_matrix or y_is_complex_matrix))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real_matrix and y_is_real_matrix) {
        var x_matrix: runtime.real34Matrix_t = undefined;
        var y_matrix: runtime.real34Matrix_t = undefined;
        var result: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);

        if (runtime.realVectorSize(&x_matrix) == 0 or runtime.realVectorSize(&y_matrix) == 0 or runtime.realVectorSize(&x_matrix) > 3 or runtime.realVectorSize(&y_matrix) > 3) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        } else {
            runtime.crossRealVectors(&y_matrix, &x_matrix, &result);
            runtime.convertReal34MatrixToReal34MatrixRegister(&result, runtime.REGISTER_X);
        }

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
        return true;
    }

    if (x_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    } else if (y_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    }

    var x_matrix: runtime.complex34Matrix_t = undefined;
    var y_matrix: runtime.complex34Matrix_t = undefined;
    var result: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x_matrix);
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y_matrix);

    if (runtime.complexVectorSize(&x_matrix) == 0 or runtime.complexVectorSize(&y_matrix) == 0 or runtime.complexVectorSize(&x_matrix) > 3 or runtime.complexVectorSize(&y_matrix) > 3) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    } else {
        runtime.crossComplexVectors(&y_matrix, &x_matrix, &result);
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    return true;
}

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

fn tryDotMatrices() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real_matrix = type_x == runtime.dtReal34Matrix;
    const x_is_complex_matrix = type_x == runtime.dtComplex34Matrix;
    const y_is_real_matrix = type_y == runtime.dtReal34Matrix;
    const y_is_complex_matrix = type_y == runtime.dtComplex34Matrix;

    if (!(x_is_real_matrix or x_is_complex_matrix or y_is_real_matrix or y_is_complex_matrix)) {
        return false;
    }

    if (!((x_is_real_matrix or x_is_complex_matrix) and (y_is_real_matrix or y_is_complex_matrix))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real_matrix and y_is_real_matrix) {
        var x_matrix: runtime.real34Matrix_t = undefined;
        var y_matrix: runtime.real34Matrix_t = undefined;
        var result: runtime.real34_t = undefined;

        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);

        if (runtime.realVectorSize(&x_matrix) == 0 or runtime.realVectorSize(&y_matrix) == 0 or runtime.realVectorSize(&x_matrix) != runtime.realVectorSize(&y_matrix)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        } else {
            runtime.dotRealVectors(&y_matrix, &x_matrix, &result);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.registerReal34Ptr(runtime.REGISTER_X).* = result;
        }

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
        return true;
    }

    if (x_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    } else if (y_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    }

    var x_matrix: runtime.complex34Matrix_t = undefined;
    var y_matrix: runtime.complex34Matrix_t = undefined;
    var result_real: runtime.real34_t = undefined;
    var result_imag: runtime.real34_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x_matrix);
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y_matrix);

    if (runtime.complexVectorSize(&x_matrix) == 0 or runtime.complexVectorSize(&y_matrix) == 0 or runtime.complexVectorSize(&x_matrix) != runtime.complexVectorSize(&y_matrix)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    } else {
        runtime.dotComplexVectors(&y_matrix, &x_matrix, &result_real, &result_imag);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = result_real;
        runtime.registerImag34Ptr(runtime.REGISTER_X).* = result_imag;
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    return true;
}

pub fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    cross_owned.cross(unused_but_mandatory_parameter);
}

pub fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (tryDotMatrices()) {
        return;
    }

    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        crossDotMatrixTypeError("In function fnDot:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}

pub fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    linpol_owned.linpol();
}
