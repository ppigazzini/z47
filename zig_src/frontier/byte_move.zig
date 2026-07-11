//! Overlap-safe byte move -- the pure core of frontier_char_string's xcopy.
//!
//! xcopy is the codebase's memmove primitive: it copies `n` bytes, choosing a
//! forward or backward direction by comparing the source and destination
//! pointers so an overlapping copy is not corrupted. It is pure over the two
//! buffers. Lift it here for native coverage; the owner keeps the C-ABI export
//! (null/zero-length handling and the returned pointer). This module uses Zig
//! many-item pointers rather than C pointers, so it stays out of the
//! idiom-ratchet cptr ceiling.

const std = @import("std");

/// Copy `n_in` bytes from `source` to `dest`, overlap-safe.
pub fn xcopy(dest: [*]u8, source: [*]const u8, n_in: u32) void {
    var n = n_in;
    if (n == 0) return;
    if (@intFromPtr(source) > @intFromPtr(dest)) {
        var d = dest;
        var s = source;
        while (n != 0) {
            n -%= 1;
            d[0] = s[0];
            d += 1;
            s += 1;
        }
    } else if (@intFromPtr(source) < @intFromPtr(dest)) {
        while (n != 0) {
            n -%= 1;
            dest[n] = source[n];
        }
    }
}

test "a non-overlapping copy moves the bytes" {
    var dst = [_]u8{ 0, 0, 0, 0 };
    const src = [_]u8{ 'a', 'b', 'c', 'd' };
    xcopy(&dst, &src, 4);
    try std.testing.expectEqualSlices(u8, "abcd", &dst);
}

test "an overlapping left shift copies forward" {
    var buf = [_]u8{ 'A', 'B', 'C', 'D', 'E', 0 };
    xcopy(&buf, buf[1..].ptr, 4); // dest < source
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'B', 'C', 'D', 'E', 'E', 0 }, &buf);
}

test "an overlapping right shift copies backward" {
    var buf = [_]u8{ 'A', 'B', 'C', 'D', 'E', 0, 0 };
    xcopy(buf[2..].ptr, &buf, 3); // dest > source
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'A', 'B', 'A', 'B', 'C', 0, 0 }, &buf);
}

test "a zero-length copy changes nothing" {
    var buf = [_]u8{ 'x', 'y' };
    xcopy(&buf, buf[1..].ptr, 0);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'x', 'y' }, &buf);
}
