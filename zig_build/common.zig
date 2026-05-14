const std = @import("std");

pub const decnumber_sources: []const []const u8 = &.{
    "decNumberICU/decContext.c",
    "decNumberICU/decDouble.c",
    "decNumberICU/decimal128.c",
    "decNumberICU/decimal64.c",
    "decNumberICU/decNumber.c",
    "decNumberICU/decQuad.c",
};

pub const generate_catalogs_sources: []const []const u8 = &.{
    "charString.c",
    "fonts.c",
    "items.c",
    "sort.c",
};

pub const generate_testpgms_sources: []const []const u8 = &.{
    "items.c",
    "c47.c",
};

pub const common_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

pub const common_c_flags_windows: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-fno-strict-aliasing",
};

pub const common_gtk_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-fstack-protector-strong",
};

pub const font_generator_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-DGENERATE_FONTS",
};

pub const generate_constants_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

pub const generate_catalogs_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

pub const generate_testpgms_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

pub const StepFile = struct {
    step: *std.Build.Step,
    path: std.Build.LazyPath,
};

pub fn addBashCommand(b: *std.Build, script: []const u8) *std.Build.Step.Run {
    return addBashCommandFmt(b, "{s}", .{script});
}

pub fn addBashCommandFmt(b: *std.Build, comptime fmt: []const u8, args: anytype) *std.Build.Step.Run {
    const script = std.fmt.allocPrint(b.allocator, fmt, args) catch @panic("OOM");
    const cmd = b.addSystemCommand(&.{ "bash", "-euo", "pipefail", "-c", script });
    cmd.setCwd(b.path("."));
    return cmd;
}

pub fn resolveBuildHostTarget(b: *std.Build) std.Build.ResolvedTarget {
    const host_target = b.graph.host;
    const needs_baseline_cpu = switch (host_target.result.cpu.arch) {
        .x86, .x86_64 => true,
        else => false,
    };

    if (!needs_baseline_cpu and host_target.result.os.tag != .windows) return host_target;

    var query: std.Target.Query = .{};
    if (needs_baseline_cpu) query.cpu_model = .baseline;
    if (host_target.result.os.tag == .windows) query.abi = .gnu;
    return b.resolveTargetQuery(query);
}

pub fn collectRelativeCFiles(b: *std.Build, root_path: []const u8) ![][]const u8 {
    var files = try std.ArrayList([]const u8).initCapacity(b.allocator, 0);
    errdefer files.deinit(b.allocator);
    var dir = try std.Io.Dir.cwd().openDir(b.graph.io, root_path, .{ .iterate = true });
    defer dir.close(b.graph.io);

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".c")) continue;
        if (std.mem.eql(u8, entry.path, "reservedRegisterLookupGenerator.c")) continue;

        const relative_path = try b.allocator.dupe(u8, entry.path);
        if (std.fs.path.sep != '/') {
            for (relative_path) |*byte| {
                if (byte.* == std.fs.path.sep) byte.* = '/';
            }
        }

        try files.append(b.allocator, relative_path);
    }

    return try files.toOwnedSlice(b.allocator);
}

pub fn commandOutput(b: *std.Build, argv: []const []const u8) ?[]const u8 {
    const result = std.process.run(b.allocator, b.graph.io, .{
        .argv = argv,
        .environ_map = &b.graph.environ_map,
    }) catch return null;

    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!ok) return null;

    return std.mem.trimEnd(u8, result.stdout, "\r\n");
}

pub fn pkgConfigExists(b: *std.Build, package: []const u8) bool {
    const result = std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ "pkg-config", "--exists", package },
        .environ_map = &b.graph.environ_map,
    }) catch return false;

    return switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
}
