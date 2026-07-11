//! In-place string prepend -- the pure core of frontier_display's strPrepend.
//!
//! strPrepend inserts `prefix` in front of `dest` in place: it grows the buffer
//! by the prefix length, shifts the existing bytes right, and copies the prefix
//! into the front. It is a no-op for an empty or over-long (>20) prefix. Pure in
//! place string edit. Lift it here for native coverage. This module uses Zig
//! many-item pointers rather than C pointers, so it stays out of the
//! idiom-ratchet cptr ceiling.

const std = @import("std");

fn strlen16(p: [*]const u8) i16 {
    var n: i16 = 0;
    while (p[@intCast(n)] != 0) : (n += 1) {}
    return n;
}

/// Prepend `prefix` in front of `dest`, in place.
pub fn strPrepend(dest: [*]u8, prefix: [*]const u8) void {
    const plen: i16 = strlen16(prefix);
    if (plen == 0 or plen > 20) {
        return;
    }
    var dlen: i16 = strlen16(dest);
    var k: i16 = 0;
    while (k < plen) : (k += 1) {
        dest[@intCast(dlen)] = ' ';
        dlen += 1;
    }
    dest[@intCast(dlen)] = 0;

    var jj: i16 = dlen - 1;
    while (jj - plen >= 0) : (jj -= 1) {
        dest[@intCast(jj)] = dest[@intCast(jj - plen)];
    }
    var ii: i16 = plen - 1;
    while (ii >= 0) : (ii -= 1) {
        dest[@intCast(ii)] = prefix[@intCast(ii)];
    }
}

fn prepended(dst_src: []const u8, prefix: [:0]const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..dst_src.len], dst_src);
    S.buf[dst_src.len] = 0;
    strPrepend(&S.buf, prefix.ptr);
    return std.mem.sliceTo(&S.buf, 0);
}

test "strPrepend inserts the prefix in front" {
    try std.testing.expectEqualStrings("XYabc", prepended("abc", "XY"));
    try std.testing.expectEqualStrings("_1", prepended("1", "_"));
}

test "an empty or over-long prefix is a no-op" {
    try std.testing.expectEqualStrings("abc", prepended("abc", ""));
    try std.testing.expectEqualStrings("abc", prepended("abc", "123456789012345678901"));
}
