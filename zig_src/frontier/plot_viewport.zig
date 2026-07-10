// SPDX-License-Identifier: GPL-3.0-only
//
// Pure graph-viewport coordinate math for the plot/stat screen, lifted from
// frontier_plotstat.zig (the upstream plotstat.c screen_window_x / _screen_window_y
// macros). These map a data value in [min, max] to an LCD column/row with
// saturation past +-32766 and clamping into the graph area; they read no register,
// dec, GTK, or global state, so they live here as a std-only module exercised
// natively under `zig build test:unit`.
//
// These paths are testSuite-BLIND (only the graph plotter calls them), so the
// native tests below are their first automated coverage -- exactly the
// saturate/clamp/flip arithmetic worth pinning. Transcription is verbatim; the
// i16 result cast matches the owner's (a huge-negative nolimit y can overflow it
// in the original, so the tests exercise the reachable saturate/clamp behavior).

const std = @import("std");

const SCREEN_WIDTH: i32 = 400;
const SCREEN_HEIGHT_GRAPH: i32 = 240;
const minn: i32 = 0; // #define minn 0

// ROUND_F2I(f) ((int)((f) >= 0 ? (f) + 0.5f : (f) - 0.5f))
inline fn roundF2I(f: f32) i32 {
    return @intFromFloat(if (f >= 0) f + 0.5 else f - 0.5);
}

/// Map data `x` in [`x_minp`, `x_maxp`] to an LCD column: scale into the graph
/// height, saturate past +-32766, clamp to [0, height-1], then offset to the
/// graph's screen origin (SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH).
pub fn screenWindowX(x_minp: f32, x: f32, x_maxp: f32) i16 {
    var temp: i16 = undefined;
    const tempr: f32 = ((x - x_minp) / (x_maxp - x_minp) * @as(f32, @floatFromInt(SCREEN_HEIGHT_GRAPH - 1)));

    if (tempr > 32766) {
        temp = 32767;
    } else if (tempr < -32766) {
        temp = -32767;
    } else {
        temp = @intCast(roundF2I(tempr));
    }

    if (temp > SCREEN_HEIGHT_GRAPH - 1) {
        temp = @intCast(SCREEN_HEIGHT_GRAPH - 1);
    } else if (temp < 0) {
        temp = 0;
    }

    return @intCast(@as(i32, temp) + SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);
}

/// Map data `y` in [`y_minp`, `y_maxp`] to an LCD row (top-origin flipped). With
/// `nolimit` the clamp into the graph area is skipped (used for line clipping).
pub fn screenWindowY(y_minp: f32, y: f32, y_maxp: f32, nolimit: bool) i16 {
    var temp: i32 = undefined;
    const tempr: f32 = ((y - y_minp) / (y_maxp - y_minp) * @as(f32, @floatFromInt(SCREEN_HEIGHT_GRAPH - 1 - minn)));

    if (tempr > 32766) {
        temp = 32767;
    } else if (tempr < -32766) {
        temp = -32767;
    } else {
        temp = @as(i32, @as(i16, @intCast(roundF2I(tempr))));
    }

    if (!nolimit) {
        if (temp > SCREEN_HEIGHT_GRAPH - 1 - minn) {
            temp = SCREEN_HEIGHT_GRAPH - 1 - minn;
        } else if (temp < 0) {
            temp = 0;
        }
    }

    return @intCast(SCREEN_HEIGHT_GRAPH - 1 - temp);
}

// ---------------------------------------------------------------------------
// Native tests -- first automated coverage of the viewport math.
// ---------------------------------------------------------------------------

test "screenWindowX maps midpoint to graph center + origin offset" {
    // x at the midpoint of [0, 10] -> (0.5 * 239) = 119.5 -> round 120,
    // then + (400 - 240) = 160 origin offset.
    try std.testing.expectEqual(@as(i16, 280), screenWindowX(0, 5, 10));
    // x at min -> 0 + 160.
    try std.testing.expectEqual(@as(i16, 160), screenWindowX(0, 0, 10));
    // x at max -> 239 + 160.
    try std.testing.expectEqual(@as(i16, 399), screenWindowX(0, 10, 10));
}

test "screenWindowX clamps out-of-range into the graph column span" {
    // Above max clamps to height-1 (239) + 160.
    try std.testing.expectEqual(@as(i16, 399), screenWindowX(0, 20, 10));
    // Below min clamps to 0 + 160.
    try std.testing.expectEqual(@as(i16, 160), screenWindowX(0, -20, 10));
}

test "screenWindowY flips origin (top-left) and clamps when limited" {
    // y at min -> temp 0 -> row 239 (bottom). y at max -> temp 239 -> row 0 (top).
    try std.testing.expectEqual(@as(i16, 239), screenWindowY(0, 0, 10, false));
    try std.testing.expectEqual(@as(i16, 0), screenWindowY(0, 10, 10, false));
    // Midpoint -> temp 120 -> row 119.
    try std.testing.expectEqual(@as(i16, 119), screenWindowY(0, 5, 10, false));
    // Above max, limited -> temp clamps to 239 -> row 0.
    try std.testing.expectEqual(@as(i16, 0), screenWindowY(0, 20, 10, false));
    // Below min, limited -> temp clamps to 0 -> row 239.
    try std.testing.expectEqual(@as(i16, 239), screenWindowY(0, -20, 10, false));
}

test "screenWindowY nolimit skips the clamp so rows go off-screen" {
    // y above max with nolimit: temp = round(2 * 239) = 478 -> row 239 - 478.
    try std.testing.expectEqual(@as(i16, 239 - 478), screenWindowY(0, 20, 10, true));
    // In-range is identical to the limited path.
    try std.testing.expectEqual(@as(i16, 119), screenWindowY(0, 5, 10, true));
}

test "roundF2I rounds half away from zero like the C macro" {
    try std.testing.expectEqual(@as(i32, 1), roundF2I(0.5));
    try std.testing.expectEqual(@as(i32, -1), roundF2I(-0.5));
    try std.testing.expectEqual(@as(i32, 3), roundF2I(2.5));
    try std.testing.expectEqual(@as(i32, 0), roundF2I(0.4));
}
