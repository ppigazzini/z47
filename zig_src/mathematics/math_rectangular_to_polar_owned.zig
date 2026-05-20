const build_options = @import("math_command_wrappers_build_options");
const atan2_owned = @import("math_atan2_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

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

pub fn realRectangularToPolarZig(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (build_options.use_fake_wp34s_model) {
        runtime.realRectangularToPolar(real, imag, magnitude, theta, real_context);
        return;
    }

    if (runtime.realIsNaN(real) or runtime.realIsNaN(imag)) {
        runtime.realSetNaN(magnitude);
        runtime.realSetNaN(theta);
        return;
    }

    if (runtime.realIsInfinite(real)) {
        setPlusInfinity(magnitude);
        if (!runtime.realIsNegative(real)) {
            if (runtime.realIsInfinite(imag)) {
                setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn4(), runtime.realIsNegative(imag));
            } else {
                runtime.realSetZero(theta);
            }
        } else {
            if (runtime.realIsInfinite(imag)) {
                setSignedAngle(theta, runtime.z47_math_wrappers_const_3piOn4(), runtime.realIsNegative(imag));
            } else {
                copyReal(theta, runtime.z47_math_wrappers_const_pi());
            }
        }
        return;
    }

    if (runtime.realIsInfinite(imag)) {
        setPlusInfinity(magnitude);
        setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn2(), runtime.realIsNegative(imag));
        return;
    }

    if (runtime.realIsZero(real)) {
        if (runtime.realIsZero(imag)) {
            runtime.realSetZero(magnitude);
            runtime.realSetZero(theta);
        } else {
            copyAbs(magnitude, imag);
            setSignedAngle(theta, runtime.z47_math_wrappers_const_piOn2(), runtime.realIsNegative(imag));
        }
        return;
    }

    if (runtime.realIsZero(imag)) {
        copyAbs(magnitude, real);
        if (runtime.realIsNegative(real)) {
            copyReal(theta, runtime.z47_math_wrappers_const_pi());
        } else {
            runtime.realSetZero(theta);
        }
        return;
    }

    runtime.realMultiply(real, real, magnitude, real_context);
    runtime.realFMA(imag, imag, magnitude, magnitude, real_context);
    runtime.realSquareRoot(magnitude, magnitude, real_context);
    atan2_owned.c47Wp34sAtan2Zig(imag, real, theta, real_context);
}
