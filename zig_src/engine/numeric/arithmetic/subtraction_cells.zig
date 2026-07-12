// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/subtraction.c: the full SUB dispatch
// matrix (`subtraction`, consumed by store.c and recall.c) plus every cell
// function, subDateDate and the subComplex helper. Faithful, line-by-line
// port of the C; upstream symbol names are kept at the export boundary. The
// legacy C fnSubtract body lives on as z47_math_wrappers_legacy_fnSubtract,
// the fallback the Zig fnSubtract wrapper uses for the error cells not
// handled natively.
//
// The `subtraction` table is TO_QSPI in C; it goes to the executable QSPI
// region on the flash-limited DM42 old_hw firmware via linksection while the
// (hot) cell functions stay in default .text. This owner is excluded from
// the fake-harness parity lanes, where the C oracle compiles subtraction.c.

const std = @import("std");
const abi = @import("abi");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;
const CellFn = *const fn () callconv(.c) void;

// defines.h values (verified against src/c47/defines.h / items.h).
const NOPARAM: u16 = 9876;
const STD_CROSS = "\x80\xd7";

// regX |    regY ==>   1            2            3            4            5            6         7            8            9             10
//      V               Long integer Real34       Complex34    Time         Date         String    Real34 mat   Complex34 m  Short integer Config data
pub export const subtraction: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]CellFn linksection(runtime.code_data_section) = .{
    // 1 Long integer
    .{ &subLonILonI, &subRealLonI, &subCplxLonI, &subTimeLonI, &subDateLonI, &subError, &subRemaLonI, &subCxmaLonI, &subShoILonI, &subError },
    // 2 Real34
    .{ &subLonIReal, &subRealReal, &subCplxReal, &subTimeReal, &subDateReal, &subError, &subRemaReal, &subCxmaReal, &subShoIReal, &subError },
    // 3 Complex34
    .{ &subLonICplx, &subRealCplx, &subCplxCplx, &subError, &subError, &subError, &subRemaCplx, &subCxmaCplx, &subShoICplx, &subError },
    // 4 Time
    .{ &subLonITime, &subRealTime, &subError, &subTimeTime, &subError, &subError, &subError, &subError, &subError, &subError },
    // 5 Date
    .{ &subError, &subError, &subError, &subError, &subDateDate, &subError, &subError, &subError, &subError, &subError },
    // 6 String
    .{ &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError },
    // 7 Real34 matrix
    .{ &subLonIRema, &subRealRema, &subCplxRema, &subError, &subError, &subError, &subRemaRema, &subCxmaRema, &subShoIRema, &subError },
    // 8 Complex34 matrix
    .{ &subLonICxma, &subRealCxma, &subCplxCxma, &subError, &subError, &subError, &subRemaCxma, &subCxmaCxma, &subShoICxma, &subError },
    // 9 Short integer
    .{ &subLonIShoI, &subRealShoI, &subCplxShoI, &subError, &subError, &subError, &subRemaShoI, &subCxmaShoI, &subShoIShoI, &subError },
    // 10 Config data
    .{ &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError, &subError },
};

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

// real34Subtract / real34ChangeSign are C macros over decQuad; reproduced inline.
inline fn real34Subtract(operand1: *const runtime.real34_t, operand2: *const runtime.real34_t, res: *runtime.real34_t) void {
    runtime.real34SubtractMacro(operand1, operand2, res);
}

inline fn real34ChangeSign(operand: *align(1) runtime.real34_t) void {
    operand.bytes[15] ^= 0x80;
}

fn significantDigitsOr34() i32 {
    return if (runtime.significantDigits == 0) 34 else runtime.significantDigits;
}

fn realElem(matrix: *runtime.real34Matrix_t, index: i32) *runtime.real34_t {
    return &abi.matrixRealElems(matrix)[@intCast(index)];
}

fn cplxElem(matrix: *runtime.complex34Matrix_t, index: i32) *runtime.complex34_t {
    return &abi.matrixComplexElems(matrix)[@intCast(index)];
}

// const34_86400: generated constant pointer in C; same decimal value built
// once through the decNumber library (exact: 86400 fits a real34).
var const34_86400_storage: runtime.real34_t = undefined;
var const34_86400_initialized = false;

fn const34_86400() *const runtime.real34_t {
    if (!const34_86400_initialized) {
        var value: runtime.real_t = undefined;
        runtime.uInt32ToReal(86400, &value);
        runtime.realToReal34(&value, &const34_86400_storage);
        const34_86400_initialized = true;
    }
    return &const34_86400_storage;
}

/// Data type error in subtraction (C: subError under EXTRA_INFO_ON_CALC_ERROR,
/// typeError otherwise; message reporting follows the established owner
/// convention, moreInfoOnError is a no-op away from the PC simulator).
pub export fn subError() callconv(.c) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);

    var message_buffer: [96]u8 = undefined;
    var second_buffer: [96]u8 = undefined;
    const type_name_x = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const type_name_y = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const message = bufPrintZ(&message_buffer, "cannot subtract {s}", .{type_name_x}) catch "cannot subtract";
    const second = bufPrintZ(&second_buffer, "from {s}", .{type_name_y}) catch "from";
    runtime.moreInfoOnError("In function fnSubtract:", message, second, null);
}

/// The legacy C fnSubtract body: saveLastX, matrix dispatch, adjustResult.
/// The Zig fnSubtract wrapper calls this for the
/// cells it does not handle natively (the error cells).
pub export fn z47_math_wrappers_legacy_fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    subtraction[runtime.getRegisterDataType(runtime.REGISTER_X)][runtime.getRegisterDataType(runtime.REGISTER_Y)]();

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, -1);
}

// long integer - ...

/// Y(long integer) - X(long integer) ==> X(long integer)
pub export fn subLonILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_sub(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(long integer) - X(time) ==> X(time)
pub export fn subLonITime() callconv(.c) void {
    runtime.convertLongIntegerRegisterToTimeRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(time) - X(long integer) ==> X(time)
pub export fn subTimeLonI() callconv(.c) void {
    runtime.convertLongIntegerRegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(date) - X(long integer) ==> X(date)
pub export fn subDateLonI() callconv(.c) void {
    var val: runtime.real34_t = undefined;
    runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_X), const34_86400(), &val);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), &val, runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(long integer) - X(short integer) ==> X(long integer)
pub export fn subLonIShoI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_sub(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(short integer) - X(long integer) ==> X(long integer)
pub export fn subShoILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_sub(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(long integer) - X(real34) ==> X(real34)
pub export fn subLonIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) - X(long integer) ==> X(real34)
pub export fn subRealLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &y);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);

    if (y_angular_mode == runtime.amNone) {
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(long integer) - X(complex34) ==> X(complex34)
pub export fn subLonICplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &a, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &c);

    runtime.realSubtract(&a, &c, &c, &runtime.ctxtReal39);

    runtime.convertRealToReal34ResultRegister(&c, runtime.REGISTER_X);
    real34ChangeSign(runtime.registerImag34Ptr(runtime.REGISTER_X));
}

/// Y(complex34) - X(long integer) ==> X(complex34)
pub export fn subCplxLonI() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var b: runtime.real34_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &a);
    b = runtime.registerImag34Ptr(runtime.REGISTER_Y).*;
    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &c, &runtime.ctxtReal39);

    runtime.realSubtract(&a, &c, &c, &runtime.ctxtReal39);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&c, runtime.REGISTER_X);
    runtime.registerImag34Ptr(runtime.REGISTER_X).* = b;
}

// time - ...

/// Y(time) - X(time) ==> X(time)
pub export fn subTimeTime() callconv(.c) void {
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(time) - X(real34) ==> X(time)
pub export fn subTimeReal() callconv(.c) void {
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        subError();
    }
}

/// Y(real34) - X(time) ==> X(time)
pub export fn subRealTime() callconv(.c) void {
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
        real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        subError();
    }
}

// date - ...

/// Y(date) - X(date) ==> X(long integer)
pub export fn subDateDate() callconv(.c) void {
    var val: runtime.real34_t = undefined;

    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_Y));
    runtime.real34Divide(runtime.registerReal34Ptr(runtime.REGISTER_Y), const34_86400(), &val);
    runtime.convertReal34ToLongIntegerRegister(&val, runtime.REGISTER_X, runtime.DEC_ROUND_DOWN);
}

/// Y(date) - X(real34) ==> X(date)
pub export fn subDateReal() callconv(.c) void {
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    var val: runtime.real34_t = undefined;

    if (x_angular_mode == runtime.amNone) {
        runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.roundingModeTable[runtime.roundingMode]);
        runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_X), const34_86400(), &val);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
        real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), &val, runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        subError();
    }
}

// real34 matrix - ...

/// Y(real34 matrix) - X(long integer) ==> X(real34 matrix)
pub export fn subRemaLonI() callconv(.c) void {
    var ym: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&ym, i), &y);
        runtime.realSubtract(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, realElem(&ym, i));
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(long integer) - X(real34 matrix) ==> X(real34 matrix)
pub export fn subLonIRema() callconv(.c) void {
    var xm: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&xm, i), &x);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, realElem(&xm, i));
    }
}

/// Y(real34 matrix) - X(real34 matrix) ==> X(real34 matrix)
pub export fn subRemaRema() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;
    var x: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y);
    runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &x);
    if (runtime.lastErrorCode != 0) {
        return;
    }

    runtime.subtractRealMatrices(&y, &x, &x);
    if (x.matrixElements != null) {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        var message_buffer: [128]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot subtract {d}" ++ STD_CROSS ++ "{d}-matrix from {d}" ++ STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns), @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns) },
        ) catch "cannot subtract matrices of mismatched dimensions";
        runtime.moreInfoOnError("In function subRemaRema:", message, null, null);
    }

    runtime.realMatrixFree(&x);
}

/// Y(real34 matrix) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subRemaCxma() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    subCxmaCxma();
}

/// Y(complex34 matrix) - X(real34 matrix) ==> X(complex34 matrix)
pub export fn subCxmaRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    subCxmaCxma();
}

/// Y(real34 matrix) - X(short integer) ==> X(real34 matrix)
pub export fn subRemaShoI() callconv(.c) void {
    var ym: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&ym, i), &y);
        runtime.realSubtract(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, realElem(&ym, i));
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(short integer) - X(real34 matrix) ==> X(real34 matrix)
pub export fn subShoIRema() callconv(.c) void {
    var xm: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&xm, i), &x);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, realElem(&xm, i));
    }
}

/// Y(real34 matrix) - X(real34) ==> X(real34 matrix)
pub export fn subRemaReal() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            real34Subtract(realElem(&y, i), runtime.registerReal34Ptr(runtime.REGISTER_X), realElem(&y, i));
        }
        runtime.fnSwapXY(NOPARAM);
    } else {
        runtime.elementwiseRemaReal(&subRealReal);
    }
}

/// Y(real34) - X(real34 matrix) ==> X(real34 matrix)
pub export fn subRealRema() callconv(.c) void {
    var x: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), realElem(&x, i), realElem(&x, i));
        }
    } else {
        runtime.elementwiseRealRema(&subRealReal);
    }
}

/// Y(real34 matrix) - X(complex34) ==> X(complex34 matrix)
pub export fn subRemaCplx() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    subCxmaCplx();
}

/// Y(complex34) - X(real34 matrix) ==> X(complex34 matrix)
pub export fn subCplxRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    subCplxCxma();
}

// complex34 matrix - ...

/// Y(complex34 matrix) - X(long integer) ==> X(complex34 matrix)
pub export fn subCxmaLonI() callconv(.c) void {
    var ym: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&ym, i).real, &y);
        runtime.realSubtract(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, &cplxElem(&ym, i).real);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(long integer) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subLonICxma() callconv(.c) void {
    var xm: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&xm, i).real, &x);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, &cplxElem(&xm, i).real);
        real34ChangeSign(&cplxElem(&xm, i).imag);
    }
}

/// Y(complex34 matrix) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subCxmaCxma() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);
    if (runtime.lastErrorCode != 0) {
        return;
    }

    runtime.subtractComplexMatrices(&y, &x, &x);
    if (x.matrixElements != null) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        var message_buffer: [128]u8 = undefined;
        // The C message says "add"/"to" here as well (kept verbatim).
        const message = bufPrintZ(
            &message_buffer,
            "cannot add {d}" ++ STD_CROSS ++ "{d}-matrix to {d}" ++ STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns), @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns) },
        ) catch "cannot subtract matrices of mismatched dimensions";
        runtime.moreInfoOnError("In function subCxmaCxma:", message, null, null);
    }

    runtime.complexMatrixFree(&x);
}

/// Y(complex34 matrix) - X(short integer) ==> X(complex34 matrix)
pub export fn subCxmaShoI() callconv(.c) void {
    var ym: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&ym, i).real, &y);
        runtime.realSubtract(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, &cplxElem(&ym, i).real);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(short integer) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subShoICxma() callconv(.c) void {
    var xm: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&xm, i).real, &x);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, &cplxElem(&xm, i).real);
        real34ChangeSign(&cplxElem(&xm, i).imag);
    }
}

/// Y(complex34 matrix) - X(real34) ==> X(complex34 matrix)
pub export fn subCxmaReal() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            real34Subtract(&cplxElem(&y, i).real, runtime.registerReal34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).real);
        }
        runtime.fnSwapXY(NOPARAM);
    } else {
        runtime.elementwiseCxmaReal(&subCplxReal);
    }
}

/// Y(real34) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subRealCxma() callconv(.c) void {
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).real, &cplxElem(&x, i).real);
            real34ChangeSign(&cplxElem(&x, i).imag);
        }
    } else {
        runtime.elementwiseRealCxma(&subRealCplx);
    }
}

/// Y(complex34 matrix) - X(complex34) ==> X(complex34 matrix)
pub export fn subCxmaCplx() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);

    const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        real34Subtract(&cplxElem(&y, i).real, runtime.registerReal34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).real);
        real34Subtract(&cplxElem(&y, i).imag, runtime.registerImag34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).imag);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(complex34) - X(complex34 matrix) ==> X(complex34 matrix)
pub export fn subCplxCxma() callconv(.c) void {
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);

    const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).real, &cplxElem(&x, i).real);
        real34Subtract(runtime.registerImag34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).imag, &cplxElem(&x, i).imag);
    }
}

// short integer - ...

/// Y(short integer) - X(short integer) ==> X(short integer)
pub export fn subShoIShoI() callconv(.c) void {
    runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterTag(runtime.REGISTER_Y));
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intSubtract(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

/// Y(short integer) - X(real34) ==> X(real34)
pub export fn subShoIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x);

    if (x_angular_mode == runtime.amNone) {
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) - X(short integer) ==> X(real34)
pub export fn subRealShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &y);
    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);

    if (y_angular_mode == runtime.amNone) {
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(short integer) - X(complex34) ==> X(complex34)
pub export fn subShoICplx() callconv(.c) void {
    runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_Y, runtime.REGISTER_Y);
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
    real34ChangeSign(runtime.registerImag34Ptr(runtime.REGISTER_X));
}

/// Y(complex34) - X(short integer) ==> X(complex34)
pub export fn subCplxShoI() callconv(.c) void {
    runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_Y)); // real part
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.registerComplex34Ptr(runtime.REGISTER_X).* = runtime.registerComplex34Ptr(runtime.REGISTER_Y).*;
}

// real34 - ...

/// Y(real34) - X(real34) ==> X(real34)
pub export fn subRealReal() callconv(.c) void {
    var y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    var x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
        real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        var y: runtime.real_t = undefined;
        var x: runtime.real_t = undefined;

        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &y);
        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x);

        if (y_angular_mode == runtime.amNone) {
            y_angular_mode = runtime.currentAngularMode;
        } else if (x_angular_mode == runtime.amNone) {
            x_angular_mode = runtime.currentAngularMode;
        }

        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);

        runtime.realSubtract(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) - X(complex34) ==> X(complex34)
pub export fn subRealCplx() callconv(.c) void {
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
    real34ChangeSign(runtime.registerImag34Ptr(runtime.REGISTER_X));
}

/// Y(complex34) - X(real34) ==> X(complex34)
pub export fn subCplxReal() callconv(.c) void {
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_Y)); // real part
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.registerComplex34Ptr(runtime.REGISTER_X).* = runtime.registerComplex34Ptr(runtime.REGISTER_Y).*;
}

// complex34 - ...

pub export fn subComplex(
    a_real: *const runtime.real_t,
    a_imag: *const runtime.real_t,
    b_real: *const runtime.real_t,
    b_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realSubtract(a_real, b_real, res_real, real_context);
    runtime.realSubtract(a_imag, b_imag, res_imag, real_context);
}

/// Y(complex34) - X(complex34) ==> X(complex34)
pub export fn subCplxCplx() callconv(.c) void {
    real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
    real34Subtract(runtime.registerImag34Ptr(runtime.REGISTER_Y), runtime.registerImag34Ptr(runtime.REGISTER_X), runtime.registerImag34Ptr(runtime.REGISTER_X)); // imaginary part
}
