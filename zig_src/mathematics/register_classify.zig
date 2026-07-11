//! Register address-band classification -- the pure core of the predicates in
//! math_register_compare.zig.
//!
//! compareRegisters must decide which address band a register index falls in
//! (global / spare / named variable / reserved variable / local / the temp
//! slot) before it can compare two registers, and it packs the two operand type
//! IDs into a single switch key. That is pure integer arithmetic over the fixed
//! band constants plus two runtime counts (the number of allocated local
//! registers and named variables). The owner reads those two counts from
//! globals; the classification itself touches no state.
//!
//! Lifting it here gives the predicates their first native coverage -- the
//! compare owner is only reachable through the C oracle. The owner keeps thin
//! wrappers (isLocalRegister / isComparableRegister / typePair / ...) so its call
//! sites, including the many comptime typePair switch labels, are unchanged; each
//! wrapper builds a RegisterMap from the constants and the two live counts and
//! delegates here.

const std = @import("std");

/// Pack two 8-bit type IDs into one 16-bit switch key: low byte = first operand
/// (REGISTER_X) type, high byte = second operand type.
pub fn typePair(lo: u32, hi: u32) u16 {
    return @as(u16, @as(u8, @truncate(lo))) | (@as(u16, @as(u8, @truncate(hi))) << 8);
}

/// Three-way sign of a comparison value: 1 if positive, -1 if negative, 0 if 0.
pub fn cmpSign(v: i32) i32 {
    return @as(i32, @intFromBool(v > 0)) - @as(i32, @intFromBool(v < 0));
}

/// The register-address layout: the fixed band constants plus the two runtime
/// counts the owner reads from globals.
pub const RegisterMap = struct {
    /// FIRST_LOCAL_REGISTER and the live local-register count.
    first_local: u16,
    local_count: u16,
    /// FIRST_NAMED_VARIABLE and the live named-variable count.
    first_named: u16,
    named_count: u16,
    /// FIRST_RESERVED_VARIABLE .. LAST_RESERVED_VARIABLE inclusive.
    first_reserved: u16,
    last_reserved: u16,
    /// FIRST_GLOBAL_REGISTER .. LAST_SPARE_REGISTER inclusive.
    first_global: u16,
    last_spare: u16,
    /// TEMP_REGISTER_1, the one comparable temp slot.
    temp_1: u16,
};

/// A local register: [first_local, first_local + local_count) -- exclusive end.
pub fn isLocal(m: RegisterMap, r: u16) bool {
    const end_exclusive = m.first_local +% m.local_count;
    return r >= m.first_local and r < end_exclusive;
}

/// A named variable: [first_named, first_named + named_count - 1], but nothing
/// when no named variables are allocated.
pub fn isNamed(m: RegisterMap, r: u16) bool {
    if (m.named_count == 0) {
        return false;
    }
    const hi = m.first_named +% m.named_count -% 1;
    return r >= m.first_named and r <= hi;
}

/// A reserved variable: [first_reserved, last_reserved] inclusive.
pub fn isReserved(m: RegisterMap, r: u16) bool {
    return r >= m.first_reserved and r <= m.last_reserved;
}

/// A global or spare register: [first_global, last_spare] inclusive.
pub fn isGlobal(m: RegisterMap, r: u16) bool {
    return r >= m.first_global and r <= m.last_spare;
}

/// Any band that compareRegisters can address, including the single temp slot.
pub fn isComparable(m: RegisterMap, r: u16) bool {
    return isLocal(m, r) or
        isGlobal(m, r) or
        isNamed(m, r) or
        isReserved(m, r) or
        (r == m.temp_1);
}

// The real z47 register layout, used so the tests also pin the documented band
// boundaries.
const real_map = RegisterMap{
    .first_local = 7000,
    .local_count = 4,
    .first_named = 256,
    .named_count = 3,
    .first_reserved = 2000,
    .last_reserved = 2047,
    .first_global = 0,
    .last_spare = 125,
    .temp_1 = 135,
};

test "typePair packs the low and high type bytes" {
    try std.testing.expectEqual(@as(u16, 0x2211), typePair(0x11, 0x22));
    // Only the low 8 bits of each argument survive.
    try std.testing.expectEqual(@as(u16, 0xFFFF), typePair(0x1FF, 0x2FF));
    try std.testing.expectEqual(@as(u16, 0x0000), typePair(0x100, 0x200));
}

test "cmpSign is the three-way sign" {
    try std.testing.expectEqual(@as(i32, 1), cmpSign(5));
    try std.testing.expectEqual(@as(i32, -1), cmpSign(-3));
    try std.testing.expectEqual(@as(i32, 0), cmpSign(0));
}

test "isGlobal covers the global/spare band inclusively" {
    try std.testing.expect(isGlobal(real_map, 0));
    try std.testing.expect(isGlobal(real_map, 125));
    try std.testing.expect(!isGlobal(real_map, 126));
}

test "isReserved covers the reserved band inclusively" {
    try std.testing.expect(!isReserved(real_map, 1999));
    try std.testing.expect(isReserved(real_map, 2000));
    try std.testing.expect(isReserved(real_map, 2047));
    try std.testing.expect(!isReserved(real_map, 2048));
}

test "isNamed respects the live count and is empty at zero" {
    try std.testing.expect(!isNamed(real_map, 255));
    try std.testing.expect(isNamed(real_map, 256));
    try std.testing.expect(isNamed(real_map, 258));
    try std.testing.expect(!isNamed(real_map, 259));
    // With no named variables allocated the band is empty.
    var empty = real_map;
    empty.named_count = 0;
    try std.testing.expect(!isNamed(empty, 256));
}

test "isLocal has an exclusive upper bound" {
    try std.testing.expect(!isLocal(real_map, 6999));
    try std.testing.expect(isLocal(real_map, 7000));
    try std.testing.expect(isLocal(real_map, 7003));
    try std.testing.expect(!isLocal(real_map, 7004));
}

test "isComparable unions every band plus the temp slot" {
    try std.testing.expect(isComparable(real_map, 10)); // global
    try std.testing.expect(isComparable(real_map, 257)); // named
    try std.testing.expect(isComparable(real_map, 2001)); // reserved
    try std.testing.expect(isComparable(real_map, 7001)); // local
    try std.testing.expect(isComparable(real_map, 135)); // temp slot
    // A gap between the spare and named bands is not comparable.
    try std.testing.expect(!isComparable(real_map, 200));
    // A gap between named and reserved bands is not comparable.
    try std.testing.expect(!isComparable(real_map, 1000));
}
