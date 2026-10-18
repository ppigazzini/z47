const build_options = @import("math_command_wrappers_build_options");
const atan2_owned = @import("../trig/atan2.zig");
const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const displayBugScreen = abi.host.showBugScreen; // routed through the host-callback boundary

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

// The angle of a finite nonzero imaginary part beside an infinite real part is
// 0 or pi with the sign of that part, so -0 and -pi name the lower half-plane.
fn setHalfPlaneAngle(destination: *runtime.real_t, angle: *const runtime.real_t, imag: *const runtime.real_t) void {
    copyReal(destination, angle);
    if (!runtime.realIsZero(imag) and runtime.realIsNegative(imag)) {
        destination.bits |= 0x80;
    }
}

pub fn rectangularToPolarReal(
    z: *const runtime.cplx_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.realRectangularToPolar(z, magnitude, theta, real_context);
        return;
    }

    copyReal(&real_value, &z.Real);
    copyReal(&imag_value, &z.Imag);

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
                setHalfPlaneAngle(theta, runtime.z47_math_wrappers_const_0(), &imag_value);
            }
        } else {
            if (runtime.realIsInfinite(&imag_value)) {
                setSignedAngle(theta, runtime.z47_math_wrappers_const_3piOn4(), runtime.realIsNegative(&imag_value));
            } else {
                setHalfPlaneAngle(theta, runtime.z47_math_wrappers_const_pi(), &imag_value);
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

    // The conversion is only correct up to 75 digits; a wider context is a
    // caller bug, and the C says so rather than computing.
    if (real_context.digits > 75) {
        displayBugScreen("In function realRectangularToPolar: The number of digits is > 75");
        return;
    }

    runtime.realMultiply(&real_value, &real_value, magnitude, real_context);
    runtime.realFMA(&imag_value, &imag_value, magnitude, magnitude, real_context);
    runtime.realSquareRoot(magnitude, magnitude, real_context);
    atan2_owned.arctan2Real(&imag_value, &real_value, theta, real_context);
}
