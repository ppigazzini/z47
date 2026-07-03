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
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // Annex A0: instrument the frontier owner object with SanitizerCoverage
    // trace-pc-guard (requires the LLVM backend) so report-zig-coverage.sh can
    // measure which zig_src owner lines a host harness executes. Only the
    // dedicated `coverage` harness sets this; every product/test build keeps it
    // false, so the owner object is unchanged there.
    coverage: bool = false,
    // Distribution clusters to compile out of the frontier object, matching the
    // upstream SAVE_SPACE_DM42_17B (cauchy/weibull/logistic/exponential) and
    // SAVE_SPACE_DM42_17C (pareto/uniform) guards for flash-limited packages.
    strip_16: bool = false,
    strip_17: bool = false,
    strip_17b: bool = false,
    strip_17c: bool = false,
    // SAVE_SPACE_DM42_15 (all distributions) gates the DISTR submenu entry in
    // softmenus.c's menu_PROB (DDMENU). Upstream defines it only for DMCP package
    // 4. Defaults false (host / other packages keep the DISTR menu).
    strip_15: bool = false,
    // SAVE_SPACE_DM42_21_HP35 gates the SetHP35 dev-profile shortcut in
    // softmenus.c's menu_Dev. Upstream defines it only for DMCP package 1.
    // Defaults false (host / other packages keep the HP35 profile shortcut).
    strip_21_hp35: bool = false,
    // SAVE_SPACE_DM42_12{ORTHO,BESSEL,ELLIP} are always defined together (the
    // NOBESSEL_NOORTHO packages 1, 3 and 4); they gate the corresponding
    // ORTHO/BESSEL/ELLIP case labels in softmenus.c's savedspace() strike-out
    // helper. Defaults false (host / package 2 / DMCP5 keep those functions).
    strip_ortho_bessel_ellip: bool = false,
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
    // default and #undef's it for every flash-limited DMCP TWO_FILE package
    // (1, 2, 3 and 4). DMCP5 (NEW_HW) and host keep it. Defaults true (host).
    ir_printing: bool = true,
    // OPTION_VECTOR gates the 2D/3D vector display special-case in display.c's
    // real34MatrixToDisplayString. Upstream enables it by default and #undef's
    // it for DMCP packages 1, 2 and 4 (package 3 and DMCP5 keep it). Defaults
    // true (host).
    option_vector: bool = true,
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
        .root_source_file = b.path("zig_src/frontier/frontier.zig"),
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

    // L1 shared ABI bindings (REPORT-23 §5): single source of truth for the C
    // numeric layouts + typed constant-blob accessors, imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("abi", abi_module);

    const build_options = b.addOptions();
    build_options.addOption(bool, "strip_16", options.strip_16);
    build_options.addOption(bool, "strip_17", options.strip_17);
    build_options.addOption(bool, "strip_17b", options.strip_17b);
    build_options.addOption(bool, "strip_17c", options.strip_17c);
    build_options.addOption(bool, "strip_15", options.strip_15);
    build_options.addOption(bool, "strip_21_hp35", options.strip_21_hp35);
    build_options.addOption(bool, "strip_ortho_bessel_ellip", options.strip_ortho_bessel_ellip);
    build_options.addOption(bool, "extra_info_on_calc_error", options.extra_info_on_calc_error);
    build_options.addOption(bool, "dmcp_build", options.dmcp_build);
    build_options.addOption(bool, "old_hw", options.old_hw);
    build_options.addOption(bool, "option_elec", options.option_elec);
    build_options.addOption(u8, "calcmodel", options.calcmodel);
    build_options.addOption(bool, "ir_printing", options.ir_printing);
    build_options.addOption(bool, "option_vector", options.option_vector);

    // versionStr / versionStr2 (was screen_snap_helpers.c): assembled here the
    // same way generated.zig builds version.h, so the ported owner needs no C
    // preprocessor stamp. STD_SPACE_3_PER_EM = "\xa0\x04" (fonts.h). VERSION1
    // mirrors defines.h. versionStr2's __DATE__ is the C compile date in
    // "Mmm dd yyyy" form (date %b %e %Y); QSPI on firmware, Sim on host.
    const sp3 = "\xa0\x04";
    const modeltext = if (options.calcmodel == 66) "R47" else "C47";
    const version1 = "0.109.03.02b0";
    const vcs = build_common.commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";
    const today = build_common.commandOutput(b, &.{ "date", "+%Y-%m-%d" }) orelse "1970-01-01";
    const cdate = build_common.commandOutput(b, &.{ "date", "+%b %e %Y" }) orelse "Jan  1 1970";
    const version_string = b.fmt("custom{s}build{s}{s}{s}{s}", .{ sp3, sp3, vcs, sp3, today });
    const version_str = b.fmt("  {s} {s}.", .{ modeltext, version_string });
    const sim_or_qspi = if (options.dmcp_build) "QSPI" else "Sim";
    const version_str2 = b.fmt("  {s} {s} {s}, dated {s}.", .{ modeltext, sim_or_qspi, version1, cdate });
    build_options.addOption([]const u8, "version_str", version_str);
    build_options.addOption([]const u8, "version_str2", version_str2);

    root_module.addOptions("frontier_build_options", build_options);

    const runtime_obj = b.addObject(.{
        .name = b.fmt("{s}-frontier-root", .{name_prefix}),
        .root_module = root_module,
    });
    if (options.coverage) {
        runtime_obj.use_llvm = true;
        runtime_obj.sanitize_coverage_trace_pc_guard = true;
    }
    return runtime_obj;
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
) void {
    var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const source = std.mem.trim(u8, line_raw, " \t");
        if (source.len == 0 or source[0] == '#') {
            continue;
        }
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{ .calcmodel = calcmodel, .coverage = coverage });
    module.addObject(runtime_object);
}