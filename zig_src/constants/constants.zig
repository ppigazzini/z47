const runtime = @import("constants_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn clearSolverReadyToExecute() void {
    runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_READY_TO_EXECUTE;
}

pub export fn fnConstant(constant: u16) callconv(.c) void {
    if (!runtime.validateConstant(constant)) {
        return;
    }

    runtime.liftStack();
    clearSolverReadyToExecute();
    runtime.storeConstantInX(constant);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
    runtime.setLastIntegerBaseToZero();
}

pub export fn fnPi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.liftStack();
    clearSolverReadyToExecute();
    runtime.storePiInX();
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
    runtime.setLastIntegerBaseToZero();
}
