// SPDX-License-Identifier: GPL-3.0-only
//
// Pure complex-number text normalization lifted from calc_state_register_codec.zig
// (saveRestoreCalcState.c standardiseComplex): accept any saved/data-file complex
// form -- "(3-i4)", "3-i4", "+3+i4", the bare "i4", or the stock "re im" -- and
// emit the stock "re im" form the restore parser expects.
//
// The C original walks raw C string buffers with strchr/strcpy/xcopy; here it
// reads an unbounded many-item pointer and writes a `[]u8`, formatting with std,
// so the module imports only std and is exercised natively under
// `zig build test:unit`, reachable as abi.complex_text. The state owner keeps its
// C-ABI call sites and delegates.
//
// These restore paths are testSuite-BLIND, so the native byte-pinning tests below
// (expected strings hand-derived from the C algorithm) are their only automated
// coverage; the transcription is verbatim to keep behaviour identical.

const std = @import("std");

fn isSpace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

// bufPrint into dest + NUL terminate, matching abi.fmtCStr's "caller guarantees
// the buffer is big enough" contract (dest is a 200-byte scratch buffer).
fn putCStr(dest: []u8, comptime fmt: []const u8, args: anytype) void {
    const s = std.fmt.bufPrint(dest, fmt, args) catch dest[0..0];
    dest[s.len] = 0;
}

/// Normalize `src` (NUL-terminated) into `dest` as the stock "re im" complex form.
pub const STANDARDISED_COMPLEX_LENGTH = 200; // one size for the work buffer and for every caller's output buffer

pub fn standardiseComplex(src: [*]const u8, dest: []u8) void {
    var work: [STANDARDISED_COMPLEX_LENGTH]u8 = undefined;
    var w: usize = 0;

    // A data file line is up to TMP_STR_LENGTH bytes and lands here unmeasured,
    // while a complex this calculator can hold is far shorter: a real34 carries 34
    // significant digits, so the widest legal element -- both parts signed, with a
    // radix mark and a four digit exponent -- is well under 100 bytes. An element
    // that does not fit is not a number that could be restored, and truncating it
    // would silently change its value, so it is read as zero instead. The 4 covers
    // the "0 +" that the leading 'i' form prepends and the terminator, the widest
    // expansion any branch below performs.
    {
        var n: usize = 0;
        while (src[n] != 0) : (n += 1) {}
        if (n + 4 > work.len) {
            putCStr(dest, "0 0", .{});
            return;
        }
    }

    // isIform: an 'i' anywhere in src marks the "re +iIM" family.
    var isIform = false;
    {
        var i: usize = 0;
        while (src[i] != 0) : (i += 1) {
            if (src[i] == 'i') {
                isIform = true;
                break;
            }
        }
    }

    var s: usize = 0;
    while (src[s] != 0) : (s += 1) {
        const ch = src[s];
        if (ch == '(' or ch == ')') continue;
        if (isIform and isSpace(ch)) continue;
        work[w] = ch;
        w += 1;
    }
    work[w] = 0;

    if (!isIform) {
        var start: usize = 0;
        while (isSpace(work[start])) start += 1;
        while (w > start and isSpace(work[w - 1])) {
            w -= 1;
            work[w] = 0;
        }
        putCStr(dest, "{s}", .{std.mem.sliceTo(work[start..], 0)}); // already stock "re im"
        return;
    }

    var ip: usize = 0;
    while (work[ip] != 'i') : (ip += 1) {} // guaranteed present (isIform)
    if (ip == 0) {
        putCStr(dest, "0 +{s}", .{std.mem.sliceTo(work[1..], 0)}); // leading 'i' (e.g. "i4" == 0+i4)
        return;
    }
    var imSign: u8 = work[ip - 1]; // the sign sits right before 'i'
    var realLen: usize = ip - 1;
    if (imSign != '+' and imSign != '-') { // malformed: treat that char as real, assume '+'
        imSign = '+';
        realLen = ip;
    }
    var realStr: [STANDARDISED_COMPLEX_LENGTH]u8 = undefined;
    @memcpy(realStr[0..realLen], work[0..realLen]);
    realStr[realLen] = 0;
    putCStr(dest, "{s} {c}{s}", .{
        std.mem.sliceTo(realStr[0..], 0),
        imSign,
        std.mem.sliceTo(work[ip + 1 ..], 0),
    });
}

// ===========================================================================
// Tests -- native byte-pinning (run under `zig build test:unit`). These are the
// ONLY automated coverage of this testSuite-blind normalizer. Expected strings are
// hand-derived from the C algorithm (emit the stock "re im" form).
// ===========================================================================
const testing = std.testing;

fn norm(dest: []u8, src: []const u8) []const u8 {
    standardiseComplex(src.ptr, dest);
    return std.mem.sliceTo(dest, 0);
}

test "standardiseComplex: stock 're im' passes through (whitespace trimmed)" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("3 -4", norm(&dest, "3 -4"));
    try testing.expectEqualStrings("3 -4", norm(&dest, "  3 -4  "));
}

test "standardiseComplex: parenthesised i-form" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("3 -4", norm(&dest, "(3-i4)"));
}

test "standardiseComplex: signed i-form keeps both signs" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("+3 +4", norm(&dest, "+3+i4"));
}

test "standardiseComplex: whitespace inside an i-form is stripped" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("3 -4", norm(&dest, " ( 3 - i4 ) "));
}

test "standardiseComplex: a bare leading 'i' means zero real part" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("0 +4", norm(&dest, "i4"));
}

test "standardiseComplex: a missing sign before 'i' is treated as '+'" {
    var dest: [200]u8 = undefined;
    try testing.expectEqualStrings("3 +4", norm(&dest, "3i4"));
}
