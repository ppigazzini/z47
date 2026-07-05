const std = @import("std");
const abi = @import("abi");
const build_options = @import("math_command_wrappers_build_options");
const rectangular_to_polar_owned = @import("math_rectangular_to_polar_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

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

    return &abi.matrixRealElems(matrix)[index];
}

fn complexMatrixElementPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.complex34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &abi.matrixComplexElems(matrix)[index];
}

fn complexMatrixRealPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).real;
}

fn complexMatrixImagPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).imag;
}

fn realPartComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertRealToResultRegister(&real_value, runtime.REGISTER_X, runtime.amNone);
}

fn realPartComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        real_matrix.matrixElements[index] = complex_matrix.matrixElements[index].real;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn realPartReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn imaginaryPartComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertRealToResultRegister(&imag_value, runtime.REGISTER_X, runtime.amNone);
}

fn imaginaryPartComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        real_matrix.matrixElements[index] = complex_matrix.matrixElements[index].imag;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn imaginaryPartReal() callconv(.c) void {
    runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.amNone);
}

pub fn realPart() void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        realPartComplexMatrix();
        return;
    }

    runtime.processRealComplexMonadicFunction(&realPartReal, &realPartComplex);
}

pub fn imaginaryPart() void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        imaginaryPartComplexMatrix();
        return;
    }

    runtime.processRealComplexMonadicFunction(&imaginaryPartReal, &imaginaryPartComplex);
}

fn realArgValue(x_value: *const runtime.real_t) *const runtime.real_t {
    return if (runtime.realIsNaN(x_value))
        x_value
    else if (runtime.realIsZero(x_value) and runtime.getSystemFlag(runtime.FLAG_SPCRES))
        x_value
    else if (runtime.realIsNegative(x_value))
        runtime.z47_math_wrappers_const_180()
    else
        runtime.z47_math_wrappers_const_0();
}

fn argReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    const result = realArgValue(&x_value);

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
    if (!runtime.realIsNaN(result)) {
        runtime.convertAngle34FromTo(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.amDegree, runtime.currentAngularMode);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

fn argError() void {
    _ = runtime.getRegisterAsReal(runtime.REGISTER_X, null);
}

fn argComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    rectangular_to_polar_owned.rectangularToPolarReal(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&imag_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&imag_value, runtime.REGISTER_X);
}

fn argRealMatrix() void {
    var matrix: runtime.real34Matrix_t = undefined;

    runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &matrix);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    defer runtime.realMatrixFree(&matrix);

    const count = realMatrixElementCount(&matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var real_value: runtime.real_t = undefined;

        runtime.real34ToReal(realMatrixElementPtr(&matrix, index), &real_value);
        real_value = realArgValue(&real_value).*;
        runtime.convertAngleFromTo(&real_value, runtime.amDegree, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realToReal34(&real_value, realMatrixElementPtr(&matrix, index));
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, runtime.REGISTER_X);
}

fn argComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;
    var dummy = std.mem.zeroes(runtime.real34_t);

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.real34RectangularToPolar(
            complexMatrixRealPtr(&complex_matrix, index),
            complexMatrixImagPtr(&complex_matrix, index),
            &dummy,
            realMatrixElementPtr(&real_matrix, index),
        );
        runtime.convertAngle34FromTo(realMatrixElementPtr(&real_matrix, index), runtime.amRadian, runtime.currentAngularMode);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

pub fn arg() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger, runtime.dtReal34, runtime.dtShortInteger => argReal(),
        runtime.dtComplex34 => argComplex(),
        runtime.dtReal34Matrix => argRealMatrix(),
        runtime.dtComplex34Matrix => argComplexMatrix(),
        else => argError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, @as(runtime.calcRegister_t, -1), @as(runtime.calcRegister_t, -1));
}

fn magnitudeLongInteger() callconv(.c) void {
    runtime.setRegisterLongIntegerSign(runtime.REGISTER_X, runtime.LI_POSITIVE);
}

fn magnitudeShortInteger() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intAbs(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

fn magnitudeReal() callconv(.c) void {
    runtime.real34SetPositiveSign(runtime.registerReal34Ptr(runtime.REGISTER_X));
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn complexMagnitudeSquared(real: *const runtime.real_t, imag: *const runtime.real_t, out_magnitude: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var product: runtime.real_t = undefined;

    runtime.realMultiply(real, real, &product, real_context);
    runtime.realFMA(imag, imag, &product, out_magnitude, real_context);
}

fn complexMagnitude(real: *const runtime.real_t, imag: *const runtime.real_t, out_magnitude: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var squared: runtime.real_t = undefined;

    complexMagnitudeSquared(real, imag, &squared, real_context);
    runtime.realSquareRoot(&squared, out_magnitude, real_context);
}

fn magnitudeComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;
    var dummy = std.mem.zeroes(runtime.real34_t);

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.real34RectangularToPolar(
            complexMatrixRealPtr(&complex_matrix, index),
            complexMatrixImagPtr(&complex_matrix, index),
            realMatrixElementPtr(&real_matrix, index),
            &dummy,
        );
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn magnitudeComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    complexMagnitude(&real_value, &imag_value, &magnitude_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&magnitude_value, runtime.REGISTER_X, runtime.amNone);
}

pub fn magnitude() void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        magnitudeComplexMatrix();
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&magnitudeReal, &magnitudeComplex, &magnitudeShortInteger, &magnitudeLongInteger);
}

fn changeReal34Sign(value: *runtime.real34_t) void {
    value.bytes[15] ^= 0x80;
}

fn conjugateRealMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &complex_matrix);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        const count = complexMatrixElementCount(&complex_matrix);

        var index: usize = 0;
        while (index < count) : (index += 1) {
            changeReal34Sign(complexMatrixImagPtr(&complex_matrix, index));
        }
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
    runtime.complexMatrixFree(&complex_matrix);
}

fn conjugateComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        changeReal34Sign(complexMatrixImagPtr(&complex_matrix, index));
        if (runtime.real34IsZero(complexMatrixImagPtr(&complex_matrix, index)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.real34SetPositiveSign(complexMatrixImagPtr(&complex_matrix, index));
        }
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
}

fn conjugateComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.realChangeSign(&imag_value);
    if (runtime.realIsZero(&imag_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(&imag_value);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

pub fn conjugate() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.saveLastX()) {
        return;
    }

    if (register_data_type == runtime.dtComplex34Matrix) {
        conjugateComplexMatrix();
        return;
    }

    if (register_data_type == runtime.dtReal34Matrix) {
        conjugateRealMatrix();
        return;
    }

    conjugateComplex();
}

fn swapRealImaginaryComplex() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertComplexToResultRegister(&imag_value, &real_value, runtime.REGISTER_X);
}

fn swapRealImaginaryRealMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &real_matrix);
    runtime.convertReal34MatrixToComplex34Matrix(&real_matrix, &complex_matrix);

    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        complex_matrix.matrixElements[index].imag = complex_matrix.matrixElements[index].real;
        complex_matrix.matrixElements[index].real = std.mem.zeroes(runtime.real34_t);
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
    runtime.complexMatrixFree(&complex_matrix);
}

fn swapRealImaginaryComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        const real_value = complex_matrix.matrixElements[index].real;
        complex_matrix.matrixElements[index].real = complex_matrix.matrixElements[index].imag;
        complex_matrix.matrixElements[index].imag = real_value;
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
}

pub fn swapRealImaginary() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.saveLastX()) {
        return;
    }

    if (register_data_type == runtime.dtReal34Matrix) {
        swapRealImaginaryRealMatrix();
        return;
    }

    if (register_data_type == runtime.dtComplex34Matrix) {
        swapRealImaginaryComplexMatrix();
        return;
    }

    swapRealImaginaryComplex();
}