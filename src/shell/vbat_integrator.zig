//! Battery-voltage integrator -- the pure core of config.zig's
//! updateVbatIntegrated_impl.
//!
//! The firmware smooths the raw battery reading toward a running integrated
//! value: a lower reading (or an out-of-range one) snaps the integrator down and
//! resets the loop counter, a reading above 2900 mV snaps it up, and an
//! in-between rising reading creeps up by at least 1 mV per minute pulse. That is
//! pure integer arithmetic over the previous value and the raw reading; the owner
//! keeps the USB early-out, the rom read, and the global writes.
//!
//! Lifting it here gives the integrator native coverage -- the config owner is
//! only reachable through the C oracle.

const std = @import("std");

/// The integration result: the new integrated value and whether the loop
/// counter should reset to zero.
pub const VbatResult = struct {
    integrated: c_int,
    reset_loop: bool,
};

/// Integrate a raw reading `raw` (mV) against the previous integrated value
/// `prev`. `minute_pulse` gates the slow creep upward.
pub fn integrate(prev: c_int, raw: c_int, minute_pulse: bool) VbatResult {
    if (raw > 1500 and raw < 3100) {
        if (raw < prev) {
            return .{ .integrated = raw, .reset_loop = true };
        } else if (raw > prev) {
            if (raw > 2900) {
                return .{ .integrated = raw, .reset_loop = true };
            } else if (minute_pulse) {
                const inc = @max(@as(c_int, 1), (raw - prev) >> 4);
                return .{ .integrated = prev + inc, .reset_loop = false };
            } else {
                return .{ .integrated = prev, .reset_loop = false };
            }
        } else {
            return .{ .integrated = prev, .reset_loop = false };
        }
    } else {
        return .{ .integrated = raw, .reset_loop = true };
    }
}

test "an out-of-range reading snaps the integrator to it and resets the loop" {
    try std.testing.expectEqual(VbatResult{ .integrated = 1000, .reset_loop = true }, integrate(2500, 1000, true));
    // 3100 is out of range (not < 3100).
    try std.testing.expectEqual(VbatResult{ .integrated = 3100, .reset_loop = true }, integrate(2500, 3100, true));
}

test "a lower in-range reading snaps down and resets" {
    try std.testing.expectEqual(VbatResult{ .integrated = 2000, .reset_loop = true }, integrate(2500, 2000, false));
}

test "a reading above 2900 snaps up and resets" {
    try std.testing.expectEqual(VbatResult{ .integrated = 2950, .reset_loop = true }, integrate(2000, 2950, false));
}

test "a rising in-range reading creeps up by at least one on a minute pulse" {
    // (2000 - 1900) >> 4 = 6.
    try std.testing.expectEqual(VbatResult{ .integrated = 1906, .reset_loop = false }, integrate(1900, 2000, true));
    // A tiny rise still moves at least 1 mV.
    try std.testing.expectEqual(VbatResult{ .integrated = 1901, .reset_loop = false }, integrate(1900, 1901, true));
}

test "a rising reading without a minute pulse holds steady" {
    try std.testing.expectEqual(VbatResult{ .integrated = 1900, .reset_loop = false }, integrate(1900, 2000, false));
}

test "an equal reading holds steady without resetting" {
    try std.testing.expectEqual(VbatResult{ .integrated = 2000, .reset_loop = false }, integrate(2000, 2000, true));
}
