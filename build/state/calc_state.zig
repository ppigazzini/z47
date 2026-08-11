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
    // CALCMODEL as the id typeDefinitions.h gives it: USER_C47 = 46,
    // USER_R47 = 66. The owner stamps it into the save file's identity line
    // ("C47_save_file_00" / "R47_save_file_00") and compares it against the line
    // a loaded file carries to decide whether that file's user key assignments
    // may be applied. It has to be passed in, not read off the object name: the
    // R47 firmware links calc-state objects it shares with the C47 firmware, so
    // their names carry no model. Defaults to USER_C47.
    calc_model_user_id: u16 = 46,
    // OPTION_XFN_1000 gates both halves of the XFN register form in
    // saveRestoreCalcState.c: the isXFNRegister arm of registerToSaveString and
    // the "RXFN" branch of restoreRegister. Upstream #undef's it in the block
    // common to DMCP packages 1-4, so no DM42 package writes or reads that form;
    // DMCP5 and host do. Defaults true to match a host build.
    option_xfn_1000: bool = true,
    // EXTRA_INFO_ON_CALC_ERROR, for the scalar-state owners this object carries
    // through its core_state module. 0 on firmware and in the testSuite; default
    // true mirrors a host build.
    extra_info_on_calc_error: bool = true,
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
        .root_source_file = b.path("src/core/persist/calc_state.zig"),
        .target = target,
        .optimize = optimize,
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
    // The DMCP ROM shim is shared by the calc-state and program-serialization
    // owners, so it is a REGISTERED module: directory-free, letting each owner
    // family live in its own subdirectory without a cross-module relative import.
    const dmcp_rom_module = b.createModule(.{
        .root_source_file = b.path("src/core/hal/dmcp_rom.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("dmcp_rom", dmcp_rom_module);
    // The scalar-state owners have their own root (core/state/state.zig) and are
    // pulled in by NAME, so no unrelated owner has to carry their compilation.
    // They still land in THIS object, exactly as when calc_state force-imported
    // them by path -- only the directory coupling is gone.
    const core_state_module = b.createModule(.{
        .root_source_file = b.path("src/core/state/state.zig"),
        .target = target,
        .optimize = optimize,
    });
    core_state_module.addImport("abi", abi_module);
    // The scalar-state owners format their out-of-domain and invalid-input
    // subjects into the shared errorMessage buffer, which upstream compiles out
    // with EXTRA_INFO_ON_CALC_ERROR: 0 on firmware and in the testSuite. Same
    // derivation as the stack and register-metadata objects use.
    const core_state_options = b.addOptions();
    core_state_options.addOption(bool, "extra_info_on_calc_error", options.extra_info_on_calc_error and
        !std.mem.startsWith(u8, name_prefix, "testSuite"));
    core_state_module.addOptions("core_state_build_options", core_state_options);
    module.addImport("core_state", core_state_module);
    const build_options = b.addOptions();
    build_options.addOption(u16, "calc_model_user_id", options.calc_model_user_id);
    // OLD_HW (DMCP / original DM42) uses RAM_SIZE_IN_BLOCKS_OLD_HW and the
    // OLD_HW program-relocation sign; DMCP5 / DM42n / host are NEW_HW. The
    // firmware names the OLD_HW calc-state object "dmcp"/"dmcpr47" and the NEW_HW
    // one "dmcp5"/"dmcp5r47"; host names are NEW_HW.
    build_options.addOption(bool, "state_old_hw", std.mem.indexOf(u8, name_prefix, "dmcp") != null and std.mem.indexOf(u8, name_prefix, "dmcp5") == null);
    build_options.addOption(bool, "option_xfn_1000", options.option_xfn_1000);
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
    calc_model_user_id: u16,
) void {
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .calc_model_user_id = calc_model_user_id });

    // The calc-state save/restore/load path is now fully Zig-owned; the former
    // calc_state_legacy.c bridge is gone. The DMCP ROM-macro shims it once needed
    // (power_check_screen / sys_timer) are now Zig-owned in core/hal/dmcp_rom.zig.
    _ = c_flags;
    module.addObject(runtime_object);
}

// NO addParityExecutable HERE, deliberately.
//
// The calc-state parity lane used to be a unit executable: a mock c47.h, a
// counting fake runtime, link stubs, and a 194-line hand-written oracle that
// modelled save-file revision parsing and nothing else. It is now a FULL-CORE
// differential (build/host/steps.zig: calc_state_parity), because sharing the
// value codecs with c43's own saveRestoreCalcState.c "for real" -- rather than
// modelling them -- needs the whole calculator, and only then can the lane
// compare `.sav` BYTES. The owner-side `use_fake_calc_state_harness_surface`
// fork went with it: it replaced eighteen call sites with counting stubs, so the
// build the lane measured was not the build that ships.
