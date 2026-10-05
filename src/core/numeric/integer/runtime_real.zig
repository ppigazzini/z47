const std = @import("std");

pub fn zeroReal(comptime RealType: type) RealType {
    return .{
        .digits = 1,
        .exponent = 0,
        .bits = 0,
        .lsu = @splat(0),
    };
}

pub fn realFromBoolean(comptime RealType: type, value: bool) RealType {
    var result = zeroReal(RealType);
    result.lsu[0] = @intFromBool(value);
    return result;
}

pub fn isRealZero(value: anytype, dec_special: u8) bool {
    return value.digits == 1 and value.lsu[0] == 0 and (value.bits & dec_special) == 0;
}
