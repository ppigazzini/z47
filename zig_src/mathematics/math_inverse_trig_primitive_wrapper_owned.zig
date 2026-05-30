const inverse_trig_command_owned = @import("math_inverse_trig_command_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub fn ArcsinComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArctanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhReal(x, res, real_context);
}

pub fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    inverse_trig_command_owned.realArcosh(x, res, real_context);
}
