// SPDX-License-Identifier: GPL-3.0-only
// Zig port of src/c47/mathematics/idiv.c, idivr.c, dblMultiplication.c,
// dblDivision.c, round.c and decomp.c (dispatch tables, cells and the
// retained legacy entry points still reachable from the Zig wrappers).

const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("math_command_wrappers_runtime.zig");
const support = @import("math_dispatch_cells_runtime.zig");

const dm42_pkg_xip = @hasDecl(build_options, "dm42_pkg_xip") and build_options.dm42_pkg_xip;
const table_section: ?[]const u8 = if (dm42_pkg_xip) ".qspi_data" else null;

const CellFn = *const fn () callconv(.c) void;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const REGISTER_T = runtime.REGISTER_T;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const no_register = @as(runtime.calcRegister_t, -1);

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) [:0]const u8 {
    const slice = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args) catch buffer[0 .. buffer.len - 1];
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

fn domainError(comptime function_name: [:0]const u8, comptime message: [:0]const u8) void {
    runtime.displayCalcErrorMessage(support.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError(function_name, message, null, null);
}

fn longIntegerIsZero(value: *const runtime.mpz_struct) bool {
    return value._mp_size == 0;
}

fn longIntegerSetPositiveSign(value: *runtime.mpz_struct) void {
    value._mp_size = @intCast(@abs(value._mp_size));
}

fn longIntegerSetNegativeSign(value: *runtime.mpz_struct) void {
    value._mp_size = -@as(c_int, @intCast(@abs(value._mp_size)));
}

// longIntegerSetZero (longIntegerType.h): mpz_clear + mpz_init.
fn longIntegerSetZero(value: *runtime.mpz_struct) void {
    runtime.__gmpz_clear(value);
    runtime.__gmpz_init(value);
}

// longInteger2Pow (longIntegerType.h): result must be zero beforehand.
fn longInteger2Pow(exponent: c_ulong, result: *runtime.mpz_struct) void {
    support.__gmpz_setbit(result, exponent);
}

// ===== idiv.c =====

// regX = column, regY = row; layout copied verbatim from idiv.c.
const idiv_table: [10][10]CellFn = .{
    // regX |    regY ==>  1             2             3          4          5          6          7          8          9             10
    //      V              Long integer  Real34        Complex34  Time       Date       String     Real34 mat Cxma       Short integer Config data
    .{ &idivLonILonI, &idivRealLonI, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivShoILonI, &idivError }, //  1 Long integer
    .{ &idivLonIReal, &idivRealReal, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivShoIReal, &idivError }, //  2 Real34
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  3 Complex34
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  4 Time
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  5 Date
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  6 String
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  7 Real34 mat
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, //  8 Complex34 mat
    .{ &idivLonIShoI, &idivRealShoI, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivShoIShoI, &idivError }, //  9 Short integer
    .{ &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError, &idivError }, // 10 Config data
};

comptime {
    @export(&idiv_table, .{ .name = "idiv", .section = table_section });
}

pub export fn idivError() callconv(.c) void {
    var message1_buffer: [192]u8 = undefined;
    var message2_buffer: [192]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message1 = bufPrintZ(&message1_buffer, "cannot IDIV {s}", .{y_type_name});
    const message2 = bufPrintZ(&message2_buffer, "by {s}", .{x_type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function fnIDiv:", message1, message2, null);
}

pub export fn z47_math_wrappers_legacy_fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    idiv_table[runtime.getRegisterDataType(REGISTER_X)][runtime.getRegisterDataType(REGISTER_Y)]();

    runtime.adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, no_register);
}

pub export fn idivLonILonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivLonILonI:", "cannot IDIV a long integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
        support.__gmpz_tdiv_q(&x[0], &y[0], &x[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

        runtime.__gmpz_clear(&y[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivLonIShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivLonIShoI:", "cannot IDIV a long integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
        support.__gmpz_tdiv_q(&x[0], &y[0], &x[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

        runtime.__gmpz_clear(&y[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivShoILonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivShoILonI:", "cannot IDIV a short integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;

        runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
        support.__gmpz_tdiv_q(&x[0], &y[0], &x[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);

        runtime.__gmpz_clear(&y[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivLonIReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivLonIReal:", "cannot IDIV a long integer by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&x, REGISTER_X, runtime.DEC_ROUND_DOWN);
}

pub export fn idivRealLonI() callconv(.c) void {
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (runtime.realIsZero(&x)) {
        domainError("In function idivRealLonI:", "cannot IDIV a real34 by 0");
        return;
    }

    var y: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&x, REGISTER_X, runtime.DEC_ROUND_DOWN);
}

pub export fn idivShoIShoI() callconv(.c) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);
    if (value == 0) {
        domainError("In function idivShoIShoI:", "cannot IDIV a short integer by 0");
    } else {
        const x_data = runtime.registerShortIntegerPtr(REGISTER_X);
        const y_data = runtime.registerShortIntegerPtr(REGISTER_Y);
        x_data.* = runtime.WP34S_intDivide(y_data.*, x_data.*);
        runtime.setRegisterTag(REGISTER_X, runtime.getRegisterShortIntegerBase(REGISTER_Y));
    }
}

pub export fn idivShoIReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivShoIReal:", "cannot IDIV a short integer by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&x, REGISTER_X, runtime.DEC_ROUND_DOWN);
}

pub export fn idivRealShoI() callconv(.c) void {
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (runtime.realIsZero(&x)) {
        domainError("In function idivRealShoI:", "cannot IDIV a real34 by 0");
        return;
    }

    var y: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&x, REGISTER_X, runtime.DEC_ROUND_DOWN);
}

pub export fn idivRealReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivRealReal:", "cannot IDIV a real34 by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&x, REGISTER_X, runtime.DEC_ROUND_DOWN);
}

// ===== idivr.c =====

// regX = column, regY = row; layout copied verbatim from idivr.c.
const idivr_table: [10][10]CellFn = .{
    // regX |    regY ==>  1              2              3           4           5           6           7           8           9              10
    //      V              Long integer   Real34         Complex34   Time        Date        String      Real34 mat  Cxma        Short integer  Config data
    .{ &idivrLonILonI, &idivrRealLonI, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrShoILonI, &idivrError }, //  1 Long integer
    .{ &idivrLonIReal, &idivrRealReal, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrShoIReal, &idivrError }, //  2 Real34
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  3 Complex34
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  4 Time
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  5 Date
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  6 String
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  7 Real34 mat
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, //  8 Complex34 mat
    .{ &idivrLonIShoI, &idivrRealShoI, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrShoIShoI, &idivrError }, //  9 Short integer
    .{ &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError, &idivrError }, // 10 Config data
};

comptime {
    @export(&idivr_table, .{ .name = "idivr", .section = table_section });
}

pub export fn idivrError() callconv(.c) void {
    var message1_buffer: [192]u8 = undefined;
    var message2_buffer: [192]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message1 = bufPrintZ(&message1_buffer, "cannot IDIVR {s}", .{y_type_name});
    const message2 = bufPrintZ(&message2_buffer, "by {s}", .{x_type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function fnIDivR:", message1, message2, null);
}

pub export fn z47_math_wrappers_legacy_fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    idivr_table[runtime.getRegisterDataType(REGISTER_X)][runtime.getRegisterDataType(REGISTER_Y)]();

    runtime.adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, no_register);
    runtime.adjustResult(REGISTER_Y, false, false, REGISTER_X, REGISTER_Y, no_register);
}

pub export fn idivrLonILonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivrLonILonI:", "cannot IDIVR a long integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y[0], &x[0]);

        runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], REGISTER_X);
        runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], REGISTER_Y);

        runtime.__gmpz_clear(&y[0]);
        runtime.__gmpz_clear(&quotient[0]);
        runtime.__gmpz_clear(&remainder[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivrLonIShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivrLonIShoI:", "cannot IDIVR a long integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y[0], &x[0]);

        runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], REGISTER_X);
        runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], REGISTER_Y);

        runtime.__gmpz_clear(&y[0]);
        runtime.__gmpz_clear(&quotient[0]);
        runtime.__gmpz_clear(&remainder[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivrShoILonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivrShoILonI:", "cannot IDIVR a short integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        const base_y = runtime.getRegisterShortIntegerBase(REGISTER_Y);
        runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y[0], &x[0]);

        runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], REGISTER_X);
        runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, REGISTER_Y);

        runtime.__gmpz_clear(&y[0]);
        runtime.__gmpz_clear(&quotient[0]);
        runtime.__gmpz_clear(&remainder[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivrLonIReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivrLonIReal:", "cannot IDIVR a long integer by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;
    var q: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &q, &runtime.ctxtReal39);
    runtime.realToIntegralValue(&q, &q, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&q, REGISTER_X, runtime.DEC_ROUND_DOWN);

    runtime.WP34S_Mod(&y, &x, &y, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_Y, runtime.dtReal34, 0, @intCast(runtime.amNone));
    runtime.convertRealToReal34ResultRegister(&y, REGISTER_Y);
}

pub export fn idivrRealLonI() callconv(.c) void {
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (runtime.realIsZero(&x)) {
        domainError("In function idivrRealLonI:", "cannot IDIVR a real34 by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var q: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.realDivide(&y, &x, &q, &runtime.ctxtReal39);
    runtime.realToIntegralValue(&q, &q, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&q, REGISTER_X, runtime.DEC_ROUND_DOWN);

    runtime.WP34S_Mod(&y, &x, &y, &runtime.ctxtReal39);
    runtime.convertRealToReal34ResultRegister(&y, REGISTER_Y);
    runtime.setRegisterAngularMode(REGISTER_Y, runtime.amNone);
}

pub export fn idivrShoIShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_X, &x[0]);

    if (longIntegerIsZero(&x[0])) {
        domainError("In function idivrShoIShoI:", "cannot IDIVR a short integer by 0");
    } else {
        var y: runtime.longInteger_t = undefined;
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        const base_y = runtime.getRegisterShortIntegerBase(REGISTER_Y);
        runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y[0], &x[0]);

        runtime.convertLongIntegerToShortIntegerRegister(&quotient[0], base_y, REGISTER_X);
        runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, REGISTER_Y);

        runtime.__gmpz_clear(&y[0]);
        runtime.__gmpz_clear(&quotient[0]);
        runtime.__gmpz_clear(&remainder[0]);
    }

    runtime.__gmpz_clear(&x[0]);
}

pub export fn idivrShoIReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivrShoIReal:", "cannot IDIVR a short integer by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;
    var q: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &q, &runtime.ctxtReal39);
    runtime.realToIntegralValue(&q, &q, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&q, REGISTER_X, runtime.DEC_ROUND_DOWN);

    runtime.WP34S_Mod(&y, &x, &y, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_Y, runtime.dtReal34, 0, @intCast(runtime.amNone));
    runtime.convertRealToReal34ResultRegister(&y, REGISTER_Y);
}

pub export fn idivrRealShoI() callconv(.c) void {
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (runtime.realIsZero(&x)) {
        domainError("In function idivrRealShoI:", "cannot IDIVR a real34 by 0");
        return;
    }

    var y: runtime.real_t = undefined;
    var q: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.realDivide(&y, &x, &q, &runtime.ctxtReal39);
    runtime.realToIntegralValue(&q, &q, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&q, REGISTER_X, runtime.DEC_ROUND_DOWN);

    runtime.WP34S_Mod(&y, &x, &y, &runtime.ctxtReal39);
    runtime.convertRealToReal34ResultRegister(&y, REGISTER_Y);
    runtime.setRegisterAngularMode(REGISTER_Y, runtime.amNone);
}

pub export fn idivrRealReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        domainError("In function idivrRealReal:", "cannot IDIVR a real34 by 0");
        return;
    }

    var x: runtime.real_t = undefined;
    var y: runtime.real_t = undefined;
    var q: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
    runtime.realDivide(&y, &x, &q, &runtime.ctxtReal39);
    runtime.realToIntegralValue(&q, &q, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    runtime.convertRealToLongIntegerRegister(&q, REGISTER_X, runtime.DEC_ROUND_DOWN);

    runtime.WP34S_Mod(&y, &x, &y, &runtime.ctxtReal39);
    runtime.convertRealToReal34ResultRegister(&y, REGISTER_Y);
    runtime.setRegisterAngularMode(REGISTER_Y, runtime.amNone);
}

// ===== dblMultiplication.c =====

fn dblTypeError(comptime function_name: [:0]const u8, comptime operator_glyph: []const u8, regist: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    var message_buffer: [160]u8 = undefined;
    const type_name = std.mem.span(support.getDataTypeName(@intCast(runtime.getRegisterDataType(regist)), false, false));
    const message = bufPrintZ(&message_buffer, "the input type {s} is not allowed for DBL" ++ operator_glyph ++ "!", .{type_name});
    runtime.moreInfoOnError(function_name, message, null, null);
}

pub export fn z47_math_wrappers_legacy_fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const sim = runtime.shortIntegerMode;

    if (runtime.getRegisterDataType(REGISTER_X) != runtime.dtShortInteger) {
        dblTypeError("In function fnDblMultiply:", support.STD_CROSS, REGISTER_X);
        return;
    }
    if (runtime.getRegisterDataType(REGISTER_Y) != runtime.dtShortInteger) {
        dblTypeError("In function fnDblMultiply:", support.STD_CROSS, REGISTER_Y);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    var y: runtime.longInteger_t = undefined;
    var x: runtime.longInteger_t = undefined;
    var ans: runtime.longInteger_t = undefined;
    var wd: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&wd[0]);
    longInteger2Pow(runtime.shortIntegerWordSize, &wd[0]);

    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
    const base = runtime.getRegisterShortIntegerBase(REGISTER_Y);

    runtime.__gmpz_init(&ans[0]);
    support.longIntegerMultiply(&y[0], &x[0], &ans[0]);
    if (sim == runtime.SIM_1COMPL) {
        if ((runtime.registerShortIntegerPtr(REGISTER_Y).* & runtime.shortIntegerSignBit) != (runtime.registerShortIntegerPtr(REGISTER_X).* & runtime.shortIntegerSignBit)) {
            runtime.__gmpz_sub_ui(&ans[0], &ans[0], 1);
        }
        runtime.shortIntegerMode = runtime.SIM_2COMPL;
    } else if (sim == runtime.SIM_SIGNMT) {
        longIntegerSetPositiveSign(&ans[0]);
        runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    }

    support.__gmpz_mod(&y[0], &ans[0], &wd[0]); // longIntegerModulo(ans, wd, y)
    support.longIntegerSubtract(&ans[0], &y[0], &x[0]);
    support.__gmpz_tdiv_q(&x[0], &x[0], &wd[0]); // longIntegerDivide(x, wd, x)

    if (sim == runtime.SIM_SIGNMT) {
        runtime.shortIntegerMode = runtime.SIM_SIGNMT;
        if ((runtime.registerShortIntegerPtr(REGISTER_Y).* & runtime.shortIntegerSignBit) != (runtime.registerShortIntegerPtr(REGISTER_X).* & runtime.shortIntegerSignBit)) {
            longIntegerSetNegativeSign(&x[0]);
        }
    }

    runtime.convertLongIntegerToShortIntegerRegister(&y[0], base, REGISTER_Y);
    runtime.convertLongIntegerToShortIntegerRegister(&x[0], base, REGISTER_X);

    runtime.shortIntegerMode = sim;

    runtime.__gmpz_clear(&x[0]);
    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&ans[0]);
    runtime.__gmpz_clear(&wd[0]);

    runtime.clearSystemFlag(support.FLAG_OVERFLOW);
}

// ===== dblDivision.c =====

fn dblDivideImpl(remainder_mode: bool) void {
    const sim = runtime.shortIntegerMode;

    if (runtime.getRegisterDataType(REGISTER_X) != runtime.dtShortInteger) {
        dblTypeError("In function dblDivide:", support.STD_DIVIDE, REGISTER_X);
        return;
    }
    if (runtime.getRegisterDataType(REGISTER_Y) != runtime.dtShortInteger) {
        dblTypeError("In function dblDivide:", support.STD_DIVIDE, REGISTER_Y);
        return;
    }
    if (runtime.getRegisterDataType(REGISTER_Z) != runtime.dtShortInteger) {
        dblTypeError("In function dblDivide:", support.STD_DIVIDE, REGISTER_Z);
        return;
    }

    var x: runtime.longInteger_t = undefined;
    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
    if (longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(support.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_T);
        runtime.moreInfoOnError("In function dblDivide:", "cannot divide a short integer by 0", null, null);
        runtime.__gmpz_clear(&x[0]);
        return;
    }

    var wd: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&wd[0]);
    longInteger2Pow(runtime.shortIntegerWordSize, &wd[0]);

    var z: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Z, &z[0]);
    runtime.convertShortIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);
    runtime.shortIntegerMode = sim;
    const base = runtime.getRegisterShortIntegerBase(REGISTER_Y);

    var dividend: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&dividend[0]);
    support.longIntegerMultiply(&y[0], &wd[0], &dividend[0]);
    support.longIntegerAdd(&dividend[0], &z[0], &dividend[0]);

    if (sim != runtime.SIM_UNSIGN) {
        longIntegerSetZero(&wd[0]);
        longInteger2Pow(@as(c_ulong, runtime.shortIntegerWordSize) * 2 - 1, &wd[0]);
        if (runtime.__gmpz_cmp(&dividend[0], &wd[0]) >= 0) { // negative
            if (sim == runtime.SIM_SIGNMT) {
                support.longIntegerSubtract(&dividend[0], &wd[0], &dividend[0]);
                longIntegerSetNegativeSign(&dividend[0]);
            } else {
                longIntegerSetZero(&wd[0]);
                longInteger2Pow(@as(c_ulong, runtime.shortIntegerWordSize) * 2, &wd[0]);
                if (sim == runtime.SIM_1COMPL) {
                    runtime.__gmpz_sub_ui(&wd[0], &wd[0], 1);
                }
                support.longIntegerSubtract(&wd[0], &dividend[0], &dividend[0]);
                longIntegerSetNegativeSign(&dividend[0]);
            }
        }
        longIntegerSetZero(&wd[0]);
        longInteger2Pow(@as(c_ulong, runtime.shortIntegerWordSize) - 1, &wd[0]);
    }

    runtime.__gmpz_tdiv_qr(&z[0], &y[0], &dividend[0], &x[0]); // longIntegerDivideQuotientRemainder(dividend, x, z, y)

    var quotient_overflow = false;

    if (remainder_mode) {
        if (!runtime.saveLastX()) {
            return; // mirrors upstream early return without cleanup
        }
        runtime.convertLongIntegerToShortIntegerRegister(&y[0], base, REGISTER_X);
    } else {
        longIntegerSetPositiveSign(&wd[0]);
        quotient_overflow = check: {
            if (runtime.__gmpz_cmp(&z[0], &wd[0]) >= 0) { // check for positive quotient overflow
                break :check true;
            }
            if (sim != runtime.SIM_UNSIGN) {
                longIntegerSetNegativeSign(&wd[0]);
                if (runtime.__gmpz_cmp(&z[0], &wd[0]) < 0) { // check for negative quotient overflow
                    break :check true;
                } else if (sim != runtime.SIM_2COMPL and runtime.__gmpz_cmp(&z[0], &wd[0]) == 0) {
                    break :check true;
                }
            }
            break :check false;
        };

        if (!quotient_overflow) {
            if (!runtime.saveLastX()) {
                return; // mirrors upstream early return without cleanup
            }
            runtime.convertLongIntegerToShortIntegerRegister(&z[0], base, REGISTER_X);

            if (longIntegerIsZero(&y[0])) {
                runtime.clearSystemFlag(support.FLAG_CARRY);
            } else {
                runtime.setSystemFlag(support.FLAG_CARRY);
            }

            runtime.clearSystemFlag(support.FLAG_OVERFLOW);
        } else {
            runtime.displayCalcErrorMessage(support.ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
            runtime.moreInfoOnError("In function dblDivide:", "quotient overflow", null, null);
        }
    }

    if (!quotient_overflow) {
        runtime.fnDropY(support.NOPARAM);
        if (runtime.lastErrorCode == support.ERROR_NONE) {
            runtime.fnDropY(support.NOPARAM);
        }
    }

    runtime.__gmpz_clear(&dividend[0]);
    runtime.__gmpz_clear(&x[0]);
    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&z[0]);
    runtime.__gmpz_clear(&wd[0]);
}

pub export fn dblDivide(remainder_mode: bool) callconv(.c) void {
    dblDivideImpl(remainder_mode);
}

pub export fn z47_math_wrappers_legacy_fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    dblDivideImpl(false);
}

pub export fn z47_math_wrappers_legacy_fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    dblDivideImpl(true);
}

// ===== round.c =====

// regX index; layout copied verbatim from round.c.
const round_table: [10]CellFn = .{
    // regX ==> 1            2          3          4          5          6           7          8           9             10
    //          Long integer Real34     Complex34  Time       Date       String      Real34 mat Complex34 m Short integer Config data
    &support.doNothing, &roundReal, &roundCplx, &roundTime, &roundDate, &roundError, &roundRema, &roundCxma, &support.doNothing, &roundError,
};

comptime {
    @export(&round_table, .{ .name = "Round", .section = table_section });
}

pub export fn roundError() callconv(.c) void {
    var message_buffer: [192]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot calculate ROUND for {s}", .{type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function roundError:", message, null, null);
}

pub export fn z47_math_wrappers_legacy_fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    round_table[runtime.getRegisterDataType(REGISTER_X)]();

    runtime.adjustResult(REGISTER_X, false, false, REGISTER_X, no_register, no_register);
}

fn real34FromInt32(value: i32) runtime.real34_t {
    var result: runtime.real34_t = undefined;
    _ = support.decQuadFromInt32(&result, value);
    return result;
}

pub export fn roundTime() callconv(.c) void {
    var real34: runtime.real34_t = undefined;

    real34 = runtime.registerReal34Ptr(REGISTER_X).*;

    switch (support.timeDisplayFormatDigits) {
        0 => {}, // no rounding
        1, 2 => { // round to minutes
            const sixty = real34FromInt32(60); // const34_60
            runtime.real34Divide(&real34, &sixty, &real34);
            runtime.real34ToIntegralValue(&real34, &real34, runtime.DEC_ROUND_DOWN);
            runtime.real34Multiply(&real34, &sixty, &real34);
        },
        else => { // round to seconds, milliseconds, microseconds, ...
            // round to timeDisplayFormatDigits decimal places via scaleB (exponent shift)
            const n: i32 = @as(i32, support.timeDisplayFormatDigits) - 3;
            var shift: runtime.real34_t = undefined;
            _ = support.decQuadFromInt32(&shift, n);
            _ = support.decQuadScaleB(&real34, &real34, &shift, &runtime.ctxtReal34);
            runtime.real34ToIntegralValue(&real34, &real34, support.roundingModeTable[support.roundingMode]);
            _ = support.decQuadFromInt32(&shift, -n);
            _ = support.decQuadScaleB(&real34, &real34, &shift, &runtime.ctxtReal34);
        },
    }

    runtime.registerReal34Ptr(REGISTER_X).* = real34;
}

pub export fn roundDate() callconv(.c) void {
    // For the case accidentally added fractions of a day. It should not occur.
    var real34: runtime.real34_t = undefined;

    real34 = runtime.registerReal34Ptr(REGISTER_X).*;

    const half_day = real34FromInt32(43200); // const34_43200
    const full_day = real34FromInt32(86400); // const34_86400

    runtime.real34Subtract(&real34, &half_day, &real34);
    runtime.real34Divide(&real34, &full_day, &real34);

    runtime.real34ToIntegralValue(&real34, &real34, support.roundingModeTable[support.roundingMode]);

    runtime.real34Multiply(&real34, &full_day, &real34);
    runtime.real34Add(&real34, &half_day, &real34);

    runtime.registerReal34Ptr(REGISTER_X).* = real34;
}

pub export fn roundRema() callconv(.c) void {
    runtime.elementwiseRema(&roundReal);
}

pub export fn roundCxma() callconv(.c) void {
    support.elementwiseCxma(&roundCplx);
}

fn displayValueXCString(offset: i32) [*:0]const u8 {
    const base: [*]u8 = &support.displayValueX;
    return @ptrCast(base + @as(usize, @intCast(offset)));
}

pub export fn roundReal() callconv(.c) void {
    support.updateDisplayValueX = true;
    support.displayValueX[0] = 0;
    support.refreshRegisterLine(REGISTER_X);
    support.updateDisplayValueX = false;

    const dvx: [*]u8 = &support.displayValueX;

    if (runtime.getSystemFlag(support.FLAG_FRACT)) {
        var end_of_integer_part: i32 = -1;
        var numerator: runtime.real34_t = undefined;
        var denominator: runtime.real34_t = undefined;

        if (runtime.getSystemFlag(support.FLAG_PROPFR)) { // a b/c
            while (true) {
                end_of_integer_part += 1;
                if (dvx[@intCast(end_of_integer_part)] == ' ') {
                    break;
                }
            }
            dvx[@intCast(end_of_integer_part)] = 0;
            _ = support.decQuadFromString(runtime.registerReal34Ptr(REGISTER_X), displayValueXCString(0), &runtime.ctxtReal34);
        } else { // FT_IMPROPER d/c
            _ = support.decQuadZero(runtime.registerReal34Ptr(REGISTER_X));
        }

        var slash_pos: i32 = end_of_integer_part;
        end_of_integer_part += 1;
        while (true) {
            slash_pos += 1;
            if (dvx[@intCast(slash_pos)] == '/') {
                break;
            }
        }
        dvx[@intCast(slash_pos)] = 0;
        slash_pos += 1;
        _ = support.decQuadFromInt32(&numerator, support.stringToInt32(displayValueXCString(end_of_integer_part)));
        _ = support.decQuadFromInt32(&denominator, support.stringToInt32(displayValueXCString(slash_pos)));
        runtime.real34Divide(&numerator, &denominator, &numerator);
        if (dvx[0] == '-') {
            runtime.real34Subtract(runtime.registerReal34Ptr(REGISTER_X), &numerator, runtime.registerReal34Ptr(REGISTER_X));
        } else {
            runtime.real34Add(runtime.registerReal34Ptr(REGISTER_X), &numerator, runtime.registerReal34Ptr(REGISTER_X));
        }
    } else {
        _ = support.decQuadFromString(runtime.registerReal34Ptr(REGISTER_X), displayValueXCString(0), &runtime.ctxtReal34);
    }
}

pub export fn roundCplx() callconv(.c) void {
    var polar = false;

    support.updateDisplayValueX = true;
    support.displayValueX[0] = 0;
    support.refreshRegisterLine(REGISTER_X);
    support.updateDisplayValueX = false;

    const dvx: [*]u8 = &support.displayValueX;

    var pos_i: i32 = support.DISPLAY_VALUE_LEN - 1;
    var pos: i32 = 0;
    while (dvx[@intCast(pos)] != 0) {
        if (dvx[@intCast(pos)] == 'i') {
            pos_i = pos;
            break;
        }
        pos += 1;
    }

    if (pos_i == support.DISPLAY_VALUE_LEN - 1) {
        pos = 0;
        while (dvx[@intCast(pos)] != 0) {
            if (dvx[@intCast(pos)] == 'j') {
                pos_i = pos;
                polar = true;
                break;
            }
            pos += 1;
        }
    }

    dvx[@intCast(pos_i)] = 0;
    pos_i += 1;
    if (polar) {
        var magnitude: runtime.real_t = undefined;
        var theta: runtime.real_t = undefined;

        _ = runtime.decNumberFromString(&magnitude, displayValueXCString(0), &runtime.ctxtReal39);
        _ = runtime.decNumberFromString(&theta, displayValueXCString(pos_i), &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39);
        runtime.realToReal34(&magnitude, runtime.registerReal34Ptr(REGISTER_X));
        runtime.realToReal34(&theta, runtime.registerImag34Ptr(REGISTER_X));
    } else {
        _ = support.decQuadFromString(runtime.registerReal34Ptr(REGISTER_X), displayValueXCString(0), &runtime.ctxtReal34);
        _ = support.decQuadFromString(runtime.registerImag34Ptr(REGISTER_X), displayValueXCString(pos_i), &runtime.ctxtReal34);
    }
}

// ===== decomp.c =====

// regX index; layout copied verbatim from decomp.c.
const decomp_table: [10]CellFn = .{
    // regX ==> 1            2           3            4            5            6            7            8            9             10
    //          Long integer Real34      Complex34    Time         Date         String       Real34 mat   Complex34 m  Short integer Config data
    &decompLonI, &decompReal, &decompError, &decompError, &decompError, &decompError, &decompError, &decompError, &decompError, &decompError,
};

comptime {
    @export(&decomp_table, .{ .name = "Decomp", .section = table_section });
}

pub export fn decompError() callconv(.c) void {
    var message_buffer: [192]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function fnDecomp:", message, null, null);
}

pub export fn z47_math_wrappers_legacy_fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    decomp_table[runtime.getRegisterDataType(REGISTER_X)]();

    runtime.adjustResult(REGISTER_X, false, false, REGISTER_X, no_register, no_register);
    runtime.adjustResult(REGISTER_Y, false, false, REGISTER_Y, no_register, no_register);
}

pub export fn decompLonI() callconv(.c) void {
    var lg_int: runtime.longInteger_t = undefined;

    runtime.liftStack();
    runtime.__gmpz_init(&lg_int[0]);
    runtime.__gmpz_set_ui(&lg_int[0], 1);
    runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], REGISTER_X);
    runtime.__gmpz_clear(&lg_int[0]);
}

pub export fn decompReal() callconv(.c) void {
    var x: runtime.real34_t = undefined;

    x = runtime.registerReal34Ptr(REGISTER_X).*;
    runtime.setSystemFlag(support.FLAG_ASLIFT);
    runtime.liftStack();

    if (runtime.real34IsNaN(&x)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), REGISTER_X, runtime.DEC_ROUND_HALF_DOWN); // Denominator = 0
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), REGISTER_Y, runtime.DEC_ROUND_HALF_DOWN); // Numerator = 0
    } else if (runtime.real34IsInfinite(&x)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), REGISTER_X, runtime.DEC_ROUND_HALF_DOWN); // Denominator = 0
        runtime.convertRealToLongIntegerRegister(
            if ((x.bytes[15] & 0x80) == 0x80) runtime.z47_math_wrappers_const_minus_1() else runtime.z47_math_wrappers_const_1(),
            REGISTER_Y,
            runtime.DEC_ROUND_HALF_DOWN,
        ); // Numerator = +/- 1
    } else {
        const ssf0 = runtime.systemFlags0;
        const ssf1 = runtime.systemFlags1;
        var sign: i16 = 0;
        var less_equal_greater: i16 = 0;
        var int_part: u64 = 0;
        var numer: u64 = 0;
        var denom: u64 = 0;
        var lg_int: runtime.longInteger_t = undefined;

        runtime.clearSystemFlag(support.FLAG_PROPFR); // set improper fraction mode

        _ = runtime.fraction(REGISTER_Y, &sign, &int_part, &numer, &denom, &less_equal_greater);

        runtime.systemFlags0 = ssf0;
        runtime.systemFlags1 = ssf1;

        runtime.__gmpz_init(&lg_int[0]);

        runtime.__gmpz_set_ui(&lg_int[0], @as(c_ulong, @as(u32, @truncate(numer))));
        if (sign == -1) {
            longIntegerSetNegativeSign(&lg_int[0]);
        }
        runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], REGISTER_Y);

        runtime.__gmpz_set_ui(&lg_int[0], @as(c_ulong, @as(u32, @truncate(denom))));
        runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], REGISTER_X);

        runtime.__gmpz_clear(&lg_int[0]);
    }
}
