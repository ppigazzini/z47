//! Zig owners for the transform/complex helper symbols ported from the upstream
//! C47 sources src/c47/mathematics/toPolar.c, toRect.c, squareRoot.c,
//! cubeRoot.c, and unitVector.c.
//!
//! This file is only referenced from math_command_wrappers.zig when the build
//! does NOT use the fake harness surface: the parity harness links
//! build/tests/math_wrappers/math_wrappers_fake_runtime.c which already
//! defines sqrtComplex/realRectangularToPolar/realPolarToRectangular/
//! unitVectorCplx, so these exports must stay out of that link.

const std = @import("std");
const abi = @import("abi");
const atan2_owned = @import("../trig/atan2.zig");
const runtime = @import("../command_wrappers/runtime.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const wrappers = @import("../command_wrappers.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const cplx159_t = runtime.cplx159_t;

// squareRoot.c compiles sqrtComplex159 under `OPTION_SQUARE_159 ||
// OPTION_CUBIC_159 || OPTION_EIGEN_159`; cubeRoot.c compiles curtComplex159 under
// `OPTION_CUBIC_159 || OPTION_EIGEN_159`. OPTION_SQUARE_159 is #undef'd at the
// top of defines.h and never defined again in any configuration, so both
// conditions are the same two terms. Without them the 159-digit bodies leave the
// image; the 75-digit sqrtComplex and curtComplex stay whatever the options.
const arm_159 = runtime.option_cubic_159 or runtime.option_eigen_159;

// Upstream realType.c functions (canonical symbols in the product link).
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
// decNumber functions behind the upstream realCopy/realMinus macros
// (src/c47/realType.h: realCopy -> decNumberCopy, realMinus -> decNumberMinus).
extern fn decNumberCopy(destination: *real_t, source: *const real_t) *real_t;
extern fn decNumberMinus(result: *real_t, rhs: *const real_t, real_context: *runtime.realContext_t) *real_t;

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

fn copyAbs(destination: *real_t, source: *const real_t) void {
    copyReal(destination, source);
    runtime.realSetPositiveSign(destination);
}

fn realSetNegativeSign(value: *real_t) void {
    value.bits |= 0x80;
}

const realIsPositive = math_real_predicates.realIsPositive;

// realDivideBy2(op, ctxt) is the upstream macro decNumberMultiply(op, op, const_1on2, ctxt).
fn realDivideBy2(operand: *real_t, real_context: *runtime.realContext_t) void {
    runtime.realMultiply(operand, runtime.z47_math_wrappers_const_1on2(), operand, real_context);
}

// Storage for one 159-digit decNumber (REAL_T_PTR(name, 159), 116 bytes); layout
// centralized in abi (size asserted there).
const Real159 = abi.Real159;

fn real159(storage: *Real159) *real_t {
    return @ptrCast(storage);
}

// ----------------------------------------------------------------------------
// toPolar.c
// ----------------------------------------------------------------------------

pub export fn fnToPolar_HP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const flag_hprp_mem = runtime.getSystemFlag(runtime.FLAG_HPRP);
    runtime.setSystemFlag(runtime.FLAG_HPRP);
    wrappers.fnToPolar2(runtime.NOPARAM);
    if (!flag_hprp_mem) {
        runtime.clearSystemFlag(runtime.FLAG_HPRP);
    }
}

pub export fn fnToPolar_CX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const flag_hprp_mem = runtime.getSystemFlag(runtime.FLAG_HPRP);
    runtime.clearSystemFlag(runtime.FLAG_HPRP);
    wrappers.fnToPolar2(runtime.NOPARAM);
    if (flag_hprp_mem) {
        runtime.setSystemFlag(runtime.FLAG_HPRP);
    }
}

// The theta34 output angle is in radian.
pub export fn real34RectangularToPolar(
    real34: *const runtime.real34_t,
    imag34: *const runtime.real34_t,
    magnitude34: *runtime.real34_t,
    theta34: *runtime.real34_t,
) callconv(.c) void {
    var z: cplx_t = undefined;

    runtime.real34ToReal(real34, &z.Real);
    runtime.real34ToReal(imag34, &z.Imag);

    rectangularToPolarReal(&z, z.mag(), z.arg(), &runtime.ctxtReal39); // theta in radian

    runtime.realToReal34(z.constMag(), magnitude34);
    runtime.realToReal34(z.constArg(), theta34);
}

// theta is in ]-pi, pi]. z may alias the outputs: both parts are copied first.
fn rectangularToPolarReal(
    z: *const cplx_t,
    magnitude: *real_t,
    theta: *real_t,
    real_context: *runtime.realContext_t,
) void {
    var re: real_t = undefined;
    var im: real_t = undefined;

    copyReal(&re, &z.Real);
    copyReal(&im, &z.Imag);

    // Testing NaNs
    if (runtime.realIsNaN(&re) or runtime.realIsNaN(&im)) {
        runtime.realSetNaN(magnitude);
        runtime.realSetNaN(theta);
        return;
    }

    // Real part is infinite: the angle is 0 or pi with the sign of a finite
    // nonzero imaginary part, so -0 and -pi name the lower half-plane.
    if (runtime.realIsInfinite(&re)) {
        realSetPlusInfinity(magnitude);

        if (realIsPositive(&re)) {
            if (runtime.realIsInfinite(&im)) {
                copyReal(theta, runtime.z47_math_wrappers_const_piOn4());
                if (runtime.realIsNegative(&im)) {
                    realSetNegativeSign(theta);
                }
            } else {
                runtime.realSetZero(theta);
                if (!runtime.realIsZero(&im) and runtime.realIsNegative(&im)) {
                    realSetNegativeSign(theta);
                }
            }
        } else {
            if (runtime.realIsInfinite(&im)) {
                copyReal(theta, runtime.z47_math_wrappers_const_3piOn4());
                if (runtime.realIsNegative(&im)) {
                    realSetNegativeSign(theta);
                }
            } else {
                copyReal(theta, runtime.z47_math_wrappers_const_pi());
                if (!runtime.realIsZero(&im) and runtime.realIsNegative(&im)) {
                    realSetNegativeSign(theta);
                }
            }
        }

        return;
    }

    // Imaginary part is infinite
    if (runtime.realIsInfinite(&im)) {
        realSetPlusInfinity(magnitude);
        copyReal(theta, runtime.z47_math_wrappers_const_piOn2());

        if (runtime.realIsNegative(&im)) {
            realSetNegativeSign(theta);
        }

        return;
    }

    // Real part = 0
    if (runtime.realIsZero(&re)) {
        if (runtime.realIsZero(&im)) {
            runtime.realSetZero(magnitude);
            runtime.realSetZero(theta);
        } else {
            copyAbs(magnitude, &im);
            copyReal(theta, runtime.z47_math_wrappers_const_piOn2()); // 90 degrees

            if (runtime.realIsNegative(&im)) {
                realSetNegativeSign(theta); // -90 degrees
            }
        }

        return;
    }

    // Imaginary part = 0
    if (runtime.realIsZero(&im)) {
        copyAbs(magnitude, &re);

        if (runtime.realIsNegative(&re)) {
            copyReal(theta, runtime.z47_math_wrappers_const_pi()); // 180 degrees
        } else {
            runtime.realSetZero(theta); // 0 degrees
        }

        return;
    }

    // Real and imaginary part not special and not zero
    if (real_context.digits > 75) {
        abi.host.showBugScreen("In function realRectangularToPolar: The number of digits is > 75");
    } else {
        // Magnitude
        runtime.realMultiply(&re, &re, magnitude, real_context);
        runtime.realFMA(&im, &im, magnitude, magnitude, real_context);
        runtime.realSquareRoot(magnitude, magnitude, real_context);

        // Angle
        atan2_owned.arctan2Real(&im, &re, theta, real_context);
    }
}

pub export fn realRectangularToPolar(
    z: *const cplx_t,
    magnitude: *real_t,
    theta: *real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    rectangularToPolarReal(z, magnitude, theta, real_context);
}

// The zero sign is part of the key, so this is an identical-bytes test and not a numeric one.
fn rectKeyEqual(a: *const real_t, b: *const real_t) bool {
    return runtime.realCompareIdentical(a, b);
}

// Cached wrapper for realRectangularToPolar. The cache is caller-owned and passed by pointer; the caller creates it as
// `.{ .valid = false }` in a scope covering every call that shares it. The input is copied before the call so an
// aliasing caller (in == out) is safe. A special magnitude or angle is never stored, so a hit is always a finite pair.
pub export fn realRectangularToPolarCached(
    z: *const cplx_t,
    magnitude: *real_t,
    theta: *real_t,
    real_context: *runtime.realContext_t,
    cache: *abi.RectToPolarCache,
) callconv(.c) void {
    var local: cplx_t = undefined;
    copyReal(&local.Real, &z.Real);
    copyReal(&local.Imag, &z.Imag);

    if (cache.valid and real_context.digits == cache.digits and real_context.round == cache.round and
        rectKeyEqual(&cache.real, &local.Real) and rectKeyEqual(&cache.imag, &local.Imag))
    {
        copyReal(magnitude, &cache.mag);
        copyReal(theta, &cache.theta);
        return;
    }

    copyReal(&cache.real, &local.Real);
    copyReal(&cache.imag, &local.Imag);
    cache.digits = real_context.digits;
    cache.round = real_context.round;
    cache.valid = false;

    rectangularToPolarReal(&local, magnitude, theta, real_context);

    if (!math_real_predicates.realIsSpecial(magnitude) and !math_real_predicates.realIsSpecial(theta)) {
        copyReal(&cache.mag, magnitude);
        copyReal(&cache.theta, theta);
        cache.valid = true;
    }
}

// ----------------------------------------------------------------------------
// toRect.c
// ----------------------------------------------------------------------------

pub export fn fnToRect_HP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const flag_hprp_mem = runtime.getSystemFlag(runtime.FLAG_HPRP);
    runtime.setSystemFlag(runtime.FLAG_HPRP);
    wrappers.fnToRect2(runtime.NOPARAM);
    if (!flag_hprp_mem) {
        runtime.clearSystemFlag(runtime.FLAG_HPRP);
    }
}

pub export fn fnToRect_CX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const flag_hprp_mem = runtime.getSystemFlag(runtime.FLAG_HPRP);
    runtime.clearSystemFlag(runtime.FLAG_HPRP);
    wrappers.fnToRect2(runtime.NOPARAM);
    if (flag_hprp_mem) {
        runtime.setSystemFlag(runtime.FLAG_HPRP);
    }
}

// Converts a magnitude and tagged angle to rectangular components. A radian
// angle is reduced modulo 2pi at 75 digits only when reduce_radian_at_p75 is
// set, which is what the plain realPolarToRectangular asks for; an angle in any
// other unit is handed to the trig evaluation in that unit. mag and the may alias
// the parts of z: both are read before z is written.
fn polarToRect(
    mag: *const real_t,
    the: *const real_t,
    angular_mode: runtime.angularMode_t,
    reduce_radian_at_p75: bool,
    z: *cplx_t,
    real_context: *runtime.realContext_t,
) void {
    var sin_value: real_t = undefined;
    var cos_value: real_t = undefined;
    var magnitude: real_t = undefined;
    var theta: real_t = undefined;
    var the_copy: real_t = undefined;
    var trig_angle: *const real_t = &the_copy;

    // Testing NaNs and infinities
    if (runtime.realIsNaN(mag) or runtime.realIsNaN(the) or runtime.realIsInfinite(the)) {
        runtime.realSetNaN(&z.Real);
        runtime.realSetNaN(&z.Imag);
        return;
    }

    copyReal(&magnitude, mag);
    copyReal(&the_copy, the);

    // Magnitude is infinite
    if (runtime.realIsInfinite(&magnitude)) {
        if (angular_mode != runtime.amRadian) {
            runtime.C47_WP34S_Cvt2RadSinCosTan(&the_copy, angular_mode, &sin_value, &cos_value, null, real_context);
            if (runtime.realIsZero(&cos_value)) {
                runtime.realSetZero(&z.Real);
            } else {
                runtime.realMultiply(&magnitude, &cos_value, &z.Real, real_context);
            }
            if (runtime.realIsZero(&sin_value)) {
                runtime.realSetZero(&z.Imag);
            } else {
                runtime.realMultiply(&magnitude, &sin_value, &z.Imag, real_context);
            }
            return;
        }

        runtime.mod2Pi(&the_copy, &theta, &runtime.ctxtReal75); // here 0 <= theta < 2pi
        const negative_angle = runtime.realIsNegative(&theta);

        if (negative_angle) {
            runtime.realChangeSign(&theta);
        }

        if (runtime.realIsZero(&theta)) { // theta = 0
            realSetPlusInfinity(&z.Real);
            runtime.realSetZero(&z.Imag);
        } else {
            runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &z.Real, &runtime.ctxtReal39);
            if (runtime.realIsZero(&z.Real)) { // theta = pi/2
                runtime.realSetZero(&z.Real);
                realSetPlusInfinity(&z.Imag);
            } else {
                runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_3piOn2(), &z.Real, &runtime.ctxtReal39);
                if (runtime.realIsZero(&z.Real)) { // theta = -pi/2
                    runtime.realSetZero(&z.Real);
                    realSetMinusInfinity(&z.Imag);
                } else {
                    runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_pi(), &z.Real, &runtime.ctxtReal39);
                    if (runtime.realIsZero(&z.Real)) { // theta = pi
                        realSetMinusInfinity(&z.Real);
                        runtime.realSetZero(&z.Imag);
                    } else {
                        runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                        if (runtime.realIsNegative(&theta)) { // 0 < theta < pi/2
                            realSetPlusInfinity(&z.Real);
                            realSetPlusInfinity(&z.Imag);
                        } else {
                            runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                            if (runtime.realIsNegative(&theta)) { // pi/2 < theta < pi
                                realSetMinusInfinity(&z.Real);
                                realSetPlusInfinity(&z.Imag);
                            } else {
                                runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                                if (runtime.realIsNegative(&theta)) { // pi < theta < 3pi/2
                                    realSetMinusInfinity(&z.Real);
                                    realSetMinusInfinity(&z.Imag);
                                } else { // 3pi/2 < theta < 2pi
                                    realSetPlusInfinity(&z.Real);
                                    realSetMinusInfinity(&z.Imag);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (runtime.realIsNegative(&magnitude)) {
            if (!runtime.realIsNaN(&z.Real) and !runtime.realIsZero(&z.Real)) {
                runtime.realChangeSign(&z.Real);
            }
            if (!runtime.realIsNaN(&z.Imag) and !runtime.realIsZero(&z.Imag)) {
                runtime.realChangeSign(&z.Imag);
            }
        }

        if (negative_angle and !runtime.realIsNaN(&z.Imag) and !runtime.realIsZero(&z.Imag)) {
            runtime.realChangeSign(&z.Imag);
        }

        return;
    }

    if (runtime.realIsZero(&magnitude)) {
        runtime.realSetZero(&z.Real);
        runtime.realSetZero(&z.Imag);
        return;
    }

    if (angular_mode == runtime.amRadian and reduce_radian_at_p75) {
        runtime.mod2Pi(&the_copy, &theta, &runtime.ctxtReal75);
        trig_angle = &theta;
    }
    runtime.C47_WP34S_Cvt2RadSinCosTan(trig_angle, angular_mode, &sin_value, &cos_value, null, real_context);
    runtime.realMultiply(&magnitude, &cos_value, &z.Real, real_context);
    runtime.realMultiply(&magnitude, &sin_value, &z.Imag, real_context);
}

pub export fn realPolarToRectangular(
    mag: *const real_t,
    the: *const real_t,
    z: *cplx_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    polarToRect(mag, the, runtime.amRadian, true, z, real_context);
}

/// Converts a polar pair while retaining the supplied angular unit through the
/// argument reduction.
pub export fn realPolarToRectangularInUnit(
    magnitude: *const real_t,
    theta: *const real_t,
    angular_mode: runtime.angularMode_t,
    z: *cplx_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    polarToRect(magnitude, theta, angular_mode, false, z, real_context);
}

// ----------------------------------------------------------------------------
// squareRoot.c
// ----------------------------------------------------------------------------

pub export fn sqrtComplex(z: *const cplx_t, res: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) void {
    if (runtime.realIsZero(&z.Imag) and runtime.realIsNegative(&z.Real)) {
        _ = decNumberMinus(&res.Imag, &z.Real, real_context);
        runtime.realSquareRoot(&res.Imag, &res.Imag, real_context);
        runtime.realSetZero(&res.Real);
    } else if (runtime.realIsZero(&z.Imag)) {
        runtime.realSquareRoot(&z.Real, &res.Real, real_context);
        runtime.realSetZero(&res.Imag);
    } else if (runtime.realIsInfinite(&z.Imag)) { // whatever the real part, NaN included
        copyAbs(&res.Real, &z.Imag);
        copyReal(&res.Imag, &z.Imag);
    } else {
        // t = sqrt((|x| + |z|) / 2) adds two terms of one sign, so no digits cancel, next to the negative real axis
        // included. The other part is y / 2t: the root is t + i y/2t for x >= 0, and |y|/2t + i t with the sign of y
        // for x < 0. A NaN part comes out as NaN + i NaN.
        var t: real_t = undefined;
        var u: real_t = undefined;
        const imag_negative = runtime.realIsNegative(&z.Imag);
        if (runtime.realIsInfinite(&z.Real) and !runtime.realIsNaN(&z.Imag)) { // t is infinite and y / 2t is 0: the formula gives the same, with zeros at the smallest exponent
            copyAbs(&t, &z.Real);
            runtime.realSetZero(&u);
        } else {
            runtime.complexMagnitude(z, &t, real_context);
            copyAbs(&u, &z.Real);
            runtime.realAdd(&u, &t, &t, real_context);
            realDivideBy2(&t, real_context);
            runtime.realSquareRoot(&t, &t, real_context);
            runtime.realDivide(&z.Imag, &t, &u, real_context);
            realDivideBy2(&u, real_context);
        }
        if (runtime.realIsNegative(&z.Real)) {
            copyAbs(&res.Real, &u);
            copyReal(&res.Imag, &t);
            if (imag_negative) {
                realSetNegativeSign(&res.Imag);
            }
        } else {
            copyReal(&res.Real, &t);
            copyReal(&res.Imag, &u);
        }
    }
}

// Complex square root using Newton-Raphson: x_{n+1} = (x_n + z/x_n) / 2
// (upstream sqrtComplex159, compiled when OPTION_SQUARE_159 || OPTION_CUBIC_159 || OPTION_EIGEN_159).
fn sqrtComplex159(z: *const cplx159_t, res: *cplx159_t, real_context: *runtime.realContext_t) callconv(.c) void {
    var xr_s: Real159 = undefined;
    var xi_s: Real159 = undefined;
    var zr_s: Real159 = undefined;
    var zi_s: Real159 = undefined;
    var temp1_s: Real159 = undefined;
    var temp2_s: Real159 = undefined;
    var temp3_s: Real159 = undefined;
    var temp4_s: Real159 = undefined;
    var denom_s: Real159 = undefined;
    var mag_s: Real159 = undefined;

    const xr = real159(&xr_s);
    const xi = real159(&xi_s);
    const zr = real159(&zr_s);
    const zi = real159(&zi_s);
    const temp1 = real159(&temp1_s);
    const temp2 = real159(&temp2_s);
    const temp3 = real159(&temp3_s);
    const temp4 = real159(&temp4_s);
    const denom = real159(&denom_s);
    const mag = real159(&mag_s);

    runtime.realSetZero(xr);
    runtime.realSetZero(xi);
    runtime.realSetZero(zr);
    runtime.realSetZero(zi);
    runtime.realSetZero(temp1);
    runtime.realSetZero(temp2);
    runtime.realSetZero(temp3);
    runtime.realSetZero(temp4);
    runtime.realSetZero(denom);
    runtime.realSetZero(mag);

    // Copy inputs
    _ = decNumberCopy(zr, z.Real.constPtr());
    _ = decNumberCopy(zi, z.Imag.constPtr());

    if (runtime.realIsZero(zr) and runtime.realIsZero(zi)) {
        runtime.realSetZero(res.Real.ptr());
        runtime.realSetZero(res.Imag.ptr());
        return;
    }

    // Initial guess: x_0 based on |z|^(1/2)
    // mag = sqrt(zr^2 + zi^2)
    runtime.realMultiply(zr, zr, temp1, real_context);
    runtime.realMultiply(zi, zi, temp2, real_context);
    runtime.realAdd(temp1, temp2, mag, real_context);
    runtime.realSquareRoot(mag, mag, real_context);

    // Initial guess: xr = sqrt((mag + zr)/2), xi = sign(zi)*sqrt((mag - zr)/2)
    // With zi zero or below the precision of zr, mag rounds to one unit below |zr| and one radicand to a negative
    // value. It starts at zero instead, and the first Newton step forms that part.
    runtime.realAdd(mag, zr, temp1, real_context);
    realDivideBy2(temp1, real_context);
    if (runtime.realIsNegative(temp1)) {
        runtime.realSetZero(temp1);
    }
    runtime.realSquareRoot(temp1, xr, real_context);

    runtime.realSubtract(mag, zr, temp2, real_context);
    realDivideBy2(temp2, real_context);
    if (runtime.realIsNegative(temp2)) {
        runtime.realSetZero(temp2);
    }
    runtime.realSquareRoot(temp2, xi, real_context);
    if (runtime.realIsNegative(zi)) {
        runtime.realChangeSign(xi);
    }

    // Newton-Raphson iterations: x_{n+1} = (x_n + z/x_n) / 2
    var iter: usize = 0;
    while (iter < 10) : (iter += 1) {
        // Compute z/x_n = (zr+zi*i) / (xr+xi*i)
        // = ((zr*xr + zi*xi) + (zi*xr - zr*xi)*i) / (xr^2 + xi^2)

        // denom = xr^2 + xi^2
        runtime.realMultiply(xr, xr, temp1, real_context);
        runtime.realMultiply(xi, xi, temp2, real_context);
        runtime.realAdd(temp1, temp2, denom, real_context);

        // temp3 = (zr*xr + zi*xi) / denom
        runtime.realMultiply(zr, xr, temp1, real_context);
        runtime.realMultiply(zi, xi, temp2, real_context);
        runtime.realAdd(temp1, temp2, temp1, real_context);
        runtime.realDivide(temp1, denom, temp3, real_context);

        // temp4 = (zi*xr - zr*xi) / denom
        runtime.realMultiply(zi, xr, temp1, real_context);
        runtime.realMultiply(zr, xi, temp2, real_context);
        runtime.realSubtract(temp1, temp2, temp1, real_context);
        runtime.realDivide(temp1, denom, temp4, real_context);

        // x_{n+1} = (x_n + z/x_n) / 2
        runtime.realAdd(xr, temp3, xr, real_context);
        realDivideBy2(xr, real_context);

        runtime.realAdd(xi, temp4, xi, real_context);
        realDivideBy2(xi, real_context);
    }

    _ = decNumberCopy(res.Real.ptr(), xr);
    _ = decNumberCopy(res.Imag.ptr(), xi);
}

// ----------------------------------------------------------------------------
// cubeRoot.c
// ----------------------------------------------------------------------------

pub export fn curtComplex(z: *const cplx_t, res: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) void {
    var w: cplx_t = undefined;

    copyReal(&w.Real, &z.Real);
    copyReal(&w.Imag, &z.Imag);

    if (runtime.realIsZero(&w.Imag)) {
        if (realIsPositive(&w.Real)) {
            runtime.PowerReal(&w.Real, runtime.z47_math_wrappers_const_1on3(), &res.Real, real_context);
        } else {
            runtime.realSetPositiveSign(&w.Real);
            runtime.PowerReal(&w.Real, runtime.z47_math_wrappers_const_1on3(), &res.Real, real_context);
            realSetNegativeSign(&res.Real);
        }
        copyReal(&res.Imag, &w.Imag);
    } else if (runtime.realIsInfinite(&w.Real) and !math_real_predicates.realIsSpecial(&w.Imag)) {
        realSetPlusInfinity(&res.Real);
        if (realIsPositive(&w.Real)) {
            runtime.realSetZero(&res.Imag);
        } else {
            realSetPlusInfinity(&res.Imag);
        }
        if (runtime.realIsNegative(&w.Imag)) {
            realSetNegativeSign(&res.Imag);
        }
    } else {
        rectangularToPolarReal(&w, w.mag(), w.arg(), real_context);
        runtime.PowerReal(w.mag(), runtime.z47_math_wrappers_const_1on3(), w.mag(), real_context);
        runtime.realMultiply(w.arg(), runtime.z47_math_wrappers_const_1on3(), w.arg(), real_context);
        polarToRect(w.constMag(), w.constArg(), runtime.amRadian, true, res, real_context);
    }
}

// Complex cube root using Halley's method: x_{n+1} = x_n * (x_n^3 + 2z) / (2x_n^3 + z)
// (upstream curtComplex159, compiled when OPTION_CUBIC_159 || OPTION_EIGEN_159).
// The point of using this is that complex trig is not available without a 159 digit Taylor series.
fn curtComplex159(z: *const cplx159_t, res: *cplx159_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const halley_iter_max = 15;

    // create 159 constants
    var const159_1on3_s: Real159 = undefined;
    var const159_root3on2_s: Real159 = undefined;
    const const159_1on3 = real159(&const159_1on3_s);
    const const159_root3on2 = real159(&const159_root3on2_s);
    // 1/3 = 1 / 3
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), runtime.z47_math_wrappers_const_3(), const159_1on3, real_context);
    // sqrt(3)/2 = sqrt(3) / 2
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_3(), const159_root3on2, real_context);
    runtime.realDivide(const159_root3on2, runtime.z47_math_wrappers_const_2(), const159_root3on2, real_context);

    var xr_s: Real159 = undefined;
    var xi_s: Real159 = undefined;
    var zr_s: Real159 = undefined;
    var zi_s: Real159 = undefined;
    var x3r_s: Real159 = undefined;
    var x3i_s: Real159 = undefined;
    var temp1r_s: Real159 = undefined;
    var temp1i_s: Real159 = undefined;
    var temp2r_s: Real159 = undefined;
    var numr_s: Real159 = undefined;
    var numi_s: Real159 = undefined;
    var denomr_s: Real159 = undefined;
    var denomi_s: Real159 = undefined;
    var quotr_s: Real159 = undefined;
    var quoti_s: Real159 = undefined;
    var temp_s: Real159 = undefined;
    var denom_mag_s: Real159 = undefined;

    const xr = real159(&xr_s);
    const xi = real159(&xi_s);
    const zr = real159(&zr_s);
    const zi = real159(&zi_s);
    const x3r = real159(&x3r_s);
    const x3i = real159(&x3i_s);
    const temp1r = real159(&temp1r_s);
    const temp1i = real159(&temp1i_s);
    const temp2r = real159(&temp2r_s);
    const numr = real159(&numr_s);
    const numi = real159(&numi_s);
    const denomr = real159(&denomr_s);
    const denomi = real159(&denomi_s);
    const quotr = real159(&quotr_s);
    const quoti = real159(&quoti_s);
    const temp = real159(&temp_s);
    const denom_mag = real159(&denom_mag_s);

    runtime.realSetZero(xr);
    runtime.realSetZero(xi);
    runtime.realSetZero(zr);
    runtime.realSetZero(zi);
    runtime.realSetZero(x3r);
    runtime.realSetZero(x3i);
    runtime.realSetZero(temp1r);
    runtime.realSetZero(temp1i);
    runtime.realSetZero(temp2r);
    runtime.realSetZero(numr);
    runtime.realSetZero(numi);
    runtime.realSetZero(denomr);
    runtime.realSetZero(denomi);
    runtime.realSetZero(quotr);
    runtime.realSetZero(quoti);
    runtime.realSetZero(temp);
    runtime.realSetZero(denom_mag);

    _ = decNumberCopy(zr, z.Real.constPtr());
    _ = decNumberCopy(zi, z.Imag.constPtr());

    if (runtime.realIsZero(zr) and runtime.realIsZero(zi)) {
        runtime.realSetZero(res.Real.ptr());
        runtime.realSetZero(res.Imag.ptr());
        return;
    }

    // Handle pure imaginary case
    if (runtime.realIsZero(zr)) {
        // cbrt(0 + bi) where b != 0
        // Use polar: bi = |b| * e^(i*pi/2*sign(b))
        // cbrt = |b|^(1/3) * e^(i*pi/6*sign(b))
        // cos(pi/6) = sqrt(3)/2, sin(pi/6) = 1/2 for positive
        // cos(-pi/6) = sqrt(3)/2, sin(-pi/6) = -1/2 for negative

        runtime.realSetPositiveSign(zi);
        runtime.realPower(zi, const159_1on3, temp, real_context);

        // xr = |zi|^(1/3) * sqrt(3)/2
        runtime.realMultiply(temp, const159_root3on2, xr, real_context);

        // xi = |zi|^(1/3) * 1/2 * sign(zi_original)
        runtime.realMultiply(temp, runtime.z47_math_wrappers_const_1on2(), xi, real_context);
        if (runtime.realIsNegative(z.Imag.constPtr())) {
            runtime.realChangeSign(xi);
        }

        _ = decNumberCopy(res.Real.ptr(), xr);
        _ = decNumberCopy(res.Imag.ptr(), xi);
        return;
    }

    // Handle real-only case (common for real symmetric matrices)
    if (runtime.realIsZero(zi)) {
        if (realIsPositive(zr)) {
            runtime.realPower(zr, const159_1on3, xr, real_context);
            runtime.realSetZero(xi);
        } else {
            runtime.realSetPositiveSign(zr); // Temporarily set to positive, handle the sign later after the power function on positive only
            runtime.realPower(zr, const159_1on3, xr, real_context);
            realSetNegativeSign(xr);
            runtime.realSetZero(xi);
            realSetNegativeSign(zr); // Restore to negative (input was negative real, we're handling cbrt of negative)
        }
        _ = decNumberCopy(res.Real.ptr(), xr);
        _ = decNumberCopy(res.Imag.ptr(), xi);
        return;
    }

    // Initial guess: x_0 = z^(1/3) ~= |z|^(1/3) * (cos(theta/3) + i*sin(theta/3))
    // Simplified: use |z|^(1/3) in direction of z
    runtime.realMultiply(zr, zr, temp, real_context);
    runtime.realMultiply(zi, zi, denom_mag, real_context);
    runtime.realAdd(temp, denom_mag, temp, real_context);
    runtime.realSquareRoot(temp, temp, real_context); // |z| = sqrt(zr^2 + zi^2)
    runtime.realPower(temp, const159_1on3, denom_mag, real_context); // |z|^(1/3)

    // Normalize z and scale by |z|^(1/3)
    runtime.realDivide(zr, temp, xr, real_context);
    runtime.realDivide(zi, temp, xi, real_context);
    runtime.realMultiply(xr, denom_mag, xr, real_context);
    runtime.realMultiply(xi, denom_mag, xi, real_context);

    // Halley's method iterations: x_{n+1} = x_n * (x_n^3 + 2z) / (2x_n^3 + z)
    var iter: usize = 0;
    while (iter < halley_iter_max) : (iter += 1) {
        // Compute x^3 = x * x^2
        // First x^2 = (xr+xi*i)^2
        runtime.realMultiply(xr, xr, temp1r, real_context);
        runtime.realMultiply(xi, xi, temp1i, real_context);
        runtime.realSubtract(temp1r, temp1i, temp1r, real_context); // x^2_r
        runtime.realMultiply(xr, xi, temp1i, real_context);
        runtime.realAdd(temp1i, temp1i, temp1i, real_context); // x^2_i

        // Now x^3 = x^2 * x
        runtime.realMultiply(temp1r, xr, temp, real_context);
        runtime.realMultiply(temp1i, xi, temp2r, real_context);
        runtime.realSubtract(temp, temp2r, x3r, real_context);

        runtime.realMultiply(temp1r, xi, temp, real_context);
        runtime.realMultiply(temp1i, xr, temp2r, real_context);
        runtime.realAdd(temp, temp2r, x3i, real_context);

        // Numerator: x^3 + 2z
        runtime.realMultiply(zr, runtime.z47_math_wrappers_const_2(), temp, real_context);
        runtime.realAdd(x3r, temp, numr, real_context);
        runtime.realMultiply(zi, runtime.z47_math_wrappers_const_2(), temp, real_context);
        runtime.realAdd(x3i, temp, numi, real_context);

        // Denominator: 2x^3 + z
        runtime.realMultiply(x3r, runtime.z47_math_wrappers_const_2(), temp, real_context);
        runtime.realAdd(temp, zr, denomr, real_context);
        runtime.realMultiply(x3i, runtime.z47_math_wrappers_const_2(), temp, real_context);
        runtime.realAdd(temp, zi, denomi, real_context);

        // Quotient: num / denom = (numr+numi*i) / (denomr+denomi*i)
        // = ((numr*denomr + numi*denomi) + (numi*denomr - numr*denomi)*i) / (denomr^2 + denomi^2)
        runtime.realMultiply(denomr, denomr, temp, real_context);
        runtime.realMultiply(denomi, denomi, temp2r, real_context);
        runtime.realAdd(temp, temp2r, denom_mag, real_context);

        runtime.realMultiply(numr, denomr, temp, real_context);
        runtime.realMultiply(numi, denomi, temp2r, real_context);
        runtime.realAdd(temp, temp2r, temp, real_context);
        runtime.realDivide(temp, denom_mag, quotr, real_context);

        runtime.realMultiply(numi, denomr, temp, real_context);
        runtime.realMultiply(numr, denomi, temp2r, real_context);
        runtime.realSubtract(temp, temp2r, temp, real_context);
        runtime.realDivide(temp, denom_mag, quoti, real_context);

        // x_{n+1} = x_n * quot = (xr+xi*i) * (quotr+quoti*i)
        runtime.realMultiply(xr, quotr, temp, real_context);
        runtime.realMultiply(xi, quoti, temp2r, real_context);
        runtime.realSubtract(temp, temp2r, temp1r, real_context);

        runtime.realMultiply(xr, quoti, temp, real_context);
        runtime.realMultiply(xi, quotr, temp2r, real_context);
        runtime.realAdd(temp, temp2r, temp1i, real_context);

        _ = decNumberCopy(xr, temp1r);
        _ = decNumberCopy(xi, temp1i);
    }

    // After Halley we have one cube root in (xr, xi), and we do not know which one.
    // To select the principal cube root from the three possibilities: choose the one
    // with the largest real part.
    // The three cube roots are: w, w*omega, w*omega^2 where omega = -1/2 + i*sqrt(3)/2
    var w1: cplx159_t = undefined;
    var w2: cplx159_t = undefined;
    var w3: cplx159_t = undefined;
    runtime.realSetZero(w1.Real.ptr());
    runtime.realSetZero(w1.Imag.ptr());
    runtime.realSetZero(w2.Real.ptr());
    runtime.realSetZero(w2.Imag.ptr());
    runtime.realSetZero(w3.Real.ptr());
    runtime.realSetZero(w3.Imag.ptr());

    // w1 = current root
    _ = decNumberCopy(w1.Real.ptr(), xr);
    _ = decNumberCopy(w1.Imag.ptr(), xi);

    // omega = -1/2 + i*sqrt(3)/2
    var omega: cplx159_t = undefined;
    runtime.realSetZero(omega.Real.ptr());
    runtime.realSetZero(omega.Imag.ptr());
    _ = decNumberCopy(omega.Real.ptr(), runtime.z47_math_wrappers_const_1on2());
    runtime.realChangeSign(omega.Real.ptr()); // -1/2
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_3(), omega.Imag.ptr(), real_context);
    runtime.realMultiply(omega.Imag.ptr(), runtime.z47_math_wrappers_const_1on2(), omega.Imag.ptr(), real_context); // sqrt(3)/2

    // w2 = w1 * omega
    runtime.mulComplexComplex159(&w1, &omega, &w2, real_context);

    // w3 = w1 * omega^2 = w1 * conj(omega)
    runtime.realChangeSign(omega.Imag.ptr());
    runtime.mulComplexComplex159(&w1, &omega, &w3, real_context);

    // Select root with largest real part
    _ = decNumberCopy(xr, w1.Real.constPtr());
    _ = decNumberCopy(xi, w1.Imag.constPtr());

    if (runtime.realCompareLessThan(xr, w2.Real.constPtr())) {
        _ = decNumberCopy(xr, w2.Real.constPtr());
        _ = decNumberCopy(xi, w2.Imag.constPtr());
    }
    if (runtime.realCompareLessThan(xr, w3.Real.constPtr())) {
        _ = decNumberCopy(xr, w3.Real.constPtr());
        _ = decNumberCopy(xi, w3.Imag.constPtr());
    }

    _ = decNumberCopy(res.Real.ptr(), xr);
    _ = decNumberCopy(res.Imag.ptr(), xi);
}

comptime {
    if (arm_159) {
        @export(&sqrtComplex159, .{ .name = "sqrtComplex159" });
        @export(&curtComplex159, .{ .name = "curtComplex159" });
    }
}

// ----------------------------------------------------------------------------
// unitVector.c
// ----------------------------------------------------------------------------

pub export fn unitVectorCplx() callconv(.c) void {
    var norm: real_t = undefined;
    var x: cplx_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &x.Real);
    runtime.real34ToReal(runtime.registerImag34Ptr(runtime.REGISTER_X), &x.Imag);

    runtime.realMultiply(&x.Real, &x.Real, &norm, &runtime.ctxtReal39);
    runtime.realFMA(&x.Imag, &x.Imag, &norm, &norm, &runtime.ctxtReal39);
    runtime.realSquareRoot(&norm, &norm, &runtime.ctxtReal39);
    runtime.realDivide(&x.Real, &norm, &x.Real, &runtime.ctxtReal39);
    runtime.realDivide(&x.Imag, &norm, &x.Imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}
