const std = @import("std");

const decnumber_sources: []const []const u8 = &.{
    "decNumberICU/decContext.c",
    "decNumberICU/decDouble.c",
    "decNumberICU/decimal128.c",
    "decNumberICU/decimal64.c",
    "decNumberICU/decNumber.c",
    "decNumberICU/decQuad.c",
};

const generate_catalogs_sources = &.{
    "charString.c",
    "fonts.c",
    "items.c",
    "sort.c",
};

const generate_testpgms_sources = &.{
    "items.c",
    "c47.c",
};

const common_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

const common_c_flags_windows: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-fno-strict-aliasing",
};

const common_gtk_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-fstack-protector-strong",
};

const font_generator_c_flags = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-DGENERATE_FONTS",
};

const generate_constants_c_flags = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

const generate_catalogs_c_flags = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

const generate_testpgms_c_flags = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

const CommonConfig = struct {
    platform_define: []const u8,
    word_size_define: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
    with_pulseaudio: bool,
    needs_gnu_source: bool,
    have_dladdr: bool,
    needs_libdl: bool,
};

const GeneratedOutputs = struct {
    raster_fonts_data: std.Build.LazyPath,
    softmenu_catalogs: std.Build.LazyPath,
    constant_pointers_c: std.Build.LazyPath,
    constant_pointers_h: std.Build.LazyPath,
    constant_pointers2_c: std.Build.LazyPath,
    test_pgms_bin: std.Build.LazyPath,
};

const ArmGmpOutputs = struct {
    header: std.Build.LazyPath,
    library: std.Build.LazyPath,
};

const FirmwareBoard = enum {
    dmcp,
    dmcp5,
};

const FirmwareOutputs = struct {
    program: std.Build.LazyPath,
    qspi: std.Build.LazyPath,
    map: std.Build.LazyPath,
};

const StepFile = struct {
    step: *std.Build.Step,
    path: std.Build.LazyPath,
};

const FirmwareBuild = struct {
    step: *std.Build.Step,
    outputs: FirmwareOutputs,
};

const FirmwareConfig = struct {
    step_name: []const u8,
    description: []const u8,
    board: FirmwareBoard,
    program_name: []const u8,
    map_name: []const u8 = "C47",
    program_extension: []const u8,
    generated_qspi_header_name: []const u8,
    qspi_macro: []const u8,
    pre_calcmodel_define: ?[]const u8 = null,
    final_calcmodel_define: ?[]const u8 = null,
    dmcp_package: ?u8 = null,
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

pub fn build(b: *std.Build) void {
    buildImpl(b) catch |err| {
        std.debug.panic("build.zig configuration failed: {s}", .{@errorName(err)});
    };
}

fn buildImpl(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const ci_commit_tag = b.option([]const u8, "ci-commit-tag", "Commit tag for version information") orelse "";
    const raspberry = b.option(bool, "raspberry", "Enable Raspberry Pi layout") orelse false;
    const decnumber_fastmul = b.option(bool, "decnumber-fastmul", "Enable DECNUMBER_FASTMUL") orelse true;
    const dmcp_package = b.option(u8, "dmcp-package", "Select the upstream DMCP package variant") orelse 4;

    const host_target = resolveBuildHostTarget(b);
    const common = try resolveCommonConfig(b, host_target, raspberry, decnumber_fastmul);

    const core_sources = try collectRelativeCFiles(b, "src/c47");
    const gtk_sources = try collectRelativeCFiles(b, "src/c47-gtk");
    const test_sources = try collectRelativeCFiles(b, "src/testSuite");

    const version_headers_dir = try addVersionHeaders(b, ci_commit_tag);
    const generated = try addGeneratorSteps(b, host_target, optimize, common);
    const forcecrc32 = addForceCrc32Tool(b, host_target, optimize);
    const arm_gmp_dmcp = addArmGmpBuild(b, .dmcp);
    const arm_gmp_dmcp5 = addArmGmpBuild(b, .dmcp5);

    const sim = addSimulator(b, host_target, "c47", "c47", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_C47", null);
    const sim_install = b.addInstallArtifact(sim, .{});
    b.getInstallStep().dependOn(&sim_install.step);
    const sim_step = b.step("sim", "Build the C47 simulator");
    sim_step.dependOn(&sim_install.step);

    const all_step = b.step("all", "Build the C47 simulator");
    all_step.dependOn(&sim_install.step);

    const simr47 = addSimulator(b, host_target, "r47", "r47", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_R47", null);
    const simr47_install = b.addInstallArtifact(simr47, .{});
    const simr47_step = b.step("simr47", "Build the R47 simulator");
    simr47_step.dependOn(&simr47_install.step);

    const both_step = b.step("both", "Build both host simulators");
    both_step.dependOn(&sim_install.step);
    both_step.dependOn(&simr47_install.step);

    const sim_asan = addSimulator(b, host_target, "c47", "c47-asan", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_C47", .full);
    const simr47_asan = addSimulator(b, host_target, "r47", "r47-asan", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_R47", .full);
    const both_asan_step = b.step("both_asan", "Build both host simulators with native Zig C sanitizing");
    both_asan_step.dependOn(&sim_asan.step);
    both_asan_step.dependOn(&simr47_asan.step);

    const test_suite = addTestSuite(b, host_target, "testSuite", optimize, core_sources, test_sources, common, version_headers_dir, generated, null);
    const run_test_suite = b.addRunArtifact(test_suite);
    run_test_suite.setCwd(b.path("."));
    run_test_suite.addArg("src/testSuite/tests/testSuiteList.txt");
    const test_step = b.step("test", "Run the host test suite");
    test_step.dependOn(&run_test_suite.step);

    const test_suite_asan = addTestSuite(b, host_target, "testSuite-asan", optimize, core_sources, test_sources, common, version_headers_dir, generated, .full);
    const run_test_suite_asan = b.addRunArtifact(test_suite_asan);
    run_test_suite_asan.setCwd(b.path("."));
    run_test_suite_asan.addArg("src/testSuite/tests/testSuiteList.txt");
    const test_asan_step = b.step("test_asan", "Run the host test suite with native Zig C sanitizing");
    test_asan_step.dependOn(&run_test_suite_asan.step);

    const repeattest_step = b.step("repeattest", "Run the host test suite incrementally");
    repeattest_step.dependOn(&run_test_suite.step);

    const update_fonts = b.addUpdateSourceFiles();
    update_fonts.addCopyFileToSource(generated.raster_fonts_data, "src/generated/rasterFontsData.c");
    const fonts_step = b.step("fonts", "Refresh rasterFontsData.c from the font generator");
    fonts_step.dependOn(&update_fonts.step);

    const update_constants = b.addUpdateSourceFiles();
    update_constants.addCopyFileToSource(generated.constant_pointers_c, "src/generated/constantPointers.c");
    update_constants.addCopyFileToSource(generated.constant_pointers_h, "src/generated/constantPointers.h");
    update_constants.addCopyFileToSource(generated.constant_pointers2_c, "src/generated/constantPointers2.c");
    const constants_step = b.step("constants", "Refresh generated constant pointer sources");
    constants_step.dependOn(&update_constants.step);

    const update_catalogs = b.addUpdateSourceFiles();
    update_catalogs.addCopyFileToSource(generated.softmenu_catalogs, "src/generated/softmenuCatalogs.h");
    const catalogs_step = b.step("catalogs", "Refresh generated softmenu catalogs");
    catalogs_step.dependOn(&update_catalogs.step);

    const update_testpgms = b.addUpdateSourceFiles();
    update_testpgms.addCopyFileToSource(generated.test_pgms_bin, "res/testPgms/testPgms.bin");
    const testpgms_step = b.step("testpgms", "Refresh the generated test program image");
    testpgms_step.dependOn(&update_testpgms.step);
    const testPgms_step = b.step("testPgms", "Refresh the generated test program image");
    testPgms_step.dependOn(&update_testpgms.step);

    test_step.dependOn(&update_testpgms.step);
    test_asan_step.dependOn(&update_testpgms.step);
    repeattest_step.dependOn(&update_testpgms.step);

    const generated_step = b.step("generated", "Refresh all tracked generated host artifacts");
    generated_step.dependOn(&update_fonts.step);
    generated_step.dependOn(&update_constants.step);
    generated_step.dependOn(&update_catalogs.step);
    generated_step.dependOn(&update_testpgms.step);

    addCleanStep(b);
    addDocsStep(b);

    const dmcp_build = addFirmwareBuild(b, .{
        .step_name = "dmcp",
        .description = b.fmt("Build the C47 DMCP firmware (package {d}) without Make or Meson", .{dmcp_package}),
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = dmcp_package,
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp, forcecrc32, decnumber_fastmul);

    const dmcpr47_build = addFirmwareBuild(b, .{
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
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp, forcecrc32, decnumber_fastmul);

    const dmcp5_build = addFirmwareBuild(b, .{
        .step_name = "dmcp5",
        .description = "Build the C47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "C47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp5, forcecrc32, decnumber_fastmul);

    const dmcp5r47_build = addFirmwareBuild(b, .{
        .step_name = "dmcp5r47",
        .description = "Build the R47 DMCP5 firmware without Make or Meson",
        .board = .dmcp5,
        .program_name = "R47",
        .program_extension = ".pg5",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .final_calcmodel_define = "USER_R47",
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp5, forcecrc32, decnumber_fastmul);

    const dmcp_pkg1 = addFirmwareBuild(b, .{
        .step_name = "dmcp_pkg1",
        .description = "Build the C47 DMCP firmware for package 1 without Make or Meson",
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = 1,
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp, forcecrc32, decnumber_fastmul);

    const dmcp_pkg2 = addFirmwareBuild(b, .{
        .step_name = "dmcp_pkg2",
        .description = "Build the C47 DMCP firmware for package 2 without Make or Meson",
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = 2,
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp, forcecrc32, decnumber_fastmul);

    const dmcp_pkg3 = addFirmwareBuild(b, .{
        .step_name = "dmcp_pkg3",
        .description = "Build the C47 DMCP firmware for package 3 without Make or Meson",
        .board = .dmcp,
        .program_name = "C47",
        .program_extension = ".pgm",
        .generated_qspi_header_name = "generated_qspi_crc.h",
        .qspi_macro = "USE_GEN_QSPI_CRC",
        .dmcp_package = 3,
    }, core_sources, version_headers_dir, generated, arm_gmp_dmcp, forcecrc32, decnumber_fastmul);

    const dmcp_pkgs_all = b.step("dmcp_pkgs_all", "Build DMCP package variants 1, 2, and 3 without Make or Meson");
    dmcp_pkgs_all.dependOn(dmcp_pkg1.step);
    dmcp_pkgs_all.dependOn(dmcp_pkg2.step);
    dmcp_pkgs_all.dependOn(dmcp_pkg3.step);

    installFirmwareOutputs(b, "dmcp", dmcp_build);
    installFirmwareOutputs(b, "dmcpr47", dmcpr47_build);
    installFirmwareOutputs(b, "dmcp5", dmcp5_build);
    installFirmwareOutputs(b, "dmcp5r47", dmcp5r47_build);
    installFirmwareOutputs(b, "dmcp_pkg1", dmcp_pkg1);
    installFirmwareOutputs(b, "dmcp_pkg2", dmcp_pkg2);
    installFirmwareOutputs(b, "dmcp_pkg3", dmcp_pkg3);

    const dist_host_optimize: std.builtin.OptimizeMode = if (host_target.result.os.tag == .linux) .Debug else .ReleaseFast;
    const dist_c47 = addSimulator(b, host_target, "c47", "c47-dist", dist_host_optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_C47", null);
    const dist_r47 = addSimulator(b, host_target, "r47", "r47-dist", dist_host_optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_R47", null);
    const dist_testpgms_zip = addTestPgmsZipStep(b, dist_c47.getEmittedBin(), generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"));
    const dist_version = if (ci_commit_tag.len > 0)
        ci_commit_tag
    else
        commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";

    const windows_stage_name = distDirName(b, "c47-windows", ci_commit_tag);
    const macos_stage_name = distDirName(b, "c47-macos", ci_commit_tag);
    const linux_stage_name = distDirName(b, "c47-linux", ci_commit_tag);
    const dmcp_stage_name = distDirName(b, "c47-dmcp", ci_commit_tag);
    const dmcpr47_stage_name = distDirName(b, "r47-dmcp", ci_commit_tag);
    const dmcp5_stage_name = distDirName(b, "c47-dmcp5", ci_commit_tag);
    const dmcp5r47_stage_name = distDirName(b, "r47-dmcp5", ci_commit_tag);
    const dmcp_pkg1_stage_name = b.fmt("{s}-pkg1", .{dmcp_stage_name});
    const dmcp_pkg2_stage_name = b.fmt("{s}-pkg2", .{dmcp_stage_name});
    const dmcp_pkg3_stage_name = b.fmt("{s}-pkg3", .{dmcp_stage_name});

    const dist_windows_step: *std.Build.Step = if (host_target.result.os.tag == .windows) blk: {
        const zip = addHostDistZipStep(b, "windows", "c47-windows.zip", windows_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-windows.zip");
        const step = b.step("dist_windows", "Create the Windows distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_windows", "dist_windows requires running zig build on a Windows host");

    const dist_macos_step: *std.Build.Step = if (host_target.result.os.tag == .macos) blk: {
        const zip = addHostDistZipStep(b, "macos", "c47-macos.zip", macos_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-macos.zip");
        const step = b.step("dist_macos", "Create the macOS distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_macos", "dist_macos requires running zig build on a macOS host");

    const dist_linux_step: *std.Build.Step = if (host_target.result.os.tag == .linux) blk: {
        const zip = addHostDistZipStep(b, "linux", "c47-linux.zip", linux_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-linux.zip");
        const step = b.step("dist_linux", "Create the Linux distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_linux", "dist_linux requires running zig build on a Linux host");

    const dist_dmcp_zip = addDmcpDistZipStep(b, "package-dmcp", "c47-dmcp.zip", dmcp_stage_name, dmcp_build.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null, true, null);
    const dist_dmcp_install = b.addInstallFileWithDir(dist_dmcp_zip.path, .prefix, "dist/c47-dmcp.zip");
    const dist_dmcp_step = b.step("dist_dmcp", "Create the DMCP distribution package with Zig-owned packaging");
    dist_dmcp_step.dependOn(&dist_dmcp_install.step);

    const dist_dmcpr47_zip = addDmcpDistZipStep(b, "package-dmcpr47", "r47-dmcp.zip", dmcpr47_stage_name, dmcpr47_build.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null, false, null);
    const dist_dmcpr47_install = b.addInstallFileWithDir(dist_dmcpr47_zip.path, .prefix, "dist/r47-dmcp.zip");
    const dist_dmcpr47_step = b.step("dist_dmcpr47", "Create the DMCP R47 distribution package with Zig-owned packaging");
    dist_dmcpr47_step.dependOn(&dist_dmcpr47_install.step);

    const dist_dmcp5_zip = addDmcp5DistZipStep(b, "package-dmcp5", "c47-dmcp5.zip", dmcp5_stage_name, dmcp5_build.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null);
    const dist_dmcp5_install = b.addInstallFileWithDir(dist_dmcp5_zip.path, .prefix, "dist/c47-dmcp5.zip");
    const dist_dmcp5_step = b.step("dist_dmcp5", "Create the DMCP5 distribution package with Zig-owned packaging");
    dist_dmcp5_step.dependOn(&dist_dmcp5_install.step);

    const dist_dmcp5r47_zip = addDmcp5DistZipStep(b, "package-dmcp5r47", "r47-dmcp5.zip", dmcp5r47_stage_name, dmcp5r47_build.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, dist_version);
    const dist_dmcp5r47_install = b.addInstallFileWithDir(dist_dmcp5r47_zip.path, .prefix, "dist/r47-dmcp5.zip");
    const dist_dmcp5r47_step = b.step("dist_dmcp5r47", "Create the DMCP5 R47 distribution package with Zig-owned packaging");
    dist_dmcp5r47_step.dependOn(&dist_dmcp5r47_install.step);

    const dist_dmcp_pkg1_zip = addDmcpDistZipStep(b, "package-dmcp", "c47-dmcp-pkg1.zip", dmcp_pkg1_stage_name, dmcp_pkg1.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null, true, null);
    const dist_dmcp_pkg1_install = b.addInstallFileWithDir(dist_dmcp_pkg1_zip.path, .prefix, "dist/c47-dmcp-pkg1.zip");
    const dist_dmcp_pkg1_step = b.step("dist_dmcp_pkg1", "Create the DMCP package 1 distribution archive with Zig-owned packaging");
    dist_dmcp_pkg1_step.dependOn(&dist_dmcp_pkg1_install.step);

    const dist_dmcp_pkg2_zip = addDmcpDistZipStep(b, "package-dmcp", "c47-dmcp-pkg2.zip", dmcp_pkg2_stage_name, dmcp_pkg2.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null, true, null);
    const dist_dmcp_pkg2_install = b.addInstallFileWithDir(dist_dmcp_pkg2_zip.path, .prefix, "dist/c47-dmcp-pkg2.zip");
    const dist_dmcp_pkg2_step = b.step("dist_dmcp_pkg2", "Create the DMCP package 2 distribution archive with Zig-owned packaging");
    dist_dmcp_pkg2_step.dependOn(&dist_dmcp_pkg2_install.step);

    const dist_dmcp_pkg3_zip = addDmcpDistZipStep(b, "package-dmcp", "c47-dmcp-pkg3.zip", dmcp_pkg3_stage_name, dmcp_pkg3.outputs, generated.test_pgms_bin, b.path("res/testPgms/testPgms.txt"), dist_testpgms_zip.path, null, true, null);
    const dist_dmcp_pkg3_install = b.addInstallFileWithDir(dist_dmcp_pkg3_zip.path, .prefix, "dist/c47-dmcp-pkg3.zip");
    const dist_dmcp_pkg3_step = b.step("dist_dmcp_pkg3", "Create the DMCP package 3 distribution archive with Zig-owned packaging");
    dist_dmcp_pkg3_step.dependOn(&dist_dmcp_pkg3_install.step);

    const dist_dmcp_pkgs_all = b.step("dist_dmcp_pkgs_all", "Create all DMCP package variant archives with Zig-owned packaging");
    dist_dmcp_pkgs_all.dependOn(dist_dmcp_pkg1_step);
    dist_dmcp_pkgs_all.dependOn(dist_dmcp_pkg2_step);
    dist_dmcp_pkgs_all.dependOn(dist_dmcp_pkg3_step);

    const dist_dmcp_pkgs_1_2 = b.step("dist_dmcp_pkgs_1_2", "Create DMCP package 1 and 2 archives with Zig-owned packaging");
    dist_dmcp_pkgs_1_2.dependOn(dist_dmcp_pkg1_step);
    dist_dmcp_pkgs_1_2.dependOn(dist_dmcp_pkg2_step);

    const dist_dmcp_pkgs_small = b.step("dist_dmcp_pkgs_small", "Create the smaller DMCP package 2 and 3 archives with Zig-owned packaging");
    dist_dmcp_pkgs_small.dependOn(dist_dmcp_pkg2_step);
    dist_dmcp_pkgs_small.dependOn(dist_dmcp_pkg3_step);

    const dist_step = b.step("dist", "Build the current-host distribution archive plus all DMCP package archives");
    switch (host_target.result.os.tag) {
        .windows => dist_step.dependOn(dist_windows_step),
        .macos => dist_step.dependOn(dist_macos_step),
        else => dist_step.dependOn(dist_linux_step),
    }
    dist_step.dependOn(dist_dmcp_step);
    dist_step.dependOn(dist_dmcpr47_step);
    dist_step.dependOn(dist_dmcp5_step);
    dist_step.dependOn(dist_dmcp5r47_step);
    dist_step.dependOn(dist_dmcp_pkg1_step);
    dist_step.dependOn(dist_dmcp_pkg2_step);
    dist_step.dependOn(dist_dmcp_pkg3_step);

    const distS_step = b.step("distS", "Run the aggregate distribution build sequence under Zig-only orchestration");
    distS_step.dependOn(dist_step);
}

fn addCleanStep(b: *std.Build) void {
    const cmd = addBashCommand(b,
        \\rm -f wp43 wp43.exe c47 c47.exe r47 r47.exe
        \\rm -rf wp43-windows* wp43-macos* wp43-linux* wp43-dm42*
        \\rm -rf c47-windows* c47-macos* c47-linux* c47-dmcp* r47-dmcp*
        \\rm -rf build build.sim build.dmcp build.dmcp.* build.dmcp5 build.rel build.rel.debug
        \\rm -rf .zig-cache zig-out
        \\rm -f src/generated/*.c src/generated/constantPointers.h src/generated/softmenuCatalogs.h
        \\rm -rf PROGRAMS/ALLPGMS
        \\rm -f src_files_stamp testPgms_stamp
    );

    const step = b.step("clean", "Remove build artifacts and generated files without Make or Meson");
    step.dependOn(&cmd.step);
}

fn addDocsStep(b: *std.Build) void {
    const docs_build_root = b.getInstallPath(.prefix, "docs/code");
    const cmd = addBashCommandFmt(b,
        \\for tool in python3 doxygen; do
        \\  command -v "$tool" >/dev/null 2>&1 || {{
        \\    echo "missing required documentation tool: $tool" >&2
        \\    exit 1
        \\  }}
        \\done
        \\python3 -c 'import sphinx, breathe, furo' >/dev/null 2>&1 || {{
        \\  echo "missing required Python docs packages; install docs/code/requirements.txt" >&2
        \\  exit 1
        \\}}
        \\rm -rf '{s}'
        \\mkdir -p '{s}'
        \\python3 -m sphinx -M html docs/code '{s}'
    , .{ docs_build_root, docs_build_root, docs_build_root });

    const step = b.step("docs", "Build documentation with Zig-owned Sphinx orchestration");
    step.dependOn(&cmd.step);
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
    exe.root_module.addCSourceFile(.{ .file = b.path("dep/forcecrc32.c"), .flags = common_c_flags });
    return exe;
}

fn addArmGmpBuild(b: *std.Build, board: FirmwareBoard) ArmGmpOutputs {
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
        \\  CFLAGS="-Os ${cpu_flags[*]}" \
        \\  CC="$target_cc" \
        \\  AR=arm-none-eabi-ar \
        \\  RANLIB=arm-none-eabi-ranlib \
        \\  CC_FOR_BUILD="$build_cc" \
        \\  "$source_dir/configure" \
        \\    --build="$build_triplet" \
        \\    --host=arm-none-eabi \
        \\    --disable-assembly \
        \\    --disable-shared \
        \\    --disable-fft \
        \\    --disable-cxx \
        \\    --prefix="$install_dir"
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
    config: FirmwareConfig,
    core_sources: []const []const u8,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    arm_gmp: ArmGmpOutputs,
    forcecrc32: *std.Build.Step.Compile,
    decnumber_fastmul: bool,
) FirmwareBuild {
    const pre_build = addFirmwareElfBuild(b, config, .pre, core_sources, version_headers_dir, generated, arm_gmp, decnumber_fastmul, null);
    const pre_qspi_bad = addObjcopyBinary(b, pre_build.elf, b.fmt("{s}_pre_qspi_incorrect_crc.bin", .{config.program_name}), .{ .section_mode = .only });
    const pre_qspi = addModifyCrcStep(b, forcecrc32, pre_qspi_bad.path, b.fmt("{s}_pre_qspi.bin", .{config.program_name}));
    const generated_qspi_header = addGenerateQspiCrcStep(b, pre_qspi.path, config.generated_qspi_header_name);

    const final_build = addFirmwareElfBuild(b, config, .final, core_sources, version_headers_dir, generated, arm_gmp, decnumber_fastmul, generated_qspi_header.path);
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

const FirmwareBuildPhase = enum {
    pre,
    final,
};

const ElfBuildOutputs = struct {
    elf: std.Build.LazyPath,
    map: std.Build.LazyPath,
};

fn addFirmwareElfBuild(
    b: *std.Build,
    config: FirmwareConfig,
    phase: FirmwareBuildPhase,
    core_sources: []const []const u8,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    arm_gmp: ArmGmpOutputs,
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
    for (decnumber_sources) |source| cmd.addArg(b.fmt("dep/{s}", .{source}));
    for (core_sources) |source| cmd.addArg(b.fmt("src/c47/{s}", .{source}));
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

const ObjcopyOptions = struct {
    section_mode: enum { only, remove },
};

fn addObjcopyBinary(
    b: *std.Build,
    input: std.Build.LazyPath,
    basename: []const u8,
    options: ObjcopyOptions,
) StepFile {
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
) StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/modify_crc" });
    cmd.setCwd(b.path("."));
    cmd.addArtifactArg(forcecrc32);
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addGenerateQspiCrcStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/gen_qspi_crc" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addPgmChecksumStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) StepFile {
    const cmd = b.addSystemCommand(&.{ "bash", "tools/add_pgm_chsum" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.addOutputFileArg(basename);
    return .{ .step = &cmd.step, .path = output };
}

fn addReadelfSectionSizesStep(b: *std.Build, input: std.Build.LazyPath, basename: []const u8) StepFile {
    const cmd = b.addSystemCommand(&.{ "arm-none-eabi-readelf", "-l" });
    cmd.setCwd(b.path("."));
    cmd.addFileArg(input);
    const output = cmd.captureStdOut(.{ .basename = basename });
    return .{ .step = &cmd.step, .path = output };
}

fn addFirmwareSizeReportStep(b: *std.Build, board: FirmwareBoard, section_sizes: std.Build.LazyPath) *std.Build.Step.Run {
    const cmd = b.addSystemCommand(&.{ "python3", "tools/size.py" });
    cmd.setCwd(b.path("."));
    if (board == .dmcp5) cmd.addArg("dmcp5");
    cmd.addFileArg(section_sizes);
    return cmd;
}

fn installFirmwareOutputs(b: *std.Build, subdir: []const u8, firmware_build: FirmwareBuild) void {
    const program_install = b.addInstallFileWithDir(firmware_build.outputs.program, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.program.getDisplayName()) }));
    const qspi_install = b.addInstallFileWithDir(firmware_build.outputs.qspi, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.qspi.getDisplayName()) }));
    const map_install = b.addInstallFileWithDir(firmware_build.outputs.map, .prefix, b.fmt("firmware/{s}/{s}", .{ subdir, std.fs.path.basename(firmware_build.outputs.map.getDisplayName()) }));
    firmware_build.step.dependOn(&program_install.step);
    firmware_build.step.dependOn(&qspi_install.step);
    firmware_build.step.dependOn(&map_install.step);
}

fn addTestPgmsZipStep(
    b: *std.Build,
    c47_bin: std.Build.LazyPath,
    testpgms_bin: std.Build.LazyPath,
    testpgms_txt: std.Build.LazyPath,
) StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", "scripts/zig_dist.py", "make-testpgms" });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg("testPgms.zip");
    cmd.addFileArg(c47_bin);
    cmd.addFileArg(testpgms_bin);
    cmd.addFileArg(testpgms_txt);
    return .{ .step = &cmd.step, .path = output };
}

fn addHostDistZipStep(
    b: *std.Build,
    flavor: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    c47_bin: std.Build.LazyPath,
    r47_bin: std.Build.LazyPath,
    testpgms_bin: std.Build.LazyPath,
    testpgms_txt: std.Build.LazyPath,
    testpgms_zip: std.Build.LazyPath,
    wiki_dir: ?std.Build.LazyPath,
) StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", "scripts/zig_dist.py", "package-host", flavor });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(c47_bin);
    cmd.addFileArg(r47_bin);
    cmd.addFileArg(testpgms_bin);
    cmd.addFileArg(testpgms_txt);
    cmd.addFileArg(testpgms_zip);
    if (wiki_dir) |dir| cmd.addDirectoryArg(dir);
    return .{ .step = &cmd.step, .path = output };
}

fn addDmcpDistZipStep(
    b: *std.Build,
    command: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    outputs: FirmwareOutputs,
    testpgms_bin: std.Build.LazyPath,
    testpgms_txt: std.Build.LazyPath,
    testpgms_zip: std.Build.LazyPath,
    wiki_dir: ?std.Build.LazyPath,
    include_packages: bool,
    version: ?[]const u8,
) StepFile {
    _ = version;
    const cmd = b.addSystemCommand(&.{ "python3", "scripts/zig_dist.py", command });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(outputs.program);
    cmd.addFileArg(outputs.qspi);
    cmd.addFileArg(outputs.map);
    cmd.addFileArg(testpgms_bin);
    cmd.addFileArg(testpgms_txt);
    cmd.addFileArg(testpgms_zip);
    if (wiki_dir) |dir| cmd.addDirectoryArg(dir);
    if (std.mem.eql(u8, command, "package-dmcp")) {
        cmd.addArg(if (include_packages) "with-packages" else "without-packages");
    }
    return .{ .step = &cmd.step, .path = output };
}

fn addDmcp5DistZipStep(
    b: *std.Build,
    command: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    outputs: FirmwareOutputs,
    testpgms_bin: std.Build.LazyPath,
    testpgms_txt: std.Build.LazyPath,
    testpgms_zip: std.Build.LazyPath,
    version: ?[]const u8,
) StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", "scripts/zig_dist.py", command });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(outputs.program);
    cmd.addFileArg(outputs.map);
    cmd.addFileArg(testpgms_bin);
    cmd.addFileArg(testpgms_txt);
    cmd.addFileArg(testpgms_zip);
    if (version) |value| cmd.addArg(value);
    return .{ .step = &cmd.step, .path = output };
}

fn addUnsupportedStep(b: *std.Build, step_name: []const u8, message: []const u8) *std.Build.Step {
    const cmd = addBashCommandFmt(b,
        \\echo '{s}' >&2
        \\exit 1
    , .{message});
    const step = b.step(step_name, message);
    step.dependOn(&cmd.step);
    return step;
}

fn distDirName(b: *std.Build, base: []const u8, ci_commit_tag: []const u8) []const u8 {
    if (ci_commit_tag.len == 0) return base;
    return b.fmt("{s}-{s}", .{ base, ci_commit_tag });
}

fn firmwareArchFlags(board: FirmwareBoard) []const []const u8 {
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

fn firmwareLinkFlags(board: FirmwareBoard) []const []const u8 {
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

fn firmwareBoardMacro(board: FirmwareBoard) ?[]const u8 {
    return switch (board) {
        .dmcp => "-DOLD_HW",
        .dmcp5 => "-DNEW_HW",
    };
}

fn firmwareBoardSourceDir(board: FirmwareBoard) []const u8 {
    return switch (board) {
        .dmcp => "src/c47-dmcp",
        .dmcp5 => "src/c47-dmcp5",
    };
}

fn firmwareBoardLinkerScript(board: FirmwareBoard) []const u8 {
    return switch (board) {
        .dmcp => "src/c47-dmcp/stm32_program.ld",
        .dmcp5 => "src/c47-dmcp5/stm32_program.ld",
    };
}

fn firmwareSdkIncludeDir(board: FirmwareBoard) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp",
        .dmcp5 => "dep/DMCP5_SDK/dmcp",
    };
}

fn firmwareSdkSyscallsSource(board: FirmwareBoard) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp/sys/pgm_syscalls.c",
        .dmcp5 => "dep/DMCP5_SDK/dmcp/sys/pgm_syscalls.c",
    };
}

fn firmwareSdkStartupSource(board: FirmwareBoard) []const u8 {
    return switch (board) {
        .dmcp => "dep/DMCP_SDK/dmcp/startup_pgm.s",
        .dmcp5 => "dep/DMCP5_SDK/dmcp/startup_pgm.s",
    };
}

fn firmwareBoardHalSources(board: FirmwareBoard) []const []const u8 {
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

fn addBashCommand(b: *std.Build, script: []const u8) *std.Build.Step.Run {
    return addBashCommandFmt(b, "{s}", .{script});
}

fn addBashCommandFmt(b: *std.Build, comptime fmt: []const u8, args: anytype) *std.Build.Step.Run {
    const script = std.fmt.allocPrint(b.allocator, fmt, args) catch @panic("OOM");
    const cmd = b.addSystemCommand(&.{ "bash", "-euo", "pipefail", "-c", script });
    cmd.setCwd(b.path("."));
    return cmd;
}

fn resolveBuildHostTarget(b: *std.Build) std.Build.ResolvedTarget {
    if (b.graph.host.result.os.tag != .windows) return b.graph.host;

    var query = std.Target.Query.fromTarget(&b.graph.host.result);
    query.abi = .gnu;
    return b.resolveTargetQuery(query);
}

fn addVersionHeaders(b: *std.Build, ci_commit_tag: []const u8) !std.Build.LazyPath {
    const vcs_tag = commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";
    const today = commandOutput(b, &.{ "date", "+%Y-%m-%d" }) orelse "1970-01-01";

    const vcs_content = try std.fmt.allocPrint(b.allocator,
        \\// SPDX-License-Identifier: GPL-3.0-only
        \\// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors
        \\
        \\/********************************************//**
        \\* \\file vcs.h
        \\***********************************************/
        \\
        \\/***********************************************************************************
        \\* Do not edit this file manually! It's automagically generated by the build system *
        \\************************************************************************************/
        \\
        \\#if !defined(VCS_H)
        \\  #define VCS_H
        \\
        \\  #define VCS_COMMIT_ID  "{s}"
        \\#endif // !VCS_H
        \\
    , .{vcs_tag});

    const version_content = if (ci_commit_tag.len > 0)
        try std.fmt.allocPrint(b.allocator,
            \\// SPDX-License-Identifier: GPL-3.0-only
            \\// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors
            \\
            \\/********************************************//**
            \\* \\file version.h
            \\***********************************************/
            \\
            \\/***********************************************************************************
            \\* Do not edit this file manually! It's automagically generated by the build system *
            \\************************************************************************************/
            \\
            \\#if !defined(VERSION_H)
            \\  #define VERSION_H
            \\
            \\  #define VERSION_STRING "v{s}" STD_SPACE_3_PER_EM "{s}"
            \\  #define VERSION_SHORT  "{s}"
            \\  #define VERSION_WINRS    0,0,0,0
            \\  #define VERSION_MODDED   0
            \\
            \\#endif // !VERSION_H
            \\
        , .{ ci_commit_tag, today, ci_commit_tag })
    else
        try std.fmt.allocPrint(b.allocator,
            \\// SPDX-License-Identifier: GPL-3.0-only
            \\// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors
            \\
            \\/********************************************//**
            \\* \\file version.h
            \\***********************************************/
            \\
            \\/***********************************************************************************
            \\* Do not edit this file manually! It's automagically generated by the build system *
            \\************************************************************************************/
            \\
            \\#if !defined(VERSION_H)
            \\  #define VERSION_H
            \\
            \\  #include "vcs.h"
            \\  #define VERSION_STRING "custom" STD_SPACE_3_PER_EM "build" STD_SPACE_3_PER_EM VCS_COMMIT_ID STD_SPACE_3_PER_EM "{s}"
            \\  #define VERSION_SHORT  VCS_COMMIT_ID
            \\  #define VERSION_WINRS    0,0,0,0
            \\  #define VERSION_MODDED   0
            \\
            \\#endif // !VERSION_H
            \\
        , .{today});

    const write_files = b.addWriteFiles();
    _ = write_files.add("vcs.h", vcs_content);
    _ = write_files.add("version.h", version_content);
    return write_files.getDirectory();
}

fn addGeneratorSteps(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    common: CommonConfig,
) !GeneratedOutputs {
    const core_c_flags = if (host_target.result.os.tag == .windows) common_c_flags_windows else common_c_flags;

    const raster_fonts_gen = b.addExecutable(.{
        .name = "ttf2RasterFonts",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    addHostMacros(raster_fonts_gen.root_module, common);
    addHostSystemPaths(raster_fonts_gen.root_module, common);
    raster_fonts_gen.root_module.addCSourceFile(.{ .file = b.path("src/ttf2RasterFonts/ttf2RasterFonts.c"), .flags = font_generator_c_flags });
    linkRasterFontsFreetype(raster_fonts_gen.root_module, common);

    const run_raster_fonts = b.addRunArtifact(raster_fonts_gen);
    run_raster_fonts.setCwd(b.path("."));
    run_raster_fonts.addArg("res/fonts");
    const raster_fonts_data = run_raster_fonts.addOutputFileArg("rasterFontsData.c");

    const generate_constants = b.addExecutable(.{
        .name = "generateConstants",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    addHostMacros(generate_constants.root_module, common);
    addHostSystemPaths(generate_constants.root_module, common);
    generate_constants.root_module.addCMacro("GENERATE_CONSTANTS", "1");
    generate_constants.root_module.addIncludePath(b.path("dep/decNumberICU"));
    generate_constants.root_module.addIncludePath(b.path("src/c47"));
    generate_constants.root_module.addCSourceFiles(.{ .root = b.path("dep"), .files = decnumber_sources, .flags = core_c_flags });
    generate_constants.root_module.addCSourceFile(.{ .file = b.path("src/generateConstants/generateConstants.c"), .flags = generate_constants_c_flags });
    linkGtk3(generate_constants.root_module, common);

    const run_generate_constants = b.addRunArtifact(generate_constants);
    run_generate_constants.setCwd(b.path("."));
    const constant_pointers_c = run_generate_constants.addOutputFileArg("constantPointers.c");
    const constant_pointers_h = run_generate_constants.addOutputFileArg("constantPointers.h");
    const constant_pointers2_c = run_generate_constants.addOutputFileArg("constantPointers2.c");

    const generate_catalogs = b.addExecutable(.{
        .name = "generateCatalogs",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    addHostMacros(generate_catalogs.root_module, common);
    addHostSystemPaths(generate_catalogs.root_module, common);
    generate_catalogs.root_module.addCMacro("GENERATE_CATALOGS", "1");
    generate_catalogs.root_module.addIncludePath(b.path("dep/decNumberICU"));
    generate_catalogs.root_module.addIncludePath(b.path("src/c47"));
    generate_catalogs.root_module.addCSourceFiles(.{ .root = b.path("dep"), .files = decnumber_sources, .flags = core_c_flags });
    generate_catalogs.root_module.addCSourceFiles(.{ .root = b.path("src/c47"), .files = generate_catalogs_sources, .flags = core_c_flags });
    generate_catalogs.root_module.addCSourceFile(.{ .file = b.path("src/generateCatalogs/generateCatalogs.c"), .flags = generate_catalogs_c_flags });
    generate_catalogs.root_module.addCSourceFile(.{ .file = raster_fonts_data, .flags = core_c_flags });
    linkGtk3(generate_catalogs.root_module, common);
    generate_catalogs.root_module.linkSystemLibrary("gmp", .{ .use_pkg_config = .yes });

    const run_generate_catalogs = b.addRunArtifact(generate_catalogs);
    run_generate_catalogs.setCwd(b.path("."));
    const softmenu_catalogs = run_generate_catalogs.addOutputFileArg("softmenuCatalogs.h");

    const generate_testpgms = b.addExecutable(.{
        .name = "generateTestPgms",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    addHostMacros(generate_testpgms.root_module, common);
    addHostSystemPaths(generate_testpgms.root_module, common);
    generate_testpgms.root_module.addCMacro("GENERATE_TESTPGMS", "1");
    generate_testpgms.root_module.addIncludePath(b.path("dep/decNumberICU"));
    generate_testpgms.root_module.addIncludePath(b.path("src/c47"));
    generate_testpgms.root_module.addCSourceFiles(.{ .root = b.path("dep"), .files = decnumber_sources, .flags = core_c_flags });
    generate_testpgms.root_module.addCSourceFiles(.{ .root = b.path("src/c47"), .files = generate_testpgms_sources, .flags = core_c_flags });
    generate_testpgms.root_module.addCSourceFile(.{ .file = b.path("src/generateTestPgms/generateTestPgms.c"), .flags = generate_testpgms_c_flags });
    linkGtk3(generate_testpgms.root_module, common);
    generate_testpgms.root_module.linkSystemLibrary("gmp", .{ .use_pkg_config = .yes });

    const run_generate_testpgms = b.addRunArtifact(generate_testpgms);
    run_generate_testpgms.setCwd(b.path("."));
    const test_pgms_bin = run_generate_testpgms.addOutputFileArg("testPgms.bin");

    return .{
        .raster_fonts_data = raster_fonts_data,
        .softmenu_catalogs = softmenu_catalogs,
        .constant_pointers_c = constant_pointers_c,
        .constant_pointers_h = constant_pointers_h,
        .constant_pointers2_c = constant_pointers2_c,
        .test_pgms_bin = test_pgms_bin,
    };
}

fn addSimulator(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    name: []const u8,
    artifact_name: []const u8,
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    gtk_sources: []const []const u8,
    common: CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    calc_model: []const u8,
    sanitize_c: ?std.zig.SanitizeC,
) *std.Build.Step.Compile {
    const core_c_flags = if (host_target.result.os.tag == .windows) common_c_flags_windows else common_c_flags;

    const exe = b.addExecutable(.{
        .name = artifact_name,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (sanitize_c) |level| {
        exe.root_module.sanitize_c = level;
    }
    if (host_target.result.os.tag == .windows) {
        exe.subsystem = .Windows;
    }
    addHostMacros(exe.root_module, common);
    addHostSystemPaths(exe.root_module, common);
    if (common.needs_gnu_source) {
        exe.root_module.addCMacro("_GNU_SOURCE", "1");
    }
    if (common.have_dladdr) {
        exe.root_module.addCMacro("HAVE_DLADDR", "1");
    }
    exe.root_module.addCMacro("CALCMODEL", calc_model);
    exe.root_module.addIncludePath(b.path("dep/decNumberICU"));
    exe.root_module.addIncludePath(b.path("src/c47"));
    exe.root_module.addIncludePath(b.path("src/c47-gtk"));
    exe.root_module.addIncludePath(version_headers_dir);
    exe.root_module.addIncludePath(generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(generated.constant_pointers_h.dirname());
    if (host_target.result.os.tag == .windows) {
        exe.root_module.addWin32ResourceFile(.{
            .file = b.path(b.fmt("src/c47-gtk/{s}-gtk.rc", .{name})),
            .include_paths = &.{
                b.path("src/c47"),
                version_headers_dir,
            },
        });
    }
    exe.root_module.addCSourceFiles(.{ .root = b.path("dep"), .files = decnumber_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = b.path("src/c47"), .files = core_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = b.path("src/c47-gtk"), .files = gtk_sources, .flags = common_gtk_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers2_c, .flags = core_c_flags });
    linkGtk3(exe.root_module, common);
    exe.root_module.linkSystemLibrary("gmp", .{ .use_pkg_config = .yes });
    exe.root_module.linkSystemLibrary("m", .{});
    if (common.needs_libdl) {
        exe.root_module.linkSystemLibrary("dl", .{});
    }
    if (common.with_pulseaudio) {
        exe.root_module.addCMacro("WITH_PULSEAUDIO", "1");
        exe.root_module.linkSystemLibrary("libpulse-simple", .{ .use_pkg_config = .force, .needed = false });
    }
    return exe;
}

fn resolveCommonConfig(
    b: *std.Build,
    host: std.Build.ResolvedTarget,
    raspberry: bool,
    decnumber_fastmul: bool,
) !CommonConfig {
    return .{
        .platform_define = switch (host.result.os.tag) {
            .linux => "LINUX",
            .macos => "OSX",
            .windows => "WIN32",
            else => return error.UnsupportedHostPlatform,
        },
        .word_size_define = switch (host.result.cpu.arch) {
            .x86_64, .aarch64 => "OS64BIT",
            .x86, .arm => "OS32BIT",
            else => return error.UnsupportedArchitecture,
        },
        .raspberry = raspberry,
        .decnumber_fastmul = decnumber_fastmul,
        .with_pulseaudio = switch (host.result.os.tag) {
            .linux, .macos => pkgConfigExists(b, "libpulse-simple"),
            .windows => false,
            else => false,
        },
        .needs_gnu_source = host.result.os.tag == .linux,
        .have_dladdr = switch (host.result.os.tag) {
            .linux, .macos => true,
            .windows => false,
            else => false,
        },
        .needs_libdl = host.result.os.tag == .linux,
    };
}

fn addTestSuite(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    test_sources: []const []const u8,
    common: CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    sanitize_c: ?std.zig.SanitizeC,
) *std.Build.Step.Compile {
    const core_c_flags = if (host_target.result.os.tag == .windows) common_c_flags_windows else common_c_flags;

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (sanitize_c) |level| {
        exe.root_module.sanitize_c = level;
    }
    addHostMacros(exe.root_module, common);
    addHostSystemPaths(exe.root_module, common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(b.path("dep/decNumberICU"));
    exe.root_module.addIncludePath(b.path("src/c47"));
    exe.root_module.addIncludePath(b.path("src/testSuite"));
    exe.root_module.addIncludePath(version_headers_dir);
    exe.root_module.addIncludePath(generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = b.path("dep"), .files = decnumber_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = b.path("src/c47"), .files = core_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = b.path("src/testSuite"), .files = test_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers2_c, .flags = core_c_flags });
    linkGtk3(exe.root_module, common);
    exe.root_module.linkSystemLibrary("gmp", .{ .use_pkg_config = .yes });
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn linkGtk3(module: *std.Build.Module, common: CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) {
        module.linkSystemLibrary("gtk+-3.0", .{ .use_pkg_config = .force });
        return;
    }

    if (!linkWindowsPkgConfigPackage(module, "gtk+-3.0")) {
        module.linkSystemLibrary("gtk+-3.0", .{
            .use_pkg_config = .force,
            .preferred_link_mode = .dynamic,
            .search_strategy = .mode_first,
        });
    }
}

fn addHostMacros(module: *std.Build.Module, common: CommonConfig) void {
    module.addCMacro("PC_BUILD", "1");
    module.addCMacro(common.platform_define, "1");
    module.addCMacro(common.word_size_define, "1");
    if (common.raspberry) {
        module.addCMacro("RASPBERRY", "1");
    }
    if (common.decnumber_fastmul) {
        module.addCMacro("DECNUMBER_FASTMUL", "1");
    }
}

const HostSearchPathKind = enum {
    include,
    library,
};

fn addHostSystemPaths(module: *std.Build.Module, common: CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) return;

    const owner = module.owner;
    if (owner.graph.environ_map.get("PKG_CONFIG_SYSTEM_INCLUDE_PATH")) |include_paths| {
        addHostSearchPaths(module, include_paths, .include);
    } else if (windowsHostPrefix(module)) |prefix| {
        module.addSystemIncludePath(.{ .cwd_relative = owner.fmt("{s}/include", .{prefix}) });
    }
    if (owner.graph.environ_map.get("PKG_CONFIG_SYSTEM_LIBRARY_PATH")) |library_paths| {
        addHostSearchPaths(module, library_paths, .library);
    } else if (windowsHostPrefix(module)) |prefix| {
        module.addLibraryPath(.{ .cwd_relative = owner.fmt("{s}/lib", .{prefix}) });
    }
}

fn linkRasterFontsFreetype(module: *std.Build.Module, common: CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) {
        module.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
        return;
    }

    if (!linkWindowsPkgConfigPackage(module, "freetype2")) {
        module.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
    }
}

fn linkWindowsPkgConfigPackage(module: *std.Build.Module, package: []const u8) bool {
    const flags = commandOutput(module.owner, &.{ "pkg-config", "--cflags", "--libs", package }) orelse return false;

    var tokens = std.mem.tokenizeAny(u8, flags, " \t\r\n");
    var pending: ?PkgConfigTokenKind = null;

    while (tokens.next()) |token| {
        if (pending) |kind| {
            addWindowsPkgConfigToken(module, token, kind);
            pending = null;
            continue;
        }

        if (std.mem.eql(u8, token, "-I")) {
            pending = .include;
            continue;
        }
        if (std.mem.eql(u8, token, "-L")) {
            pending = .library_path;
            continue;
        }
        if (std.mem.eql(u8, token, "-D")) {
            pending = .define;
            continue;
        }
        if (std.mem.eql(u8, token, "-l")) {
            pending = .library;
            continue;
        }

        if (std.mem.startsWith(u8, token, "-I")) {
            addWindowsPkgConfigToken(module, token[2..], .include);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-L")) {
            addWindowsPkgConfigToken(module, token[2..], .library_path);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-D")) {
            addWindowsPkgConfigToken(module, token[2..], .define);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-l")) {
            addWindowsPkgConfigToken(module, token[2..], .library);
            continue;
        }
    }

    return pending == null;
}

const PkgConfigTokenKind = enum {
    include,
    library_path,
    define,
    library,
};

fn addWindowsPkgConfigToken(module: *std.Build.Module, token: []const u8, kind: PkgConfigTokenKind) void {
    switch (kind) {
        .include => module.addSystemIncludePath(.{ .cwd_relative = token }),
        .library_path => module.addLibraryPath(.{ .cwd_relative = token }),
        .define => addPkgConfigDefine(module, token),
        .library => linkWindowsImportLibraryOrSystem(module, token),
    }
}

fn addPkgConfigDefine(module: *std.Build.Module, define: []const u8) void {
    if (std.mem.indexOfScalar(u8, define, '=')) |eq| {
        module.addCMacro(define[0..eq], define[eq + 1 ..]);
        return;
    }

    module.addCMacro(define, "1");
}

fn linkWindowsImportLibraryOrSystem(module: *std.Build.Module, name: []const u8) void {
    const prefix = windowsHostPrefix(module) orelse {
        module.linkSystemLibrary(name, .{ .use_pkg_config = .no });
        return;
    };

    const import_library = module.owner.fmt("{s}/lib/lib{s}.dll.a", .{ prefix, name });
    const exists = blk: {
        if (std.fs.path.isAbsolute(import_library)) {
            std.Io.Dir.accessAbsolute(module.owner.graph.io, import_library, .{}) catch break :blk false;
            break :blk true;
        }

        std.Io.Dir.cwd().access(module.owner.graph.io, import_library, .{}) catch break :blk false;
        break :blk true;
    };

    if (exists) {
        module.addObjectFile(.{ .cwd_relative = import_library });
        return;
    }

    module.linkSystemLibrary(name, .{ .use_pkg_config = .no });
}

fn windowsHostPrefix(module: *std.Build.Module) ?[]const u8 {
    const owner = module.owner;
    return owner.graph.environ_map.get("MSYSTEM_PREFIX") orelse owner.graph.environ_map.get("MINGW_PREFIX");
}

// Zig gets the pkg-config-emitted -l names, but on MSYS2 it still needs the
// active UCRT64 import-library directories added explicitly.
fn addHostSearchPaths(module: *std.Build.Module, paths: []const u8, comptime kind: HostSearchPathKind) void {
    const separator: ?u8 = blk: {
        if (std.mem.indexOfScalar(u8, paths, ';') != null) break :blk ';';
        if (looksLikeWindowsAbsolutePath(paths)) break :blk null;
        break :blk ':';
    };

    if (separator) |sep| {
        var iter = std.mem.tokenizeScalar(u8, paths, sep);
        while (iter.next()) |path| {
            if (path.len == 0) continue;
            addHostSearchPath(module, path, kind);
        }
        return;
    }

    addHostSearchPath(module, paths, kind);
}

fn addHostSearchPath(module: *std.Build.Module, path: []const u8, comptime kind: HostSearchPathKind) void {
    switch (kind) {
        .include => module.addSystemIncludePath(.{ .cwd_relative = path }),
        .library => module.addLibraryPath(.{ .cwd_relative = path }),
    }
}

fn looksLikeWindowsAbsolutePath(path: []const u8) bool {
    return path.len >= 3 and std.ascii.isAlphabetic(path[0]) and path[1] == ':' and (path[2] == '/' or path[2] == '\\');
}

fn collectRelativeCFiles(b: *std.Build, root_path: []const u8) ![][]const u8 {
    var files = try std.ArrayList([]const u8).initCapacity(b.allocator, 0);
    errdefer files.deinit(b.allocator);
    var dir = try std.Io.Dir.cwd().openDir(b.graph.io, root_path, .{ .iterate = true });
    defer dir.close(b.graph.io);

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".c")) continue;
        if (std.mem.eql(u8, entry.path, "reservedRegisterLookupGenerator.c")) continue;
        try files.append(b.allocator, try b.allocator.dupe(u8, entry.path));
    }

    return try files.toOwnedSlice(b.allocator);
}

fn commandOutput(b: *std.Build, argv: []const []const u8) ?[]const u8 {
    const result = std.process.run(b.allocator, b.graph.io, .{
        .argv = argv,
        .environ_map = &b.graph.environ_map,
    }) catch return null;

    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!ok) return null;

    return std.mem.trimEnd(u8, result.stdout, "\r\n");
}

fn pkgConfigExists(b: *std.Build, package: []const u8) bool {
    const result = std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ "pkg-config", "--exists", package },
        .environ_map = &b.graph.environ_map,
    }) catch return false;

    return switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
}