const runtime = @import("solve_runtime.zig");

comptime {
    _ = @import("tvm.zig");
    _ = @import("sumprod.zig");
    _ = @import("isumprod.zig");
    _ = @import("differentiate.zig");
    _ = @import("solve_owned.zig");
    _ = @import("integrate.zig");
    _ = @import("equation.zig");
    _ = @import("graph.zig");
}

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

pub export fn fnPgmPlt(label: u16) callconv(.c) void {
    // solve.c: fnPgmPlt(label) { fnPgmSlv(label); } -- faithful delegation.
    fnPgmSlv(label);
}

pub export fn fnMvarPlot(labelOrVariable: u16) callconv(.c) void {
    // PENDING faithful port of solve.c:fnMvarPlot -- the RPN-grapher launch
    // (SOLVER_STATUS_RPN_GRAPHER + fnPlotf), part of the testSuite-blind
    // graph/plot rework. Stubbed so the all-Zig product build links; the full
    // behavioral port is deferred to the graph-rework re-sync slice.
    _ = labelOrVariable;
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
    runtime.z47_solver_fnIntegrate(label_or_variable);
}

pub export fn fnIntegrateYX(label_or_variable: u16) callconv(.c) void {
    runtime.z47_solver_fnIntegrateYX(label_or_variable);
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
    runtime.z47_solver_fnProgrammableSum(label);
}

pub export fn fnProgrammableProduct(label: u16) callconv(.c) void {
    runtime.z47_solver_fnProgrammableProduct(label);
}

pub export fn fnProgrammableiSum(label: u16) callconv(.c) void {
    runtime.z47_solver_fnProgrammableiSum(label);
}

pub export fn fnProgrammableiProduct(label: u16) callconv(.c) void {
    runtime.z47_solver_fnProgrammableiProduct(label);
}

pub export fn fn1stDeriv(label: u16) callconv(.c) void {
    runtime.z47_solver_fn1stDeriv(label);
}
