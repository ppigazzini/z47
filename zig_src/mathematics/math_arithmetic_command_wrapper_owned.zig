const arithmetic_dispatch_command_owned = @import("math_arithmetic_dispatch_command_owned.zig");
const atan2_command_owned = @import("math_atan2_command_owned.zig");
const double_width_command_owned = @import("math_double_width_command_owned.zig");
const percent_command_owned = @import("math_percent_command_owned.zig");

pub fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    atan2_command_owned.atan2(unused_but_mandatory_parameter);
}

pub fn fnPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.percent(unused_but_mandatory_parameter);
}

pub fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnAdd(unused_but_mandatory_parameter);
}

pub fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnSubtract(unused_but_mandatory_parameter);
}

pub fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDivR(unused_but_mandatory_parameter);
}

pub fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblMultiply(unused_but_mandatory_parameter);
}

pub fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivide(unused_but_mandatory_parameter);
}

pub fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivideRemainder(unused_but_mandatory_parameter);
}
