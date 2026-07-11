//! String append -- the pure core of frontier_char_string's stringAppend.
//!
//! stringAppend copies a NUL-terminated source (including its terminator) onto
//! the destination and returns a pointer to the copied NUL, so the next append
//! continues from there. It is a pure byte copy. Lift it here for native
//! coverage. This module uses Zig many-item pointers rather than C pointers, so
//! it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Copy `source` (including its NUL) to `dest`; return the pointer to the copied
/// NUL.
pub fn stringAppend(dest: [*]u8, source: [*]const u8) [*]u8 {
    var l: usize = 0;
    while (source[l] != 0) : (l += 1) {}
    var i: usize = 0;
    while (i <= l) : (i += 1) {
        dest[i] = source[i];
    }
    return dest + l;
}

test "stringAppend copies including the NUL and points at it" {
    var dst = [_]u8{ 'x', 'y', 0, 0, 0, 0 };
    // Append "z" starting where the first string ends.
    const end = stringAppend(dst[2..].ptr, "z");
    try std.testing.expectEqualStrings("xyz", std.mem.sliceTo(&dst, 0));
    try std.testing.expectEqual(@as(u8, 0), end[0]);
    try std.testing.expectEqual(@as(usize, 3), @intFromPtr(end) - @intFromPtr(&dst));
}
