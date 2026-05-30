const check_value_owned = @import("math_check_value_owned.zig");
const get_type_owned = @import("math_get_type_owned.zig");

pub fn fnCheckInteger(mode: u16) callconv(.c) void {
    check_value_owned.checkInteger(mode);
}

pub fn fnCheckType(type_: u16) callconv(.c) void {
    check_value_owned.checkType(type_);
}

pub fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkReal();
}

pub fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNumber();
}

pub fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkAngle();
}

pub fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrix();
}

pub fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrixSquare();
}

pub fn fnCheckForZero(mode: u16) callconv(.c) void {
    check_value_owned.checkForZero(mode);
}

pub fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(2);
}

pub fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(3);
}

pub fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNaN();
}

pub fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkInfinite();
}

pub fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkSpecial();
}

pub fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkPlusZero();
}

pub fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMinusZero();
}

pub fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    get_type_owned.getType();
}
