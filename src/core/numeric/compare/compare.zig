const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const legacy = runtime.legacy;

pub const Mode = enum(u8) {
    less_than = 0x1,
    equal = 0x2,
    less_equal = 0x3,
    greater_than = 0x4,
    not_equal = 0x5,
    greater_equal = 0x6,
};

fn registFromParameter(parameter: u16) runtime.calcRegister_t {
    return @intCast(parameter);
}

fn isOwnedStackRegister(regist: runtime.calcRegister_t) bool {
    return switch (regist) {
        runtime.REGISTER_X,
        runtime.REGISTER_Y,
        runtime.REGISTER_Z,
        runtime.REGISTER_T,
        => true,
        else => false,
    };
}

fn callLegacyCompare(mode: Mode, parameter: u16) void {
    switch (mode) {
        .less_than => legacy.fnXLessThan(parameter),
        .equal => legacy.fnXEqualsTo(parameter),
        .less_equal => legacy.fnXLessEqual(parameter),
        .greater_than => legacy.fnXGreaterThan(parameter),
        .not_equal => legacy.fnXNotEqual(parameter),
        .greater_equal => legacy.fnXGreaterEqual(parameter),
    }
}

fn runCompare(parameter: u16, mode: Mode) void {
    const regist = registFromParameter(parameter);
    // The owned fast path only covers integer/real/complex scalars. Anything
    // else (e.g. dtTime, which the legacy compareRegisters normalizes by
    // dividing seconds by const_3600) must defer to the legacy machinery.
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_r = runtime.getRegisterDataType(regist);
    // An integer against an integer is compared exactly, through the long-integer
    // path. Routing it through a real conversion decides two values equal as soon
    // as they agree to the context's digit count, and a long integer carries far
    // more digits than that.
    if (!isOwnedStackRegister(regist) or
        !isOwnedCompareType(type_x) or
        !isOwnedCompareType(type_r) or
        (isOwnedAlmostEqualIntegerType(type_x) and isOwnedAlmostEqualIntegerType(type_r)))
    {
        callLegacyCompare(mode, parameter);
        return;
    }
    compareScalarRegister(regist, mode);
}

fn isOwnedAlmostEqualIntegerType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or data_type == runtime.dtShortInteger;
}

fn isOwnedCompareType(data_type: u32) bool {
    return switch (data_type) {
        runtime.dtLongInteger,
        runtime.dtShortInteger,
        runtime.dtReal34,
        runtime.dtComplex34,
        => true,
        else => false,
    };
}

fn compareTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot convert Register {} from {s}", .{ regist, type_name }) catch "cannot convert Register";

    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function badTypeError:", message, null, null);
}

fn compareResultToTemporaryInformation(result: i32, mode: Mode) void {
    const mode_bits = @intFromEnum(mode);

    if (result < 0) {
        runtime.setTemporaryInformation((mode_bits & @intFromEnum(Mode.less_than)) != 0);
    } else if (result > 0) {
        runtime.setTemporaryInformation((mode_bits & @intFromEnum(Mode.greater_than)) != 0);
    } else {
        runtime.setTemporaryInformation((mode_bits & @intFromEnum(Mode.equal)) != 0);
    }
}

fn compareRealsToTemporaryInformation(left: *runtime.real_t, right: *runtime.real_t, mode: Mode) void {
    if (runtime.realIsNaN(left) or runtime.realIsNaN(right)) {
        runtime.setTemporaryInformation(false);
        return;
    }

    const result: i32 = if (runtime.realCompareEqual(left, right))
        0
    else if (runtime.realCompareLessThan(left, right))
        -1
    else
        1;

    compareResultToTemporaryInformation(result, mode);
}

fn compareComplexToTemporaryInformation(
    left_real: *runtime.real_t,
    left_imag: *runtime.real_t,
    right_real: *runtime.real_t,
    right_imag: *runtime.real_t,
    mode: Mode,
    regist: runtime.calcRegister_t,
) void {
    if (mode != .equal and mode != .not_equal) {
        compareTypeError(regist);
        return;
    }

    compareRealsToTemporaryInformation(left_real, right_real, mode);
    if (runtime.temporaryInformation != runtime.TI_FALSE) {
        compareRealsToTemporaryInformation(left_imag, right_imag, mode);
    }
}

fn getCompareInput(
    regist: runtime.calcRegister_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, real, imag);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, real)) {
                return false;
            }
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtLongInteger => {
            // 75 digits, as getRegisterAsComplexOrAnyRealQuiet uses: a long integer
            // mixed with a real must not lose digits on the way in.
            runtime.convertLongIntegerRegisterToReal(regist, real, &runtime.ctxtReal75);
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtShortInteger => {
            // 34 digits, as getRegisterAsComplexOrAnyRealQuiet uses.
            runtime.convertShortIntegerRegisterToReal(regist, real, &runtime.ctxtReal34);
            runtime.realSetZero(imag);
            return true;
        },
        else => return false,
    }
}

pub fn compareScalarRegister(regist: runtime.calcRegister_t, mode: Mode) void {
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var regist_real: runtime.real_t = undefined;
    var regist_imag: runtime.real_t = undefined;
    var is_complex = false;

    if (!isOwnedCompareType(x_type) or !isOwnedCompareType(regist_type)) {
        compareTypeError(regist);
        return;
    }

    if (!getCompareInput(runtime.REGISTER_X, &x_real, &x_imag, &is_complex) or !getCompareInput(regist, &regist_real, &regist_imag, &is_complex)) {
        compareTypeError(regist);
        return;
    }

    if (is_complex) {
        compareComplexToTemporaryInformation(&x_real, &x_imag, &regist_real, &regist_imag, mode, regist);
    } else {
        compareRealsToTemporaryInformation(&x_real, &regist_real, mode);
    }
}

pub fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .less_than);
}

pub fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .less_equal);
}

pub fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .greater_than);
}

pub fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .greater_equal);
}

pub fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .equal);
}

pub fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runCompare(unused_but_mandatory_parameter, .not_equal);
}

pub fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    // x~? has no owned fast path. Every type pair it accepts needs either the
    // rounding snapshot of almostEqualScalar/almostEqualMatrix or, for an
    // integer against an integer, the exact long-integer comparison of
    // compareRegisters. Rounding an integer pair into a real instead would
    // call two values equal as soon as they agree to the context's digit
    // count, and a long integer carries far more digits than that.
    legacy.fnXAlmostEqual(unused_but_mandatory_parameter);
}
