const std = @import("std");
const abi_host = @import("../abi_host.zig");
const build_common = @import("../common.zig");
const host_builders = @import("builders.zig");
const host_platform = @import("platform.zig");
const shortint = @import("../shortint/shortint.zig");
const calc_state = @import("../state/calc_state.zig");
const constants = @import("../constants/constants.zig");
const flags = @import("../state/flags.zig");
const math_command_wrappers = @import("../mathematics/math_command_wrappers.zig");
const keyboard_state = @import("../state/keyboard_state.zig");
const memory = @import("../state/memory.zig");
const program_serialization = @import("../state/program_serialization.zig");
const register_metadata = @import("../state/register_metadata.zig");
const stack = @import("../state/stack.zig");
const tone = @import("../ui/tone.zig");
const host_types = @import("types.zig");

const z47_test_list = "zig_build/tests/testSuiteList_z47.txt";

fn addTestSuiteRun(b: *std.Build, test_suite: *std.Build.Step.Compile, list_path: []const u8) *std.Build.Step.Run {
    const run_test_suite = b.addRunArtifact(test_suite);
    // testSuite.c opens some inputs CWD-relative, not relative to the list file:
    // `res/testPgms/testPgms.bin` is the one that matters, because it stages the
    // test programs. res/ is an imported-upstream path, so the run has to happen
    // from the upstream root -- which is exactly the directory upstream's own
    // suite is written to run in. Running from the repo root instead makes that
    // fopen fail silently, and the missing program memory then surfaces far away
    // as an integer-overflow panic in the calc-state save path.
    run_test_suite.setCwd(b.path(build_common.upstreamRootString(b)));
    // The list is passed as a resolved file argument rather than a CWD-relative
    // string: the lists live on both sides of the boundary (upstream's under
    // src/testSuite/tests/, z47's under zig_build/tests/), so no single CWD can
    // spell both. testSuite.c derives the per-test directory and items.h from
    // dirname(argv[1]), which keeps working with an absolute path.
    run_test_suite.addFileArg(b.path(list_path));
    return run_test_suite;
}

fn addMathLnComplexOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-ln-complex-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-ln-complex-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    // The Zig owner tree exports the same command wrappers the C defines, so the
    // C files it replaces have to come out or the link is a wall of duplicate
    // symbols -- the same filter every other math oracle below applies.
    // mathematics/ln.c is among them, so the C lnComplex this oracle exists to
    // differentiate against arrives via math_ln_complex_reference.c below, which
    // includes that file with only the owner-exported entry points renamed.
    const ln_complex_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = ln_complex_core_sources, .flags = core_c_flags });

    const math_ln_complex_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    // The owner tree reaches the shared C layouts as `@import("abi")`, so the
    // module has to register it the way every other math oracle here does.
    const math_ln_complex_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    math_ln_complex_module.addImport("abi", math_ln_complex_abi_module);
    const math_ln_complex_build_options = b.addOptions();
    math_ln_complex_build_options.addOption(bool, "use_fake_wp34s_model", false);
    math_ln_complex_build_options.addOption(bool, "export_public_ln_complex", false);
    math_ln_complex_module.addOptions("math_command_wrappers_build_options", math_ln_complex_build_options);
    const math_ln_complex_object = b.addObject(.{
        .name = "math-ln-complex-oracle-owned",
        .root_module = math_ln_complex_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_ln_complex_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_ln_complex_oracle.c"), .flags = core_c_flags });
    // math_ln_complex_runtime_constants.c is deliberately NOT linked: every
    // z47_math_wrappers_const_* accessor it defines now comes from the owner
    // tree (command_wrappers/helpers.zig), so linking both is a duplicate.
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    // C side of the differential: the real ln.c body, with only the entry
    // points the Zig owner also exports renamed away. lnComplex keeps its name.
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_ln_complex_reference.c"), .flags = core_c_flags });
    exe.root_module.addObject(math_ln_complex_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathEigenOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-eigen-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-eigen-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    // raw_core_sources minus ONLY the math-replaced files (matrix.c /
    // comparisonReals.c / slvq.c / slvc.c): the Zig math module below provides
    // those symbols. The fully-filtered context.core_sources would also drop
    // frontier/state-replaced C this math-only harness still needs as C, so use
    // the math replaced-manifest filter specifically.
    const eigen_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = eigen_core_sources, .flags = core_c_flags });

    const eigen_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const eigen_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    eigen_module.addImport("abi", eigen_abi_module);
    const eigen_build_options = b.addOptions();
    eigen_build_options.addOption(bool, "use_fake_wp34s_model", false);
    eigen_build_options.addOption(bool, "export_public_ln_complex", false);
    eigen_module.addOptions("math_command_wrappers_build_options", eigen_build_options);
    const eigen_object = b.addObject(.{
        .name = "math-eigen-oracle-owned",
        .root_module = eigen_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_eigen_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(eigen_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathRealRectangularToPolarOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-real-rectangular-to-polar-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-real-rectangular-to-polar-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    const filtered_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = filtered_core_sources, .flags = core_c_flags });

    const helper_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const helper_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    helper_module.addImport("abi", helper_abi_module);
    const helper_build_options = b.addOptions();
    helper_build_options.addOption(bool, "use_fake_wp34s_model", false);
    helper_build_options.addOption(bool, "export_public_ln_complex", false);
    helper_module.addOptions("math_command_wrappers_build_options", helper_build_options);
    const helper_object = b.addObject(.{
        .name = "math-real-rectangular-to-polar-oracle-owned",
        .root_module = helper_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_real_rectangular_to_polar_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_real_rectangular_to_polar_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(helper_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathAtan2Oracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-atan2-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-atan2-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    const filtered_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = filtered_core_sources, .flags = core_c_flags });

    const helper_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const helper_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    helper_module.addImport("abi", helper_abi_module);
    const helper_build_options = b.addOptions();
    helper_build_options.addOption(bool, "use_fake_wp34s_model", false);
    helper_build_options.addOption(bool, "export_public_ln_complex", false);
    helper_module.addOptions("math_command_wrappers_build_options", helper_build_options);
    const helper_object = b.addObject(.{
        .name = "math-atan2-oracle-owned",
        .root_module = helper_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_atan2_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_atan2_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(helper_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathAtanOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-atan-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-atan-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    const filtered_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = filtered_core_sources, .flags = core_c_flags });

    const helper_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const helper_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    helper_module.addImport("abi", helper_abi_module);
    const helper_build_options = b.addOptions();
    helper_build_options.addOption(bool, "use_fake_wp34s_model", false);
    helper_build_options.addOption(bool, "export_public_ln_complex", false);
    helper_module.addOptions("math_command_wrappers_build_options", helper_build_options);
    const helper_object = b.addObject(.{
        .name = "math-atan-oracle-owned",
        .root_module = helper_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_atan_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_atan_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(helper_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathRealTrigPrimitivesOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-real-trig-primitives-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-real-trig-primitives-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    const filtered_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = filtered_core_sources, .flags = core_c_flags });

    const helper_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const helper_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    helper_module.addImport("abi", helper_abi_module);
    const helper_build_options = b.addOptions();
    helper_build_options.addOption(bool, "use_fake_wp34s_model", false);
    helper_build_options.addOption(bool, "export_public_ln_complex", false);
    helper_module.addOptions("math_command_wrappers_build_options", helper_build_options);
    const helper_object = b.addObject(.{
        .name = "math-real-trig-primitives-oracle-owned",
        .root_module = helper_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_real_trig_primitives_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_real_trig_primitives_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(helper_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}

fn addMathCircularTrigOracle(
    b: *std.Build,
    context: host_types.Context,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const core_c_flags = if (context.host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = "math-circular-trig-oracle",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, context.host_target, optimize, "math-circular-trig-oracle");
    host_platform.addHostMacros(exe.root_module, context.common);
    host_platform.addHostSystemPaths(exe.root_module, context.common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(context.version_headers_dir);
    exe.root_module.addIncludePath(context.generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(context.generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    const filtered_core_sources = math_command_wrappers.filterCoreSources(b, context.raw_core_sources) catch @panic("filterCoreSources failed");
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = filtered_core_sources, .flags = core_c_flags });

    const helper_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/numeric/command_wrappers.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const helper_abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    helper_module.addImport("abi", helper_abi_module);
    const helper_build_options = b.addOptions();
    helper_build_options.addOption(bool, "use_fake_wp34s_model", false);
    helper_build_options.addOption(bool, "export_public_ln_complex", false);
    helper_module.addOptions("math_command_wrappers_build_options", helper_build_options);
    const helper_object = b.addObject(.{
        .name = "math-circular-trig-oracle-owned",
        .root_module = helper_module,
    });

    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, "src/testSuite/testSuite.c"), .flags = &.{ "-Dmain=z47_math_circular_trig_oracle_testsuite_main", "-Wno-date-time", "-fno-sanitize=undefined" } });
    exe.root_module.addObject(host_builders.addTestSuiteHalObject(b, context.host_target, optimize, exe.name));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_circular_trig_oracle.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_eigen_link_stubs.c"), .flags = core_c_flags });
    exe.root_module.addObject(helper_object);
    exe.root_module.addCSourceFile(.{ .file = context.generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = context.generated.constant_pointers2_c, .flags = core_c_flags });
    host_platform.linkGtk3(exe.root_module, context.common);
    host_platform.linkGmp(exe.root_module, context.host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}
pub fn registerSteps(b: *std.Build, context: host_types.Context, optimize: std.builtin.OptimizeMode) host_types.SimulatorOutputs {
    const sim = host_builders.addSimulator(
        b,
        context.host_target,
        "c47",
        "c47",
        optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        "USER_C47",
        null,
    );
    const sim_install = b.addInstallArtifact(sim, .{});
    b.getInstallStep().dependOn(&sim_install.step);
    const sim_step = b.step("sim", "Build the C47 simulator");
    sim_step.dependOn(&sim_install.step);

    const all_step = b.step("all", "Build the C47 simulator");
    all_step.dependOn(&sim_install.step);

    const simr47 = host_builders.addSimulator(
        b,
        context.host_target,
        "r47",
        "r47",
        optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        "USER_R47",
        null,
    );
    const simr47_install = b.addInstallArtifact(simr47, .{});
    const simr47_step = b.step("simr47", "Build the R47 simulator");
    simr47_step.dependOn(&simr47_install.step);

    const both_step = b.step("both", "Build both host simulators");
    both_step.dependOn(&sim_install.step);
    both_step.dependOn(&simr47_install.step);

    const simulator_smoke_cmd = build_common.addBashCommandFmt(b,
        \\bash zig_build/host/simulator_smoke.sh zig-out/bin/c47 C47
        \\bash zig_build/host/simulator_smoke.sh zig-out/bin/r47 R47
    , .{});
    simulator_smoke_cmd.step.dependOn(&sim_install.step);
    simulator_smoke_cmd.step.dependOn(&simr47_install.step);
    const simulator_smoke_step = b.step("simulator_smoke", "Run the Linux Xvfb-backed simulator smoke probe");
    simulator_smoke_step.dependOn(&simulator_smoke_cmd.step);

    const sim_asan = host_builders.addSimulator(
        b,
        context.host_target,
        "c47",
        "c47-asan",
        optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        "USER_C47",
        .full,
    );
    const simr47_asan = host_builders.addSimulator(
        b,
        context.host_target,
        "r47",
        "r47-asan",
        optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        "USER_R47",
        .full,
    );
    const both_asan_step = b.step("both_asan", "Build both host simulators with native Zig C sanitizing");
    both_asan_step.dependOn(&sim_asan.step);
    both_asan_step.dependOn(&simr47_asan.step);

    const test_suite = host_builders.addTestSuite(
        b,
        context.host_target,
        "testSuite",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
    );

    const logical_shortint_parity = shortint.addParityExecutable(
        b,
        context.host_target,
        optimize,
        context.shortint_objects,
    );
    const run_logical_shortint_parity = b.addRunArtifact(logical_shortint_parity);
    run_logical_shortint_parity.setCwd(b.path("."));
    const logical_shortint_parity_step = b.step("logical_shortint_parity", "Run the short-integer logical parity suite");
    logical_shortint_parity_step.dependOn(&run_logical_shortint_parity.step);

    const rotate_bits_parity = shortint.addRotateBitsParityExecutable(
        b,
        context.host_target,
        optimize,
        context.shortint_objects.rotate_bits,
    );
    const run_rotate_bits_parity = b.addRunArtifact(rotate_bits_parity);
    run_rotate_bits_parity.setCwd(b.path("."));
    const rotate_bits_parity_step = b.step("rotate_bits_parity", "Run the rotate-bits parity suite");
    rotate_bits_parity_step.dependOn(&run_rotate_bits_parity.step);

    const run_logical_boolean_ops_suite = addTestSuiteRun(b, test_suite, "zig_build/tests/testSuiteList_logical_boolean_ops.txt");
    const logical_boolean_ops_suite_step = b.step("logical_boolean_ops_suite", "Run the logical boolean operator suite");
    logical_boolean_ops_suite_step.dependOn(&run_logical_boolean_ops_suite.step);

    const stack_state_parity_objects = stack.addRuntimeObjects(b, context.host_target, optimize, "stack-parity");
    const stack_state_parity = stack.addParityExecutable(b, context.host_target, optimize, stack_state_parity_objects);
    const run_stack_state_parity = b.addRunArtifact(stack_state_parity);
    run_stack_state_parity.setCwd(b.path("."));
    const stack_state_parity_step = b.step("stack_state_parity", "Run the stack-state parity suite");
    stack_state_parity_step.dependOn(&run_stack_state_parity.step);

    const register_metadata_parity = register_metadata.addParityExecutable(b, context.host_target, optimize);
    const run_register_metadata_parity = b.addRunArtifact(register_metadata_parity);
    run_register_metadata_parity.setCwd(b.path("."));
    const register_metadata_parity_step = b.step("register_metadata_parity", "Run the register-metadata parity suite");
    register_metadata_parity_step.dependOn(&run_register_metadata_parity.step);

    const flags_parity = flags.addParityExecutable(b, context.host_target, optimize);
    const run_flags_parity = b.addRunArtifact(flags_parity);
    run_flags_parity.setCwd(b.path("."));
    const flags_parity_step = b.step("flags_parity", "Run the system-flags parity suite");
    flags_parity_step.dependOn(&run_flags_parity.step);

    const memory_parity = memory.addParityExecutable(b, context.host_target, optimize);
    const run_memory_parity = b.addRunArtifact(memory_parity);
    run_memory_parity.setCwd(b.path("."));
    const memory_parity_step = b.step("memory_parity", "Run the memory-state parity suite");
    memory_parity_step.dependOn(&run_memory_parity.step);

    const calc_state_parity = calc_state.addParityExecutable(b, context.host_target, optimize);
    const run_calc_state_parity = b.addRunArtifact(calc_state_parity);
    run_calc_state_parity.setCwd(b.path("."));
    const calc_state_parity_step = b.step("calc_state_parity", "Run the calc-state parity suite");
    calc_state_parity_step.dependOn(&run_calc_state_parity.step);

    const saveload_parity_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "saveLoadParity",
        "zig_build/tests/calc_state/save_load_parity_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
        false,
    );
    const run_saveload_parity = b.addRunArtifact(saveload_parity_harness);
    run_saveload_parity.setCwd(b.path("."));
    run_saveload_parity.addArg("zig_build/tests/calc_state/save_load_golden.sav");
    const saveload_parity_step = b.step("saveload_parity", "Run the save/load round-trip + golden parity harness");
    saveload_parity_step.dependOn(&run_saveload_parity.step);

    // Regenerate the golden save file from the current implementation.
    const gen_saveload_golden = b.addRunArtifact(saveload_parity_harness);
    gen_saveload_golden.setCwd(b.path("."));
    gen_saveload_golden.addArg("zig_build/tests/calc_state/save_load_golden.sav");
    gen_saveload_golden.addArg("--write-golden");
    const saveload_golden_step = b.step("saveload_golden", "Regenerate the save/load parity golden file");
    saveload_golden_step.dependOn(&gen_saveload_golden.step);

    // Keyboard ENTRY-layer harness: drives the host btnClicked entry path
    // (btnClicked -> btnPressed/Released -> processKeyAction -> NIM/exec), which
    // the main testSuite never reaches (it calls funcToTest directly).
    const keyboard_entry_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "keyboardEntry",
        "zig_build/tests/keyboard_state/keyboard_entry_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
        false,
    );
    const run_keyboard_entry = b.addRunArtifact(keyboard_entry_harness);
    run_keyboard_entry.setCwd(b.path("."));
    const keyboard_entry_step = b.step("keyboard_entry_parity", "Run the keyboard entry-layer (btnClicked) parity harness");
    keyboard_entry_step.dependOn(&run_keyboard_entry.step);

    // Annex A0: a coverage build of the keyboard harness -- the same full core,
    // but instrumented with sancov trace-pc-guard (LLVM backend) plus a
    // PC-recording runtime, so report-zig-coverage.sh can measure which
    // Zig-owner source lines the host harness actually executes. kcov is not
    // available in this environment and Zig 0.16 has no -fprofile-instr path, so
    // this is the coverage mechanism. Measurement-only: the sancov flag and the
    // handler are compiled ONLY into this dedicated binary, never a product or
    // normal-test one.
    //
    // REPORT-27 M-IDIOM-9: the keyboard_state and stack_state owners are exercised
    // by this harness (btnClicked dispatch + stack ops), but the shared context
    // objects are built WITHOUT the coverage flag and reused by sim/test, so we
    // cannot flip sancov on them (the handler symbol is linked only here). Instead
    // build dedicated "keyboardEntryCov" variants of just those two objects with
    // coverage=true and link them into this harness, so the report resolves their
    // Zig owner lines too -- not only the frontier owners compiled into the module.
    // The HostModuleConfig mirrors host/context.zig's keyboard_state wiring.
    const cov_keyboard_state_objects = keyboard_state.addHostRuntimeObjectsWithOptions(
        b,
        context.host_target,
        optimize,
        "keyboardEntryCov",
        .{
            .platform_define = context.common.platform_define,
            .word_size_define = context.common.word_size_define,
            .raspberry = context.common.raspberry,
            .decnumber_fastmul = context.common.decnumber_fastmul,
            .needs_gnu_source = context.common.needs_gnu_source,
            .have_dladdr = context.common.have_dladdr,
            .generated_headers = .{
                .version_headers_dir = context.version_headers_dir,
                .softmenu_catalogs_dir = context.generated.softmenu_catalogs.dirname(),
                .constant_pointers_h_dir = context.generated.constant_pointers_h.dirname(),
            },
        },
        .{ .coverage = true },
    );
    const cov_stack_state_objects = stack.addRuntimeObjectsWithOptions(
        b,
        context.host_target,
        optimize,
        "keyboardEntryCov",
        .{ .coverage = true },
    );
    const coverage_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "keyboardEntryCov",
        "zig_build/tests/keyboard_state/keyboard_entry_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        cov_keyboard_state_objects,
        cov_stack_state_objects,
        null,
        true,
    );
    coverage_harness.use_llvm = true;
    coverage_harness.sanitize_coverage_trace_pc_guard = true;
    coverage_harness.root_module.addCSourceFile(.{
        .file = b.path("zig_build/tests/coverage/sancov_handler.c"),
        .flags = &.{},
    });
    const run_coverage = b.addRunArtifact(coverage_harness);
    run_coverage.setCwd(b.path("."));
    const coverage_step = b.step("coverage", "Build+run the sancov-instrumented keyboard harness, emitting cov_pcs.txt for report-zig-coverage.sh (Annex A0)");
    coverage_step.dependOn(&run_coverage.step);

    // Annex A5: C-vs-Zig differential. The same full core, plus the pinned
    // upstream C oracle (extract_oracle.sh -> charstring_diff_oracle.c) linked
    // beside the Zig owner export, so the harness can byte-compare the two over
    // an enumerated input space. This is the catch the parity suites cannot give
    // for the replaced (compiled-out) owners -- on an M10 pin bump the oracle
    // tracks the new upstream C, so a Zig owner not re-ported to match goes RED.
    const charstring_diff_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "charstringDiff",
        "zig_build/tests/charstring_diff/charstring_diff_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
        false,
    );
    charstring_diff_harness.root_module.addCSourceFile(.{
        .file = b.path("zig_build/tests/charstring_diff/charstring_diff_oracle.c"),
        .flags = &.{},
    });
    const run_charstring_diff = b.addRunArtifact(charstring_diff_harness);
    run_charstring_diff.setCwd(b.path("."));
    const charstring_diff_step = b.step("charstring_diff", "Run the C-vs-Zig differential (stringGlyphLength vs the pinned upstream oracle) (Annex A5)");
    charstring_diff_step.dependOn(&run_charstring_diff.step);

    // Format-equivalence oracle (M24): a self-contained differential that proves
    // each C sprintf conversion byte-equal to its std.fmt translation over a fuzz
    // matrix (libc snprintf is the ground truth). Gates the sprintf->std.fmt
    // migration -- a translation may only be applied at a call site once it is
    // GREEN here. Pure Zig + libc; no core link needed.
    const format_parity_exe = b.addExecutable(.{
        .name = "format-parity-oracle",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/tests/format/format_parity.zig"),
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "float_format", .module = b.createModule(.{
                    .root_source_file = b.path("zig_src/abi/float_format.zig"),
                    .target = context.host_target,
                    .optimize = optimize,
                }) },
            },
        }),
    });
    const run_format_parity = b.addRunArtifact(format_parity_exe);
    run_format_parity.setCwd(b.path("."));
    const format_parity_step = b.step("format_parity", "Run the sprintf<->std.fmt format-equivalence oracle (M24)");
    format_parity_step.dependOn(&run_format_parity.step);

    // Headless .p47 program runner: load a user program file through the real
    // load path and XEQ it from the top on the full calc core (no GTK). Catches
    // crashes and (wrapped in `timeout`) infinite loops in the actual programs.
    //   zig build pgm_run -- res/PROGRAMS/BinetV3.p47
    const pgm_run_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "pgmRun",
        "zig_build/tests/pgm_run/pgm_run_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
        false,
    );
    const run_pgm_run = b.addRunArtifact(pgm_run_harness);
    run_pgm_run.setCwd(b.path("."));
    if (b.option([]const u8, "pgm", "the .p47 program to load and run")) |pgm| {
        run_pgm_run.addArgs(&.{pgm});
    }
    const pgm_run_step = b.step("pgm_run", "Load and XEQ a .p47 program on the full core (-Dpgm=<file.p47>)");
    pgm_run_step.dependOn(&run_pgm_run.step);

    // M1 (REPORT-27 ANNEX B): run a corpus of MALFORMED .p47 files through the real
    // program-load path under AddressSanitizer. This is the one justified memory-
    // correctness task -- the load path is the empirical bug surface (upstream 577
    // statefile overflow, decode-literal-base-oob), and the existing cov tests only
    // exercise VALID round-trips. A graceful reject (no labels -> exit 1) passes; an
    // OOB read/write on a malformed file aborts ASAN -> the driver fails the build.
    const pgm_run_asan = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "pgmRunAsan",
        "zig_build/tests/pgm_run/pgm_run_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        .full,
        false,
    );
    const pgm_load_fuzz_cmd = b.addSystemCommand(&.{ "bash", "zig_build/tests/pgm_run/run-pgm-load-fuzz.sh" });
    pgm_load_fuzz_cmd.addArtifactArg(pgm_run_asan);
    pgm_load_fuzz_cmd.addArg("zig_build/tests/pgm_run/malformed");
    pgm_load_fuzz_cmd.setCwd(b.path("."));
    const pgm_load_fuzz_step = b.step("pgm_load_fuzz", "M1: run malformed .p47 files through the load path under ASAN");
    pgm_load_fuzz_step.dependOn(&pgm_load_fuzz_cmd.step);

    // M-SAFE-7 (REPORT-30): the same treatment for STATE files. saveload_parity
    // and saveload_golden only round-trip files the calculator just wrote, so the
    // 137 lines of bounds 31fb6f755 added to calc_state_restore.zig, and the
    // matrix-dimension guard M-SAFE-1 ported, had no adversarial coverage at all.
    // Built at the default optimize level on purpose: Zig's safety checks are the
    // detector here, since an out-of-range @intCast on the load path traps in a
    // safe build and wraps silently in the ReleaseSmall firmware.
    const state_load_harness = host_builders.addFullCoreHarness(
        b,
        context.host_target,
        "stateLoadFuzz",
        "zig_build/tests/calc_state/state_load_harness.c",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        .full,
        false,
    );
    const state_load_fuzz_cmd = b.addSystemCommand(&.{ "bash", "zig_build/tests/calc_state/run-state-load-fuzz.sh" });
    state_load_fuzz_cmd.addArtifactArg(state_load_harness);
    state_load_fuzz_cmd.addArg("zig_build/tests/calc_state/malformed");
    state_load_fuzz_cmd.setCwd(b.path("."));
    const state_load_fuzz_step = b.step("state_load_fuzz", "M-SAFE-7: run malformed state files through the real restore path");
    state_load_fuzz_step.dependOn(&state_load_fuzz_cmd.step);

    // Program-memory pointer-math harness: verifies the HW-geometry-dependent
    // save/load logic (RAM_SIZE_IN_BLOCKS + the cross-hardware relocation) for
    // BOTH the NEW_HW (host/DMCP5/DM42n) and OLD_HW (DMCP/original DM42) lanes.
    // The host parity round-trip only covers NEW_HW; this makes the OLD_HW
    // firmware lane verifiable without a device.
    const progmem_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/core/persist/calc_state_progmem.zig"),
            .target = context.host_target,
            .optimize = optimize,
        }),
    });
    const run_progmem_test = b.addRunArtifact(progmem_test);
    const progmem_test_step = b.step("state-progmem-test", "Run the program-memory pointer-math harness (NEW_HW + OLD_HW)");
    progmem_test_step.dependOn(&run_progmem_test.step);

    // The DMCP key ring buffer is `#if DMCP_BUILD`-only, so the host testSuite
    // never reaches it; its embedded tests make the buffer mechanics verifiable
    // without a device before the bridge port wires it onto the firmware lanes.
    const ringbuffer_test_module = b.createModule(.{
        .root_source_file = b.path("zig_src/core/input/keyboard_state_ringbuffer.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    const ringbuffer_build_options = b.addOptions();
    ringbuffer_build_options.addOption(bool, "is_r47", false);
    ringbuffer_test_module.addOptions("keyboard_state_build_options", ringbuffer_build_options);
    const ringbuffer_test = b.addTest(.{ .root_module = ringbuffer_test_module });
    const run_ringbuffer_test = b.addRunArtifact(ringbuffer_test);
    const ringbuffer_test_step = b.step("keyboard_ringbuffer_test", "Run the DMCP key ring-buffer mechanics tests");
    ringbuffer_test_step.dependOn(&run_ringbuffer_test.step);

    // REPORT-23 §7.2/§11: the idiomatic-refactor colocated `test {}` blocks. These
    // are hermetic (no C runtime) -- the L1 abi ABI-contract asserts and, as the
    // L2 owner cores land, their pure-logic tests. The C parity oracle stays the
    // authority for behavior; this covers invariants the oracle cannot express.
    const idiom_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/abi/types.zig"),
            .target = context.host_target,
            .optimize = optimize,
        }),
    });
    const run_idiom_test = b.addRunArtifact(idiom_test);
    const idiom_test_step = b.step("idiom-test", "Run the REPORT-23 idiomatic-Zig colocated test blocks");
    idiom_test_step.dependOn(&run_idiom_test.step);

    // Seam-and-core harness: cross-check the abi/types.zig numeric mirrors
    // against the translate-c'd upstream decNumber-family headers, so a wrong
    // layout (silent-corruption class) fails here rather than at runtime. This
    // must gate green before abi/types.zig is generated. Wiring mirrors the
    // generate_constants translate-c root (dep/decNumberICU + src/c47 includes).
    const abi_layout_c_bindings = b.addTranslateC(.{
        .root_source_file = b.path("zig_build/tools/translate_c/abi_layout_oracle.h"),
        .target = context.host_target,
        .optimize = optimize,
        .link_libc = true,
    });
    abi_layout_c_bindings.defineCMacro("PC_BUILD", "1");
    abi_layout_c_bindings.defineCMacro(context.common.platform_define, "1");
    abi_layout_c_bindings.defineCMacro(context.common.word_size_define, "1");
    abi_layout_c_bindings.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    abi_layout_c_bindings.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    const abi_layout_module = b.createModule(.{
        .root_source_file = b.path("zig_build/tests/abi_layout/abi_layout_oracle.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    abi_layout_module.addImport("c_bindings", abi_layout_c_bindings.createModule());
    abi_layout_module.addImport("abi", b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = context.host_target,
        .optimize = optimize,
    }));
    // C-side static-assert companion: the bitfield/union types translate-c can
    // only expose as opaque are pinned here, compiled against the upstream C.
    abi_layout_module.link_libc = true;
    abi_layout_module.addCSourceFile(.{
        .file = b.path("zig_build/tests/abi_layout/abi_layout_c_asserts.c"),
        .flags = &.{
            "-DPC_BUILD=1",
            b.fmt("-D{s}=1", .{context.common.platform_define}),
            b.fmt("-D{s}=1", .{context.common.word_size_define}),
        },
    });
    abi_layout_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    abi_layout_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    const abi_layout_test = b.addTest(.{ .root_module = abi_layout_module });
    const run_abi_layout_test = b.addRunArtifact(abi_layout_test);
    const abi_layout_step = b.step("abi-layout-parity", "Cross-check abi/types.zig mirrors against the upstream C layout");
    abi_layout_step.dependOn(&run_abi_layout_test.step);

    const keyboard_state_parity = keyboard_state.addParityExecutable(b, context.host_target, optimize);
    const run_keyboard_state_parity = b.addRunArtifact(keyboard_state_parity);
    run_keyboard_state_parity.setCwd(b.path("."));
    const keyboard_state_parity_step = b.step("keyboard_state_parity", "Run the keyboard-state parity suite");
    keyboard_state_parity_step.dependOn(&run_keyboard_state_parity.step);

    const math_command_wrappers_parity = math_command_wrappers.addParityExecutable(b, context.host_target, optimize);
    const run_math_command_wrappers_parity = b.addRunArtifact(math_command_wrappers_parity);
    run_math_command_wrappers_parity.setCwd(b.path("."));
    const math_command_wrappers_parity_step = b.step("math_command_wrappers_parity", "Run the math-command wrapper parity suite");
    math_command_wrappers_parity_step.dependOn(&run_math_command_wrappers_parity.step);

    const math_ln_complex_oracle = addMathLnComplexOracle(b, context, optimize);
    const run_math_ln_complex_oracle = b.addRunArtifact(math_ln_complex_oracle);
    run_math_ln_complex_oracle.setCwd(b.path("."));
    const math_ln_complex_oracle_step = b.step("math_ln_complex_oracle", "Run the direct lnComplex helper oracle");
    math_ln_complex_oracle_step.dependOn(&run_math_ln_complex_oracle.step);

    const math_eigen_oracle = addMathEigenOracle(b, context, optimize);
    const run_math_eigen_oracle = b.addRunArtifact(math_eigen_oracle);
    run_math_eigen_oracle.setCwd(b.path("."));
    const eigen_parity_step = b.step("eigen_parity", "Run the eigenvalue worker golden oracle (matrix.c eigen engine)");
    eigen_parity_step.dependOn(&run_math_eigen_oracle.step);

    const math_real_rectangular_to_polar_oracle = addMathRealRectangularToPolarOracle(b, context, optimize);
    const run_math_real_rectangular_to_polar_oracle = b.addRunArtifact(math_real_rectangular_to_polar_oracle);
    run_math_real_rectangular_to_polar_oracle.setCwd(b.path("."));
    const math_real_rectangular_to_polar_oracle_step = b.step("math_real_rectangular_to_polar_oracle", "Run the direct realRectangularToPolar helper oracle");
    math_real_rectangular_to_polar_oracle_step.dependOn(&run_math_real_rectangular_to_polar_oracle.step);

    const math_atan_oracle = addMathAtanOracle(b, context, optimize);
    const run_math_atan_oracle = b.addRunArtifact(math_atan_oracle);
    run_math_atan_oracle.setCwd(b.path("."));
    const math_atan_oracle_step = b.step("math_atan_oracle", "Run the direct C47_WP34S_Atan helper oracle");
    math_atan_oracle_step.dependOn(&run_math_atan_oracle.step);

    const math_real_trig_primitives_oracle = addMathRealTrigPrimitivesOracle(b, context, optimize);
    const run_math_real_trig_primitives_oracle = b.addRunArtifact(math_real_trig_primitives_oracle);
    run_math_real_trig_primitives_oracle.setCwd(b.path("."));
    const math_real_trig_primitives_oracle_step = b.step("math_real_trig_primitives_oracle", "Run the direct real trig primitive oracle");
    math_real_trig_primitives_oracle_step.dependOn(&run_math_real_trig_primitives_oracle.step);

    const math_circular_trig_oracle = addMathCircularTrigOracle(b, context, optimize);
    const run_math_circular_trig_oracle = b.addRunArtifact(math_circular_trig_oracle);
    run_math_circular_trig_oracle.setCwd(b.path("."));
    const math_circular_trig_oracle_step = b.step("math_circular_trig_oracle", "Run the direct circular trig helper oracle");
    math_circular_trig_oracle_step.dependOn(&run_math_circular_trig_oracle.step);

    const math_atan2_oracle = addMathAtan2Oracle(b, context, optimize);
    const run_math_atan2_oracle = b.addRunArtifact(math_atan2_oracle);
    run_math_atan2_oracle.setCwd(b.path("."));
    const math_atan2_oracle_step = b.step("math_atan2_oracle", "Run the direct C47_WP34S_Atan2 helper oracle");
    math_atan2_oracle_step.dependOn(&run_math_atan2_oracle.step);

    const math_random_parity = math_command_wrappers.addRandomParityExecutable(b, context.host_target, optimize);
    const run_math_random_parity = b.addRunArtifact(math_random_parity);
    run_math_random_parity.setCwd(b.path("."));
    const math_random_parity_step = b.step("math_random_parity", "Run the math random and PCG parity suite");
    math_random_parity_step.dependOn(&run_math_random_parity.step);

    const constants_parity = constants.addParityExecutable(b, context.host_target, optimize);
    const run_constants_parity = b.addRunArtifact(constants_parity);
    run_constants_parity.setCwd(b.path("."));
    const constants_parity_step = b.step("constants_parity", "Run the constants-command parity suite");
    constants_parity_step.dependOn(&run_constants_parity.step);

    const tone_parity = tone.addParityExecutable(b, context.host_target, optimize);
    const run_tone_parity = b.addRunArtifact(tone_parity);
    run_tone_parity.setCwd(b.path("."));
    const tone_parity_step = b.step("tone_parity", "Run the tone UI parity suite");
    tone_parity_step.dependOn(&run_tone_parity.step);

    const distribution_owners_module = b.createModule(.{
        .root_source_file = b.path("zig_src/shell/distributions/distributions_test_owners.zig"),
        .target = context.host_target,
        .optimize = optimize,
    });
    // The distribution owners (via frontier_distribution_runtime) expect the same
    // frontier_build_options the product frontier object gets; the harness is a
    // host-style link, so keep all distributions and the EXTRA_INFO hints.
    const distribution_owners_options = b.addOptions();
    distribution_owners_options.addOption(bool, "strip_17b", false);
    distribution_owners_options.addOption(bool, "strip_17c", false);
    distribution_owners_options.addOption(bool, "extra_info_on_calc_error", true);
    // frontier_distribution_runtime derives code_section from these; the harness is
    // a host link, so both are false (code_section resolves to .text / __TEXT).
    distribution_owners_options.addOption(bool, "dmcp_build", false);
    distribution_owners_options.addOption(bool, "old_hw", false);
    distribution_owners_module.addOptions("frontier_build_options", distribution_owners_options);
    const distribution_parity = b.addExecutable(.{
        .name = "distribution-parity",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/tests/distributions/distribution_parity.zig"),
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "dist_owners", .module = distribution_owners_module },
            },
        }),
    });
    abi_host.addToModule(b, distribution_parity.root_module, context.host_target, optimize, "distribution-parity");
    // Match the production decNumber compile: it includes decNumber.h directly
    // (not c47.h), so DECNUMDIGITS keeps its default of 1 and the library mallocs
    // working buffers per operation. Forcing DECNUMDIGITS=75 instead sized those
    // buffers onto the stack and overran the caller frame on in-place ops.
    const distribution_dec_flags: []const []const u8 = if (context.host_target.result.os.tag == .windows)
        &.{ "-Wno-date-time", "-fno-sanitize=undefined", "-fno-strict-aliasing", "-DDECNUMBER_FASTMUL=1" }
    else
        &.{ "-Wno-date-time", "-fno-sanitize=undefined", "-DDECNUMBER_FASTMUL=1" };
    distribution_parity.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    distribution_parity.root_module.addCSourceFiles(.{
        .root = build_common.upstreamPath(b, "dep"),
        .files = build_common.decnumber_sources,
        .flags = distribution_dec_flags,
    });
    const run_distribution_parity = b.addRunArtifact(distribution_parity);
    run_distribution_parity.setCwd(b.path("."));
    const distribution_parity_step = b.step("distribution_parity", "Run the statistical-distribution parity suite");
    distribution_parity_step.dependOn(&run_distribution_parity.step);

    const keyboard_statusbar_flags_regression = b.addExecutable(.{
        .name = "keyboard-statusbar-flags-regression",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, keyboard_statusbar_flags_regression.root_module, context.host_target, optimize, "keyboard-statusbar-flags-regression");
    host_platform.addHostMacros(keyboard_statusbar_flags_regression.root_module, context.common);
    keyboard_statusbar_flags_regression.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    keyboard_statusbar_flags_regression.root_module.addIncludePath(b.path("zig_bridge/state"));
    keyboard_statusbar_flags_regression.root_module.addCSourceFile(.{
        .file = b.path("zig_build/tests/keyboard_statusbar_flags_regression.c"),
        .flags = &.{},
    });
    const run_keyboard_statusbar_flags_regression = b.addRunArtifact(keyboard_statusbar_flags_regression);
    run_keyboard_statusbar_flags_regression.setCwd(b.path("."));
    const keyboard_statusbar_flags_regression_step = b.step("keyboard_statusbar_flags_regression", "Run the keyboard statusbar flag-clearing regression");
    keyboard_statusbar_flags_regression_step.dependOn(&run_keyboard_statusbar_flags_regression.step);

    const program_serialization_parity = program_serialization.addParityExecutable(b, context.host_target, optimize);
    const run_program_serialization_parity = b.addRunArtifact(program_serialization_parity);
    run_program_serialization_parity.setCwd(b.path("."));
    const program_serialization_parity_step = b.step("program_serialization_parity", "Run the program-serialization parity suite");
    program_serialization_parity_step.dependOn(&run_program_serialization_parity.step);

    const run_test_suite = addTestSuiteRun(b, test_suite, build_common.upstreamPathString(b, "src/testSuite/tests/testSuiteList.txt"));
    const run_test_suite_z47 = addTestSuiteRun(b, test_suite, z47_test_list);
    const test_step = b.step("test", "Run the host test suite");
    test_step.dependOn(&run_keyboard_statusbar_flags_regression.step);
    test_step.dependOn(&run_test_suite.step);
    test_step.dependOn(&run_test_suite_z47.step);

    const test_suite_asan = host_builders.addTestSuite(
        b,
        context.host_target,
        "testSuite-asan",
        optimize,
        context.core_sources,
        context.test_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        .full,
    );
    const run_test_suite_asan = addTestSuiteRun(b, test_suite_asan, build_common.upstreamPathString(b, "src/testSuite/tests/testSuiteList.txt"));
    const run_test_suite_asan_z47 = addTestSuiteRun(b, test_suite_asan, z47_test_list);
    const test_asan_step = b.step("test_asan", "Run the host test suite with native Zig C sanitizing");
    test_asan_step.dependOn(&run_test_suite_asan.step);
    test_asan_step.dependOn(&run_test_suite_asan_z47.step);

    const repeattest_step = b.step("repeattest", "Run the host test suite incrementally");
    repeattest_step.dependOn(&run_test_suite.step);
    repeattest_step.dependOn(&run_test_suite_z47.step);

    const update_fonts = b.addUpdateSourceFiles();
    update_fonts.addCopyFileToSource(context.generated.raster_fonts_data, build_common.upstreamPathString(b, "src/generated/" ++ "rasterFontsData.c"));
    const fonts_step = b.step("fonts", "Refresh rasterFontsData.c from the font generator");
    fonts_step.dependOn(&update_fonts.step);

    const update_constants = b.addUpdateSourceFiles();
    update_constants.addCopyFileToSource(context.generated.constant_pointers_c, build_common.upstreamPathString(b, "src/generated/" ++ "constantPointers.c"));
    update_constants.addCopyFileToSource(context.generated.constant_pointers_h, build_common.upstreamPathString(b, "src/generated/constantPointers.h"));
    update_constants.addCopyFileToSource(context.generated.constant_pointers2_c, build_common.upstreamPathString(b, "src/generated/" ++ "constantPointers2.c"));
    const constants_step = b.step("constants", "Refresh generated constant pointer sources");
    constants_step.dependOn(&update_constants.step);

    const update_catalogs = b.addUpdateSourceFiles();
    update_catalogs.addCopyFileToSource(context.generated.softmenu_catalogs, build_common.upstreamPathString(b, "src/generated/softmenuCatalogs.h"));
    const catalogs_step = b.step("catalogs", "Refresh generated softmenu catalogs");
    catalogs_step.dependOn(&update_catalogs.step);

    const update_testpgms = b.addUpdateSourceFiles();
    update_testpgms.addCopyFileToSource(context.generated.test_pgms_bin, build_common.upstreamPathString(b, "res/testPgms/testPgms.bin"));
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

    const outputs: host_types.SimulatorOutputs = .{
        .c47_exe = sim,
        .c47_bin = sim.getEmittedBin(),
        .r47_bin = simr47.getEmittedBin(),
    };

    addCleanStep(b);
    addDocsStep(b);

    return outputs;
}

fn addCleanStep(b: *std.Build) void {
    const cmd = build_common.addBashCommand(b,
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
    // The bash command runs in the build root (addBashCommandFmt sets cwd to "."),
    // so a build-root-relative install path is what the tools want; b.pathJoin is
    // stable across the 0.16 baseline and the monitored Zig master.
    const docs_build_root = b.pathJoin(&.{ "zig-out", "docs/code" });
    const docs_source_root = build_common.upstreamPathString(b, "docs/code");
    const cmd = build_common.addBashCommandFmt(b,
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
        \\python3 -m sphinx -M html '{s}' '{s}'
    , .{ docs_build_root, docs_build_root, docs_source_root, docs_build_root });

    const step = b.step("docs", "Build documentation with Zig-owned Sphinx orchestration");
    step.dependOn(&cmd.step);
}
