// SPDX-License-Identifier: GPL-3.0-only
const std = @import("std");
const Translator = @import("translate_c").Translator;

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
/// sanitizer symbols in the linked binary. The `comptime` block after the flag
/// lists fails the build if a sanitizing list carries it.
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
    //   load of misaligned address ... for type 'uint64_t', which requires 8 byte
    //   alignment
    // from upstream's testSuite.c (checkExpectedOutParameter), which reads a
    // short integer as `*REGISTER_SHORT_INTEGER_DATA(r)`: a uint64_t at a pool
    // block address, which the C47 allocator aligns to 4. The access is
    // upstream's, in retained C z47 must not diverge from; abi.registers views
    // the same payload as `*align(4) u64`. The fix is an upstream report.
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

    return std.Io.Dir.path.join(b.allocator, &.{ upstream_root, relative }) catch @panic("OOM");
}

pub fn upstreamPath(b: *std.Build, relative: []const u8) std.Build.LazyPath {
    return b.path(upstreamPathString(b, relative));
}

/// The build's version identity, the one source for version.h, the frontier's
/// version lines and the simulator's --help. VERSION_STRING and VERSION_SHORT
/// follow generated.zig's version.h: a CI build names its tag, a local build
/// its git describe.
pub const VersionStamp = struct {
    /// -Dci-commit-tag, or "" for a local build.
    ci_commit_tag: []const u8,
    /// git describe of the tree: vcs.h's VCS_COMMIT_ID.
    vcs: []const u8,
    /// yyyy-mm-dd, the date VERSION_STRING ends with.
    today: []const u8,
    /// __DATE__'s "Mmm dd yyyy" shape, the day space-padded to two columns.
    compile_date: []const u8,

    /// VERSION_STRING with `space` between its words: upstream joins them with
    /// STD_SPACE_3_PER_EM.
    pub fn string(stamp: VersionStamp, b: *std.Build, space: []const u8) []const u8 {
        if (stamp.ci_commit_tag.len > 0) return b.fmt("v{s}{s}{s}", .{ stamp.ci_commit_tag, space, stamp.today });
        return b.fmt("custom{s}build{s}{s}{s}{s}", .{ space, space, stamp.vcs, space, stamp.today });
    }

    /// VERSION_SHORT: the tag when there is one, else the VCS id.
    pub fn short(stamp: VersionStamp) []const u8 {
        return if (stamp.ci_commit_tag.len > 0) stamp.ci_commit_tag else stamp.vcs;
    }
};

var cached_version_stamp: ?VersionStamp = null;

/// Declares -Dci-commit-tag the one time it is read and stamps the build.
pub fn versionStamp(b: *std.Build) VersionStamp {
    if (cached_version_stamp) |stamp| return stamp;

    const stamp: VersionStamp = .{
        .ci_commit_tag = b.option([]const u8, "ci-commit-tag", "Commit tag for version information") orelse "",
        .vcs = commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown",
        .today = commandOutput(b, &.{ "date", "+%Y-%m-%d" }) orelse "1970-01-01",
        .compile_date = commandOutput(b, &.{ "date", "+%b %e %Y" }) orelse "Jan  1 1970",
    };
    cached_version_stamp = stamp;
    return stamp;
}

var cached_upstream_version1: ?[]const u8 = null;

/// VERSION1 as the pinned defines.h defines it: the release string every
/// version line and the CAT sequence header show. Read at configure time, so a
/// resync that moves it moves every target with it.
pub fn upstreamVersion1(b: *std.Build) []const u8 {
    if (cached_upstream_version1) |version1| return version1;

    const header = "src/c47/defines.h";
    const version1 = defineStringValue(readUpstreamFile(b, header), "VERSION1") orelse
        std.debug.panic("{s} defines no VERSION1 string", .{header});
    cached_upstream_version1 = version1;
    return version1;
}

/// The string literal a `#define <name> "..."` line gives, or null.
fn defineStringValue(text: []const u8, name: []const u8) ?[]const u8 {
    const value = defineValue(text, name) orelse return null;
    if (value.len == 0 or value[0] != '"') return null;
    const end = std.mem.indexOfScalarPos(u8, value, 1, '"') orelse return null;
    return value[1..end];
}

/// The text after the name of a `#define <name> <value>` line, without a
/// trailing `//` comment, or null.
fn defineValue(text: []const u8, name: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var rest = std.mem.trim(u8, line, " \t\r");
        if (!std.mem.startsWith(u8, rest, "#define")) continue;
        rest = std.mem.trimStart(u8, rest["#define".len..], " \t");
        if (!std.mem.startsWith(u8, rest, name)) continue;
        rest = rest[name.len..];
        if (rest.len == 0 or (rest[0] != ' ' and rest[0] != '\t')) continue;
        if (std.mem.find(u8, rest, "//")) |comment| rest = rest[0..comment];
        return std.mem.trim(u8, rest, " \t");
    }
    return null;
}

/// The value of the `0x` literal `text` starts with, or null.
fn parseHexPrefix(text: []const u8) ?usize {
    if (!std.mem.startsWith(u8, text, "0x")) return null;
    const digits = text[2..];
    const end = std.mem.indexOfNone(u8, digits, "0123456789abcdefABCDEF") orelse digits.len;
    if (end == 0) return null;
    return std.fmt.parseInt(usize, digits[0..end], 16) catch null;
}

/// An imported file's text, read at configure time; a change to the file
/// reconfigures the build.
fn readUpstreamFile(b: *std.Build, relative: []const u8) []const u8 {
    const path = upstreamPathString(b, relative);
    b.dependOnFileContents(upstreamPath(b, relative));
    const full_path = b.root.joinString(b.allocator, path) catch @panic("OOM");
    return std.Io.Dir.cwd().readFileAlloc(b.graph.io, full_path, b.allocator, .limited(4 << 20)) catch |err|
        std.debug.panic("cannot read {s}: {t}", .{ full_path, err });
}

/// Valgrind suppressions for decNumber's word-at-a-time coefficient scans: one
/// `src:` entry per line of decBasic.c and decCommon.c that reads a coefficient
/// four bytes at a time (UBTOUI, ISCOEFFZERO). Those reads run past the last
/// digit into the rounded-up end of decNumber's own buffers, which nothing
/// writes; decBasic.c's comment on them is "tests are safe because acc and coe
/// are rounded up to uInts". The entries come from the source, so a change to
/// decNumber cannot leave one on the wrong line.
pub fn decNumberWordScanSuppressions(b: *std.Build) std.Build.LazyPath {
    var text: std.ArrayList(u8) = .empty;
    for ([_][]const u8{ "decBasic.c", "decCommon.c" }) |name| {
        const source = readUpstreamFile(b, b.fmt("dep/decNumberICU/{s}", .{name}));
        var lines = std.mem.splitScalar(u8, source, '\n');
        var number: usize = 0;
        while (lines.next()) |line| {
            number += 1;
            const scans = std.mem.indexOf(u8, line, "UBTOUI(") != null or std.mem.indexOf(u8, line, "ISCOEFFZERO(") != null;
            if (!scans) continue;
            text.print(b.allocator, "{{\n   decnumber-word-scan-{s}-{d}\n   Memcheck:Cond\n   src:{s}:{d}\n}}\n", .{ name, number, name, number }) catch @panic("OOM");
        }
    }
    return b.addWriteFiles().add("decnumber-word-scans.supp", text.items);
}

/// The hardware an owner object is compiled for. Every board fact an owner's
/// build options carry -- DMCP_BUILD, OLD_HW, HARDWARE_MODEL == HWM_DM42 -- is
/// derived from this value, which the caller sets from the target it builds.
/// An object's name is a label and carries no fact.
pub const Board = enum {
    /// The simulators and every host lane.
    host,
    /// The DM42: the DMCP SDK, OLD_HW, HARDWARE_MODEL == HWM_DM42.
    dmcp,
    /// The DM42n and the DM32: the DMCP5 SDK, NEW_HW.
    dmcp5,

    /// DMCP_BUILD.
    pub fn isDmcp(board: Board) bool {
        return board != .host;
    }

    /// OLD_HW. It is also HARDWARE_MODEL == HWM_DM42: defines.h gives every
    /// DMCP build that does not define NEW_HW the DM42 model.
    pub fn isOldHw(board: Board) bool {
        return board == .dmcp;
    }

    /// The imported directory holding the board's SDK headers.
    pub fn sdkHeaderDir(board: Board) []const u8 {
        return switch (board) {
            .host => unreachable,
            .dmcp => "dep/DMCP_SDK/dmcp",
            .dmcp5 => "dep/DMCP5_SDK/dmcp",
        };
    }
};

/// Whether the board's SDK headers are checked out. They come from git
/// submodules, which a checkout that builds only host targets may skip, so
/// configuring must not need them: without them the board's values read 0 and
/// every firmware link of that board fails with `missingSdkStep`'s message.
pub fn sdkPresent(b: *std.Build, board: Board) bool {
    if (board == .host) return true;
    const path = upstreamPathString(b, b.fmt("{s}/lft_ifc.h", .{board.sdkHeaderDir()}));
    const full_path = b.root.joinString(b.allocator, path) catch @panic("OOM");
    std.Io.Dir.cwd().access(b.graph.io, full_path, .{}) catch return false;
    return true;
}

/// A step that fails a firmware build of `board` whose SDK is not checked out.
pub fn missingSdkStep(b: *std.Build, board: Board) *std.Build.Step {
    return &b.addFail(b.fmt(
        "the {t} SDK headers are missing ({s}); run `git submodule update --init`",
        .{ board, upstreamPathString(b, board.sdkHeaderDir()) },
    )).step;
}

/// LIBRARY_FN_BASE as the board's SDK defines it in lft_ifc.h: the ROM function
/// table every DMCP library call goes through. 0 on host, which has none.
pub fn libraryFnBase(b: *std.Build, board: Board) usize {
    if (board == .host or !sdkPresent(b, board)) return 0;
    const header = b.fmt("{s}/lft_ifc.h", .{board.sdkHeaderDir()});
    const value = defineValue(readUpstreamFile(b, header), "LIBRARY_FN_BASE") orelse
        std.debug.panic("{s} defines no LIBRARY_FN_BASE", .{header});
    return parseHexPrefix(value) orelse
        std.debug.panic("{s}: LIBRARY_FN_BASE is not an address: {s}", .{ header, value });
}

/// The address dmcp.h's `sdb` macro casts to the board's system data block. 0 on
/// host, which has none.
pub fn systemDataBlockBase(b: *std.Build, board: Board) usize {
    if (board == .host or !sdkPresent(b, board)) return 0;
    const header = b.fmt("{s}/dmcp.h", .{board.sdkHeaderDir()});
    const value = defineValue(readUpstreamFile(b, header), "sdb") orelse
        std.debug.panic("{s} defines no sdb", .{header});
    const address = std.mem.find(u8, value, "0x") orelse
        std.debug.panic("{s}: sdb names no address: {s}", .{ header, value });
    return parseHexPrefix(value[address..]) orelse
        std.debug.panic("{s}: sdb names no address: {s}", .{ header, value });
}

/// RAM_SIZE_IN_BLOCKS as the pinned defines.h selects it: the OLD_HW count on
/// the DM42 and the NEW_HW count everywhere else, host included.
pub fn ramSizeInBlocks(b: *std.Build, board: Board) u16 {
    const header = "src/c47/defines.h";
    const name = if (board.isOldHw()) "RAM_SIZE_IN_BLOCKS_OLD_HW" else "RAM_SIZE_IN_BLOCKS_NEW_HW";
    const value = defineValue(readUpstreamFile(b, header), name) orelse
        std.debug.panic("{s} defines no {s}", .{ header, name });
    const digits = std.mem.trim(u8, value, "() \t");
    const end = std.mem.indexOfNone(u8, digits, "0123456789") orelse digits.len;
    return std.fmt.parseInt(u16, digits[0..end], 10) catch
        std.debug.panic("{s}: {s} is not a block count: {s}", .{ header, name, value });
}

/// The DMCP ROM shim (src/core/hal/dmcp_rom.zig), a registered module several
/// owners import, with the board's ROM table and system data block addresses.
pub fn addDmcpRomModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    board: Board,
) *std.Build.Module {
    const module = b.createModule(.{
        .root_source_file = b.path("src/core/hal/dmcp_rom.zig"),
        .target = target,
        .optimize = optimize,
    });
    const options = b.addOptions();
    options.addOption(usize, "library_fn_base", libraryFnBase(b, board));
    options.addOption(usize, "sdb_base", systemDataBlockBase(b, board));
    module.addOptions("dmcp_rom_build_options", options);
    return module;
}

/// The kind of executable an owner object is linked into, for the facts that
/// differ between executables built for one target. Like the board, it is set
/// by the caller and never read off the object's name.
pub const Linkage = enum {
    /// A simulator, a firmware image, or a lane that links the owner as they do.
    product,
    /// An executable whose C half is compiled with -DTESTSUITE_BUILD: the
    /// testSuite, its sanitizer lane and the full-core harnesses.
    testsuite,
    /// A unit parity lane, which links a fake runtime in place of the core.
    fake_harness,
};

/// EXTRA_INFO_ON_CALC_ERROR as defines.h resolves it: 1, forced to 0 for
/// DMCP_BUILD and again for TESTSUITE_BUILD.
pub fn extraInfoOnCalcError(board: Board, linkage: Linkage) bool {
    return !board.isDmcp() and linkage != .testsuite;
}

pub fn addBashCommand(b: *std.Build, script: []const u8) *std.Build.Step.Run {
    return addBashCommandFmt(b, "{s}", .{script});
}

pub fn addBashCommandFmt(b: *std.Build, comptime fmt: []const u8, args: anytype) *std.Build.Step.Run {
    const script = b.allocator.print(fmt, args) catch @panic("OOM");
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

/// `link_libc` for a Zig object that a C-rooted executable links. Every hosted
/// executable in this build links libc, so std inside the object must be compiled
/// against it too: built without libc, std on Linux reads the auxiliary vector and
/// static TLS from state that only Zig's own startup code fills in, and the link
/// fails on the missing `__zig_elf_*` symbols. Firmware objects are freestanding
/// and stay unset.
pub fn objectLinkLibc(target: std.Build.ResolvedTarget) ?bool {
    return if (target.result.os.tag == .freestanding) null else true;
}

/// Translates a C root header with the official translate-c package. The
/// translator is a host tool, so it is built for the same host target as the
/// generators that consume its output.
pub fn addTranslator(b: *std.Build, options: Translator.Options) Translator {
    const translate_c = b.dependency("translate_c", .{
        .target = resolveBuildHostTarget(b),
    });
    return .init(translate_c, options);
}

/// Lists the `.c` files under `root_path`, relative to it. Each directory the walk
/// reads is declared to the configure cache, which tracks one directory's entries
/// and not its subdirectories, so adding, removing or renaming a file anywhere in
/// the tree makes the next `zig build` configure again.
pub fn collectRelativeCFiles(b: *std.Build, root_path: []const u8) ![][]const u8 {
    var files = try std.ArrayList([]const u8).initCapacity(b.allocator, 0);
    errdefer files.deinit(b.allocator);
    var dir = try std.Io.Dir.cwd().openDir(b.graph.io, root_path, .{ .iterate = true });
    defer dir.close(b.graph.io);
    b.dependOnDirectoryContents(b.path(root_path));

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind == .directory) {
            b.dependOnDirectoryContents(b.path(b.pathJoin(&.{ root_path, entry.path })));
            continue;
        }
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".c")) continue;
        if (std.mem.eql(u8, entry.path, "reservedRegisterLookupGenerator.c")) continue;

        const relative_path = try b.allocator.dupe(u8, entry.path);
        if (std.Io.Dir.path.sep != '/') {
            for (relative_path) |*byte| {
                if (byte.* == std.Io.Dir.path.sep) byte.* = '/';
            }
        }

        try files.append(b.allocator, relative_path);
    }

    return try files.toOwnedSlice(b.allocator);
}

// The configure cache keys on the command line, the target triple and the build
// sources, so it cannot see what the helpers below read from the host: a
// process's output, an environment variable, whether a file exists. Each one
// poisons the cache, and `zig build` configures again on every run rather than
// reusing an answer the host has since changed, such as `git describe --dirty`.

pub fn commandOutput(b: *std.Build, argv: []const []const u8) ?[]const u8 {
    b.graph.poisonCache();
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
    b.graph.poisonCache();
    const result = std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ "pkg-config", "--exists", package },
        .environ_map = &b.graph.environ_map,
    }) catch return false;

    return switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
}

pub fn hostEnv(b: *std.Build, name: []const u8) ?[]const u8 {
    b.graph.poisonCache();
    return b.graph.environ_map.get(name);
}

pub fn hostFileExists(b: *std.Build, path: []const u8) bool {
    b.graph.poisonCache();
    if (std.Io.Dir.path.isAbsolute(path)) {
        std.Io.Dir.accessAbsolute(b.graph.io, path, .{}) catch return false;
        return true;
    }
    std.Io.Dir.cwd().access(b.graph.io, path, .{}) catch return false;
    return true;
}
