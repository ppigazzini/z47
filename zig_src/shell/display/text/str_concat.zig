//! Scratch-buffer string concatenation -- the pure core of frontier_softmenus'
//! concat2 / concat3.
//!
//! These reproduce C string-literal concatenation (e.g. STD_GAUSS_WHITE_R
//! STD_SUB_0) by copying two or three NUL-terminated operands into a scratch
//! buffer. The copy is pure over the operands and a destination; the owner keeps
//! the scratch buffers. Lift the copy here for native coverage -- the softmenu
//! owner is only reachable through the C oracle. This module uses Zig many-item
//! pointers rather than C pointers.

const std = @import("std");

fn appendZ(dest: [*]u8, at: usize, src: [*]const u8) usize {
    var n = at;
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        dest[n] = src[i];
        n += 1;
    }
    return n;
}

/// Concatenate `a` then `b` into `dest`, NUL-terminate, return the length.
pub fn concat2(dest: [*]u8, a: [*]const u8, b: [*]const u8) usize {
    var n = appendZ(dest, 0, a);
    n = appendZ(dest, n, b);
    dest[n] = 0;
    return n;
}

/// Concatenate `a`, `b`, `c` into `dest`, NUL-terminate, return the length.
pub fn concat3(dest: [*]u8, a: [*]const u8, b: [*]const u8, c: [*]const u8) usize {
    var n = appendZ(dest, 0, a);
    n = appendZ(dest, n, b);
    n = appendZ(dest, n, c);
    dest[n] = 0;
    return n;
}

fn cat2(a: [:0]const u8, b: [:0]const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    const n = concat2(&S.buf, a.ptr, b.ptr);
    return S.buf[0..n];
}

fn cat3(a: [:0]const u8, b: [:0]const u8, c: [:0]const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    const n = concat3(&S.buf, a.ptr, b.ptr, c.ptr);
    return S.buf[0..n];
}

test "concat2 joins two strings" {
    try std.testing.expectEqualStrings("foobar", cat2("foo", "bar"));
    try std.testing.expectEqualStrings("x", cat2("", "x"));
    try std.testing.expectEqualStrings("x", cat2("x", ""));
    try std.testing.expectEqualStrings("", cat2("", ""));
}

test "concat3 joins three strings" {
    try std.testing.expectEqualStrings("[<]", cat3("[", "<", "]"));
    try std.testing.expectEqualStrings("abc", cat3("a", "b", "c"));
}
