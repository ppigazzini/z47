const factorial_owned = @import("math_special_function_factorial_owned.zig");
const fibonacci_owned = @import("math_special_function_fibonacci_owned.zig");
const ixyz_owned = @import("math_special_function_ixyz_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn erfReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn erfcReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erfc(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&erfReal, null);
}

pub fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&erfcReal, null);
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
