const std = @import("std");
const build_common = @import("../common.zig");
const abi_host = @import("../abi_host.zig");

pub const RuntimeObjects = struct {
    tone: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg2(self.tone.getEmittedBin(), .{});
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.lang.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // The board this object is compiled for, set by the caller that builds
    // for it; every board fact below derives from it.
    board: build_common.Board = .host,
};

const replaced_core_sources = [_][]const u8{
    "ui/" ++ "tone.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/shell/audio/tone.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = build_common.objectLinkLibc(target),
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    const build_options = b.addOptions();
    build_options.addOption(usize, "library_fn_base", build_common.libraryFnBase(b, options.board));
    module.addOptions("tone_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-ui-tone", .{name_prefix}),
        .root_module = module,
    });
}

pub fn addRuntimeObjects(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
) RuntimeObjects {
    return addRuntimeObjectsWithOptions(b, target, optimize, name_prefix, .{});
}

pub fn addRuntimeObjectsWithOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
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
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
) void {
    module.addObject(addRuntimeObject(b, target, optimize, name_prefix, .{}));
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
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
    abi_host.addToModule(b, exe.root_module, target, optimize, "tone-parity");

    exe.root_module.addIncludePath(b.path("build/tests/tone"));
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/tone/tone_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/tone/tone_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/tone/tone_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
