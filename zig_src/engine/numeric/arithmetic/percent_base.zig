const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn percent(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);
    var register_y = std.mem.zeroes(runtime.real_t);
    var result = std.mem.zeroes(runtime.real_t);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &register_y)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.realMultiply(&register_x, &register_y, &result, &runtime.ctxtReal34);
    result.exponent -= 2;

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}
