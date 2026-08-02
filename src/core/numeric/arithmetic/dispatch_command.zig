const runtime = @import("../command_wrappers/runtime.zig");
const selectors_coordinator = @import("dispatch_selectors_coordinator.zig");
const arithmetic_scalar = @import("dispatch_scalar.zig");
const arithmetic_integer = @import("dispatch_integer.zig");

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

    runtime.legacy.fnAdd(unused_but_mandatory_parameter);
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

    runtime.legacy.fnSubtract(unused_but_mandatory_parameter);
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

    runtime.legacy.fnMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_scalar.tryScalarDivide()) {
        return;
    }

    if (selectors_coordinator.tryRemainingDivideDispatch()) {
        return;
    }

    runtime.legacy.fnDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDiv()) {
        return;
    }

    runtime.legacy.fnIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDivR()) {
        return;
    }

    runtime.legacy.fnIDivR(unused_but_mandatory_parameter);
}
