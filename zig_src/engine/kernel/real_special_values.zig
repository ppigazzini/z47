// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the real_t special-value setters from src/c47/realType.c:
// realSetZero / realSetOne / realSetNaN / realSetPlusInfinity /
// realSetMinusInfinity. These construct a real_t directly from its decNumber
// coefficient/exponent/bits fields with no runtime coupling -- they touch only
// the caller's real_t, so they belong in the headless base kernel rather than
// the shell. The int-conversion helpers that share realType.c stay on the shell
// owner for now because they route through the register_value_conversions
// god-adapter; only the pure constructors move here.
//
// The testSuite exercises these pervasively (every math path that seeds a NaN,
// zero, one, or infinity), which is the behavioral parity gate for the port.

const abi = @import("abi"); // shared ABI bindings
const real_t = abi.Real;

// decNumber field bits (decNumberLocal.h): sign, infinity, NaN.
const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;

pub export fn realSetZero(r: *real_t) callconv(.c) void {
    r.bits = 0;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}

pub export fn realSetOne(r: *real_t) callconv(.c) void {
    r.bits = 0;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 1;
}

pub export fn realSetNaN(r: *real_t) callconv(.c) void {
    r.bits = DECNAN;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}

pub export fn realSetPlusInfinity(r: *real_t) callconv(.c) void {
    r.bits = DECINF;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}

pub export fn realSetMinusInfinity(r: *real_t) callconv(.c) void {
    r.bits = DECINF | DECNEG;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}

const std = @import("std");
const testing = std.testing;

test "realSetZero/One seed a finite coefficient with clear flag bits" {
    var r: real_t = undefined;
    realSetZero(&r);
    try testing.expectEqual(@as(u8, 0), r.bits);
    try testing.expectEqual(@as(u16, 0), r.lsu[0]);
    try testing.expectEqual(@as(i32, 1), r.digits);

    realSetOne(&r);
    try testing.expectEqual(@as(u8, 0), r.bits);
    try testing.expectEqual(@as(u16, 1), r.lsu[0]);
}

test "special-value setters set the decNumber flag bits" {
    var r: real_t = undefined;
    realSetNaN(&r);
    try testing.expectEqual(DECNAN, r.bits);
    realSetPlusInfinity(&r);
    try testing.expectEqual(DECINF, r.bits);
    realSetMinusInfinity(&r);
    try testing.expectEqual(@as(u8, DECINF | DECNEG), r.bits);
}
