const std = @import("std");

const decnumber_sources = &.{
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

    const host_target = resolveBuildHostTarget(b);
    const common = try resolveCommonConfig(b, host_target, raspberry, decnumber_fastmul);

    const core_sources = try collectRelativeCFiles(b, "src/c47");
    const gtk_sources = try collectRelativeCFiles(b, "src/c47-gtk");
    const test_sources = try collectRelativeCFiles(b, "src/testSuite");

    const version_headers_dir = try addVersionHeaders(b, ci_commit_tag);
    const generated = try addGeneratorSteps(b, host_target, optimize, common);

    const sim = addSimulator(b, host_target, "c47", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_C47");
    const sim_install = b.addInstallArtifact(sim, .{});
    b.getInstallStep().dependOn(&sim_install.step);
    const sim_step = b.step("sim", "Build the C47 simulator");
    sim_step.dependOn(&sim_install.step);

    const simr47 = addSimulator(b, host_target, "r47", optimize, core_sources, gtk_sources, common, version_headers_dir, generated, "USER_R47");
    const simr47_install = b.addInstallArtifact(simr47, .{});
    const simr47_step = b.step("simr47", "Build the R47 simulator");
    simr47_step.dependOn(&simr47_install.step);

    const test_suite = addTestSuite(b, host_target, optimize, core_sources, test_sources, common, version_headers_dir, generated);
    const run_test_suite = b.addRunArtifact(test_suite);
    run_test_suite.setCwd(b.path("."));
    run_test_suite.addArg("src/testSuite/tests/testSuiteList.txt");
    const test_step = b.step("test", "Run the host test suite");
    test_step.dependOn(&run_test_suite.step);

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

    const generated_step = b.step("generated", "Refresh all tracked generated host artifacts");
    generated_step.dependOn(&update_fonts.step);
    generated_step.dependOn(&update_constants.step);
    generated_step.dependOn(&update_catalogs.step);
    generated_step.dependOn(&update_testpgms.step);
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
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    gtk_sources: []const []const u8,
    common: CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    calc_model: []const u8,
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
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    test_sources: []const []const u8,
    common: CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
) *std.Build.Step.Compile {
    const core_c_flags = if (host_target.result.os.tag == .windows) common_c_flags_windows else common_c_flags;

    const exe = b.addExecutable(.{
        .name = "testSuite",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
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