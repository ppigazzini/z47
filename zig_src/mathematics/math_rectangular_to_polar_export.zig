const owned = @import("math_rectangular_to_polar_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_realRectangularToPolar(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.rectangularToPolarReal(real, imag, magnitude, theta, real_context);
}
