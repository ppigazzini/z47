//! Store-path register-range validity -- the pure core of frontier_store's
//! isRegInRange.
//!
//! A STO/RCL target is valid only inside one of the register bands: the lettered
//! range (r00..r99 and X..K), the stat range, the spare range, the live local
//! and named-variable ranges, the reserved range, or the temp range. Membership
//! is pure interval arithmetic over the band constants and the two live counts.
//! Lift it here for native coverage -- the store owner is only reachable through
//! the C oracle.

const std = @import("std");

/// The register-band layout: fixed band bounds plus the two live counts.
pub const StoreBands = struct {
    last_lettered: u16,
    first_stat: u16,
    last_stat: u16,
    first_spare: u16,
    last_spare: u16,
    first_local: u16,
    local_count: u16,
    first_named: u16,
    named_count: u16,
    first_reserved: u16,
    last_reserved: u16,
    first_temp: u16,
    last_temp: u16,
};

/// Whether `regist` falls inside any valid band.
pub fn isRegInRange(regist: u16, b: StoreBands) bool {
    return (regist <= b.last_lettered) or
        (b.first_stat <= regist and regist <= b.last_stat) or
        (b.first_spare <= regist and regist <= b.last_spare) or
        (b.first_local <= regist and @as(i32, regist) < @as(i32, b.first_local) + @as(i32, b.local_count)) or
        (b.first_named <= regist and @as(i32, regist) < @as(i32, b.first_named) + @as(i32, b.named_count)) or
        (b.first_reserved <= regist and regist <= b.last_reserved) or
        (b.first_temp <= regist and regist <= b.last_temp);
}

const test_bands = StoreBands{
    .last_lettered = 99,
    .first_stat = 100,
    .last_stat = 105,
    .first_spare = 106,
    .last_spare = 125,
    .first_local = 7000,
    .local_count = 4,
    .first_named = 256,
    .named_count = 3,
    .first_reserved = 2000,
    .last_reserved = 2047,
    .first_temp = 135,
    .last_temp = 136,
};

fn valid(reg: u16) bool {
    return isRegInRange(reg, test_bands);
}

test "each band is accepted" {
    try std.testing.expect(valid(0)); // lettered
    try std.testing.expect(valid(99));
    try std.testing.expect(valid(102)); // stat
    try std.testing.expect(valid(110)); // spare
    try std.testing.expect(valid(7003)); // local (count 4)
    try std.testing.expect(valid(258)); // named (count 3)
    try std.testing.expect(valid(2047)); // reserved
    try std.testing.expect(valid(135)); // temp
}

test "gaps and past-the-count are rejected" {
    try std.testing.expect(!valid(200)); // between spare and temp/named
    try std.testing.expect(!valid(1000)); // between named and reserved
    try std.testing.expect(!valid(7004)); // past the live local count
    try std.testing.expect(!valid(259)); // past the live named count
}
