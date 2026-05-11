const std = @import("std");
const build_common = @import("../common.zig");
const host_builders = @import("builders.zig");
const host_types = @import("types.zig");

pub fn registerSteps(b: *std.Build, context: host_types.Context, optimize: std.builtin.OptimizeMode) void {
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
        "USER_R47",
        null,
    );
    const simr47_install = b.addInstallArtifact(simr47, .{});
    const simr47_step = b.step("simr47", "Build the R47 simulator");
    simr47_step.dependOn(&simr47_install.step);

    const both_step = b.step("both", "Build both host simulators");
    both_step.dependOn(&sim_install.step);
    both_step.dependOn(&simr47_install.step);

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
        null,
    );
    const run_test_suite = b.addRunArtifact(test_suite);
    run_test_suite.setCwd(b.path("."));
    run_test_suite.addArg("src/testSuite/tests/testSuiteList.txt");
    const test_step = b.step("test", "Run the host test suite");
    test_step.dependOn(&run_test_suite.step);

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
        .full,
    );
    const run_test_suite_asan = b.addRunArtifact(test_suite_asan);
    run_test_suite_asan.setCwd(b.path("."));
    run_test_suite_asan.addArg("src/testSuite/tests/testSuiteList.txt");
    const test_asan_step = b.step("test_asan", "Run the host test suite with native Zig C sanitizing");
    test_asan_step.dependOn(&run_test_suite_asan.step);

    const repeattest_step = b.step("repeattest", "Run the host test suite incrementally");
    repeattest_step.dependOn(&run_test_suite.step);

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

    addCleanStep(b);
    addDocsStep(b);
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