const std = @import("std");
const build_common = @import("../common.zig");
const calc_state_rewrites = @import("../state/calc_state_rewrites.zig");
const shortint_rewrites = @import("../leaf/shortint_rewrites.zig");
const flags_rewrites = @import("../state/flags_rewrites.zig");
const keyboard_state_rewrites = @import("../state/keyboard_state_rewrites.zig");
const memory_rewrites = @import("../state/memory_rewrites.zig");
const program_serialization_rewrites = @import("../state/program_serialization_rewrites.zig");
const register_metadata_rewrites = @import("../state/register_metadata_rewrites.zig");
const stack_rewrites = @import("../state/stack_rewrites.zig");
const host_generated = @import("generated.zig");
const host_platform = @import("platform.zig");
const host_types = @import("types.zig");

fn filterSourceByName(
    b: *std.Build,
    sources: []const []const u8,
    excluded_name: []const u8,
) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, sources.len);
    errdefer filtered.deinit(b.allocator);

    for (sources) |source| {
        if (std.mem.eql(u8, source, excluded_name)) continue;
        try filtered.append(b.allocator, source);
    }

    return try filtered.toOwnedSlice(b.allocator);
}

pub fn prepareContext(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    ci_commit_tag: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
) !host_types.Context {
    const host_target = build_common.resolveBuildHostTarget(b);
    const common = try host_platform.resolveCommonConfig(b, host_target, raspberry, decnumber_fastmul);
    const core_sources = try build_common.collectRelativeCFiles(b, build_common.upstreamPathString(b, "src/c47"));
    const core_sources_without_shortint = try shortint_rewrites.filterCoreSources(b, core_sources);
    const core_sources_without_register_metadata = try register_metadata_rewrites.filterCoreSources(b, core_sources_without_shortint);
    const core_sources_without_state = try stack_rewrites.filterCoreSources(b, core_sources_without_register_metadata);
    const core_sources_without_flags = try flags_rewrites.filterCoreSources(b, core_sources_without_state);
    const core_sources_without_memory = try memory_rewrites.filterCoreSources(b, core_sources_without_flags);
    const core_sources_without_program_serialization = try program_serialization_rewrites.filterCoreSources(b, core_sources_without_memory);
    const core_sources_without_calc_state = try calc_state_rewrites.filterCoreSources(b, core_sources_without_program_serialization);
    const core_sources_without_keyboard_state = try keyboard_state_rewrites.filterCoreSources(b, core_sources_without_calc_state);

    const version_headers_dir = try host_generated.addVersionHeaders(b, ci_commit_tag);
    const generated = try host_generated.addGeneratorSteps(b, host_target, optimize, common);

    const gtk_sources = try build_common.collectRelativeCFiles(b, build_common.upstreamPathString(b, "src/c47-gtk"));

    return .{
        .host_target = host_target,
        .common = common,
        .core_sources = core_sources_without_keyboard_state,
        .gtk_sources = try filterSourceByName(b, gtk_sources, "gtkGui.c"),
        .test_sources = try build_common.collectRelativeCFiles(b, build_common.upstreamPathString(b, "src/testSuite")),
        .version_headers_dir = version_headers_dir,
        .generated = generated,
        .shortint_leaf_objects = shortint_rewrites.addRuntimeObjects(b, host_target, optimize, "host"),
        .keyboard_state_objects = keyboard_state_rewrites.addHostRuntimeObjects(b, host_target, optimize, "host", .{
            .platform_define = common.platform_define,
            .word_size_define = common.word_size_define,
            .raspberry = common.raspberry,
            .decnumber_fastmul = common.decnumber_fastmul,
            .needs_gnu_source = common.needs_gnu_source,
            .have_dladdr = common.have_dladdr,
            .generated_headers = .{
                .version_headers_dir = version_headers_dir,
                .softmenu_catalogs_dir = generated.softmenu_catalogs.dirname(),
                .constant_pointers_h_dir = generated.constant_pointers_h.dirname(),
            },
        }),
        .stack_state_objects = stack_rewrites.addRuntimeObjects(b, host_target, optimize, "host"),
    };
}
