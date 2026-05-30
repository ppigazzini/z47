const projection_owned = @import("math_projection_owned.zig");

pub fn fnRealPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.realPart();
}

pub fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.imaginaryPart();
}

pub fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.arg();
}

pub fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.magnitude();
}

pub fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.conjugate();
}

pub fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.swapRealImaginary();
}
