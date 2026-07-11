//! Leading-space trim -- the pure core of frontier_string_funcs' trimLeadingSpace.
//!
//! Some display-formatting paths drop a single leading space from a string in
//! place by shifting the remainder (including the terminator) left one byte. It
//! is a pure byte operation. Lift it here for native coverage -- the string owner
//! is only reachable through the C oracle. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");

/// Drop a single leading space from the NUL-terminated string in place.
pub fn trimLeadingSpace(s: [*]u8) void {
    if (s[0] == ' ') {
        var n: usize = 0;
        while (s[n] != 0) : (n += 1) {}
        var i: usize = 0;
        while (i < n) : (i += 1) s[i] = s[i + 1];
    }
}

fn trimmed(src: []const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..src.len], src);
    S.buf[src.len] = 0;
    trimLeadingSpace(&S.buf);
    return std.mem.sliceTo(&S.buf, 0);
}

test "a single leading space is dropped" {
    try std.testing.expectEqualStrings("abc", trimmed(" abc"));
    try std.testing.expectEqualStrings("", trimmed(" "));
}

test "a string without a leading space is unchanged" {
    try std.testing.expectEqualStrings("abc", trimmed("abc"));
    try std.testing.expectEqualStrings("", trimmed(""));
}

test "only one leading space is removed" {
    try std.testing.expectEqualStrings(" x", trimmed("  x"));
}
