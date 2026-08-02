const std = @import("std");
const build_common = @import("../common.zig");
const calc_state = @import("../state/calc_state.zig");
const constants = @import("../constants/constants.zig");
const gtk_gui = @import("gtk_gui.zig");
const math_command_wrappers = @import("../mathematics/math_command_wrappers.zig");
const shortint = @import("../shortint/shortint.zig");
const flags = @import("../state/flags.zig");
const keyboard_state = @import("../state/keyboard_state.zig");
const memory = @import("../state/memory.zig");
const program_serialization = @import("../state/program_serialization.zig");
const frontier = @import("../frontier/frontier.zig");
const solve = @import("../solver/solve.zig");
const register_metadata = @import("../state/register_metadata.zig");
const stack = @import("../state/stack.zig");
const tone = @import("../ui/tone.zig");
const host_generated = @import("generated.zig");
const host_platform = @import("platform.zig");
const host_types = @import("types.zig");

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
    const core_sources_without_shortint = try shortint.filterCoreSources(b, core_sources);
    const core_sources_without_register_metadata = try register_metadata.filterCoreSources(b, core_sources_without_shortint);
    const core_sources_without_state = try stack.filterCoreSources(b, core_sources_without_register_metadata);
    const core_sources_without_flags = try flags.filterCoreSources(b, core_sources_without_state);
    const core_sources_without_memory = try memory.filterCoreSources(b, core_sources_without_flags);
    const core_sources_without_program_serialization = try program_serialization.filterCoreSources(b, core_sources_without_memory);
    const core_sources_without_calc_state = try calc_state.filterCoreSources(b, core_sources_without_program_serialization);
    const core_sources_without_keyboard_state = try keyboard_state.filterCoreSources(b, core_sources_without_calc_state);
    const core_sources_without_math_command_wrappers = try math_command_wrappers.filterCoreSources(b, core_sources_without_keyboard_state);
    const core_sources_without_solver = try solve.filterCoreSources(b, core_sources_without_math_command_wrappers);
    const core_sources_without_frontier = try frontier.filterCoreSources(b, core_sources_without_solver);
    const core_sources_without_constants = try constants.filterCoreSources(b, core_sources_without_frontier);
    const core_sources_without_tone = try tone.filterCoreSources(b, core_sources_without_constants);

    const version_headers_dir = try host_generated.addVersionHeaders(b, ci_commit_tag);
    const generated = try host_generated.addGeneratorSteps(b, host_target, optimize, common);

    const gtk_sources = try build_common.collectRelativeCFiles(b, build_common.upstreamPathString(b, "src/c47-gtk"));

    return .{
        .host_target = host_target,
        .common = common,
        .raw_core_sources = core_sources,
        .core_sources = core_sources_without_tone,
        .gtk_sources = try gtk_gui.filterGtkSources(b, gtk_sources),
        .test_sources = try build_common.collectRelativeCFiles(b, build_common.upstreamPathString(b, "src/testSuite")),
        .version_headers_dir = version_headers_dir,
        .generated = generated,
        .shortint_objects = shortint.addRuntimeObjects(b, host_target, optimize, "host"),
        .keyboard_state_objects = keyboard_state.addHostRuntimeObjects(b, host_target, optimize, "host", .{
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
        .stack_state_objects = stack.addRuntimeObjects(b, host_target, optimize, "host"),
    };
}
