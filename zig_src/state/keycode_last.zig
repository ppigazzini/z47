// SPDX-License-Identifier: GPL-3.0-only
//
// Pure physical-key -> lastKeyCode band remap, lifted from
// keyboard_state_shared.zig (setLastKeyCode). The 43 physical keys map to a
// banded internal code; the only side effect in the owner is writing
// runtime.lastKeyCode, so the mapping itself is std-only and lives here,
// exercised natively under `zig build test:unit`. Out-of-range keys yield null,
// so the owner leaves lastKeyCode unchanged (the C early `return`).
//
// testSuite-BLIND (the suite drives logical items, not physical scan codes), so
// the native tests are this remap's first coverage -- the band boundaries are
// exactly the off-by-one-prone spot to pin. Transcription is verbatim.

const std = @import("std");

/// Internal key code for physical `key` (1..43), or null if out of range.
pub fn lastKeyCodeFor(key: i32) ?u8 {
    if (key < 1 or key > 43) return null;
    if (key <= 6) return @intCast(key + 20);
    if (key <= 12) return @intCast(key - 6 + 30);
    if (key <= 17) return @intCast(key - 12 + 40);
    if (key <= 22) return @intCast(key - 17 + 50);
    if (key <= 27) return @intCast(key - 22 + 60);
    if (key <= 32) return @intCast(key - 27 + 70);
    if (key <= 37) return @intCast(key - 32 + 80);
    return @intCast(key - 37 + 10);
}

test "lastKeyCodeFor rejects out-of-range keys" {
    try std.testing.expectEqual(@as(?u8, null), lastKeyCodeFor(0));
    try std.testing.expectEqual(@as(?u8, null), lastKeyCodeFor(44));
    try std.testing.expectEqual(@as(?u8, null), lastKeyCodeFor(-1));
}

test "lastKeyCodeFor maps each band at its boundaries" {
    // {first,last} physical key of each band -> {first,last} code.
    const cases = [_]struct { k: i32, c: u8 }{
        .{ .k = 1, .c = 21 }, .{ .k = 6, .c = 26 }, // band 1: +20
        .{ .k = 7, .c = 31 }, .{ .k = 12, .c = 36 }, // band 2
        .{ .k = 13, .c = 41 }, .{ .k = 17, .c = 45 }, // band 3
        .{ .k = 18, .c = 51 }, .{ .k = 22, .c = 55 }, // band 4
        .{ .k = 23, .c = 61 }, .{ .k = 27, .c = 65 }, // band 5
        .{ .k = 28, .c = 71 }, .{ .k = 32, .c = 75 }, // band 6
        .{ .k = 33, .c = 81 }, .{ .k = 37, .c = 85 }, // band 7
        .{ .k = 38, .c = 11 }, .{ .k = 43, .c = 16 }, // band 8 wraps to 10s
    };
    for (cases) |t| try std.testing.expectEqual(@as(?u8, t.c), lastKeyCodeFor(t.k));
}
