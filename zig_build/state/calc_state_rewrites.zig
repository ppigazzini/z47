const std = @import("std");

pub const RuntimeObjects = struct {
    calc_state: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addArg("zig_build/state/calc_state_runtime_helpers.c");
        cmd.addArg("zig_build/state/calc_state_retained.c");
        cmd.addFileArg(self.calc_state.getEmittedBin());
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
    "saveRestoreCalcState.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-calc-state", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/state/calc_state.zig"),
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
        .calc_state = addRuntimeObject(b, target, optimize, name_prefix, options),
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
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});

    module.addCSourceFile(.{ .file = b.path("zig_build/state/calc_state_runtime_helpers.c"), .flags = c_flags });
    module.addCSourceFile(.{ .file = b.path("zig_build/state/calc_state_retained.c"), .flags = c_flags });
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "calc-state-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/calc_state"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/calc_state/calc_state_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/calc_state/calc_state_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/calc_state/calc_state_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
