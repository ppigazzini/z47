const build_options = @import("math_command_wrappers_build_options");
const ln_complex_owned = @import("math_ln_complex.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn logWithLnBase(
    x_in: *const runtime.real_t,
    base: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var y: runtime.real_t = undefined;

    if (runtime.realIsSpecial(x_in)) {
        if (runtime.realIsNaN(x_in) or runtime.realIsNegative(x_in)) {
            runtime.realSetNaN(res);
        } else {
            copyReal(res, runtime.z47_math_wrappers_const_plus_infinity());
        }
        return;
    }

    ln_complex_owned.lnRealValue(x_in, &y, real_context);
    runtime.realDivide(&y, base, res, real_context);
}

pub fn logxyRealValue(
    y_in: *const runtime.real_t,
    x_in: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Logxy(y_in, x_in, res, real_context);
        return;
    }

    var ln_x: runtime.real_t = undefined;

    ln_complex_owned.lnRealValue(x_in, &ln_x, real_context);
    logWithLnBase(y_in, &ln_x, res, real_context);
}
