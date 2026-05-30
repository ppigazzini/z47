const erf_owned = @import("math_special_function_erf_owned.zig");
const factorial_owned = @import("math_special_function_factorial_owned.zig");
const fibonacci_owned = @import("math_special_function_fibonacci_owned.zig");
const ixyz_owned = @import("math_special_function_ixyz_owned.zig");

pub fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    erf_owned.fnErf(unused_but_mandatory_parameter);
}

pub fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    erf_owned.fnErfc(unused_but_mandatory_parameter);
}

pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    factorial_owned.fnFactorial(unused_but_mandatory_parameter);
}

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    fibonacci_owned.fnFib(unused_but_mandatory_parameter);
}

pub fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    ixyz_owned.fnIxyz(unused_but_mandatory_parameter);
}
