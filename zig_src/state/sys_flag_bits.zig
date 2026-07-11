//! System-flag bit location -- the pure core shared by flags.zig's
//! setSystemFlagBit / clearSystemFlagBit / flipSystemFlagBit.
//!
//! A masked system-flag index selects one of the two 64-bit flag words and a bit
//! shift within it. Computing which word and shift is pure arithmetic; the owner
//! mutates the flag words and their change-masks. Lift it here for native
//! coverage.

const std = @import("std");

/// Which flag word (0 or 1) and bit shift a masked flag index selects.
pub const SysFlagBit = struct { word: u1, shift: u6 };

pub fn systemFlagBitLocation(masked_flag: i32) SysFlagBit {
    if (masked_flag < 64) {
        return .{ .word = 0, .shift = @intCast(masked_flag) };
    }
    return .{ .word = 1, .shift = @intCast(masked_flag - 64) };
}

test "the first 64 flags live in word 0, the rest in word 1" {
    try std.testing.expectEqual(SysFlagBit{ .word = 0, .shift = 0 }, systemFlagBitLocation(0));
    try std.testing.expectEqual(SysFlagBit{ .word = 0, .shift = 63 }, systemFlagBitLocation(63));
    try std.testing.expectEqual(SysFlagBit{ .word = 1, .shift = 0 }, systemFlagBitLocation(64));
    try std.testing.expectEqual(SysFlagBit{ .word = 1, .shift = 63 }, systemFlagBitLocation(127));
}
