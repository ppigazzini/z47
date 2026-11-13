const std = @import("std");
const build_common = @import("../common.zig");
const abi_host = @import("../abi_host.zig");

pub const RuntimeObjects = struct {
    memory_state: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg2(self.memory_state.getEmittedBin(), .{});
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
};

const replaced_core_sources = [_][]const u8{
    "memory.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/memory/memory.zig"),
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
    // L1 shared ABI bindings.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    // The DMCP ROM shim the GMP allocator's exhaustion stop calls; the same
    // registered module the calc-state and program-serialization owners import.
    const dmcp_rom_module = build_common.addDmcpRomModule(b, target, optimize, options.board);
    module.addImport("dmcp_rom", dmcp_rom_module);
    const build_options = b.addOptions();
    const use_fake_harness_surface = options.linkage == .fake_harness;
    const free_regions_are_inline_array = options.board.isOldHw();
    build_options.addOption(bool, "use_fake_harness_surface", use_fake_harness_surface);
    build_options.addOption(bool, "free_regions_are_inline_array", free_regions_are_inline_array);
    build_options.addOption(usize, "max_free_regions", if (free_regions_are_inline_array) 50 else 200);
    // RAM_SIZE_IN_BLOCKS, from defines.h. The fake surface asks its harness for
    // the pool size at run time and never reads this.
    build_options.addOption(u16, "ram_size_in_blocks", build_common.ramSizeInBlocks(b, options.board));
    module.addOptions("memory_build_options", build_options);

    return b.addObject(.{
        .name = b.fmt("{s}-memory-state", .{name_prefix}),
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
        .memory_state = addRuntimeObject(b, target, optimize, name_prefix, options),
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
    optimize: std.lang.Optimize,
    name_prefix: []const u8,
) void {
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});

    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{ .linkage = .fake_harness });
    const exe = b.addExecutable(.{
        .name = "memory-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "memory-parity");

    exe.root_module.addIncludePath(b.path("build/tests/memory"));
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/memory/memory_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/memory/memory_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("build/tests/memory/memory_parity.c"), .flags = &.{} });
    exe.root_module.addObject(runtime_object);
    return exe;
}
