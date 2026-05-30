const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

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

pub fn linpol() callconv(.c) void {
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
