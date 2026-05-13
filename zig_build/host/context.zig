const std = @import("std");
const build_common = @import("../common.zig");
const shortint_rewrites = @import("../leaf/shortint_rewrites.zig");
const flags_rewrites = @import("../state/flags_rewrites.zig");
const register_metadata_rewrites = @import("../state/register_metadata_rewrites.zig");
const stack_rewrites = @import("../state/stack_rewrites.zig");
const host_generated = @import("generated.zig");
const host_platform = @import("platform.zig");
const host_types = @import("types.zig");

pub fn prepareContext(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    ci_commit_tag: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
) !host_types.Context {
    const host_target = build_common.resolveBuildHostTarget(b);
    const common = try host_platform.resolveCommonConfig(b, host_target, raspberry, decnumber_fastmul);
    const core_sources = try build_common.collectRelativeCFiles(b, "src/c47");
    const core_sources_without_shortint = try shortint_rewrites.filterCoreSources(b, core_sources);
    const core_sources_without_register_metadata = try register_metadata_rewrites.filterCoreSources(b, core_sources_without_shortint);
    const core_sources_without_state = try stack_rewrites.filterCoreSources(b, core_sources_without_register_metadata);
    const core_sources_without_flags = try flags_rewrites.filterCoreSources(b, core_sources_without_state);

    return .{
        .host_target = host_target,
        .common = common,
        .core_sources = core_sources_without_flags,
        .gtk_sources = try build_common.collectRelativeCFiles(b, "src/c47-gtk"),
        .test_sources = try build_common.collectRelativeCFiles(b, "src/testSuite"),
        .version_headers_dir = try host_generated.addVersionHeaders(b, ci_commit_tag),
        .generated = try host_generated.addGeneratorSteps(b, host_target, optimize, common),
        .shortint_leaf_objects = shortint_rewrites.addRuntimeObjects(b, host_target, optimize, "host"),
        .stack_state_objects = stack_rewrites.addRuntimeObjects(b, host_target, optimize, "host"),
    };
}
