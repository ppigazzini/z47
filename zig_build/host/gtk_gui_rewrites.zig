const std = @import("std");

const retained_gtk_sources = [_][]const u8{};

const runtime_helper_sources = [_][]const u8{};

pub fn filterGtkSources(b: *std.Build, gtk_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, gtk_sources.len);
    errdefer filtered.deinit(b.allocator);

    outer: for (gtk_sources) |source| {
        for (retained_gtk_sources) |removed| {
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
    for (runtime_helper_sources) |source| {
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }

    const signal_wrappers = b.addObject(.{
        .name = b.fmt("{s}-gtk-button-signals", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/host/gtk_button_signal_wrappers.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    module.addObject(signal_wrappers);
}