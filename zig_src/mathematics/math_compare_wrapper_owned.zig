const compare_owned = @import("math_compare_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const compare_less_than_retained = runtime.retained.z47_math_wrappers_retained_fnXLessThan;
const compare_less_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXLessEqual;
const compare_greater_than_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterThan;
const compare_greater_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterEqual;
const compare_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXEqualsTo;
const compare_not_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXNotEqual;
const compare_almost_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXAlmostEqual;

pub fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_less_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .less_than);
}

pub fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_less_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .less_equal);
}

pub fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_greater_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .greater_than);
}

pub fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_greater_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .greater_equal);
}

pub fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .equal);
}

pub fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_not_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .not_equal);
}

pub fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);

    if (!compare_owned.isOwnedCompareRegister(regist) or !compare_owned.isOwnedAlmostEqualIntegerType(x_type) or !compare_owned.isOwnedAlmostEqualIntegerType(regist_type)) {
        compare_almost_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .equal);
}
