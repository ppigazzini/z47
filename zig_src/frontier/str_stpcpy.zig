//! stpcpy -- the pure core of frontier_conversion_units' stpcpy.
//!
//! stpcpy copies a NUL-terminated string and returns a pointer to the
//! destination's terminating NUL (so callers can keep appending). It is a pure
//! byte copy. Lift it here for native coverage. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");

/// Copy `src` (including its NUL) to `dst`; return the pointer to the NUL.
pub fn stpcpy(dst: [*]u8, src: [*]const u8) [*]u8 {
    var d = dst;
    var s = src;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}

test "stpcpy copies and returns the terminator" {
    var dst: [16]u8 = undefined;
    const end = stpcpy(&dst, "abc");
    try std.testing.expectEqualStrings("abc", std.mem.sliceTo(&dst, 0));
    try std.testing.expectEqual(@as(usize, 3), @intFromPtr(end) - @intFromPtr(&dst));
    try std.testing.expectEqual(@as(u8, 0), end[0]);
}

test "stpcpy of an empty string points at the start" {
    var dst: [4]u8 = undefined;
    const end = stpcpy(&dst, "");
    try std.testing.expectEqual(@as(usize, 0), @intFromPtr(end) - @intFromPtr(&dst));
}
