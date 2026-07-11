//! Zero-axis range inclusion -- the pure core of frontier_graphs' graph_Include0.
//!
//! When both ends of a plot axis share a sign, the 0 line is off-screen. To keep
//! it visible the range is pulled toward zero: the near end becomes -5% of the
//! far end (its magnitude, so 0 is just inside), or is clamped to 0 outright when
//! the ends are ordered the "wrong" way. The same adjustment applies to the X and
//! Y axes, so lift it here once for native coverage -- the plot owner reads the
//! axis globals and the SHOWX/SHOWY flags and delegates.

const std = @import("std");

pub const Range = struct { min: f32, max: f32 };

/// Pull `[min, max]` toward the 0 axis when both ends share a sign.
pub fn includeZeroAxis(min_in: f32, max_in: f32) Range {
    var min = min_in;
    var max = max_in;
    if (min > 0.0 and max > 0.0) {
        if (min <= max) {
            min = -0.05 * max;
        } else {
            min = 0.0;
        }
    }
    if (min < 0.0 and max < 0.0) {
        if (min >= max) {
            min = -0.05 * max;
        } else {
            max = 0.0;
        }
    }
    return .{ .min = min, .max = max };
}

test "a positive range drops its lower end below zero" {
    const r = includeZeroAxis(2.0, 10.0); // min <= max
    try std.testing.expectEqual(@as(f32, -0.5), r.min); // -0.05 * 10
    try std.testing.expectEqual(@as(f32, 10.0), r.max);
}

test "a reversed positive range clamps the lower end to zero" {
    const r = includeZeroAxis(10.0, 2.0); // min > max
    try std.testing.expectEqual(@as(f32, 0.0), r.min);
    try std.testing.expectEqual(@as(f32, 2.0), r.max);
}

test "a negative range lifts its upper end above zero" {
    const r = includeZeroAxis(-10.0, -2.0); // min < max -> else branch
    try std.testing.expectEqual(@as(f32, -10.0), r.min);
    try std.testing.expectEqual(@as(f32, 0.0), r.max);
    const r2 = includeZeroAxis(-2.0, -10.0); // min >= max
    try std.testing.expectEqual(@as(f32, 0.5), r2.min); // -0.05 * -10
}

test "a range straddling zero is unchanged" {
    const r = includeZeroAxis(-3.0, 5.0);
    try std.testing.expectEqual(@as(f32, -3.0), r.min);
    try std.testing.expectEqual(@as(f32, 5.0), r.max);
}
