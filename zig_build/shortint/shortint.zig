const std = @import("std");
const abi_host = @import("../abi_host.zig");
const build_common = @import("../common.zig");

const replaced_core_sources_manifest = @embedFile("shortint_replaced_core_sources.txt");
const parity_oracle_sources_manifest = @embedFile("shortint_parity_oracle_sources.txt");
const rotate_bits_oracle_source_manifest = @embedFile("shortint_rotate_bits_oracle_source.txt");

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (std.mem.eql(u8, line, needle)) return true;
    }
    return false;
}

fn firstManifestPath(manifest: []const u8) []const u8 {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        return line;
    }
    @panic("manifest has no usable path entries");
}

pub const RuntimeObjects = struct {
    bit_manipulation: *std.Build.Step.Compile,
    logical_boolean_ops: *std.Build.Step.Compile,
    rotate_bits: *std.Build.Step.Compile,

    pub fn link(self: RuntimeObjects, module: *std.Build.Module) void {
        module.addObject(self.bit_manipulation);
        module.addObject(self.logical_boolean_ops);
        module.addObject(self.rotate_bits);
    }

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.bit_manipulation.getEmittedBin());
        cmd.addFileArg(self.logical_boolean_ops.getEmittedBin());
        cmd.addFileArg(self.rotate_bits.getEmittedBin());
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

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    name_suffix: []const u8,
    root_source_file: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path(root_source_file),
        .target = target,
        .optimize = optimize,
        .strip = options.strip,
        .unwind_tables = options.unwind_tables,
        .stack_protector = options.stack_protector,
        .stack_check = options.stack_check,
        .omit_frame_pointer = options.omit_frame_pointer,
        .error_tracing = options.error_tracing,
    });
    // L1 shared ABI bindings (REPORT-23 §5), imported as `@import("abi")`.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("abi", abi_module);
    return b.addObject(.{
        .name = b.fmt("{s}-{s}", .{ name_prefix, name_suffix }),
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
        .bit_manipulation = addRuntimeObject(b, target, optimize, name_prefix, "bit-manipulation", "zig_src/core/numeric/integer/bit_manipulation.zig", options),
        .logical_boolean_ops = addRuntimeObject(b, target, optimize, name_prefix, "logical-boolean-ops", "zig_src/core/numeric/integer/logical_boolean_ops.zig", options),
        .rotate_bits = addRuntimeObject(b, target, optimize, name_prefix, "rotate-bits", "zig_src/core/numeric/integer/rotate_bits.zig", options),
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

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    runtime_objects: RuntimeObjects,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "logical-shortint-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "logical-shortint-parity");

    exe.root_module.addIncludePath(b.path("zig_build/tests"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/logical_shortint_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/logical_shortint_parity.c"), .flags = &.{} });
    var parity_oracle_paths = std.mem.tokenizeAny(u8, parity_oracle_sources_manifest, "\r\n");
    const mask_source = std.mem.trim(u8, parity_oracle_paths.next().?, " \t");
    const count_bits_source = std.mem.trim(u8, parity_oracle_paths.next().?, " \t");
    const set_clear_flip_bits_source = std.mem.trim(u8, parity_oracle_paths.next().?, " \t");
    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, mask_source), .flags = &.{ "-DfnMaskl=oracle_fnMaskl", "-DfnMaskr=oracle_fnMaskr" } });
    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, count_bits_source), .flags = &.{"-DfnCountBits=oracle_fnCountBits"} });
    exe.root_module.addCSourceFile(.{ .file = build_common.upstreamPath(b, set_clear_flip_bits_source), .flags = &.{ "-DfnCb=oracle_fnCb", "-DfnSb=oracle_fnSb", "-DfnFb=oracle_fnFb", "-DfnBc=oracle_fnBc", "-DfnBs=oracle_fnBs" } });
    exe.root_module.addObject(runtime_objects.bit_manipulation);
    return exe;
}

pub fn addRotateBitsParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rotate_bits_object: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "rotate-bits-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    abi_host.addToModule(b, exe.root_module, target, optimize, "rotate-bits-parity");

    exe.root_module.addIncludePath(b.path("zig_build/tests/rotate_bits"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/rotate_bits/rotate_bits_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/rotate_bits/rotate_bits_parity.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{
        .file = build_common.upstreamPath(b, firstManifestPath(rotate_bits_oracle_source_manifest)),
        .flags = &.{
            "-DfnAsr=oracle_fnAsr",
            "-DfnSl=oracle_fnSl",
            "-DfnSr=oracle_fnSr",
            "-DfnRl=oracle_fnRl",
            "-DfnRr=oracle_fnRr",
            "-DfnRlc=oracle_fnRlc",
            "-DfnRrc=oracle_fnRrc",
            "-DfnLj=oracle_fnLj",
            "-DfnRj=oracle_fnRj",
            "-DfnMirror=oracle_fnMirror",
            "-DfnSwapEndian=oracle_fnSwapEndian",
            "-DfnZip=oracle_fnZip",
            "-DfnUnzip=oracle_fnUnzip",
        },
    });
    exe.root_module.addObject(rotate_bits_object);
    return exe;
}
