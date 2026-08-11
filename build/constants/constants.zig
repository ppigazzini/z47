const std = @import("std");
const abi_host = @import("../abi_host.zig");

pub const RuntimeObjects = struct {
    constants: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.constants.getEmittedBin());
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
    "constants.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/abi/constants/constants.zig"),
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
    const build_options = b.addOptions();
    build_options.addOption(bool, "extra_info_on_calc_error", std.mem.eql(u8, name_prefix, "host") or std.mem.endsWith(u8, name_prefix, "parity"));
    build_options.addOption(bool, "use_fake_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    module.addOptions("constants_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-constants", .{name_prefix}),
        .root_module = module,
    });
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
        .constants = addRuntimeObject(b, target, optimize, name_prefix, options),
    };
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

pub fn addToModule(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    c_flags: []const []const u8,
) void {
    _ = c_flags;
    module.addObject(addRuntimeObject(b, target, optimize, name_prefix, .{}));
}

/// The three artefacts `generateConstants` emits, as the parity lane consumes
/// them. The lane compiles c43's OWN generated blob and pointer table instead of
/// standing up a fake one: an offset or a table position restated in the harness
/// is a frozen copy of c43, and this lane exists to catch exactly the confusion
/// such a copy would hide -- reaching a constant by position rather than by name.
pub const GeneratedConstants = struct {
    /// `constantPointers.h`. Its DIRECTORY goes on the include path, the way the
    /// product build does it; the harness `c47.h` includes it by name.
    header: std.Build.LazyPath,
    /// `constantPointers.c` -- the `constants` byte blob every const*_ macro,
    /// and the port's blob accessors, index into.
    blob: std.Build.LazyPath,
    /// `constantPointers2.c` -- the `realtConstants` table `fnConstant` indexes.
    table: std.Build.LazyPath,
};

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    generated: GeneratedConstants,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const parity_driver = b.addObject(.{
        .name = "constants-parity-driver",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/tests/constants/constants_parity.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    const exe = b.addExecutable(.{
        .name = "constants-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "constants-parity");

    // The harness `c47.h` first, so the generated sources resolve `c47.h` to the
    // mock rather than to a core header they cannot pull in headless.
    exe.root_module.addIncludePath(b.path("build/tests/constants"));
    exe.root_module.addIncludePath(generated.header.dirname());
    exe.root_module.addCSourceFile(.{ .file = generated.blob, .flags = &.{} });
    // The table is sized by the harness header's NOUC. Promote the truncation
    // warning: a NOUC that has fallen behind c43's would otherwise drop the
    // constants past it -- pi among them -- and leave the lane comparing two
    // sides that agree about a table c43 no longer has.
    exe.root_module.addCSourceFile(.{ .file = generated.table, .flags = &.{"-Werror=excess-initializers"} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/constants/constants_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/constants/constants_oracle.c"), .flags = &.{} });
    exe.root_module.addObject(parity_driver);
    exe.root_module.addObject(runtime_object);
    return exe;
}
