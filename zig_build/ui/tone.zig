const std = @import("std");

pub const RuntimeObjects = struct {
    tone: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.tone.getEmittedBin());
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
    "ui/" ++ "tone.c",
};

fn firmwareLibraryFnBase(target: std.Build.ResolvedTarget, name_prefix: []const u8) usize {
    if (target.result.os.tag != .freestanding) {
        return 0;
    }

    if (std.mem.startsWith(u8, name_prefix, "dmcp5")) {
        return 0x08000301;
    }

    return 0x08000201;
}

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/ui/tone.zig"),
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
        .root_source_file = b.path("zig_src/seam/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    const build_options = b.addOptions();
    build_options.addOption(usize, "library_fn_base", firmwareLibraryFnBase(target, name_prefix));
    module.addOptions("tone_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-ui-tone", .{name_prefix}),
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
        .tone = addRuntimeObject(b, target, optimize, name_prefix, options),
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
    _ = c_flags;
    module.addObject(addRuntimeObject(b, target, optimize, name_prefix, .{}));
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "tone-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/tone"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/tone/tone_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/tone/tone_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/tone/tone_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
