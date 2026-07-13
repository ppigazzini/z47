// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/realType.c: real_t <-> integer conversions and the
// real_t special-value setters. These are low-level helpers called directly
// throughout c47 (and bound by the distribution runtime), so they are exported
// with C linkage. The testSuite exercises them pervasively, which is the parity
// gate for this port.

const DECNUMUNITS = 25;
const DECDPUN = 3;

const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSPECIAL: u8 = 0x70;

// decContext.h rounding enum order: CEILING,UP,HALF_UP,HALF_EVEN,HALF_DOWN,DOWN,..
const DEC_ROUND_DOWN: c_int = 5;

const abi = @import("abi"); // shared ABI bindings
const real_t = abi.Real;

const realContext_t = abi.RealContext;

extern var ctxtReal39: realContext_t;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void;

inline fn realIsSpecial(r: *const real_t) bool {
    return (r.bits & DECSPECIAL) != 0;
}
inline fn realIsNegative(r: *const real_t) bool {
    return (r.bits & DECNEG) != 0;
}

fn realToInt(r: *const real_t, magnitude_limit: u64, round: c_int, err: ?*bool) u64 {
    if (realIsSpecial(r)) {
        return 0;
    }

    var integer: real_t = undefined;
    realToIntegralValue(r, &integer, round, &ctxtReal39);

    var value: u64 = 0;
    var i: i32 = @divTrunc(integer.digits - 1, DECDPUN);
    while (i >= 0) : (i -= 1) {
        value = value * 1000 + integer.lsu[@intCast(i)]; // 1000 = 10^DECDPUN
        if (value > magnitude_limit) {
            return 0;
        }
    }

    var e: i32 = integer.exponent;
    while (e > 0) : (e -= 1) {
        value *= 10;
        if (value > magnitude_limit) {
            return 0;
        }
    }

    if (err) |ep| ep.* = false;
    return value;
}

pub export fn realToInt32C47(r: *const real_t, err: ?*bool) callconv(.c) i32 {
    const sign = realIsNegative(r);
    const magnitude_limit: u64 = @as(u64, 2147483647) + @intFromBool(sign); // INT32_MAX (+1 if negative)
    if (err) |ep| ep.* = true;
    const value: i64 = @intCast(realToInt(r, magnitude_limit, DEC_ROUND_DOWN, err));
    return if (sign) @intCast(-value) else @intCast(value);
}

pub export fn realToUint32C47(r: *const real_t, err: ?*bool) callconv(.c) u32 {
    if (err) |ep| ep.* = true;

    if (realIsNegative(r)) {
        return 0;
    }

    const magnitude_limit: u64 = 4294967295; // UINT32_MAX
    return @intCast(realToInt(r, magnitude_limit, DEC_ROUND_DOWN, err));
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
