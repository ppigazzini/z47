const std = @import("std");
const build_common = @import("../common.zig");
const host_builders = @import("builders.zig");
const host_platform = @import("platform.zig");
const shortint_rewrites = @import("../leaf/shortint_rewrites.zig");
const calc_state_rewrites = @import("../state/calc_state_rewrites.zig");
const flags_rewrites = @import("../state/flags_rewrites.zig");
const keyboard_state_rewrites = @import("../state/keyboard_state_rewrites.zig");
const memory_rewrites = @import("../state/memory_rewrites.zig");
const program_serialization_rewrites = @import("../state/program_serialization_rewrites.zig");
const register_metadata_rewrites = @import("../state/register_metadata_rewrites.zig");
const stack_rewrites = @import("../state/stack_rewrites.zig");
const host_types = @import("types.zig");

const upstream_test_list = "src/testSuite/tests/testSuiteList.txt";
const z47_test_list = "zig_build/tests/testSuiteList_z47.txt";

fn addTestSuiteRun(b: *std.Build, test_suite: *std.Build.Step.Compile, list_path: []const u8) *std.Build.Step.Run {
    const run_test_suite = b.addRunArtifact(test_suite);
    run_test_suite.setCwd(b.path("."));
    run_test_suite.addArg(list_path);
    return run_test_suite;
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
        context.shortint_leaf_objects,
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
        context.shortint_leaf_objects,
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
        context.shortint_leaf_objects,
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
        context.shortint_leaf_objects,
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
        context.shortint_leaf_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        null,
    );

    const logical_shortint_parity = shortint_rewrites.addParityExecutable(
        b,
        context.host_target,
        optimize,
        .{
            .logical_mask = context.shortint_leaf_objects.logical_mask,
            .logical_count_bits = context.shortint_leaf_objects.logical_count_bits,
            .logical_set_clear_flip_bits = context.shortint_leaf_objects.logical_set_clear_flip_bits,
        },
    );
    const run_logical_shortint_parity = b.addRunArtifact(logical_shortint_parity);
    run_logical_shortint_parity.setCwd(b.path("."));
    const logical_shortint_parity_step = b.step("logical_shortint_parity", "Run the short-integer logical leaf-module parity suite");
    logical_shortint_parity_step.dependOn(&run_logical_shortint_parity.step);

    const stack_state_parity = stack_rewrites.addParityExecutable(b, context.host_target, optimize, context.stack_state_objects);
    const run_stack_state_parity = b.addRunArtifact(stack_state_parity);
    run_stack_state_parity.setCwd(b.path("."));
    const stack_state_parity_step = b.step("stack_state_parity", "Run the stack-state parity suite");
    stack_state_parity_step.dependOn(&run_stack_state_parity.step);

    const register_metadata_parity = register_metadata_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_register_metadata_parity = b.addRunArtifact(register_metadata_parity);
    run_register_metadata_parity.setCwd(b.path("."));
    const register_metadata_parity_step = b.step("register_metadata_parity", "Run the register-metadata parity suite");
    register_metadata_parity_step.dependOn(&run_register_metadata_parity.step);

    const flags_parity = flags_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_flags_parity = b.addRunArtifact(flags_parity);
    run_flags_parity.setCwd(b.path("."));
    const flags_parity_step = b.step("flags_parity", "Run the system-flags parity suite");
    flags_parity_step.dependOn(&run_flags_parity.step);

    const memory_parity = memory_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_memory_parity = b.addRunArtifact(memory_parity);
    run_memory_parity.setCwd(b.path("."));
    const memory_parity_step = b.step("memory_parity", "Run the memory-state parity suite");
    memory_parity_step.dependOn(&run_memory_parity.step);

    const calc_state_parity = calc_state_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_calc_state_parity = b.addRunArtifact(calc_state_parity);
    run_calc_state_parity.setCwd(b.path("."));
    const calc_state_parity_step = b.step("calc_state_parity", "Run the calc-state parity suite");
    calc_state_parity_step.dependOn(&run_calc_state_parity.step);

    const keyboard_state_parity = keyboard_state_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_keyboard_state_parity = b.addRunArtifact(keyboard_state_parity);
    run_keyboard_state_parity.setCwd(b.path("."));
    const keyboard_state_parity_step = b.step("keyboard_state_parity", "Run the keyboard-state parity suite");
    keyboard_state_parity_step.dependOn(&run_keyboard_state_parity.step);

    const keyboard_statusbar_flags_regression = b.addExecutable(.{
        .name = "keyboard-statusbar-flags-regression",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = context.host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    host_platform.addHostMacros(keyboard_statusbar_flags_regression.root_module, context.common);
    keyboard_statusbar_flags_regression.root_module.addIncludePath(b.path("src/c47"));
    keyboard_statusbar_flags_regression.root_module.addIncludePath(b.path("zig_bridge/state"));
    keyboard_statusbar_flags_regression.root_module.addCSourceFile(.{
        .file = b.path("zig_build/tests/keyboard_statusbar_flags_regression.c"),
        .flags = &.{},
    });
    const run_keyboard_statusbar_flags_regression = b.addRunArtifact(keyboard_statusbar_flags_regression);
    run_keyboard_statusbar_flags_regression.setCwd(b.path("."));
    const keyboard_statusbar_flags_regression_step = b.step("keyboard_statusbar_flags_regression", "Run the keyboard statusbar flag-clearing regression");
    keyboard_statusbar_flags_regression_step.dependOn(&run_keyboard_statusbar_flags_regression.step);

    const program_serialization_parity = program_serialization_rewrites.addParityExecutable(b, context.host_target, optimize);
    const run_program_serialization_parity = b.addRunArtifact(program_serialization_parity);
    run_program_serialization_parity.setCwd(b.path("."));
    const program_serialization_parity_step = b.step("program_serialization_parity", "Run the program-serialization parity suite");
    program_serialization_parity_step.dependOn(&run_program_serialization_parity.step);

    const run_test_suite = addTestSuiteRun(b, test_suite, upstream_test_list);
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
        context.shortint_leaf_objects,
        context.keyboard_state_objects,
        context.stack_state_objects,
        .full,
    );
    const run_test_suite_asan = addTestSuiteRun(b, test_suite_asan, upstream_test_list);
    const run_test_suite_asan_z47 = addTestSuiteRun(b, test_suite_asan, z47_test_list);
    const test_asan_step = b.step("test_asan", "Run the host test suite with native Zig C sanitizing");
    test_asan_step.dependOn(&run_test_suite_asan.step);
    test_asan_step.dependOn(&run_test_suite_asan_z47.step);

    const repeattest_step = b.step("repeattest", "Run the host test suite incrementally");
    repeattest_step.dependOn(&run_test_suite.step);
    repeattest_step.dependOn(&run_test_suite_z47.step);

    const update_fonts = b.addUpdateSourceFiles();
    update_fonts.addCopyFileToSource(context.generated.raster_fonts_data, "src/generated/rasterFontsData.c");
    const fonts_step = b.step("fonts", "Refresh rasterFontsData.c from the font generator");
    fonts_step.dependOn(&update_fonts.step);

    const update_constants = b.addUpdateSourceFiles();
    update_constants.addCopyFileToSource(context.generated.constant_pointers_c, "src/generated/constantPointers.c");
    update_constants.addCopyFileToSource(context.generated.constant_pointers_h, "src/generated/constantPointers.h");
    update_constants.addCopyFileToSource(context.generated.constant_pointers2_c, "src/generated/constantPointers2.c");
    const constants_step = b.step("constants", "Refresh generated constant pointer sources");
    constants_step.dependOn(&update_constants.step);

    const update_catalogs = b.addUpdateSourceFiles();
    update_catalogs.addCopyFileToSource(context.generated.softmenu_catalogs, "src/generated/softmenuCatalogs.h");
    const catalogs_step = b.step("catalogs", "Refresh generated softmenu catalogs");
    catalogs_step.dependOn(&update_catalogs.step);

    const update_testpgms = b.addUpdateSourceFiles();
    update_testpgms.addCopyFileToSource(context.generated.test_pgms_bin, "res/testPgms/testPgms.bin");
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
    const docs_build_root = b.getInstallPath(.prefix, "docs/code");
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
        \\python3 -m sphinx -M html docs/code '{s}'
    , .{ docs_build_root, docs_build_root, docs_build_root });

    const step = b.step("docs", "Build documentation with Zig-owned Sphinx orchestration");
    step.dependOn(&cmd.step);
}
