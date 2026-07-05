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

extern fn snprintf(buf: [*]u8, size: usize, fmt: [*:0]const u8, ...) c_int;

fn cFmt(buf: []u8, comptime cfmt: [:0]const u8, arg: anytype) []u8 {
    const n = snprintf(buf.ptr, buf.len, cfmt.ptr, arg);
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

    std.debug.print("format-equivalence oracle: {d} checks, {d} mismatches\n", .{ check_count, fail_count });
    if (fail_count != 0) {
        std.debug.print("FAIL: {d} proven-unsafe translations\n", .{fail_count});
        std.process.exit(1);
    }
    std.debug.print("PASS: every tabled sprintf<->std.fmt translation is byte-identical over its proven range\n", .{});
}
