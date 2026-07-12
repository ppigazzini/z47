const build_options = @import("math_command_wrappers_build_options");
const atan2_owned = @import("../trig/atan2.zig");
const runtime = @import("../command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn copyAbs(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realSetPositiveSign(destination);
}

fn setPlusInfinity(destination: *runtime.real_t) void {
    copyReal(destination, runtime.z47_math_wrappers_const_plus_infinity());
}

fn setSignedAngle(destination: *runtime.real_t, angle: *const runtime.real_t, negative: bool) void {
    copyReal(destination, angle);
    if (negative and !runtime.realIsZero(destination)) {
        runtime.realChangeSign(destination);
    }
}

pub fn rectangularToPolarReal(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.realRectangularToPolar(real, imag, magnitude, theta, real_context);
        return;
    }

    copyReal(&real_value, real);
    copyReal(&imag_value, imag);

    if (runtime.realIsNaN(&real_value) or runtime.realIsNaN(&imag_value)) {
        runtime.realSetNaN(magnitude);
        runtime.realSetNaN(theta);
        return;
    }

    if (runtime.realIsInfinite(&real_value)) {
        setPlusInfinity(magnitude);
        if (!runtime.realIsNegative(&real_value)) {
            if (runtime.realIsInfinite(&imag_value)) {
                setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn4(), runtime.realIsNegative(&imag_value));
            } else {
                runtime.realSetZero(theta);
            }
        } else {
            if (runtime.realIsInfinite(&imag_value)) {
                setSignedAngle(theta, runtime.z47_math_wrappers_const_3piOn4(), runtime.realIsNegative(&imag_value));
            } else {
                copyReal(theta, runtime.z47_math_wrappers_const_pi());
            }
        }
        return;
    }

    if (runtime.realIsInfinite(&imag_value)) {
        setPlusInfinity(magnitude);
        setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn2(), runtime.realIsNegative(&imag_value));
        return;
    }

    if (runtime.realIsZero(&real_value)) {
        if (runtime.realIsZero(&imag_value)) {
            runtime.realSetZero(magnitude);
            runtime.realSetZero(theta);
        } else {
            copyAbs(magnitude, &imag_value);
            setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn2(), runtime.realIsNegative(&imag_value));
        }
        return;
    }

    if (runtime.realIsZero(&imag_value)) {
        copyAbs(magnitude, &real_value);
        if (runtime.realIsNegative(&real_value)) {
            copyReal(theta, runtime.z47_math_wrappers_const_pi());
        } else {
            runtime.realSetZero(theta);
        }
        return;
    }

    runtime.realMultiply(&real_value, &real_value, magnitude, real_context);
    runtime.realFMA(&imag_value, &imag_value, magnitude, magnitude, real_context);
    runtime.realSquareRoot(magnitude, magnitude, real_context);
    atan2_owned.arctan2Real(&imag_value, &real_value, theta, real_context);
}
