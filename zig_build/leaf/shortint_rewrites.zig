const std = @import("std");
const build_common = @import("../common.zig");

pub const RuntimeObjects = struct {
    logical_mask: *std.Build.Step.Compile,
    logical_count_bits: *std.Build.Step.Compile,
    logical_set_clear_flip_bits: *std.Build.Step.Compile,
    logical_boolean_ops: *std.Build.Step.Compile,
    rotate_bits: *std.Build.Step.Compile,

    pub fn link(self: RuntimeObjects, module: *std.Build.Module) void {
        module.addObject(self.logical_mask);
        module.addObject(self.logical_count_bits);
        module.addObject(self.logical_set_clear_flip_bits);
        module.addObject(self.logical_boolean_ops);
        module.addObject(self.rotate_bits);
    }

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.logical_mask.getEmittedBin());
        cmd.addFileArg(self.logical_count_bits.getEmittedBin());
        cmd.addFileArg(self.logical_set_clear_flip_bits.getEmittedBin());
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

const replaced_core_sources = [_][]const u8{
    "logicalOps/and.c",
    "logicalOps/countBits.c",
    "logicalOps/mask.c",
    "logicalOps/nand.c",
    "logicalOps/nor.c",
    "logicalOps/not.c",
    "logicalOps/or.c",
    "logicalOps/rotateBits.c",
    "logicalOps/setClearFlipBits.c",
    "logicalOps/xnor.c",
    "logicalOps/xor.c",
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
    return b.addObject(.{
        .name = b.fmt("{s}-{s}", .{ name_prefix, name_suffix }),
        .root_module = b.createModule(.{
            .root_source_file = b.path(root_source_file),
            .target = target,
            .optimize = optimize,
            .strip = options.strip,
            .unwind_tables = options.unwind_tables,
            .stack_protector = options.stack_protector,
            .stack_check = options.stack_check,
            .omit_frame_pointer = options.omit_frame_pointer,
            .error_tracing = options.error_tracing,
        }),
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
        .logical_mask = addRuntimeObject(b, target, optimize, name_prefix, "logical-mask", "zig_src/leaf/logical_mask.zig", options),
        .logical_count_bits = addRuntimeObject(b, target, optimize, name_prefix, "logical-count-bits", "zig_src/leaf/logical_count_bits.zig", options),
        .logical_boolean_ops = addRuntimeObject(b, target, optimize, name_prefix, "logical-boolean-ops", "zig_src/leaf/logical_boolean_ops.zig", options),
        .rotate_bits = addRuntimeObject(b, target, optimize, name_prefix, "rotate-bits", "zig_src/leaf/rotate_bits.zig", options),
        .logical_set_clear_flip_bits = addRuntimeObject(b, target, optimize, name_prefix, "logical-set-clear-flip-bits", "zig_src/leaf/logical_set_clear_flip_bits.zig", options),
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

    exe.root_module.addIncludePath(b.path("zig_build/tests"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/logical_shortint_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/logical_shortint_parity.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{
        .file = build_common.upstreamPath(b, "src/c47/logicalOps/mask.c"),
        .flags = &.{ "-DfnMaskl=oracle_fnMaskl", "-DfnMaskr=oracle_fnMaskr" },
    });
    exe.root_module.addCSourceFile(.{
        .file = build_common.upstreamPath(b, "src/c47/logicalOps/countBits.c"),
        .flags = &.{"-DfnCountBits=oracle_fnCountBits"},
    });
    exe.root_module.addCSourceFile(.{
        .file = build_common.upstreamPath(b, "src/c47/logicalOps/setClearFlipBits.c"),
        .flags = &.{
            "-DfnCb=oracle_fnCb",
            "-DfnSb=oracle_fnSb",
            "-DfnFb=oracle_fnFb",
            "-DfnBc=oracle_fnBc",
            "-DfnBs=oracle_fnBs",
        },
    });
    exe.root_module.addObject(runtime_objects.logical_mask);
    exe.root_module.addObject(runtime_objects.logical_count_bits);
    exe.root_module.addObject(runtime_objects.logical_set_clear_flip_bits);
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

    exe.root_module.addIncludePath(b.path("zig_build/tests/rotate_bits"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/rotate_bits/rotate_bits_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/rotate_bits/rotate_bits_parity.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{
        .file = build_common.upstreamPath(b, "src/c47/logicalOps/rotateBits.c"),
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
