const std = @import("std");
const build_common = @import("../common.zig");
const abi_host = @import("../abi_host.zig");
const host_platform = @import("../host/platform.zig");

const replaced_core_sources_manifest = @embedFile("math_command_wrapper_replaced_core_sources.txt");

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
        cmd.addFileArg2(self.math_command_wrappers.getEmittedBin(), .{});
    }
};

pub const RuntimeObjectOptions = struct {
    /// The board this object is compiled for, set by the caller that builds for
    /// it; every board fact the options carry derives from it.
    board: build_common.Board = .host,
    /// The kind of executable this object is linked into, set by the caller;
    /// see build_common.Linkage.
    linkage: build_common.Linkage = .product,
    strip: ?bool = null,
    unwind_tables: ?std.lang.UnwindTables = null,
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
    // THE DISTRIBUTION GATES (defines.h): one OPTION_DIST_* per distribution
    // file, defined by the group option that carries it (NORML by DIST_NORMAL;
    // T, LOGIS, CAUCH, WEIBL, EXPON and CHI2 by DIST_B; BINOM, F, GEOM, HYPER,
    // NBIN and POISS by DIST_C; PRTO, GEV and UNFM by DIST_D), so a shipped
    // package takes a whole group or none of it. Each owner reads its own gate,
    // as its upstream file does. build/firmware.zig derives them from the
    // dm42Package table; host and DMCP5 keep every one.
    option_dist_norml: bool = true,
    option_dist_t: bool = true,
    option_dist_logis: bool = true,
    option_dist_cauch: bool = true,
    option_dist_weibl: bool = true,
    option_dist_expon: bool = true,
    option_dist_chi2: bool = true,
    option_dist_binom: bool = true,
    option_dist_f: bool = true,
    option_dist_geom: bool = true,
    option_dist_hyper: bool = true,
    option_dist_nbin: bool = true,
    option_dist_poiss: bool = true,
    option_dist_prto: bool = true,
    option_dist_gev: bool = true,
    option_dist_unfm: bool = true,
    // OPTION_EIGEN gates the eigenvalue/eigenvector/QR/matrix-sqrt half of
    // matrix.c (EIGVAL, EIGVEC, M.QR, MSQRT) and squareRoot.c's 159-digit
    // helpers; LU, determinant and inverse stay either way. Which DM42 packages
    // keep it is build/firmware.zig's dm42Package table; DMCP5 and host keep it.
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
    // OPTION_DRG_CFG: XDRG steps through the units the DRG menu chose, and the
    // unit it lands on becomes ADM under A.AUTO. Every target z47 builds defines
    // it. Defaults true.
    option_drg_cfg: bool = true,
    // OPTION_SLVP_POLY gates SLVP (every root of a polynomial, through the
    // companion matrix and the QR eigensolver) in slvp.c and matrix.c. It is set
    // per DM42 package, from build/firmware.zig's dm42Package table. defines.h also
    // #undef's it whenever OPTION_EIGEN is out, which adds nothing: every package
    // that drops EIGEN drops SLVP in its own block.
    option_slvp_poly: bool = true,
    // OPTION_ALGDEP gates algdep.c whole: fnAlgdep and fnLindep are empty stubs
    // and algdepPolynomialString() is "" without it. #undef'd in the block common
    // to DM42 packages 1-4 (3896 bytes of flash); DMCP5 and host keep it.
    option_algdep: bool = true,
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
    // Whether the owner exports its lnComplex and lnComplexDirect under the plain
    // C names. True for the product, sim and testSuite links, where
    // mathematics/ln.c is filtered out and the owner is the only definition. The
    // focused oracles set it false: each of them already links a C lnComplex and
    // lnComplexDirect, so a second one would clash.
    export_public_ln_complex: bool = true,
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/numeric/command_wrappers.zig"),
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
    // L1 shared ABI bindings, imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    // The DMCP ROM function table the integer-check commands refresh the LCD
    // through.
    const dmcp_rom_module = build_common.addDmcpRomModule(b, target, optimize, options.board);
    module.addImport("dmcp_rom", dmcp_rom_module);
    addBuildOptions(b, module, options);

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
    options: RuntimeObjectOptions,
) void {
    const build_options = b.addOptions();
    build_options.addOption(bool, "use_fake_wp34s_model", options.linkage == .fake_harness);
    build_options.addOption(bool, "use_fake_wp34s_harness_surface", options.linkage == .fake_harness);
    build_options.addOption(bool, "export_public_ln_complex", options.export_public_ln_complex);
    // Passed in by whoever also hands the C sources -DTESTSUITE_BUILD, so the Zig
    // random seed is the deterministic test seed in every executable whose C half
    // is a testSuite build -- the ASAN lane and the full-core harnesses included,
    // which a test on the target name used to miss or catch only by accident.
    build_options.addOption(bool, "is_testsuite_build", options.linkage == .testsuite);
    // Mirror "#if defined(DMCP_BUILD) && HARDWARE_MODEL == HWM_DM42" from wp34s.c:
    // only the DM42 uses the small fallback mod buffers and reduced mod
    // precision.
    build_options.addOption(bool, "wp34s_mod_small_buffers", options.board.isOldHw());
    // The flash-limited DM42 runs the heavy, cold math owners (bessel, elliptic,
    // opmod, power, xthRoot) from executable QSPI (XIP) to keep main FLASH free;
    // the dateTime and distribution owners use the same placement.
    build_options.addOption(bool, "dm42_pkg_xip", options.board.isOldHw());
    // The four inverse-trig result slots are 588 bytes of .bss, which the DM42
    // does not have (its .bss ends exactly at the DMCP system data block). A hit
    // returns what a recompute returns -- that is what upstream's CACHE_VERIFY
    // build asserts -- so leaving them out costs the board speed and nothing else.
    // The DM42's SRAM2 .bss ends exactly at the DMCP system data block, and the
    // four inverse-trig result slots are 588 bytes it does not have.
    build_options.addOption(bool, "trig_result_cache", !options.board.isOldHw());
    build_options.addOption(bool, "option_xfn_1000", options.option_xfn_1000);
    build_options.addOption(bool, "option_drg_cfg", options.option_drg_cfg);
    build_options.addOption(bool, "option_slvp_poly", options.option_slvp_poly);
    build_options.addOption(bool, "option_algdep", options.option_algdep);
    build_options.addOption(bool, "option_cubic_159", options.option_cubic_159);
    build_options.addOption(bool, "option_eigen_159", options.option_eigen_159);
    build_options.addOption(bool, "option_elliptic", options.option_elliptic);
    build_options.addOption(bool, "option_bessel", options.option_bessel);
    build_options.addOption(bool, "option_ortho", options.option_ortho);
    build_options.addOption(bool, "option_dist_normal", options.option_dist_normal);
    build_options.addOption(bool, "option_dist_norml", options.option_dist_norml);
    build_options.addOption(bool, "option_dist_t", options.option_dist_t);
    build_options.addOption(bool, "option_dist_logis", options.option_dist_logis);
    build_options.addOption(bool, "option_dist_cauch", options.option_dist_cauch);
    build_options.addOption(bool, "option_dist_weibl", options.option_dist_weibl);
    build_options.addOption(bool, "option_dist_expon", options.option_dist_expon);
    build_options.addOption(bool, "option_dist_chi2", options.option_dist_chi2);
    build_options.addOption(bool, "option_dist_binom", options.option_dist_binom);
    build_options.addOption(bool, "option_dist_f", options.option_dist_f);
    build_options.addOption(bool, "option_dist_geom", options.option_dist_geom);
    build_options.addOption(bool, "option_dist_hyper", options.option_dist_hyper);
    build_options.addOption(bool, "option_dist_nbin", options.option_dist_nbin);
    build_options.addOption(bool, "option_dist_poiss", options.option_dist_poiss);
    build_options.addOption(bool, "option_dist_prto", options.option_dist_prto);
    build_options.addOption(bool, "option_dist_gev", options.option_dist_gev);
    build_options.addOption(bool, "option_dist_unfm", options.option_dist_unfm);
    build_options.addOption(bool, "option_eigen", options.option_eigen);
    build_options.addOption(bool, "option_vector", options.option_vector);
    module.addOptions("math_command_wrappers_build_options", build_options);
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
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    linkage: build_common.Linkage,
) void {
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .linkage = linkage });
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{ .linkage = .fake_harness });
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
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}

pub fn addRandomParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "random-parity", .{ .linkage = .fake_harness });
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
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_wrappers_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/math_wrappers/math_random_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}
