const std = @import("std");
const abi = @import("abi");
const rectangular_to_polar_owned = @import("transform/rectangular_to_polar.zig");
const runtime = @import("command_wrappers/runtime.zig");

fn realMatrixElementCount(matrix: *const runtime.real34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn complexMatrixElementCount(matrix: *const runtime.complex34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn realMatrixElementPtr(matrix: *runtime.real34Matrix_t, index: usize) *runtime.real34_t {
    return &abi.matrixRealElems(matrix)[index];
}

fn complexMatrixElementPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.complex34_t {
    return &abi.matrixComplexElems(matrix)[index];
}

fn complexMatrixRealPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).real;
}

fn complexMatrixImagPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).imag;
}

// The parts of a complex34 are copied as they are stored: no conversion, so no
// rounding the stored value did not already have.
fn realPartComplex() callconv(.c) void {
    const real = runtime.registerReal34Ptr(runtime.REGISTER_X).*;
    runtime.convertReal34ToReal34Register(&real, runtime.REGISTER_X);
}

fn realPartComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        realMatrixElementPtr(&real_matrix, index).* = complexMatrixRealPtr(&complex_matrix, index).*;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn realPartReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34) {
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        return;
    }
    if (data_type == runtime.dtLongInteger and (runtime.significantDigits == 0 or runtime.significantDigits == 34)) {
        runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        return;
    }
    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn imaginaryPartComplex() callconv(.c) void {
    const imaginary = runtime.registerImag34Ptr(runtime.REGISTER_X).*;
    runtime.convertReal34ToReal34Register(&imaginary, runtime.REGISTER_X);
}

fn imaginaryPartComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        realMatrixElementPtr(&real_matrix, index).* = complexMatrixImagPtr(&complex_matrix, index).*;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn imaginaryPartReal() callconv(.c) void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.real34SetZero(runtime.registerReal34Data(runtime.REGISTER_X));
}

pub fn realPart() void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        realPartComplexMatrix();
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
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
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    }

    runtime.processRealComplexMonadicFunction(&imaginaryPartReal, &imaginaryPartComplex);
}

fn realArgValue(x_value: *const runtime.real_t) *const runtime.real_t {
    if (runtime.realIsNaN(x_value)) {
        return x_value;
    }
    // The zero test is terminal, whatever SPCRES says: it only decides whether
    // the sign of a zero is preserved. Falling through to the sign test would
    // read -0 as negative and answer 180 degrees.
    if (runtime.realIsZero(x_value)) {
        return if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) x_value else runtime.z47_math_wrappers_const_0();
    }
    return if (runtime.realIsNegative(x_value))
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
    var value: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.C47_WP34S_Atan2(&value.Imag, &value.Real, value.arg(), &runtime.ctxtReal39);
    runtime.convertAngleFromTo(value.arg(), runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(value.arg(), runtime.REGISTER_X);
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

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var z: runtime.cplx_t = undefined;
        runtime.real34ToReal(complexMatrixRealPtr(&complex_matrix, index), &z.Real);
        runtime.real34ToReal(complexMatrixImagPtr(&complex_matrix, index), &z.Imag);
        runtime.C47_WP34S_Atan2(&z.Imag, &z.Real, z.arg(), &runtime.ctxtReal39);
        runtime.convertAngleFromTo(z.arg(), runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realToReal34(z.arg(), realMatrixElementPtr(&real_matrix, index));
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

pub fn arg() void {
    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
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

fn magnitudeComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = complexMatrixElementCount(&complex_matrix);
    const digits: i32 = if (runtime.significantDigits == 0) 34 else runtime.significantDigits;

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var magnitude_value: runtime.real_t = undefined;
        var z: runtime.cplx_t = undefined;
        runtime.real34ToReal(complexMatrixRealPtr(&complex_matrix, index), &z.Real);
        runtime.real34ToReal(complexMatrixImagPtr(&complex_matrix, index), &z.Imag);
        runtime.complexMagnitude(&z, &magnitude_value, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&magnitude_value, &magnitude_value, digits, &runtime.ctxtReal39);
        runtime.realToReal34(&magnitude_value, realMatrixElementPtr(&real_matrix, index));
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn magnitudeComplex() callconv(.c) void {
    var value: runtime.cplx_t = undefined;
    var magnitude_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.complexMagnitude(&value, &magnitude_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&magnitude_value, runtime.REGISTER_X, runtime.amNone);
}

pub fn magnitude() void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        magnitudeComplexMatrix();
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&magnitudeReal, &magnitudeComplex, &magnitudeShortInteger, &magnitudeLongInteger);
}

// The imaginary part of a conjugate: the sign flipped, a zero kept positive
// unless special results are on, then rounded to the selected significant digits.
fn conjugateComponent(component: *align(1) runtime.real34_t) void {
    component.bytes[15] ^= 0x80;
    if (runtime.real34IsZero(component) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        component.bytes[15] &= 0x7f;
    }
    runtime.roundReal34ResultToSignificantDigits(component);
}

fn conjugateRealMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &complex_matrix);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.roundReal34ResultToSignificantDigits(complexMatrixRealPtr(&complex_matrix, index));
        conjugateComponent(complexMatrixImagPtr(&complex_matrix, index));
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
    runtime.complexMatrixFree(&complex_matrix);
}

fn conjugateComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    // linkToComplexMatrixRegister aliases the register's own storage, so the loop
    // below edits the register in place and conjugate.c's conjCxma ends here. No
    // write-back: convertComplex34MatrixToComplex34MatrixRegister would
    // reallocateRegister the very block matrixElements points into and then copy
    // from it, and it can raise ERROR_RAM_FULL on a path where c43 never allocates.
    // conjRema above DOES write back and free, because its matrix is a converted
    // copy rather than the register.
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.roundReal34ResultToSignificantDigits(complexMatrixRealPtr(&complex_matrix, index));
        conjugateComponent(complexMatrixImagPtr(&complex_matrix, index));
    }
    runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
}

// A real34 or a long integer the conjugate turns into a complex34 with a zero
// imaginary part, its real part as stored (the real34 rounded to SDIGS).
fn conjugateRealIntoComplex(real: runtime.real34_t) void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
        return;
    }
    runtime.registerReal34Ptr(runtime.REGISTER_X).* = real;
    runtime.real34SetZero(runtime.registerImag34Data(runtime.REGISTER_X));
    conjugateComponent(runtime.registerImag34Ptr(runtime.REGISTER_X));
}

fn conjugateComplex() callconv(.c) void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    var value: runtime.cplx_t = undefined;

    if (data_type == runtime.dtComplex34) {
        runtime.roundReal34ResultToSignificantDigits(runtime.registerReal34Ptr(runtime.REGISTER_X));
        conjugateComponent(runtime.registerImag34Ptr(runtime.REGISTER_X));
        runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
        return;
    }
    if (data_type == runtime.dtReal34) {
        var real = runtime.registerReal34Ptr(runtime.REGISTER_X).*;
        runtime.roundReal34ResultToSignificantDigits(&real);
        conjugateRealIntoComplex(real);
        return;
    }
    if (data_type == runtime.dtLongInteger and (runtime.significantDigits == 0 or runtime.significantDigits == 34)) {
        var real: runtime.real34_t = undefined;
        runtime.convertLongIntegerRegisterToReal34(runtime.REGISTER_X, &real);
        conjugateRealIntoComplex(real);
        return;
    }
    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.realChangeSign(&value.Imag);
    if (runtime.realIsZero(&value.Imag) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(&value.Imag);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(&value, runtime.REGISTER_X);
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

fn swapRealImaginaryRealMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &real_matrix);
    runtime.convertReal34MatrixToComplex34Matrix(&real_matrix, &complex_matrix);
    if (!abi.matrixHasElements(&complex_matrix)) {
        return;
    }

    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        complexMatrixImagPtr(&complex_matrix, index).* = complexMatrixRealPtr(&complex_matrix, index).*;
        // real34SetZero (decQuadZero), NOT sixteen zero bytes. An all-zero blob
        // is a valid decQuad but a DIFFERENT member of zero's cohort than the one
        // decQuadZero writes, so the register ends up holding bytes c43 never
        // produces. swapRealImaginary.c uses real34SetZero here.
        runtime.real34SetZero(complexMatrixRealPtr(&complex_matrix, index));
        runtime.roundReal34ResultToSignificantDigits(complexMatrixImagPtr(&complex_matrix, index));
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
    runtime.complexMatrixFree(&complex_matrix);
}

fn swapRealImaginaryComplexMatrix() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    // Aliased to the register, so the swap lands in place and
    // swapRealImaginary.c's swapReImCxma ends here. swapReImRema above writes back
    // and frees because its matrix is a converted copy, not the register.
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = complexMatrixElementCount(&complex_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        const real_value = complexMatrixRealPtr(&complex_matrix, index).*;
        complexMatrixRealPtr(&complex_matrix, index).* = complexMatrixImagPtr(&complex_matrix, index).*;
        complexMatrixImagPtr(&complex_matrix, index).* = real_value;
        runtime.roundReal34ResultToSignificantDigits(complexMatrixRealPtr(&complex_matrix, index));
        runtime.roundReal34ResultToSignificantDigits(complexMatrixImagPtr(&complex_matrix, index));
    }
    runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
}

// A real34 or a long integer swapped into a complex34: zero real part, the value
// as the imaginary part.
fn swapRealIntoComplex(real: runtime.real34_t) void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
        return;
    }
    runtime.real34SetZero(runtime.registerReal34Data(runtime.REGISTER_X));
    runtime.registerImag34Ptr(runtime.REGISTER_X).* = real;
}

pub fn swapRealImaginary() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    var value: runtime.cplx_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (register_data_type == runtime.dtReal34Matrix) {
        swapRealImaginaryRealMatrix();
    } else if (register_data_type == runtime.dtComplex34Matrix) {
        swapRealImaginaryComplexMatrix();
    } else if (register_data_type == runtime.dtComplex34) {
        const real_value = runtime.registerReal34Ptr(runtime.REGISTER_X).*;
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = runtime.registerImag34Ptr(runtime.REGISTER_X).*;
        runtime.registerImag34Ptr(runtime.REGISTER_X).* = real_value;
        runtime.roundReal34ResultToSignificantDigits(runtime.registerReal34Ptr(runtime.REGISTER_X));
        runtime.roundReal34ResultToSignificantDigits(runtime.registerImag34Ptr(runtime.REGISTER_X));
        runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
    } else if (register_data_type == runtime.dtReal34) {
        var real = runtime.registerReal34Ptr(runtime.REGISTER_X).*;
        runtime.roundReal34ResultToSignificantDigits(&real);
        swapRealIntoComplex(real);
    } else if (register_data_type == runtime.dtLongInteger and (runtime.significantDigits == 0 or runtime.significantDigits == 34)) {
        var real: runtime.real34_t = undefined;
        runtime.convertLongIntegerRegisterToReal34(runtime.REGISTER_X, &real);
        swapRealIntoComplex(real);
    } else {
        if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &value)) {
            return;
        }
        runtime.convertComplexPartsToResultRegister(&value.Imag, &value.Real, runtime.REGISTER_X);
    }
}
