//! Zig owners for the transform/complex helper symbols that used to be
//! provided by zig_bridge/mathematics/math_wrappers_runtime_transform_helpers.c
//! (upstream toPolar.c, toRect.c, squareRoot.c, cubeRoot.c, unitVector.c).
//!
//! This file is only referenced from math_command_wrappers.zig when the build
//! does NOT use the fake harness surface: the parity harness links
//! zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c which already
//! defines sqrtComplex/realRectangularToPolar/realPolarToRectangular/
//! unitVectorCplx, so these exports must stay out of that link.

const std = @import("std");
const atan2_owned = @import("math_atan2_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const wrappers = @import("math_command_wrappers.zig");

// Upstream realType.c functions (canonical symbols in the product link).
extern fn realSetPlusInfinity(value: *runtime.real_t) void;
extern fn realSetMinusInfinity(value: *runtime.real_t) void;
// Upstream error.c.
extern fn displayBugScreen(msg: [*:0]const u8) void;
// decNumber functions behind the upstream realCopy/realMinus macros
// (src/c47/realType.h: realCopy -> decNumberCopy, realMinus -> decNumberMinus).
extern fn decNumberCopy(destination: *runtime.real_t, source: *const runtime.real_t) *runtime.real_t;
extern fn decNumberMinus(result: *runtime.real_t, rhs: *const runtime.real_t, real_context: *runtime.realContext_t) *runtime.real_t;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn realSetNegativeSign(value: *runtime.real_t) void {
    value.bits |= 0x80;
}

fn realIsPositive(value: *const runtime.real_t) bool {
    return (value.bits & 0x80) == 0;
}

// realDivideBy2(op, ctxt) is the upstream macro decNumberMultiply(op, op, const_1on2, ctxt).
fn realDivideBy2(operand: *runtime.real_t, real_context: *runtime.realContext_t) void {
    runtime.realMultiply(operand, runtime.z47_math_wrappers_const_1on2(), operand, real_context);
}

// Storage for one 159-digit decNumber, mirroring upstream REAL_T_PTR(name, 159):
// REAL_SIZE_IN_BYTES(159) == 10 + 2 * (159 / 3) == 116 bytes -> 53 lsu units.
const real159_unit_count = 53;
const Real159 = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [real159_unit_count]u16,
};

fn real159(storage: *Real159) *runtime.real_t {
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
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;
    var theta: runtime.real_t = undefined;

    runtime.real34ToReal(real34, &real_value);
    runtime.real34ToReal(imag34, &imag_value);

    rectangularToPolarReal(&real_value, &imag_value, &magnitude, &theta, &runtime.ctxtReal39); // theta in radian

    runtime.realToReal34(&magnitude, magnitude34);
    runtime.realToReal34(&theta, theta34);
}

// theta is in ]-pi, pi]
fn rectangularToPolarReal(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var re: runtime.real_t = undefined;
    var im: runtime.real_t = undefined;

    copyReal(&re, real);
    copyReal(&im, imag);

    // Testing NaNs
    if (runtime.realIsNaN(&re) or runtime.realIsNaN(&im)) {
        runtime.realSetNaN(magnitude);
        runtime.realSetNaN(theta);
        return;
    }

    // Real part is infinite
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
            }
        } else {
            if (runtime.realIsInfinite(&im)) {
                copyReal(theta, runtime.z47_math_wrappers_const_3piOn4());
                if (runtime.realIsNegative(&im)) {
                    realSetNegativeSign(theta);
                }
            } else {
                copyReal(theta, runtime.z47_math_wrappers_const_pi());
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
            copyReal(magnitude, &im);
            runtime.realSetPositiveSign(magnitude);
            copyReal(theta, runtime.z47_math_wrappers_const_piOn2()); // 90 degrees

            if (runtime.realIsNegative(&im)) {
                realSetNegativeSign(theta); // -90 degrees
            }
        }

        return;
    }

    // Imaginary part = 0
    if (runtime.realIsZero(&im)) {
        copyReal(magnitude, &re);
        runtime.realSetPositiveSign(magnitude);

        if (runtime.realIsNegative(&re)) {
            copyReal(theta, runtime.z47_math_wrappers_const_pi()); // 180 degrees
        } else {
            runtime.realSetZero(theta); // 0 degrees
        }

        return;
    }

    // Real and imaginary part not special and not zero
    if (real_context.digits > 75) {
        displayBugScreen("In function realRectangularToPolar: The number of digits is > 75");
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
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    magnitude: *runtime.real_t,
    theta: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    rectangularToPolarReal(real, imag, magnitude, theta, real_context);
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

fn polarToRectangularReal(
    mag: *const runtime.real_t,
    the: *const runtime.real_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;
    var theta: runtime.real_t = undefined;

    // Testing NaNs and infinities
    if (runtime.realIsNaN(mag) or runtime.realIsNaN(the) or runtime.realIsInfinite(the)) {
        runtime.realSetNaN(real);
        runtime.realSetNaN(imag);
        return;
    }

    copyReal(&magnitude, mag);
    runtime.mod2Pi(the, &theta, &runtime.ctxtReal75); // here 0 <= theta < 2pi
    const negative_angle = runtime.realIsNegative(&theta);

    // Magnitude is infinite
    if (runtime.realIsInfinite(&magnitude)) {
        if (negative_angle) {
            runtime.realChangeSign(&theta);
        }

        if (runtime.realIsZero(&theta)) { // theta = 0
            realSetPlusInfinity(real);
            runtime.realSetZero(imag);
        } else {
            runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), real, &runtime.ctxtReal39);
            if (runtime.realIsZero(real)) { // theta = pi/2
                runtime.realSetZero(real);
                realSetPlusInfinity(imag);
            } else {
                runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_3piOn2(), real, &runtime.ctxtReal39);
                if (runtime.realIsZero(real)) { // theta = -pi/2
                    runtime.realSetZero(real);
                    realSetMinusInfinity(imag);
                } else {
                    runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_pi(), real, &runtime.ctxtReal39);
                    if (runtime.realIsZero(real)) { // theta = pi
                        realSetMinusInfinity(real);
                        runtime.realSetZero(imag);
                    } else {
                        runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                        if (runtime.realIsNegative(&theta)) { // 0 < theta < pi/2
                            realSetPlusInfinity(real);
                            realSetPlusInfinity(imag);
                        } else {
                            runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                            if (runtime.realIsNegative(&theta)) { // pi/2 < theta < pi
                                realSetMinusInfinity(real);
                                realSetPlusInfinity(imag);
                            } else {
                                runtime.realSubtract(&theta, runtime.z47_math_wrappers_const_piOn2(), &theta, &runtime.ctxtReal39);
                                if (runtime.realIsNegative(&theta)) { // pi < theta < 3pi/2
                                    realSetMinusInfinity(real);
                                    realSetMinusInfinity(imag);
                                } else { // 3pi/2 < theta < 2pi
                                    realSetPlusInfinity(real);
                                    realSetMinusInfinity(imag);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (runtime.realIsNegative(&magnitude)) {
            if (!runtime.realIsNaN(real) and !runtime.realIsZero(real)) {
                runtime.realChangeSign(real);
            }
            if (!runtime.realIsNaN(imag) and !runtime.realIsZero(imag)) {
                runtime.realChangeSign(imag);
            }
        }

        if (negative_angle and !runtime.realIsNaN(imag) and !runtime.realIsZero(imag)) {
            runtime.realChangeSign(imag);
        }

        return;
    }

    if (runtime.realIsZero(&magnitude)) {
        runtime.realSetZero(real);
        runtime.realSetZero(imag);
        return;
    }

    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta, runtime.amRadian, &sin_value, &cos_value, null, real_context);
    runtime.realMultiply(&magnitude, &cos_value, real, real_context);
    runtime.realMultiply(&magnitude, &sin_value, imag, real_context);
}

pub export fn realPolarToRectangular(
    mag: *const runtime.real_t,
    the: *const runtime.real_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    polarToRectangularReal(mag, the, real, imag, real_context);
}

// ----------------------------------------------------------------------------
// squareRoot.c
// ----------------------------------------------------------------------------

fn sqrtComplex75(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (runtime.realIsZero(imag) and runtime.realIsNegative(real)) {
        _ = decNumberMinus(res_imag, real, real_context);
        runtime.realSquareRoot(res_imag, res_imag, real_context);
        runtime.realSetZero(res_real);
    } else if (runtime.realIsZero(imag)) {
        runtime.realSquareRoot(real, res_real, real_context);
        runtime.realSetZero(res_imag);
    } else {
        rectangularToPolarReal(real, imag, res_real, res_imag, real_context);
        runtime.realSquareRoot(res_real, res_real, real_context);
        runtime.realMultiply(res_imag, runtime.z47_math_wrappers_const_1on2(), res_imag, real_context);
        polarToRectangularReal(res_real, res_imag, res_real, res_imag, real_context);
    }
}

// Complex square root using Newton-Raphson: x_{n+1} = (x_n + z/x_n) / 2
// (upstream sqrtComplex159, compiled when OPTION_SQUARE_159 || OPTION_CUBIC_159 || OPTION_EIGEN_159).
fn sqrtComplex159(
    z_real: *const runtime.real_t,
    z_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
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
    _ = decNumberCopy(zr, z_real);
    _ = decNumberCopy(zi, z_imag);

    if (runtime.realIsZero(zr) and runtime.realIsZero(zi)) {
        runtime.realSetZero(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    // Initial guess: x_0 based on |z|^(1/2)
    // mag = sqrt(zr^2 + zi^2)
    runtime.realMultiply(zr, zr, temp1, real_context);
    runtime.realMultiply(zi, zi, temp2, real_context);
    runtime.realAdd(temp1, temp2, mag, real_context);
    runtime.realSquareRoot(mag, mag, real_context);

    // Initial guess: xr = sqrt((mag + zr)/2), xi = sign(zi)*sqrt((mag - zr)/2)
    runtime.realAdd(mag, zr, temp1, real_context);
    realDivideBy2(temp1, real_context);
    runtime.realSquareRoot(temp1, xr, real_context);

    runtime.realSubtract(mag, zr, temp2, real_context);
    realDivideBy2(temp2, real_context);
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

    _ = decNumberCopy(res_real, xr);
    _ = decNumberCopy(res_imag, xi);
}

pub export fn sqrtComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (real_context.digits <= 75) {
        sqrtComplex75(real, imag, res_real, res_imag, real_context);
    } else if (real_context.digits <= 159) {
        sqrtComplex159(real, imag, res_real, res_imag, real_context);
    } else {
        var message_buffer: [64]u8 = undefined;
        const message = bufPrintZ(&message_buffer, "Exceed digits :sqrtComplex: {d}", .{real_context.digits}) catch "Exceed digits :sqrtComplex:";
        displayBugScreen(message);
    }
}

// ----------------------------------------------------------------------------
// cubeRoot.c
// ----------------------------------------------------------------------------

fn curtComplex75(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, real);
    copyReal(&b, imag);

    if (runtime.realIsZero(&b)) {
        if (realIsPositive(&a)) {
            runtime.PowerReal(&a, runtime.z47_math_wrappers_const_1on3(), res_real, real_context);
        } else {
            runtime.realSetPositiveSign(&a);
            runtime.PowerReal(&a, runtime.z47_math_wrappers_const_1on3(), res_real, real_context);
            realSetNegativeSign(res_real);
        }
        runtime.realSetZero(res_imag);
    } else {
        rectangularToPolarReal(&a, &b, &a, &b, real_context);
        runtime.PowerReal(&a, runtime.z47_math_wrappers_const_1on3(), &a, real_context);
        runtime.realMultiply(&b, runtime.z47_math_wrappers_const_1on3(), &b, real_context);
        polarToRectangularReal(&a, &b, res_real, res_imag, real_context);
    }
}

// Complex cube root using Halley's method: x_{n+1} = x_n * (x_n^3 + 2z) / (2x_n^3 + z)
// (upstream curtComplex159, compiled when OPTION_CUBIC_159 || OPTION_EIGEN_159).
fn curtComplex159(
    z_real: *const runtime.real_t,
    z_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
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

    _ = decNumberCopy(zr, z_real);
    _ = decNumberCopy(zi, z_imag);

    if (runtime.realIsZero(zr) and runtime.realIsZero(zi)) {
        runtime.realSetZero(res_real);
        runtime.realSetZero(res_imag);
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
        if (runtime.realIsNegative(z_imag)) {
            runtime.realChangeSign(xi);
        }

        _ = decNumberCopy(res_real, xr);
        _ = decNumberCopy(res_imag, xi);
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
        _ = decNumberCopy(res_real, xr);
        _ = decNumberCopy(res_imag, xi);
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
    var w1r_s: Real159 = undefined;
    var w1i_s: Real159 = undefined;
    var w2r_s: Real159 = undefined;
    var w2i_s: Real159 = undefined;
    var w3r_s: Real159 = undefined;
    var w3i_s: Real159 = undefined;
    const w1r = real159(&w1r_s);
    const w1i = real159(&w1i_s);
    const w2r = real159(&w2r_s);
    const w2i = real159(&w2i_s);
    const w3r = real159(&w3r_s);
    const w3i = real159(&w3i_s);
    runtime.realSetZero(w1r);
    runtime.realSetZero(w1i);
    runtime.realSetZero(w2r);
    runtime.realSetZero(w2i);
    runtime.realSetZero(w3r);
    runtime.realSetZero(w3i);

    // w1 = current root
    _ = decNumberCopy(w1r, xr);
    _ = decNumberCopy(w1i, xi);

    // omega = -1/2 + i*sqrt(3)/2
    var omega_r_s: Real159 = undefined;
    var omega_i_s: Real159 = undefined;
    const omega_r = real159(&omega_r_s);
    const omega_i = real159(&omega_i_s);
    runtime.realSetZero(omega_r);
    runtime.realSetZero(omega_i);
    _ = decNumberCopy(omega_r, runtime.z47_math_wrappers_const_1on2());
    runtime.realChangeSign(omega_r); // -1/2
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_3(), omega_i, real_context);
    runtime.realMultiply(omega_i, runtime.z47_math_wrappers_const_1on2(), omega_i, real_context); // sqrt(3)/2

    // w2 = w1 * omega
    runtime.mulComplexComplex(w1r, w1i, omega_r, omega_i, w2r, w2i, real_context);

    // w3 = w1 * omega^2 = w1 * conj(omega)
    runtime.realChangeSign(omega_i);
    runtime.mulComplexComplex(w1r, w1i, omega_r, omega_i, w3r, w3i, real_context);

    // Select root with largest real part
    _ = decNumberCopy(xr, w1r);
    _ = decNumberCopy(xi, w1i);

    if (runtime.realCompareLessThan(xr, w2r)) {
        _ = decNumberCopy(xr, w2r);
        _ = decNumberCopy(xi, w2i);
    }
    if (runtime.realCompareLessThan(xr, w3r)) {
        _ = decNumberCopy(xr, w3r);
        _ = decNumberCopy(xi, w3i);
    }

    _ = decNumberCopy(res_real, xr);
    _ = decNumberCopy(res_imag, xi);
}

pub export fn curtComplex(
    z_real: *const runtime.real_t,
    z_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (real_context.digits <= 75) {
        curtComplex75(z_real, z_imag, res_real, res_imag, real_context);
    } else if (real_context.digits <= 159) {
        curtComplex159(z_real, z_imag, res_real, res_imag, real_context);
    } else {
        var message_buffer: [64]u8 = undefined;
        const message = bufPrintZ(&message_buffer, "Exceed digits :curtComplex159: {d}", .{real_context.digits}) catch "Exceed digits :curtComplex159:";
        displayBugScreen(message);
    }
}

// ----------------------------------------------------------------------------
// unitVector.c
// ----------------------------------------------------------------------------

pub export fn unitVectorCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var norm: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &a);
    runtime.real34ToReal(runtime.registerImag34Ptr(runtime.REGISTER_X), &b);

    runtime.realMultiply(&a, &a, &norm, &runtime.ctxtReal39);
    runtime.realFMA(&b, &b, &norm, &norm, &runtime.ctxtReal39);
    runtime.realSquareRoot(&norm, &norm, &runtime.ctxtReal39);
    runtime.realDivide(&a, &norm, &a, &runtime.ctxtReal39);
    runtime.realDivide(&b, &norm, &b, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}
