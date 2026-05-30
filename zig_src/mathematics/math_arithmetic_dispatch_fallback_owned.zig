const runtime = @import("math_command_wrappers_runtime.zig");

pub fn fallbackAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnAdd(unused_but_mandatory_parameter);
}

pub fn fallbackSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnSubtract(unused_but_mandatory_parameter);
}

pub fn fallbackMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnMultiply(unused_but_mandatory_parameter);
}

pub fn fallbackDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnDivide(unused_but_mandatory_parameter);
}

pub fn fallbackIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnIDiv(unused_but_mandatory_parameter);
}

pub fn fallbackIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.retained.z47_math_wrappers_retained_fnIDivR(unused_but_mandatory_parameter);
}