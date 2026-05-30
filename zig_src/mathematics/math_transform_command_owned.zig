const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const polar_rect_command_owned = @import("math_transform_polar_rect_command_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);
const square_root_retained = runtime.retained.z47_math_wrappers_retained_fnSquareRoot;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

fn shortIntegerData(reg: runtime.calcRegister_t) *align(1) u64 {
    return @as(*align(1) u64, @ptrCast(runtime.getRegisterDataPointer(reg).?));
}

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

fn unitVectorError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot calculate the unit vector of {s}", .{type_name}) catch "cannot calculate the unit vector";

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

fn squareLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_mul(&x[0], &x[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn squareShoI() callconv(.c) void {
    shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        shortIntegerData(runtime.REGISTER_X).*,
        shortIntegerData(runtime.REGISTER_X).*,
    );
}

fn squareReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_square_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn squareCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn cubeLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var cube_value: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_init(&cube_value[0]);
    defer runtime.__gmpz_clear(&cube_value[0]);

    runtime.__gmpz_mul(&cube_value[0], &x[0], &x[0]);
    runtime.__gmpz_mul(&cube_value[0], &cube_value[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&cube_value[0], runtime.REGISTER_X);
}

fn cubeShoI() callconv(.c) void {
    const square_value = runtime.WP34S_intMultiply(
        shortIntegerData(runtime.REGISTER_X).*,
        shortIntegerData(runtime.REGISTER_X).*,
    );
    shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        square_value,
        shortIntegerData(runtime.REGISTER_X).*,
    );
}

fn cubeReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var x_squared: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_cube_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x_squared, &runtime.ctxtReal39);
    runtime.realMultiply(&x_squared, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn cubeCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_square: runtime.real_t = undefined;
    var imag_square: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &real_square, &imag_square, &runtime.ctxtReal39);
    runtime.mulComplexComplex(&real_square, &imag_square, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn sqrtShoI() callconv(.c) void {
    var sign_value: i32 = 0;

    _ = runtime.WP34S_extract_value(shortIntegerData(runtime.REGISTER_X).*, &sign_value);
    if (sign_value != 0 and runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        var value: runtime.real_t = undefined;

        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intSqrt(shortIntegerData(runtime.REGISTER_X).*);
}

fn sqrtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use infinity as X input of sqrt when flag D is not set", null, null);
        return;
    }

    if (!runtime.realIsNegative(&value)) {
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function sqrtReal:", "sqrt does not accept a negative real when flag I is not set", null, null);
}

fn sqrtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    if (value[0]._mp_size >= 0) {
        var rem: runtime.longInteger_t = undefined;
        var root: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&rem[0]);
        defer runtime.__gmpz_clear(&rem[0]);
        runtime.__gmpz_init(&root[0]);
        defer runtime.__gmpz_clear(&root[0]);

        runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 2);
        if (rem[0]._mp_size == 0) {
            runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
            return;
        }
    }

    sqrtReal();
}

fn sqrtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value) and runtime.realIsNegative(&real_value)) {
        runtime.realChangeSign(&real_value);
        runtime.realSquareRoot(&real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSetZero(&real_value);
    } else if (runtime.realIsZero(&imag_value)) {
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_1on2(), &imag_value, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn curtShoI() callconv(.c) void {
    var value: runtime.real_t = undefined;
    var cube_root: i32 = 0;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    cube_root = runtime.realToInt32C47(&value, null);
    if (cube_root >= 0) {
        shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(cube_root), 0);
    } else {
        shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(-cube_root), 1);
    }
}

fn curtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function curtReal:", "cannot use infinity as X input of curt when flag D is not set", null, null);
        return;
    }

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn curtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var rem: runtime.longInteger_t = undefined;
    var root: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_init(&rem[0]);
    defer runtime.__gmpz_clear(&rem[0]);
    runtime.__gmpz_init(&root[0]);
    defer runtime.__gmpz_clear(&root[0]);

    runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 3);
    if (rem[0]._mp_size == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
        return;
    }

    curtReal();
}

fn curtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;
    var angle: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    magnitude = real_value;
    angle = imag_value;

    if (runtime.realIsZero(&angle)) {
        if (runtime.realIsNegative(&magnitude)) {
            runtime.realSetPositiveSign(&magnitude);
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
            runtime.realChangeSign(&real_value);
        } else {
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
        }
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&magnitude, &angle, &magnitude, &angle, &runtime.ctxtReal39);
        runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &magnitude, &runtime.ctxtReal39);
        runtime.realMultiply(&angle, runtime.z47_math_wrappers_const_1on3(), &angle, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&magnitude, &angle, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

pub fn square(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&squareReal, &squareCplx, &squareShoI, &squareLonI);
}

pub fn cube(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&cubeReal, &cubeCplx, &cubeShoI, &cubeLonI);
}

pub fn squareRoot(unused_but_mandatory_parameter: u16) void {
    const register_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (register_type == runtime.dtReal34Matrix or register_type == runtime.dtComplex34Matrix) {
        square_root_retained(0);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, &sqrtLonI);
}

pub fn cubeRoot(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}

pub fn toPolar2(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toPolar2(unused_but_mandatory_parameter);
}

pub fn toRect2(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toRect2(unused_but_mandatory_parameter);
}

pub fn toRect(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toRect(unused_but_mandatory_parameter);
}

pub fn parallel(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexDyadicFunction(&doParallelReal, &doParallelComplex);
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