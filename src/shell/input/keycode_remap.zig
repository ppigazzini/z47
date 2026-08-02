// SPDX-License-Identifier: GPL-3.0-only
//
// Pure physical->logical key-code remapping for the R47 and WP43 keyboard
// layouts, lifted from c47.zig (dmcp.convertKeyCode). It is a plain
// integer table -- no register, dec, or GTK coupling -- so it lives here as a
// std-only module exercised natively under `zig build test:unit`. The owner reads
// the layout globals (isR47FAM(), wp43KbdLayout) and threads them in as flags.
//
// These layout branches are testSuite-BLIND (the suite runs the default layout,
// where every key passes through), so the native tests below are the only
// automated coverage of the specific remaps -- exactly the off-by-one-prone table
// worth pinning. Transcription is verbatim.

const std = @import("std");

/// Remap `key_in` for the active keyboard layout. R47 takes precedence over WP43;
/// with neither active (the default layout) the key passes through unchanged, as
/// does any key not listed in the active layout's table.
pub fn remapKey(key_in: c_int, is_r47: bool, wp43_layout: bool) c_int {
    var key = key_in;
    if (is_r47) {
        // R47 keyboard mapping (upstream #if CALCMODEL == USER_R47).
        switch (key) {
            11 => key = 18, // COS
            15 => key = 16, // +/-
            16 => key = 15, // E
            18 => key = 23, // UP
            23 => key = 28, // DOWN
            28 => key = 11, // SHIFT
            else => {},
        }
    } else if (wp43_layout) {
        switch (key) {
            1 => key = 2, // SUM+
            2 => key = 1, // 1/x
            3 => key = 6, // SQRT
            4 => key = 5, // LOG
            5 => key = 4, // LN
            6 => key = 22, // XEQ
            10 => key = 3, // SIN
            11 => key = 10, // COS
            12 => key = 11, // TAN
            18 => key = 27, // UP
            22 => key = 18, // /
            23 => key = 32, // DOWN
            27 => key = 23, // x
            28 => key = 12, // SHIFT
            32 => key = 28, // -
            33 => key = 37, // EXIT
            37 => key = 33, // +
            else => {},
        }
    }
    return key;
}

// ===========================================================================
// Tests -- native (run under `zig build test:unit`).
// ===========================================================================
const testing = std.testing;

test "default layout passes every key through unchanged" {
    var k: c_int = 0;
    while (k < 40) : (k += 1) {
        try testing.expectEqual(k, remapKey(k, false, false));
    }
}

test "R47 layout remaps its six keys and passes the rest through" {
    try testing.expectEqual(@as(c_int, 18), remapKey(11, true, false));
    try testing.expectEqual(@as(c_int, 16), remapKey(15, true, false));
    try testing.expectEqual(@as(c_int, 15), remapKey(16, true, false));
    try testing.expectEqual(@as(c_int, 23), remapKey(18, true, false));
    try testing.expectEqual(@as(c_int, 28), remapKey(23, true, false));
    try testing.expectEqual(@as(c_int, 11), remapKey(28, true, false));
    try testing.expectEqual(@as(c_int, 5), remapKey(5, true, false)); // unlisted
}

test "R47 takes precedence over WP43 when both flags are set" {
    // is_r47 wins: key 1 is not in the R47 table, so it stays 1 (not the WP43 2).
    try testing.expectEqual(@as(c_int, 1), remapKey(1, true, true));
    try testing.expectEqual(@as(c_int, 18), remapKey(11, true, true)); // R47 map
}

test "WP43 layout applies its full table" {
    const pairs = [_][2]c_int{
        .{ 1, 2 },   .{ 2, 1 },   .{ 3, 6 },   .{ 4, 5 },   .{ 5, 4 },
        .{ 6, 22 },  .{ 10, 3 },  .{ 11, 10 }, .{ 12, 11 }, .{ 18, 27 },
        .{ 22, 18 }, .{ 23, 32 }, .{ 27, 23 }, .{ 28, 12 }, .{ 32, 28 },
        .{ 33, 37 }, .{ 37, 33 },
    };
    for (pairs) |p| {
        try testing.expectEqual(p[1], remapKey(p[0], false, true));
    }
    try testing.expectEqual(@as(c_int, 40), remapKey(40, false, true)); // unlisted
}
