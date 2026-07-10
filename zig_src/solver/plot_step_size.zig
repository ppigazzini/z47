// SPDX-License-Identifier: GPL-3.0-only
//
// Pure plot-step-size control, lifted from graph.zig (src/c47/graphs graph step
// control). Given the discontinuity/gradient state of the plotter it returns the
// next x step dx -- plain f64 arithmetic over three tuning constants, no register,
// dec, GTK, or global state -- so it lives here as a std-only module exercised
// natively under `zig build test:unit`. The owner keeps its pub-export C-ABI
// wrapper and delegates.
//
// testSuite-BLIND (the adaptive plotter is not in the oracle suite), so the native
// tests below are the first automated coverage of the four step-size branches.
// Transcription is verbatim.

const std = @import("std");

const SS1: f64 = 1.8; // grad ratio threshold for a 50% dx cut
const FINE: c_int = 9; // number of fine steps taken while resolving a discontinuity
const dJMP: f64 = 0.2; // fine movement in p.u. of dx while resolving

/// Next plot x-step dx: shrink hard (dJMP*dx0) during the fine steps that resolve
/// a discontinuity; hold at dx0 when a gradient is flat; halve on a steep grad
/// ratio increase; otherwise hold.
pub fn calculateNewStepSize(discontinuityDetected: c_int, grad1: f64, grad2: f64, grad2IncreaseDetected: bool, dx0: f64) f64 {
    if (discontinuityDetected > 0 and discontinuityDetected <= FINE) {
        const newDx: f64 = dJMP * dx0;
        return newDx;
    } else if (grad2 == 0 or grad1 == 0) {
        return dx0;
    } else if (grad2IncreaseDetected) {
        const ratio1: f64 = grad2 / grad1;
        const ratio2: f64 = grad1 / grad2;
        const newDx: f64 = dx0 * (if (ratio1 > SS1 or ratio2 > SS1) @as(f64, 0.5) else @as(f64, 1.0));
        return newDx;
    } else {
        return dx0;
    }
}

const testing = std.testing;

test "calculateNewStepSize picks the right dx per branch" {
    // Resolving a discontinuity (1..=FINE) -> fine step dJMP*dx0.
    try testing.expectEqual(@as(f64, 0.2), calculateNewStepSize(3, 1, 1, false, 1.0));
    try testing.expectEqual(@as(f64, 0.2), calculateNewStepSize(9, 1, 1, false, 1.0)); // FINE boundary
    // Past the fine window (10 > FINE) falls through to the gradient logic.
    try testing.expectEqual(@as(f64, 1.0), calculateNewStepSize(10, 1, 2, false, 1.0));
    // A flat gradient holds dx0.
    try testing.expectEqual(@as(f64, 1.0), calculateNewStepSize(0, 0, 0, false, 1.0));
    // grad increase with a steep ratio (>SS1) halves dx0...
    try testing.expectEqual(@as(f64, 0.5), calculateNewStepSize(0, 1, 3, true, 1.0));
    // ...but a shallow ratio holds it.
    try testing.expectEqual(@as(f64, 1.0), calculateNewStepSize(0, 1, 1.5, true, 1.0));
    // No grad increase holds dx0.
    try testing.expectEqual(@as(f64, 1.0), calculateNewStepSize(0, 1, 2, false, 1.0));
}
