const owned = @import("math_atan2_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_C47_WP34S_Atan2(
    y: *const runtime.real_t,
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.arctan2Real(y, x, angle, real_context);
}
