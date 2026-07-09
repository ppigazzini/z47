// SPDX-License-Identifier: GPL-3.0-only
//! Pure in-place string-edit helpers lifted out of frontier_char_string.zig
//! (src/c47/charString.c): wrap a NUL-terminated buffer with a character or a
//! pair of affix strings, and find the first adjacent character pair. They
//! depend on nothing but their byte arguments, so this module imports only std
//! and runs under `zig build test:unit`.
//!
//! addChrBothSides / addStrBothSides shift the buffer rightward to open room
//! for a prefix, which overlaps the source. The owner used xcopy (a memmove
//! that copies backward when dest > source); `move` below reproduces that exact
//! direction choice so the overlapping shifts stay byte-identical.

const std = @import("std");

/// Length of a NUL-terminated byte buffer (a std-only strlen).
fn byteLen(s: [*]const u8) usize {
    var n: usize = 0;
    while (s[n] != 0) n += 1;
    return n;
}

/// Copy `n` bytes from `source` to `dest`, choosing copy direction by pointer
/// order exactly as the owner's xcopy memmove did: forward when the source sits
/// above the destination, backward when it sits below (a right-shift), nothing
/// when they coincide. Overlap-safe for both shift directions.
fn move(dest: [*]u8, source: [*]const u8, n: usize) void {
    if (n == 0) return;
    if (@intFromPtr(source) > @intFromPtr(dest)) {
        var i: usize = 0;
        while (i < n) : (i += 1) dest[i] = source[i];
    } else if (@intFromPtr(source) < @intFromPtr(dest)) {
        var k = n;
        while (k != 0) {
            k -= 1;
            dest[k] = source[k];
        }
    }
}

/// addChrBothSides: wrap `str` in place with the single byte `t` on both ends
/// (e.g. surrounding a name with quote characters).
pub fn addChrBothSides(t: u8, str: [*]u8) void {
    move(str + 1, str, byteLen(str) + 1); // shift right by one to free str[0]
    str[0] = t;
    const end = byteLen(str);
    str[end] = t; // append the closing copy
    str[end + 1] = 0;
}

/// addStrBothSides: wrap `str` in place, prepending `str_b` and appending
/// `str_e` (both NUL-terminated).
pub fn addStrBothSides(str: [*]u8, str_b: [*]const u8, str_e: [*]const u8) void {
    const len_b = byteLen(str_b);
    move(str + len_b, str, byteLen(str) + 1); // shift right to open room for str_b
    move(str, str_b, len_b); // write the prefix
    const end = byteLen(str); // length after the prepend
    move(str + end, str_e, byteLen(str_e) + 1); // append the suffix incl. its NUL
}

/// findTwoChars: report the index of the first place where `char1` is
/// immediately followed by `char2`, writing it through `position` and returning
/// true; return false when no such pair exists. Wrapping u16 index matches the
/// owner.
pub fn findTwoChars(str: [*]const u8, char1: u8, char2: u8, position: *u16) bool {
    var i: u16 = 0;
    while (str[i] != 0 and str[i + 1] != 0) : (i +%= 1) {
        if (str[i] == char1 and str[i + 1] == char2) {
            position.* = i;
            return true;
        }
    }
    return false;
}

const testing = std.testing;

fn cstr(comptime in: []const u8, buf: []u8) [*]u8 {
    for (in, 0..) |c, k| buf[k] = c;
    buf[in.len] = 0;
    return buf.ptr;
}

test "addChrBothSides wraps a string with a quote on both ends" {
    var buf: [16]u8 = undefined;
    const s = cstr("AB", &buf);
    addChrBothSides('"', s);
    try testing.expectEqualStrings("\"AB\"", std.mem.sliceTo(s, 0));
}

test "addChrBothSides on an empty string yields just the doubled character" {
    var buf: [8]u8 = undefined;
    const s = cstr("", &buf);
    addChrBothSides('*', s);
    try testing.expectEqualStrings("**", std.mem.sliceTo(s, 0));
}

test "addStrBothSides prepends and appends the affix strings" {
    var buf: [32]u8 = undefined;
    const s = cstr("X", &buf);
    var bb: [8]u8 = undefined;
    var ee: [8]u8 = undefined;
    addStrBothSides(s, cstr("[", &bb), cstr("]", &ee));
    try testing.expectEqualStrings("[X]", std.mem.sliceTo(s, 0));
}

test "addStrBothSides handles multi-character affixes" {
    var buf: [32]u8 = undefined;
    const s = cstr("mid", &buf);
    var bb: [8]u8 = undefined;
    var ee: [8]u8 = undefined;
    addStrBothSides(s, cstr("<<", &bb), cstr(">>", &ee));
    try testing.expectEqualStrings("<<mid>>", std.mem.sliceTo(s, 0));
}

test "findTwoChars locates the first adjacent pair" {
    var pos: u16 = 0xffff;
    try testing.expect(findTwoChars("abXYc", 'X', 'Y', &pos));
    try testing.expectEqual(@as(u16, 2), pos);
}

test "findTwoChars returns false when the pair is absent" {
    var pos: u16 = 0xffff;
    try testing.expect(!findTwoChars("abcd", 'X', 'Y', &pos));
    try testing.expectEqual(@as(u16, 0xffff), pos); // left untouched
}

test "findTwoChars needs the two chars adjacent, not merely present" {
    var pos: u16 = 0;
    try testing.expect(!findTwoChars("XaY", 'X', 'Y', &pos));
}
