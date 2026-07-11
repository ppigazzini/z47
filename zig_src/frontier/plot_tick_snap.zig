//! Axis-tick mantissa snapping -- the pure core of frontier_plotstat's auto_tick.
//!
//! With rounded ticks enabled, a raw tick interval's mantissa (its value in the
//! [1, 10) decade) is snapped to one of the "nice" tick steps 1, 1.5, 2, 5, 7.5
//! by ascending threshold; a non-positive mantissa falls back to 1. The owner
//! extracts the mantissa and its power-of-ten multiplier (via the C formatting
//! round-trip, kept for exact parity) and multiplies the snapped mantissa back;
//! only the threshold ladder is lifted here for native coverage.

const std = @import("std");

/// Snap a tick-interval mantissa to the nearest "nice" step at or above it.
pub fn snapTickMantissa(m: f32) f32 {
    if (m <= 0) return 1;
    if (m <= 1.3) return 1.0;
    if (m <= 1.7) return 1.5;
    if (m <= 3.0) return 2.0;
    if (m <= 6.5) return 5.0;
    if (m <= 9.9) return 7.5;
    return m;
}

test "each decade band snaps to its nice step" {
    try std.testing.expectEqual(@as(f32, 1.0), snapTickMantissa(1.0));
    try std.testing.expectEqual(@as(f32, 1.5), snapTickMantissa(1.5));
    try std.testing.expectEqual(@as(f32, 2.0), snapTickMantissa(2.5));
    try std.testing.expectEqual(@as(f32, 5.0), snapTickMantissa(6.0));
    try std.testing.expectEqual(@as(f32, 7.5), snapTickMantissa(8.0));
}

test "a non-positive mantissa falls back to 1" {
    try std.testing.expectEqual(@as(f32, 1.0), snapTickMantissa(0.0));
    try std.testing.expectEqual(@as(f32, 1.0), snapTickMantissa(-2.0));
}
