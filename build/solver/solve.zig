const std = @import("std");
const build_common = @import("../common.zig");

const replaced_core_sources_manifest = @embedFile("solve_replaced_core_sources.txt");

pub const RuntimeObjects = struct {
    solve: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg2(self.solve.getEmittedBin(), .{});
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.lang.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // The board this object is compiled for, set by the caller that builds
    // for it; every board fact below derives from it.
    board: build_common.Board = .host,
    // The kind of executable this object is linked into, set by the caller;
    // see build_common.Linkage.
    linkage: build_common.Linkage = .product,
    // Per-package OPTION_* from defines.h, all defaulting to a host build. Which
    // DM42 packages keep each one is build/firmware.zig's dm42Package table.
    //
    // OPTION_TVM_FORMULAS is the analytical closed forms tvm.c uses where one
    // exists; without it every unknown goes through the solver.
    option_tvm_formulas: bool = true,
    // OPTION_TVM_NEWTON adds the Newton-Raphson refinement inside solve.c's brent
    // solver for TVM; without it the FIN solver is the slow brent-only path.
    option_tvm_newton: bool = true,
    // OPTION_TVM_AMORT is the AMORT half of tvm.c: without it fnAmortP,
    // fnAmortNext, fnAmortBal, fnAmortPrn and fnAmortInt are empty.
    option_tvm_amort: bool = true,
    // OPTION_INFSUMS is the infinity sum and its early stop in sumprod.c; the
    // plain programmable sum and product stay either way. Every target z47
    // builds defines it: the block common to the DM42 packages keeps it.
    option_infsums: bool = true,
    // OPTION_SLVP_POLY is the general polynomial-roots command and, with it,
    // equation.c's V->EQ rendering of a coefficient vector.
    option_slvp_poly: bool = true,
};

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (std.mem.eql(u8, line, needle)) return true;
    }
    return false;
}

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/analysis/solve.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
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
    // The DMCP ROM function table the graph and progress panels refresh the LCD
    // through.
    const dmcp_rom_module = build_common.addDmcpRomModule(b, target, optimize, options.board);
    module.addImport("dmcp_rom", dmcp_rom_module);
    const build_options = b.addOptions();
    // The flash-limited DM42 runs the heavy, cold solver owners (tvm, sumprod)
    // from executable QSPI (XIP) to keep main FLASH free; the mathematics owners
    // use the same placement.
    build_options.addOption(bool, "dm42_pkg_xip", options.board.isOldHw());
    // Passed in by whoever also hands the C sources -DTESTSUITE_BUILD, so the Zig
    // solver owners (tvm.zig) take the testSuite code path -- fnTvmVar's `testing`
    // short-circuit -- in every executable whose C half is a testSuite build. That
    // includes the ASAN lane and the full-core harnesses, which a test on the
    // target name used to miss or catch only by accident.
    build_options.addOption(bool, "is_testsuite_build", options.linkage == .testsuite);
    // Both firmware boards stub calcModeAimGui() to a no-op (hal/gui.h: #if
    // defined(DMCP_BUILD) ...); the on-screen-keyboard sim and testSuite link the
    // real function. equation.zig mirrors this.
    build_options.addOption(bool, "is_dmcp_build", options.board.isDmcp());
    // OLD_HW against NEW_HW: the engine-nesting depth cap
    // (MAX_ENGINE_NESTING_DEPTH / PLOT_NESTING_ALLOWED) is hardware-tier-specific,
    // and HARDWARE_MODEL == HWM_DM42 selects TVM's working precision.
    build_options.addOption(bool, "is_old_hw", options.board.isOldHw());
    build_options.addOption(bool, "option_infsums", options.option_infsums);
    build_options.addOption(bool, "option_slvp_poly", options.option_slvp_poly);
    build_options.addOption(bool, "option_tvm_formulas", options.option_tvm_formulas);
    build_options.addOption(bool, "option_tvm_newton", options.option_tvm_newton);
    build_options.addOption(bool, "option_tvm_amort", options.option_tvm_amort);
    module.addOptions("solve_build_options", build_options);
    return b.addObject(.{
        .name = b.fmt("{s}-solver-solve", .{name_prefix}),
        .root_module = module,
    });
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
        .solve = addRuntimeObject(b, target, optimize, name_prefix, options),
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
