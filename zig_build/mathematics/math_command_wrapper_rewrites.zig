const std = @import("std");

pub const RuntimeObjects = struct {
    math_command_wrappers: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addArg("zig_bridge/mathematics/math_wrappers_runtime_helpers.c");
        cmd.addFileArg(self.math_command_wrappers.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
};

const replaced_core_sources = [_][]const u8{
    "mathematics/min.c",
    "mathematics/max.c",
    "mathematics/ceil.c",
    "mathematics/floor.c",
    "mathematics/2pow.c",
    "mathematics/10pow.c",
    "mathematics/exp.c",
    "mathematics/eulersFormula.c",
    "mathematics/invert.c",
    "mathematics/sign.c",
    "mathematics/changeSign.c",
    "mathematics/sin.c",
    "mathematics/cos.c",
    "mathematics/tan.c",
    "mathematics/sinh.c",
    "mathematics/cosh.c",
    "mathematics/tanh.c",
    "mathematics/square.c",
    "mathematics/cube.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-math-command-wrappers", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/mathematics/math_command_wrappers.zig"),
            .target = target,
            .optimize = optimize,
            .strip = options.strip,
            .unwind_tables = options.unwind_tables,
            .stack_protector = options.stack_protector,
            .stack_check = options.stack_check,
            .omit_frame_pointer = options.omit_frame_pointer,
            .error_tracing = options.error_tracing,
        }),
    });
}

pub fn addRuntimeObjects(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) RuntimeObjects {
    return addRuntimeObjectsWithOptions(b, target, optimize, name_prefix, .{});
}

pub fn addRuntimeObjectsWithOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) RuntimeObjects {
    return .{
        .math_command_wrappers = addRuntimeObject(b, target, optimize, name_prefix, options),
    };
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
    module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/math_wrappers_runtime_helpers.c"), .flags = c_flags });
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-command-wrappers-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_parity.c"), .flags = &.{} });
    exe.root_module.linkSystemLibrary("gmp", .{ .use_pkg_config = .yes });
    exe.root_module.addObject(runtime_object);
    return exe;
}
