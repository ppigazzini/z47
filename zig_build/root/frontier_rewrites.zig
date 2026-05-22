const std = @import("std");

const replaced_core_sources = [_][]const u8{
    "c47Extensions/addons.c",
    "display.c",
    "items.c",
    "softmenus.c",
    "screen.c",
};

const runtime_helper_sources = [_][]const u8{
    "zig_bridge/root/addons_retained.c",
    "zig_bridge/root/display_retained.c",
    "zig_bridge/root/items_retained.c",
    "zig_bridge/root/softmenus_retained.c",
    "zig_bridge/root/screen_retained.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-frontier-root", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/root/frontier_entries.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
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
    for (runtime_helper_sources) |source| {
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix);
    module.addObject(runtime_object);
}