//! Byte-string substring search -- the pure core of frontier_string_funcs'
//! ALPHAPOS.
//!
//! ALPHAPOS finds the first index at which a target string occurs in a register
//! string (or -1). The naive scan is pure over the two buffers and their lengths.
//! Lift it here for native coverage -- the string owner is only reachable through
//! the C oracle. This module uses Zig many-item pointers rather than C pointers,
//! so it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// The first index of `needle` in `haystack`, or -1 if absent.
pub fn substringPosition(haystack: [*]const u8, hay_len: i16, needle: [*]const u8, needle_len: i16) i16 {
    var i: i16 = 0;
    while (i <= hay_len - needle_len) : (i += 1) {
        var found = true;
        var j: i16 = 0;
        while (j < needle_len) : (j += 1) {
            if (haystack[@intCast(i + j)] != needle[@intCast(j)]) {
                found = false;
                break;
            }
        }
        if (found) return i;
    }
    return -1;
}

fn pos(hay: []const u8, needle: []const u8) i16 {
    return substringPosition(hay.ptr, @intCast(hay.len), needle.ptr, @intCast(needle.len));
}

test "substringPosition finds the first occurrence" {
    try std.testing.expectEqual(@as(i16, 2), pos("hello", "ll"));
    try std.testing.expectEqual(@as(i16, 0), pos("hello", "hello"));
    try std.testing.expectEqual(@as(i16, 3), pos("ababc", "bc"));
}

test "an absent needle returns -1" {
    try std.testing.expectEqual(@as(i16, -1), pos("hello", "x"));
    try std.testing.expectEqual(@as(i16, -1), pos("ab", "abc"));
}
