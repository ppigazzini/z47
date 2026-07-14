const std = @import("std");

pub const RuntimeObjects = struct {
    calc_state: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
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
    const module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/kernel/calc_state.zig"),
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
    build_options.addOption(bool, "use_fake_calc_state_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    // R47 build variants ("r47", "dmcpr47") select USER_R47 (66); otherwise
    // USER_C47 (46). Only allow_user_keys consumes this in the product path.
    build_options.addOption(u16, "calc_model_user_id", if (std.mem.indexOf(u8, name_prefix, "r47") != null) 66 else 46);
    // OLD_HW (DMCP / original DM42) uses RAM_SIZE_IN_BLOCKS_OLD_HW and the
    // OLD_HW program-relocation sign; DMCP5 / DM42n / host are NEW_HW. The
    // firmware names the OLD_HW calc-state object "dmcp"/"dmcpr47" and the NEW_HW
    // one "dmcp5"/"dmcp5r47"; host names are NEW_HW.
    build_options.addOption(bool, "state_old_hw", std.mem.indexOf(u8, name_prefix, "dmcp") != null and std.mem.indexOf(u8, name_prefix, "dmcp5") == null);
    module.addOptions("calc_state_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-calc-state", .{name_prefix}),
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

    // The calc-state save/restore/load path is now fully Zig-owned; the former
    // calc_state_legacy.c bridge is gone. The DMCP ROM-macro shims it once needed
    // (power_check_screen / sys_timer) are now Zig-owned in state_dmcp_rom.zig.
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
    // Link stubs for the calc-state owner C deps not provided by the fake
    // surface (codec leaves, gmp, calc-state globals); unexercised by the
    // header-only fixture, present only to satisfy the link. gmp is stubbed in
    // the link-stub file (not linked) so the harness needs no system gmp — which
    // the Windows/macOS runners can't resolve via linkSystemLibrary.
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/calc_state/calc_state_parity_link_stubs.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
