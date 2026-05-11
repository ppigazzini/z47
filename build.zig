const std = @import("std");
const build_common = @import("zig_build/common.zig");
const dist_steps = @import("zig_build/dist.zig");
const firmware_steps = @import("zig_build/firmware.zig");
const host_steps = @import("zig_build/host.zig");

pub fn build(b: *std.Build) void {
    buildImpl(b) catch |err| {
        std.debug.panic("build.zig configuration failed: {s}", .{@errorName(err)});
    };
}

fn buildImpl(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const ci_commit_tag = b.option([]const u8, "ci-commit-tag", "Commit tag for version information") orelse "";
    const raspberry = b.option(bool, "raspberry", "Enable Raspberry Pi layout") orelse false;
    const decnumber_fastmul = b.option(bool, "decnumber-fastmul", "Enable DECNUMBER_FASTMUL") orelse true;
    const dmcp_package = b.option(u8, "dmcp-package", "Select the upstream DMCP package variant") orelse 4;

    const host_context = try host_steps.prepareContext(b, optimize, ci_commit_tag, raspberry, decnumber_fastmul);
    host_steps.registerSteps(b, host_context, optimize);

    const firmware_bundle = firmware_steps.registerSteps(
        b,
        host_context,
        optimize,
        dmcp_package,
        decnumber_fastmul,
    );

    const dist_version = if (ci_commit_tag.len > 0)
        ci_commit_tag
    else
        build_common.commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";

    try dist_steps.registerSteps(
        b,
        host_context,
        firmware_bundle,
        ci_commit_tag,
        dist_version,
    );
}