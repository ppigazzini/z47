const runtime = @import("../command_wrappers/runtime.zig");

// Store the interpolation in X with the type and tag of Y. `exact_result`, when
// given, is the exactly formed real result and replaces the real part of
// `result` for a plain real register.
pub fn writeResult(
    type_y: u32,
    is_y_angle: bool,
    is_z_angle: bool,
    data_tag_y: runtime.angularMode_t,
    data_tag_z: runtime.angularMode_t,
    real_coefs: bool,
    result: *const runtime.cplx_t,
    exact_result: ?*const runtime.real_t,
) void {
    var output_tag = data_tag_y;

    if (real_coefs) {
        if (type_y == runtime.dtTime) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(&result.Real, runtime.REGISTER_X);
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        } else if (type_y == runtime.dtDate) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
            runtime.realToReal34(&result.Real, runtime.registerReal34Ptr(runtime.REGISTER_X));
            runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.DEC_ROUND_CEILING);
            runtime.julianDayToInternalDate(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
        } else {
            if (is_y_angle and is_z_angle) {
                if (output_tag != data_tag_z) {
                    output_tag = runtime.currentAngularMode;
                }
            } else {
                output_tag = runtime.amNone;
            }

            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @as(u32, @intCast(output_tag)));
            if (exact_result) |exact| {
                runtime.convertRealToReal34ResultRegister(exact, runtime.REGISTER_X);
            } else {
                runtime.convertRealToReal34ResultRegister(&result.Real, runtime.REGISTER_X);
            }
        }

        return;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(result, runtime.REGISTER_X);
}
