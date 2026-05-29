const owned = @import("math_real_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_C47_WP34S_Asin(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.arcsinReal(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Acos(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.arccosReal(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_SinhCosh(
    x: *const runtime.real_t,
    sinh_out: ?*runtime.real_t,
    cosh_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.sinhCoshReal(x, sinh_out, cosh_out, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_Tanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.tanhReal(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcSinh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.arcsinhReal(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcTanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.arctanhReal(x, res, real_context);
}