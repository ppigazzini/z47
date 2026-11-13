const std = @import("std");
const build_common = @import("../common.zig");

pub const RuntimeObjects = struct {
    calc_state: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg2(self.calc_state.getEmittedBin(), .{});
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
    // The kind of executable this object is linked into, set by the caller;
    // see build_common.Linkage.
    linkage: build_common.Linkage = .product,
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
    // OPTION_STRUCTURED_PGM gates the STRUCT halves of the two save/restore
    // owners: the forLoopTable block backup.cfg carries, and the forClearLoops a
    // load makes so no FOR structure survives the file. It is set per DM42
    // package, from build/firmware.zig's dm42Package table. Defaults true to match a
    // host build.
    option_structured_pgm: bool = true,
    // OPTION_IR_PRINTING: the IR printer paths. defines.h drops it on DM42
    // package 1 only; it is set per package from build/firmware.zig's
    // dm42Package table. Defaults true (host).
    ir_printing: bool = true,
    // OPTION_ATEXT_FONTS gates graFont's line in the state file and its key in
    // backup.cfg, both written and read. Every target z47 builds defines it: the
    // block common to the DM42 packages keeps it.
    option_atext_fonts: bool = true,
    // OPTION_DRG_CFG gates drgConfig's key in backup.cfg, written and read. Every
    // target z47 builds defines it: the block common to the DM42 packages keeps
    // it.
    option_drg_cfg: bool = true,
};

const replaced_core_sources = [_][]const u8{
    "saveRestoreCalcState.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/persist/calc_state.zig"),
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
    core_state_options.addOption(bool, "extra_info_on_calc_error", build_common.extraInfoOnCalcError(options.board, options.linkage));
    core_state_module.addOptions("core_state_build_options", core_state_options);
    module.addImport("core_state", core_state_module);
    const build_options = b.addOptions();
    build_options.addOption(u16, "calc_model_user_id", options.calc_model_user_id);
    // OLD_HW (the DM42) uses RAM_SIZE_IN_BLOCKS_OLD_HW and the OLD_HW
    // program-relocation sign; DMCP5 and host are NEW_HW.
    build_options.addOption(bool, "state_old_hw", options.board.isOldHw());
    build_options.addOption(bool, "option_xfn_1000", options.option_xfn_1000);
    build_options.addOption(bool, "option_structured_pgm", options.option_structured_pgm);
    build_options.addOption(bool, "ir_printing", options.ir_printing);
    build_options.addOption(bool, "option_atext_fonts", options.option_atext_fonts);
    build_options.addOption(bool, "option_drg_cfg", options.option_drg_cfg);
    // EXTRA_INFO_ON_CALC_ERROR, for the owners rooted in this object.
    build_options.addOption(bool, "extra_info_on_calc_error", build_common.extraInfoOnCalcError(options.board, options.linkage));
    module.addOptions("calc_state_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-calc-state", .{name_prefix}),
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
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    calc_model_user_id: u16,
    linkage: build_common.Linkage,
) void {
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .calc_model_user_id = calc_model_user_id, .linkage = linkage });
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
