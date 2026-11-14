const runtime = @import("../command_wrappers/runtime.zig");
const bodies = @import("../command_bodies.zig");
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

    bodies.fnAdd(unused_but_mandatory_parameter);
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

    bodies.fnSubtract(unused_but_mandatory_parameter);
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

    bodies.fnMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_scalar.tryScalarDivide()) {
        return;
    }

    if (selectors_coordinator.tryRemainingDivideDispatch()) {
        return;
    }

    bodies.fnDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDiv()) {
        return;
    }

    bodies.fnIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (arithmetic_integer.tryIntegerIDivR()) {
        return;
    }

    bodies.fnIDivR(unused_but_mandatory_parameter);
}
