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

        const named_label: u16 = @intCast(runtime.findNamedLabel(@ptrCast(&buf[0]), runtime.GLOBAL_LABELS));
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
    if (runtime.isLabelOrStackRegister(labelOrVariable)) {
        // Interactive mode: arm the RPN grapher over the selected program.
        fnPgmSlv(labelOrVariable);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            runtime.currentSolverStatus = runtime.SOLVER_STATUS_INTERACTIVE | runtime.SOLVER_STATUS_RPN_GRAPHER;
        }
    } else if ((runtime.currentSolverStatus & runtime.SOLVER_STATUS_USES_FORMULA) == 0 and runtime.isNamedVariable(labelOrVariable) and runtime.currentSolverProgram >= runtime.numberOfLabels) {
        runtime.displayCalcErrorMessage(runtime.ERROR_NO_PROGRAM_SPECIFIED, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
    } else if (runtime.isNamedVariable(labelOrVariable)) {
        // Execute: plot the program over labelOrVariable across [Y, X].
        var xl: runtime.real34_t = undefined;
        var xh: runtime.real34_t = undefined;
        if (runtime.getRegisterAsReal34Quiet(runtime.REGISTER_Y, &xl) and runtime.getRegisterAsReal34Quiet(runtime.REGISTER_X, &xh)) {
            runtime.saveForUndo(); // repeat after dropping the input parameters
            runtime.currentSolverVariable = labelOrVariable;
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
            runtime.refreshScreen(0);
            runtime.currentSolverStatus |= runtime.SOLVER_STATUS_RPN_GRAPHER;
            runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_EQUATION_GRAPHER;
            runtime.fnPlotf(0);
            runtime.fnUndo(0);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.NIM_REGISTER_LINE);
            runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
    }
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

        const named_label: u16 = @intCast(runtime.findNamedLabel(@ptrCast(&buf[0]), runtime.GLOBAL_LABELS));
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
