//! Degenerate plot-range expansion -- the pure core of frontier_graphs'
//! graph_Include0 "modify the draw range if min == max" step.
//!
//! A zero-width axis (min == max, e.g. a single data point) cannot be drawn, so
//! it is widened to unit width centred on the value: max = min + 0.5, min -= 0.5.
//! The same expansion applies to the X and Y axes. It is pure f32 arithmetic --
//! lift it here for native coverage; the plot owner reads the axis globals and
//! recomputes the span from the widened range.

const std = @import("std");

pub const Range = struct { min: f32, max: f32 };

/// Widen a zero-width `[min, max]` range to unit width centred on the value; a
/// non-degenerate range is returned unchanged.
pub fn expandDegenerateRange(min_in: f32, max_in: f32) Range {
    var min = min_in;
    var max = max_in;
    if (max - min == 0.0) {
        const d: f32 = 1.0;
        max = min + d / 2.0;
        min = max - d;
    }
    return .{ .min = min, .max = max };
}

test "a degenerate range widens to unit width centred on the value" {
    const r = expandDegenerateRange(3.0, 3.0);
    try std.testing.expectEqual(@as(f32, 2.5), r.min);
    try std.testing.expectEqual(@as(f32, 3.5), r.max);
    try std.testing.expectEqual(@as(f32, 1.0), r.max - r.min);
}

test "a non-degenerate range is unchanged" {
    const r = expandDegenerateRange(-2.0, 5.0);
    try std.testing.expectEqual(@as(f32, -2.0), r.min);
    try std.testing.expectEqual(@as(f32, 5.0), r.max);
}
