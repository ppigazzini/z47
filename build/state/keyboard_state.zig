const std = @import("std");
const abi_host = @import("../abi_host.zig");
const build_common = @import("../common.zig");

pub const RuntimeObjects = struct {
    keyboard_state: *std.Build.Step.Compile,

    pub fn link(self: RuntimeObjects, module: *std.Build.Module) void {
        module.addObject(self.keyboard_state);
    }

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        // The keyboard-state C bridge is fully retired; only the Zig object links.
        cmd.addFileArg(self.keyboard_state.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // CALCMODEL == USER_R47 for the R47 firmware variants (dmcpr47 / dmcp5r47).
    // The DMCP key ring buffer's keyBuffer_pop applies convertKeyCode only under
    // that compile-time model, and the keyboard-state object is shared between a
    // HW's C47 and R47 builds, so the distinction is threaded as a build option.
    is_r47: bool = false,
    // REPORT-27 M-IDIOM-9: build this object with SanitizerCoverage
    // trace-pc-guard so report-zig-coverage.sh can resolve the keyboard-state Zig
    // owner lines the host coverage harness executes. Measurement-only: set ONLY
    // for the dedicated coverage harness variant, never a product/test object,
    // because the sancov handler symbol is linked only into that binary.
    coverage: bool = false,
};

const replaced_core_sources = [_][]const u8{
    "keyboard.c",
    "c47Extensions/" ++ "keyboardTweak.c",
};

const GeneratedHeaderDirs = struct {
    version_headers_dir: std.Build.LazyPath,
    softmenu_catalogs_dir: std.Build.LazyPath,
    constant_pointers_h_dir: std.Build.LazyPath,
};

pub const HostModuleConfig = struct {
    platform_define: []const u8,
    word_size_define: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
    needs_gnu_source: bool,
    have_dladdr: bool,
    generated_headers: GeneratedHeaderDirs,
};

pub const FirmwareModuleConfig = struct {
    board_source_dir: []const u8,
    sdk_include_dir: []const u8,
    board_macro: ?[]const u8 = null,
    decnumber_fastmul: bool,
    generated_headers: GeneratedHeaderDirs,
};

fn addRuntimeObjectWithIncludeDir(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    root_source_file: std.Build.LazyPath,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings (REPORT-23 §5).
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);

    const kb_build_options = b.addOptions();
    kb_build_options.addOption(bool, "is_r47", options.is_r47);
    module.addOptions("keyboard_state_build_options", kb_build_options);

    const object = b.addObject(.{
        .name = b.fmt("{s}-keyboard-state", .{name_prefix}),
        .root_module = module,
    });
    if (options.coverage) {
        object.use_llvm = true;
        object.sanitize_coverage_trace_pc_guard = true;
    }
    return object;
}

fn addGeneratedHeaderDirs(module: *std.Build.Module, headers: GeneratedHeaderDirs) void {
    module.addIncludePath(headers.version_headers_dir);
    module.addIncludePath(headers.softmenu_catalogs_dir);
    module.addIncludePath(headers.constant_pointers_h_dir);
}

fn configureHostModule(module: *std.Build.Module, config: HostModuleConfig) void {
    module.addCMacro("PC_BUILD", "1");
    module.addCMacro("__GI_SCANNER__", "1");
    module.addCMacro(config.platform_define, "1");
    module.addCMacro(config.word_size_define, "1");
    if (config.raspberry) {
        module.addCMacro("RASPBERRY", "1");
    }
    if (config.decnumber_fastmul) {
        module.addCMacro("DECNUMBER_FASTMUL", "1");
    }
    if (config.needs_gnu_source) {
        module.addCMacro("_GNU_SOURCE", "1");
    }
    if (config.have_dladdr) {
        module.addCMacro("HAVE_DLADDR", "1");
    }

    module.addIncludePath(build_common.upstreamPath(module.owner, "dep/decNumberICU"));
    module.addIncludePath(build_common.upstreamPath(module.owner, "src/c47"));
    addGeneratedHeaderDirs(module, config.generated_headers);
}

fn configureFirmwareModule(module: *std.Build.Module, config: FirmwareModuleConfig) void {
    module.addCMacro("DMCP_BUILD", "1");
    module.addCMacro("OS32BIT", "1");
    if (config.board_macro) |macro| {
        module.addCMacro(macro, "1");
    }
    if (config.decnumber_fastmul) {
        module.addCMacro("DECNUMBER_FASTMUL", "1");
    }

    module.addIncludePath(build_common.upstreamPath(module.owner, "dep/decNumberICU"));
    module.addIncludePath(build_common.upstreamPath(module.owner, "src/c47"));
    module.addIncludePath(module.owner.path(config.board_source_dir));
    module.addIncludePath(module.owner.path(config.sdk_include_dir));
    addGeneratedHeaderDirs(module, config.generated_headers);
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
    return addHostRuntimeObjectsWithOptions(b, target, optimize, name_prefix, .{
        .platform_define = "LINUX",
        .word_size_define = "OS64BIT",
        .raspberry = false,
        .decnumber_fastmul = false,
        .needs_gnu_source = true,
        .have_dladdr = true,
        .generated_headers = .{
            .version_headers_dir = build_common.upstreamPath(b, "src/c47"),
            .softmenu_catalogs_dir = build_common.upstreamPath(b, "src/c47"),
            .constant_pointers_h_dir = build_common.upstreamPath(b, "src/c47"),
        },
    }, options);
}

pub fn addHostRuntimeObjects(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    config: HostModuleConfig,
) RuntimeObjects {
    return addHostRuntimeObjectsWithOptions(b, target, optimize, name_prefix, config, .{});
}

pub fn addHostRuntimeObjectsWithOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    config: HostModuleConfig,
    options: RuntimeObjectOptions,
) RuntimeObjects {
    const object = addRuntimeObjectWithIncludeDir(b, target, optimize, name_prefix, b.path("src/core/input/keyboard_state.zig"), options);
    configureHostModule(object.root_module, config);
    return .{ .keyboard_state = object };
}

pub fn addFirmwareRuntimeObjects(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    config: FirmwareModuleConfig,
) RuntimeObjects {
    return addFirmwareRuntimeObjectsWithOptions(b, target, optimize, name_prefix, config, .{});
}

pub fn addFirmwareRuntimeObjectsWithOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    config: FirmwareModuleConfig,
    options: RuntimeObjectOptions,
) RuntimeObjects {
    const object = addRuntimeObjectWithIncludeDir(b, target, optimize, name_prefix, b.path("src/core/input/keyboard_state.zig"), options);
    configureFirmwareModule(object.root_module, config);
    return .{ .keyboard_state = object };
}

pub fn filterCoreSources(b: *std.Build, core_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, core_sources.len);
    errdefer filtered.deinit(b.allocator);

    outer: for (core_sources) |source| {
        for (replaced_core_sources) |removed| {
            if (std.mem.eql(u8, source, removed)) {
                continue :outer;
            }
        }
        try filtered.append(b.allocator, source);
    }

    return try filtered.toOwnedSlice(b.allocator);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObjectWithIncludeDir(b, target, optimize, "parity", b.path("build/tests/keyboard_state/keyboard_state_parity.zig"), .{});
    runtime_object.root_module.addImport("z47_keyboard_state_shared", b.createModule(.{
        .root_source_file = b.path("src/core/input/keyboard_state_shared.zig"),
        .target = target,
        .optimize = optimize,
    }));
    runtime_object.root_module.addIncludePath(b.path("build/tests/keyboard_state"));
    const exe = b.addExecutable(.{
        .name = "keyboard-state-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "keyboard-state-parity");

    exe.root_module.addIncludePath(b.path("build/tests/keyboard_state"));
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/keyboard_state/keyboard_state_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/keyboard_state/keyboard_state_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/keyboard_state/keyboard_state_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
