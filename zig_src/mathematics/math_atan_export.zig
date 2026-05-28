const owned = @import("math_atan_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_C47_WP34S_Atan(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.c47Wp34sAtanZig(x, angle, real_context);
}