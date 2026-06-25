// SPDX-License-Identifier: GPL-3.0-only
// Zig port of src/c47/mathematics/multiplication.c (dispatch matrix and cells).

const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("math_command_wrappers_runtime.zig");
const support = @import("math_dispatch_cells_runtime.zig");

const dm42_pkg_xip = @hasDecl(build_options, "dm42_pkg_xip") and build_options.dm42_pkg_xip;
const table_section: ?[]const u8 = if (dm42_pkg_xip) ".qspi" else null;

const CellFn = *const fn () callconv(.c) void;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const no_register = @as(runtime.calcRegister_t, -1);

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) [:0]const u8 {
    const slice = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args) catch buffer[0 .. buffer.len - 1];
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

// regX = column, regY = row; layout copied verbatim from multiplication.c.
const multiplication_table: [10][10]CellFn = .{
    // regX |    regY ==>  1            2            3            4            5         6         7            8            9             10
    //      V              Long integer Real34       Complex34    Time         Date      String    Real34 mat   Complex34 m  Short integer Config data
    .{ &mulLonILonI, &mulRealLonI, &mulCplxLonI, &mulTimeLonI, &mulError, &mulError, &mulRemaLonI, &mulCxmaLonI, &mulShoILonI, &mulError }, //  1 Long integer
    .{ &mulLonIReal, &mulRealReal, &mulCplxReal, &mulTimeReal, &mulError, &mulError, &mulRemaReal, &mulCxmaReal, &mulShoIReal, &mulError }, //  2 Real34
    .{ &mulLonICplx, &mulRealCplx, &mulCplxCplx, &mulError, &mulError, &mulError, &mulRemaCplx, &mulCxmaCplx, &mulShoICplx, &mulError }, //  3 Complex34
    .{ &mulLonITime, &mulRealTime, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulShoITime, &mulError }, //  4 Time
    .{ &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError }, //  5 Date
    .{ &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError }, //  6 String
    .{ &mulLonIRema, &mulRealRema, &mulCplxRema, &mulError, &mulError, &mulError, &mulRemaRema, &mulCxmaRema, &mulShoIRema, &mulError }, //  7 Real34 mat
    .{ &mulLonICxma, &mulRealCxma, &mulCplxCxma, &mulError, &mulError, &mulError, &mulRemaCxma, &mulCxmaCxma, &mulShoICxma, &mulError }, //  8 Complex34 mat
    .{ &mulLonIShoI, &mulRealShoI, &mulCplxShoI, &mulTimeShoI, &mulError, &mulError, &mulRemaShoI, &mulCxmaShoI, &mulShoIShoI, &mulError }, //  9 Short integer
    .{ &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError, &mulError }, // 10 Config data
};

comptime {
    @export(&multiplication_table, .{ .name = "multiplication", .section = table_section });
}

pub export fn mulError() callconv(.c) void {
    var message1_buffer: [192]u8 = undefined;
    var message2_buffer: [192]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message1 = bufPrintZ(&message1_buffer, "cannot multiply {s}", .{y_type_name});
    const message2 = bufPrintZ(&message2_buffer, "by {s}", .{x_type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function fnMultiply:", message1, message2, null);
}

pub export fn z47_math_wrappers_legacy_fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    multiplication_table[runtime.getRegisterDataType(REGISTER_X)][runtime.getRegisterDataType(REGISTER_Y)]();

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, no_register);
}

pub export fn mulComplexi(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    product_real: *runtime.real_t,
    product_imag: *runtime.real_t,
) callconv(.c) void {
    var tmp_i: runtime.real_t = undefined;

    _ = support.decNumberCopy(&tmp_i, in_imag);
    runtime.realChangeSign(&tmp_i);
    _ = support.decNumberCopy(product_imag, in_real);
    _ = support.decNumberCopy(product_real, &tmp_i);
}

fn mulComplexComplex75(
    factor1_real: *const runtime.real_t,
    factor1_imag: *const runtime.real_t,
    factor2_real: *const runtime.real_t,
    factor2_imag: *const runtime.real_t,
    product_real: *runtime.real_t,
    product_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var d: runtime.real_t = undefined;
    var p: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;

    _ = support.decNumberCopy(&a, factor1_real);
    const a_is_zero = runtime.realIsZero(&a);
    const a_is_infinite = runtime.realIsInfinite(&a);

    _ = support.decNumberCopy(&b, factor1_imag);
    const b_is_zero = runtime.realIsZero(&b);
    const b_is_infinite = runtime.realIsInfinite(&b);

    _ = support.decNumberCopy(&c, factor2_real);
    const c_is_zero = runtime.realIsZero(&c);
    const c_is_infinite = runtime.realIsInfinite(&c);

    _ = support.decNumberCopy(&d, factor2_imag);
    const d_is_zero = runtime.realIsZero(&d);
    const d_is_infinite = runtime.realIsInfinite(&d);

    if (runtime.realIsNaN(&a) or runtime.realIsNaN(&b) or runtime.realIsNaN(&c) or runtime.realIsNaN(&d) or
        (a_is_zero and b_is_zero and (c_is_infinite or d_is_infinite)) or
        (c_is_zero and d_is_zero and (a_is_infinite or b_is_infinite)))
    {
        runtime.realSetNaN(product_real);
        runtime.realSetNaN(product_imag);
        return;
    }

    if ((a_is_infinite or b_is_infinite) and (c_is_infinite or d_is_infinite)) { // perform multiplication in polar form
        support.setInfiniteComplexAngle(
            (support.getInfiniteComplexAngle(&a, &b) + support.getInfiniteComplexAngle(&c, &d)) % 8,
            product_real,
            product_imag,
        );
    } else { // perform multiplication in rectangular form using numerically stable approach
        // real part
        runtime.realMultiply(&a, &c, &p, real_context); // RN(ac)
        runtime.realChangeSign(&b);
        runtime.realFMA(&b, &d, &p, &t, real_context); // RN(p - bd)
        runtime.realChangeSign(&b);
        runtime.realChangeSign(&p);
        runtime.realFMA(&a, &c, &p, product_real, real_context); // RN(ac - p)
        runtime.realAdd(product_real, &t, product_real, real_context); // RN(RN(p - bd) + RN(ac - p))

        // imaginary part
        runtime.realMultiply(&a, &d, &p, real_context); // RN(ad)
        runtime.realFMA(&b, &c, &p, &t, real_context); // RN(bc + p)
        runtime.realChangeSign(&p);
        runtime.realFMA(&a, &d, &p, product_imag, real_context); // RN(ad - p)
        runtime.realAdd(product_imag, &t, product_imag, real_context); // RN(RN(bc + p) + RN(ad - p))
    }
}

// Compiled when OPTION_CUBIC_159 / OPTION_SQUARE_159 / OPTION_EIGEN_159 are
// enabled upstream; only reachable when realContext->digits > 75.
fn mulComplexComplex159(
    factor1_real: *const runtime.real_t,
    factor1_imag: *const runtime.real_t,
    factor2_real: *const runtime.real_t,
    factor2_imag: *const runtime.real_t,
    product_real: *runtime.real_t,
    product_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a_data: support.real159_t = undefined;
    var b_data: support.real159_t = undefined;
    var c_data: support.real159_t = undefined;
    var d_data: support.real159_t = undefined;
    var p_data: support.real159_t = undefined;

    const a = support.asReal(&a_data);
    const b = support.asReal(&b_data);
    const c = support.asReal(&c_data);
    const d = support.asReal(&d_data);
    const p = support.asReal(&p_data);

    runtime.realSetZero(a);
    runtime.realSetZero(b);
    runtime.realSetZero(c);
    runtime.realSetZero(d);
    runtime.realSetZero(p);
    _ = support.decNumberCopy(a, factor1_real);
    _ = support.decNumberCopy(b, factor1_imag);
    _ = support.decNumberCopy(c, factor2_real);
    _ = support.decNumberCopy(d, factor2_imag);

    // Real part: ac - bd
    runtime.realMultiply(a, c, p, real_context);
    runtime.realChangeSign(b);
    runtime.realFMA(b, d, p, product_real, real_context);
    runtime.realChangeSign(b);

    // Imaginary part: ad + bc
    runtime.realMultiply(a, d, p, real_context);
    runtime.realFMA(b, c, p, product_imag, real_context);
}

pub export fn mulComplexComplex(
    factor1_real: *const runtime.real_t,
    factor1_imag: *const runtime.real_t,
    factor2_real: *const runtime.real_t,
    factor2_imag: *const runtime.real_t,
    product_real: *runtime.real_t,
    product_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (real_context.digits <= 75) {
        mulComplexComplex75(factor1_real, factor1_imag, factor2_real, factor2_imag, product_real, product_imag, real_context);
    } else if (!dm42_pkg_xip and real_context.digits <= 159) {
        // OPTION_CUBIC_159/OPTION_EIGEN_159 are undefined for TWO_FILE_PGM
        // (old-hardware DM42) builds, exactly like upstream defines.h.
        mulComplexComplex159(factor1_real, factor1_imag, factor2_real, factor2_imag, product_real, product_imag, real_context);
    } else {
        var message_buffer: [96]u8 = undefined;
        const message = bufPrintZ(&message_buffer, "Exceed digits :mulComplexComplex: {d}", .{real_context.digits});
        support.displayBugScreen(message);
    }
}

pub export fn mulComplexReal(
    factor1_real: *const runtime.real_t,
    factor1_imag: *const runtime.real_t,
    factor2: *const runtime.real_t,
    product_real: *runtime.real_t,
    product_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realMultiply(factor1_real, factor2, product_real, real_context);
    runtime.realMultiply(factor1_imag, factor2, product_imag, real_context);
}

// ===== long integer × ... =====

pub export fn mulLonILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    support.longIntegerMultiply(&y[0], &x[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

pub export fn mulLonITime() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);

    runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
    runtime.realToReal34(&x, runtime.registerReal34Ptr(REGISTER_X));
}

pub export fn mulTimeLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));

    runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
    runtime.realToReal34(&x, runtime.registerReal34Ptr(REGISTER_X));
}

pub export fn mulLonIRema() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    support._multiplyRealMatrix(&matrix, &y, &res, &runtime.ctxtReal39);
    runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
    runtime.realMatrixFree(&res);
}

pub export fn mulRemaLonI() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
    support._multiplyRealMatrix(&matrix, &x, &res, &runtime.ctxtReal39);
    runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
    runtime.realMatrixFree(&res);
}

pub export fn mulLonICxma() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
    support._multiplyComplexMatrix(&matrix, &y, runtime.z47_math_wrappers_const_0(), &res, &runtime.ctxtReal39);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
    runtime.complexMatrixFree(&res);
}

pub export fn mulCxmaLonI() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &y, &runtime.ctxtReal39);
    runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
    support._multiplyComplexMatrix(&matrix, &y, runtime.z47_math_wrappers_const_0(), &res, &runtime.ctxtReal39);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
    runtime.complexMatrixFree(&res);
}

pub export fn mulLonIShoI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    support.convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    support.longIntegerMultiply(&y[0], &x[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

pub export fn mulShoILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    support.longIntegerMultiply(&y[0], &x[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

pub export fn mulLonIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
    }
}

pub export fn mulRealLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);
    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));

    if (y_angular_mode == runtime.amNone) {
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
    }
}

pub export fn mulLonICplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var d: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &a, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &c);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &d);

    runtime.realMultiply(&c, &a, &c, &runtime.ctxtReal39);
    runtime.realMultiply(&d, &a, &d, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&c, &d, REGISTER_X);
}

pub export fn mulCplxLonI() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &a);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_Y), &b);
    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &c, &runtime.ctxtReal39);

    runtime.realMultiply(&a, &c, &a, &runtime.ctxtReal39);
    runtime.realMultiply(&b, &c, &b, &runtime.ctxtReal39);

    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.convertComplexToResultRegister(&a, &b, REGISTER_X);
}

// ===== time × ... =====

pub export fn mulTimeShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));

    runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
    runtime.realToReal34(&x, runtime.registerReal34Ptr(REGISTER_X));
}

pub export fn mulShoITime() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);

    runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
    runtime.realToReal34(&x, runtime.registerReal34Ptr(REGISTER_X));
}

pub export fn mulTimeReal() callconv(.c) void {
    const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        var b: runtime.real34_t = undefined;

        b = runtime.registerReal34Ptr(REGISTER_X).*;
        runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));
        runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), &b, runtime.registerReal34Ptr(REGISTER_X));
    } else {
        mulError();
    }
}

pub export fn mulRealTime() callconv(.c) void {
    const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X));
    } else {
        mulError();
    }
}

// ===== real34 matrix × ... =====

pub export fn mulRemaRema() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;
    var x: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(REGISTER_Y, &y);
    runtime.linkToRealMatrixRegister(REGISTER_X, &x);

    support.multiplyRealMatrices(&y, &x, &res);
    if (res.matrixElements != null) {
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    } else {
        runtime.displayCalcErrorMessage(support.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        var message_buffer: [196]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot multiply {d}" ++ support.STD_CROSS ++ "{d}-matrix and {d}" ++ support.STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns), @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns) },
        );
        runtime.moreInfoOnError("In function mulRemaRema:", message, null, null);
    }
}

pub export fn mulRemaCxma() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    mulCxmaCxma();
}

pub export fn mulCxmaRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_X, REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    mulCxmaCxma();
}

pub export fn mulRemaShoI() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
    support._multiplyRealMatrix(&matrix, &x, &res, &runtime.ctxtReal39);
    runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
    runtime.realMatrixFree(&res);
}

pub export fn mulShoIRema() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);

    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    support._multiplyRealMatrix(&matrix, &y, &res, &runtime.ctxtReal39);
    runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
    runtime.realMatrixFree(&res);
}

pub export fn mulRemaReal() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
        var matrix: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
        support.multiplyRealMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), &matrix);
        runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
    } else {
        runtime.elementwiseRemaReal(&mulRealReal);
    }
}

pub export fn mulRealRema() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_Y) == runtime.amNone) {
        var matrix: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
        support.multiplyRealMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_Y), &matrix);
    } else {
        support.elementwiseRealRema(&mulRealReal);
    }
}

pub export fn mulRemaCplx() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    mulCxmaCplx();
}

pub export fn mulCplxRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_X, REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    mulCplxCxma();
}

// ===== complex34 matrix × ... =====

pub export fn mulCxmaCxma() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;
    var x: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_Y, &y);
    runtime.linkToComplexMatrixRegister(REGISTER_X, &x);

    support.multiplyComplexMatrices(&y, &x, &res);
    if (res.matrixElements != null) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
        runtime.complexMatrixFree(&res);
    } else {
        runtime.displayCalcErrorMessage(support.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        var message_buffer: [196]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot multiply {d}" ++ support.STD_CROSS ++ "{d}-matrix and {d}" ++ support.STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns), @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns) },
        );
        runtime.moreInfoOnError("In function mulCxmaCxma:", message, null, null);
    }
}

pub export fn mulCxmaShoI() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    mulCxmaReal();
}

pub export fn mulShoICxma() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    mulRealCxma();
}

pub export fn mulCxmaReal() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
        var matrix: runtime.complex34Matrix_t = undefined;
        var zero34: runtime.real34_t = undefined;

        _ = support.decQuadZero(&zero34);
        runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
        support.multiplyComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), &zero34, &matrix);
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
    } else {
        support.elementwiseCxmaReal(&mulCplxReal);
    }
}

pub export fn mulRealCxma() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_Y) == runtime.amNone) {
        var matrix: runtime.complex34Matrix_t = undefined;
        var zero34: runtime.real34_t = undefined;

        _ = support.decQuadZero(&zero34);
        runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
        support.multiplyComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_Y), &zero34, &matrix);
    } else {
        support.elementwiseRealCxma(&mulRealCplx);
    }
}

pub export fn mulCxmaCplx() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
    support.multiplyComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_X), &matrix);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
}

pub export fn mulCplxCxma() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
    support.multiplyComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_Y), runtime.registerImag34Ptr(REGISTER_Y), &matrix);
}

// ===== short integer × ... =====

pub export fn mulShoIShoI() callconv(.c) void {
    runtime.setRegisterTag(REGISTER_X, runtime.getRegisterTag(REGISTER_Y));
    const x_data = runtime.registerShortIntegerPtr(REGISTER_X);
    const y_data = runtime.registerShortIntegerPtr(REGISTER_Y);
    x_data.* = runtime.WP34S_intMultiply(y_data.*, x_data.*);
}

pub export fn mulShoIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
    }
}

pub export fn mulRealShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);
    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));

    if (y_angular_mode == runtime.amNone) {
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
    }
}

pub export fn mulShoICplx() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X)); // real part
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerImag34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_X)); // imaginary part
}

pub export fn mulCplxShoI() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_Y)); // real part
    runtime.real34Multiply(runtime.registerImag34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_Y)); // imaginary part
    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.registerComplex34Ptr(REGISTER_X).* = runtime.registerComplex34Ptr(REGISTER_Y).*;
}

// ===== real34 × ... =====

pub export fn mulRealReal() callconv(.c) void {
    const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);
    const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

    if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) { // Neither is an angle
        runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X));
    } else if (y_angular_mode != runtime.amNone and x_angular_mode != runtime.amNone) { // Both are angles
        runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X));
        runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
    } else { // One and only one is an angle
        var y: runtime.real_t = undefined;
        var x: runtime.real_t = undefined;

        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
        runtime.realMultiply(&y, &x, &x, &runtime.ctxtReal39);

        runtime.convertAngleFromTo(&x, if (y_angular_mode != runtime.amNone) y_angular_mode else x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);

        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
    }
}

pub export fn mulRealCplx() callconv(.c) void {
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X)); // real part
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerImag34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_X)); // imaginary part
}

pub export fn mulCplxReal() callconv(.c) void {
    runtime.real34Multiply(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_Y)); // real part
    runtime.real34Multiply(runtime.registerImag34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_Y)); // imaginary part
    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.registerComplex34Ptr(REGISTER_X).* = runtime.registerComplex34Ptr(REGISTER_Y).*;
}

// ===== complex34 × ... =====

pub export fn mulCplxCplx() callconv(.c) void {
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_Y), &y_imag);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &x_imag);

    mulComplexComplex(&y_real, &y_imag, &x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x_real, &x_imag, REGISTER_X);
}
