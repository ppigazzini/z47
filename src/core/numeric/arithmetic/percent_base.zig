const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn percent(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);
    var register_y = std.mem.zeroes(runtime.real_t);
    var result = std.mem.zeroes(runtime.real_t);
    var exact_result: runtime.real34_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    // The product of a long integer and a finite value is exact where the
    // scaled coefficients fit a real34.
    const exact_product = (type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and
        runtime.multiplyRegisterValuesToReal34Scaled(runtime.REGISTER_X, runtime.REGISTER_Y, -2, &exact_result);

    if (!exact_product and (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &register_y))) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    if (exact_product) {
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = exact_result;
    } else {
        register_x.exponent -= 2; // xReal = xReal / 100.0
        runtime.realMultiply(&register_x, &register_y, &result, &runtime.ctxtReal34); // rReal = xReal * yReal / 100.0
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}
