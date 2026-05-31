const runtime = @import("math_command_wrappers_runtime.zig");
const selectors_coordinator = @import("math_arithmetic_dispatch_selectors_coordinator_owned.zig");
const arithmetic_scalar = @import("math_arithmetic_dispatch_scalar_owned.zig");
const arithmetic_integer = @import("math_arithmetic_dispatch_integer_owned.zig");

pub fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerAdd()) {
        return;
    }

    if (arithmetic_scalar.tryScalarAdd()) {
        return;
    }

    if (selectors_coordinator.tryRemainingAdd()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnAdd(unused_but_mandatory_parameter);
}

pub fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerSubtract()) {
        return;
    }

    if (arithmetic_scalar.tryScalarSubtract()) {
        return;
    }

    if (selectors_coordinator.tryRemainingSubtract()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnSubtract(unused_but_mandatory_parameter);
}

pub fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerMultiply()) {
        return;
    }

    if (arithmetic_scalar.tryScalarMultiply()) {
        return;
    }

    if (selectors_coordinator.tryRemainingMultiply()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_scalar.tryScalarDivide()) {
        return;
    }

    if (selectors_coordinator.tryRemainingDivideDispatch()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDiv()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDivR()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnIDivR(unused_but_mandatory_parameter);
}
