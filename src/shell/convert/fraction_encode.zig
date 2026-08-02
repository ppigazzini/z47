//! Fraction numerator/denominator glyph encoding -- the pure core shared by
//! the display owner's _numerator and _denominator.
//!
//! When a value is displayed as a fraction, the numerator renders as superscript
//! digit glyphs and the denominator as subscript ones, each digit a two-byte
//! glyph inserted at a fixed position (pushing the rest of the string right by
//! two) with a group separator every GROUPWIDTH_LEFT digits. The two owner
//! functions are identical apart from the base glyph (superscript 0 vs subscript
//! 0), so the loop is one pure transform over the value, the destination buffer,
//! and the resolved formatting (group width, separator bytes, base glyph). The
//! owner reads those from globals at the edge.
//!
//! Lifting it here gives the encoder its first native coverage -- the display
//! owner is only reachable through the C oracle. The _numerator / _denominator
//! exports keep their C-ABI signatures and delegate. This module uses Zig
//! many-item pointers rather than C pointers.

const std = @import("std");

// memmove of `n` bytes from dest[insert_at ..] to dest[insert_at + 2 ..],
// matching the owner's xcopy right-shift-by-two (dest > source, so copy
// backwards to survive the overlap).
fn shiftRightTwo(dest: [*]u8, insert_at: i16, n: i16) void {
    const ia: usize = @intCast(insert_at);
    const cnt: usize = @intCast(n);
    std.mem.copyBackwards(u8, dest[ia + 2 .. ia + 2 + cnt], dest[ia .. ia + cnt]);
}

/// Encode `value` into `dest` at `ending_zero.*` as two-byte digit glyphs based
/// on `base_glyph` (superscript 0 for a numerator, subscript 0 for a
/// denominator), most-significant digit last-inserted-first, with a `sep`
/// separator every `group_width` digits. `ending_zero` is advanced past the
/// written glyphs, exactly as _numerator/_denominator do.
pub fn encodeFractionPart(
    value_in: u64,
    dest: [*]u8,
    ending_zero: *i16,
    group_width: i16,
    sep: [*]const u8,
    base_glyph: [*]const u8,
) void {
    var value = value_in;
    var u: i16 = undefined;
    var gap: i16 = -1;
    const insert_at: i16 = ending_zero.*;
    while (true) {
        gap += 1;
        if (gap == group_width) {
            gap = 0;
            ending_zero.* += 1;
            shiftRightTwo(dest, insert_at, ending_zero.* - insert_at);
            ending_zero.* += 1;
            dest[@intCast(insert_at)] = sep[0];
            dest[@intCast(insert_at + 1)] = sep[1];
        }

        u = @intCast(value % 10);
        value /= 10;
        ending_zero.* += 1;
        shiftRightTwo(dest, insert_at, ending_zero.* - insert_at);
        ending_zero.* += 1;

        dest[@intCast(insert_at)] = base_glyph[0];
        dest[@intCast(insert_at + 1)] = base_glyph[1];
        dest[@intCast(insert_at + 1)] +%= @intCast(u);
        if (value == 0) break;
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

const sup0 = "\xa1\x60"; // superscript 0 (numerator base)

fn encode(value: u64, group_width: i16, sep: []const u8) struct { bytes: []const u8, end: i16 } {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    for (&S.buf) |*b| b.* = 0;
    var ending_zero: i16 = 0;
    encodeFractionPart(value, &S.buf, &ending_zero, group_width, sep.ptr, sup0);
    return .{ .bytes = S.buf[0..@intCast(ending_zero)], .end = ending_zero };
}

test "a single digit becomes one superscript glyph" {
    const r = encode(5, 3, "\xaa\xbb");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x65 }, r.bytes);
    try std.testing.expectEqual(@as(i16, 2), r.end);
}

test "multiple digits render most-significant first" {
    // 12 -> superscript '1' then '2', no separator at width 3.
    const r = encode(12, 3, "\xaa\xbb");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x61, 0xa1, 0x62 }, r.bytes);
    try std.testing.expectEqual(@as(i16, 4), r.end);
}

test "a separator is inserted every group_width digits" {
    // width 1 => a separator between every pair of digits: '1' sep '2'.
    const r = encode(12, 1, "\xaa\xbb");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x61, 0xaa, 0xbb, 0xa1, 0x62 }, r.bytes);
    try std.testing.expectEqual(@as(i16, 6), r.end);
}

test "the digit is added to the base glyph's low byte" {
    // 9 -> base low byte 0x60 + 9 = 0x69.
    const r = encode(9, 3, "\xaa\xbb");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x69 }, r.bytes);
}

test "a three-digit value at width 3 gets no interior separator" {
    // 123 -> '1' '2' '3'; the width-3 boundary would fall only after the third.
    const r = encode(123, 3, "\xaa\xbb");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x61, 0xa1, 0x62, 0xa1, 0x63 }, r.bytes);
    try std.testing.expectEqual(@as(i16, 6), r.end);
}
