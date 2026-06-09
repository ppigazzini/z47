const std = @import("std");
const host_platform = @import("../host/platform.zig");

const replaced_core_sources_manifest = @embedFile("math_command_wrapper_replaced_core_sources.txt");
const runtime_helper_sources_manifest = @embedFile("math_command_wrapper_runtime_helper_sources.txt");

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') {
            continue;
        }
        if (std.mem.eql(u8, line, needle)) {
            return true;
        }
    }
    return false;
}

pub const RuntimeObjects = struct {
    math_command_wrappers: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
        while (lines.next()) |line_raw| {
            const source = std.mem.trim(u8, line_raw, " \t");
            if (source.len == 0 or source[0] == '#') {
                continue;
            }
            cmd.addArg(source);
        }
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


fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/mathematics/math_command_wrappers.zig"),
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    const build_options = b.addOptions();
    build_options.addOption(bool, "use_fake_wp34s_model", std.mem.endsWith(u8, name_prefix, "parity"));
    build_options.addOption(bool, "use_fake_wp34s_harness_surface", std.mem.eql(u8, name_prefix, "parity") or std.mem.eql(u8, name_prefix, "random-parity"));
    build_options.addOption(bool, "export_public_ln_complex", true);
    // The testSuite executable defines TESTSUITE_BUILD for its C sources; mirror
    // that here so the Zig random seed uses the deterministic test seed.
    build_options.addOption(bool, "is_testsuite_build", std.mem.eql(u8, name_prefix, "testSuite"));
    // Mirror "#if defined(DMCP_BUILD) && HARDWARE_MODEL == HWM_DM42" from wp34s.c:
    // only the DM42 firmware ("dmcp", not "dmcp5"/sim/testSuite) uses the small
    // fallback mod buffers / reduced mod precision.
    build_options.addOption(bool, "wp34s_mod_small_buffers", std.mem.eql(u8, name_prefix, "dmcp"));
    module.addOptions("math_command_wrappers_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-math-command-wrappers", .{name_prefix}),
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
        .math_command_wrappers = addRuntimeObject(b, target, optimize, name_prefix, options),
    };
}

pub fn filterCoreSources(b: *std.Build, core_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, core_sources.len);
    errdefer filtered.deinit(b.allocator);

    for (core_sources) |source| {
        if (manifestContainsPath(replaced_core_sources_manifest, source)) {
            continue;
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
    var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const source = std.mem.trim(u8, line_raw, " \t");
        if (source.len == 0 or source[0] == '#') {
            continue;
        }
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
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
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/" ++ "math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/" ++ "random_fake_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_legacy_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}

pub fn addRandomParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "random-parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-random-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/" ++ "math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/" ++ "random_fake_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_random_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_random_dispatch_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_legacy_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_random_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}
