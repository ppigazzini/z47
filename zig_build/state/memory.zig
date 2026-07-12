const std = @import("std");

pub const RuntimeObjects = struct {
    memory_state: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.memory_state.getEmittedBin());
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
    "memory.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/kernel/memory.zig"),
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings (REPORT-23 §5).
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    const build_options = b.addOptions();
    const use_fake_harness_surface = std.mem.endsWith(u8, name_prefix, "parity");
    const free_regions_are_inline_array = target.result.os.tag == .freestanding and std.mem.eql(u8, name_prefix, "dmcp");
    build_options.addOption(bool, "use_fake_harness_surface", use_fake_harness_surface);
    build_options.addOption(bool, "free_regions_are_inline_array", free_regions_are_inline_array);
    build_options.addOption(usize, "max_free_regions", if (free_regions_are_inline_array) 50 else 200);
    build_options.addOption(u16, "ram_size_in_blocks", if (use_fake_harness_surface) 64 else if (free_regions_are_inline_array) 16384 else 65534);
    module.addOptions("memory_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-memory-state", .{name_prefix}),
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
        .memory_state = addRuntimeObject(b, target, optimize, name_prefix, options),
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

    _ = c_flags;
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "memory-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/memory"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/memory/memory_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/memory/memory_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/memory/memory_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
