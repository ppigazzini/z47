//! Display word-break trim -- the pure core of frontier_display's checkAndEat.
//!
//! When a display line must break, checkAndEat walks back up to 16 bytes from the
//! current position to the last punctuation-space or plain-space boundary and
//! NUL-terminates there, so the break lands on a separator rather than mid-word.
//! It is a small state machine over the buffer bytes and two indices; the owner
//! supplies the buffer, the group-disabled flag, and the punctuation-space
//! bytes. Lift it here for native coverage -- the display owner is only reachable
//! through the C oracle. This module uses Zig many-item pointers rather than C
//! pointers, so it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Trim `buf` back to the last space boundary before `dest`, advancing `dest`
/// and `source_p` together, and NUL-terminate there. A no-op when the source has
/// reached `last` or grouping is disabled.
pub fn checkAndEat(buf: [*]u8, source_p: *i16, last: i16, dest: *i16, group_disabled: bool, space_punct: [*]const u8) void {
    var ix: u8 = 0;
    if (source_p.* < last and !group_disabled) {
        while (ix < 16) : (ix += 1) {
            if (buf[@intCast(dest.* - 2)] == space_punct[0] and buf[@intCast(dest.* - 1)] == space_punct[1]) break;
            if (buf[@intCast(dest.* - 1)] == 32) break;
            dest.* -= 1;
            source_p.* -= 1;
        }
        buf[@intCast(dest.*)] = 0;
    }
}

const test_space_punct = "\xa0\x08";

test "breaks at a plain space and terminates there" {
    var buf = [_]u8{ 'a', 'b', ' ', 'c', 'd', 0 };
    var source_p: i16 = 3;
    var dest: i16 = 5;
    checkAndEat(&buf, &source_p, 10, &dest, false, test_space_punct);
    try std.testing.expectEqual(@as(i16, 3), dest);
    try std.testing.expectEqualStrings("ab ", std.mem.sliceTo(&buf, 0));
}

test "breaks at a two-byte punctuation-space marker" {
    var buf = [_]u8{ 'a', 'b', 0xa0, 0x08, 'c', 'd', 0 };
    var source_p: i16 = 4;
    var dest: i16 = 6;
    checkAndEat(&buf, &source_p, 10, &dest, false, test_space_punct);
    try std.testing.expectEqual(@as(i16, 4), dest);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 'a', 'b', 0xa0, 0x08 }, std.mem.sliceTo(&buf, 0));
}

test "does nothing when the source has reached last" {
    var buf = [_]u8{ 'a', 'b', 'c', 0 };
    var source_p: i16 = 10;
    var dest: i16 = 3;
    checkAndEat(&buf, &source_p, 10, &dest, false, test_space_punct);
    try std.testing.expectEqual(@as(i16, 3), dest);
    try std.testing.expectEqualStrings("abc", std.mem.sliceTo(&buf, 0));
}

test "does nothing when grouping is disabled" {
    var buf = [_]u8{ 'a', ' ', 'c', 0 };
    var source_p: i16 = 1;
    var dest: i16 = 3;
    checkAndEat(&buf, &source_p, 10, &dest, true, test_space_punct);
    try std.testing.expectEqual(@as(i16, 3), dest);
    try std.testing.expectEqualStrings("a c", std.mem.sliceTo(&buf, 0));
}
