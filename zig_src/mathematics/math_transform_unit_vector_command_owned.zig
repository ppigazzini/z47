const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn realMatrixElementCount(matrix: *const runtime.real34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn complexMatrixElementCount(matrix: *const runtime.complex34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn realMatrixElementPtr(matrix: *runtime.real34Matrix_t, index: usize) *runtime.real34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &@as([*]runtime.real34_t, @ptrCast(matrix.matrixElements))[index];
}

fn complexMatrixElementPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.complex34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &@as([*]runtime.complex34_t, @ptrCast(matrix.matrixElements))[index];
}

fn complexMatrixRealPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).real;
}

fn complexMatrixImagPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).imag;
}

fn unitVectorError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot calculate the unit vector of {s}", .{type_name}) catch "cannot calculate the unit vector";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnUnitVector:", message, null, null);
}

fn unitVectorComplex() void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var norm: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
    runtime.real34ToReal(runtime.registerImag34Ptr(runtime.REGISTER_X), &imag_value);

    runtime.realMultiply(&real_value, &real_value, &norm, &runtime.ctxtReal39);
    runtime.realFMA(&imag_value, &imag_value, &norm, &norm, &runtime.ctxtReal39);
    runtime.realSquareRoot(&norm, &norm, &runtime.ctxtReal39);
    runtime.realDivide(&real_value, &norm, &real_value, &runtime.ctxtReal39);
    runtime.realDivide(&imag_value, &norm, &imag_value, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn unitVectorRema() void {
    var matrix: runtime.real34Matrix_t = undefined;
    var element: runtime.real_t = undefined;
    var sum: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
    runtime.realSetZero(&sum);

    const count = realMatrixElementCount(&matrix);

    for (0..count) |index| {
        runtime.real34ToReal(realMatrixElementPtr(&matrix, index), &element);
        runtime.realMultiply(&element, &element, &element, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &element, &sum, &runtime.ctxtReal39);
    }

    runtime.realSquareRoot(&sum, &sum, &runtime.ctxtReal39);

    for (0..count) |index| {
        runtime.real34ToReal(realMatrixElementPtr(&matrix, index), &element);
        runtime.realDivide(&element, &sum, &element, &runtime.ctxtReal39);
        runtime.realToReal34(&element, realMatrixElementPtr(&matrix, index));
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, runtime.REGISTER_X);
}

fn unitVectorCxma() void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var sum: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &matrix);
    runtime.realSetZero(&sum);

    const count = complexMatrixElementCount(&matrix);

    for (0..count) |index| {
        runtime.real34ToReal(complexMatrixRealPtr(&matrix, index), &real_value);
        runtime.realMultiply(&real_value, &real_value, &real_value, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &real_value, &sum, &runtime.ctxtReal39);
        runtime.real34ToReal(complexMatrixImagPtr(&matrix, index), &imag_value);
        runtime.realMultiply(&imag_value, &imag_value, &imag_value, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &imag_value, &sum, &runtime.ctxtReal39);
    }

    runtime.realSquareRoot(&sum, &sum, &runtime.ctxtReal39);

    for (0..count) |index| {
        runtime.real34ToReal(complexMatrixRealPtr(&matrix, index), &real_value);
        runtime.real34ToReal(complexMatrixImagPtr(&matrix, index), &imag_value);
        runtime.divComplexComplex(&real_value, &imag_value, &sum, runtime.z47_math_wrappers_const_0(), &real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realToReal34(&real_value, complexMatrixRealPtr(&matrix, index));
        runtime.realToReal34(&imag_value, complexMatrixImagPtr(&matrix, index));
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, runtime.REGISTER_X);
}

pub fn unitVector(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtComplex34 => unitVectorComplex(),
        runtime.dtReal34Matrix => unitVectorRema(),
        runtime.dtComplex34Matrix => unitVectorCxma(),
        else => unitVectorError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}
