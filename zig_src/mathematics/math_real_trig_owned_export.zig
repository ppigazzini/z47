const owned = @import("math_real_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_C47_WP34S_Asin(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.c47Wp34sAsinZig(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_C47_WP34S_Acos(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.c47Wp34sAcosZig(x, angle, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_SinhCosh(
    x: *const runtime.real_t,
    sinh_out: ?*runtime.real_t,
    cosh_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.wp34sSinhCoshZig(x, sinh_out, cosh_out, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_Tanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.wp34sTanhZig(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcSinh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.wp34sArcSinhZig(x, res, real_context);
}

pub export fn z47_math_wrappers_owned_WP34S_ArcTanh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.wp34sArcTanhZig(x, res, real_context);
}