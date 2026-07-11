//! Plot viewport zoom -- the pure core of frontier_graphs' multiplyZoomFactors.
//!
//! Zooming the plot pans the min/max bounds outward by dx/dy * zoomfactor, then
//! rescales symmetrically about the recomputed center by plotzoom * histofactor.
//! It is pure f32 arithmetic over the bound pointers; the owner supplies the
//! file-constant zoomfactor. Lift it here for native coverage -- the graphs owner
//! is only reachable through the C oracle.

const std = @import("std");

/// Pan and rescale the plot bounds in place. `zoomfactor` is the pan step; the
/// `plotzoom*`/`histofactor` factors rescale about the center.
pub fn multiplyZoomFactors(
    plotzoomx: f32,
    plotzoomy: f32,
    histofactor: f32,
    zoomfactor: f32,
    x_min_: *f32,
    x_max_: *f32,
    y_min_: *f32,
    y_max_: *f32,
    dx: *f32,
    dy: *f32,
) void {
    x_min_.* = x_min_.* - dx.* * zoomfactor;
    y_min_.* = y_min_.* - dy.* * zoomfactor;
    x_max_.* = x_max_.* + dx.* * zoomfactor;
    y_max_.* = y_max_.* + dy.* * zoomfactor;
    dx.* = x_max_.* - x_min_.*;
    dy.* = y_max_.* - y_min_.*;
    const xavg: f32 = (x_max_.* + x_min_.*) / 2;
    const yavg: f32 = (y_max_.* + y_min_.*) / 2;
    y_min_.* = yavg - dy.* / 2 * plotzoomy * histofactor;
    y_max_.* = yavg + dy.* / 2 * plotzoomy * histofactor;
    x_min_.* = xavg - dx.* / 2 * plotzoomx * histofactor;
    x_max_.* = xavg + dx.* / 2 * plotzoomx * histofactor;
}

const Bounds = struct { x_min: f32, x_max: f32, y_min: f32, y_max: f32, dx: f32, dy: f32 };

fn run(b: *Bounds, plotzoomx: f32, plotzoomy: f32, histofactor: f32, zoomfactor: f32) void {
    multiplyZoomFactors(plotzoomx, plotzoomy, histofactor, zoomfactor, &b.x_min, &b.x_max, &b.y_min, &b.y_max, &b.dx, &b.dy);
}

test "unit factors and no pan leave the bounds unchanged" {
    var b = Bounds{ .x_min = 0, .x_max = 4, .y_min = 0, .y_max = 2, .dx = 4, .dy = 2 };
    run(&b, 1, 1, 1, 0);
    try std.testing.expectEqual(Bounds{ .x_min = 0, .x_max = 4, .y_min = 0, .y_max = 2, .dx = 4, .dy = 2 }, b);
}

test "histofactor rescales symmetrically about the center" {
    var b = Bounds{ .x_min = 0, .x_max = 4, .y_min = 0, .y_max = 2, .dx = 4, .dy = 2 };
    run(&b, 1, 1, 2, 0);
    // Center (2,1); spans doubled: x [-2,6], y [-1,3].
    try std.testing.expectEqual(@as(f32, -2), b.x_min);
    try std.testing.expectEqual(@as(f32, 6), b.x_max);
    try std.testing.expectEqual(@as(f32, -1), b.y_min);
    try std.testing.expectEqual(@as(f32, 3), b.y_max);
}

test "zoomfactor pans the bounds outward before the rescale" {
    var b = Bounds{ .x_min = 0, .x_max = 4, .y_min = 0, .y_max = 4, .dx = 4, .dy = 4 };
    run(&b, 1, 1, 1, 0.5);
    // Pan: x [-2,6] dx=8, rescale about center 2 keeps [-2,6].
    try std.testing.expectEqual(@as(f32, -2), b.x_min);
    try std.testing.expectEqual(@as(f32, 6), b.x_max);
    try std.testing.expectEqual(@as(f32, 8), b.dx);
}
