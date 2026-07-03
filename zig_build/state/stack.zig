const std = @import("std");

pub const RuntimeObjects = struct {
    stack_state: *std.Build.Step.Compile,

    pub fn link(self: RuntimeObjects, module: *std.Build.Module) void {
        module.addObject(self.stack_state);
    }

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.stack_state.getEmittedBin());
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
    "stack.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/state/stack.zig"),
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings (REPORT-23 §5), imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    const build_options = b.addOptions();
    build_options.addOption(bool, "use_fake_stack_state_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    module.addOptions("stack_state_build_options", build_options);

    const descriptor_storage_options = b.addOptions();
    descriptor_storage_options.addOption(bool, "use_array_backed_global_registers", std.mem.endsWith(u8, name_prefix, "parity") or std.mem.eql(u8, name_prefix, "dmcp"));
    descriptor_storage_options.addOption(bool, "use_fake_state_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    module.addOptions("state_descriptor_storage_build_options", descriptor_storage_options);

    return b.addObject(.{
        .name = b.fmt("{s}-stack-state", .{name_prefix}),
        .root_module = module,
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
        .stack_state = addRuntimeObject(b, target, optimize, name_prefix, options),
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

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    runtime_objects: RuntimeObjects,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "stack-state-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/stack_state"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/stack_state/stack_state_fake_runtime.c"), .flags = &.{"-DZ47_STACK_STATE_RUNTIME=1"} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/stack_state/stack_state_parity.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/stack_state/stack_state_oracle.c"), .flags = &.{} });
    runtime_objects.link(exe.root_module);
    return exe;
}
