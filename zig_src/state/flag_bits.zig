//! User-flag bit location -- the pure core shared by flags.zig's setUserFlag /
//! clearUserFlag / flipUserFlag.
//!
//! A user flag lives in the global-flags word bank (index = flag/16, shift =
//! flag%16), the current local-flags word (shift = flag - global count), or the
//! extra M..W bank (index = (flag-99)/16). Computing which bank and bit is pure
//! integer arithmetic; the three owner functions differ only in the bit operation
//! they apply. Lift the location logic here for native coverage -- the flags
//! owner mutates the flag words and is only reachable through the C oracle.

const std = @import("std");

/// A word-bank index plus a bit shift (shared by the global and extra banks).
pub const BankBit = struct { index: usize, shift: u4 };

/// Where a user flag's bit lives.
pub const FlagLocation = union(enum) {
    global: BankBit,
    local: struct { shift: u5 },
    extra: BankBit,
    none,
};

/// Resolve `flag` to its bit location.
pub fn flagLocation(flag: u16, flag_k: u16, last_local_flag: u16, num_global_flags: u16, num_local_flags: u16, flag_m: u16, flag_w: u16) FlagLocation {
    if (flag <= flag_k) {
        return .{ .global = .{ .index = @intCast(flag / 16), .shift = @intCast(flag % 16) } };
    }
    if (flag <= last_local_flag) {
        const local_flag = flag - num_global_flags;
        if (local_flag < num_local_flags) {
            return .{ .local = .{ .shift = @intCast(local_flag) } };
        }
        return .none;
    }
    if (flag >= flag_m and flag <= flag_w) {
        const extra_flag = flag - 99;
        return .{ .extra = .{ .index = @intCast(extra_flag / 16), .shift = @intCast(extra_flag % 16) } };
    }
    return .none;
}

// flag_k=99, last_local_flag=143, num_global=112, num_local=32, flag_m=211, flag_w=224.
fn loc(flag: u16) FlagLocation {
    return flagLocation(flag, 99, 143, 112, 32, 211, 224);
}

test "global-bank flags" {
    try std.testing.expectEqual(FlagLocation{ .global = .{ .index = 0, .shift = 5 } }, loc(5));
    try std.testing.expectEqual(FlagLocation{ .global = .{ .index = 6, .shift = 3 } }, loc(99)); // 99/16=6, 99%16=3
}

test "local-bank flags and out-of-range" {
    // flag 112 -> local_flag 0.
    try std.testing.expectEqual(FlagLocation{ .local = .{ .shift = 0 } }, loc(112));
    try std.testing.expectEqual(FlagLocation{ .local = .{ .shift = 31 } }, loc(143));
}

test "extra M..W bank and gaps" {
    // flag 211 -> extra_flag 112 -> index 7, shift 0.
    try std.testing.expectEqual(FlagLocation{ .extra = .{ .index = 7, .shift = 0 } }, loc(211));
    // A gap between local and M is none.
    try std.testing.expectEqual(FlagLocation.none, loc(200));
}
