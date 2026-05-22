const runtime = @import("solve_runtime.zig");

pub export fn fnPgmSlv(label: u16) callconv(.c) void {
    if (runtime.isLabel(label)) {
        runtime.currentSolverProgram = runtime.labelToProgram(label);
        return;
    }

    if (runtime.isStackRegister(label)) {
        var buf: [2]u8 = undefined;
        buf[0] = runtime.letteredRegisterName(@intCast(label));
        buf[1] = 0;

        const named_label: u16 = @intCast(runtime.findNamedLabel(@ptrCast(&buf[0])));
        if (runtime.isInvalidVariable(named_label)) {
            runtime.reportLabelNotFound(@ptrCast(&buf[0]));
        } else {
            runtime.currentSolverProgram = runtime.labelToProgram(named_label);
        }
        return;
    }

    runtime.reportOutOfRange(label);
}

pub export fn fnPgmInt(label: u16) callconv(.c) void {
    if (runtime.isLabel(label)) {
        runtime.currentSolverProgram = runtime.labelToProgram(label);
        runtime.clearUsesFormulaStatus();
        return;
    }

    if (runtime.isStackRegister(label)) {
        var buf: [2]u8 = undefined;
        buf[0] = runtime.letteredRegisterName(@intCast(label));
        buf[1] = 0;

        const named_label: u16 = @intCast(runtime.findNamedLabel(@ptrCast(&buf[0])));
        if (runtime.isInvalidVariable(named_label)) {
            runtime.reportLabelNotFoundPgmInt(@ptrCast(&buf[0]));
        } else {
            runtime.currentSolverProgram = runtime.labelToProgram(named_label);
            runtime.clearUsesFormulaStatus();
        }
        return;
    }

    runtime.reportOutOfRangePgmInt(label);
}

pub export fn fnIntegrate(label_or_variable: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnIntegrate(label_or_variable);
}

pub export fn fnIntegrateYX(label_or_variable: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnIntegrateYX(label_or_variable);
}

pub export fn fnTvmBeginMode(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.tvmBeginMode();
}

pub export fn fnTvmEndMode(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.tvmEndMode();
}

pub export fn fnProgrammableSum(label: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnProgrammableSum(label);
}

pub export fn fnProgrammableProduct(label: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnProgrammableProduct(label);
}

pub export fn fnProgrammableiSum(label: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnProgrammableiSum(label);
}

pub export fn fnProgrammableiProduct(label: u16) callconv(.c) void {
    runtime.z47_solver_retained_fnProgrammableiProduct(label);
}