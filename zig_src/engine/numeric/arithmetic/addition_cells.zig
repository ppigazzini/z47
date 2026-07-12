// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/addition.c: the full ADD dispatch matrix
// (`addition`, consumed by store.c, recall.c and xeqm.c) plus every cell
// function and the addComplex helper. Faithful, line-by-line port of the C;
// upstream symbol names are kept at the export boundary. The legacy C fnAdd
// body lives on as z47_math_wrappers_legacy_fnAdd, the fallback the Zig
// fnAdd wrapper uses for the string/error cells not handled natively.
//
// The `addition` table is TO_QSPI in C; it goes to the executable QSPI
// region on the flash-limited DM42 old_hw firmware via linksection while the
// (hot) cell functions stay in default .text. This owner is excluded from
// the fake-harness parity lanes, where the C oracle compiles addition.c.

const std = @import("std");
const abi = @import("abi");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

// trimLeadingSpace (stringFuncs owner) — master fd83b4a4 strips the leading
// FRONTSPACE from a formatted number before appending it to a string.
extern fn trimLeadingSpace(stringToTrim: [*c]u8) void;

const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;
const CellFn = *const fn () callconv(.c) void;

// defines.h values (verified against src/c47/defines.h / items.h / display.h).
const NOPARAM: u16 = 9876;
const TEMP_REGISTER_1: runtime.calcRegister_t = 135;
const TMP_STR_LENGTH: i32 = 2560;
const SCREEN_WIDTH: i16 = 400;
const NUMBER_OF_DISPLAY_DIGITS: i16 = 20;
const LIMITEXP = true;
const FRONTSPACE = true;
const FULLIRFRAC: c_int = 3;
const no_base_override: u8 = 0;
const MAX_NUMBER_OF_GLYPHS_IN_STRING: i32 = 508;
const ERROR_STRING_WOULD_BE_TOO_LONG: u8 = 33;
const FLAG_FRACT: i32 = 0x8007;
const FLAG_POLAR: i32 = 0x8006;
const STD_CROSS = "\x80\xd7";

// regX |    regY ==>   1            2            3            4            5            6            7            8            9             10
//      V               Long integer Real34       Complex34    Time         Date         String       Real34 mat   Complex34 m  Short integer Config data
pub export const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]CellFn linksection(runtime.code_data_section) = .{
    // 1 Long integer
    .{ &addLonILonI, &addRealLonI, &addCplxLonI, &addTimeLonI, &addDateLonI, &addStriLonI, &addRemaLonI, &addCxmaLonI, &addShoILonI, &addError },
    // 2 Real34
    .{ &addLonIReal, &addRealReal, &addCplxReal, &addTimeReal, &addDateReal, &addStriReal, &addRemaReal, &addCxmaReal, &addShoIReal, &addError },
    // 3 Complex34
    .{ &addLonICplx, &addRealCplx, &addCplxCplx, &addError, &addError, &addStriCplx, &addRemaCplx, &addCxmaCplx, &addShoICplx, &addError },
    // 4 Time
    .{ &addLonITime, &addRealTime, &addError, &addTimeTime, &addError, &addStriTime, &addError, &addError, &addError, &addError },
    // 5 Date
    .{ &addLonIDate, &addRealDate, &addError, &addError, &addError, &addStriDate, &addError, &addError, &addError, &addError },
    // 6 String
    .{ &addRegYStri, &addRegYStri, &addRegYStri, &addRegYStri, &addRegYStri, &addStriStri, &addRegYStri, &addRegYStri, &addRegYStri, &addError },
    // 7 Real34 matrix
    .{ &addLonIRema, &addRealRema, &addCplxRema, &addError, &addError, &addStriRema, &addRemaRema, &addCxmaRema, &addShoIRema, &addError },
    // 8 Complex34 matrix
    .{ &addLonICxma, &addRealCxma, &addCplxCxma, &addError, &addError, &addStriCxma, &addRemaCxma, &addCxmaCxma, &addShoICxma, &addError },
    // 9 Short integer
    .{ &addLonIShoI, &addRealShoI, &addCplxShoI, &addError, &addError, &addStriShoI, &addRemaShoI, &addCxmaShoI, &addShoIShoI, &addError },
    // 10 Config data
    .{ &addError, &addError, &addError, &addError, &addError, &addError, &addError, &addError, &addError, &addError },
};

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

// REGISTER_STRING_DATA(a): data pointer + sizeof(strLgIntHeader_t) (4 bytes).
fn registerStringData(reg: runtime.calcRegister_t) [*c]u8 {
    const ptr = runtime.getRegisterDataPointer(reg) orelse return null;
    const bytes: [*]u8 = @ptrCast(ptr);
    return @ptrCast(bytes + 4);
}

// stringByteLength is "#define stringByteLength(str) ((int32_t)strlen(str))".
fn stringByteLength(str: [*c]const u8) i32 {
    var index: usize = 0;
    while (str[index] != 0) : (index += 1) {}
    return @intCast(index);
}

// TO_BLOCKS(n) = (n + BYTES_PER_BLOCK - 1) >> BPB with BPB = 2.
fn toBlocks(n: u32) u16 {
    return @intCast((n + 3) >> 2);
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

/// Data type error in addition (C: addError under EXTRA_INFO_ON_CALC_ERROR,
/// typeError otherwise; message reporting follows the established owner
/// convention, moreInfoOnError is a no-op away from the PC simulator).
pub export fn addError() callconv(.c) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);

    var message_buffer: [96]u8 = undefined;
    var second_buffer: [96]u8 = undefined;
    const type_name_x = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const type_name_y = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const message = bufPrintZ(&message_buffer, "cannot add {s}", .{type_name_x}) catch "cannot add";
    const second = bufPrintZ(&second_buffer, "to {s}", .{type_name_y}) catch "to";
    runtime.moreInfoOnError("In function fnAdd:", message, second, null);
}

/// The legacy C fnAdd body: saveLastX, matrix dispatch, adjustResult. The Zig
/// fnAdd wrapper (command_wrappers.zig) calls this for the cells it does
/// not handle natively (string rows/columns and the error cells).
pub export fn z47_math_wrappers_legacy_fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    addition[runtime.getRegisterDataType(runtime.REGISTER_X)][runtime.getRegisterDataType(runtime.REGISTER_Y)]();

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, -1);
}

pub export fn addRegYStri() callconv(.c) void {
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, TEMP_REGISTER_1);
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_Y, runtime.REGISTER_X);

    var tmp = [2]u8{ 0, 0 };
    const len: i32 = stringByteLength(&tmp) + 1;
    runtime.reallocateRegister(runtime.REGISTER_Y, runtime.dtString, toBlocks(@intCast(len)), runtime.amNone);
    _ = runtime.xcopy(registerStringData(runtime.REGISTER_Y), &tmp, @intCast(len));

    addition[runtime.getRegisterDataType(runtime.REGISTER_X)][runtime.getRegisterDataType(runtime.REGISTER_Y)]();

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_Y);
    runtime.copySourceRegisterToDestRegister(TEMP_REGISTER_1, runtime.REGISTER_X);

    addition[runtime.getRegisterDataType(runtime.REGISTER_X)][runtime.getRegisterDataType(runtime.REGISTER_Y)]();
}

// long integer + ...

/// Y(long integer) + X(long integer) ==> X(long integer)
pub export fn addLonILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_add(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(long integer) + X(time) ==> X(time)
pub export fn addLonITime() callconv(.c) void {
    runtime.convertLongIntegerRegisterToTimeRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(time) + X(long integer) ==> X(time)
pub export fn addTimeLonI() callconv(.c) void {
    runtime.convertLongIntegerRegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(long integer) + X(date) ==> X(date)
pub export fn addLonIDate() callconv(.c) void {
    var val: runtime.real34_t = undefined;
    runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_Y, runtime.REGISTER_Y);
    runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_Y), const34_86400(), &val);
    runtime.real34Add(&val, runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(date) + X(long integer) ==> X(date)
pub export fn addDateLonI() callconv(.c) void {
    var val: runtime.real34_t = undefined;
    runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_X), const34_86400(), &val);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), &val, runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(long integer) + X(short integer) ==> X(long integer)
pub export fn addLonIShoI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_add(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(short integer) + X(long integer) ==> X(long integer)
pub export fn addShoILonI() callconv(.c) void {
    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y[0]);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    runtime.__gmpz_add(&x[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

/// Y(long integer) + X(real34) ==> X(real34)
pub export fn addLonIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) + X(long integer) ==> X(real34)
pub export fn addRealLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &y);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);

    if (y_angular_mode == runtime.amNone) {
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(long integer) + X(complex34) ==> X(complex34)
pub export fn addLonICplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &a, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &c);

    runtime.realAdd(&a, &c, &c, &runtime.ctxtReal39);

    runtime.convertRealToReal34ResultRegister(&c, runtime.REGISTER_X);
}

/// Y(complex34) + X(long integer) ==> X(complex34)
pub export fn addCplxLonI() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var b: runtime.real34_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &a);
    b = runtime.registerImag34Ptr(runtime.REGISTER_Y).*;
    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &c, &runtime.ctxtReal39);

    runtime.realAdd(&a, &c, &c, &runtime.ctxtReal39);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&c, runtime.REGISTER_X);
    runtime.registerImag34Ptr(runtime.REGISTER_X).* = b;
}

// time + ...

/// Y(time) + X(time) ==> X(time)
pub export fn addTimeTime() callconv(.c) void {
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
}

/// Y(time) + X(real34) ==> X(time)
pub export fn addTimeReal() callconv(.c) void {
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        addError();
    }
}

/// Y(real34) + X(time) ==> X(time)
pub export fn addRealTime() callconv(.c) void {
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
        runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        addError();
    }
}

// date + ...

/// Y(date) + X(real34) ==> X(date)
pub export fn addDateReal() callconv(.c) void {
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    var val: runtime.real34_t = undefined;

    if (x_angular_mode == runtime.amNone) {
        runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.roundingModeTable[runtime.roundingMode]);
        runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_X), const34_86400(), &val);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
        runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), &val, runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        addError();
    }
}

/// Y(real34) + X(date) ==> X(date)
pub export fn addRealDate() callconv(.c) void {
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    var val: runtime.real34_t = undefined;

    if (y_angular_mode == runtime.amNone) {
        runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.roundingModeTable[runtime.roundingMode]);
        runtime.real34Multiply(runtime.registerReal34Ptr(runtime.REGISTER_Y), const34_86400(), &val);
        runtime.real34Add(&val, runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        addError();
    }
}

// string + ...

// static _addString in C.
fn addString(string_to_append: [*c]const u8) void {
    const y_glyphs = runtime.stringGlyphLength(registerStringData(runtime.REGISTER_Y));
    const append_glyphs = runtime.stringGlyphLength(string_to_append);

    if (y_glyphs + append_glyphs > MAX_NUMBER_OF_GLYPHS_IN_STRING) {
        runtime.displayCalcErrorMessage(ERROR_STRING_WOULD_BE_TOO_LONG, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        var message_buffer: [160]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "the resulting string would be {d} (Y {d} + X {d}) characters long. Maximum is {d}",
            .{ y_glyphs + append_glyphs, y_glyphs, append_glyphs, MAX_NUMBER_OF_GLYPHS_IN_STRING },
        ) catch "the resulting string would be too long";
        runtime.moreInfoOnError("In function _addString:", message, null, null);
    } else {
        const len1 = stringByteLength(registerStringData(runtime.REGISTER_Y));
        const len2 = stringByteLength(string_to_append) + 1;

        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtString, toBlocks(@intCast(len1 + len2)), runtime.amNone);

        _ = runtime.xcopy(registerStringData(runtime.REGISTER_X), registerStringData(runtime.REGISTER_Y), @intCast(len1));
        _ = runtime.xcopy(registerStringData(runtime.REGISTER_X) + @as(usize, @intCast(len1)), string_to_append, @intCast(len2));
    }
}

/// Y(string) + X(long integer) ==> X(string)
pub export fn addStriLonI() callconv(.c) void {
    runtime.longIntegerRegisterToDisplayString(runtime.REGISTER_X, runtime.tmpString, TMP_STR_LENGTH, SCREEN_WIDTH, 50, false);
    addString(runtime.tmpString);
}

/// Y(string) + X(time) ==> X(string)
pub export fn addStriTime() callconv(.c) void {
    runtime.timeToDisplayString(runtime.REGISTER_X, runtime.tmpString, false);
    addString(runtime.tmpString);
}

/// Y(string) + X(date) ==> X(string)
pub export fn addStriDate() callconv(.c) void {
    runtime.dateToDisplayString(runtime.REGISTER_X, runtime.tmpString);
    addString(runtime.tmpString);
}

/// Y(string) + X(string) ==> X(string)
pub export fn addStriStri() callconv(.c) void {
    const x_string = registerStringData(runtime.REGISTER_X);
    const copy_length: u32 = if (x_string != null and x_string[0] != 0)
        @intCast(stringByteLength(x_string) + 1)
    else
        1;
    _ = runtime.xcopy(runtime.tmpString, x_string, copy_length);
    addString(runtime.tmpString);
}

/// Y(string) + X(real34 matrix) ==> X(string)
pub export fn addStriRema() callconv(.c) void {
    runtime.real34MatrixToDisplayString(runtime.REGISTER_X, runtime.tmpString);
    addString(runtime.tmpString);
}

/// Y(string) + X(complex34 matrix) ==> X(string)
pub export fn addStriCxma() callconv(.c) void {
    runtime.complex34MatrixToDisplayString(runtime.REGISTER_X, runtime.tmpString);
    addString(runtime.tmpString);
}

/// Y(string) + X(short integer) ==> X(string)
pub export fn addStriShoI() callconv(.c) void {
    runtime.shortIntegerToDisplayString(runtime.REGISTER_X, runtime.tmpString, false, no_base_override);
    addString(runtime.tmpString);
}

/// Y(string) + X(real34) ==> X(string)
pub export fn addStriReal() callconv(.c) void {
    if (runtime.getSystemFlag(FLAG_FRACT)) {
        runtime.fractionToDisplayString(runtime.REGISTER_X, runtime.tmpString);
    } else {
        runtime.real34ToDisplayString(
            runtime.registerReal34Ptr(runtime.REGISTER_X),
            @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X)),
            runtime.tmpString,
            &runtime.standardFont,
            SCREEN_WIDTH,
            NUMBER_OF_DISPLAY_DIGITS,
            !LIMITEXP,
            FRONTSPACE,
            FULLIRFRAC,
        );
        trimLeadingSpace(runtime.tmpString);
    }
    addString(runtime.tmpString);
}

/// Y(string) + X(complex34) ==> X(string)
pub export fn addStriCplx() callconv(.c) void {
    runtime.complex34ToDisplayString(
        runtime.registerComplex34Ptr(runtime.REGISTER_X),
        runtime.tmpString,
        &runtime.numericFont,
        SCREEN_WIDTH,
        NUMBER_OF_DISPLAY_DIGITS,
        !LIMITEXP,
        FRONTSPACE,
        FULLIRFRAC,
        @intCast(runtime.currentAngularMode),
        runtime.getSystemFlag(FLAG_POLAR),
    );
    trimLeadingSpace(runtime.tmpString);
    addString(runtime.tmpString);
}

// real34 matrix + ...

/// Y(real34 matrix) + X(long integer) ==> X(real34 matrix)
pub export fn addRemaLonI() callconv(.c) void {
    var ym: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&ym, i), &y);
        runtime.realAdd(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, realElem(&ym, i));
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(long integer) + X(real34 matrix) ==> X(real34 matrix)
pub export fn addLonIRema() callconv(.c) void {
    var xm: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&xm, i), &x);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, realElem(&xm, i));
    }
}

/// Y(real34 matrix) + X(real34 matrix) ==> X(real34 matrix)
pub export fn addRemaRema() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;
    var x: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y);
    runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &x);
    if (runtime.lastErrorCode != 0) {
        return;
    }

    runtime.addRealMatrices(&y, &x, &x);
    if (x.matrixElements != null) {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        var message_buffer: [128]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot add {d}" ++ STD_CROSS ++ "{d}-matrix to {d}" ++ STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns), @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns) },
        ) catch "cannot add matrices of mismatched dimensions";
        runtime.moreInfoOnError("In function addRemaRema:", message, null, null);
    }

    runtime.realMatrixFree(&x);
}

/// Y(real34 matrix) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addRemaCxma() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    addCxmaCxma();
}

/// Y(complex34 matrix) + X(real34 matrix) ==> X(complex34 matrix)
pub export fn addCxmaRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    addCxmaCxma();
}

/// Y(real34 matrix) + X(short integer) ==> X(real34 matrix)
pub export fn addRemaShoI() callconv(.c) void {
    var ym: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&ym, i), &y);
        runtime.realAdd(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, realElem(&ym, i));
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(short integer) + X(real34 matrix) ==> X(real34 matrix)
pub export fn addShoIRema() callconv(.c) void {
    var xm: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(realElem(&xm, i), &x);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, realElem(&xm, i));
    }
}

/// Y(real34 matrix) + X(real34) ==> X(real34 matrix)
pub export fn addRemaReal() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            runtime.real34Add(realElem(&y, i), runtime.registerReal34Ptr(runtime.REGISTER_X), realElem(&y, i));
        }
        runtime.fnSwapXY(NOPARAM);
    } else {
        runtime.elementwiseRemaReal(&addRealReal);
    }
}

/// Y(real34) + X(real34 matrix) ==> X(real34 matrix)
pub export fn addRealRema() callconv(.c) void {
    var x: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), realElem(&x, i), realElem(&x, i));
        }
    } else {
        runtime.elementwiseRealRema(&addRealReal);
    }
}

/// Y(real34 matrix) + X(complex34) ==> X(complex34 matrix)
pub export fn addRemaCplx() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    addCxmaCplx();
}

/// Y(complex34) + X(real34 matrix) ==> X(complex34 matrix)
pub export fn addCplxRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    if (runtime.lastErrorCode != 0) {
        return;
    }
    addCplxCxma();
}

// complex34 matrix + ...

/// Y(complex34 matrix) + X(long integer) ==> X(complex34 matrix)
pub export fn addCxmaLonI() callconv(.c) void {
    var ym: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&ym, i).real, &y);
        runtime.realAdd(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, &cplxElem(&ym, i).real);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(long integer) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addLonICxma() callconv(.c) void {
    var xm: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&xm, i).real, &x);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, &cplxElem(&xm, i).real);
    }
}

/// Y(complex34 matrix) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addCxmaCxma() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);
    if (runtime.lastErrorCode != 0) {
        return;
    }

    runtime.addComplexMatrices(&y, &x, &x);
    if (x.matrixElements != null) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        var message_buffer: [128]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot add {d}" ++ STD_CROSS ++ "{d}-matrix to {d}" ++ STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns), @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns) },
        ) catch "cannot add matrices of mismatched dimensions";
        runtime.moreInfoOnError("In function addCxmaCxma:", message, null, null);
    }

    runtime.complexMatrixFree(&x);
}

/// Y(complex34 matrix) + X(short integer) ==> X(complex34 matrix)
pub export fn addCxmaShoI() callconv(.c) void {
    var ym: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &ym);

    const count = @as(i32, ym.header.matrixRows) * @as(i32, ym.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&ym, i).real, &y);
        runtime.realAdd(&y, &x, &y, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&y, &y, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&y, &cplxElem(&ym, i).real);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(short integer) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addShoICxma() callconv(.c) void {
    var xm: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &xm);

    const count = @as(i32, xm.header.matrixRows) * @as(i32, xm.header.matrixColumns);

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&cplxElem(&xm, i).real, &x);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x, &x, significantDigitsOr34(), &runtime.ctxtReal39);
        runtime.realToReal34(&x, &cplxElem(&xm, i).real);
    }
}

/// Y(complex34 matrix) + X(real34) ==> X(complex34 matrix)
pub export fn addCxmaReal() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            runtime.real34Add(&cplxElem(&y, i).real, runtime.registerReal34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).real);
        }
        runtime.fnSwapXY(NOPARAM);
    } else {
        runtime.elementwiseCxmaReal(&addCplxReal);
    }
}

/// Y(real34) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addRealCxma() callconv(.c) void {
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    if (y_angular_mode == runtime.amNone) {
        const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

        var i: i32 = 0;
        while (i < count) : (i += 1) {
            runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).real, &cplxElem(&x, i).real);
        }
    } else {
        runtime.elementwiseRealCxma(&addRealCplx);
    }
}

/// Y(complex34 matrix) + X(complex34) ==> X(complex34 matrix)
pub export fn addCxmaCplx() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y);

    const count = @as(i32, y.header.matrixRows) * @as(i32, y.header.matrixColumns);

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34Add(&cplxElem(&y, i).real, runtime.registerReal34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).real);
        runtime.real34Add(&cplxElem(&y, i).imag, runtime.registerImag34Ptr(runtime.REGISTER_X), &cplxElem(&y, i).imag);
    }
    runtime.fnSwapXY(NOPARAM);
}

/// Y(complex34) + X(complex34 matrix) ==> X(complex34 matrix)
pub export fn addCplxCxma() callconv(.c) void {
    var x: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);

    const count = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).real, &cplxElem(&x, i).real);
        runtime.real34Add(runtime.registerImag34Ptr(runtime.REGISTER_Y), &cplxElem(&x, i).imag, &cplxElem(&x, i).imag);
    }
}

// short integer + ...

/// Y(short integer) + X(short integer) ==> X(short integer)
pub export fn addShoIShoI() callconv(.c) void {
    runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterTag(runtime.REGISTER_Y));
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intAdd(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

/// Y(short integer) + X(real34) ==> X(real34)
pub export fn addShoIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (x_angular_mode == runtime.amNone) {
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&x, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) + X(short integer) ==> X(real34)
pub export fn addRealShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_Y), &y);
    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);

    if (y_angular_mode == runtime.amNone) {
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
    } else {
        runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(short integer) + X(complex34) ==> X(complex34)
pub export fn addShoICplx() callconv(.c) void {
    runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_Y, runtime.REGISTER_Y);
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
}

/// Y(complex34) + X(short integer) ==> X(complex34)
pub export fn addCplxShoI() callconv(.c) void {
    runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_Y)); // real part
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.registerComplex34Ptr(runtime.REGISTER_X).* = runtime.registerComplex34Ptr(runtime.REGISTER_Y).*;
}

// real34 + ...

/// Y(real34) + X(real34) ==> X(real34)
pub export fn addRealReal() callconv(.c) void {
    var y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    var x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
        runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
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

        runtime.realAdd(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, runtime.REGISTER_X);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

/// Y(real34) + X(complex34) ==> X(complex34)
pub export fn addRealCplx() callconv(.c) void {
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
}

/// Y(complex34) + X(real34) ==> X(complex34)
pub export fn addCplxReal() callconv(.c) void {
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_Y)); // real part
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.registerComplex34Ptr(runtime.REGISTER_X).* = runtime.registerComplex34Ptr(runtime.REGISTER_Y).*; // imaginary part
}

// complex34 + ...

pub export fn addComplex(
    a_real: *const runtime.real_t,
    a_imag: *const runtime.real_t,
    b_real: *const runtime.real_t,
    b_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realAdd(a_real, b_real, res_real, real_context);
    runtime.realAdd(a_imag, b_imag, res_imag, real_context);
}

/// Y(complex34) + X(complex34) ==> X(complex34)
pub export fn addCplxCplx() callconv(.c) void {
    runtime.real34Add(runtime.registerReal34Ptr(runtime.REGISTER_Y), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X)); // real part
    runtime.real34Add(runtime.registerImag34Ptr(runtime.REGISTER_Y), runtime.registerImag34Ptr(runtime.REGISTER_X), runtime.registerImag34Ptr(runtime.REGISTER_X)); // imaginary part
}
