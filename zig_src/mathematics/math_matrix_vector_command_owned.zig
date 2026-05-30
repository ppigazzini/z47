const std = @import("std");
const linpol_owned = @import("math_matrix_vector_linpol_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return @as(*runtime.real34_t, @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?)));
}

fn imag34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    const base: [*]u8 = @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?));
    return @as(*runtime.real34_t, @ptrCast(@alignCast(base + @sizeOf(runtime.real34_t))));
}

fn linpolScalar(a: *const runtime.real_t, b: *const runtime.real_t, p: *const runtime.real_t, res: *runtime.real_t) void {
    var x: runtime.real_t = undefined;

    if (runtime.realIsNaN(a) or runtime.realIsNaN(b) or runtime.realIsNaN(p) or runtime.realIsInfinite(p)) {
        runtime.realSetNaN(res);
    } else if (runtime.realIsInfinite(a)) {
        if (runtime.realIsInfinite(b)) {
            if (runtime.realIsNegative(a) == runtime.realIsNegative(b)) {
                res.* = a.*;
            } else {
                runtime.realSetNaN(res);
            }
        } else {
            res.* = a.*;
        }
    } else if (runtime.realIsInfinite(b)) {
        res.* = b.*;
    } else if (runtime.realCompareEqual(a, b)) {
        res.* = a.*;
    } else if (runtime.realIsNegative(a) != runtime.realIsNegative(b)) {
        x = p.*;
        runtime.realChangeSign(&x);
        runtime.realFMA(&x, a, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(p, b, &x, res, &runtime.ctxtReal75);
    } else {
        runtime.realSubtract(b, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(&x, p, a, res, &runtime.ctxtReal75);
    }
}

fn linpolReadP(p: *runtime.real_t) bool {
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), p);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, p, &runtime.ctxtReal75);
            return true;
        },
        else => return false,
    }
}

fn linpolReadCoeff(
    regist: runtime.calcRegister_t,
    data_type: u32,
    real_part: *runtime.real_t,
    imag_part: *runtime.real_t,
    real_coefs: *bool,
    data_tag: *runtime.angularMode_t,
) bool {
    switch (data_type) {
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal75);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal39);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.getRegisterAngularMode(regist);
            return true;
        },
        runtime.dtTime => {
            runtime.convertTimeRegisterToReal34Register(regist, regist);
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtDate => {
            runtime.internalDateToJulianDay(real34DataPointer(regist), real34DataPointer(regist));
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtComplex34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            runtime.real34ToReal(imag34DataPointer(regist), imag_part);
            real_coefs.* = false;
            data_tag.* = runtime.amNone;
            return true;
        },
        else => return false,
    }
}

fn linpolInvalidXError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot LINPOL with {s} in X", .{type_name}) catch "cannot LINPOL with current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

fn linpolDifferingTypeError() void {
    var message_buffer: [192]u8 = undefined;
    const type_name_y = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const type_name_z = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Z, true, false));
    const message = std.fmt.bufPrintZ(
        &message_buffer,
        "cannot LINPOL with differing data types in Y ({s}) and Z ({s})",
        .{ type_name_y, type_name_z },
    ) catch "cannot LINPOL with differing data types in Y and Z";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

fn linpolCoeffTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const register_name = if (regist == runtime.REGISTER_Y) "Y" else "Z";
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot LINPOL with {s} in {s}", .{ type_name, register_name }) catch "cannot LINPOL with current coefficient type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

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

fn linpol() callconv(.c) void {
    var a_real: runtime.real_t = undefined;
    var b_real: runtime.real_t = undefined;
    var a_imag: runtime.real_t = undefined;
    var b_imag: runtime.real_t = undefined;
    var p: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;
    var real_coefs = true;
    var data_tag_y: runtime.angularMode_t = runtime.amNone;
    var data_tag_z: runtime.angularMode_t = runtime.amNone;
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const type_z = runtime.getRegisterDataType(runtime.REGISTER_Z);
    const is_y_angle = type_y == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Y) != runtime.amNone;
    const is_z_angle = type_z == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Z) != runtime.amNone;

    runtime.realSetZero(&a_imag);
    runtime.realSetZero(&b_imag);

    if (!linpolReadP(&p)) {
        linpolInvalidXError();
        return;
    }

    if ((type_y != type_z and (type_y == runtime.dtTime or type_z == runtime.dtTime)) or
        (is_y_angle and !is_z_angle) or
        (is_z_angle and !is_y_angle))
    {
        linpolDifferingTypeError();
        return;
    }

    if (!linpolReadCoeff(runtime.REGISTER_Y, type_y, &b_real, &b_imag, &real_coefs, &data_tag_y)) {
        linpolCoeffTypeError(runtime.REGISTER_Y);
        return;
    }

    if (!linpolReadCoeff(runtime.REGISTER_Z, type_z, &a_real, &a_imag, &real_coefs, &data_tag_z)) {
        linpolCoeffTypeError(runtime.REGISTER_Z);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_Z);
    runtime.fnDrop(0);
    runtime.fnDrop(0);

    linpolScalar(&a_real, &b_real, &p, &result_real);
    if (real_coefs) {
        if (type_y == runtime.dtTime) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(&result_real, runtime.REGISTER_X);
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        } else if (type_y == runtime.dtDate) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
            runtime.realToReal34(&result_real, runtime.registerReal34Ptr(runtime.REGISTER_X));
            runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.DEC_ROUND_CEILING);
            runtime.julianDayToInternalDate(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
        } else {
            if (is_y_angle and is_z_angle) {
                if (data_tag_y != data_tag_z) {
                    data_tag_y = runtime.currentAngularMode;
                }
            } else {
                data_tag_y = runtime.amNone;
            }

            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @as(u32, @intCast(data_tag_y)));
            runtime.convertRealToReal34ResultRegister(&result_real, runtime.REGISTER_X);
        }

        return;
    }

    linpolScalar(&a_imag, &b_imag, &p, &result_imag);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

pub fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (tryCrossMatrices()) {
        return;
    }

    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        crossDotMatrixTypeError("In function fnCross:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&crossReal, &crossCplx);
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
