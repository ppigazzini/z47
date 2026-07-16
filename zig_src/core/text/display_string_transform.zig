// SPDX-License-Identifier: GPL-3.0-only
//! Pure display-string post-processing transforms lifted out of
//! frontier_plotstat.zig (the stat-plot drawing/formatting owner). Each walks a
//! NUL-terminated input buffer and writes a transformed NUL-terminated output
//! buffer, returning the number of bytes written (excluding the terminator).
//!
//! The substitution glyph bytes that the owner reads from module-level glyph
//! constants (STD_SPACE_PUNCTUATION, STD_SUB_E) or derives from the radix-mode
//! item table (radix34MarkChar) are threaded in as VALUE parameters. That keeps
//! this module dependent on std alone -- it never has to duplicate the shared
//! glyph tables -- and lets the owner keep owning those constants at the call
//! site. Behaviour is a verbatim transcription of the owner, so the C-ABI
//! wrappers stay byte-identical; index widths (i8/i32) are preserved exactly as
//! the port had them.
//!
//! These helpers feed graph/plot/softmenu rendering only, so the upstream
//! testSuite never exercises them. The native tests below -- expected bytes
//! hand-derived from the algorithm, not from the port -- are their first
//! automated coverage.

const std = @import("std");

/// Length of a NUL-terminated byte buffer (a std-only strlen).
fn byteLen(s: [*]const u8) usize {
    var n: usize = 0;
    while (s[n] != 0) n += 1;
    return n;
}

/// Overwrite the head of `dst` with `src` plus its NUL terminator (a std-only
/// strcpy). Bytes past `src.len` are left untouched, matching strcpy exactly.
fn setCStr(dst: [*]u8, comptime src: []const u8) void {
    for (src, 0..) |c, i| dst[i] = c;
    dst[src.len] = 0;
}

/// First occurrence of `c` in the NUL-terminated `s`, or null (a std-only
/// strchr, searching only up to the terminator).
fn findChar(s: [*]u8, c: u8) ?[*]u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == c) return p;
    }
    return null;
}

/// Copy `n` bytes from `src` to `dst` low-to-high. Every caller here shifts a
/// tail leftward (dst <= src), so a forward copy is the overlap-safe move --
/// the std-only equivalent of the memmove the owner used.
fn memmoveLeft(dst: [*]u8, src: [*]const u8, n: usize) void {
    var i: usize = 0;
    while (i < n) : (i += 1) dst[i] = src[i];
}

/// radixProcess: copy `in` to `out`, replacing ',' or '.' with `radix_mark`
/// and '#' with ';'. Every input byte yields exactly one output byte, so it is
/// safe to call in place (out and in may alias the same buffer): the write
/// index never outruns the read index. Index width (i8) matches the owner.
pub fn radixProcess(out: [*]u8, in: [*]const u8, radix_mark: u8) usize {
    var ix: i8 = 0;
    var iy: i8 = 0;
    while (in[@intCast(ix)] != 0) {
        if (in[@intCast(ix)] == ',' or in[@intCast(ix)] == '.') {
            out[@intCast(iy)] = radix_mark;
            iy += 1;
        } else if (in[@intCast(ix)] == '#') {
            out[@intCast(iy)] = ';';
            iy += 1;
        } else {
            out[@intCast(iy)] = in[@intCast(ix)];
            iy += 1;
        }
        ix += 1;
    }
    out[@intCast(iy)] = 0;
    return @intCast(iy);
}

/// padEquals: copy `in` to `out`, expanding a '=' to
/// space_punct ++ "=" ++ space_punct and passing high-bit glyph byte-pairs
/// through unchanged. Expands, so `out` must NOT alias `in`. `space_punct` is
/// the owner's 2-byte STD_SPACE_PUNCTUATION glyph.
pub fn padEquals(out: [*]u8, in: [*]const u8, space_punct: [2]u8) usize {
    var ix: i8 = 0;
    var iy: i8 = 0;
    while (in[@intCast(ix)] != 0) {
        if ((in[@intCast(ix)] & 0x80) == 0) {
            if (in[@intCast(ix)] == '=') {
                out[@intCast(iy)] = space_punct[0];
                iy += 1;
                out[@intCast(iy)] = space_punct[1];
                iy += 1;
                out[@intCast(iy)] = '=';
                iy += 1;
                out[@intCast(iy)] = space_punct[0];
                iy += 1;
                out[@intCast(iy)] = space_punct[1];
                iy += 1;
            } else {
                out[@intCast(iy)] = in[@intCast(ix)];
                iy += 1;
            }
        } else {
            out[@intCast(iy)] = in[@intCast(ix)];
            iy += 1;
            if (in[@intCast(ix + 1)] != 0) {
                ix += 1;
                out[@intCast(iy)] = in[@intCast(ix)];
                iy += 1;
            }
        }
        ix += 1;
    }
    out[@intCast(iy)] = 0;
    return @intCast(iy);
}

/// smallE: copy `in` to `out`, replacing an ASCII 'E' with the 2-byte `sub_e`
/// subscript glyph and passing high-bit glyph byte-pairs through unchanged.
/// Expands, so `out` must NOT alias `in`. `sub_e` is the owner's STD_SUB_E.
pub fn smallE(out: [*]u8, in: [*]const u8, sub_e: [2]u8) usize {
    var ix: i8 = 0;
    var iy: i8 = 0;
    while (in[@intCast(ix)] != 0) {
        if ((in[@intCast(ix)] & 0x80) == 0) {
            if (in[@intCast(ix)] == 'E') {
                out[@intCast(iy)] = sub_e[0];
                iy += 1;
                out[@intCast(iy)] = sub_e[1];
                iy += 1;
            } else {
                out[@intCast(iy)] = in[@intCast(ix)];
                iy += 1;
            }
        } else {
            out[@intCast(iy)] = in[@intCast(ix)];
            iy += 1;
            if (in[@intCast(ix + 1)] != 0) {
                ix += 1;
                out[@intCast(iy)] = in[@intCast(ix)];
                iy += 1;
            }
        }
        ix += 1;
    }
    out[@intCast(iy)] = 0;
    return @intCast(iy);
}

/// nanCheck: in place, when a lowercase "nan" run is found from index 2 on,
/// collapse the whole buffer to "(NaN" (when it opens with '(') or ";NaN)"
/// (when it opens with ';', closes with ')', and has bytes on both sides of the
/// run). The scan continues over the now-stale tail exactly as the owner does.
pub fn nanCheck(s: [*]u8) void {
    if (byteLen(s) > 2) {
        var ix: i32 = 2;
        while (s[@intCast(ix)] != 0) : (ix += 1) {
            if (s[@intCast(ix)] == 'n' and s[@intCast(ix - 1)] == 'a' and s[@intCast(ix - 2)] == 'n') {
                if (s[0] == '(' and s[@intCast(ix + 1)] != 0) {
                    setCStr(s, "(NaN");
                } else if (s[0] == ';' and s[byteLen(s) - 1] == ')' and s[@intCast(ix + 1)] != 0 and s[@intCast(ix + 2)] != 0) {
                    setCStr(s, ";NaN)");
                }
            }
        }
    }
}

/// cleanupTrailingZeros: normalise a formatted number in place. When an
/// exponent is present (lowercase 'e' is first upcased to 'E'): drop trailing
/// mantissa zeros between '.' and 'E' (removing the '.' too if every fractional
/// digit was zero), then drop leading zeros from the exponent digits (after an
/// optional sign). When no exponent is present: drop trailing fractional zeros,
/// removing the '.' when the whole fraction was zero. Pointer walks and the
/// left-shifting splices mirror the owner byte-for-byte.
pub fn cleanupTrailingZeros(str: [*]u8) void {
    var e_pos = findChar(str, 'E');
    if (e_pos == null) e_pos = findChar(str, 'e');
    if (e_pos) |e| {
        if (e[0] == 'e') e[0] = 'E';
    }
    if (e_pos) |e| {
        if (findChar(str, '.')) |dp| {
            if (@intFromPtr(dp) < @intFromPtr(e)) {
                var p = e - 1;
                while (@intFromPtr(p) > @intFromPtr(dp) and p[0] == '0') p -= 1;
                if (@intFromPtr(p) == @intFromPtr(dp)) {
                    memmoveLeft(dp, e, byteLen(e) + 1);
                } else {
                    memmoveLeft(p + 1, e, byteLen(e) + 1);
                }
            }
        }
        if (findChar(str, 'E')) |e2| {
            var exp_start = e2 + 1;
            if (exp_start[0] == '+') exp_start += 1;
            if (exp_start[0] == '-') exp_start += 1;
            while (exp_start[0] == '0' and (exp_start + 1)[0] != 0) {
                memmoveLeft(exp_start, exp_start + 1, byteLen(exp_start + 1) + 1);
            }
        }
    } else {
        if (findChar(str, '.')) |dp| {
            const len: i32 = @intCast(byteLen(str));
            var i: i32 = len - 1;
            const dpIdx: i32 = @intCast(@intFromPtr(dp) - @intFromPtr(str));
            while (i > dpIdx and str[@intCast(i)] == '0') {
                str[@intCast(i)] = 0;
                i -= 1;
            }
            if (i == dpIdx) {
                str[@intCast(i)] = 0;
            }
        }
    }
}

/// The two-byte subscript glyphs convertDigits maps to. Grouping them in one
/// struct lets the owner thread its own glyph constants in as a single value,
/// so this module needs none of the shared glyph tables.
pub const SubscriptGlyphs = struct {
    /// Base subscript-zero glyph: '0'..'9' map to sub_0[0], sub_0[1] +% (c-'0').
    sub_0: [2]u8,
    /// Base subscript-a glyph: the letter set maps to sub_a[0], sub_a[1] +% (c-'a').
    sub_a: [2]u8,
    ratio: [2]u8, // ':'
    sub_plus: [2]u8, // '+'
    sub_minus: [2]u8, // '-'
    low_quote: [2]u8, // ','
    oblique3: [2]u8, // '/'
};

/// convertDigits: rewrite selected ASCII characters of `in` to their two-byte
/// subscript glyphs in `out`, copying anything else through as a single byte.
/// Digits and the letter set {t,i,c,k,x,y,a,s} use contiguous-range arithmetic
/// off sub_0 / sub_a; the punctuation glyphs are direct. Index width (u16) and
/// the wrapping arithmetic (+%) match the owner. `out` must NOT alias `in`
/// (glyph output is wider than its input byte).
pub fn convertDigits(out: [*]u8, in: [*]const u8, g: SubscriptGlyphs) void {
    var ii: u16 = 0;
    var oo: u16 = 0;
    out[0] = 0;
    while (in[ii] != 0) {
        const c = in[ii];
        switch (c) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                out[oo] = g.sub_0[0];
                oo +%= 1;
                out[oo] = g.sub_0[1] +% (c -% '0');
                oo +%= 1;
            },
            't', 'i', 'c', 'k', 'x', 'y', 'a', 's' => {
                out[oo] = g.sub_a[0];
                oo +%= 1;
                out[oo] = g.sub_a[1] +% (c -% 'a');
                oo +%= 1;
            },
            ':' => {
                out[oo] = g.ratio[0];
                oo +%= 1;
                out[oo] = g.ratio[1];
                oo +%= 1;
            },
            '+' => {
                out[oo] = g.sub_plus[0];
                oo +%= 1;
                out[oo] = g.sub_plus[1];
                oo +%= 1;
            },
            '-' => {
                out[oo] = g.sub_minus[0];
                oo +%= 1;
                out[oo] = g.sub_minus[1];
                oo +%= 1;
            },
            ',' => {
                out[oo] = g.low_quote[0];
                oo +%= 1;
                out[oo] = g.low_quote[1];
                oo +%= 1;
            },
            '/' => {
                out[oo] = g.oblique3[0];
                oo +%= 1;
                out[oo] = g.oblique3[1];
                oo +%= 1;
            },
            // '.' and everything else fall through to a verbatim single-byte copy.
            else => {
                out[oo] = in[ii];
                oo +%= 1;
            },
        }
        ii +%= 1;
    }
    out[oo] = 0;
}

const testing = std.testing;

test "radixProcess substitutes radix mark and hash, NUL-terminates" {
    var out: [32]u8 = undefined;
    const n = radixProcess(&out, "3,14#5", '.');
    try testing.expectEqual(@as(usize, 6), n);
    try testing.expectEqualStrings("3.14;5", out[0..n]);
    try testing.expectEqual(@as(u8, 0), out[n]);
}

test "radixProcess honours a comma radix mark and leaves other bytes" {
    var out: [32]u8 = undefined;
    const n = radixProcess(&out, "1.2 x", ',');
    try testing.expectEqualStrings("1,2 x", out[0..n]);
}

test "radixProcess is safe in place (out aliases in)" {
    var buf: [8]u8 = undefined;
    const src = "a.b#c";
    @memcpy(buf[0..src.len], src);
    buf[src.len] = 0;
    const n = radixProcess(&buf, &buf, '.');
    try testing.expectEqualStrings("a.b;c", buf[0..n]);
}

test "padEquals expands equals and passes glyph pairs" {
    const space_punct = [2]u8{ 0xa0, 0x08 };
    var out: [64]u8 = undefined;
    const n = padEquals(&out, "x=y", space_punct);
    const expected = [_]u8{ 'x', 0xa0, 0x08, '=', 0xa0, 0x08, 'y' };
    try testing.expectEqual(@as(usize, expected.len), n);
    try testing.expectEqualSlices(u8, &expected, out[0..n]);
    try testing.expectEqual(@as(u8, 0), out[n]);
}

test "padEquals copies a high-bit glyph pair verbatim before an equals" {
    const space_punct = [2]u8{ 0xa0, 0x08 };
    var out: [64]u8 = undefined;
    const in = [_]u8{ 0x80, 0x81, '=', 0 };
    const n = padEquals(&out, &in, space_punct);
    const expected = [_]u8{ 0x80, 0x81, 0xa0, 0x08, '=', 0xa0, 0x08 };
    try testing.expectEqualSlices(u8, &expected, out[0..n]);
}

test "smallE replaces E with the two-byte subscript glyph" {
    const sub_e = [2]u8{ 0xa4, 0xd4 };
    var out: [64]u8 = undefined;
    const n = smallE(&out, "1E3", sub_e);
    const expected = [_]u8{ '1', 0xa4, 0xd4, '3' };
    try testing.expectEqualSlices(u8, &expected, out[0..n]);
}

test "smallE only folds ASCII E, not a high-bit byte that happens to be 0x45" {
    const sub_e = [2]u8{ 0xa4, 0xd4 };
    var out: [64]u8 = undefined;
    // 0xC5 0x45: a glyph pair whose trailing byte is 'E' (0x45) must pass
    // through as data, because the high-bit lead byte takes the glyph branch.
    const in = [_]u8{ 0xc5, 'E', 'E', 0 };
    const n = smallE(&out, &in, sub_e);
    // 0xC5 leads a pair -> copies 0xC5 and the next 'E' verbatim; the final
    // standalone 'E' folds.
    const expected = [_]u8{ 0xc5, 'E', 0xa4, 0xd4 };
    try testing.expectEqualSlices(u8, &expected, out[0..n]);
}

test "nanCheck rewrites a bracketed nan to (NaN" {
    var s = "(3-nan4)".*;
    nanCheck(&s);
    try testing.expectEqualStrings("(NaN", std.mem.sliceTo(&s, 0));
}

test "nanCheck rewrites a semicolon-bracketed nan to ;NaN)" {
    var s = ";nan45)".*;
    nanCheck(&s);
    try testing.expectEqualStrings(";NaN)", std.mem.sliceTo(&s, 0));
}

test "nanCheck leaves a string without a nan run unchanged" {
    var s = "(1.5)".*;
    nanCheck(&s);
    try testing.expectEqualStrings("(1.5)", std.mem.sliceTo(&s, 0));
}

test "nanCheck does not rewrite a bracketed nan with nothing after the run" {
    // s[0]=='(' but s[ix+1]==0 (run is at the very end) -> no rewrite.
    var s = "(nan".*;
    nanCheck(&s);
    try testing.expectEqualStrings("(nan", std.mem.sliceTo(&s, 0));
}

fn cleanupCase(comptime in: []const u8) [in.len + 1]u8 {
    var buf: [in.len + 1]u8 = undefined;
    for (in, 0..) |c, i| buf[i] = c;
    buf[in.len] = 0;
    cleanupTrailingZeros(&buf);
    return buf;
}

test "cleanupTrailingZeros strips fractional zeros without an exponent" {
    var a = cleanupCase("1.2300");
    try testing.expectEqualStrings("1.23", std.mem.sliceTo(&a, 0));
    var b = cleanupCase("5.0");
    try testing.expectEqualStrings("5", std.mem.sliceTo(&b, 0));
    var c = cleanupCase("1.000");
    try testing.expectEqualStrings("1", std.mem.sliceTo(&c, 0));
}

test "cleanupTrailingZeros leaves an integer or a clean fraction alone" {
    var a = cleanupCase("123");
    try testing.expectEqualStrings("123", std.mem.sliceTo(&a, 0));
    var b = cleanupCase("1.23");
    try testing.expectEqualStrings("1.23", std.mem.sliceTo(&b, 0));
}

test "cleanupTrailingZeros strips mantissa zeros before an exponent" {
    var a = cleanupCase("1.2300E5");
    try testing.expectEqualStrings("1.23E5", std.mem.sliceTo(&a, 0));
}

test "cleanupTrailingZeros drops the dot when the whole fraction is zero" {
    var a = cleanupCase("1.000E5");
    try testing.expectEqualStrings("1E5", std.mem.sliceTo(&a, 0));
}

test "cleanupTrailingZeros strips leading exponent zeros after a sign" {
    var a = cleanupCase("1E05");
    try testing.expectEqualStrings("1E5", std.mem.sliceTo(&a, 0));
    var b = cleanupCase("1E-005");
    try testing.expectEqualStrings("1E-5", std.mem.sliceTo(&b, 0));
}

test "cleanupTrailingZeros upcases a lowercase e and then cleans" {
    var a = cleanupCase("1.20e3");
    try testing.expectEqualStrings("1.2E3", std.mem.sliceTo(&a, 0));
}

// The owner's frontier_char_string.zig glyph constants, verbatim.
const owner_glyphs = SubscriptGlyphs{
    .sub_0 = .{ 0xa0, 0x80 },
    .sub_a = .{ 0xa4, 0x9c },
    .ratio = .{ 0xa2, 0x36 },
    .sub_plus = .{ 0xa0, 0x8a },
    .sub_minus = .{ 0xa0, 0x8b },
    .low_quote = .{ 0xa0, 0x1a },
    .oblique3 = .{ 0xa4, 0x25 },
};

test "convertDigits maps digits off the contiguous subscript-zero range" {
    var out: [64]u8 = undefined;
    convertDigits(&out, "123", owner_glyphs);
    // '1'->a0 81, '2'->a0 82, '3'->a0 83.
    const expected = [_]u8{ 0xa0, 0x81, 0xa0, 0x82, 0xa0, 0x83 };
    try testing.expectEqualSlices(u8, &expected, std.mem.sliceTo(&out, 0));
}

test "convertDigits maps the letter set off the contiguous subscript-a range" {
    var out: [64]u8 = undefined;
    convertDigits(&out, "xy", owner_glyphs);
    // 'x'->a4 (9c+23=b3), 'y'->a4 (9c+24=b4).
    const expected = [_]u8{ 0xa4, 0xb3, 0xa4, 0xb4 };
    try testing.expectEqualSlices(u8, &expected, std.mem.sliceTo(&out, 0));
}

test "convertDigits maps the direct punctuation glyphs" {
    var out: [64]u8 = undefined;
    convertDigits(&out, ":+-,/", owner_glyphs);
    const expected = [_]u8{ 0xa2, 0x36, 0xa0, 0x8a, 0xa0, 0x8b, 0xa0, 0x1a, 0xa4, 0x25 };
    try testing.expectEqualSlices(u8, &expected, std.mem.sliceTo(&out, 0));
}

test "convertDigits copies unmapped characters (incl. '.') verbatim" {
    var out: [64]u8 = undefined;
    convertDigits(&out, "P.Q", owner_glyphs);
    try testing.expectEqualStrings("P.Q", std.mem.sliceTo(&out, 0));
}

test "convertDigits produces an empty string for empty input" {
    var out: [4]u8 = undefined;
    convertDigits(&out, "", owner_glyphs);
    try testing.expectEqual(@as(u8, 0), out[0]);
}
