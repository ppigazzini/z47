const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const compare_less_than_retained = runtime.retained.z47_math_wrappers_retained_fnXLessThan;
const compare_less_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXLessEqual;
const compare_greater_than_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterThan;
const compare_greater_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterEqual;
const compare_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXEqualsTo;
const compare_not_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXNotEqual;
const compare_almost_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXAlmostEqual;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

pub const Mode = enum(u8) {
    less_than = 0x1,
    equal = 0x2,
    less_equal = 0x3,
    greater_than = 0x4,
    not_equal = 0x5,
    greater_equal = 0x6,
};

pub fn isOwnedCompareRegister(regist: runtime.calcRegister_t) bool {
    return regist == runtime.REGISTER_X or regist == runtime.REGISTER_Y or regist == runtime.REGISTER_Z or regist == runtime.REGISTER_T;
}

pub fn isOwnedAlmostEqualIntegerType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or data_type == runtime.dtShortInteger;
}

fn isOwnedCompareType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or data_type == runtime.dtShortInteger or data_type == runtime.dtReal34 or data_type == runtime.dtComplex34;
}

fn compareTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const message = bufPrintZ(&message_buffer, "cannot convert Register {} from {s}", .{ regist, type_name }) catch "cannot convert Register";

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
            runtime.convertLongIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
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
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_less_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .less_than);
}

pub fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_less_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .less_equal);
}

pub fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_greater_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .greater_than);
}

pub fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_greater_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .greater_equal);
}

pub fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .equal);
}

pub fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        compare_not_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .not_equal);
}

pub fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);

    if (!isOwnedCompareRegister(regist) or !isOwnedAlmostEqualIntegerType(x_type) or !isOwnedAlmostEqualIntegerType(regist_type)) {
        compare_almost_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, .equal);
}