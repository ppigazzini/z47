const runtime = @import("math_command_wrappers_runtime.zig");

pub fn writeResult(
    type_y: u32,
    is_y_angle: bool,
    is_z_angle: bool,
    data_tag_y: runtime.angularMode_t,
    data_tag_z: runtime.angularMode_t,
    real_coefs: bool,
    result_real: *const runtime.real_t,
    result_imag: *const runtime.real_t,
) void {
    var output_tag = data_tag_y;

    if (real_coefs) {
        if (type_y == runtime.dtTime) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(result_real, runtime.REGISTER_X);
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        } else if (type_y == runtime.dtDate) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
            runtime.realToReal34(result_real, runtime.registerReal34Ptr(runtime.REGISTER_X));
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
            runtime.convertRealToReal34ResultRegister(result_real, runtime.REGISTER_X);
        }

        return;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(result_real, result_imag, runtime.REGISTER_X);
}
