const std = @import("std");
const build_common = @import("common.zig");
const host_steps = @import("host.zig");
const constants = @import("constants/constants.zig");
const shortint = @import("shortint/shortint.zig");
const calc_state = @import("state/calc_state.zig");
const flags = @import("state/flags.zig");
const math_command_wrappers = @import("mathematics/math_command_wrappers.zig");
const keyboard_state = @import("state/keyboard_state.zig");
const memory = @import("state/memory.zig");
const program_serialization = @import("state/program_serialization.zig");
const frontier = @import("frontier/frontier.zig");
const solve = @import("solver/solve.zig");
const register_metadata = @import("state/register_metadata.zig");
const stack = @import("state/stack.zig");
const tone = @import("ui/tone.zig");

pub const Board = enum {
    dmcp,
    dmcp5,
};

// CALCMODEL as the ids typeDefinitions.h gives them. Every owner family that
// needs to know which calculator this firmware is takes its value from here: the
// frontier object seeds the calcModel global with it, and the calc-state object
// stamps it into the save file's identity line and compares it against the line
// a loaded file carries. It cannot be recovered from an object name, because the
// C47 and R47 firmwares of one board share most of their objects and so share
// those objects' names.
const user_c47: u8 = 46;
const user_r47: u8 = 66;

pub const Outputs = struct {
    program: std.Build.LazyPath,
    qspi: std.Build.LazyPath,
    map: std.Build.LazyPath,
};

pub const Build = struct {
    /// The object set this firmware links, named once so the object-manifest
    /// step and the linker cannot disagree.
    objects: FirmwareObjects,
    step: *std.Build.Step,
    outputs: Outputs,
};

pub const Config = struct {
    step_name: []const u8,
    description: []const u8,
    board: Board,
    program_name: []const u8,
    map_name: []const u8 = "C47",
    program_extension: []const u8,
    generated_qspi_header_name: []const u8,
    qspi_macro: []const u8,
    pre_calcmodel_define: ?[]const u8 = null,
    final_calcmodel_define: ?[]const u8 = null,
    dmcp_package: ?u8 = null,
};

pub const VariantBuild = struct {
    package: u8,
    build: Build,
};

pub const Bundle = struct {
    dmcp: Build,
    dmcpr47: Build,
    dmcp5: Build,
    dmcp5r47: Build,
    dmcp_variants: [3]VariantBuild,
};

const ArmGmpOutputs = struct {
    header: std.Build.LazyPath,
    library: std.Build.LazyPath,
};

const ConstantsObjects = constants.RuntimeObjects;
const ShortIntObjects = shortint.RuntimeObjects;
const CalcStateObjects = calc_state.RuntimeObjects;
const FlagsStateObjects = flags.RuntimeObjects;
const MathCommandWrapperObjects = math_command_wrappers.RuntimeObjects;
const KeyboardStateObjects = keyboard_state.RuntimeObjects;
const MemoryStateObjects = memory.RuntimeObjects;
const ProgramSerializationObjects = program_serialization.RuntimeObjects;
const FrontierObjects = frontier.RuntimeObjects;
const SolveObjects = solve.RuntimeObjects;
const RegisterMetadataObjects = register_metadata.RuntimeObjects;
const StackStateObjects = stack.RuntimeObjects;
const ToneObjects = tone.RuntimeObjects;

const BuildPhase = enum {
    pre,
    final,
};

/// The firmware product's object set, named once.
///
/// The link command and the object manifest both consume THIS list, so the
/// manifest cannot drift from what is linked. Before it existed the set had no
/// single name, and every attempt to measure it from outside the build -- a cache
/// glob, a name-prefix filter, a `--verbose-link` scrape -- produced a different
/// wrong answer. A build that cannot name its own product object set is why.
const FirmwareObjects = struct {
    flags_state: FlagsStateObjects,
    math_command_wrappers: MathCommandWrapperObjects,
    constants: ConstantsObjects,
    tone: ToneObjects,
    audio_runtime: *std.Build.Step.Compile,
    print_ir_runtime: *std.Build.Step.Compile,
    io_runtime: *std.Build.Step.Compile,
    keyboard_state: KeyboardStateObjects,
    memory_state: MemoryStateObjects,
    calc_state: CalcStateObjects,
    program_serialization: ProgramSerializationObjects,
    frontier: FrontierObjects,
    solve: SolveObjects,
    register_metadata: RegisterMetadataObjects,
    shortint: ShortIntObjects,
    stack_state: StackStateObjects,

    /// Append every object, in link order. Works against any `Run` step: the
    /// firmware linker takes them as inputs, the manifest writer takes them as
    /// paths to record.
    pub fn addToCommand(self: FirmwareObjects, cmd: *std.Build.Step.Run) void {
        self.flags_state.addToCommand(cmd);
        self.math_command_wrappers.addToCommand(cmd);
        self.constants.addToCommand(cmd);
        self.tone.addToCommand(cmd);
        cmd.addFileArg2(self.audio_runtime.getEmittedBin(), .{});
        cmd.addFileArg2(self.print_ir_runtime.getEmittedBin(), .{});
        cmd.addFileArg2(self.io_runtime.getEmittedBin(), .{});
        self.keyboard_state.addToCommand(cmd);
        self.memory_state.addToCommand(cmd);
        self.calc_state.addToCommand(cmd);
        self.program_serialization.addToCommand(cmd);
        self.frontier.addToCommand(cmd);
        self.solve.addToCommand(cmd);
        self.register_metadata.addToCommand(cmd);
        self.shortint.addToCommand(cmd);
        self.stack_state.addToCommand(cmd);
    }
};

const ElfBuildOutputs = struct {
    elf: std.Build.LazyPath,
    map: std.Build.LazyPath,
    objects: FirmwareObjects,
};

const ObjcopyOptions = struct {
    section_mode: enum { only, remove },
};

const firmware_common_c_flags: []const []const u8 = &.{
    "-DDMCP_BUILD",
    "-DOS32BIT",
    "-D__weak=\"__attribute__((weak))\"",
    "-D__packed=\"__attribute__((__packed__))\"",
    "-Wno-unused-parameter",
    "-fno-exceptions",
    "-fno-unwind-tables",
    "-fno-asynchronous-unwind-tables",
};

const firmware_common_link_flags: []const []const u8 = &.{
    "--specs=nano.specs",
    "--specs=nosys.specs",
    "-u",
    "_printf_float",
    "-lc",
    "-lm",
    "-lnosys",
    "-Wl,--gc-sections",
    "-Wl,--wrap=_malloc_r",
    "-Wl,--cref",
};

// The OPTION_* a DM42 package compiles, as defines.h settles them for
// DMCP_BUILD, OLD_HW and TWO_FILE_PGM. defines.h decides each option in layers:
// the default block, then the DMCP_PACKAGE1..3 / DMCP_PACKAGE4_NOOPT block of the
// selected package, then the block common to packages 1-4, which runs after the
// package blocks and overrides them, then the dependency fixups after
// `#endif // DMCP_BUILD`. Preprocessing defines.h for each package gives:
//
//   option                 pkg 1  pkg 2  pkg 3  pkg 4
//   ELLIPTIC                 -      Y      Y      -
//   BESSEL, ORTHO            Y      Y      Y      -
//   DISTRIBUTIONS            Y      Y      Y      -
//   DIST_NORMAL, DIST_B      Y      Y      Y      -
//   DIST_C, DIST_D           Y      -      Y      -
//   TVM_FORMULAS             Y      Y      -      -
//   TVM_NEWTON, TVM_AMORT    Y      Y      Y      -
//   ELEC, EIGEN, SLVP_POLY   Y      Y      Y      -
//   STRUCTURED_PGM           Y      Y      Y      -
//   IR_PRINTING              Y      Y      -      Y
//
// Every other option is a property of the board, not of the package: the
// common block drops VECTOR, XFN_1000, ALGDEP, MX_SHOW, CUBIC_159 and EIGEN_159
// from all four, and keeps the rest of the host set, ATEXT, ATEXT_FONTS,
// INFSUMS, LP_DP_TIMING, EDIT_X and EDIT_PEM among them. A null package is a
// TWO_FILE_PGM build with no DMCP_PACKAGE: no package block runs, so it keeps
// every option in the table. DMCP5 is NEW_HW, never enters the TWO_FILE_PGM
// block, and goes through none of this.
const Dm42Package = struct {
    elliptic: bool = true,
    bessel: bool = true,
    ortho: bool = true,
    distributions: bool = true,
    dist_normal: bool = true,
    dist_b: bool = true,
    dist_c: bool = true,
    dist_d: bool = true,
    tvm_formulas: bool = true,
    tvm_newton: bool = true,
    tvm_amort: bool = true,
    elec: bool = true,
    eigen: bool = true,
    slvp_poly: bool = true,
    structured_pgm: bool = true,
    ir_printing: bool = true,
};

// What each package block drops from the table above.
fn dm42Package(dmcp_package: ?u8) Dm42Package {
    return switch (dmcp_package orelse return .{}) {
        1 => .{ .elliptic = false },
        2 => .{ .dist_c = false, .dist_d = false },
        3 => .{ .tvm_formulas = false, .ir_printing = false },
        4 => .{
            .elliptic = false,
            .bessel = false,
            .ortho = false,
            .distributions = false,
            .dist_normal = false,
            .dist_b = false,
            .dist_c = false,
            .dist_d = false,
            .tvm_formulas = false,
            .tvm_newton = false,
            .tvm_amort = false,
            .elec = false,
            .eigen = false,
            .slvp_poly = false,
            .structured_pgm = false,
        },
        else => .{},
    };
}

// Apply the DM42 board and package OPTION_* to a frontier build options value.
// Only the DM42 (OLD_HW) objects go through here; DMCP5 takes the host-shaped
// defaults unchanged.
fn frontierDistributionStrip(base: frontier.RuntimeObjectOptions, dmcp_package: ?u8) frontier.RuntimeObjectOptions {
    var opts = base;
    // The DMCP (DM42) family is OLD_HW, where freeMemoryRegions is a static
    // array rather than a pointer. DMCP5 (NEW_HW) keeps the pointer layout.
    opts.old_hw = true;
    // Settled by the block common to packages 1-4, so the same for all four.
    opts.option_vector = false; // !OPTION_VECTOR: no 2D/3D vector commands or TI
    opts.option_xfn_1000 = false; // !OPTION_XFN_1000: no 1000-digit XFN entries
    opts.option_algdep = false; // !OPTION_ALGDEP: x->POLY and V->SUM=0 bind itemToBeCoded, leave the POLY menu and are struck out
    opts.option_mx_show = false; // !OPTION_MX_SHOW: SHOW draws 9 matrix rows in ALL at 15 digits, with no rolled out or laid flat page
    // Each strip_* below is the inverse of the matching upstream OPTION_*, which
    // is an include flag: defined means the feature is compiled in, and its
    // absence is what turns the bodies into empty stubs.
    const pkg = dm42Package(dmcp_package);
    opts.strip_16 = !pkg.dist_normal;
    opts.strip_17b = !pkg.dist_b;
    opts.strip_17 = !pkg.dist_c;
    opts.strip_17c = !pkg.dist_d;
    // !OPTION_DISTRIBUTIONS drops the DISTR entry from menu_PROB.
    opts.strip_15 = !pkg.distributions;
    // OPTION_HP35 stays defined for every TWO_FILE_PGM package, so menu_Dev keeps
    // its SetHP35 entry throughout.
    opts.strip_21_hp35 = false;
    opts.strip_ortho = !pkg.ortho;
    opts.strip_bessel = !pkg.bessel;
    opts.strip_elliptic = !pkg.elliptic;
    opts.option_elec = pkg.elec;
    opts.ir_printing = pkg.ir_printing;
    opts.option_eigen = pkg.eigen;
    opts.option_slvp_poly = pkg.slvp_poly;
    opts.option_structured_pgm = pkg.structured_pgm; // without it the STRUCT items report that this hardware cannot run them
    opts.option_tvm_amort = pkg.tvm_amort; // without it menu_AMORT is struck out and the amort TI lines are not drawn
    return opts;
}

// Apply the DM42 board and package OPTION_* to a mathematics build options
// value. The mathematics owners are the port of upstream's src/c47/mathematics/,
// so the options that gate bodies there are the ones set here. The DM42 board is
// OLD_HW, marked here rather than inferred from the object's name prefix: the
// name is a label, the board is the fact.
fn mathematicsPackageOptions(base: math_command_wrappers.RuntimeObjectOptions, dmcp_package: ?u8) math_command_wrappers.RuntimeObjectOptions {
    var opts = base;
    opts.old_hw = true;
    // Settled by the block common to packages 1-4, so the same for all four.
    opts.option_vector = false;
    opts.option_xfn_1000 = false;
    opts.option_algdep = false;
    opts.option_cubic_159 = false;
    opts.option_eigen_159 = false;
    const pkg = dm42Package(dmcp_package);
    opts.option_elliptic = pkg.elliptic;
    opts.option_bessel = pkg.bessel;
    opts.option_ortho = pkg.ortho;
    opts.option_dist_normal = pkg.dist_normal;
    opts.option_eigen = pkg.eigen;
    opts.option_slvp_poly = pkg.slvp_poly;
    return opts;
}

// Apply the DM42 board and package OPTION_* to a calc-state build options value.
// Only the DM42 (OLD_HW) object goes through here; DMCP5 keeps the host-shaped
// defaults.
fn calcStateOptions(base: calc_state.RuntimeObjectOptions, dmcp_package: ?u8) calc_state.RuntimeObjectOptions {
    var opts = base;
    // !OPTION_XFN_1000, settled by the common block: registerToSaveString falls
    // through the XFN arm to the standard data-type branch, and restoreRegister
    // offers no "RXFN" branch.
    opts.option_xfn_1000 = false;
    // !OPTION_STRUCTURED_PGM: backup.cfg carries no forLoopTable block, and a
    // load has no running FOR structure to clear.
    opts.option_structured_pgm = dm42Package(dmcp_package).structured_pgm;
    return opts;
}

// Apply the DM42 board and package OPTION_* to a keyboard-state build options
// value.
fn keyboardStateOptions(base: keyboard_state.RuntimeObjectOptions, dmcp_package: ?u8) keyboard_state.RuntimeObjectOptions {
    var opts = base;
    opts.old_hw = true; // DM42: quarter-size pool, read by leavePem
    opts.option_structured_pgm = dm42Package(dmcp_package).structured_pgm; // without it there is no VALID to run on the way out of the editor
    return opts;
}

// Apply the DM42 board and package OPTION_* to a program-serialization build
// options value.
fn programSerializationOptions(base: program_serialization.RuntimeObjectOptions, dmcp_package: ?u8) program_serialization.RuntimeObjectOptions {
    var opts = base;
    opts.old_hw = true; // DM42: quarter-size pool
    opts.option_structured_pgm = dm42Package(dmcp_package).structured_pgm; // without it there is nothing to refuse, to validate, or to indent
    return opts;
}

// Apply the DM42 package OPTION_* to a solver build options value.
fn solverPackageOptions(base: solve.RuntimeObjectOptions, dmcp_package: ?u8) solve.RuntimeObjectOptions {
    var opts = base;
    const pkg = dm42Package(dmcp_package);
    opts.option_slvp_poly = pkg.slvp_poly;
    // Without TVM_FORMULAS every unknown goes through the solver; without
    // TVM_NEWTON as well, the solver is brent-only.
    opts.option_tvm_formulas = pkg.tvm_formulas;
    opts.option_tvm_newton = pkg.tvm_newton;
    opts.option_tvm_amort = pkg.tvm_amort;
    return opts;
}

pub fn registerSteps(
    b: *std.Build,
    context: host_steps.Context,
    optimize: std.lang.Optimize,
    dmcp_package: u8,
    decnumber_fastmul: bool,
) Bundle {
    const forcecrc32 = addForceCrc32Tool(b, context.host_target, optimize);
    const arm_gmp_dmcp = addArmGmpBuild(b, .dmcp);
    const arm_gmp_dmcp5 = addArmGmpBuild(b, .dmcp5);
    const firmware_leaf_optimize = defaultFirmwareLeafOptimize(optimize);
    const firmware_leaf_options: shortint.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_flags_options: flags.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    };
    const firmware_math_command_wrapper_options: math_command_wrappers.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_constants_options: constants.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_tone_options: tone.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_memory_options: memory.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_calc_state_options: calc_state.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // The C47 firmwares; the r47 value below overrides it for the R47 ones.
        .calc_model_user_id = user_c47,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    };
    var firmware_r47_calc_state_options = firmware_calc_state_options;
    firmware_r47_calc_state_options.calc_model_user_id = user_r47;
    const firmware_program_serialization_options: program_serialization.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_register_metadata_options: register_metadata.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    };
    const firmware_stack_options: stack.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    };
    const firmware_frontier_options: frontier.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful and reclaim flash.
        .extra_info_on_calc_error = false,
        // Only the r47 firmware targets are built with -DCALCMODEL=USER_R47; the
        // C47 ones take the defines.h default. The r47 objects below override it.
        .calcmodel = user_c47,
        // Firmware build: use backToSystem tails and drop the PC allocation
        // tracking. old_hw (static freeMemoryRegions array) is set per board by
        // frontierDistributionStrip for DMCP; DMCP5 keeps the default (pointer).
        .dmcp_build = true,
        // OPTION_SAMPLEPGMS is #undef'd for NEW_HW and again in the block common
        // to packages 1-4, so no DMCP build carries the sample programs.
        .option_samplepgms = false,
    };
    const firmware_solve_options: solve.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const dmcp_shortint_objects = shortint.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_leaf_options);
    const dmcp5_shortint_objects = shortint.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_leaf_options);
    const dmcp_flags_state_objects = flags.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_flags_options);
    const dmcp5_flags_state_objects = flags.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_flags_options);
    // Per package: OPTION_ELLIPTIC, _BESSEL, _ORTHO, _DIST_NORMAL, _EIGEN and
    // _SLVP_POLY each empty the matching command bodies upstream, so the object
    // cannot be shared.
    const dmcp_math_command_wrapper_options = mathematicsPackageOptions(firmware_math_command_wrapper_options, dmcp_package);
    const dmcp_math_command_wrapper_objects = math_command_wrappers.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", dmcp_math_command_wrapper_options);
    const dmcp5_math_command_wrapper_objects = math_command_wrappers.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_math_command_wrapper_options);
    const dmcp_constants_objects = constants.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_constants_options);
    const dmcp5_constants_objects = constants.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_constants_options);
    const dmcp_tone_objects = tone.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_tone_options);
    const dmcp5_tone_objects = tone.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_tone_options);
    const dmcp_keyboard_state_board: keyboard_state.FirmwareModuleConfig = .{
        .board_source_dir = build_common.upstreamPathString(b, firmwareBoardSourceDir(.dmcp)),
        .sdk_include_dir = build_common.upstreamPathString(b, firmwareSdkIncludeDir(.dmcp)),
        .board_macro = "OLD_HW",
        .decnumber_fastmul = decnumber_fastmul,
        .generated_headers = .{
            .version_headers_dir = context.version_headers_dir,
            .softmenu_catalogs_dir = context.generated.softmenu_catalogs.dirname(),
            .constant_pointers_h_dir = context.generated.constant_pointers_h.dirname(),
        },
    };
    const firmware_keyboard_state_options: keyboard_state.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    };
    var firmware_r47_keyboard_state_options = firmware_keyboard_state_options;
    firmware_r47_keyboard_state_options.is_r47 = true;
    const dmcp_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", dmcp_keyboard_state_board, keyboardStateOptions(firmware_keyboard_state_options, dmcp_package));
    const dmcp5_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", .{
        .board_source_dir = build_common.upstreamPathString(b, firmwareBoardSourceDir(.dmcp5)),
        .sdk_include_dir = build_common.upstreamPathString(b, firmwareSdkIncludeDir(.dmcp5)),
        .board_macro = "NEW_HW",
        .decnumber_fastmul = decnumber_fastmul,
        .generated_headers = .{
            .version_headers_dir = context.version_headers_dir,
            .softmenu_catalogs_dir = context.generated.softmenu_catalogs.dirname(),
            .constant_pointers_h_dir = context.generated.constant_pointers_h.dirname(),
        },
    }, .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    });
    // R47 variants build the keyboard-state object with is_r47 = true so its DMCP
    // key ring buffer keyBuffer_pop applies convertKeyCode, matching the upstream
    // `#if CALCMODEL == USER_R47`. Same board config as the C47 object otherwise.
    const dmcpr47_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcpr47", dmcp_keyboard_state_board, keyboardStateOptions(firmware_r47_keyboard_state_options, dmcp_package));
    const dmcp5r47_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5r47", .{
        .board_source_dir = build_common.upstreamPathString(b, firmwareBoardSourceDir(.dmcp5)),
        .sdk_include_dir = build_common.upstreamPathString(b, firmwareSdkIncludeDir(.dmcp5)),
        .board_macro = "NEW_HW",
        .decnumber_fastmul = decnumber_fastmul,
        .generated_headers = .{
            .version_headers_dir = context.version_headers_dir,
            .softmenu_catalogs_dir = context.generated.softmenu_catalogs.dirname(),
            .constant_pointers_h_dir = context.generated.constant_pointers_h.dirname(),
        },
    }, .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
        .is_r47 = true,
        // Firmware is DMCP_BUILD, where upstream compiles the EXTRA_INFO console
        // hints out; match that to stay faithful.
        .extra_info_on_calc_error = false,
    });
    const dmcp_memory_state_objects = memory.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_memory_options);
    const dmcp5_memory_state_objects = memory.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_memory_options);
    // Four calc-state objects, not two: the object carries CALCMODEL, so the R47
    // firmware of a board cannot share the C47 one. state_old_hw still comes off
    // the name, and the r47 names keep it right ("dmcpr47" is OLD_HW, "dmcp5r47"
    // is not).
    const dmcp_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", calcStateOptions(firmware_calc_state_options, dmcp_package));
    const dmcpr47_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcpr47", calcStateOptions(firmware_r47_calc_state_options, dmcp_package));
    const dmcp5_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_calc_state_options);
    const dmcp5r47_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5r47", firmware_r47_calc_state_options);
    const dmcp_program_serialization_objects = program_serialization.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", programSerializationOptions(firmware_program_serialization_options, dmcp_package));
    const dmcp5_program_serialization_objects = program_serialization.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_program_serialization_options);
    // The frontier object embeds package-specific distribution stubbing, so it
    // must be built per package (the DM42 family) rather than shared. The
    // dmcp/dmcpr47 steps both build DMCP_PACKAGE=`dmcp_package`.
    const dmcp_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, b.fmt("dmcp-pkg{d}", .{dmcp_package}), frontierDistributionStrip(firmware_frontier_options, dmcp_package));
    const dmcp5_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_frontier_options);
    // USER_R47 (66) seeds calcModel to USER_R47f_g, which isR47FAM reads to pick
    // the R47 key remap and layout. Only the r47 targets get it.
    var firmware_r47_frontier_options = firmware_frontier_options;
    firmware_r47_frontier_options.calcmodel = user_r47;
    const dmcpr47_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, b.fmt("dmcpr47-pkg{d}", .{dmcp_package}), frontierDistributionStrip(firmware_r47_frontier_options, dmcp_package));
    const dmcp5r47_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5r47", firmware_r47_frontier_options);
    // OPTION_TVM_FORMULAS, _TVM_NEWTON, _TVM_AMORT and _SLVP_POLY differ between
    // the DM42 packages, so the solver object is per package the way the frontier
    // one is.
    const dmcp_solve_objects = solve.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", solverPackageOptions(firmware_solve_options, dmcp_package));
    const dmcp5_solve_objects = solve.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_solve_options);
    const dmcp_register_metadata_objects = register_metadata.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_register_metadata_options);
    const dmcp5_register_metadata_objects = register_metadata.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_register_metadata_options);
    const dmcp_stack_state_objects = stack.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_stack_options);
    const dmcp5_stack_state_objects = stack.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_stack_options);
    const dmcp_audio_runtime_object = addFirmwareAudioRuntimeObject(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_stack_options, .dmcp);
    const dmcp5_audio_runtime_object = addFirmwareAudioRuntimeObject(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_stack_options, .dmcp5);
    const dmcp_print_ir_runtime_object = addFirmwarePrintIrRuntimeObject(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_stack_options, .dmcp);
    const dmcp5_print_ir_runtime_object = addFirmwarePrintIrRuntimeObject(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_stack_options, .dmcp5);
    const dmcp_io_runtime_object = addFirmwareIoRuntimeObject(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_stack_options, .dmcp);
    const dmcp5_io_runtime_object = addFirmwareIoRuntimeObject(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_stack_options, .dmcp5);
    const dmcp = addFirmwareBuild(b, .{
        .step_name = "dmcp",
        .description = b.fmt("Build the C47 DMCP firmware (package {d}) without Make or Meson", .{dmcp_package}),
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = dmcp_package,
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_objects, dmcp_flags_state_objects, dmcp_math_command_wrapper_objects, dmcp_constants_objects, dmcp_tone_objects, dmcp_audio_runtime_object, dmcp_print_ir_runtime_object, dmcp_io_runtime_object, dmcp_keyboard_state_objects, dmcp_memory_state_objects, dmcp_calc_state_objects, dmcp_program_serialization_objects, dmcp_frontier_objects, dmcp_solve_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcpr47 = addFirmwareBuild(b, .{
        .step_name = "dmcpr47",
        .description = b.fmt("Build the R47 DMCP firmware (package {d}) without Make or Meson", .{dmcp_package}),
        .board = .dmcp,
        .program_name = "R47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_r47_qspi_crc.h",
        .qspi_macro = "USE_GEN_R47_QSPI_CRC",
        .pre_calcmodel_define = "USER_R47",
        .final_calcmodel_define = "USER_R47",
        .dmcp_package = dmcp_package,
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_objects, dmcp_flags_state_objects, dmcp_math_command_wrapper_objects, dmcp_constants_objects, dmcp_tone_objects, dmcp_audio_runtime_object, dmcp_print_ir_runtime_object, dmcp_io_runtime_object, dmcpr47_keyboard_state_objects, dmcp_memory_state_objects, dmcpr47_calc_state_objects, dmcp_program_serialization_objects, dmcpr47_frontier_objects, dmcp_solve_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp5 = addFirmwareBuild(b, .{
        .step_name = "dmcp5",
        .description = "Build the C47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "C47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp5, dmcp5_shortint_objects, dmcp5_flags_state_objects, dmcp5_math_command_wrapper_objects, dmcp5_constants_objects, dmcp5_tone_objects, dmcp5_audio_runtime_object, dmcp5_print_ir_runtime_object, dmcp5_io_runtime_object, dmcp5_keyboard_state_objects, dmcp5_memory_state_objects, dmcp5_calc_state_objects, dmcp5_program_serialization_objects, dmcp5_frontier_objects, dmcp5_solve_objects, dmcp5_register_metadata_objects, dmcp5_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp5r47 = addFirmwareBuild(b, .{
        .step_name = "dmcp5r47",
        .description = "Build the R47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "R47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .final_calcmodel_define = "USER_R47",
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp5, dmcp5_shortint_objects, dmcp5_flags_state_objects, dmcp5_math_command_wrapper_objects, dmcp5_constants_objects, dmcp5_tone_objects, dmcp5_audio_runtime_object, dmcp5_print_ir_runtime_object, dmcp5_io_runtime_object, dmcp5r47_keyboard_state_objects, dmcp5_memory_state_objects, dmcp5r47_calc_state_objects, dmcp5_program_serialization_objects, dmcp5r47_frontier_objects, dmcp5_solve_objects, dmcp5_register_metadata_objects, dmcp5_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp_packages = [_]u8{ 1, 2, 3 };
    var dmcp_variants: [dmcp_packages.len]VariantBuild = undefined;
    for (dmcp_packages, 0..) |package, index| {
        const variant_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, b.fmt("dmcp-variant-pkg{d}", .{package}), frontierDistributionStrip(firmware_frontier_options, package));
        const variant_math_command_wrapper_objects = math_command_wrappers.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", mathematicsPackageOptions(firmware_math_command_wrapper_options, package));
        const variant_solve_objects = solve.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", solverPackageOptions(firmware_solve_options, package));
        // OPTION_STRUCTURED_PGM differs between the DM42 packages too, so the
        // three state objects that read it are per package as well.
        const variant_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", dmcp_keyboard_state_board, keyboardStateOptions(firmware_keyboard_state_options, package));
        const variant_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", calcStateOptions(firmware_calc_state_options, package));
        const variant_program_serialization_objects = program_serialization.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", programSerializationOptions(firmware_program_serialization_options, package));
        const variant_build = addFirmwareBuild(b, .{
            .step_name = b.fmt("dmcp_pkg{d}", .{package}),
            .description = b.fmt("Build the C47 DMCP firmware for package {d} without Make or Meson", .{package}),
            .board = .dmcp,
            .program_name = "C47",
            .program_extension = ".pgm",
            .generated_qspi_header_name = "generated_qspi_crc.h",
            .qspi_macro = "USE_GEN_QSPI_CRC",
            .dmcp_package = package,
        }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_objects, dmcp_flags_state_objects, variant_math_command_wrapper_objects, dmcp_constants_objects, dmcp_tone_objects, dmcp_audio_runtime_object, dmcp_print_ir_runtime_object, dmcp_io_runtime_object, variant_keyboard_state_objects, dmcp_memory_state_objects, variant_calc_state_objects, variant_program_serialization_objects, variant_frontier_objects, variant_solve_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);
        dmcp_variants[index] = .{ .package = package, .build = variant_build };
    }

    const dmcp_pkgs_all = b.step("dmcp_pkgs_all", "Build DMCP package variants 1, 2, and 3 without Make or Meson");
    for (dmcp_variants) |variant| {
        dmcp_pkgs_all.dependOn(variant.build.step);
    }

    installFirmwareOutputs(b, "dmcp", dmcp);
    installFirmwareOutputs(b, "dmcpr47", dmcpr47);
    installFirmwareOutputs(b, "dmcp5", dmcp5);
    installFirmwareOutputs(b, "dmcp5r47", dmcp5r47);
    for (dmcp_variants) |variant| {
        installFirmwareOutputs(b, b.fmt("dmcp_pkg{d}", .{variant.package}), variant.build);
    }

    return .{
        .dmcp = dmcp,
        .dmcpr47 = dmcpr47,
        .dmcp5 = dmcp5,
        .dmcp5r47 = dmcp5r47,
        .dmcp_variants = dmcp_variants,
    };
}

fn defaultFirmwareLeafOptimize(optimize: std.lang.Optimize) std.lang.Optimize {
    _ = optimize;
    return .small;
}

fn addForceCrc32Tool(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "forcecrc32",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "dep/forcecrc32.c"), .flags = build_common.common_c_flags });
    return exe;
}

fn addArmGmpBuild(b: *std.Build, board: Board) ArmGmpOutputs {
    const gmp_repo_source = build_common.upstreamPathString(b, "subprojects/gmp-6.2.1");
    const script_prefix =
        \\board="$1"
        \\header_out="$2"
        \\lib_out="$3"
        \\impl_overlay="$4"
        \\mparam_overlay="$5"
        \\work_dir="$(cd "$(dirname "$lib_out")" && pwd)/gmp-work"
        \\repo_source="$PWD/
    ;
    const script_suffix =
        \\"
        \\source_dir="$repo_source"
        \\tarball="$work_dir/gmp-6.2.1.tar.bz2"
        \\download_urls=(
        \\  "https://gmplib.org/download/gmp/gmp-6.2.1.tar.bz2"
        \\  "https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.bz2"
        \\  "https://ftp.acc.umu.se/mirror/gnu.org/gnu/gmp/gmp-6.2.1.tar.bz2"
        \\  "https://ftpmirror.gnu.org/gmp/gmp-6.2.1.tar.bz2"
        \\  "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.bz2"
        \\)
        \\extract_root="$work_dir/src"
        \\build_dir="$work_dir/build-$board"
        \\install_dir="$work_dir/install-$board"
        \\jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
        \\build_cc="$(command -v cc || command -v gcc || true)"
        \\target_cc="arm-none-eabi-gcc --specs=nosys.specs"
        \\for tool in arm-none-eabi-gcc arm-none-eabi-ar arm-none-eabi-ranlib make python3 tar; do
        \\  command -v "$tool" >/dev/null 2>&1 || {
        \\    echo "missing required firmware tool: $tool" >&2
        \\    exit 1
        \\  }
        \\done
        \\if [[ -z "$build_cc" ]]; then
        \\  echo "missing required native build compiler: cc or gcc" >&2
        \\  exit 1
        \\fi
        \\mkdir -p "$work_dir"
        \\verify_gmp_hash() {
        \\  python3 - "$tarball" <<'PY'
        \\import hashlib
        \\import pathlib
        \\import sys
        \\path = pathlib.Path(sys.argv[1])
        \\expected = "eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c"
        \\digest = hashlib.sha256(path.read_bytes()).hexdigest()
        \\if digest != expected:
        \\    raise SystemExit(f"gmp-6.2.1 sha256 mismatch: {digest}")
        \\PY
        \\}
        \\download_gmp() {
        \\  local partial="$tarball.part"
        \\  local url
        \\  rm -f "$partial"
        \\  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        \\    echo "missing curl or wget to fetch gmp-6.2.1" >&2
        \\    exit 1
        \\  fi
        \\  for url in "${download_urls[@]}"; do
        \\    if command -v curl >/dev/null 2>&1; then
        \\      if curl -L --fail --retry 3 --retry-delay 2 --retry-all-errors --connect-timeout 15 --max-time 120 --output "$partial" "$url" && [[ -s "$partial" ]]; then
        \\        mv "$partial" "$tarball"
        \\        return 0
        \\      fi
        \\    else
        \\      if wget --tries=3 --timeout=15 -O "$partial" "$url" && [[ -s "$partial" ]]; then
        \\        mv "$partial" "$tarball"
        \\        return 0
        \\      fi
        \\    fi
        \\    rm -f "$partial"
        \\  done
        \\  return 1
        \\}
        \\case "$board" in
        \\  dmcp) cpu_flags=( -mthumb -march=armv7e-m -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 ) ;;
        \\  dmcp5) cpu_flags=( -mthumb -march=armv8-m.main+dsp -mcpu=cortex-m33 -mfloat-abi=hard -mfpu=fpv5-sp-d16 ) ;;
        \\  *) echo "unsupported firmware board: $board" >&2; exit 1 ;;
        \\esac
        \\if [[ -d "$source_dir" ]]; then
        \\  rm -rf "$extract_root"
        \\  mkdir -p "$extract_root"
        \\  cp -R "$source_dir" "$extract_root/gmp-6.2.1"
        \\  source_dir="$extract_root/gmp-6.2.1"
        \\else
        \\  if [[ -f "$tarball" ]] && ! verify_gmp_hash; then
        \\    rm -f "$tarball"
        \\  fi
        \\  if [[ ! -f "$tarball" ]]; then
        \\    for attempt in 1 2 3 4 5; do
        \\      if download_gmp && verify_gmp_hash; then
        \\        break
        \\      fi
        \\      rm -f "$tarball"
        \\      if [[ "$attempt" -eq 5 ]]; then
        \\        echo "failed to fetch a verified gmp-6.2.1 tarball" >&2
        \\        exit 1
        \\      fi
        \\    done
        \\  fi
        \\  rm -rf "$extract_root"
        \\  mkdir -p "$extract_root"
        \\  tar -xf "$tarball" -C "$extract_root"
        \\  source_dir="$extract_root/gmp-6.2.1"
        \\fi
        \\cp "$impl_overlay" "$source_dir/gmp-impl.h"
        \\cp "$mparam_overlay" "$source_dir/mpn/generic/gmp-mparam.h"
        \\build_triplet="$($source_dir/config.guess)"
        \\rm -rf "$build_dir" "$install_dir"
        \\mkdir -p "$build_dir" "$install_dir"
        \\(
        \\  cd "$build_dir"
        \\  CFLAGS="-Os -std=gnu17 -Wno-overflow ${cpu_flags[*]}" CC="$target_cc" AR=arm-none-eabi-ar RANLIB=arm-none-eabi-ranlib CC_FOR_BUILD="$build_cc" "$source_dir/configure" --build="$build_triplet" --host=arm-none-eabi --disable-assembly --disable-shared --disable-fft --disable-cxx --prefix="$install_dir"
        \\  make -j"$jobs"
        \\  make install
        \\)
        \\cp "$install_dir/include/gmp.h" "$header_out"
        \\cp "$install_dir/lib/libgmp.a" "$lib_out"
    ;
    const script = b.allocator.print("{s}{s}{s}", .{ script_prefix, gmp_repo_source, script_suffix }) catch @panic("OOM");

    const cmd = b.addSystemCommand(&.{ "bash", "-euo", "pipefail", "-c", script, "--" });
    cmd.setCwd(b.path("."));
    cmd.addFileInput(build_common.upstreamPath(b, "subprojects/gmp-6.2.1.wrap"));
    cmd.addArg(@tagName(board));
    const header = cmd.addOutputFileArg2("gmp.h", .{});
    const library = cmd.addOutputFileArg2("libgmp.a", .{});
    // Upstream's packagefiles overlay, which its wrap lays over the GMP source:
    // gmp-impl.h with the TMP_ALLOC stack/heap split lowered to 1 KB for the
    // DM42's stack grant, and a generic gmp-mparam.h that sets every threshold a
    // 3328-bit long integer can never reach to MP_SIZE_T_MAX, so those
    // algorithms leave the link. The source is staged in the work directory and
    // overlaid there, never in place.
    cmd.addFileArg2(build_common.upstreamPath(b, "subprojects/packagefiles/gmp-6.2.1/gmp-impl.h"), .{});
    cmd.addFileArg2(build_common.upstreamPath(b, "subprojects/packagefiles/gmp-6.2.1/mpn/generic/gmp-mparam.h"), .{});
    return .{ .header = header, .library = library };
}

fn addFirmwareBuild(
    b: *std.Build,
    config: Config,
    core_sources: []const []const u8,
    version_headers_dir: std.Build.LazyPath,
    generated: host_steps.GeneratedOutputs,
    arm_gmp: ArmGmpOutputs,
    shortint_objects: ShortIntObjects,
    flags_state_objects: FlagsStateObjects,
    math_command_wrapper_objects: MathCommandWrapperObjects,
    constants_objects: ConstantsObjects,
    tone_objects: ToneObjects,
    audio_runtime_object: *std.Build.Step.Compile,
    print_ir_runtime_object: *std.Build.Step.Compile,
    io_runtime_object: *std.Build.Step.Compile,
    keyboard_state_objects: KeyboardStateObjects,
    memory_state_objects: MemoryStateObjects,
    calc_state_objects: CalcStateObjects,
    program_serialization_objects: ProgramSerializationObjects,
    frontier_objects: FrontierObjects,
    solve_objects: SolveObjects,
    register_metadata_objects: RegisterMetadataObjects,
    stack_state_objects: StackStateObjects,
    forcecrc32: *std.Build.Step.Compile,
    decnumber_fastmul: bool,
) Build {
    const pre_build = addFirmwareElfBuild(b, config, .pre, core_sources, version_headers_dir, generated, arm_gmp, shortint_objects, flags_state_objects, math_command_wrapper_objects, constants_objects, tone_objects, audio_runtime_object, print_ir_runtime_object, io_runtime_object, keyboard_state_objects, memory_state_objects, calc_state_objects, program_serialization_objects, frontier_objects, solve_objects, register_metadata_objects, stack_state_objects, decnumber_fastmul, null);
    const pre_qspi_bad = addObjcopyBinary(b, pre_build.elf, b.fmt("{s}_pre_qspi_incorrect_crc.bin", .{config.program_name}), .{ .section_mode = .only });
    const pre_qspi = addModifyCrcStep(b, forcecrc32, pre_qspi_bad.path, b.fmt("{s}_pre_qspi.bin", .{config.program_name}));
    const generated_qspi_header = addGenerateQspiCrcStep(b, pre_qspi.path, config.generated_qspi_header_name);

    const final_build = addFirmwareElfBuild(b, config, .final, core_sources, version_headers_dir, generated, arm_gmp, shortint_objects, flags_state_objects, math_command_wrapper_objects, constants_objects, tone_objects, audio_runtime_object, print_ir_runtime_object, io_runtime_object, keyboard_state_objects, memory_state_objects, calc_state_objects, program_serialization_objects, frontier_objects, solve_objects, register_metadata_objects, stack_state_objects, decnumber_fastmul, generated_qspi_header.path);
    const flash = addObjcopyBinary(b, final_build.elf, b.fmt("{s}_flash.bin", .{config.program_name}), .{ .section_mode = .remove });
    const program = addPgmChecksumStep(b, flash.path, b.fmt("{s}{s}", .{ config.program_name, config.program_extension }));
    const qspi_bad = addObjcopyBinary(b, final_build.elf, b.fmt("{s}_qspi_incorrect_crc.bin", .{config.program_name}), .{ .section_mode = .only });
    const qspi = addModifyCrcStep(b, forcecrc32, qspi_bad.path, b.fmt("{s}_qspi.bin", .{config.program_name}));
    const section_sizes = addReadelfSectionSizesStep(b, final_build.elf, b.fmt("{s}_section_sizes.txt", .{config.program_name}));
    const size_report = addFirmwareSizeReportStep(b, config.board, section_sizes.path);

    const step = b.step(config.step_name, config.description);
    step.dependOn(program.step);
    step.dependOn(qspi.step);
    step.dependOn(&size_report.step);

    return .{
        .step = step,
        .objects = final_build.objects,
        .outputs = .{
            .program = program.path,
            .qspi = qspi.path,
            .map = final_build.map,
        },
    };
}

fn addFirmwareElfBuild(
    b: *std.Build,
    config: Config,
    phase: BuildPhase,
    core_sources: []const []const u8,
    version_headers_dir: std.Build.LazyPath,
    generated: host_steps.GeneratedOutputs,
    arm_gmp: ArmGmpOutputs,
    shortint_objects: ShortIntObjects,
    flags_state_objects: FlagsStateObjects,
    math_command_wrapper_objects: MathCommandWrapperObjects,
    constants_objects: ConstantsObjects,
    tone_objects: ToneObjects,
    audio_runtime_object: *std.Build.Step.Compile,
    print_ir_runtime_object: *std.Build.Step.Compile,
    io_runtime_object: *std.Build.Step.Compile,
    keyboard_state_objects: KeyboardStateObjects,
    memory_state_objects: MemoryStateObjects,
    calc_state_objects: CalcStateObjects,
    program_serialization_objects: ProgramSerializationObjects,
    frontier_objects: FrontierObjects,
    solve_objects: SolveObjects,
    register_metadata_objects: RegisterMetadataObjects,
    stack_state_objects: StackStateObjects,
    decnumber_fastmul: bool,
    generated_qspi_header: ?std.Build.LazyPath,
) ElfBuildOutputs {
    const cmd = b.addSystemCommand(&.{"arm-none-eabi-gcc"});
    cmd.setCwd(b.path("."));

    for (firmwareArchFlags(config.board)) |flag| cmd.addArg(flag);
    for (firmware_common_c_flags) |flag| cmd.addArg(flag);
    if (firmwareBoardMacro(config.board)) |flag| cmd.addArg(flag);
    if (decnumber_fastmul) cmd.addArg("-DDECNUMBER_FASTMUL=1");
    if (config.board == .dmcp) {
        if (config.dmcp_package) |package| cmd.addArg(b.fmt("-DDMCP_PACKAGE={d}", .{package}));
    }

    const calcmodel_define = switch (phase) {
        .pre => config.pre_calcmodel_define,
        .final => config.final_calcmodel_define,
    };
    if (calcmodel_define) |define| cmd.addArg(b.fmt("-DCALCMODEL={s}", .{define}));
    if (phase == .final) cmd.addArg(b.fmt("-D{s}", .{config.qspi_macro}));

    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, "dep/decNumberICU")}));
    cmd.addArg("-Ibridge");
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, "src/c47")}));
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, firmwareBoardSourceDir(config.board))}));
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, firmwareSdkIncludeDir(config.board))}));
    cmd.addDirectoryArg2(version_headers_dir, .{ .prefix = "-I" });
    cmd.addDirectoryArg2(generated.softmenu_catalogs.dirname(), .{ .prefix = "-I" });
    cmd.addDirectoryArg2(generated.constant_pointers_h.dirname(), .{ .prefix = "-I" });
    cmd.addDirectoryArg2(arm_gmp.header.dirname(), .{ .prefix = "-I" });
    cmd.addFileInput(generated.softmenu_catalogs);
    cmd.addFileInput(generated.constant_pointers_h);
    cmd.addFileInput(arm_gmp.header);
    if (generated_qspi_header) |header| {
        cmd.addDirectoryArg2(header.dirname(), .{ .prefix = "-I" });
        cmd.addFileInput(header);
    }

    cmd.addArg(build_common.upstreamPathString(b, firmwareSdkSyscallsSource(config.board)));
    cmd.addArg(build_common.upstreamPathString(b, firmwareSdkStartupSource(config.board)));
    for (build_common.decnumber_sources) |source| cmd.addArg(build_common.upstreamPathString(b, b.fmt("dep/{s}", .{source})));
    std.debug.assert(core_sources.len == 0);
    const objects: FirmwareObjects = .{
        .flags_state = flags_state_objects,
        .math_command_wrappers = math_command_wrapper_objects,
        .constants = constants_objects,
        .tone = tone_objects,
        .audio_runtime = audio_runtime_object,
        .print_ir_runtime = print_ir_runtime_object,
        .io_runtime = io_runtime_object,
        .keyboard_state = keyboard_state_objects,
        .memory_state = memory_state_objects,
        .calc_state = calc_state_objects,
        .program_serialization = program_serialization_objects,
        .frontier = frontier_objects,
        .solve = solve_objects,
        .register_metadata = register_metadata_objects,
        .shortint = shortint_objects,
        .stack_state = stack_state_objects,
    };
    objects.addToCommand(cmd);
    for (firmwareBoardHalSources(config.board)) |source| cmd.addArg(build_common.upstreamPathString(b, source));
    cmd.addFileArg2(generated.raster_fonts_data, .{});
    cmd.addFileArg2(generated.constant_pointers_c, .{});
    cmd.addFileArg2(generated.constant_pointers2_c, .{});

    for (firmware_common_link_flags) |flag| cmd.addArg(flag);
    for (firmwareLinkFlags(config.board)) |flag| cmd.addArg(flag);
    // Discard .ARM.exidx (see fragment) before the upstream script so QSPI-placed
    // owner code does not blow the PREL31 exidx relocation range.
    cmd.addFileArg2(b.path("build/firmware/discard_exidx.ld"), .{ .prefix = "-T" });
    cmd.addFileArg2(build_common.upstreamPath(b, firmwareBoardLinkerScript(config.board)), .{ .prefix = "-T" });
    const map_name = switch (phase) {
        .pre => b.fmt("{s}_pre.map", .{config.program_name}),
        .final => b.fmt("{s}.map", .{config.map_name}),
    };
    const map = cmd.addOutputFileArg2(map_name, .{ .prefix = "-Wl,-Map=" });
    cmd.addArg("-o");
    const elf = cmd.addOutputFileArg2(switch (phase) {
        .pre => b.fmt("{s}_pre.elf", .{config.program_name}),
        .final => b.fmt("{s}.elf", .{config.program_name}),
    }, .{});
    cmd.addDirectoryArg2(arm_gmp.library.dirname(), .{ .prefix = "-L" });
    cmd.addArg("-lgmp");
    cmd.addFileInput(arm_gmp.library);

    return .{ .elf = elf, .map = map, .objects = objects };
}

fn resolveFirmwareTarget(b: *std.Build, board: Board) std.Build.ResolvedTarget {
    return switch (board) {
        .dmcp => b.resolveTargetQuery(.{
            .cpu_arch = .thumb,
            .os_tag = .freestanding,
            .abi = .eabihf,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        }),
        .dmcp5 => b.resolveTargetQuery(.{
            .cpu_arch = .thumb,
            .os_tag = .freestanding,
            .abi = .eabihf,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m33 },
        }),
    };
}

fn addObjcopyBinary(
    b: *std.Build,
    input: std.Build.LazyPath,
    basename: []const u8,
    options: ObjcopyOptions,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{"arm-none-eabi-objcopy"});
    cmd.setCwd(b.path("."));
    switch (options.section_mode) {
        .only => cmd.addArgs(&.{ "--only-section", ".qspi" }),
        .remove => cmd.addArgs(&.{ "--remove-section", ".qspi" }),
    }
    cmd.addArgs(&.{ "-O", "binary" });
    cmd.addFileArg2(input, .{});
    const output = cmd.addOutputFileArg2(basename, .{});
    return .{ .step = &cmd.step, .path = output };
}

fn firmwareLibraryFnBase(board: Board) usize {
    return switch (board) {
        .dmcp => 0x08000201,
        .dmcp5 => 0x08000301,
    };
}

fn firmwareSdbBase(board: Board) usize {
    return switch (board) {
        .dmcp => 0x10002000,
        .dmcp5 => 0x20000000,
    };
}

fn addFirmwarePrintIrRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("build/firmware_print_ir_runtime.zig"),
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
    build_options.addOption(usize, "library_fn_base", firmwareLibraryFnBase(board));
    module.addOptions("firmware_print_ir_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-firmware-print-ir-runtime", .{name_prefix}),
        .root_module = module,
    });
}

fn addFirmwareAudioRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("build/firmware_audio_runtime.zig"),
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
    build_options.addOption(usize, "library_fn_base", firmwareLibraryFnBase(board));
    module.addOptions("firmware_audio_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-firmware-audio-runtime", .{name_prefix}),
        .root_module = module,
    });
}

fn addFirmwareIoRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("build/firmware_io_runtime.zig"),
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
    build_options.addOption(usize, "library_fn_base", firmwareLibraryFnBase(board));
    build_options.addOption(usize, "sdb_base", firmwareSdbBase(board));
    module.addOptions("firmware_io_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-firmware-io-runtime", .{name_prefix}),
        .root_module = module,
    });
}

fn addModifyCrcStep(
    b: *std.Build,
    forcecrc32: *std.Build.Step.Compile,
    input: std.Build.LazyPath,
    basename: []const u8,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", build_common.upstreamPathString(b, "tools/modify_crc") });
    cmd.setCwd(b.path("."));
    cmd.addArtifactArg2(forcecrc32, .{});
    cmd.addFileArg2(input, .{});
    const output = cmd.addOutputFileArg2(basename, .{});
    return .{ .step = &cmd.step, .path = output };
}

fn addGenerateQspiCrcStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", build_common.upstreamPathString(b, "tools/gen_qspi_crc") });
    cmd.setCwd(b.path("."));
    cmd.addFileArg2(input, .{});
    const output = cmd.addOutputFileArg2(basename, .{});
    return .{ .step = &cmd.step, .path = output };
}

fn addPgmChecksumStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", build_common.upstreamPathString(b, "tools/add_pgm_chsum") });
    cmd.setCwd(b.path("."));
    cmd.addFileArg2(input, .{});
    const output = cmd.addOutputFileArg2(basename, .{});
    return .{ .step = &cmd.step, .path = output };
}

fn addReadelfSectionSizesStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "arm-none-eabi-readelf", "-l" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg2(input, .{});
    const output = cmd.captureStdOut(.{ .basename = basename });
    return .{ .step = &cmd.step, .path = output };
}

fn addFirmwareSizeReportStep(b: *std.Build, board: Board, section_sizes: std.Build.LazyPath) *std.Build.Step.Run {
    // z47 owns this reporter. Upstream's copy indexes readelf fields without
    // bounds checks and dies on the section tables this toolchain emits, and it is
    // 88 lines of size printing -- not worth carrying a patch inside the vendored
    // tree for, which is what it used to be.
    const cmd = b.addSystemCommand(&.{ "python3", "build/tools/size.py" });
    cmd.setCwd(b.path("."));
    if (board == .dmcp5) cmd.addArg("dmcp5");
    cmd.addFileArg2(section_sizes, .{});
    return cmd;
}

fn installFirmwareOutputs(b: *std.Build, subdir: []const u8, firmware_build: Build) void {
    const program_install = b.addInstallFileWithDir(firmware_build.outputs.program, .prefix, b.fmt("firmware/{s}/{f}", .{ subdir, firmware_build.outputs.program }));
    const qspi_install = b.addInstallFileWithDir(firmware_build.outputs.qspi, .prefix, b.fmt("firmware/{s}/{f}", .{ subdir, firmware_build.outputs.qspi }));
    const map_install = b.addInstallFileWithDir(firmware_build.outputs.map, .prefix, b.fmt("firmware/{s}/{f}", .{ subdir, firmware_build.outputs.map }));
    firmware_build.step.dependOn(&program_install.step);
    firmware_build.step.dependOn(&qspi_install.step);
    firmware_build.step.dependOn(&map_install.step);
}

fn firmwareArchFlags(board: Board) []const []const u8 {
    return switch (board) {
        .dmcp => &.{
            "-mthumb",
            "-march=armv7e-m",
            "-mcpu=cortex-m4",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
            "-Os",
            "-s",
            "-fsigned-char",
            "-ffunction-sections",
            "-fdata-sections",
            "-fno-strict-aliasing",
            "-fmerge-all-constants",
        },
        .dmcp5 => &.{
            "-mthumb",
            "-march=armv8-m.main+dsp",
            "-mcpu=cortex-m33",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
            "-Os",
            "-s",
            "-fsigned-char",
            "-ffunction-sections",
            "-fdata-sections",
            "-fno-strict-aliasing",
            "-fmerge-all-constants",
        },
    };
}

fn firmwareLinkFlags(board: Board) []const []const u8 {
    return switch (board) {
        .dmcp => &.{
            "-mthumb",
            "-march=armv7e-m",
            "-mcpu=cortex-m4",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
            "-Wl,--no-undefined",
        },
        .dmcp5 => &.{
            "-mthumb",
            "-march=armv8-m.main+dsp",
            "-mcpu=cortex-m33",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
            "-Wl,--no-undefined",
        },
    };
}

fn firmwareBoardHalSources(board: Board) []const []const u8 {
    return switch (board) {
        // No board HAL C: every upstream hal/*.c has a Zig owner. console.c's
        // console sinks live in build/firmware_console_runtime.zig, carried
        // into the link by firmware_io_runtime.zig.
        .dmcp => &[_][]const u8{},
        .dmcp5 => &[_][]const u8{},
    };
}

fn firmwareBoardMacro(board: Board) ?[]const u8 {
    return switch (board) {
        .dmcp => "-DOLD_HW",
        .dmcp5 => "-DNEW_HW",
    };
}

fn firmwareBoardSourceDir(board: Board) []const u8 {
    return switch (board) {
        .dmcp => "src/c47-dmcp",
        .dmcp5 => "src/c47-dmcp5",
    };
}

fn firmwareBoardLinkerScript(board: Board) []const u8 {
    return switch (board) {
        .dmcp => "src/c47-dmcp/stm32_program.ld",
        .dmcp5 => "src/c47-dmcp5/stm32_program.ld",
    };
}

fn firmwareSdkIncludeDir(board: Board) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp",
        .dmcp5 => "dep/DMCP5_SDK/dmcp",
    };
}

fn firmwareSdkSyscallsSource(board: Board) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp/sys/pgm_syscalls.c",
        .dmcp5 => "dep/DMCP5_SDK/dmcp/sys/pgm_syscalls.c",
    };
}

fn firmwareSdkStartupSource(board: Board) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp/startup_pgm.s",
        .dmcp5 => "dep/DMCP5_SDK/dmcp/startup_pgm.s",
    };
}
