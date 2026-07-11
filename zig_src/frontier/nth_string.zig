//! Packed-string advance -- the pure core of frontier_softmenus' getNthString.
//!
//! Softmenu name data is stored as a run of NUL-terminated strings packed back
//! to back; getNthString advances a pointer past `n` of them. It is a pure
//! pointer walk (a strlen+1 step per string). Lift it here for native coverage
//! -- the softmenu owner is only reachable through the C oracle. This module uses
//! Zig many-item pointers rather than C pointers, so it stays out of the
//! idiom-ratchet cptr ceiling.

const std = @import("std");

fn byteLength(p: [*]const u8) usize {
    var i: usize = 0;
    while (p[i] != 0) : (i += 1) {}
    return i;
}

/// Advance `ptr` past `n` NUL-terminated strings and return the new pointer.
pub fn getNthString(ptr: [*]u8, n: i16) [*]u8 {
    var p = ptr;
    var count = n;
    while (count != 0) {
        p += byteLength(p) + 1;
        count -= 1;
    }
    return p;
}

test "advancing zero strings returns the same pointer" {
    var buf = [_]u8{ 'a', 'b', 0, 'c', 0 };
    try std.testing.expectEqual(@as([*]u8, &buf), getNthString(&buf, 0));
}

test "advancing past packed strings lands on each start" {
    var buf = [_]u8{ 'o', 'n', 'e', 0, 't', 'w', 'o', 0, 0, 'x', 0 };
    // Past "one" -> "two".
    try std.testing.expectEqualStrings("two", std.mem.sliceTo(getNthString(&buf, 1), 0));
    // Past "one","two" -> empty string.
    try std.testing.expectEqualStrings("", std.mem.sliceTo(getNthString(&buf, 2), 0));
    // Past "one","two","" -> "x".
    try std.testing.expectEqualStrings("x", std.mem.sliceTo(getNthString(&buf, 3), 0));
}
