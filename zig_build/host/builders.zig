const std = @import("std");
const build_common = @import("../common.zig");
const calc_state_rewrites = @import("../state/calc_state_rewrites.zig");
const constants_rewrites = @import("../leaf/constants_rewrites.zig");
const flags_rewrites = @import("../state/flags_rewrites.zig");
const math_command_wrapper_rewrites = @import("../mathematics/math_command_wrapper_rewrites.zig");
const memory_rewrites = @import("../state/memory_rewrites.zig");
const keyboard_state_rewrites = @import("../state/keyboard_state_rewrites.zig");
const program_serialization_rewrites = @import("../state/program_serialization_rewrites.zig");
const host_platform = @import("platform.zig");
const register_metadata_rewrites = @import("../state/register_metadata_rewrites.zig");
const tone_rewrites = @import("../ui/tone_rewrites.zig");
const host_types = @import("types.zig");

pub fn addSimulator(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    name: []const u8,
    artifact_name: []const u8,
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    gtk_sources: []const []const u8,
    common: host_types.CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: host_types.GeneratedOutputs,
    shortint_leaf_objects: host_types.ShortIntLeafObjects,
    keyboard_state_objects: host_types.KeyboardStateObjects,
    stack_state_objects: host_types.StackStateObjects,
    calc_model: []const u8,
    sanitize_c: ?std.zig.SanitizeC,
) *std.Build.Step.Compile {
    const core_c_flags = if (host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = artifact_name,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (sanitize_c) |level| {
        exe.root_module.sanitize_c = level;
    }
    if (host_target.result.os.tag == .windows) {
        exe.subsystem = .Windows;
    }
    host_platform.addHostMacros(exe.root_module, common);
    host_platform.addHostSystemPaths(exe.root_module, common);
    if (common.needs_gnu_source) {
        exe.root_module.addCMacro("_GNU_SOURCE", "1");
    }
    if (common.have_dladdr) {
        exe.root_module.addCMacro("HAVE_DLADDR", "1");
    }
    exe.root_module.addCMacro("CALCMODEL", calc_model);
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47-gtk"));
    exe.root_module.addIncludePath(version_headers_dir);
    exe.root_module.addIncludePath(generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(generated.constant_pointers_h.dirname());
    if (host_target.result.os.tag == .windows) {
        exe.root_module.addWin32ResourceFile(.{
            .file = build_common.upstreamPath(b, b.fmt("src/c47-gtk/{s}-gtk.rc", .{name})),
            .include_paths = &.{
                build_common.upstreamPath(b, "src/c47"),
                version_headers_dir,
            },
        });
    }
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = core_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47-gtk"), .files = gtk_sources, .flags = build_common.common_gtk_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/host/gtk_button_signal_wrappers.c"), .flags = build_common.common_gtk_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/host/gtk_gui_retained.c"), .flags = build_common.common_gtk_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_runtime_helpers.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_overlay.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_retained.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/stack_runtime_helpers.c"), .flags = core_c_flags });
    memory_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    calc_state_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    program_serialization_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    register_metadata_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    flags_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    math_command_wrapper_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    constants_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    tone_rewrites.addToModule(b, exe.root_module, host_target, optimize, artifact_name, core_c_flags);
    exe.root_module.addCSourceFile(.{ .file = generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers2_c, .flags = core_c_flags });
    shortint_leaf_objects.link(exe.root_module);
    exe.root_module.addObject(keyboard_state_objects.keyboard_state);
    exe.root_module.addObject(stack_state_objects.stack_state);
    host_platform.linkGtk3(exe.root_module, common);
    host_platform.linkGmp(exe.root_module, host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    if (common.needs_libdl) {
        exe.root_module.linkSystemLibrary("dl", .{});
    }
    if (common.with_pulseaudio) {
        exe.root_module.addCMacro("WITH_PULSEAUDIO", "1");
        exe.root_module.linkSystemLibrary("libpulse-simple", .{ .use_pkg_config = .force, .needed = false });
    }
    return exe;
}

pub fn addTestSuite(
    b: *std.Build,
    host_target: std.Build.ResolvedTarget,
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    core_sources: []const []const u8,
    test_sources: []const []const u8,
    common: host_types.CommonConfig,
    version_headers_dir: std.Build.LazyPath,
    generated: host_types.GeneratedOutputs,
    shortint_leaf_objects: host_types.ShortIntLeafObjects,
    keyboard_state_objects: host_types.KeyboardStateObjects,
    stack_state_objects: host_types.StackStateObjects,
    sanitize_c: ?std.zig.SanitizeC,
) *std.Build.Step.Compile {
    const core_c_flags = if (host_target.result.os.tag == .windows)
        build_common.common_c_flags_windows
    else
        build_common.common_c_flags;

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = host_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (sanitize_c) |level| {
        exe.root_module.sanitize_c = level;
    }
    host_platform.addHostMacros(exe.root_module, common);
    host_platform.addHostSystemPaths(exe.root_module, common);
    exe.root_module.addCMacro("TESTSUITE_BUILD", "1");
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
    exe.root_module.addIncludePath(build_common.upstreamPath(b, "src/testSuite"));
    exe.root_module.addIncludePath(version_headers_dir);
    exe.root_module.addIncludePath(generated.softmenu_catalogs.dirname());
    exe.root_module.addIncludePath(generated.constant_pointers_h.dirname());
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "dep"), .files = build_common.decnumber_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/c47"), .files = core_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFiles(.{ .root = build_common.upstreamPath(b, "src/testSuite"), .files = test_sources, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_runtime_helpers.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_overlay.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/keyboard_state_retained.c"), .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/state/stack_runtime_helpers.c"), .flags = core_c_flags });
    memory_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    calc_state_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    program_serialization_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    register_metadata_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    flags_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    math_command_wrapper_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    constants_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    tone_rewrites.addToModule(b, exe.root_module, host_target, optimize, name, core_c_flags);
    exe.root_module.addCSourceFile(.{ .file = generated.raster_fonts_data, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers_c, .flags = core_c_flags });
    exe.root_module.addCSourceFile(.{ .file = generated.constant_pointers2_c, .flags = core_c_flags });
    shortint_leaf_objects.link(exe.root_module);
    exe.root_module.addObject(keyboard_state_objects.keyboard_state);
    exe.root_module.addObject(stack_state_objects.stack_state);
    host_platform.linkGtk3(exe.root_module, common);
    host_platform.linkGmp(exe.root_module, host_target);
    exe.root_module.linkSystemLibrary("m", .{});
    return exe;
}
