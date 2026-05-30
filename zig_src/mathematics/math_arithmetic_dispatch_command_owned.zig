const runtime = @import("math_command_wrappers_runtime.zig");
const arithmetic_dispatch_fallback_owned = @import("math_arithmetic_dispatch_fallback_owned.zig");
const arithmetic_selectors = @import("math_arithmetic_dispatch_selectors_owned.zig");
const arithmetic_scalar = @import("math_arithmetic_dispatch_scalar_owned.zig");
const arithmetic_integer = @import("math_arithmetic_dispatch_integer_owned.zig");

pub fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerAdd()) {
        return;
    }

    if (arithmetic_scalar.tryScalarAdd()) {
        return;
    }

    if (arithmetic_selectors.tryRemainingAdd()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackAdd(unused_but_mandatory_parameter);
}

pub fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerSubtract()) {
        return;
    }

    if (arithmetic_scalar.tryScalarSubtract()) {
        return;
    }

    if (arithmetic_selectors.tryRemainingSubtract()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackSubtract(unused_but_mandatory_parameter);
}

pub fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerMultiply()) {
        return;
    }

    if (arithmetic_scalar.tryScalarMultiply()) {
        return;
    }

    if (arithmetic_selectors.tryRemainingMultiply()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_scalar.tryScalarDivide()) {
        return;
    }

    if (arithmetic_selectors.tryRemainingDivideDispatch()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDiv()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDivR()) {
        return;
    }

    arithmetic_dispatch_fallback_owned.fallbackIDivR(unused_but_mandatory_parameter);
}
