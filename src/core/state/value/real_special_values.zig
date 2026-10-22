// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the real_t special-value setters from src/c47/realType.c:
// realSetZero / realSetOne / realSetNegativeOne / realSetNaN /
// realSetPlusInfinity / realSetMinusInfinity, and the C-ABI symbols of its value
// helpers realIsZero / copyComplex34 / setReal34NegativeSign, whose one
// definition is in abi so the Zig owners share it. These construct or inspect a
// real_t directly from its decNumber coefficient/exponent/bits fields with no
// runtime coupling -- they touch only the caller's value, so they belong in the
// headless base kernel rather than the shell. The int-conversion helpers that share realType.c stay on the shell
// owner for now because they route through the register_value_conversions
// god-adapter; only the pure constructors move here.
//
// The testSuite exercises these pervasively (every math path that seeds a NaN,
// zero, one, or infinity), which is the behavioral parity gate for the port.

const abi = @import("abi"); // shared ABI bindings
const real_t = abi.Real;
const real34_t = abi.Real34;

// decNumber field bits (decNumberLocal.h): sign, infinity, NaN.
const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;

pub export fn realIsZero(r: *const real_t) bool {
    return abi.realIsZero(r);
}

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

pub export fn realSetNegativeOne(r: *real_t) callconv(.c) void {
    r.bits = DECNEG;
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

// The real part and the imaginary part of a complex34, which upstream addresses
// as two consecutive real34_t.
pub export fn copyComplex34(source: *const [2]real34_t, destination: *[2]real34_t) void {
    abi.complex34Copy(@ptrCast(source), @ptrCast(destination));
}

pub export fn setReal34NegativeSign(r: *real34_t) void {
    abi.real34SetNegativeSign(r);
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

    realSetNegativeOne(&r);
    try testing.expectEqual(DECNEG, r.bits);
    try testing.expectEqual(@as(i32, 0), r.exponent);
    try testing.expectEqual(@as(i32, 1), r.digits);
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
