//! Integer thousands-separator insertion -- the pure core of frontier_display's
//! insertSepsIntoIntegerText.
//!
//! An already-formatted integer display string is walked right-to-left and group
//! separators are spliced in every groupwidth digits (with a distinct first-group
//! width, a first-group overflow allowance, and a shorter HP-mode width). Each
//! splice shifts the tail right and writes the 1- or 2-byte separator. It is a
//! pure in-place buffer transform; the owner resolves the widths, the separator
//! bytes, and the HP-mode flag, and applies the grouping-enabled guard. Lift it
//! here for native coverage -- the display owner is only reachable through the C
//! oracle. This module uses Zig many-item pointers rather than C pointers, so it
//! stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

fn strlen(p: [*]const u8) i16 {
    var i: i16 = 0;
    while (p[@intCast(i)] != 0) : (i += 1) {}
    return i;
}

// memmove the `n` bytes at [src_at, src_at+n) right by `shift` (dest > src, so
// copy backwards to survive the overlap) -- the owner's xcopy right-shift.
fn moveRight(display: [*]u8, src_at: i16, shift: usize, n: i16) void {
    const s: usize = @intCast(src_at);
    const cnt: usize = @intCast(n);
    std.mem.copyBackwards(u8, display[s + shift .. s + shift + cnt], display[s .. s + cnt]);
}

/// Splice group separators into the NUL-terminated integer string `display`.
/// `group_left` / `group_left1` are the ordinary and first-group widths,
/// `group_left1x` the first-group overflow allowance, `sep0`/`sep1` the separator
/// bytes (sep1 == 1 marks a single-byte separator), `is_hp` the HP-mode flag.
pub fn insertSeps(display: [*]u8, group_left: i16, group_left1: i16, group_left1x: i32, sep0: u8, sep1: u8, is_hp: bool) void {
    var len: i16 = strlen(display);
    const digit_one: i16 = if (display[0] == '-') 1 else 0;
    var grp1: i16 = if (group_left1x > 0 and (@as(i32, display[@intCast(digit_one)]) - 48 <= group_left1x) and (len - digit_one == group_left1 + 1)) group_left1 + 1 else group_left1;
    grp1 = if (len >= (if (is_hp) @as(i16, 10) else 20)) group_left else grp1;
    var ii: i16 = len - grp1;
    if (ii > 0 and (ii != 1 or display[0] != '-')) {
        if (sep1 != 1) {
            moveRight(display, ii, 2, len - ii + 1);
            display[@intCast(ii)] = sep0;
            display[@intCast(ii + 1)] = sep1;
        } else if (sep0 != 1) {
            moveRight(display, ii, 1, len - ii + 1);
            display[@intCast(ii)] = sep0;
        }

        len = strlen(display);
        ii = len - group_left - (grp1 + (if (sep1 == 1) @as(i16, 1) else 2));
        while (ii > 0) : (ii -= group_left) {
            if (ii != 1 or display[0] != '-') {
                if (sep1 != 1) {
                    moveRight(display, ii, 2, len - ii + 1);
                    display[@intCast(ii)] = sep0;
                    display[@intCast(ii + 1)] = sep1;
                    len += 2;
                } else if (sep0 != 1) {
                    moveRight(display, ii, 1, len - ii + 1);
                    display[@intCast(ii)] = sep0;
                    len += 1;
                }
            }
        }
    }
}

fn grouped(src: []const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..src.len], src);
    S.buf[src.len] = 0;
    insertSeps(&S.buf, 3, 3, 0, ',', 1, false);
    return std.mem.sliceTo(&S.buf, 0);
}

test "groups a seven-digit integer every three digits" {
    try std.testing.expectEqualStrings("1,234,567", grouped("1234567"));
}

test "keeps the minus sign outside the grouping" {
    try std.testing.expectEqualStrings("-1,234,567", grouped("-1234567"));
}

test "leaves a short integer untouched" {
    try std.testing.expectEqualStrings("123", grouped("123"));
    try std.testing.expectEqualStrings("-1", grouped("-1"));
}

test "a two-byte separator writes both bytes" {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    const src = "1234";
    @memcpy(S.buf[0..src.len], src);
    S.buf[src.len] = 0;
    insertSeps(&S.buf, 3, 3, 0, 0xaa, 0xbb, false);
    // 1234 -> one separator before the last three digits.
    try std.testing.expectEqualSlices(u8, &[_]u8{ '1', 0xaa, 0xbb, '2', '3', '4' }, std.mem.sliceTo(&S.buf, 0));
}
