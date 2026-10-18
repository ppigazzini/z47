const circular_trig_owned = @import("circular_trig.zig");
const real_trig_owned = @import("real_trig.zig");
const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}

fn copyAbs(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
    runtime.realSetPositiveSign(destination);
}

// A tiny odd function of x: the series x +- x^3/d rounded once, below 1E-18 where
// the next term is already past 72 digits.
fn isTinyArgument(x: *const real_t) bool {
    return !runtime.realIsZero(x) and realGetExponent(x) < -18;
}

/// Multiplies a trigonometric by a hyperbolic factor, keeping an exact zero exact
/// beside an infinite factor instead of the NaN the product would give.
pub fn multiplyTrigByHyperbolic(trigonometric: *const real_t, hyperbolic: *const real_t, res: *real_t, real_context: *runtime.realContext_t) void {
    if (runtime.realIsZero(trigonometric)) {
        res.* = trigonometric.*;
        if (!runtime.realIsNaN(hyperbolic) and runtime.realIsNegative(hyperbolic)) {
            runtime.realChangeSign(res);
        }
    } else if (runtime.realIsZero(hyperbolic)) {
        res.* = hyperbolic.*;
        if (!runtime.realIsNaN(trigonometric) and runtime.realIsNegative(trigonometric)) {
            runtime.realChangeSign(res);
        }
    } else if (!runtime.realIsInfinite(hyperbolic)) {
        runtime.realMultiply(trigonometric, hyperbolic, res, real_context);
    } else if (runtime.realIsNaN(trigonometric)) {
        runtime.realSetNaN(res);
    } else {
        res.* = runtime.z47_math_wrappers_const_plus_infinity().*;
        if (runtime.realIsNegative(trigonometric) != runtime.realIsNegative(hyperbolic)) {
            res.bits |= 0x80;
        }
    }
}

// The hyperbolic-first twin of multiplyTrigByHyperbolic for sinh and cosh of a
// complex argument, at 39 digits: an infinite hyperbolic factor times a zero
// trigonometric one is that zero with the product's sign.
fn multiplyHyperbolicByTrig(hyperbolic: *const real_t, trigonometric: *const real_t, res: *real_t) void {
    if (!runtime.realIsInfinite(hyperbolic)) {
        runtime.realMultiply(hyperbolic, trigonometric, res, &runtime.ctxtReal39);
    } else if (runtime.realIsNaN(trigonometric)) {
        runtime.realSetNaN(res);
    } else if (runtime.realIsZero(trigonometric)) {
        res.* = trigonometric.*;
        if (runtime.realIsNegative(hyperbolic)) {
            runtime.realChangeSign(res);
        }
    } else {
        res.* = runtime.z47_math_wrappers_const_plus_infinity().*;
        if (runtime.realIsNegative(hyperbolic) != runtime.realIsNegative(trigonometric)) {
            res.bits |= 0x80;
        }
    }
}

/// sin(a + ib) = sin(a) cosh(b) + i cos(a) sinh(b)
pub fn sinComplex(z: *const cplx_t, res: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) void {
    var sina: real_t = undefined;
    var cosa: real_t = undefined;
    var sinhb: real_t = undefined;
    var coshb: real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(&z.Real, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(&z.Imag, &sinhb, &coshb, real_context);
    multiplyTrigByHyperbolic(&sina, &coshb, &res.Real, real_context);
    multiplyTrigByHyperbolic(&cosa, &sinhb, &res.Imag, real_context);
}

/// cos(a + ib) = cos(a) cosh(b) - i sin(a) sinh(b)
pub fn cosComplex(z: *const cplx_t, res: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) void {
    var sina: real_t = undefined;
    var cosa: real_t = undefined;
    var sinhb: real_t = undefined;
    var coshb: real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(&z.Real, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(&z.Imag, &sinhb, &coshb, real_context);
    multiplyTrigByHyperbolic(&cosa, &coshb, &res.Real, real_context);
    multiplyTrigByHyperbolic(&sina, &sinhb, &res.Imag, real_context);
    runtime.realChangeSign(&res.Imag);
}

pub fn sinCosReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = undefined;

    if (!runtime.getRegisterAsRealAngle(runtime.REGISTER_X, &x, &x_angular_mode, runtime.ifLongIntegerDoAngleReduction)) {
        return;
    }

    if (runtime.realIsSpecial(&x)) {
        runtime.realSetNaN(&x);
    } else if (trig_type == runtime.trigSin and x_angular_mode == runtime.amRadian and isTinyArgument(&x)) { // sin x = x - x^3/6 to 72 digits, below |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, runtime.z47_math_wrappers_const_6(), false, &x, &runtime.ctxtReal75);
    } else if (trig_type == runtime.trigSin) {
        circular_trig_owned.convertAngleToSinCosTan(&x, x_angular_mode, &x, null, null, &runtime.ctxtReal34);
    } else {
        circular_trig_owned.convertAngleToSinCosTan(&x, x_angular_mode, null, &x, null, &runtime.ctxtReal34);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn sinCosCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    if (trig_type == runtime.trigSin) {
        sinComplex(&z, &z, &runtime.ctxtReal39);
    } else {
        cosComplex(&z, &z, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

pub fn sinhCoshReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_sinh_cosh_real_domain_error();
        return;
    }

    if (trig_type == runtime.trigSin and !runtime.realIsSpecial(&x) and isTinyArgument(&x)) { // sinh x = x + x^3/6 to 72 digits, above |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&x, runtime.z47_math_wrappers_const_6(), true, &x, &runtime.ctxtReal75);
    } else if (trig_type == runtime.trigSin) {
        real_trig_owned.sinhCoshReal(&x, &x, null, &runtime.ctxtReal39);
    } else {
        real_trig_owned.sinhCoshReal(&x, null, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn sinhCoshCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var sinha: real_t = undefined;
    var cosha: real_t = undefined;
    var sinb: real_t = undefined;
    var cosb: real_t = undefined;
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x.Real) and runtime.realIsSpecial(&x.Imag)) {
        const negative = runtime.realIsNegative(&x.Real);

        x.Real = runtime.z47_math_wrappers_const_plus_infinity().*;
        if (trig_type == runtime.trigSin and negative) {
            x.Real.bits |= 0x80;
        }
        runtime.realSetNaN(&x.Imag);
    } else if (runtime.realIsZero(&x.Real) and runtime.realIsSpecial(&x.Imag)) {
        if (trig_type == runtime.trigSin) {
            runtime.realSetNaN(&x.Imag);
        } else {
            x.Imag = x.Real;
            runtime.realSetNaN(&x.Real);
        }
    } else if (!(runtime.realIsNaN(&x.Real) and runtime.realIsZero(&x.Imag))) {
        real_trig_owned.sinhCoshReal(&x.Real, &sinha, &cosha, &runtime.ctxtReal39);
        circular_trig_owned.convertAngleToSinCosTan(&x.Imag, runtime.amRadian, &sinb, &cosb, null, &runtime.ctxtReal39);

        if (trig_type == runtime.trigSin) {
            // sinh(a + i b) = sinh(a) cos(b) + i cosh(a) sin(b)
            multiplyHyperbolicByTrig(&sinha, &cosb, &x.Real);
            multiplyHyperbolicByTrig(&cosha, &sinb, &x.Imag);
        } else {
            // cosh(a + i b) = cosh(a) cos(b) + i sinh(a) sin(b)
            multiplyHyperbolicByTrig(&cosha, &cosb, &x.Real);
            multiplyHyperbolicByTrig(&sinha, &sinb, &x.Imag);
        }
    }

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

/// tan(a + ib) from exp(-2|b|): the denominator 4 cos^2(a) e + (1 - e)^2 and
/// the numerator 4 sin(a) cos(a) e + i (1 - e)(1 + e) stay positive and finite
/// for every finite b, with the imaginary part taking the sign of b. A zero
/// imaginary part gives tan(a) + i(that zero).
pub fn TanComplex(x: *const cplx_t, r: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) u8 {
    var sina: real_t = undefined;
    var cosa: real_t = undefined;
    var exp_term: real_t = undefined;
    var one_minus_exp: real_t = undefined;
    var one_plus_exp: real_t = undefined;
    var twice_imag: real_t = undefined;
    var denominator: real_t = undefined;
    var temporary: real_t = undefined;
    var numer: cplx_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(&x.Real, runtime.amRadian, &sina, &cosa, null, real_context);
    if (runtime.realIsZero(&x.Imag)) {
        runtime.realDivide(&sina, &cosa, &r.Real, real_context);
        r.Imag = x.Imag;
        return runtime.ERROR_NONE;
    }

    copyAbs(&twice_imag, &x.Imag);
    runtime.realAdd(&twice_imag, &twice_imag, &twice_imag, real_context);
    twice_imag.bits |= 0x80;

    _ = runtime.decNumberExp(&exp_term, &twice_imag, real_context);
    runtime.WP34S_ExpM1(&twice_imag, &one_minus_exp, real_context);
    runtime.realChangeSign(&one_minus_exp);
    runtime.realAdd(&exp_term, runtime.z47_math_wrappers_const_1(), &one_plus_exp, real_context);

    runtime.realMultiply(&cosa, &cosa, &denominator, real_context);
    runtime.realMultiply(&denominator, runtime.z47_math_wrappers_const_4(), &denominator, real_context);
    runtime.realMultiply(&denominator, &exp_term, &denominator, real_context);
    runtime.realMultiply(&one_minus_exp, &one_minus_exp, &temporary, real_context);
    runtime.realAdd(&denominator, &temporary, &denominator, real_context);

    runtime.realMultiply(&sina, &cosa, &numer.Real, real_context);
    runtime.realMultiply(&numer.Real, runtime.z47_math_wrappers_const_4(), &numer.Real, real_context);
    runtime.realMultiply(&numer.Real, &exp_term, &numer.Real, real_context);
    runtime.realMultiply(&one_minus_exp, &one_plus_exp, &numer.Imag, real_context);
    if (runtime.realIsNegative(&x.Imag)) {
        numer.Imag.bits |= 0x80;
    }

    runtime.realDivide(&numer.Real, &denominator, &r.Real, real_context);
    runtime.realDivide(&numer.Imag, &denominator, &r.Imag, real_context);

    return runtime.ERROR_NONE;
}

/// tanh(z) = -i tan(iz), with iz = -Im(z) + i Re(z).
pub fn TanhComplex(x: *const cplx_t, r: *cplx_t, real_context: *runtime.realContext_t) callconv(.c) u8 {
    var iz: cplx_t = undefined;
    var tan_iz: cplx_t = undefined;

    if (runtime.realIsNaN(&x.Real) and runtime.realIsZero(&x.Imag)) {
        r.Imag = x.Imag;
        runtime.realSetNaN(&r.Real);
        return runtime.ERROR_NONE;
    }

    if (runtime.realIsInfinite(&x.Real) and runtime.realIsSpecial(&x.Imag)) {
        const negative = runtime.realIsNegative(&x.Real);

        r.Real = runtime.z47_math_wrappers_const_1().*;
        if (negative) {
            r.Real.bits |= 0x80;
        }
        runtime.realSetZero(&r.Imag);
        return runtime.ERROR_NONE;
    }

    iz.Real = x.Imag;
    runtime.realChangeSign(&iz.Real);
    iz.Imag = x.Real;
    _ = TanComplex(&iz, &tan_iz, real_context);

    r.Real = tan_iz.Imag;
    r.Imag = tan_iz.Real;
    runtime.realChangeSign(&r.Imag);
    // TanComplex returns +0 as the real part of tan(-0 + iy), where tanh(x +- i0) is tanh(x) +- i0, so a zero Im(z)
    // gives the sign of Im(tanh(z)) directly.
    if (runtime.realIsZero(&iz.Real)) {
        r.Imag = iz.Real;
        runtime.realChangeSign(&r.Imag);
    }

    return runtime.ERROR_NONE;
}
