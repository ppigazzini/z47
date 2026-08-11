// SPDX-License-Identifier: GPL-3.0-only
//
// Pure graph-viewport clamping for the plot/stat screen, lifted from the tails of
// upstream plotstat.c screen_window_x_r / _screen_window_y_r. Those functions
// compute their ratio in decimal (screenWindowRatio, which needs decNumber and
// therefore stays with the plotstat owner) and then clamp the saturated int16
// ratio into the graph area; the clamping half reads no register, dec, GTK or
// global state, so it lives here as a std-only module exercised natively under
// `zig build test:unit`.
//
// These paths are testSuite-BLIND (only the graph plotter reaches them), so the
// native tests below are their only automated coverage -- exactly the
// clamp/flip/offset arithmetic worth pinning.

const std = @import("std");

const SCREEN_WIDTH: i32 = 400;
const SCREEN_HEIGHT_GRAPH: i32 = 240;
const minn: i32 = 0; // #define minn 0

/// screen_window_x_r's tail: clamp the saturated ratio into
/// [0, SCREEN_HEIGHT_GRAPH-1], then offset to the graph's screen origin.
pub fn graphColumn(ratio: i16) i16 {
    var temp: i16 = ratio;

    if (temp > SCREEN_HEIGHT_GRAPH - 1) {
        temp = @intCast(SCREEN_HEIGHT_GRAPH - 1);
    } else if (temp < 0) {
        temp = 0;
    }

    return @intCast(@as(i32, temp) + SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);
}

/// _screen_window_y_r's tail: clamp the saturated ratio into the graph area
/// unless `nolimit`, then flip to a top-origin row. The result is returned as
/// i32 because the unclamped flip leaves the int16 range (the C computes it in
/// `int` and truncates only in the return cast), and because the caller's
/// PC_BUILD range telltale reads the untruncated value.
pub fn graphRow(ratio: i16, nolimit: bool) i32 {
    var temp: i16 = ratio;

    if (!nolimit) {
        if (temp > SCREEN_HEIGHT_GRAPH - 1 - minn) {
            temp = @intCast(SCREEN_HEIGHT_GRAPH - 1 - minn);
        } else if (temp < 0) {
            temp = 0;
        }
    }

    return SCREEN_HEIGHT_GRAPH - 1 - @as(i32, temp);
}

// ---------------------------------------------------------------------------
// Native tests -- the only automated coverage of the viewport clamping.
// ---------------------------------------------------------------------------

test "graphColumn offsets an in-range ratio to the graph's screen origin" {
    try std.testing.expectEqual(@as(i16, 160), graphColumn(0));
    try std.testing.expectEqual(@as(i16, 280), graphColumn(120));
    try std.testing.expectEqual(@as(i16, 399), graphColumn(239));
}

test "graphColumn clamps out-of-range ratios into the graph column span" {
    try std.testing.expectEqual(@as(i16, 399), graphColumn(240));
    try std.testing.expectEqual(@as(i16, 399), graphColumn(32767));
    try std.testing.expectEqual(@as(i16, 160), graphColumn(-1));
    try std.testing.expectEqual(@as(i16, 160), graphColumn(-32767));
}

test "graphRow flips origin (top-left) and clamps when limited" {
    try std.testing.expectEqual(@as(i32, 239), graphRow(0, false));
    try std.testing.expectEqual(@as(i32, 0), graphRow(239, false));
    try std.testing.expectEqual(@as(i32, 119), graphRow(120, false));
    // Above the graph area clamps to 239 -> row 0; below it clamps to 0 -> row 239.
    try std.testing.expectEqual(@as(i32, 0), graphRow(1000, false));
    try std.testing.expectEqual(@as(i32, 239), graphRow(-1000, false));
}

test "graphRow nolimit skips the clamp so rows leave the screen" {
    try std.testing.expectEqual(@as(i32, 239 - 478), graphRow(478, true));
    try std.testing.expectEqual(@as(i32, 119), graphRow(120, true));
    // The saturated extremes stay representable in i32 and only the caller's
    // return cast truncates them.
    try std.testing.expectEqual(@as(i32, 239 - 32767), graphRow(32767, true));
    try std.testing.expectEqual(@as(i32, 239 + 32767), graphRow(-32767, true));
}
