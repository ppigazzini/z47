const std = @import("std");

// The single owner of the core-to-shell hook storage (`src/abi/host_state.zig`).
//
// Every executable that links a core object needs exactly one of these objects:
// a missing one is a link error naming a `z47Host*Hook` symbol, and a second
// one in the same link is a duplicate-symbol error. Both are loud, which is the
// point -- the previous scheme (weak definitions in every object) failed
// silently on the platforms where weak symbols do not fold.
pub fn addObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-abi-host-state", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/abi/host_state.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
}

pub fn addToModule(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) void {
    module.addObject(addObject(b, target, optimize, name_prefix));
}
