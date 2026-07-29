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
        cmd.addFileArg(self.audio_runtime.getEmittedBin());
        cmd.addFileArg(self.print_ir_runtime.getEmittedBin());
        cmd.addFileArg(self.io_runtime.getEmittedBin());
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

// Apply the per-package distribution strip flags to a frontier build options
// value. Mirrors the upstream defines.h TWO_FILE_PGM package blocks: the 17B
// cluster (cauchy/weibull/logistic/exponential) is stripped on packages 2 and 4,
// and the 17C cluster (pareto/uniform) on packages 2, 3 and 4. A null package
// (e.g. DMCP5) keeps every distribution.
fn frontierDistributionStrip(base: frontier.RuntimeObjectOptions, dmcp_package: ?u8) frontier.RuntimeObjectOptions {
    var opts = base;
    // The DMCP (DM42) family is OLD_HW, where freeMemoryRegions is a static
    // array rather than a pointer. DMCP5 (NEW_HW) keeps the pointer layout.
    opts.old_hw = true;
    const pkg = dmcp_package orelse return opts;
    opts.strip_16 = true; // SAVE_SPACE_DM42_16 (normal) set on every DM42 package
    opts.strip_17 = true; // SAVE_SPACE_DM42_17 is set on every DM42 package
    opts.strip_17b = (pkg == 2 or pkg == 4);
    opts.strip_17c = (pkg == 2 or pkg == 3 or pkg == 4);
    // SAVE_SPACE_DM42_15 (all distributions, drops the DISTR softmenu entry from
    // menu_PROB) is defined only for package 4. Mirrors the upstream defines.h.
    opts.strip_15 = (pkg == 4);
    // SAVE_SPACE_DM42_21_HP35 (drops the SetHP35 dev-profile from menu_Dev) is
    // defined only for package 1. Mirrors the upstream defines.h.
    opts.strip_21_hp35 = (pkg == 1);
    // SAVE_SPACE_DM42_12{ORTHO,BESSEL,ELLIP} (strike-out savedspace cases) are
    // defined together for the NOBESSEL_NOORTHO packages 1, 3 and 4.
    opts.strip_ortho_bessel_ellip = (pkg == 1 or pkg == 3 or pkg == 4);
    // OPTION_ELEC is #undef'd for DMCP packages 1, 2 and 4; only package 3 keeps
    // the ELEC functions (fnJM body). Mirrors the upstream defines.h package
    // blocks.
    opts.option_elec = (pkg == 3);
    // IR_PRINTING is #undef'd for every DMCP TWO_FILE package (1, 2, 3, 4).
    opts.ir_printing = false;
    // OPTION_VECTOR is #undef'd for DMCP packages 1, 2 and 4; package 3 keeps it.
    opts.option_vector = (pkg == 3);
    return opts;
}

pub fn registerSteps(
    b: *std.Build,
    context: host_steps.Context,
    optimize: std.builtin.OptimizeMode,
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
    };
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
    };
    const firmware_stack_options: stack.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
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
        // The DMCP firmware is built with -DCALCMODEL=USER_R47 (66), so calcModel
        // must seed to USER_R47f_g -- matching upstream's static init.
        .calcmodel = 66,
        // Firmware build: use backToSystem tails and drop the PC allocation
        // tracking. old_hw (static freeMemoryRegions array) is set per board by
        // frontierDistributionStrip for DMCP; DMCP5 keeps the default (pointer).
        .dmcp_build = true,
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
    const dmcp_math_command_wrapper_objects = math_command_wrappers.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_math_command_wrapper_options);
    const dmcp5_math_command_wrapper_objects = math_command_wrappers.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_math_command_wrapper_options);
    const dmcp_constants_objects = constants.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_constants_options);
    const dmcp5_constants_objects = constants.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_constants_options);
    const dmcp_tone_objects = tone.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_tone_options);
    const dmcp5_tone_objects = tone.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_tone_options);
    const dmcp_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", .{
        .board_source_dir = build_common.upstreamPathString(b, firmwareBoardSourceDir(.dmcp)),
        .sdk_include_dir = build_common.upstreamPathString(b, firmwareSdkIncludeDir(.dmcp)),
        .board_macro = "OLD_HW",
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
    });
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
    });
    // R47 variants build the keyboard-state object with is_r47 = true so its DMCP
    // key ring buffer keyBuffer_pop applies convertKeyCode, matching the upstream
    // `#if CALCMODEL == USER_R47`. Same board config as the C47 object otherwise.
    const dmcpr47_keyboard_state_objects = keyboard_state.addFirmwareRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcpr47", .{
        .board_source_dir = build_common.upstreamPathString(b, firmwareBoardSourceDir(.dmcp)),
        .sdk_include_dir = build_common.upstreamPathString(b, firmwareSdkIncludeDir(.dmcp)),
        .board_macro = "OLD_HW",
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
    });
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
    });
    const dmcp_memory_state_objects = memory.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_memory_options);
    const dmcp5_memory_state_objects = memory.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_memory_options);
    const dmcp_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_calc_state_options);
    const dmcp5_calc_state_objects = calc_state.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_calc_state_options);
    const dmcp_program_serialization_objects = program_serialization.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_program_serialization_options);
    const dmcp5_program_serialization_objects = program_serialization.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_program_serialization_options);
    // The frontier object embeds package-specific distribution stubbing, so it
    // must be built per package (the DM42 family) rather than shared. The
    // dmcp/dmcpr47 steps both build DMCP_PACKAGE=`dmcp_package`.
    const dmcp_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, b.fmt("dmcp-pkg{d}", .{dmcp_package}), frontierDistributionStrip(firmware_frontier_options, dmcp_package));
    const dmcp5_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_frontier_options);
    const dmcp_solve_objects = solve.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_solve_options);
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
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_objects, dmcp_flags_state_objects, dmcp_math_command_wrapper_objects, dmcp_constants_objects, dmcp_tone_objects, dmcp_audio_runtime_object, dmcp_print_ir_runtime_object, dmcp_io_runtime_object, dmcpr47_keyboard_state_objects, dmcp_memory_state_objects, dmcp_calc_state_objects, dmcp_program_serialization_objects, dmcp_frontier_objects, dmcp_solve_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);

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
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp5, dmcp5_shortint_objects, dmcp5_flags_state_objects, dmcp5_math_command_wrapper_objects, dmcp5_constants_objects, dmcp5_tone_objects, dmcp5_audio_runtime_object, dmcp5_print_ir_runtime_object, dmcp5_io_runtime_object, dmcp5r47_keyboard_state_objects, dmcp5_memory_state_objects, dmcp5_calc_state_objects, dmcp5_program_serialization_objects, dmcp5_frontier_objects, dmcp5_solve_objects, dmcp5_register_metadata_objects, dmcp5_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp_packages = [_]u8{ 1, 2, 3 };
    var dmcp_variants: [dmcp_packages.len]VariantBuild = undefined;
    for (dmcp_packages, 0..) |package, index| {
        const variant_frontier_objects = frontier.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, b.fmt("dmcp-variant-pkg{d}", .{package}), frontierDistributionStrip(firmware_frontier_options, package));
        const variant_build = addFirmwareBuild(b, .{
            .step_name = b.fmt("dmcp_pkg{d}", .{package}),
            .description = b.fmt("Build the C47 DMCP firmware for package {d} without Make or Meson", .{package}),
            .board = .dmcp,
            .program_name = "C47",
            .program_extension = ".pgm",
            .generated_qspi_header_name = "generated_qspi_crc.h",
            .qspi_macro = "USE_GEN_QSPI_CRC",
            .dmcp_package = package,
        }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_objects, dmcp_flags_state_objects, dmcp_math_command_wrapper_objects, dmcp_constants_objects, dmcp_tone_objects, dmcp_audio_runtime_object, dmcp_print_ir_runtime_object, dmcp_io_runtime_object, dmcp_keyboard_state_objects, dmcp_memory_state_objects, dmcp_calc_state_objects, dmcp_program_serialization_objects, variant_frontier_objects, dmcp_solve_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);
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

fn defaultFirmwareLeafOptimize(optimize: std.builtin.OptimizeMode) std.builtin.OptimizeMode {
    _ = optimize;
    return .ReleaseSmall;
}

fn addForceCrc32Tool(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
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
        \\work_dir="$(dirname "$lib_out")/gmp-work"
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
        \\if [[ ! -d "$source_dir" ]]; then
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
        \\build_triplet="$($source_dir/config.guess)"
        \\rm -rf "$build_dir" "$install_dir"
        \\mkdir -p "$build_dir" "$install_dir"
        \\(
        \\  cd "$build_dir"
        \\  CFLAGS="-Os ${cpu_flags[*]}" CC="$target_cc" AR=arm-none-eabi-ar RANLIB=arm-none-eabi-ranlib CC_FOR_BUILD="$build_cc" "$source_dir/configure" --build="$build_triplet" --host=arm-none-eabi --disable-assembly --disable-shared --disable-fft --disable-cxx --prefix="$install_dir"
        \\  make -j"$jobs"
        \\  make install
        \\)
        \\cp "$install_dir/include/gmp.h" "$header_out"
        \\cp "$install_dir/lib/libgmp.a" "$lib_out"
    ;
    const script = std.fmt.allocPrint(b.allocator, "{s}{s}{s}", .{ script_prefix, gmp_repo_source, script_suffix }) catch @panic("OOM");

    const cmd = b.addSystemCommand(&.{ "bash", "-euo", "pipefail", "-c", script, "--" });
    cmd.setCwd(b.path("."));
    cmd.addFileInput(build_common.upstreamPath(b, "subprojects/gmp-6.2.1.wrap"));
    cmd.addArg(@tagName(board));
    const header = cmd.addOutputFileArg("gmp.h");
    const library = cmd.addOutputFileArg("libgmp.a");
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
    cmd.addArg("-Izig_bridge");
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, "src/c47")}));
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, firmwareBoardSourceDir(config.board))}));
    cmd.addArg(b.fmt("-I{s}", .{build_common.upstreamPathString(b, firmwareSdkIncludeDir(config.board))}));
    cmd.addPrefixedDirectoryArg("-I", version_headers_dir);
    cmd.addPrefixedDirectoryArg("-I", generated.softmenu_catalogs.dirname());
    cmd.addPrefixedDirectoryArg("-I", generated.constant_pointers_h.dirname());
    cmd.addPrefixedDirectoryArg("-I", arm_gmp.header.dirname());
    cmd.addFileInput(generated.softmenu_catalogs);
    cmd.addFileInput(generated.constant_pointers_h);
    cmd.addFileInput(arm_gmp.header);
    if (generated_qspi_header) |header| {
        cmd.addPrefixedDirectoryArg("-I", header.dirname());
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
    cmd.addFileArg(generated.raster_fonts_data);
    cmd.addFileArg(generated.constant_pointers_c);
    cmd.addFileArg(generated.constant_pointers2_c);

    for (firmware_common_link_flags) |flag| cmd.addArg(flag);
    for (firmwareLinkFlags(config.board)) |flag| cmd.addArg(flag);
    // Discard .ARM.exidx (see fragment) before the upstream script so QSPI-placed
    // owner code does not blow the PREL31 exidx relocation range.
    cmd.addPrefixedFileArg("-T", b.path("zig_build/firmware/discard_exidx.ld"));
    cmd.addPrefixedFileArg("-T", build_common.upstreamPath(b, firmwareBoardLinkerScript(config.board)));
    const map_name = switch (phase) {
        .pre => b.fmt("{s}_pre.map", .{config.program_name}),
        .final => b.fmt("{s}.map", .{config.map_name}),
    };
    const map = cmd.addPrefixedOutputFileArg("-Wl,-Map=", map_name);
    cmd.addArg("-o");
    const elf = cmd.addOutputFileArg(switch (phase) {
        .pre => b.fmt("{s}_pre.elf", .{config.program_name}),
        .final => b.fmt("{s}.elf", .{config.program_name}),
    });
    cmd.addPrefixedDirectoryArg("-L", arm_gmp.library.dirname());
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
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
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
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_build/firmware_print_ir_runtime.zig"),
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
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_build/firmware_audio_runtime.zig"),
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
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: stack.RuntimeObjectOptions,
    board: Board,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("zig_build/firmware_io_runtime.zig"),
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
    cmd.addArtifactArg(forcecrc32);
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addGenerateQspiCrcStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", build_common.upstreamPathString(b, "tools/gen_qspi_crc") });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addPgmChecksumStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", build_common.upstreamPathString(b, "tools/add_pgm_chsum") });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addReadelfSectionSizesStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "arm-none-eabi-readelf", "-l" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.captureStdOut(.{ .basename = basename });
    return .{ .step = &cmd.step, .path = output };
}

fn addFirmwareSizeReportStep(b: *std.Build, board: Board, section_sizes: std.Build.LazyPath) *std.Build.Step.Run {
    const cmd = b.addSystemCommand(&.{ "python3", build_common.upstreamPathString(b, "tools/size.py") });
    cmd.setCwd(b.path("."));
    if (board == .dmcp5) cmd.addArg("dmcp5");
    cmd.addFileArg(section_sizes);
    return cmd;
}

fn installFirmwareOutputs(b: *std.Build, subdir: []const u8, firmware_build: Build) void {
    const program_install = b.addInstallFileWithDir(firmware_build.outputs.program, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.program.getDisplayName()) }));
    const qspi_install = b.addInstallFileWithDir(firmware_build.outputs.qspi, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.qspi.getDisplayName()) }));
    const map_install = b.addInstallFileWithDir(firmware_build.outputs.map, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.map.getDisplayName()) }));
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
        // hal/console.c is the one board HAL source z47 still compiles from
        // upstream rather than porting: it exists purely to keep newlib's
        // buffered stdio out of the link. There is no console on DMCP hardware,
        // so it defines printf/iprintf/puts/putchar/fputs/fputc/fprintf/
        // fiprintf/fflush/_fflush_r as discards, which also intercepts printing
        // from inside gmp and assert. Without it the link resolves those against
        // libc_nano and drags in findfp.o -- 316 bytes of __sf FILE structs in
        // SRAM2, which the DM42 cannot afford. The 4697e526a resync added an
        // exit() override to the dmcp copy for the same reason (newlib's exit
        // pulls __stdio_exit_handler, hence findfp). Porting these to Zig would
        // fork a file whose whole job is to match newlib's ABI, so compile
        // upstream's own and let future upstream changes to it land with the
        // import.
        .dmcp => &[_][]const u8{"src/c47-dmcp/hal/console.c"},
        .dmcp5 => &[_][]const u8{"src/c47-dmcp5/hal/console.c"},
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
