// SPDX-License-Identifier: GPL-3.0-only
// Zig port of src/c47/mathematics/division.c (dispatch matrix and cells).

const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("math_command_wrappers_runtime.zig");
const support = @import("math_dispatch_cells_runtime.zig");

const dm42_pkg_xip = @hasDecl(build_options, "dm42_pkg_xip") and build_options.dm42_pkg_xip;
const table_section: ?[]const u8 = if (dm42_pkg_xip) ".qspi" else null;

const CellFn = *const fn () callconv(.c) void;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_L = runtime.REGISTER_L;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const no_register = @as(runtime.calcRegister_t, -1);

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) [:0]const u8 {
    const slice = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args) catch buffer[0 .. buffer.len - 1];
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

// regX = column, regY = row; layout copied verbatim from division.c.
const division_table: [10][10]CellFn = .{
    // regX |    regY ==>  1            2            3            4            5         6         7            8            9             10
    //      V              Long integer Real34       Complex34    Time         Date      String    Real34 mat   Complex34 m  Short integer Config data
    .{ &divLonILonI, &divRealLonI, &divCplxLonI, &divTimeLonI, &divError, &divError, &divRemaLonI, &divCxmaLonI, &divShoILonI, &divError }, //  1 Long integer
    .{ &divLonIReal, &divRealReal, &divCplxReal, &divTimeReal, &divError, &divError, &divRemaReal, &divCxmaReal, &divShoIReal, &divError }, //  2 Real34
    .{ &divLonICplx, &divRealCplx, &divCplxCplx, &divError, &divError, &divError, &divRemaCplx, &divCxmaCplx, &divShoICplx, &divError }, //  3 Complex34
    .{ &divLonITime, &divRealTime, &divError, &divTimeTime, &divError, &divError, &divError, &divError, &divShoITime, &divError }, //  4 Time
    .{ &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError }, //  5 Date
    .{ &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError }, //  6 String
    .{ &divLonIRema, &divRealRema, &divCplxRema, &divError, &divError, &divError, &divRemaRema, &divCxmaRema, &divShoIRema, &divError }, //  7 Real34 mat
    .{ &divLonICxma, &divRealCxma, &divCplxCxma, &divError, &divError, &divError, &divRemaCxma, &divCxmaCxma, &divShoICxma, &divError }, //  8 Complex34 mat
    .{ &divLonIShoI, &divRealShoI, &divCplxShoI, &divTimeShoI, &divError, &divError, &divRemaShoI, &divCxmaShoI, &divShoIShoI, &divError }, //  9 Short integer
    .{ &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError, &divError }, // 10 Config data
};

comptime {
    @export(&division_table, .{ .name = "division", .section = table_section });
}

pub export fn divError() callconv(.c) void {
    var message1_buffer: [192]u8 = undefined;
    var message2_buffer: [192]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
    const message1 = bufPrintZ(&message1_buffer, "cannot divide {s}", .{y_type_name});
    const message2 = bufPrintZ(&message2_buffer, "by {s}", .{x_type_name});

    runtime.displayCalcErrorMessage(support.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError("In function fnDivide:", message1, message2, null);
}

pub export fn z47_math_wrappers_legacy_fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);

    division_table[runtime.getRegisterDataType(REGISTER_X)][runtime.getRegisterDataType(REGISTER_Y)]();

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, no_register);
}

fn divisionDomainError(comptime function_name: [:0]const u8, comptime message: [:0]const u8) void {
    runtime.displayCalcErrorMessage(support.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    runtime.moreInfoOnError(function_name, message, null, null);
}

fn divComplexComplex75(
    numer_real: *const runtime.real_t,
    numer_imag: *const runtime.real_t,
    denom_real: *const runtime.real_t,
    denom_imag: *const runtime.real_t,
    quotient_real: *runtime.real_t,
    quotient_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var real_numer: runtime.real_t = undefined;
    var real_denom: runtime.real_t = undefined;
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var d: runtime.real_t = undefined;

    _ = support.decNumberCopy(&a, numer_real);
    _ = support.decNumberCopy(&b, numer_imag);
    _ = support.decNumberCopy(&c, denom_real);
    _ = support.decNumberCopy(&d, denom_imag);

    if (runtime.realIsNaN(&a) or runtime.realIsNaN(&b) or runtime.realIsNaN(&c) or runtime.realIsNaN(&d)) {
        runtime.realSetNaN(quotient_real);
        runtime.realSetNaN(quotient_imag);
        return;
    }

    if (runtime.realIsInfinite(&c) or runtime.realIsInfinite(&d)) {
        if (runtime.realIsInfinite(&a) or runtime.realIsInfinite(&b)) {
            runtime.realSetNaN(quotient_real);
            runtime.realSetNaN(quotient_imag);
        } else {
            runtime.realSetZero(quotient_real);
            runtime.realSetZero(quotient_imag);
        }
        return;
    }

    if (runtime.realIsInfinite(&a) and !runtime.realIsInfinite(&b)) {
        runtime.realSetZero(&b);
    }

    if (runtime.realIsInfinite(&b) and !runtime.realIsInfinite(&a)) {
        runtime.realSetZero(&a);
    }

    // Denominator
    runtime.realMultiply(&c, &c, &real_denom, real_context); // realDenom = c²
    runtime.realFMA(&d, &d, &real_denom, &real_denom, real_context); // realDenom = c² + d²

    // real part
    runtime.realMultiply(&a, &c, &real_numer, real_context); // realNumer = a*c
    runtime.realFMA(&b, &d, &real_numer, &real_numer, real_context); // realNumer = a*c + b*d
    runtime.realDivide(&real_numer, &real_denom, quotient_real, real_context); // realPart = (a*c + b*d) / (c² + d²)

    // imaginary part
    runtime.realMultiply(&b, &c, &real_numer, real_context); // realNumer = b*c
    runtime.realChangeSign(&a); // a = -a
    runtime.realFMA(&a, &d, &real_numer, &real_numer, real_context); // realNumer = b*c - a*d
    runtime.realDivide(&real_numer, &real_denom, quotient_imag, real_context); // imagPart = (b*c - a*d) / (c² + d²)
}

// Compiled when OPTION_CUBIC_159 / OPTION_SQUARE_159 / OPTION_EIGEN_159 are
// enabled upstream; only reachable when realContext->digits > 75.
fn divComplexComplex159(
    numer_real: *const runtime.real_t,
    numer_imag: *const runtime.real_t,
    denom_real: *const runtime.real_t,
    denom_imag: *const runtime.real_t,
    quotient_real: *runtime.real_t,
    quotient_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var real_numer_data: support.real159_t = undefined;
    var real_denom_data: support.real159_t = undefined;
    var a_data: support.real159_t = undefined;
    var b_data: support.real159_t = undefined;
    var c_data: support.real159_t = undefined;
    var d_data: support.real159_t = undefined;

    const real_numer = support.asReal(&real_numer_data);
    const real_denom = support.asReal(&real_denom_data);
    const a = support.asReal(&a_data);
    const b = support.asReal(&b_data);
    const c = support.asReal(&c_data);
    const d = support.asReal(&d_data);

    runtime.realSetZero(real_numer);
    runtime.realSetZero(real_denom);
    runtime.realSetZero(a);
    runtime.realSetZero(b);
    runtime.realSetZero(c);
    runtime.realSetZero(d);

    _ = support.decNumberCopy(a, numer_real);
    _ = support.decNumberCopy(b, numer_imag);
    _ = support.decNumberCopy(c, denom_real);
    _ = support.decNumberCopy(d, denom_imag);

    if (runtime.realIsNaN(a) or runtime.realIsNaN(b) or runtime.realIsNaN(c) or runtime.realIsNaN(d)) {
        runtime.realSetNaN(quotient_real);
        runtime.realSetNaN(quotient_imag);
        return;
    }

    if (runtime.realIsInfinite(c) or runtime.realIsInfinite(d)) {
        if (runtime.realIsInfinite(a) or runtime.realIsInfinite(b)) {
            runtime.realSetNaN(quotient_real);
            runtime.realSetNaN(quotient_imag);
        } else {
            runtime.realSetZero(quotient_real);
            runtime.realSetZero(quotient_imag);
        }
        return;
    }

    if (runtime.realIsInfinite(a) and !runtime.realIsInfinite(b)) {
        runtime.realSetZero(b);
    }
    if (runtime.realIsInfinite(b) and !runtime.realIsInfinite(a)) {
        runtime.realSetZero(a);
    }

    // Denominator: c² + d²
    runtime.realMultiply(c, c, real_denom, real_context);
    runtime.realFMA(d, d, real_denom, real_denom, real_context);

    // Real part: (a*c + b*d) / (c² + d²)
    runtime.realMultiply(a, c, real_numer, real_context);
    runtime.realFMA(b, d, real_numer, real_numer, real_context);
    runtime.realDivide(real_numer, real_denom, quotient_real, real_context);

    // Imaginary part: (b*c - a*d) / (c² + d²)
    runtime.realMultiply(b, c, real_numer, real_context);
    runtime.realChangeSign(a);
    runtime.realFMA(a, d, real_numer, real_numer, real_context);
    runtime.realDivide(real_numer, real_denom, quotient_imag, real_context);
}

pub export fn divComplexComplex(
    numer_real: *const runtime.real_t,
    numer_imag: *const runtime.real_t,
    denom_real: *const runtime.real_t,
    denom_imag: *const runtime.real_t,
    quotient_real: *runtime.real_t,
    quotient_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (real_context.digits <= 75) {
        divComplexComplex75(numer_real, numer_imag, denom_real, denom_imag, quotient_real, quotient_imag, real_context);
    } else if (!dm42_pkg_xip and real_context.digits <= 159) {
        // OPTION_CUBIC_159/OPTION_EIGEN_159 are undefined for TWO_FILE_PGM
        // (old-hardware DM42) builds, exactly like upstream defines.h.
        divComplexComplex159(numer_real, numer_imag, denom_real, denom_imag, quotient_real, quotient_imag, real_context);
    } else {
        var message_buffer: [96]u8 = undefined;
        const message = bufPrintZ(&message_buffer, "Exceed digits :divComplexComplex: {d}", .{real_context.digits});
        support.displayBugScreen(message);
    }
}

pub export fn divRealComplex(
    numer_real: *const runtime.real_t,
    denom_real: *const runtime.real_t,
    denom_imag: *const runtime.real_t,
    quotient_real: *runtime.real_t,
    quotient_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;
    var d: runtime.real_t = undefined;
    var denom: runtime.real_t = undefined;

    _ = support.decNumberCopy(&a, numer_real);
    _ = support.decNumberCopy(&c, denom_real);
    _ = support.decNumberCopy(&d, denom_imag);

    if (runtime.realIsNaN(&a) or runtime.realIsNaN(&c) or runtime.realIsNaN(&d)) {
        runtime.realSetNaN(quotient_real);
        runtime.realSetNaN(quotient_imag);
        return;
    }

    if (runtime.realIsInfinite(&c) or runtime.realIsInfinite(&d)) {
        runtime.realSetZero(quotient_real);
        runtime.realSetZero(quotient_imag);
        return;
    }

    runtime.realMultiply(&c, &c, &denom, real_context); // c²
    runtime.realFMA(&d, &d, &denom, &denom, real_context); // c² + d²

    // real part
    runtime.realMultiply(&a, &c, quotient_real, real_context); // numer = a*c
    runtime.realDivide(quotient_real, &denom, quotient_real, real_context); // realPart = (a*c) / (c² + d²)

    // imaginary part
    runtime.realChangeSign(&a); // a = -a
    runtime.realMultiply(&a, &d, quotient_imag, real_context); // numer = -a*d
    runtime.realDivide(quotient_imag, &denom, quotient_imag, real_context); // imagPart = -(a*d) / (c² + d²)
}

pub export fn divComplexReal(
    numer_real: *const runtime.real_t,
    numer_imag: *const runtime.real_t,
    denom: *const runtime.real_t,
    quotient_real: *runtime.real_t,
    quotient_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realDivide(numer_real, denom, quotient_real, real_context);
    runtime.realDivide(numer_imag, denom, quotient_imag, real_context);
}

// ===== long integer / ... =====

pub export fn divLonILonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y[0]);

    if (x[0]._mp_size == 0) { // longIntegerIsZero(x)
        runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));
        support.convertLongIntegerToReal34(&x[0], runtime.registerReal34Ptr(REGISTER_X));
        runtime.reallocateRegister(REGISTER_Y, runtime.dtReal34, 0, @intCast(runtime.amNone));
        support.convertLongIntegerToReal34(&y[0], runtime.registerReal34Ptr(REGISTER_Y));
        divRealReal();
    } else {
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y[0], &x[0]);

        if (remainder[0]._mp_size == 0) { // longIntegerIsZero(remainder)
            runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], REGISTER_X);
        } else {
            var x_ic: runtime.real_t = undefined;
            var y_ic: runtime.real_t = undefined;

            runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y_ic, &runtime.ctxtReal39);
            runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x_ic, &runtime.ctxtReal39);
            runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));

            runtime.realDivide(&y_ic, &x_ic, &x_ic, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_ic, REGISTER_X);
        }

        runtime.__gmpz_clear(&quotient[0]);
        runtime.__gmpz_clear(&remainder[0]);
    }

    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
}

pub export fn divLonIShoI() callconv(.c) void {
    var a: runtime.longInteger_t = undefined;
    var c: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &a[0]);
    support.convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &c[0]);

    if (c[0]._mp_size == 0) {
        divisionDomainError("In function divLonIShoI:", "cannot divide a long integer by 0");
    } else {
        runtime.__gmpz_tdiv_qr(&a[0], &c[0], &a[0], &c[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&a[0], REGISTER_X);
    }

    runtime.__gmpz_clear(&a[0]);
    runtime.__gmpz_clear(&c[0]);
}

pub export fn divShoILonI() callconv(.c) void {
    var a: runtime.longInteger_t = undefined;
    var c: runtime.longInteger_t = undefined;

    support.convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &a[0]);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &c[0]);

    if (c[0]._mp_size == 0) {
        divisionDomainError("In function divShoILonI:", "cannot divide a short integer by 0");
    } else {
        runtime.__gmpz_tdiv_qr(&a[0], &c[0], &a[0], &c[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&a[0], REGISTER_X);
    }

    runtime.__gmpz_clear(&a[0]);
    runtime.__gmpz_clear(&c[0]);
}

pub export fn divLonIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);

    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.realIsZero(&y)) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
            } else {
                divisionDomainError("In function divLonIReal:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (!runtime.realIsNegative(&y)) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divLonIReal:", "cannot divide a long integer by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
        runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    }
}

pub export fn divRealLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));

    if (runtime.realIsZero(&x)) {
        if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y))) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
            } else {
                divisionDomainError("In function divRealLonI:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divRealLonI:", "cannot divide a real34 by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
        const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);

        if (y_angular_mode == runtime.amNone) {
            runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
            runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
        }
    }
}

pub export fn divLonICplx() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &x_imag);

    divRealComplex(&y, &x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x_real, &x_imag, REGISTER_X);
}

pub export fn divCplxLonI() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &a);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_Y), &b);
    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &c, &runtime.ctxtReal39);

    runtime.realDivide(&a, &c, &a, &runtime.ctxtReal39);
    runtime.realDivide(&b, &c, &b, &runtime.ctxtReal39);

    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.convertComplexToResultRegister(&a, &b, REGISTER_X);
}

// ===== time / ... =====

pub export fn divTimeLonI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));

    if (runtime.realIsZero(&x)) {
        if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y))) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(runtime.const_NaN, runtime.registerReal34Ptr(REGISTER_X));
            } else {
                divisionDomainError("In function divTimeLonI:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divTimeLonI:", "cannot divide time by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);

        runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
        runtime.realToReal34(&x, runtime.registerReal34Ptr(REGISTER_X));
    }
}

pub export fn divLonITime() callconv(.c) void {
    runtime.convertTimeRegisterToReal34Register(REGISTER_X, REGISTER_X);
    divLonIReal();
}

pub export fn divTimeShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));

    if (runtime.realIsZero(&x)) {
        if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y))) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
            } else {
                divisionDomainError("In function divTimeShoI:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divTimeShoI:", "cannot divide time by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);

        runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    }
}

pub export fn divShoITime() callconv(.c) void {
    runtime.convertTimeRegisterToReal34Register(REGISTER_X, REGISTER_X);
    divShoIReal();
}

pub export fn divTimeReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y)) and runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));
            runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
        } else {
            divisionDomainError("In function divTimeReal:", "cannot divide 0 by 0");
        }
    } else if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));
            runtime.realToReal34(
                if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                runtime.registerReal34Ptr(REGISTER_X),
            );
        } else {
            divisionDomainError("In function divTimeReal:", "cannot divide a real34 by 0");
        }
    } else {
        var x: runtime.real34_t = undefined;

        x = runtime.registerReal34Ptr(REGISTER_X).*;
        const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

        if (x_angular_mode == runtime.amNone) { // time / real
            runtime.reallocateRegister(REGISTER_X, runtime.dtTime, 0, @intCast(runtime.amNone));
            runtime.real34Divide(runtime.registerReal34Ptr(REGISTER_Y), &x, runtime.registerReal34Ptr(REGISTER_X));
        } else { // time / angle
            divError();
        }
    }
}

pub export fn divRealTime() callconv(.c) void {
    runtime.convertTimeRegisterToReal34Register(REGISTER_X, REGISTER_X);
    divRealReal();
}

pub export fn divTimeTime() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y)) and runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
        } else {
            divisionDomainError("In function divTimeTime:", "cannot divide 0 by 0");
        }
    } else if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                runtime.registerReal34Ptr(REGISTER_X),
            );
        } else {
            divisionDomainError("In function divTimeTime:", "cannot divide time by 0");
        }
    } else {
        var b: runtime.real34_t = undefined;

        b = runtime.registerReal34Ptr(REGISTER_X).*;
        runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));
        runtime.real34Divide(runtime.registerReal34Ptr(REGISTER_Y), &b, runtime.registerReal34Ptr(REGISTER_X));
        runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
    }
}

// ===== real34 matrix / ... =====

pub export fn divRemaLonI() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (!runtime.getSystemFlag(support.FLAG_SPCRES) and runtime.realIsZero(&x)) {
        divisionDomainError("In function divRemaLonI:", "cannot divide by 0");
    } else {
        runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
        support._divideRealMatrix(&matrix, &x, &res, &runtime.ctxtReal39);
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    }
}

fn realMatrixHasZeroElement(matrix: *const runtime.real34Matrix_t) bool {
    const rows: u16 = matrix.header.matrixRows;
    const cols: u16 = matrix.header.matrixColumns;
    const elements: [*]const runtime.real34_t = matrix.matrixElements;
    var div_zero_occurs = false;

    var i: i32 = 0;
    while (i < @as(i32, cols) * @as(i32, rows)) : (i += 1) {
        if (runtime.real34IsZero(&elements[@intCast(i)])) {
            div_zero_occurs = true;
        }
    }

    return div_zero_occurs;
}

pub export fn divLonIRema() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var div_zero_occurs = false;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    if (!runtime.getSystemFlag(support.FLAG_SPCRES)) {
        div_zero_occurs = realMatrixHasZeroElement(&matrix);
    }

    if (div_zero_occurs) {
        divisionDomainError("In function divLonIRema:", "cannot divide by 0");
    } else {
        support._divideByRealMatrix(&y, &matrix, &res, &runtime.ctxtReal39);
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    }
}

pub export fn divRemaRema() callconv(.c) void {
    var y: runtime.real34Matrix_t = undefined;
    var x: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(REGISTER_Y, &y);
    runtime.linkToRealMatrixRegister(REGISTER_X, &x);

    if (y.header.matrixColumns != x.header.matrixRows or y.header.matrixColumns != x.header.matrixColumns or x.header.matrixRows != x.header.matrixColumns) {
        runtime.displayCalcErrorMessage(support.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        var message_buffer: [196]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot divide {d}" ++ support.STD_CROSS ++ "{d}-matrix and {d}" ++ support.STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns), @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns) },
        );
        runtime.moreInfoOnError("In function divRemaRema:", message, null, null);
    } else {
        support.divideRealMatrices(&y, &x, &res);
        if (res.matrixElements != null) {
            runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
            runtime.realMatrixFree(&res);
        } else {
            runtime.displayCalcErrorMessage(support.ERROR_SINGULAR_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            runtime.moreInfoOnError("In function divRemaRema:", "cannot divide by a singular matrix", null, null);
        }
    }
}

pub export fn divRemaCxma() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
    divCxmaCxma();
}

pub export fn divRemaShoI() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    if (!runtime.getSystemFlag(support.FLAG_SPCRES) and runtime.realIsZero(&x)) {
        divisionDomainError("In function divRemaShoI:", "cannot divide by 0");
    } else {
        runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
        support._divideRealMatrix(&matrix, &x, &res, &runtime.ctxtReal39);
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    }
}

pub export fn divShoIRema() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var y: runtime.real_t = undefined;
    var div_zero_occurs = false;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    if (!runtime.getSystemFlag(support.FLAG_SPCRES)) {
        div_zero_occurs = realMatrixHasZeroElement(&matrix);
    }

    if (div_zero_occurs) {
        divisionDomainError("In function divShoIRema:", "cannot divide by 0");
    } else {
        support._divideByRealMatrix(&y, &matrix, &res, &runtime.ctxtReal39);
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    }
}

pub export fn divRemaReal() callconv(.c) void {
    if (!runtime.getSystemFlag(support.FLAG_SPCRES) and runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        divisionDomainError("In function divRemaReal:", "cannot divide by 0");
    } else if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
        var matrix: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(REGISTER_Y, &matrix);
        support.divideRealMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), &matrix);
        runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
    } else {
        runtime.elementwiseRemaReal(&divRealReal);
    }
}

pub export fn divRealRema() callconv(.c) void {
    var matrix: runtime.real34Matrix_t = undefined;
    var res: runtime.real34Matrix_t = undefined;
    var div_zero_occurs = false;

    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    if (!runtime.getSystemFlag(support.FLAG_SPCRES)) {
        div_zero_occurs = realMatrixHasZeroElement(&matrix);
    }

    if (div_zero_occurs) {
        divisionDomainError("In function divRealRema:", "cannot divide by 0");
    } else if (runtime.getRegisterAngularMode(REGISTER_Y) == runtime.amNone) {
        support.divideByRealMatrix(runtime.registerReal34Ptr(REGISTER_Y), &matrix, &res);
        runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        runtime.realMatrixFree(&res);
    } else {
        support.elementwiseRealRema(&divRealReal);
    }
}

pub export fn divRemaCplx() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
    divCxmaCplx();
}

pub export fn divCplxRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_X, REGISTER_X);
    divCplxCxma();
}

// ===== complex34 matrix / ... =====

pub export fn divCxmaLonI() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
    support._divideComplexMatrix(&matrix, &x, runtime.z47_math_wrappers_const_0(), &res, &runtime.ctxtReal39);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
    runtime.complexMatrixFree(&res);
}

pub export fn divLonICxma() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;
    var y: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
    support._divideByComplexMatrix(&y, runtime.z47_math_wrappers_const_0(), &matrix, &res, &runtime.ctxtReal39);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
    runtime.complexMatrixFree(&res);
}

pub export fn divCxmaRema() callconv(.c) void {
    runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_X, REGISTER_X);
    divCxmaCxma();
}

pub export fn divCxmaCxma() callconv(.c) void {
    var y: runtime.complex34Matrix_t = undefined;
    var x: runtime.complex34Matrix_t = undefined;
    var res: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_Y, &y);
    runtime.linkToComplexMatrixRegister(REGISTER_X, &x);

    if (y.header.matrixColumns != x.header.matrixRows or y.header.matrixColumns != x.header.matrixColumns or x.header.matrixRows != x.header.matrixColumns) {
        runtime.displayCalcErrorMessage(support.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        var message_buffer: [196]u8 = undefined;
        const message = bufPrintZ(
            &message_buffer,
            "cannot divide {d}" ++ support.STD_CROSS ++ "{d}-matrix and {d}" ++ support.STD_CROSS ++ "{d}-matrix",
            .{ @as(u16, y.header.matrixRows), @as(u16, y.header.matrixColumns), @as(u16, x.header.matrixRows), @as(u16, x.header.matrixColumns) },
        );
        runtime.moreInfoOnError("In function divCxmaCxma:", message, null, null);
    } else {
        support.divideComplexMatrices(&y, &x, &res);
        if (res.matrixElements != null) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
            runtime.complexMatrixFree(&res);
        } else {
            runtime.displayCalcErrorMessage(support.ERROR_SINGULAR_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            runtime.moreInfoOnError("In function divCxmaCxma:", "cannot divide by a singular matrix", null, null);
        }
    }
}

pub export fn divCxmaShoI() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    divCxmaReal();
}

pub export fn divShoICxma() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    divRealCxma();
}

pub export fn divCxmaReal() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
        var matrix: runtime.complex34Matrix_t = undefined;
        var zero34: runtime.real34_t = undefined;

        _ = support.decQuadZero(&zero34);
        runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
        support.divideComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), &zero34, &matrix);
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
    } else {
        support.elementwiseCxmaReal(&divCplxReal);
    }
}

pub export fn divRealCxma() callconv(.c) void {
    if (runtime.getRegisterAngularMode(REGISTER_Y) == runtime.amNone) {
        var matrix: runtime.complex34Matrix_t = undefined;
        var zero34: runtime.real34_t = undefined;

        _ = support.decQuadZero(&zero34);
        runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
        support.divideByComplexMatrix(runtime.registerReal34Ptr(REGISTER_Y), &zero34, &matrix, &matrix);
    } else {
        support.elementwiseRealCxma(&divRealCplx);
    }
}

pub export fn divCxmaCplx() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_Y, &matrix);
    support.divideComplexMatrix(&matrix, runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_X), &matrix);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
}

pub export fn divCplxCxma() callconv(.c) void {
    var matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(REGISTER_X, &matrix);
    support.divideByComplexMatrix(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerImag34Ptr(REGISTER_Y), &matrix, &matrix);
}

// ===== short integer / ... =====

pub export fn divShoIShoI() callconv(.c) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);
    if (value == 0) {
        divisionDomainError("In function divShoIShoI:", "cannot divide a short integer by 0");
    } else {
        const x_data = runtime.registerShortIntegerPtr(REGISTER_X);
        const y_data = runtime.registerShortIntegerPtr(REGISTER_Y);
        x_data.* = runtime.WP34S_intDivide(y_data.*, x_data.*);
        runtime.setRegisterTag(REGISTER_X, runtime.getRegisterShortIntegerBase(REGISTER_Y));
    }
}

pub export fn divShoIReal() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);

    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.realIsZero(&y)) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
            } else {
                divisionDomainError("In function divShoIReal:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (!runtime.realIsNegative(&y)) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divShoIReal:", "cannot divide a short integer by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);
        runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
    }
}

pub export fn divRealShoI() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.amNone));

    if (runtime.realIsZero(&x)) {
        if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y))) {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
            } else {
                divisionDomainError("In function divRealShoI:", "cannot divide 0 by 0");
            }
        } else {
            if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
                runtime.realToReal34(
                    if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                    runtime.registerReal34Ptr(REGISTER_X),
                );
            } else {
                divisionDomainError("In function divRealShoI:", "cannot divide a real34 by 0");
            }
        }
    } else {
        runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
        const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);

        if (y_angular_mode == runtime.amNone) {
            runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&y, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
            runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
        }
    }
}

pub export fn divShoICplx() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    runtime.convertShortIntegerRegisterToReal(REGISTER_Y, &y, &runtime.ctxtReal39);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &x_imag);

    divRealComplex(&y, &x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x_real, &x_imag, REGISTER_X);
}

pub export fn divCplxShoI() callconv(.c) void {
    support.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    runtime.real34Divide(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_Y)); // real part
    runtime.real34Divide(runtime.registerImag34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_Y)); // imaginary part
    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.registerComplex34Ptr(REGISTER_X).* = runtime.registerComplex34Ptr(REGISTER_Y).*;
}

// ===== real34 / ... =====

pub export fn divRealReal() callconv(.c) void {
    if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y)) and runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.convertRealToReal34ResultRegister(runtime.const_NaN, REGISTER_X);
        } else {
            divisionDomainError("In function divRealReal:", "cannot divide 0 by 0");
        }
    } else if (runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X))) {
        if (runtime.getSystemFlag(support.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (support.real34IsPositive(runtime.registerReal34Ptr(REGISTER_Y))) runtime.z47_math_wrappers_const_plus_infinity() else runtime.z47_math_wrappers_const_minus_infinity(),
                runtime.registerReal34Ptr(REGISTER_X),
            );
        } else {
            divisionDomainError("In function divRealReal:", "cannot divide a real34 by 0");
        }
    } else {
        var y: runtime.real_t = undefined;
        var x: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(REGISTER_Y);
        const x_angular_mode = runtime.getRegisterAngularMode(REGISTER_X);

        if (y_angular_mode == runtime.amNone) { // real / (real or angle)
            runtime.real34Divide(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_X));
            runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
        } else {
            runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
            runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x);

            if (y_angular_mode != runtime.amNone and x_angular_mode != runtime.amNone) { // angle / angle
                runtime.convertAngleFromTo(&x, x_angular_mode, y_angular_mode, &runtime.ctxtReal39);
                runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
                runtime.setRegisterAngularMode(REGISTER_X, runtime.amNone);
            } else { // angle / real
                runtime.realDivide(&y, &x, &x, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(&x, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x, REGISTER_X);
                runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
            }
        }
    }
}

pub export fn divRealCplx() callconv(.c) void {
    var y: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &x_imag);

    divRealComplex(&y, &x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x_real, &x_imag, REGISTER_X);
}

pub export fn divCplxReal() callconv(.c) void {
    runtime.real34Divide(runtime.registerReal34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerReal34Ptr(REGISTER_Y)); // real part
    runtime.real34Divide(runtime.registerImag34Ptr(REGISTER_Y), runtime.registerReal34Ptr(REGISTER_X), runtime.registerImag34Ptr(REGISTER_Y)); // imaginary part
    runtime.reallocateRegister(REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.registerComplex34Ptr(REGISTER_X).* = runtime.registerComplex34Ptr(REGISTER_Y).*;
}

// ===== complex34 / ... =====

pub export fn divCplxCplx() callconv(.c) void {
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_Y), &y_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_Y), &y_imag);
    runtime.real34ToReal(runtime.registerReal34Ptr(REGISTER_X), &x_real);
    runtime.real34ToReal(runtime.registerImag34Ptr(REGISTER_X), &x_imag);

    divComplexComplex(&y_real, &y_imag, &x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x_real, &x_imag, REGISTER_X);
}
