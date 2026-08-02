const std = @import("std");

const upstream_pin_env_path = ".github/project/upstream-pin.env";

var cached_upstream_root: ?[]const u8 = null;

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

/// C flags for a build, honouring whatever `sanitize_c` the caller asked for.
///
/// The `common_c_flags` families below carry `-fno-sanitize=undefined`, which is
/// right for the product builds -- upstream's C leans on wraparound in places --
/// but it CANCELS `Module.sanitize_c`. A lane that asks for a sanitizer and also
/// passes that flag gets no sanitizer at all, silently: the only symptom is zero
/// sanitizer symbols in the linked binary, which nothing checked. That is how
/// `test_asan`, `both_asan` and `pgm_load_fuzz` ran for their whole existence
/// without sanitizing anything. `check-sanitizer-lanes.sh` now fails the build if
/// it recurs.
pub fn sanitizerCFlags(
    target: std.Build.ResolvedTarget,
    sanitize_c: ?std.zig.SanitizeC,
) []const []const u8 {
    const windows = target.result.os.tag == .windows;
    const level = sanitize_c orelse .off;
    if (level == .off) return if (windows) common_c_flags_windows else common_c_flags;
    return if (windows) sanitized_c_flags_windows else sanitized_c_flags;
}

pub const common_c_flags: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
};

pub const common_c_flags_windows: []const []const u8 = &.{
    "-Wno-date-time",
    "-fno-sanitize=undefined",
    "-fno-strict-aliasing",
};

/// Individually justified sanitizer exclusions. Empty means "everything UBSan
/// checks is enforced".
/// Exclusions that apply ONLY to the vendored third-party C under `dep/`, which
/// z47 does not own and must not diverge from. Keeping these off the first-party
/// list is the point: a finding in z47's own C stays a finding.
const vendor_sanitizer_exclusions = [_][]const u8{
    // decNumber's own signed-shift UB: `n = n<<1` in decExpOp
    // (dep/decNumberICU/decNumber.c:5541) overflows int32 for a large enough
    // exponent, which UBSan reports as
    //   left shift of 1310720000 by 1 places cannot be represented in 'int32_t'
    // Vendored ICU code, unchanged since import. Reporting it upstream to
    // decNumber is the fix; patching a vendored library here would be a
    // divergence with no gate to protect it.
    "-fno-sanitize=shift",
};

/// C flags for the vendored `dep/` sources, honouring `sanitize_c`.
pub fn sanitizerVendorCFlags(
    target: std.Build.ResolvedTarget,
    sanitize_c: ?std.zig.SanitizeC,
) []const []const u8 {
    const windows = target.result.os.tag == .windows;
    const level = sanitize_c orelse .off;
    if (level == .off) return if (windows) common_c_flags_windows else common_c_flags;
    return if (windows) sanitized_vendor_c_flags_windows else sanitized_vendor_c_flags;
}

const sanitizer_exclusions = [_][]const u8{
    // FILED, not quietened. Removing this reports
    //   member access within misaligned address ... for type 'const decQuad',
    //   which requires 4 byte alignment
    // from decQuadGetCoefficient. Real defect: abi.Real34 is
    // `extern struct { bytes: [16]u8 }`, alignment 1, mirroring a C decQuad whose
    // _Alignof is 4 (measured). Correcting it means raising the type's alignment
    // and propagating it through the accessors that hand out `*align(1)` pointers
    // -- 1051 sites reference that spelling, so it is a project with an
    // ABI-layout gate to satisfy, not a line to change here.
    "-fno-sanitize=alignment",
};

/// `common_c_flags` minus `-fno-sanitize=undefined`, for lanes that ask for a
/// sanitizer. Each `-fno-sanitize=<check>` below is a SPECIFIC, justified
/// exclusion for a real defect that is filed and not yet fixed -- never a blanket
/// quietening. Removing one should make a lane red with a genuine finding.
pub const sanitized_c_flags: []const []const u8 = &([_][]const u8{
    "-Wno-date-time",
} ++ sanitizer_exclusions);

pub const sanitized_c_flags_windows: []const []const u8 = &([_][]const u8{
    "-Wno-date-time",
    "-fno-strict-aliasing",
} ++ sanitizer_exclusions);

pub const sanitized_vendor_c_flags: []const []const u8 =
    &([_][]const u8{"-Wno-date-time"} ++ sanitizer_exclusions ++ vendor_sanitizer_exclusions);

pub const sanitized_vendor_c_flags_windows: []const []const u8 = &([_][]const u8{
    "-Wno-date-time",
    "-fno-strict-aliasing",
} ++ sanitizer_exclusions ++ vendor_sanitizer_exclusions);

comptime {
    // The invariant that was silently violated for the whole life of the
    // `*_asan` lanes: a flag list handed to a sanitizing build must not contain
    // the blanket `-fno-sanitize=undefined`, which overrides `Module.sanitize_c`
    // and leaves the binary with no instrumentation at all. Checked here rather
    // than by inspecting built binaries, because the cache keeps older copies
    // around and `find` will happily hand you one of those instead.
    //
    // Specific `-fno-sanitize=<check>` entries are fine and expected -- each one
    // is justified above. It is the un-suffixed blanket form that must never
    // appear.
    for ([_][]const []const u8{
        sanitized_c_flags,
        sanitized_c_flags_windows,
        sanitized_vendor_c_flags,
        sanitized_vendor_c_flags_windows,
    }) |list| {
        for (list) |flag| {
            if (std.mem.eql(u8, flag, "-fno-sanitize=undefined")) {
                @compileError("a sanitizing flag list carries -fno-sanitize=undefined, " ++
                    "which cancels sanitize_c and leaves the lane instrumenting nothing");
            }
        }
    }
    // ...and the product lists must still carry it: upstream's C leans on
    // wraparound, and the shipped builds are not sanitizer lanes.
    for ([_][]const []const u8{ common_c_flags, common_c_flags_windows }) |list| {
        var found = false;
        for (list) |flag| {
            if (std.mem.eql(u8, flag, "-fno-sanitize=undefined")) found = true;
        }
        if (!found) @compileError("a product flag list lost -fno-sanitize=undefined");
    }
}

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

fn loadPinnedUpstreamRoot(b: *std.Build) []const u8 {
    return commandOutput(b, &.{
        "bash",
        "-euo",
        "pipefail",
        "-c",
        ". ./.github/project/upstream-pin.env && printf '%s' \"$UPSTREAM_ROOT\"",
    }) orelse std.debug.panic("missing or unreadable UPSTREAM_ROOT in {s}", .{upstream_pin_env_path});
}

pub fn upstreamRootString(b: *std.Build) []const u8 {
    if (cached_upstream_root) |root| return root;

    const root = loadPinnedUpstreamRoot(b);
    cached_upstream_root = root;
    return root;
}

pub fn upstreamPathString(b: *std.Build, relative: []const u8) []const u8 {
    const upstream_root = upstreamRootString(b);
    if (std.mem.eql(u8, upstream_root, ".")) return relative;

    return std.fs.path.join(b.allocator, &.{ upstream_root, relative }) catch @panic("OOM");
}

pub fn upstreamPath(b: *std.Build, relative: []const u8) std.Build.LazyPath {
    return b.path(upstreamPathString(b, relative));
}

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
