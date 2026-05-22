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