const std = @import("std");
const abi_host = @import("../abi_host.zig");
const host_platform = @import("../host/platform.zig");

const replaced_core_sources_manifest = @embedFile("math_command_wrapper_replaced_core_sources.txt");
const runtime_helper_sources_manifest = @embedFile("math_command_wrapper_runtime_helper_sources.txt");

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') {
            continue;
        }
        if (std.mem.eql(u8, line, needle)) {
            return true;
        }
    }
    return false;
}

pub const RuntimeObjects = struct {
    math_command_wrappers: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
        while (lines.next()) |line_raw| {
            const source = std.mem.trim(u8, line_raw, " \t");
            if (source.len == 0 or source[0] == '#') {
                continue;
            }
            cmd.addArg(source);
        }
        cmd.addFileArg(self.math_command_wrappers.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    /// True where this executable's C sources are compiled with
    /// TESTSUITE_BUILD, so the Zig owners answer the same question the C half
    /// does: fnSNAP freezes the clock the date/time formatters read, and RESET
    /// loads the sample programs. The testSuite and the full-core harnesses set
    /// it; the product and the simulator leave it false.
    is_testsuite_build: bool = false,
    /// The DM42 board (OLD_HW). Its SRAM2 .bss ends exactly at the DMCP system
    /// data block, and the four inverse-trig result slots are 588 bytes it does
    /// not have, so that board computes every call instead of caching it. Set by
    /// the two firmware call sites that build for the board, not inferred from
    /// the object name.
    old_hw: bool = false,
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // Per-package OPTION_* from defines.h. Each is an include flag: with it out,
    // upstream compiles the whole owner down to empty stubs, so the commands
    // return without touching the stack. Defaults match a host build.
    option_elliptic: bool = true,
    option_bessel: bool = true,
    option_ortho: bool = true,
    option_dist_normal: bool = true,
    // OPTION_EIGEN gates the eigenvalue/eigenvector/QR/matrix-sqrt half of
    // matrix.c (EIGVAL, EIGVEC, M.QR, MSQRT) and squareRoot.c's 159-digit
    // helpers; LU, determinant and inverse stay either way. Upstream #undef's it
    // for DMCP packages 1, 2 and 4; package 3, DMCP5 and host keep it.
    option_eigen: bool = true,
    // OPTION_VECTOR gates matrix.c's 2D/3D vector command surface and the
    // rectangular <-> spherical/cylindrical/polar conversions in toRect.c and
    // toPolar.c. Upstream #undef's it in the block common to DMCP packages 1-4,
    // so no DM42 package has it; DMCP5 and host do.
    option_vector: bool = true,
    // OPTION_XFN_1000 gates the 1071-digit XFN math in xfn.c and wp34s.c. Its own
    // defines.h comment says it "does not work on DM42, due to stack constraint";
    // upstream #undef's it in the same "common to packages 1-4" block, so it is
    // off for every DM42 package and on for DMCP5 and host.
    option_xfn_1000: bool = true,
    // OPTION_SLVP_POLY gates SLVP (every root of a polynomial, through the
    // companion matrix and the QR eigensolver) in slvp.c and matrix.c. Same
    // block, so the same per-target answer. defines.h also #undef's it whenever
    // OPTION_EIGEN is out, which adds nothing: every target that drops EIGEN has
    // already dropped SLVP with the block.
    option_slvp_poly: bool = true,
    // OPTION_CUBIC_159 and OPTION_EIGEN_159 raise the internal working precision
    // of SLVC and of the eigen solver to 159 digits, which is what makes 34-digit
    // input accurate; slvc.c, slvq.c, matrix.c, squareRoot.c, cubeRoot.c,
    // division.c, multiplication.c and comparisonReals.c all carry 159-digit
    // bodies behind them. Same block, so both are off for every DM42 package.
    //
    // Upstream writes several of those bodies as
    // `OPTION_SQUARE_159 || OPTION_CUBIC_159 || OPTION_EIGEN_159`. There is no
    // option_square_159 here because defines.h #undef's OPTION_SQUARE_159
    // unconditionally at the top and never defines it again -- SLVQ's worst case
    // is accurate at the standard 75 digits -- so the term is false in every
    // configuration and the disjunction is the other two.
    option_cubic_159: bool = true,
    option_eigen_159: bool = true,
    // Whether the owner exports its lnComplex under the plain C name. True for
    // the product, sim and testSuite links, where mathematics/ln.c is filtered
    // out and the owner is the only definition. The focused oracles set it false:
    // each of them already links a C lnComplex, so a second one would clash.
    export_public_ln_complex: bool = true,
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/numeric/command_wrappers.zig"),
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings, imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    addBuildOptions(b, module, name_prefix, options);

    return b.addObject(.{
        .name = b.fmt("{s}-math-command-wrappers", .{name_prefix}),
        .root_module = module,
    });
}

/// Register `math_command_wrappers_build_options` on a module rooted anywhere in
/// the mathematics owner tree. Every option the tree reads is added here
/// unconditionally, so a focused oracle that compiles a subset of the owners is
/// given the same option set as the product object and an owner never has to
/// cope with an option being absent.
pub fn addBuildOptions(
    b: *std.Build,
    module: *std.Build.Module,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) void {
    const build_options = b.addOptions();
    build_options.addOption(bool, "use_fake_wp34s_model", std.mem.endsWith(u8, name_prefix, "parity"));
    build_options.addOption(bool, "use_fake_wp34s_harness_surface", std.mem.eql(u8, name_prefix, "parity") or std.mem.eql(u8, name_prefix, "random-parity"));
    build_options.addOption(bool, "export_public_ln_complex", options.export_public_ln_complex);
    // Passed in by whoever also hands the C sources -DTESTSUITE_BUILD, so the Zig
    // random seed is the deterministic test seed in every executable whose C half
    // is a testSuite build -- the ASAN lane and the full-core harnesses included,
    // which a test on the target name used to miss or catch only by accident.
    build_options.addOption(bool, "is_testsuite_build", options.is_testsuite_build);
    // Mirror "#if defined(DMCP_BUILD) && HARDWARE_MODEL == HWM_DM42" from wp34s.c:
    // only the DM42 firmware ("dmcp", not "dmcp5"/sim/testSuite) uses the small
    // fallback mod buffers / reduced mod precision.
    build_options.addOption(bool, "wp34s_mod_small_buffers", std.mem.eql(u8, name_prefix, "dmcp"));
    // The flash-limited DM42 old_hw firmware ("dmcp", not "dmcp5"/sim/testSuite)
    // runs the heavy/cold math owners (bessel, elliptic, opmod, power, xthRoot)
    // from executable QSPI (XIP) to keep main FLASH free; same mechanism the
    // dateTime owner and the distribution owners use.
    build_options.addOption(bool, "dm42_pkg_xip", std.mem.eql(u8, name_prefix, "dmcp"));
    // The four inverse-trig result slots are 588 bytes of .bss, which the DM42
    // does not have (its .bss ends exactly at the DMCP system data block). A hit
    // returns what a recompute returns -- that is what upstream's CACHE_VERIFY
    // build asserts -- so leaving them out costs the board speed and nothing else.
    build_options.addOption(bool, "trig_result_cache", !options.old_hw);
    build_options.addOption(bool, "option_xfn_1000", options.option_xfn_1000);
    build_options.addOption(bool, "option_slvp_poly", options.option_slvp_poly);
    build_options.addOption(bool, "option_cubic_159", options.option_cubic_159);
    build_options.addOption(bool, "option_eigen_159", options.option_eigen_159);
    build_options.addOption(bool, "option_elliptic", options.option_elliptic);
    build_options.addOption(bool, "option_bessel", options.option_bessel);
    build_options.addOption(bool, "option_ortho", options.option_ortho);
    build_options.addOption(bool, "option_dist_normal", options.option_dist_normal);
    build_options.addOption(bool, "option_eigen", options.option_eigen);
    build_options.addOption(bool, "option_vector", options.option_vector);
    module.addOptions("math_command_wrappers_build_options", build_options);
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
        .math_command_wrappers = addRuntimeObject(b, target, optimize, name_prefix, options),
    };
}

pub fn filterCoreSources(b: *std.Build, core_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, core_sources.len);
    errdefer filtered.deinit(b.allocator);

    for (core_sources) |source| {
        if (manifestContainsPath(replaced_core_sources_manifest, source)) {
            continue;
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
    is_testsuite_build: bool,
) void {
    var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const source = std.mem.trim(u8, line_raw, " \t");
        if (source.len == 0 or source[0] == '#') {
            continue;
        }
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .is_testsuite_build = is_testsuite_build });
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-command-wrappers-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "math-command-wrappers-parity");

    exe.root_module.addIncludePath(b.path("build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/" ++ "random_fake_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_legacy_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}

pub fn addRandomParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "random-parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-random-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "math-random-parity");

    exe.root_module.addIncludePath(b.path("build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/" ++ "random_fake_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_random_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_random_dispatch_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_legacy_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_random_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}
