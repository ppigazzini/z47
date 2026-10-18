const abi = @import("abi");
const atan_owned = @import("atan.zig");
const inverse_trig_complex_command_owned = @import("inverse_trig_complex_command.zig");
const inverse_trig_command_owned = @import("inverse_trig_command.zig");
const real_trig_owned = @import("real_trig.zig");
const runtime = @import("../command_wrappers/runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn realGetExponent(source: *const runtime.real_t) i32 {
    return source.digits + source.exponent - 1;
}

fn isAbsLessThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareAbsGreaterThan(lhs, rhs) and !runtime.realCompareAbsEqual(lhs, rhs);
}

// A tiny odd function of x: the series x +- x^3/d rounded once, below 1E-18 where
// the next term is already past 72 digits.
fn isTinyArgument(x: *const runtime.real_t) bool {
    return !runtime.realIsZero(x) and realGetExponent(x) < -18;
}

// The real argument of arcsin or arccos outside [-1, 1] continued into the
// complex plane: the imaginary zero takes the sign that selects the established
// branch, negative for a positive argument.
fn realOutsideUnitInterval(x: *const runtime.real_t) runtime.cplx_t {
    var z: runtime.cplx_t = undefined;
    copyReal(&z.Real, x);
    runtime.realSetZero(&z.Imag);
    if (!runtime.realIsNegative(x)) {
        z.Imag.bits |= 0x80;
    }
    return z;
}

/// The exact angle of arcsin or arccos of +-1/2 and +-1, and of arccos 0, in
/// the current angular mode. The angles are 30, 60, 90, 120 and 180 degrees and
/// their negatives. An angle is returned only where the current angular mode
/// writes it exactly: every one in degrees, the multiples of 9 degrees in
/// grads, the multiples of 90 degrees in multiples of pi, none in radians.
/// arcsin 0 is left to the caller, so a zero keeps its sign. x is the argument,
/// |x| <= 1; cosine selects arccos. True when res is the exact angle.
pub fn exactArcSinCosAngle(x: *const runtime.real_t, cosine: bool, res: *runtime.real_t) bool {
    var degrees: i32 = undefined;
    var a: runtime.real_t = undefined;

    copyReal(&a, x);
    runtime.realSetPositiveSign(&a);
    if (runtime.realIsZero(&a) and cosine) {
        degrees = 0;
    } else if (runtime.realCompareEqual(&a, runtime.z47_math_wrappers_const_1on2())) {
        degrees = 30;
    } else if (runtime.realCompareEqual(&a, runtime.z47_math_wrappers_const_1())) {
        degrees = 90;
    } else {
        return false;
    }
    if (runtime.realIsNegative(x)) {
        degrees = -degrees; // arcsin is odd
    }
    if (cosine) {
        degrees = 90 - degrees; // arccos x = 90 degrees - arcsin x
    }

    switch (runtime.currentAngularMode) {
        runtime.amDegree, runtime.amDMS => {
            runtime.int32ToReal(degrees, res);
            return true;
        },
        runtime.amGrad => {
            if (@rem(degrees, 9) != 0) {
                return false;
            }
            runtime.int32ToReal(@divTrunc(degrees, 9) * 10, res);
            return true;
        },
        runtime.amMultPi => {
            if (@rem(degrees, 90) != 0) {
                return false;
            }
            runtime.int32ToReal(@divTrunc(degrees, 90) * 5, res); // 90 degrees is 0.5 pi
            runtime.realMultiply(res, abi.constants.const_1on10(), res, &runtime.ctxtReal39);
            return true;
        },
        else => {
            if (degrees != 0) {
                return false;
            }
            runtime.realSetZero(res);
            return true;
        },
    }
}

pub fn arcsinReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            var z = realOutsideUnitInterval(&x);
            _ = inverse_trig_command_owned.ArcsinComplex(&z, &z, &runtime.ctxtReal39);
            runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arcsin_real_domain_error();
            return;
        }
    } else if (runtime.currentAngularMode == runtime.amRadian and isTinyArgument(&x)) { // arcsin x = x + x^3/6 to 72 digits, above |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, abi.constants.const_6(), true, &x, &runtime.ctxtReal75);
    } else if (!exactArcSinCosAngle(&x, false, &x)) {
        real_trig_owned.arcsinReal(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arccosReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            var z = realOutsideUnitInterval(&x);
            _ = inverse_trig_command_owned.ArcsinAcosComplex(&z, &z, true, &runtime.ctxtReal39);
            runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccos_real_domain_error();
            return;
        }
    } else if (!exactArcSinCosAngle(&x, true, &x)) {
        if (runtime.currentAngularMode != runtime.amRadian and isAbsLessThan(&x, runtime.z47_math_wrappers_const_1on2())) { // 90 degrees less arcsin x: the right angle is exact outside radians
            real_trig_owned.arcsinReal(&x, &x, &runtime.ctxtReal39);
            runtime.rightAngleLessRadians(&x, false);
        } else {
            real_trig_owned.arccosReal(&x, &x, &runtime.ctxtReal39);
            runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
        }
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arctanReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var was_negative = false;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    was_negative = runtime.realIsNegative(&x);

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x, runtime.z47_math_wrappers_const_90());
            if (was_negative) {
                runtime.realChangeSign(&x);
            }
            runtime.convertAngleFromTo(&x, runtime.amDegree, runtime.currentAngularMode, &runtime.ctxtReal39);
        } else {
            runtime.z47_math_wrappers_report_arctan_real_domain_error();
            return;
        }
    } else if (runtime.currentAngularMode == runtime.amRadian and isTinyArgument(&x)) { // arctan x = x - x^3/3 to 72 digits, below |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, runtime.z47_math_wrappers_const_3(), false, &x, &runtime.ctxtReal75);
    } else if (runtime.currentAngularMode != runtime.amRadian and runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) { // +-90 degrees less arctan(1/x): the right angle is exact outside radians
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &x, &x, &runtime.ctxtReal39);
        atan_owned.arctanReal(&x, &x, &runtime.ctxtReal39);
        runtime.rightAngleLessRadians(&x, runtime.realIsNegative(&x));
    } else {
        atan_owned.arctanReal(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arcsinhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinhReal(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn arccoshReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareLessThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arccoshCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccosh_real_domain_error();
            return;
        }
    } else {
        inverse_trig_command_owned.realArcosh(&x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn arctanhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        real_trig_owned.arctanhReal(&x, &x, &runtime.ctxtReal39);
        result = &x;
    } else if (runtime.realCompareEqual(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity();
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_positive_one_domain_error();
            return;
        }
    } else if (runtime.realCompareEqual(&x, runtime.z47_math_wrappers_const_minus_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_minus_infinity();
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_negative_one_domain_error();
            return;
        }
    } else if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arctanhCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_domain_error();
            return;
        }
    } else if (realGetExponent(&x) < -18) { // artanh x = x + x^3/3 to 72 digits, above |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, runtime.z47_math_wrappers_const_3(), true, &x, &runtime.ctxtReal75);
    } else {
        real_trig_owned.arctanhReal(&x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}
