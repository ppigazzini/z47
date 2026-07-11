//! Alpha MID substring extraction -- the pure core of frontier_string_funcs'
//! _alphaMid.
//!
//! ALPHAMID copies `len` glyphs of a string starting at the 1-based glyph index
//! `start`, clamping the window against the string's glyph length and handling
//! two-byte glyphs. The clamp arithmetic and the glyph-walk copy are pure over
//! the source string and a destination buffer; the owner touches state only at
//! the edges (the source register fetch and the REGISTER_X reallocate/copy of
//! the result). Glyph stepping reuses the tested abi.c47_string.nextGlyph so the
//! two-byte handling matches the rest of the string engine exactly.
//!
//! Lifting it here gives ALPHAMID its first native coverage -- the string owner
//! is only reachable through the C oracle. The owner keeps the thin _alphaMid
//! shim that resolves the glyph length, calls this core into the scratch buffer,
//! and writes the result into REGISTER_X. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");
const abi = @import("abi");
const c47_string = abi.c47_string;

/// Copy `len_arg` glyphs of `src` starting at the 1-based glyph index
/// `start_arg` into `dest` (NUL-terminated), returning the number of bytes
/// written (excluding the NUL). `glyph_length` is the source glyph count.
///
/// Byte-for-byte equivalent to _alphaMid: `start` of 0, a `start` past the end,
/// and a window running off the end all clamp exactly as the original does.
pub fn alphaMid(dest: [*]u8, src: [*]const u8, start_arg: i32, len_arg: i32, glyph_length: i32) usize {
    var start: i32 = start_arg;
    var len: i32 = len_arg;
    if (start == 0) {
        len = 0;
    }
    if (start > glyph_length) {
        start = glyph_length;
        len = 0;
    } else if (start + len - 1 > glyph_length) {
        len = glyph_length - start + 1;
    }

    var pos1: i16 = 0;
    if (start > 1) {
        var i: i32 = 1;
        while (i < start) : (i += 1) {
            pos1 = c47_string.nextGlyph(src, pos1);
        }
    }

    var pos2: i16 = 0;
    var i: i32 = 0;
    while (i < len) : (i += 1) {
        if ((src[@intCast(pos1)] & 0x80) != 0) {
            dest[@intCast(pos2)] = src[@intCast(pos1)];
            pos2 += 1;
            pos1 += 1;
        }
        dest[@intCast(pos2)] = src[@intCast(pos1)];
        pos2 += 1;
        pos1 += 1;
    }
    dest[@intCast(pos2)] = 0;
    return @intCast(pos2);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

fn mid(src: [:0]const u8, start: i32, len: i32, glyph_length: i32) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    const n = alphaMid(&S.buf, src.ptr, start, len, glyph_length);
    return S.buf[0..n];
}

test "a mid window copies the requested glyphs" {
    try std.testing.expectEqualStrings("BC", mid("ABCDE", 2, 2, 5));
    try std.testing.expectEqualStrings("ABCDE", mid("ABCDE", 1, 5, 5));
}

test "a start past the end yields an empty string" {
    try std.testing.expectEqualStrings("", mid("ABC", 5, 2, 3));
}

test "a start of 0 yields an empty string" {
    try std.testing.expectEqualStrings("", mid("ABC", 0, 2, 3));
}

test "a window running off the end is clamped to the remaining glyphs" {
    try std.testing.expectEqualStrings("BC", mid("ABC", 2, 5, 3));
}

test "two-byte glyphs are copied whole" {
    // 'A', a two-byte glyph 0x8142, then 'C' -> 3 glyphs; extract glyph 2.
    const src = [_:0]u8{ 'A', 0x81, 0x42, 'C' };
    const out = mid(&src, 2, 1, 3);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x81, 0x42 }, out);
}
