const std = @import("std");

const DECNUMUNITS = 25;

pub const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

pub fn zeroReal() real_t {
    return .{
        .digits = 1,
        .exponent = 0,
        .bits = 0,
        .lsu = std.mem.zeroes([DECNUMUNITS]u16),
    };
}

pub fn realFromBoolean(value: bool) real_t {
    var result = zeroReal();
    result.lsu[0] = @intFromBool(value);
    return result;
}

pub fn isRealZero(value: *const real_t, dec_special: u8) bool {
    return value.digits == 1 and value.lsu[0] == 0 and (value.bits & dec_special) == 0;
}