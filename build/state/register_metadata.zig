const std = @import("std");
const abi_host = @import("../abi_host.zig");

pub const RuntimeObjects = struct {
    register_metadata: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        cmd.addFileArg(self.register_metadata.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
    // EXTRA_INFO_ON_CALC_ERROR. The register-metadata owners format the
    // "is not defined!" subject and range into the shared errorMessage buffer,
    // which upstream compiles out with the hints; the macro is 0 on firmware and
    // in the testSuite. Default true mirrors a host build.
    extra_info_on_calc_error: bool = true,
};

const replaced_core_sources = [_][]const u8{
    "registers.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/state/register_metadata.zig"),
        .target = target,
        .optimize = optimize,
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
    const stack_build_options = b.addOptions();
    stack_build_options.addOption(bool, "use_fake_stack_state_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    // Same option set, and the same derivation, as the stack object builds under
    // this name: the two objects share owner files, so a fact carried by one copy
    // of the module and not the other makes one of the two read a default.
    stack_build_options.addOption(bool, "extra_info_on_calc_error", options.extra_info_on_calc_error and
        !std.mem.startsWith(u8, name_prefix, "testSuite"));
    module.addOptions("stack_state_build_options", stack_build_options);

    const register_metadata_options = b.addOptions();
    register_metadata_options.addOption(bool, "extra_info_on_calc_error", options.extra_info_on_calc_error and
        !std.mem.startsWith(u8, name_prefix, "testSuite"));
    module.addOptions("register_metadata_build_options", register_metadata_options);

    const descriptor_storage_options = b.addOptions();
    descriptor_storage_options.addOption(bool, "use_array_backed_global_registers", std.mem.endsWith(u8, name_prefix, "parity") or std.mem.eql(u8, name_prefix, "dmcp"));
    descriptor_storage_options.addOption(bool, "use_fake_state_harness_surface", std.mem.endsWith(u8, name_prefix, "parity"));
    module.addOptions("state_descriptor_storage_build_options", descriptor_storage_options);

    return b.addObject(.{
        .name = b.fmt("{s}-register-metadata", .{name_prefix}),
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
        .register_metadata = addRuntimeObject(b, target, optimize, name_prefix, options),
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
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});
    _ = c_flags;

    module.addObject(runtime_object);
}

// NO addParityExecutable HERE, deliberately.
//
// The register-metadata parity lane used to be a unit executable over a MOCK
// world: 1060 lines of hand-transliterated oracle, a 939-line driver, and 1649
// lines of fake runtime whose `registerHeader_t` was a packed descriptor word
// rather than c43's bitfield struct. It is now a FULL-CORE differential
// (build/host/steps.zig: register_metadata_parity) against c43's own registers.c,
// because registers.c IS the register subsystem: sharing state with the Zig owner
// means sharing globalRegister, the named variables, the RAM slab and the free
// list, which is the whole calculator. The owner-side
// `use_fake_register_metadata_harness_surface` fork went with it -- it replaced
// twenty-one call sites with fakes, so the build the lane measured was not the
// build that ships, and three live defects were hiding behind it.
