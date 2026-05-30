const decomp_owned = @import("math_scalar_integer_decomp_command_owned.zig");
const precision_owned = @import("math_scalar_integer_precision_owned.zig");
const round_owned = @import("math_scalar_integer_round_command_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnUlp(unused_but_mandatory_parameter);
}

pub fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnMant(unused_but_mandatory_parameter);
}

pub fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    precision_owned.fnRoundi(unused_but_mandatory_parameter);
}

pub fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    round_owned.round(unused_but_mandatory_parameter);
}

pub fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    decomp_owned.decomp(unused_but_mandatory_parameter);
}
