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
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
    runtime.moreInfoOnError("In function badTypeError:", message, null, null);
}

fn compareResultToTemporaryInformation(result: i32, mode: Mode) void {
    const mode_bits = @backingInt(mode);

    if (result < 0) {
        runtime.setTemporaryInformation((mode_bits & @backingInt(Mode.less_than)) != 0);
    } else if (result > 0) {
        runtime.setTemporaryInformation((mode_bits & @backingInt(Mode.greater_than)) != 0);
    } else {
        runtime.setTemporaryInformation((mode_bits & @backingInt(Mode.equal)) != 0);
    }
}

// Ordered comparison and equality are false for NaN; inequality is true.
fn compareRealsToTemporaryInformation(left: *const runtime.real_t, right: *const runtime.real_t, mode: Mode) void {
    if (runtime.realIsNaN(left) or runtime.realIsNaN(right)) {
        runtime.setTemporaryInformation(mode == .not_equal);
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

// Complex numbers do not have a total ordering; only == and != are supported.
fn compareComplexToTemporaryInformation(
    left: *const runtime.cplx_t,
    right: *const runtime.cplx_t,
    mode: Mode,
    regist: runtime.calcRegister_t,
) void {
    if (mode != .equal and mode != .not_equal) {
        compareTypeError(regist);
        return;
    }

    const equal = runtime.realCompareEqual(&left.Real, &right.Real) and runtime.realCompareEqual(&left.Imag, &right.Imag);
    runtime.setTemporaryInformation(if (mode == .equal) equal else !equal);
}

fn getCompareInput(
    regist: runtime.calcRegister_t,
    z: *runtime.cplx_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, z);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, &z.Real)) {
                return false;
            }
            runtime.realSetZero(&z.Imag);
            return true;
        },
        runtime.dtLongInteger => {
            // 75 digits, as getRegisterAsComplexOrAnyRealQuiet uses: a long integer
            // mixed with a real must not lose digits on the way in.
            runtime.convertLongIntegerRegisterToReal(regist, &z.Real, &runtime.ctxtReal75);
            runtime.realSetZero(&z.Imag);
            return true;
        },
        runtime.dtShortInteger => {
            // 34 digits, as getRegisterAsComplexOrAnyRealQuiet uses.
            runtime.convertShortIntegerRegisterToReal(regist, &z.Real, &runtime.ctxtReal34);
            runtime.realSetZero(&z.Imag);
            return true;
        },
        else => return false,
    }
}

// A tagged real is converted to the current angular mode before it is
// compared; a conversion from or to radians runs at 75 digits.
fn normaliseRegisterRealForComparison(regist: runtime.calcRegister_t, value: *runtime.real_t) void {
    if (runtime.getRegisterDataType(regist) != runtime.dtReal34) {
        return;
    }

    const mode = runtime.getRegisterAngularMode(regist);
    if (mode != runtime.amNone and mode != runtime.currentAngularMode) {
        const context = if (mode == runtime.amRadian or runtime.currentAngularMode == runtime.amRadian) &runtime.ctxtReal75 else &runtime.ctxtReal39;
        runtime.convertAngleFromTo(value, mode, runtime.currentAngularMode, context);
    }
}

// A Real34 against a long integer is compared exactly, without rounding
// either into the other's digits, unless the real carries an angle in a unit
// other than the current one. True with the signed comparison when that path
// applies.
fn compareMixedRealLong(regist1: runtime.calcRegister_t, regist2: runtime.calcRegister_t, comparison: *i32) bool {
    const type1 = runtime.getRegisterDataType(regist1);
    const type2 = runtime.getRegisterDataType(regist2);
    const real_register = if (type1 == runtime.dtReal34 and type2 == runtime.dtLongInteger)
        regist1
    else if (type1 == runtime.dtLongInteger and type2 == runtime.dtReal34)
        regist2
    else
        return false;

    const mode = runtime.getRegisterAngularMode(real_register);
    if (mode != runtime.amNone and mode != runtime.currentAngularMode) {
        return false;
    }
    return runtime.compareFiniteReal34LongIntegerRegisters(regist1, regist2, comparison);
}

pub fn compareScalarRegister(regist: runtime.calcRegister_t, mode: Mode) void {
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);
    var x: runtime.cplx_t = undefined;
    var r: runtime.cplx_t = undefined;
    var is_complex = false;
    var comparison: i32 = undefined;

    if (!isOwnedCompareType(x_type) or !isOwnedCompareType(regist_type)) {
        compareTypeError(regist);
        return;
    }

    if (compareMixedRealLong(runtime.REGISTER_X, regist, &comparison)) {
        compareResultToTemporaryInformation(comparison, mode);
        return;
    }

    if (!getCompareInput(runtime.REGISTER_X, &x, &is_complex) or !getCompareInput(regist, &r, &is_complex)) {
        compareTypeError(regist);
        return;
    }

    normaliseRegisterRealForComparison(runtime.REGISTER_X, &x.Real);
    normaliseRegisterRealForComparison(regist, &r.Real);

    if (is_complex) {
        compareComplexToTemporaryInformation(&x, &r, mode, regist);
    } else {
        compareRealsToTemporaryInformation(&x.Real, &r.Real, mode);
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
