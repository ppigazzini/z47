// SPDX-License-Identifier: GPL-3.0-only
//
// Format-equivalence oracle (REPORT-23 / MILESTONES-4 M24).
//
// The port formats display/label/error strings with C `sprintf`/`snprintf` for
// byte-identical output (the LCD + error-hint text the testSuite parity checks).
// Migrating a site to `std.fmt` is a byte-level parity risk unless the exact
// Zig format string is PROVEN to reproduce libc's bytes for that conversion over
// the value range the site actually uses.
//
// This harness is that proof. For every entry in TABLE it drives a fuzz matrix
// of values through BOTH libc `snprintf` (the ground truth, linked here) and the
// candidate `std.fmt.bufPrint` translation, and asserts the bytes are identical.
// A migration may only adopt a (C spec -> Zig fmt) pair that is GREEN here; a
// pair that mismatches (e.g. `%04d` vs `{d:0>4}` on negatives -- C sign-then-pad
// vs Zig fill-then-sign) is reported and MUST NOT be applied over that range.
//
// Run: `zig build format_parity`. Exit 1 on any mismatch.

const std = @import("std");
const float_format = @import("float_format");

extern fn snprintf(buf: [*]u8, size: usize, fmt: [*:0]const u8, ...) c_int;

fn cFmt(buf: []u8, comptime cfmt: [:0]const u8, arg: anytype) []u8 {
    const n = snprintf(buf.ptr, buf.len, cfmt.ptr, arg);
    return buf[0..@intCast(n)];
}

/// libc `%.*e` (runtime precision) -- the ground truth for the float formatter.
fn cFmtFloat(buf: []u8, precision: c_int, value: f64) []u8 {
    const n = snprintf(buf.ptr, buf.len, "%.*e", precision, value);
    return buf[0..@intCast(n)];
}

/// libc `%.*f` (runtime precision) -- the ground truth for the fixed formatter.
fn cFmtFixed(buf: []u8, precision: c_int, value: f64) []u8 {
    const n = snprintf(buf.ptr, buf.len, "%.*f", precision, value);
    return buf[0..@intCast(n)];
}

var fail_count: usize = 0;
var check_count: usize = 0;

fn expectEqualStr(comptime label: []const u8, comptime cspec: []const u8, comptime zfmt: []const u8, a: []const u8, b: []const u8, note: []const u8) void {
    check_count += 1;
    if (!std.mem.eql(u8, a, b)) {
        fail_count += 1;
        std.debug.print("  MISMATCH {s}: C `{s}`=\"{s}\"  Zig `{s}`=\"{s}\"  ({s})\n", .{ label, cspec, a, zfmt, b, note });
    }
}

/// Prove a signed-decimal translation over a value slice.
fn proveSignedDecimal(
    comptime label: []const u8,
    comptime cspec: [:0]const u8,
    comptime zfmt: []const u8,
    values: []const i64,
) void {
    var cbuf: [64]u8 = undefined;
    var zbuf: [64]u8 = undefined;
    for (values) |v| {
        const c = cFmt(&cbuf, cspec, @as(c_int, @intCast(v)));
        const z = std.fmt.bufPrint(&zbuf, zfmt, .{v}) catch unreachable;
        expectEqualStr(label, cspec, zfmt, c, z, "signed");
    }
}

/// Prove that a C `%0Nd` on a NON-NEGATIVE value equals the Zig zero-pad applied
/// to the value cast to unsigned (the safe migration -- avoids Zig's signed
/// sign-space `+`). C `%0Nd` == `%0Nu` for non-negatives, so libc via `%0Nd` is
/// still the ground truth.
fn proveNonNegZeroPad(
    comptime label: []const u8,
    comptime cspec: [:0]const u8,
    comptime zfmt: []const u8,
    values: []const i64,
) void {
    var cbuf: [64]u8 = undefined;
    var zbuf: [64]u8 = undefined;
    for (values) |v| {
        const c = cFmt(&cbuf, cspec, @as(c_int, @intCast(v)));
        const z = std.fmt.bufPrint(&zbuf, zfmt, .{@as(u64, @intCast(v))}) catch unreachable;
        expectEqualStr(label, cspec, zfmt, c, z, "nonneg->unsigned");
    }
}

/// Non-negative signed with a SPACE min-width, migrated via the unsigned cast.
fn proveNonNegSpacePad(
    comptime label: []const u8,
    comptime cspec: [:0]const u8,
    comptime zfmt: []const u8,
    values: []const i64,
) void {
    var cbuf: [64]u8 = undefined;
    var zbuf: [64]u8 = undefined;
    for (values) |v| {
        const c = cFmt(&cbuf, cspec, @as(c_int, @intCast(v)));
        const z = std.fmt.bufPrint(&zbuf, zfmt, .{@as(u64, @intCast(v))}) catch unreachable;
        expectEqualStr(label, cspec, zfmt, c, z, "nonneg-space->unsigned");
    }
}

/// Prove an unsigned-decimal / hex translation over a value slice.
fn proveUnsigned(
    comptime label: []const u8,
    comptime cspec: [:0]const u8,
    comptime zfmt: []const u8,
    values: []const u64,
) void {
    var cbuf: [64]u8 = undefined;
    var zbuf: [64]u8 = undefined;
    for (values) |v| {
        const c = cFmt(&cbuf, cspec, @as(c_uint, @intCast(v)));
        const z = std.fmt.bufPrint(&zbuf, zfmt, .{v}) catch unreachable;
        expectEqualStr(label, cspec, zfmt, c, z, "unsigned");
    }
}

pub fn main() !void {
    std.debug.print("format-equivalence oracle (M24): proving sprintf <-> std.fmt byte-equality\n", .{});

    // Value matrices: include negatives + boundaries so a bad translation cannot
    // hide (that is the whole point -- the oracle must catch %04d/{d:0>4} etc.).
    const signed_all = [_]i64{ 0, 1, -1, 5, -5, 9, 10, 42, -42, 99, 100, 999, 1000, 9999, 12345, -12345, 32767, -32768, 2147483647, -2147483648 };
    const signed_nonneg = [_]i64{ 0, 1, 5, 9, 10, 42, 99, 100, 999, 1000, 9999, 12345, 65535, 2147483647 };
    const unsigned_all = [_]u64{ 0, 1, 5, 9, 10, 42, 99, 100, 255, 256, 999, 1000, 4095, 4096, 9999, 65535, 65536, 1000000, 4294967295 };

    // ---- Plain decimal ----
    proveSignedDecimal("d", "%d", "{d}", &signed_all);
    proveSignedDecimal("i", "%i", "{d}", &signed_all);
    proveUnsigned("u", "%u", "{d}", &unsigned_all);

    // ---- Zero-padded unsigned (no sign -> C and Zig agree) ----
    proveUnsigned("02u", "%02u", "{d:0>2}", &unsigned_all);
    proveUnsigned("03u", "%03u", "{d:0>3}", &unsigned_all);
    proveUnsigned("04u", "%04u", "{d:0>4}", &unsigned_all);

    // ---- Zero-padded signed: Zig `{d:0>N}` on a SIGNED value reserves sign
    //      space and emits `+`, so it does NOT match C `%0Nd`. The SAFE, proven
    //      migration for a NON-NEGATIVE `%0Nd` site is to format the value cast
    //      to UNSIGNED (`{d:0>N}` on the u-cast) -- identical bytes to `%0Nd`
    //      because C `%0Nd` == `%0Nu` for non-negatives. That is exactly what the
    //      call-site migration writes, so that is what we prove here. ----
    proveNonNegZeroPad("02d(nonneg->u)", "%02d", "{d:0>2}", &signed_nonneg);
    proveNonNegZeroPad("03d(nonneg->u)", "%03d", "{d:0>3}", &signed_nonneg);
    proveNonNegZeroPad("04d(nonneg->u)", "%04d", "{d:0>4}", &signed_nonneg);

    // ---- Space-padded (min-width) unsigned: C `%Nu` right-justifies with
    //      spaces. Zig `{d: >N}` = fill ' ', align right, width N. ----
    proveUnsigned("2u", "%2u", "{d: >2}", &unsigned_all);
    proveUnsigned("3u", "%3u", "{d: >3}", &unsigned_all);
    proveUnsigned("4u", "%4u", "{d: >4}", &unsigned_all);
    proveUnsigned("10u", "%10u", "{d: >10}", &unsigned_all);

    // ---- Space-padded signed: proven for NON-NEGATIVE only (Zig reserves sign
    //      space -> `+`; the oracle's negative guard below shows why). The safe
    //      migration formats the non-negative value as unsigned. ----
    proveNonNegSpacePad("2d(nonneg->u)", "%2d", "{d: >2}", &signed_nonneg);
    proveNonNegSpacePad("3d(nonneg->u)", "%3d", "{d: >3}", &signed_nonneg);

    // ---- Hex (lower/upper), zero-padded ----
    proveUnsigned("x", "%x", "{x}", &unsigned_all);
    proveUnsigned("02x", "%02x", "{x:0>2}", &unsigned_all);
    proveUnsigned("04x", "%04x", "{x:0>4}", &unsigned_all);
    proveUnsigned("05x", "%05x", "{x:0>5}", &unsigned_all);
    proveUnsigned("08x", "%08x", "{x:0>8}", &unsigned_all);
    proveUnsigned("X", "%X", "{X}", &unsigned_all);
    proveUnsigned("02X", "%02X", "{X:0>2}", &unsigned_all);
    proveUnsigned("04X", "%04X", "{X:0>4}", &unsigned_all);

    // ---- Character ----
    {
        var cbuf: [8]u8 = undefined;
        var zbuf: [8]u8 = undefined;
        var ch: u8 = 32;
        while (ch < 127) : (ch += 1) {
            const c = cFmt(&cbuf, "%c", @as(c_int, ch));
            const z = std.fmt.bufPrint(&zbuf, "{c}", .{ch}) catch unreachable;
            expectEqualStr("c", "%c", "{c}", c, z, "char");
        }
    }

    // ---- String, incl. width-padded (right-justified) ----
    {
        var cbuf: [64]u8 = undefined;
        var zbuf: [64]u8 = undefined;
        const samples = [_][:0]const u8{ "", "A", "abc", "hello", "0.0", "PI" };
        for (samples) |s| {
            const c = cFmt(&cbuf, "%s", s.ptr);
            const z = std.fmt.bufPrint(&zbuf, "{s}", .{s}) catch unreachable;
            expectEqualStr("s", "%s", "{s}", c, z, "string");
        }
        // width-padded string: C `%8s` right-justifies with spaces.
        for (samples) |s| {
            const c = cFmt(&cbuf, "%8s", s.ptr);
            const z = std.fmt.bufPrint(&zbuf, "{s: >8}", .{s}) catch unreachable;
            expectEqualStr("8s", "%8s", "{s: >8}", c, z, "string-width");
        }
    }

    // ---- Negative-demonstration: %04d over negatives is NOT equal to
    //      {d:0>4}. We assert the MISMATCH exists so the harness documents the
    //      guard rail rather than silently trusting the pair. ----
    {
        var cbuf: [64]u8 = undefined;
        var zbuf: [64]u8 = undefined;
        const c = cFmt(&cbuf, "%04d", @as(c_int, -42));
        const z = std.fmt.bufPrint(&zbuf, "{d:0>4}", .{@as(i64, -42)}) catch unreachable;
        if (std.mem.eql(u8, c, z)) {
            std.debug.print("  UNEXPECTED: %04d and {{d:0>4}} agree on -42 (\"{s}\"); tighten the guard\n", .{c});
            fail_count += 1;
        } else {
            std.debug.print("  guard confirmed: %04d(-42)=\"{s}\" != {{d:0>4}}=\"{s}\" -> signed zero-pad stays sprintf/non-negative-only\n", .{ c, z });
        }
        check_count += 1;
    }

    // ---- Float guard-rail: C printf %e and Zig std.fmt {e} are NOT byte-equal
    //      (different dtoa: C emits the exact decimal expansion with round-half-
    //      to-even and a signed >=2-digit exponent; Zig emits the shortest round-
    //      trip mantissa zero-padded, with a bare exponent). Asserted, not
    //      assumed, so std.fmt is provably NOT a valid float translation. ----
    {
        var cbuf: [80]u8 = undefined;
        var zbuf: [80]u8 = undefined;
        const c = cFmt(&cbuf, "%.16e", @as(f64, -3.14159));
        const z = std.fmt.bufPrint(&zbuf, "{e:.16}", .{@as(f64, -3.14159)}) catch unreachable;
        if (std.mem.eql(u8, c, z)) {
            std.debug.print("  UNEXPECTED: C %.16e and Zig {{e:.16}} now agree (\"{s}\") -- revisit float path\n", .{c});
            fail_count += 1;
        } else {
            std.debug.print("  guard confirmed: C %.16e=\"{s}\" != Zig {{e:.16}}=\"{s}\" -> std.fmt is not the float path\n", .{ c, z });
        }
        check_count += 1;
    }

    // ---- Float SOLUTION: abi.fmtExpBuf (abi/float_format.zig) IS the byte-exact
    //      C `%.Pe` reproduction (big-int exact decimal, round-half-to-even). It
    //      is what the migrated %.1e/%.16e/%.20e display/CSV/backup sites call.
    //      Prove it byte-identical to libc `%.*e` over a fuzz matrix: the exact
    //      precisions the sites use (1, 16, 20) plus 0/2/6, across edge values
    //      (0, +-0, subnormals, floatMin/TrueMin/Max, the 0.1/0.2/0.3 hard cases)
    //      and 4000 deterministic random f64 bit patterns per precision. ----
    {
        var cbuf: [128]u8 = undefined;
        var zbuf: [128]u8 = undefined;
        const precs = [_]usize{ 1, 16, 20, 0, 2, 6 };
        const edges = [_]f64{
            0.0,                          -0.0,
            1.0,                          -1.0,
            0.1,                          0.2,
            0.3,                          3.14159,
            1e-34,                        9.999999e-35,
            2.5e100,                      6.022e23,
            1234567890123.456,            std.math.floatMin(f64),
            std.math.floatTrueMin(f64),   std.math.floatMax(f64),
            1.0 / 3.0,                    -7.77e-12,
            9.999999999999999e99,
        };
        var prng = std.Random.DefaultPrng.init(0xC47F10A7);
        const rnd = prng.random();
        for (precs) |p| {
            for (edges) |v| {
                const c = cFmtFloat(&cbuf, @intCast(p), v);
                const z = float_format.fmtExpBuf(&zbuf, p, v);
                expectEqualStr("exp-edge", "%.*e", "fmtExpBuf", c, z, "float-exact");
            }
            var i: usize = 0;
            while (i < 4000) : (i += 1) {
                const v: f64 = @bitCast(rnd.int(u64));
                if (std.math.isNan(v) or std.math.isInf(v)) continue;
                const c = cFmtFloat(&cbuf, @intCast(p), v);
                const z = float_format.fmtExpBuf(&zbuf, p, v);
                expectEqualStr("exp-rand", "%.*e", "fmtExpBuf", c, z, "float-exact");
            }
        }
    }

    // ---- Fixed-notation float: abi.fmtFixedBuf reproduces C `%.Pf` byte-exact
    //      (the save-file graph_dx/graph_dy `%f` == `%.6f` sites). Fuzz over the
    //      save precision (6) plus 0/2, edges + 4000 random f64 per precision.
    //      Random f64 spans huge magnitudes -> 512B target for the ~309-digit
    //      integer part of floatMax; the save call sites use small plot deltas. ----
    {
        var cbuf: [512]u8 = undefined;
        var zbuf: [512]u8 = undefined;
        const precs = [_]usize{ 6, 0, 2 };
        const edges = [_]f64{
            0.0,             -0.0,
            1.0,             -1.0,
            0.5,             1.5,
            0.001,           0.0000005,
            123.456,         -123.456,
            0.1,             0.2,
            0.3,             1.0 / 3.0,
            2.0 / 3.0,       9999999.9999995,
            std.math.floatMin(f64),
        };
        var prng = std.Random.DefaultPrng.init(0xF13ED0);
        const rnd = prng.random();
        for (precs) |p| {
            for (edges) |v| {
                const c = cFmtFixed(&cbuf, @intCast(p), v);
                const z = float_format.fmtFixedBuf(&zbuf, p, v);
                expectEqualStr("fixed-edge", "%.*f", "fmtFixedBuf", c, z, "float-fixed");
            }
            var i: usize = 0;
            while (i < 4000) : (i += 1) {
                const v: f64 = @bitCast(rnd.int(u64));
                if (std.math.isNan(v) or std.math.isInf(v)) continue;
                const c = cFmtFixed(&cbuf, @intCast(p), v);
                const z = float_format.fmtFixedBuf(&zbuf, p, v);
                expectEqualStr("fixed-rand", "%.*f", "fmtFixedBuf", c, z, "float-fixed");
            }
        }
    }

    // ---- %g/%G: abi.fmtGBuf reproduces C `%5.G` byte-exact (the softmenus plot-
    //      zoom label -- the sole %g site). It formats POSITIVE finite values
    //      (tmpF in (0,1] at the site). Prove over its constrained range + broad
    //      positive fuzz (30000 random positive f64). ----
    {
        var cbuf: [64]u8 = undefined;
        var zbuf: [64]u8 = undefined;
        const edges = [_]f64{
            1e-34,   9.9e-35, 1.0,    0.9999,
            0.5,     0.1,     0.05,   0.01,
            0.001,   1e-4,    9.9e-5, 1e-5,
            0.123,   0.15,    0.25,   0.35,
            0.55,    0.95,    0.099,  0.15e-30,
        };
        for (edges) |v| {
            const c = cFmt(&cbuf, "%5.G", v);
            const z = float_format.fmtGBuf(&zbuf, 5, 0, true, v);
            expectEqualStr("g-edge", "%5.G", "fmtGBuf", c, z, "float-g");
        }
        var prng = std.Random.DefaultPrng.init(0x6C0DE9);
        const rnd = prng.random();
        var i: usize = 0;
        while (i < 30000) : (i += 1) {
            const v: f64 = @bitCast(rnd.int(u64));
            if (std.math.isNan(v) or std.math.isInf(v) or !(v > 0)) continue;
            const c = cFmt(&cbuf, "%5.G", v);
            const z = float_format.fmtGBuf(&zbuf, 5, 0, true, v);
            expectEqualStr("g-rand", "%5.G", "fmtGBuf", c, z, "float-g");
        }
    }

    std.debug.print("format-equivalence oracle: {d} checks, {d} mismatches\n", .{ check_count, fail_count });
    if (fail_count != 0) {
        std.debug.print("FAIL: {d} proven-unsafe translations\n", .{fail_count});
        std.process.exit(1);
    }
    std.debug.print("PASS: every tabled sprintf<->std.fmt translation is byte-identical over its proven range\n", .{});
}
