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
