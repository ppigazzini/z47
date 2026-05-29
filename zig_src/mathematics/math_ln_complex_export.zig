const owned = @import("math_ln_complex_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub export fn z47_math_wrappers_owned_lnComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    owned.lnComplex(real, imag, ln_real, ln_imag, real_context);
}