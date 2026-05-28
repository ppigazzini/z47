const std = @import("std");

const retained_gtk_sources_manifest = @embedFile("gtk_gui_retained_gtk_sources.txt");
const runtime_helper_sources_manifest = @embedFile("gtk_gui_runtime_helper_sources.txt");

fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (std.mem.eql(u8, line, needle)) return true;
    }
    return false;
}

pub fn filterGtkSources(b: *std.Build, gtk_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, gtk_sources.len);
    errdefer filtered.deinit(b.allocator);

    for (gtk_sources) |source| {
        if (manifestContainsPath(retained_gtk_sources_manifest, source)) {
            continue;
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
    var lines = std.mem.tokenizeAny(u8, runtime_helper_sources_manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const source = std.mem.trim(u8, line_raw, " \t");
        if (source.len == 0 or source[0] == '#') continue;
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }

    const signal_wrappers = b.addObject(.{
        .name = b.fmt("{s}-gtk-button-signals", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_button_signals_export.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const gui_wrappers = b.addObject(.{
        .name = b.fmt("{s}-gtk-gui-wrappers", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_gui_wrappers.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const hal_runtime = b.addObject(.{
        .name = b.fmt("{s}-gtk-hal-runtime", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_hal_runtime.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const io_runtime = b.addObject(.{
        .name = b.fmt("{s}-gtk-io-runtime", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_io_runtime.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const lcd_runtime = b.addObject(.{
        .name = b.fmt("{s}-gtk-lcd-runtime", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_lcd_runtime.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    module.addObject(signal_wrappers);
    module.addObject(gui_wrappers);
    module.addObject(hal_runtime);
    module.addObject(io_runtime);
    module.addObject(lcd_runtime);
}