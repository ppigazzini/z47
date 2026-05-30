const runtime = @import("math_command_wrappers_runtime.zig");
const powlog_log_owned = @import("math_powlog_log_owned.zig");
const powlog_power_owned = @import("math_powlog_power_owned.zig");

extern fn realExp(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void;

pub fn fn2Pow(unused_but_mandatory_parameter: u16) void {
    powlog_power_owned.fn2Pow(unused_but_mandatory_parameter);
}

pub fn fn10Pow(unused_but_mandatory_parameter: u16) void {
    powlog_power_owned.fn10Pow(unused_but_mandatory_parameter);
}

pub fn fnLog10(unused_but_mandatory_parameter: u16) void {
    powlog_log_owned.fnLog10(unused_but_mandatory_parameter);
}

pub fn fnLog2(unused_but_mandatory_parameter: u16) void {
    powlog_log_owned.fnLog2(unused_but_mandatory_parameter);
}