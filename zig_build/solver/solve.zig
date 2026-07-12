const std = @import("std");

const replaced_core_sources_manifest = @embedFile("solve_replaced_core_sources.txt");
const runtime_helper_sources_manifest = @embedFile("solve_runtime_helper_sources.txt");

pub const RuntimeObjects = struct {
    solve: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
        while (lines.next()) |line_raw| {
            const source = std.mem.trim(u8, line_raw, " \t");
            if (source.len == 0 or source[0] == '#') continue;
            cmd.addArg(source);
        }
        cmd.addFileArg(self.solve.getEmittedBin());
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

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (std.mem.eql(u8, line, needle)) return true;
    }
    return false;
}

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/engine/analysis/solve.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings (REPORT-23 §5), imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/seam/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    const build_options = b.addOptions();
    // The flash-limited DM42 old_hw firmware ("dmcp", not "dmcp5"/sim/testSuite)
    // runs the heavy/cold solver owners (tvm, sumprod) from executable QSPI
    // (XIP) to keep main FLASH free; same mechanism as the mathematics owners.
    build_options.addOption(bool, "dm42_pkg_xip", std.mem.eql(u8, name_prefix, "dmcp"));
    // The testSuite executable defines TESTSUITE_BUILD for its C sources; mirror
    // it here so the Zig solver owners (tvm.zig) take the testSuite code
    // path (fnTvmVar's `testing` short-circuit).
    // startsWith, not eql: the ASAN lane builds "testSuite-asan", which must take
    // the same testSuite code paths (fnTvmVar's `testing` short-circuit) or the
    // TVM tests fail there while passing on the plain testSuite.
    build_options.addOption(bool, "is_testsuite_build", std.mem.startsWith(u8, name_prefix, "testSuite"));
    // DMCP firmware builds (both "dmcp" old_hw and "dmcp5") stub calcModeAimGui()
    // to a no-op (hal/gui.h: #if defined(DMCP_BUILD) ...); the on-screen-keyboard
    // sim/testSuite link the real function. equation.zig mirrors this.
    build_options.addOption(bool, "is_dmcp_build", std.mem.startsWith(u8, name_prefix, "dmcp"));
    module.addOptions("solve_build_options", build_options);
    return b.addObject(.{
        .name = b.fmt("{s}-solver-solve", .{name_prefix}),
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
        .solve = addRuntimeObject(b, target, optimize, name_prefix, options),
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
        if (source.len == 0 or source[0] == '#') continue;
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});
    module.addObject(runtime_object);
}
