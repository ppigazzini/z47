//! Register-shuffle order decode -- the pure core of stack_descriptor's shuffle.
//!
//! A shuffle packs four 2-bit source-register offsets into a u16 (slot i at bit
//! i*2). Unpacking the four offsets is pure bit arithmetic; the owner performs
//! the descriptor swaps and copies. Lift the decode here for native coverage.

const std = @import("std");

/// The four 2-bit source offsets packed in `regist_order`.
pub fn shuffleOrder(regist_order: u16) [4]u16 {
    var out: [4]u16 = undefined;
    var i: u16 = 0;
    while (i < 4) : (i += 1) {
        out[i] = (regist_order >> @intCast(i * 2)) & 3;
    }
    return out;
}

test "shuffleOrder unpacks the 2-bit slots" {
    // 0xE4 = 11_10_01_00 -> slots 0,1,2,3.
    try std.testing.expectEqual([4]u16{ 0, 1, 2, 3 }, shuffleOrder(0xE4));
    try std.testing.expectEqual([4]u16{ 0, 0, 0, 0 }, shuffleOrder(0));
    // 0x1B = 00_01_10_11 -> slots 3,2,1,0.
    try std.testing.expectEqual([4]u16{ 3, 2, 1, 0 }, shuffleOrder(0x1B));
}
