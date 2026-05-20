const std = @import("std");

const retained_gtk_sources = [_][]const u8{
    "gtkGui.c",
};

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
    c_flags: []const []const u8,
) void {
    module.addCSourceFile(.{ .file = b.path("zig_build/host/gtk_button_signal_wrappers.c"), .flags = c_flags });
    module.addCSourceFile(.{ .file = b.path("zig_build/host/gtk_gui_retained.c"), .flags = c_flags });
}