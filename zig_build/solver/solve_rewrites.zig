const std = @import("std");

const replaced_core_sources = [_][]const u8{
    "solver/solve.c",
    "solver/integrate.c",
    "solver/tvm.c",
    "solver/sumprod.c",
};

const runtime_helper_sources = [_][]const u8{
    "zig_bridge/solver/solve_runtime_helpers.c",
    "zig_bridge/solver/solve_retained.c",
    "zig_bridge/solver/integrate_runtime_helpers.c",
    "zig_bridge/solver/integrate_retained.c",
    "zig_bridge/solver/tvm_runtime_helpers.c",
    "zig_bridge/solver/tvm_retained.c",
    "zig_bridge/solver/sumprod_retained.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-solver-solve", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/solver/solve.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
}

pub fn filterCoreSources(b: *std.Build, core_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, core_sources.len);
    errdefer filtered.deinit(b.allocator);

    outer: for (core_sources) |source| {
        for (replaced_core_sources) |removed| {
            if (std.mem.eql(u8, source, removed)) {
                continue :outer;
            }
        }
        try filtered.append(b.allocator, source);
    }

    return try filtered.toOwnedSlice(b.allocator);
}

pub fn addToModule(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    c_flags: []const []const u8,
) void {
    for (runtime_helper_sources) |source| {
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix);
    module.addObject(runtime_object);
}