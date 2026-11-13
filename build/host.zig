const std = @import("std");
const host_context = @import("host/context.zig");
const host_steps = @import("host/steps.zig");
const host_types = @import("host/types.zig");

pub const CommonConfig = host_types.CommonConfig;
pub const GeneratedOutputs = host_types.GeneratedOutputs;
pub const Context = host_types.Context;
pub const SimulatorOutputs = host_types.SimulatorOutputs;

pub fn prepareContext(
    b: *std.Build,
    optimize: std.lang.Optimize,
    raspberry: bool,
    decnumber_fastmul: bool,
) !Context {
    return host_context.prepareContext(b, optimize, raspberry, decnumber_fastmul);
}

pub fn registerSteps(b: *std.Build, context: Context, optimize: std.lang.Optimize) SimulatorOutputs {
    return host_steps.registerSteps(b, context, optimize);
}
