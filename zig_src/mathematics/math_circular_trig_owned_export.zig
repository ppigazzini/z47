const owned = @import("math_circular_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_C47_WP34S_Cvt2RadSinCosTan(
    angle: *const runtime.real_t,
    mode: runtime.angularMode_t,
    sin: ?*runtime.real_t,
    cos: ?*runtime.real_t,
    tan: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.c47Wp34sCvt2RadSinCosTanZig(angle, mode, sin, cos, tan, real_context);
}