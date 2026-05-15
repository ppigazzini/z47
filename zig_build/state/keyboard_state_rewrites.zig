const std = @import("std");
const build_common = @import("../common.zig");

pub const RuntimeObjects = struct {
    keyboard_state: *std.Build.Step.Compile,

    pub fn link(self: RuntimeObjects, module: *std.Build.Module) void {
        module.addObject(self.keyboard_state);
    }

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addArg("zig_bridge/state/keyboard_state_runtime_helpers.c");
        cmd.addArg("zig_bridge/state/keyboard_state_overlay.c");
        cmd.addArg("zig_bridge/state/keyboard_state_retained.c");
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
};

const replaced_core_sources = [_][]const u8{
    "keyboard.c",
    "c47Extensions/keyboardTweak.c",
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

    return b.addObject(.{
        .name = b.fmt("{s}-keyboard-state", .{name_prefix}),
        .root_module = module,
    });
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

    module.addIncludePath(module.owner.path("dep/decNumberICU"));
    module.addIncludePath(module.owner.path("src/c47"));
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

    module.addIncludePath(module.owner.path("dep/decNumberICU"));
    module.addIncludePath(module.owner.path("src/c47"));
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
            .version_headers_dir = b.path("src/c47"),
            .softmenu_catalogs_dir = b.path("src/c47"),
            .constant_pointers_h_dir = b.path("src/c47"),
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
    const object = addRuntimeObjectWithIncludeDir(b, target, optimize, name_prefix, b.path("zig_src/state/keyboard_state.zig"), options);
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
    const object = addRuntimeObjectWithIncludeDir(b, target, optimize, name_prefix, b.path("zig_src/state/keyboard_state.zig"), options);
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
    const runtime_object = addRuntimeObjectWithIncludeDir(b, target, optimize, "parity", b.path("zig_build/tests/keyboard_state/keyboard_state_parity.zig"), .{});
    runtime_object.root_module.addImport("z47_keyboard_state_shared", b.createModule(.{
        .root_source_file = b.path("zig_src/state/keyboard_state_shared.zig"),
        .target = target,
        .optimize = optimize,
    }));
    runtime_object.root_module.addIncludePath(b.path("zig_build/tests/keyboard_state"));
    const exe = b.addExecutable(.{
        .name = "keyboard-state-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/keyboard_state"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/keyboard_state/keyboard_state_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/keyboard_state/keyboard_state_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/keyboard_state/keyboard_state_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
