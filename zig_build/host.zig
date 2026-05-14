const std = @import("std");
const host_builders = @import("host/builders.zig");
const host_context = @import("host/context.zig");
const host_steps = @import("host/steps.zig");
const host_types = @import("host/types.zig");

pub const CommonConfig = host_types.CommonConfig;
pub const GeneratedOutputs = host_types.GeneratedOutputs;
pub const ShortIntLeafObjects = host_types.ShortIntLeafObjects;
pub const KeyboardStateObjects = host_types.KeyboardStateObjects;
pub const StackStateObjects = host_types.StackStateObjects;
pub const Context = host_types.Context;
pub const SimulatorOutputs = host_types.SimulatorOutputs;

pub fn prepareContext(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    ci_commit_tag: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
) !Context {
    return host_context.prepareContext(b, optimize, ci_commit_tag, raspberry, decnumber_fastmul);
}

pub fn registerSteps(b: *std.Build, context: Context, optimize: std.builtin.OptimizeMode) SimulatorOutputs {
    return host_steps.registerSteps(b, context, optimize);
}

pub fn addSimulator(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    name: []const u8,
    artifact_name: []const u8,
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    gtk_sources: []const []const u8,
    common: CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    shortint_leaf_objects: ShortIntLeafObjects,
    keyboard_state_objects: KeyboardStateObjects,
    stack_state_objects: StackStateObjects,
    calc_model: []const u8,
    sanitize_c: ?std.zig.SanitizeC,
) *std.Build.Step.Compile {
    return host_builders.addSimulator(
        b,
        host_target,
        name,
        artifact_name,
        optimize,
        core_sources,
        gtk_sources,
        common,
        version_headers_dir,
        generated,
        shortint_leaf_objects,
        keyboard_state_objects,
        stack_state_objects,
        calc_model,
        sanitize_c,
    );
}
