const std = @import("std");
const build_common = @import("../common.zig");
const host_types = @import("types.zig");
const TranslateC = std.Build.Step.TranslateC;

const HostSearchPathKind = enum {
    include,
    library,
};

const PkgConfigTokenKind = enum {
    include,
    library_path,
    define,
    library,
};

const TranslateCPkgConfigTokenKind = enum {
    include,
    define,
};

pub fn resolveCommonConfig(
    b: *std.Build,
    host: std.Build.ResolvedTarget,
    raspberry: bool,
    decnumber_fastmul: bool,
) !host_types.CommonConfig {
    return .{
        .platform_define = switch (host.result.os.tag) {
            .linux => "LINUX",
            .macos => "OSX",
            .windows => "WIN32",
            else => return error.UnsupportedHostPlatform,
        },
        .word_size_define = switch (host.result.cpu.arch) {
            .x86_64, .aarch64 => "OS64BIT",
            .x86, .arm => "OS32BIT",
            else => return error.UnsupportedArchitecture,
        },
        .raspberry = raspberry,
        .decnumber_fastmul = decnumber_fastmul,
        .with_pulseaudio = switch (host.result.os.tag) {
            .linux, .macos => build_common.pkgConfigExists(b, "libpulse-simple"),
            .windows => false,
            else => false,
        },
        .needs_gnu_source = host.result.os.tag == .linux,
        .have_dladdr = switch (host.result.os.tag) {
            .linux, .macos => true,
            .windows => false,
            else => false,
        },
        .needs_libdl = host.result.os.tag == .linux,
    };
}

pub fn linkGtk3(module: *std.Build.Module, common: host_types.CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) {
        module.linkSystemLibrary("gtk+-3.0", .{ .use_pkg_config = .force });
        return;
    }

    if (!linkWindowsPkgConfigPackage(module, "gtk+-3.0")) {
        module.linkSystemLibrary("gtk+-3.0", .{
            .use_pkg_config = .force,
            .preferred_link_mode = .dynamic,
            .search_strategy = .mode_first,
        });
    }
}

pub fn addHostMacros(module: *std.Build.Module, common: host_types.CommonConfig) void {
    module.addCMacro("PC_BUILD", "1");
    module.addCMacro(common.platform_define, "1");
    module.addCMacro(common.word_size_define, "1");
    if (common.raspberry) {
        module.addCMacro("RASPBERRY", "1");
    }
    if (common.decnumber_fastmul) {
        module.addCMacro("DECNUMBER_FASTMUL", "1");
    }
}

pub fn addHostSystemPaths(module: *std.Build.Module, common: host_types.CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) return;

    const owner = module.owner;
    if (owner.graph.environ_map.get("PKG_CONFIG_SYSTEM_INCLUDE_PATH")) |include_paths| {
        addHostSearchPaths(module, include_paths, .include);
    } else if (windowsHostPrefix(module)) |prefix| {
        module.addSystemIncludePath(.{ .cwd_relative = owner.fmt("{s}/include", .{prefix}) });
    }
    if (owner.graph.environ_map.get("PKG_CONFIG_SYSTEM_LIBRARY_PATH")) |library_paths| {
        addHostSearchPaths(module, library_paths, .library);
    } else if (windowsHostPrefix(module)) |prefix| {
        module.addLibraryPath(.{ .cwd_relative = owner.fmt("{s}/lib", .{prefix}) });
    }
}

pub fn linkRasterFontsFreetype(module: *std.Build.Module, common: host_types.CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) {
        module.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
        return;
    }

    if (!linkWindowsPkgConfigPackage(module, "freetype2")) {
        module.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
    }
}

pub fn configureRasterFontsTranslateC(translate_c: *TranslateC, common: host_types.CommonConfig) void {
    if (!std.mem.eql(u8, common.platform_define, "WIN32")) {
        translate_c.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
        return;
    }

    if (addWindowsPkgConfigCFlagsTranslateC(translate_c, "freetype2")) {
        return;
    }

    if (windowsHostPrefixFromOwner(translate_c.step.owner)) |prefix| {
        translate_c.addSystemIncludePath(.{ .cwd_relative = translate_c.step.owner.fmt("{s}/include/freetype2", .{prefix}) });
        return;
    }

    translate_c.linkSystemLibrary("freetype2", .{ .use_pkg_config = .force });
}

fn linkWindowsPkgConfigPackage(module: *std.Build.Module, package: []const u8) bool {
    const flags = build_common.commandOutput(module.owner, &.{ "pkg-config", "--cflags", "--libs", package }) orelse return false;

    var tokens = std.mem.tokenizeAny(u8, flags, " \t\r\n");
    var pending: ?PkgConfigTokenKind = null;

    while (tokens.next()) |token| {
        if (pending) |kind| {
            addWindowsPkgConfigToken(module, token, kind);
            pending = null;
            continue;
        }

        if (std.mem.eql(u8, token, "-I")) {
            pending = .include;
            continue;
        }
        if (std.mem.eql(u8, token, "-L")) {
            pending = .library_path;
            continue;
        }
        if (std.mem.eql(u8, token, "-D")) {
            pending = .define;
            continue;
        }
        if (std.mem.eql(u8, token, "-l")) {
            pending = .library;
            continue;
        }

        if (std.mem.startsWith(u8, token, "-I")) {
            addWindowsPkgConfigToken(module, token[2..], .include);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-L")) {
            addWindowsPkgConfigToken(module, token[2..], .library_path);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-D")) {
            addWindowsPkgConfigToken(module, token[2..], .define);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-l")) {
            addWindowsPkgConfigToken(module, token[2..], .library);
            continue;
        }
    }

    return pending == null;
}

fn addWindowsPkgConfigCFlagsTranslateC(translate_c: *TranslateC, package: []const u8) bool {
    const flags = build_common.commandOutput(translate_c.step.owner, &.{ "pkg-config", "--cflags", package }) orelse return false;

    var tokens = std.mem.tokenizeAny(u8, flags, " \t\r\n");
    var pending: ?TranslateCPkgConfigTokenKind = null;

    while (tokens.next()) |token| {
        if (pending) |kind| {
            addTranslateCPkgConfigToken(translate_c, token, kind);
            pending = null;
            continue;
        }

        if (std.mem.eql(u8, token, "-I")) {
            pending = .include;
            continue;
        }
        if (std.mem.eql(u8, token, "-D")) {
            pending = .define;
            continue;
        }

        if (std.mem.startsWith(u8, token, "-I")) {
            addTranslateCPkgConfigToken(translate_c, token[2..], .include);
            continue;
        }
        if (std.mem.startsWith(u8, token, "-D")) {
            addTranslateCPkgConfigToken(translate_c, token[2..], .define);
            continue;
        }
    }

    return pending == null;
}

fn addWindowsPkgConfigToken(module: *std.Build.Module, token: []const u8, kind: PkgConfigTokenKind) void {
    switch (kind) {
        .include => module.addSystemIncludePath(.{ .cwd_relative = token }),
        .library_path => module.addLibraryPath(.{ .cwd_relative = token }),
        .define => addPkgConfigDefine(module, token),
        .library => linkWindowsImportLibraryOrSystem(module, token),
    }
}

fn addTranslateCPkgConfigToken(translate_c: *TranslateC, token: []const u8, kind: TranslateCPkgConfigTokenKind) void {
    switch (kind) {
        .include => translate_c.addSystemIncludePath(.{ .cwd_relative = token }),
        .define => addTranslateCPkgConfigDefine(translate_c, token),
    }
}

fn addPkgConfigDefine(module: *std.Build.Module, define: []const u8) void {
    if (std.mem.indexOfScalar(u8, define, '=')) |eq| {
        module.addCMacro(define[0..eq], define[eq + 1 ..]);
        return;
    }

    module.addCMacro(define, "1");
}

fn addTranslateCPkgConfigDefine(translate_c: *TranslateC, define: []const u8) void {
    if (std.mem.indexOfScalar(u8, define, '=')) |eq| {
        translate_c.defineCMacro(define[0..eq], define[eq + 1 ..]);
        return;
    }

    translate_c.defineCMacro(define, "1");
}

fn linkWindowsImportLibraryOrSystem(module: *std.Build.Module, name: []const u8) void {
    const prefix = windowsHostPrefix(module) orelse {
        module.linkSystemLibrary(name, .{ .use_pkg_config = .no });
        return;
    };

    const import_library = module.owner.fmt("{s}/lib/lib{s}.dll.a", .{ prefix, name });
    const exists = blk: {
        if (std.fs.path.isAbsolute(import_library)) {
            std.Io.Dir.accessAbsolute(module.owner.graph.io, import_library, .{}) catch break :blk false;
            break :blk true;
        }

        std.Io.Dir.cwd().access(module.owner.graph.io, import_library, .{}) catch break :blk false;
        break :blk true;
    };

    if (exists) {
        module.addObjectFile(.{ .cwd_relative = import_library });
        return;
    }

    module.linkSystemLibrary(name, .{ .use_pkg_config = .no });
}

fn windowsHostPrefixFromOwner(owner: *std.Build) ?[]const u8 {
    return owner.graph.environ_map.get("MSYSTEM_PREFIX") orelse owner.graph.environ_map.get("MINGW_PREFIX");
}

fn windowsHostPrefix(module: *std.Build.Module) ?[]const u8 {
    return windowsHostPrefixFromOwner(module.owner);
}

fn addHostSearchPaths(module: *std.Build.Module, paths: []const u8, comptime kind: HostSearchPathKind) void {
    const separator: ?u8 = blk: {
        if (std.mem.indexOfScalar(u8, paths, ';') != null) break :blk ';';
        if (looksLikeWindowsAbsolutePath(paths)) break :blk null;
        break :blk ':';
    };

    if (separator) |sep| {
        var iter = std.mem.tokenizeScalar(u8, paths, sep);
        while (iter.next()) |path| {
            if (path.len == 0) continue;
            addHostSearchPath(module, path, kind);
        }
        return;
    }

    addHostSearchPath(module, paths, kind);
}

fn addHostSearchPath(module: *std.Build.Module, path: []const u8, comptime kind: HostSearchPathKind) void {
    switch (kind) {
        .include => module.addSystemIncludePath(.{ .cwd_relative = path }),
        .library => module.addLibraryPath(.{ .cwd_relative = path }),
    }
}

fn looksLikeWindowsAbsolutePath(path: []const u8) bool {
    return path.len >= 3 and std.ascii.isAlphabetic(path[0]) and path[1] == ':' and (path[2] == '/' or path[2] == '\\');
}
