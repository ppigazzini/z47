// SPDX-License-Identifier: GPL-3.0-only
//! Pure unit-conversion-name compress/expand codec lifted out of
//! frontier_char_string.zig (src/c47/charString.c). These rewrite a conversion
//! menu name in place between its stored form and its display form: the "100km"
//! binary-prefix run becomes the two-glyph STD_BINARY pair and back, and the
//! "/kWh" <-> "/E" energy-unit shorthands are swapped.
//!
//! Each function first copies the caller buffer into a bounded local scratch
//! (the owner's xcopy(min(50, len+1)) + a hard terminator at index 50), then
//! rewrites the caller buffer from that scratch, so input and output never
//! alias. The only external data -- the two STD_BINARY glyph bytes -- is
//! threaded in as a BinaryGlyphs value, so this module needs none of the shared
//! glyph tables; the owner keeps owning those constants. Index widths (i16) and
//! the scratch bound (51) match the owner byte-for-byte.
//!
//! Conversion names surface only in the units menus, so the upstream testSuite
//! does not drive these; the native tests below are their first coverage.

const std = @import("std");

/// The two-byte STD_BINARY glyphs the compress side emits for a "100k"/"100m"
/// run: the leading "1" glyph and the "0" glyph (written twice).
pub const BinaryGlyphs = struct {
    one: [2]u8,
    zero: [2]u8,
};

/// Length of a NUL-terminated byte buffer (a std-only strlen).
fn byteLen(s: [*]const u8) usize {
    var n: usize = 0;
    while (s[n] != 0) n += 1;
    return n;
}

/// Copy `msg1` into a fresh 51-byte scratch, mirroring the owner's
/// `xcopy(&inStr, msg1, min(50, strlen+1)); inStr[50] = 0;`. Bytes past the copy
/// are only read after the terminator, so leaving them undefined is faithful.
fn loadScratch(msg1: [*]const u8) [51]u8 {
    var scratch: [51]u8 = undefined;
    const n = @min(@as(usize, 50), byteLen(msg1) + 1);
    var k: usize = 0;
    while (k < n) : (k += 1) scratch[k] = msg1[k];
    scratch[50] = 0;
    return scratch;
}

/// expandConversionName: rewrite the stored name to its long display form --
/// "hkm" -> "100km", "/E" -> "/kWh", "E/" -> "kWh/", everything else verbatim.
/// Pure ASCII substitution; no glyph constants involved.
pub fn expandConversionName(msg1: [*]u8) void {
    const inStr = loadScratch(msg1);
    var i: i16 = 0;
    var jj: i16 = 0;
    msg1[0] = 0;
    while (inStr[@intCast(i)] != 0) {
        if ('h' == inStr[@intCast(i)] and 'k' == inStr[@intCast(i + 1)] and 'm' == inStr[@intCast(i + 2)]) {
            msg1[@intCast(jj)] = '1';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = '0';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = '0';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = 'k';
            jj += 1;
            msg1[@intCast(jj)] = 'm';
            jj += 1;
        } else if ('/' == inStr[@intCast(i)] and 'E' == inStr[@intCast(i + 1)]) {
            msg1[@intCast(jj)] = '/';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = 'k';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = 'W';
            jj += 1;
            msg1[@intCast(jj)] = 'h';
            jj += 1;
        } else if ('E' == inStr[@intCast(i)] and '/' == inStr[@intCast(i + 1)]) {
            msg1[@intCast(jj)] = 'k';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = 'W';
            jj += 1;
            i += 1;
            msg1[@intCast(jj)] = 'h';
            jj += 1;
            msg1[@intCast(jj)] = '/';
            jj += 1;
        } else {
            msg1[@intCast(jj)] = inStr[@intCast(i)];
            jj += 1;
            i += 1;
        }
    }
    msg1[@intCast(jj)] = 0;
}

/// compressBinary: when `in` opens with "100k" or "100m", emit the two-glyph
/// STD_BINARY "100" prefix plus the trailing k/m into `out` at `jj` and report
/// true (leaving the caller to advance its input by 4); otherwise leave `out`
/// untouched and report false. Twin of charString.c:166.
fn compressBinary(in: [*]const u8, out: [*]u8, jjPtr: *i16, binary: BinaryGlyphs) bool {
    if ('1' == in[0] and '0' == in[1] and '0' == in[2] and ('k' == in[3] or 'm' == in[3])) {
        var jj = jjPtr.*;
        out[@intCast(jj)] = binary.one[0];
        jj += 1;
        out[@intCast(jj)] = binary.one[1];
        jj += 1;
        out[@intCast(jj)] = binary.zero[0];
        jj += 1;
        out[@intCast(jj)] = binary.zero[1];
        jj += 1;
        out[@intCast(jj)] = binary.zero[0];
        jj += 1;
        out[@intCast(jj)] = binary.zero[1];
        jj += 1;
        out[@intCast(jj)] = in[3]; // k or m for km or mile
        jj += 1;
        jjPtr.* = jj;
        return true;
    }
    return false;
}

/// expandAbbreviations: expand the long form, then fold each "100k"/"100m" run
/// to its STD_BINARY glyphs. Twin of charString.c:183.
pub fn expandAbbreviations(msg1: [*]u8, binary: BinaryGlyphs) void {
    expandConversionName(msg1);
    const inStr = loadScratch(msg1);
    var i: i16 = 0;
    var jj: i16 = 0;
    msg1[0] = 0;
    while (inStr[@intCast(i)] != 0) {
        if (compressBinary(@ptrCast(inStr[@intCast(i)..].ptr), msg1, &jj, binary)) {
            i += 4;
        } else {
            msg1[@intCast(jj)] = inStr[@intCast(i)];
            jj += 1;
            i += 1;
        }
    }
    msg1[@intCast(jj)] = 0;
}

/// compressConversionName: rewrite the display name to its stored form --
/// "100k"/"100m" -> the STD_BINARY glyph run, "/kWh" -> "/E", "kWh/" -> "E/",
/// everything else verbatim.
pub fn compressConversionName(msg1: [*]u8, binary: BinaryGlyphs) void {
    const inStr = loadScratch(msg1);
    var i: i16 = 0;
    var jj: i16 = 0;
    msg1[0] = 0;
    while (inStr[@intCast(i)] != 0) {
        if ('1' == inStr[@intCast(i)] and '0' == inStr[@intCast(i + 1)] and '0' == inStr[@intCast(i + 2)] and ('k' == inStr[@intCast(i + 3)] or 'm' == inStr[@intCast(i + 3)])) {
            msg1[@intCast(jj)] = binary.one[0];
            jj += 1;
            msg1[@intCast(jj)] = binary.one[1];
            jj += 1;
            msg1[@intCast(jj)] = binary.zero[0];
            jj += 1;
            msg1[@intCast(jj)] = binary.zero[1];
            jj += 1;
            msg1[@intCast(jj)] = binary.zero[0];
            jj += 1;
            msg1[@intCast(jj)] = binary.zero[1];
            jj += 1;
            msg1[@intCast(jj)] = inStr[@intCast(i + 3)];
            jj += 1;
            i += 4;
        } else if ('/' == inStr[@intCast(i)] and 'k' == inStr[@intCast(i + 1)] and 'W' == inStr[@intCast(i + 2)] and 'h' == inStr[@intCast(i + 3)]) {
            msg1[@intCast(jj)] = '/';
            jj += 1;
            msg1[@intCast(jj)] = 'E';
            jj += 1;
            i += 4;
        } else if ('k' == inStr[@intCast(i)] and 'W' == inStr[@intCast(i + 1)] and 'h' == inStr[@intCast(i + 2)] and '/' == inStr[@intCast(i + 3)]) {
            msg1[@intCast(jj)] = 'E';
            jj += 1;
            msg1[@intCast(jj)] = '/';
            jj += 1;
            i += 4;
        } else {
            msg1[@intCast(jj)] = inStr[@intCast(i)];
            jj += 1;
            i += 1;
        }
    }
    msg1[@intCast(jj)] = 0;
}

const testing = std.testing;

// The owner's frontier_char_string.zig STD_BINARY glyphs, verbatim.
const owner_binary = BinaryGlyphs{
    .one = .{ 0xa0, 0x27 },
    .zero = .{ 0xa2, 0x0e },
};

/// Run one in-place codec call on a NUL-terminated copy of `in`, sized to hold
/// the widest expansion, and return the sliced result.
fn runExpand(comptime in: []const u8) [64]u8 {
    var buf: [64]u8 = undefined;
    for (in, 0..) |c, k| buf[k] = c;
    buf[in.len] = 0;
    expandConversionName(&buf);
    return buf;
}

test "expandConversionName expands hkm, /E and E/" {
    var a = runExpand("hkm");
    try testing.expectEqualStrings("100km", std.mem.sliceTo(&a, 0));
    var b = runExpand("a/Eb");
    try testing.expectEqualStrings("a/kWhb", std.mem.sliceTo(&b, 0));
    var c = runExpand("E/");
    try testing.expectEqualStrings("kWh/", std.mem.sliceTo(&c, 0));
}

test "expandConversionName leaves an unrelated name unchanged" {
    var a = runExpand("km/h");
    try testing.expectEqualStrings("km/h", std.mem.sliceTo(&a, 0));
}

test "compressConversionName folds 100k/100m and the kWh shorthands" {
    var buf: [64]u8 = undefined;
    const src = "100km";
    for (src, 0..) |c, k| buf[k] = c;
    buf[src.len] = 0;
    compressConversionName(&buf, owner_binary);
    // "100k" -> one,zero,zero glyph run + 'k'; trailing 'm' verbatim.
    const expected = [_]u8{ 0xa0, 0x27, 0xa2, 0x0e, 0xa2, 0x0e, 'k', 'm' };
    try testing.expectEqualSlices(u8, &expected, std.mem.sliceTo(&buf, 0));
}

test "compressConversionName swaps /kWh and kWh/" {
    var buf: [64]u8 = undefined;
    const src = "/kWh";
    for (src, 0..) |c, k| buf[k] = c;
    buf[src.len] = 0;
    compressConversionName(&buf, owner_binary);
    try testing.expectEqualStrings("/E", std.mem.sliceTo(&buf, 0));

    var buf2: [64]u8 = undefined;
    const src2 = "kWh/";
    for (src2, 0..) |c, k| buf2[k] = c;
    buf2[src2.len] = 0;
    compressConversionName(&buf2, owner_binary);
    try testing.expectEqualStrings("E/", std.mem.sliceTo(&buf2, 0));
}

test "expandAbbreviations expands then folds the binary run" {
    var buf: [64]u8 = undefined;
    const src = "hkm";
    for (src, 0..) |c, k| buf[k] = c;
    buf[src.len] = 0;
    // "hkm" -> "100km" (expand) -> one,zero,zero,'k' + 'm' (fold).
    expandAbbreviations(&buf, owner_binary);
    const expected = [_]u8{ 0xa0, 0x27, 0xa2, 0x0e, 0xa2, 0x0e, 'k', 'm' };
    try testing.expectEqualSlices(u8, &expected, std.mem.sliceTo(&buf, 0));
}

test "compress then expand round-trips the kWh shorthand" {
    var buf: [64]u8 = undefined;
    const src = "kWh/s";
    for (src, 0..) |c, k| buf[k] = c;
    buf[src.len] = 0;
    compressConversionName(&buf, owner_binary); // "kWh/" -> "E/", trailing 's'
    try testing.expectEqualStrings("E/s", std.mem.sliceTo(&buf, 0));
    expandConversionName(&buf); // "E/" -> "kWh/"
    try testing.expectEqualStrings("kWh/s", std.mem.sliceTo(&buf, 0));
}
