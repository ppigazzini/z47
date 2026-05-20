const build_options = @import("math_command_wrappers_build_options");
const atan_owned = @import("math_atan_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn setSignedAngle(destination: *runtime.real_t, angle: *const runtime.real_t, negative: bool) void {
    copyReal(destination, angle);
    if (negative and !runtime.realIsZero(destination)) {
        runtime.realChangeSign(destination);
    }
}

pub fn c47Wp34sAtan2Zig(
    y: *const runtime.real_t,
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var reduced: runtime.real_t = undefined;
    var offset: runtime.real_t = undefined;
    const x_negative = runtime.realIsNegative(x);
    const y_negative = runtime.realIsNegative(y);

    if (build_options.use_fake_wp34s_model or real_context.digits != runtime.ctxtReal39.digits) {
        runtime.C47_WP34S_Atan2(y, x, angle, real_context);
        return;
    }

    if (runtime.realIsNaN(x) or runtime.realIsNaN(y)) {
        runtime.realSetNaN(angle);
        return;
    }

    if (runtime.realCompareEqual(y, runtime.z47_math_wrappers_const_0())) {
        if (y_negative) {
            if (runtime.realCompareEqual(x, runtime.z47_math_wrappers_const_0())) {
                if (x_negative) {
                    setSignedAngle(angle, runtime.z47_math_wrappers_const_pi(), true);
                } else {
                    copyReal(angle, y);
                }
            } else if (x_negative) {
                setSignedAngle(angle, runtime.z47_math_wrappers_const_pi(), true);
            } else {
                copyReal(angle, y);
            }
        } else {
            if (runtime.realCompareEqual(x, runtime.z47_math_wrappers_const_0())) {
                if (x_negative) {
                    copyReal(angle, runtime.z47_math_wrappers_const_pi());
                } else {
                    runtime.realSetZero(angle);
                }
            } else if (x_negative) {
                copyReal(angle, runtime.z47_math_wrappers_const_pi());
            } else {
                runtime.realSetZero(angle);
            }
        }
        return;
    }

    if (runtime.realCompareEqual(x, runtime.z47_math_wrappers_const_0())) {
        setSignedAngle(angle, runtime.z47_math_wrappers_const_piOn2(), y_negative);
        return;
    }

    if (runtime.realIsInfinite(x)) {
        if (x_negative) {
            if (runtime.realIsInfinite(y)) {
                setSignedAngle(angle, runtime.z47_math_wrappers_const_3piOn4(), y_negative);
            } else {
                setSignedAngle(angle, runtime.z47_math_wrappers_const_pi(), y_negative);
            }
        } else {
            if (runtime.realIsInfinite(y)) {
                setSignedAngle(angle, runtime.z47_math_wrappers_const_piOn4(), y_negative);
            } else {
                runtime.realSetZero(angle);
                if (y_negative) {
                    runtime.realChangeSign(angle);
                }
            }
        }
        return;
    }

    if (runtime.realIsInfinite(y)) {
        setSignedAngle(angle, runtime.z47_math_wrappers_const_piOn2(), y_negative);
        return;
    }

    runtime.realDivide(y, x, &offset, real_context);
    atan_owned.c47Wp34sAtanZig(&offset, &reduced, real_context);
    if (x_negative) {
        setSignedAngle(&offset, runtime.z47_math_wrappers_const_pi(), y_negative);
    } else {
        runtime.realSetZero(&offset);
    }

    runtime.realAdd(&reduced, &offset, angle, real_context);
    if (runtime.realCompareEqual(angle, runtime.z47_math_wrappers_const_0()) and y_negative) {
        runtime.realChangeSign(angle);
    }
}
