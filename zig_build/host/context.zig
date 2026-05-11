const std = @import("std");
const build_common = @import("../common.zig");
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

    return .{
        .host_target = host_target,
        .common = common,
        .core_sources = try build_common.collectRelativeCFiles(b, "src/c47"),
        .gtk_sources = try build_common.collectRelativeCFiles(b, "src/c47-gtk"),
        .test_sources = try build_common.collectRelativeCFiles(b, "src/testSuite"),
        .version_headers_dir = try host_generated.addVersionHeaders(b, ci_commit_tag),
        .generated = try host_generated.addGeneratorSteps(b, host_target, optimize, common),
    };
}