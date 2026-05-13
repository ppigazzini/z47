const std = @import("std");
const build_common = @import("common.zig");
const host_steps = @import("host.zig");
const shortint_rewrites = @import("leaf/shortint_rewrites.zig");
const flags_rewrites = @import("state/flags_rewrites.zig");
const memory_rewrites = @import("state/memory_rewrites.zig");
const register_metadata_rewrites = @import("state/register_metadata_rewrites.zig");
const stack_rewrites = @import("state/stack_rewrites.zig");

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

const ShortIntLeafObjects = shortint_rewrites.RuntimeObjects;
const FlagsStateObjects = flags_rewrites.RuntimeObjects;
const MemoryStateObjects = memory_rewrites.RuntimeObjects;
const RegisterMetadataObjects = register_metadata_rewrites.RuntimeObjects;
const StackStateObjects = stack_rewrites.RuntimeObjects;

const BuildPhase = enum {
    pre,
    final,
};

const ElfBuildOutputs = struct {
    elf: std.Build.LazyPath,
    map: std.Build.LazyPath,
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
    const firmware_leaf_options: shortint_rewrites.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_flags_options: flags_rewrites.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_memory_options: memory_rewrites.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_register_metadata_options: register_metadata_rewrites.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const firmware_stack_options: stack_rewrites.RuntimeObjectOptions = .{
        .strip = true,
        .unwind_tables = .none,
        .stack_protector = false,
        .stack_check = false,
        .omit_frame_pointer = true,
        .error_tracing = false,
    };
    const dmcp_shortint_leaf_objects = shortint_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_leaf_options);
    const dmcp5_shortint_leaf_objects = shortint_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_leaf_options);
    const dmcp_flags_state_objects = flags_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_flags_options);
    const dmcp5_flags_state_objects = flags_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_flags_options);
    const dmcp_memory_state_objects = memory_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_memory_options);
    const dmcp5_memory_state_objects = memory_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_memory_options);
    const dmcp_register_metadata_objects = register_metadata_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_register_metadata_options);
    const dmcp5_register_metadata_objects = register_metadata_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_register_metadata_options);
    const dmcp_stack_state_objects = stack_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp), firmware_leaf_optimize, "dmcp", firmware_stack_options);
    const dmcp5_stack_state_objects = stack_rewrites.addRuntimeObjectsWithOptions(b, resolveFirmwareTarget(b, .dmcp5), firmware_leaf_optimize, "dmcp5", firmware_stack_options);

    const dmcp = addFirmwareBuild(b, .{
        .step_name = "dmcp",
        .description = b.fmt("Build the C47 DMCP firmware (package {d}) without Make or Meson", .{dmcp_package}),
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = dmcp_package,
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_leaf_objects, dmcp_flags_state_objects, dmcp_memory_state_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);

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
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_leaf_objects, dmcp_flags_state_objects, dmcp_memory_state_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp5 = addFirmwareBuild(b, .{
        .step_name = "dmcp5",
        .description = "Build the C47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "C47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp5, dmcp5_shortint_leaf_objects, dmcp5_flags_state_objects, dmcp5_memory_state_objects, dmcp5_register_metadata_objects, dmcp5_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp5r47 = addFirmwareBuild(b, .{
        .step_name = "dmcp5r47",
        .description = "Build the R47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "R47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .final_calcmodel_define = "USER_R47",
    }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp5, dmcp5_shortint_leaf_objects, dmcp5_flags_state_objects, dmcp5_memory_state_objects, dmcp5_register_metadata_objects, dmcp5_stack_state_objects, forcecrc32, decnumber_fastmul);

    const dmcp_packages = [_]u8{ 1, 2, 3 };
    var dmcp_variants: [dmcp_packages.len]VariantBuild = undefined;
    for (dmcp_packages, 0..) |package, index| {
        const variant_build = addFirmwareBuild(b, .{
            .step_name = b.fmt("dmcp_pkg{d}", .{package}),
            .description = b.fmt("Build the C47 DMCP firmware for package {d} without Make or Meson", .{package}),
            .board = .dmcp,
            .program_name = "C47",
            .program_extension = ".pgm",
            .generated_qspi_header_name = "generated_qspi_crc.h",
            .qspi_macro = "USE_GEN_QSPI_CRC",
            .dmcp_package = package,
        }, context.core_sources, context.version_headers_dir, context.generated, arm_gmp_dmcp, dmcp_shortint_leaf_objects, dmcp_flags_state_objects, dmcp_memory_state_objects, dmcp_register_metadata_objects, dmcp_stack_state_objects, forcecrc32, decnumber_fastmul);
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
    return switch (optimize) {
        .Debug => .ReleaseSmall,
        else => optimize,
    };
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
    exe.root_module.addCSourceFile(.{ .file = b.path("dep/forcecrc32.c"), .flags = build_common.common_c_flags });
    return exe;
}

fn addArmGmpBuild(b: *std.Build, board: Board) ArmGmpOutputs {
    const script =
        \\board="$1"
        \\header_out="$2"
        \\lib_out="$3"
        \\work_dir="$(dirname "$lib_out")/gmp-work"
        \\repo_source="$PWD/subprojects/gmp-6.2.1"
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

    const cmd = b.addSystemCommand(&.{ "bash", "-euo", "pipefail", "-c", script, "--" });
    cmd.setCwd(b.path("."));
    cmd.addFileInput(b.path("subprojects/gmp-6.2.1.wrap"));
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
    shortint_leaf_objects: ShortIntLeafObjects,
    flags_state_objects: FlagsStateObjects,
    memory_state_objects: MemoryStateObjects,
    register_metadata_objects: RegisterMetadataObjects,
    stack_state_objects: StackStateObjects,
    forcecrc32: *std.Build.Step.Compile,
    decnumber_fastmul: bool,
) Build {
    const pre_build = addFirmwareElfBuild(b, config, .pre, core_sources, version_headers_dir, generated, arm_gmp, shortint_leaf_objects, flags_state_objects, memory_state_objects, register_metadata_objects, stack_state_objects, decnumber_fastmul, null);
    const pre_qspi_bad = addObjcopyBinary(b, pre_build.elf, b.fmt("{s}_pre_qspi_incorrect_crc.bin", .{config.program_name}), .{ .section_mode = .only });
    const pre_qspi = addModifyCrcStep(b, forcecrc32, pre_qspi_bad.path, b.fmt("{s}_pre_qspi.bin", .{config.program_name}));
    const generated_qspi_header = addGenerateQspiCrcStep(b, pre_qspi.path, config.generated_qspi_header_name);

    const final_build = addFirmwareElfBuild(b, config, .final, core_sources, version_headers_dir, generated, arm_gmp, shortint_leaf_objects, flags_state_objects, memory_state_objects, register_metadata_objects, stack_state_objects, decnumber_fastmul, generated_qspi_header.path);
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
    shortint_leaf_objects: ShortIntLeafObjects,
    flags_state_objects: FlagsStateObjects,
    memory_state_objects: MemoryStateObjects,
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

    cmd.addArg("-Idep/decNumberICU");
    cmd.addArg("-Isrc/c47");
    cmd.addArg(b.fmt("-I{s}", .{firmwareBoardSourceDir(config.board)}));
    cmd.addArg(b.fmt("-I{s}", .{firmwareSdkIncludeDir(config.board)}));
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

    cmd.addArg(firmwareSdkSyscallsSource(config.board));
    cmd.addArg(firmwareSdkStartupSource(config.board));
    for (build_common.decnumber_sources) |source| cmd.addArg(b.fmt("dep/{s}", .{source}));
    for (core_sources) |source| cmd.addArg(b.fmt("src/c47/{s}", .{source}));
    flags_state_objects.addToCommand(cmd);
    memory_state_objects.addToCommand(cmd);
    register_metadata_objects.addToCommand(cmd);
    cmd.addArg("zig_build/state/stack_runtime_helpers.c");
    shortint_leaf_objects.addToCommand(cmd);
    stack_state_objects.addToCommand(cmd);
    for (firmwareBoardHalSources(config.board)) |source| cmd.addArg(source);
    cmd.addFileArg(generated.raster_fonts_data);
    cmd.addFileArg(generated.constant_pointers_c);
    cmd.addFileArg(generated.constant_pointers2_c);

    for (firmware_common_link_flags) |flag| cmd.addArg(flag);
    for (firmwareLinkFlags(config.board)) |flag| cmd.addArg(flag);
    cmd.addPrefixedFileArg("-T", b.path(firmwareBoardLinkerScript(config.board)));
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

    return .{ .elf = elf, .map = map };
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

fn addModifyCrcStep(
    b: *std.Build,
    forcecrc32: *std.Build.Step.Compile,
    input: std.Build.LazyPath,
    basename: []const u8,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/modify_crc" });
    cmd.setCwd(b.path("."));
    cmd.addArtifactArg(forcecrc32);
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addGenerateQspiCrcStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/gen_qspi_crc" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addPgmChecksumStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/add_pgm_chsum" });
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
    const cmd = b.addSystemCommand(&.{ "python3", "tools/size.py" });
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

fn firmwareBoardHalSources(board: Board) []const []const u8 {
    return switch (board) {
        .dmcp => &.{
            "src/c47-dmcp/hal/audio.c",
            "src/c47-dmcp/hal/io.c",
            "src/c47-dmcp/hal/print_ir.c",
        },
        .dmcp5 => &.{
            "src/c47-dmcp5/hal/audio.c",
            "src/c47-dmcp5/hal/io.c",
            "src/c47-dmcp5/hal/print_ir.c",
        },
    };
}
