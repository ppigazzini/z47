const std = @import("std");
const build_common = @import("../common.zig");

const replaced_core_sources_manifest = @embedFile("frontier_replaced_core_sources.txt");
const runtime_helper_sources_manifest = @embedFile("frontier_runtime_helper_sources.txt");

pub const RuntimeObjects = struct {
    frontier_root: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
        while (lines.next()) |line_raw| {
            const source = std.mem.trim(u8, line_raw, " \t");
            if (source.len == 0 or source[0] == '#') {
                continue;
            }
            cmd.addArg(source);
        }
        cmd.addFileArg(self.frontier_root.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    /// True where this executable's C sources are compiled with
    /// TESTSUITE_BUILD, so the Zig owners answer the same question the C half
    /// does: fnSNAP freezes the clock the date/time formatters read, and RESET
    /// loads the sample programs. The testSuite and the full-core harnesses set
    /// it; the product and the simulator leave it false.
    is_testsuite_build: bool = false,
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // Annex A0: instrument the frontier owner object with SanitizerCoverage
    // trace-pc-guard (requires the LLVM backend) so report-zig-coverage.sh can
    // measure which src owner lines a host harness executes. Only the
    // dedicated `coverage` harness sets this; every product/test build keeps it
    // false, so the owner object is unchanged there.
    coverage: bool = false,
    // Distribution clusters to compile out of the frontier object. Each is the
    // INVERSE of an upstream option: strip_16 of OPTION_DIST_NORMAL, strip_17 of
    // OPTION_DIST_C (binomial/f/geometric/hyper/negBinom/poisson), strip_17b of
    // OPTION_DIST_B (cauchy/chi2/expo/logistic/t/weibull) and strip_17c of
    // OPTION_DIST_D (gev/pareto/uniform). build/firmware.zig maps each to the
    // packages whose defines.h block undefines it.
    strip_16: bool = false,
    strip_17: bool = false,
    strip_17b: bool = false,
    strip_17c: bool = false,
    // The inverse of OPTION_DISTRIBUTIONS, which carries the DISTR submenu entry
    // in softmenus.c's menu_PROB (DDMENU). Upstream undefines it for DMCP package
    // 4 alone. Defaults false (host / other packages keep the DISTR menu).
    strip_15: bool = false,
    // The inverse of OPTION_HP35, which carries the SetHP35 dev-profile shortcut
    // in softmenus.c's menu_Dev. Upstream defines it for host and for every DMCP
    // package, so nothing sets this today; it defaults false, keeping the shortcut.
    strip_21_hp35: bool = false,
    // The inverses of upstream's OPTION_ORTHO, OPTION_BESSEL and OPTION_ELLIPTIC,
    // which gate the matching case labels in softmenus.c's savedspace()
    // strike-out helper. They are three separate options with three different
    // per-package values, so they cannot share one flag: elliptic is out of
    // packages 1, 3 and 4, while ortho and bessel are out of package 4 alone.
    // Default false (host / DMCP5 keep all three).
    strip_ortho: bool = false,
    strip_bessel: bool = false,
    strip_elliptic: bool = false,
    // Emit the EXTRA_INFO_ON_CALC_ERROR console hints. Upstream compiles these
    // out on firmware (DMCP_BUILD), so default off there to match and save flash;
    // host/sim keep them. Default true mirrors a normal host build.
    extra_info_on_calc_error: bool = true,
    // Firmware (DMCP_BUILD) vs host: selects backToSystem error tails, drops the
    // PC-only allocation tracking, and (with old_hw) the static-array layout of
    // freeMemoryRegions. Defaults match a host build.
    dmcp_build: bool = false,
    old_hw: bool = false,
    // OPTION_ELEC gates the ELEC functions (fnJM body in c47Extensions/jm.c).
    // Upstream defines.h enables it by default and #undef's it for the
    // flash-limited DMCP TWO_FILE packages 1, 2 and 4 (package 3 and DMCP5 keep
    // it). Defaults true to match a host build.
    option_elec: bool = true,
    // CALCMODEL selects the firmware/sim model the way upstream's compile-time
    // -DCALCMODEL does: it seeds the calcModel global (c47.c) so isR47FAM() and
    // the early startup render (window title, keyboard layout) are correct
    // BEFORE c47-gtk.c re-sets calcModel after restore. USER_C47 = 46 (host C47
    // sim + testSuite default), USER_R47 = 66 (host R47 sim + DMCP firmware).
    calcmodel: u8 = 46,
    // IR_PRINTING gates the IR printer paths (printViewAview / printInputPrompt
    // in display.c's fnView/fnAview/fnPrompt). Upstream defines.h enables it by
    // default and #undef's it for DMCP packages 1 and 3; packages 2 and 4,
    // DMCP5 (NEW_HW) and host keep it. Defaults true (host).
    ir_printing: bool = true,
    // OPTION_VECTOR gates the 2D/3D vector display special-case in display.c's
    // real34MatrixToDisplayString and the VECTOR menu entries. Upstream enables
    // it by default and #undef's it in the block common to DMCP packages 1-4,
    // so no DM42 package has it; DMCP5 and host do. Defaults true (host).
    option_vector: bool = true,
    // OPTION_SAMPLEPGMS gates loading res/testPgms into program memory on RESET.
    // Upstream enables it by default and #undef's it for NEW_HW and again for
    // packages 1-4, so no DMCP build has it. Defaults true (host), where the
    // load is still gated at runtime on the loadTestPrograms command-line flag.
    option_samplepgms: bool = true,
    // OPTION_EIGEN gates EIGVAL, EIGVEC, M.QR and MSQRT. Upstream enables it by
    // default and #undef's it for DMCP packages 1, 2 and 4; package 3, DMCP5 and
    // host keep it. Defaults true (host).
    option_eigen: bool = true,
    // OPTION_XFN_1000 gates the 1000-digit XFN surface the frontier owners see:
    // the menu_XFN softkeys, the matching items-table entries and the saved-state
    // gate. Upstream enables it by default and #undef's it in the block
    // common to DMCP packages 1-4, so no DM42 package has it; DMCP5 and host do.
    // Defaults true (host).
    option_xfn_1000: bool = true,
    // OPTION_SLVP_POLY gates the SLVP softkey and its savedspace() strike-out.
    // It sits in the same "common to packages 1-4" block as OPTION_XFN_1000, so
    // it has the same per-target answer. Defaults true (host).
    option_slvp_poly: bool = true,
    // OPTION_INFSUMS gates the infinity-sum items; the plain programmable sum and
    // product stay either way. Same block again, so the same per-target answer.
    // Defaults true (host).
    option_infsums: bool = true,
    // OPTION_TVM_AMORT gates menu_AMORT and screen.c's amort temporary-information
    // lines. Upstream defines it for every DMCP package as well as for DMCP5 and
    // host; its only #undef is in the legacy single-file block, which needs
    // neither TWO_FILE_PGM nor NEW_HW and so is unreachable for every target z47
    // builds. It is therefore true everywhere, and exists as an option so the two
    // owners read the fact instead of restating it.
    option_tvm_amort: bool = true,
};

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

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/frontier.zig"),
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

    // L1 shared ABI bindings: single source of truth for the C
    // numeric layouts + typed constant-blob accessors, imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("abi", abi_module);

    addBuildOptions(b, root_module, name_prefix, options);

    const runtime_obj = b.addObject(.{
        .name = b.fmt("{s}-frontier-root", .{name_prefix}),
        .root_module = root_module,
    });
    // One section per global so --gc-sections can drop what this build's feature
    // stripping left unreferenced, and so LLVM's GlobalMerge stops padding
    // unrelated globals into shared blobs. Worth ~570 bytes of .bss, which the
    // DM42's 8Kb SRAM2 budget needs; the .rodata split it also causes costs
    // flash, which only the DM42 is tight on and which stubbing newlib's stdio
    // has since paid for.
    runtime_obj.link_data_sections = true;
    if (options.coverage) {
        runtime_obj.use_llvm = true;
        runtime_obj.sanitize_coverage_trace_pc_guard = true;
    }
    return runtime_obj;
}

/// Register `frontier_build_options` on a module rooted anywhere in the frontier
/// owner tree. Every option the tree reads is added here unconditionally, so a
/// module that compiles a subset of the owners (a parity harness) is given the
/// same option set as the product object and an owner never has to cope with an
/// option being absent.
pub fn addBuildOptions(
    b: *std.Build,
    module: *std.Build.Module,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) void {
    const build_options = b.addOptions();
    build_options.addOption(bool, "strip_16", options.strip_16);
    build_options.addOption(bool, "strip_17", options.strip_17);
    build_options.addOption(bool, "strip_17b", options.strip_17b);
    build_options.addOption(bool, "strip_17c", options.strip_17c);
    build_options.addOption(bool, "strip_15", options.strip_15);
    build_options.addOption(bool, "strip_21_hp35", options.strip_21_hp35);
    build_options.addOption(bool, "strip_ortho", options.strip_ortho);
    build_options.addOption(bool, "strip_bessel", options.strip_bessel);
    build_options.addOption(bool, "strip_elliptic", options.strip_elliptic);
    // The testSuite build forces EXTRA_INFO_ON_CALC_ERROR to 0, as the firmware
    // does. Leaving the hints in made the tested owners write the shared
    // errorMessage buffer and print on paths the C oracle compiles out.
    build_options.addOption(bool, "extra_info_on_calc_error", options.extra_info_on_calc_error and
        !std.mem.startsWith(u8, name_prefix, "testSuite"));
    build_options.addOption(bool, "dmcp_build", options.dmcp_build);
    build_options.addOption(bool, "old_hw", options.old_hw);
    build_options.addOption(bool, "option_elec", options.option_elec);
    build_options.addOption(u8, "calcmodel", options.calcmodel);
    build_options.addOption(bool, "ir_printing", options.ir_printing);
    build_options.addOption(bool, "option_vector", options.option_vector);
    build_options.addOption(bool, "option_samplepgms", options.option_samplepgms);
    build_options.addOption(bool, "option_eigen", options.option_eigen);
    build_options.addOption(bool, "option_xfn_1000", options.option_xfn_1000);
    build_options.addOption(bool, "option_slvp_poly", options.option_slvp_poly);
    build_options.addOption(bool, "option_infsums", options.option_infsums);
    build_options.addOption(bool, "option_tvm_amort", options.option_tvm_amort);
    // Passed in by whoever also hands the C sources -DTESTSUITE_BUILD, so the Zig
    // owners and the C half of the same executable agree on which build this is:
    // fnSNAP freezes the clock the date/time formatters read, and RESET loads the
    // sample programs. Derived from the target NAME before, which silently left
    // every full-core harness -- all of which define the macro for their C -- on
    // the product's answer.
    build_options.addOption(bool, "is_testsuite_build", options.is_testsuite_build);

    // versionStr / versionStr2: assembled here the same way generated.zig builds
    // version.h, so the ported owner needs no C preprocessor stamp.
    // STD_SPACE_3_PER_EM = "\xa0\x04" (fonts.h). VERSION1 mirrors defines.h;
    // QSPI on firmware, Sim on host. compile_date stands in for __DATE__ and so
    // must keep its exact "Mmm dd yyyy" shape with the day space-padded to two
    // columns (date %e, not %-d): the owner reproduces versionDateStr by
    // indexing those eleven columns.
    const sp3 = "\xa0\x04";
    const modeltext = if (options.calcmodel == 66) "R47" else "C47";
    const version1 = "00.109.04.00b0";
    const vcs = build_common.commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";
    const today = build_common.commandOutput(b, &.{ "date", "+%Y-%m-%d" }) orelse "1970-01-01";
    const cdate = build_common.commandOutput(b, &.{ "date", "+%b %e %Y" }) orelse "Jan  1 1970";
    const version_string = b.fmt("custom{s}build{s}{s}{s}{s}", .{ sp3, sp3, vcs, sp3, today });
    const version_str = b.fmt("  {s} {s}.", .{ modeltext, version_string });
    const sim_or_qspi = if (options.dmcp_build) "QSPI" else "Sim";
    const version_str2 = b.fmt("  {s} {s} {s}, dd ", .{ modeltext, sim_or_qspi, version1 });
    build_options.addOption([]const u8, "version_str", version_str);
    build_options.addOption([]const u8, "version_str2", version_str2);
    build_options.addOption([]const u8, "compile_date", cdate);

    module.addOptions("frontier_build_options", build_options);
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
        .frontier_root = addRuntimeObject(b, target, optimize, name_prefix, options),
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
    calcmodel: u8,
    coverage: bool,
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
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .calcmodel = calcmodel, .coverage = coverage, .is_testsuite_build = is_testsuite_build });
    module.addObject(runtime_object);
}
