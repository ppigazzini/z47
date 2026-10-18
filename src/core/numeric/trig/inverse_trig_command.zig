const inverse_trig_complex_command_owned = @import("inverse_trig_complex_command.zig");
const inverse_trig_real_command_owned = @import("inverse_trig_real_command.zig");
const real_trig_owned = @import("real_trig.zig");
const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

fn copyAbs(destination: *real_t, source: *const real_t) void {
    copyReal(destination, source);
    runtime.realSetPositiveSign(destination);
}

fn setNegativeSign(value: *real_t) void {
    value.bits |= 0x80;
}

/// The principal arcsin, or arccos when calculate_acos is set, of a complex
/// argument. For asin(x+iy) = a+ib, t = sinh(b)^2 is the nonnegative root of
/// t^2 - (x^2+y^2-1) t - y^2 = 0; acos takes pi/2 - a and -b from the same
/// magnitudes. On either real-axis cut an exact zero imaginary part keeps the
/// continuation the real part selects, not the sign of that zero.
pub fn ArcsinAcosComplex(z: *const cplx_t, r: *cplx_t, calculate_acos: bool, real_context: *runtime.realContext_t) u8 {
    var x: real_t = undefined;
    var x_abs: real_t = undefined;
    var y: real_t = undefined;
    var y_abs: real_t = undefined;
    var y_squared: real_t = undefined;
    var q: real_t = undefined;
    var d: real_t = undefined;
    var t: real_t = undefined;
    const wide = real_context.digits > 39;
    const pi: *const real_t = if (wide) runtime.z47_math_wrappers_const75_pi() else runtime.z47_math_wrappers_const_pi();
    const pi_on_2: *const real_t = if (wide) runtime.z47_math_wrappers_const75_piOn2() else runtime.z47_math_wrappers_const_piOn2();
    const pi_on_4: *const real_t = if (wide) runtime.z47_math_wrappers_const75_piOn4() else runtime.z47_math_wrappers_const_piOn4();
    const pi_3_on_4: *const real_t = if (wide) runtime.z47_math_wrappers_const75_3piOn4() else runtime.z47_math_wrappers_const_3piOn4();

    copyReal(&x, &z.Real);
    copyReal(&y, &z.Imag);

    if (runtime.realIsNaN(&x) or runtime.realIsNaN(&y)) {
        runtime.realSetNaN(&r.Real);
        runtime.realSetNaN(&r.Imag);
        return runtime.ERROR_NONE;
    }

    var negative_imaginary_input = runtime.realIsNegative(&y);
    if (runtime.realIsZero(&y) and runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        negative_imaginary_input = !runtime.realIsNegative(&x);
    }

    if (runtime.realIsInfinite(&x) or runtime.realIsInfinite(&y)) {
        if (runtime.realIsInfinite(&x) and runtime.realIsInfinite(&y)) {
            copyReal(&r.Real, if (runtime.realIsNegative(&x) and calculate_acos) pi_3_on_4 else pi_on_4);
            if (runtime.realIsNegative(&x) and !calculate_acos) {
                setNegativeSign(&r.Real);
            }
        } else if (runtime.realIsInfinite(&x)) {
            if (calculate_acos) {
                if (runtime.realIsNegative(&x)) {
                    copyReal(&r.Real, pi);
                } else {
                    runtime.realSetZero(&r.Real);
                }
            } else {
                copyReal(&r.Real, pi_on_2);
                if (runtime.realIsNegative(&x)) {
                    setNegativeSign(&r.Real);
                }
            }
        } else if (calculate_acos) {
            copyReal(&r.Real, pi_on_2);
        } else {
            runtime.realSetZero(&r.Real);
            if (runtime.realIsNegative(&x)) {
                setNegativeSign(&r.Real);
            }
        }

        copyReal(&r.Imag, runtime.z47_math_wrappers_const_plus_infinity());
        if ((calculate_acos and !negative_imaginary_input) or (!calculate_acos and negative_imaginary_input)) {
            setNegativeSign(&r.Imag);
        }
        return runtime.ERROR_NONE;
    }

    copyAbs(&x_abs, &x);
    copyAbs(&y_abs, &y);
    runtime.realMultiply(&y_abs, &y_abs, &y_squared, real_context);
    runtime.realSubtract(&x_abs, runtime.z47_math_wrappers_const_1(), &q, real_context);
    runtime.realAdd(&x_abs, runtime.z47_math_wrappers_const_1(), &d, real_context);
    runtime.realMultiply(&q, &d, &q, real_context);
    runtime.realFMA(&y_abs, &y_abs, &q, &q, real_context);

    // d = sqrt(q^2 + 4y^2); for q < 0 the root t uses d - q instead of q + d, which keeps two nearly equal operands apart
    // next to the finite real-axis segment.
    runtime.realMultiply(&y_squared, runtime.z47_math_wrappers_const_4(), &d, real_context);
    runtime.realFMA(&q, &q, &d, &d, real_context);
    runtime.realSquareRoot(&d, &d, real_context);
    if (runtime.realIsNegative(&q)) {
        runtime.realSubtract(&d, &q, &r.Imag, real_context);
        runtime.realMultiply(&y_squared, runtime.z47_math_wrappers_const_2(), &t, real_context);
        runtime.realDivide(&t, &r.Imag, &t, real_context);
    } else {
        runtime.realAdd(&q, &d, &t, real_context);
        runtime.realMultiply(&t, runtime.z47_math_wrappers_const_1on2(), &t, real_context);
    }

    runtime.realSquareRoot(&t, &y_squared, real_context);
    real_trig_owned.arcsinhReal(&y_squared, &r.Imag, real_context);
    if ((calculate_acos and !negative_imaginary_input) or (!calculate_acos and negative_imaginary_input)) {
        setNegativeSign(&r.Imag);
    }

    runtime.realAdd(&t, runtime.z47_math_wrappers_const_1(), &r.Real, real_context);
    runtime.realSquareRoot(&r.Real, &r.Real, real_context);
    if (runtime.realIsZero(&t)) {
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &x_abs, &q, real_context);
        runtime.realAdd(runtime.z47_math_wrappers_const_1(), &x_abs, &d, real_context);
        runtime.realMultiply(&q, &d, &q, real_context);
        runtime.realSquareRoot(&q, &q, real_context);
        runtime.C47_WP34S_Atan2(if (calculate_acos) &q else &x, if (calculate_acos) &x else &q, &r.Real, real_context);
    } else {
        runtime.realMultiply(&x, &y_squared, &q, real_context);
        runtime.realMultiply(&y_abs, &r.Real, &d, real_context);
        runtime.C47_WP34S_Atan2(if (calculate_acos) &d else &q, if (calculate_acos) &q else &d, &r.Real, real_context);
    }

    return runtime.ERROR_NONE;
}

pub fn ArcsinComplex(x: *const cplx_t, r: *cplx_t, real_context: *runtime.realContext_t) u8 {
    return ArcsinAcosComplex(x, r, false, real_context);
}

/// atan(a+bi): the real part is atan2(2a, (1-b)(1+b) - a^2) / 2, the imaginary
/// part sign(b)/4 ln(1 + 4|b| / (a^2 + (|b|-1)^2)), a positive ln1p argument on
/// either side of the real axis.
pub fn ArctanComplex(x: *cplx_t, r: *cplx_t, real_context: *runtime.realContext_t) u8 {
    var a_squared: real_t = undefined;
    var denominator: real_t = undefined;
    var numerator: real_t = undefined;
    var w: cplx_t = undefined;

    copyReal(&w.Real, &x.Real);
    copyReal(&w.Imag, &x.Imag);

    if (runtime.realIsNaN(&w.Real) or runtime.realIsNaN(&w.Imag)) {
        runtime.realSetNaN(&r.Real);
        runtime.realSetNaN(&r.Imag);
        return runtime.ERROR_NONE;
    }

    if (runtime.realIsInfinite(&w.Real) or runtime.realIsInfinite(&w.Imag)) {
        runtime.C47_WP34S_Atan2(runtime.z47_math_wrappers_const_1(), runtime.z47_math_wrappers_const_0(), &r.Real, real_context);
        if (runtime.realIsNegative(&w.Real)) {
            setNegativeSign(&r.Real);
        }
        runtime.realSetZero(&r.Imag);
        if (runtime.realIsNegative(&w.Imag)) {
            setNegativeSign(&r.Imag);
        }
        return runtime.ERROR_NONE;
    }

    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &w.Imag, &denominator, real_context);
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &w.Imag, &numerator, real_context);
    runtime.realMultiply(&denominator, &numerator, &denominator, real_context);
    runtime.realMinus(&w.Real, &numerator, real_context);
    runtime.realFMA(&numerator, &w.Real, &denominator, &denominator, real_context);
    runtime.realMultiply(&w.Real, runtime.z47_math_wrappers_const_2(), &numerator, real_context);
    runtime.C47_WP34S_Atan2(&numerator, &denominator, &r.Real, real_context);
    runtime.realMultiply(&r.Real, runtime.z47_math_wrappers_const_1on2(), &r.Real, real_context);

    runtime.realMultiply(&w.Real, &w.Real, &a_squared, real_context);
    if (runtime.realIsNegative(&w.Imag)) {
        runtime.realAdd(&w.Imag, runtime.z47_math_wrappers_const_1(), &denominator, real_context);
        runtime.realMultiply(&w.Imag, runtime.z47_math_wrappers_const_minus_4(), &numerator, real_context);
    } else {
        runtime.realSubtract(&w.Imag, runtime.z47_math_wrappers_const_1(), &denominator, real_context);
        runtime.realMultiply(&w.Imag, runtime.z47_math_wrappers_const_4(), &numerator, real_context);
    }
    runtime.realFMA(&denominator, &denominator, &a_squared, &denominator, real_context);
    runtime.realDivide(&numerator, &denominator, &numerator, real_context);
    runtime.WP34S_Ln1P(&numerator, &r.Imag, real_context);
    runtime.realMultiply(&r.Imag, runtime.z47_math_wrappers_const_1on2(), &r.Imag, real_context);
    runtime.realMultiply(&r.Imag, runtime.z47_math_wrappers_const_1on2(), &r.Imag, real_context);
    if (runtime.realIsNegative(&w.Imag)) {
        setNegativeSign(&r.Imag);
    }

    return runtime.ERROR_NONE;
}

pub fn ArcsinhReal(
    x: *const real_t,
    res: *real_t,
    real_context: *runtime.realContext_t,
) u8 {
    if (runtime.realIsInfinite(x)) {
        copyReal(res, x);
    } else {
        real_trig_owned.arcsinhReal(x, res, real_context);
    }

    return runtime.ERROR_NONE;
}

/// asinh(x+iy) = u+iv: t = sinh(u)^2 is the nonnegative root of
/// t^2 - (x^2+y^2-1) t - x^2 = 0, which keeps the component signs apart from
/// their magnitudes during the evaluation.
pub fn ArcsinhComplex(z: *const cplx_t, r: *cplx_t, real_context: *runtime.realContext_t) u8 {
    var x: real_t = undefined;
    var x_abs: real_t = undefined;
    var x_squared: real_t = undefined;
    var y: real_t = undefined;
    var y_abs: real_t = undefined;
    var q: real_t = undefined;
    var d: real_t = undefined;
    var t: real_t = undefined;

    copyReal(&x, &z.Real);
    copyReal(&y, &z.Imag);

    if (runtime.realIsNaN(&x) or runtime.realIsNaN(&y)) {
        runtime.realSetNaN(&r.Real);
        runtime.realSetNaN(&r.Imag);
        return runtime.ERROR_NONE;
    }

    if (runtime.realIsInfinite(&x)) {
        copyReal(&r.Real, if (runtime.realIsNegative(&x)) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity());
        if (runtime.realIsInfinite(&y)) {
            copyReal(&r.Imag, runtime.z47_math_wrappers_const_piOn4());
            if (runtime.realIsNegative(&y)) {
                setNegativeSign(&r.Imag);
            }
        } else {
            runtime.realSetZero(&r.Imag);
            if (runtime.realIsNegative(&y)) {
                setNegativeSign(&r.Imag);
            }
        }
        return runtime.ERROR_NONE;
    }

    if (runtime.realIsInfinite(&y)) {
        copyReal(&r.Real, if (runtime.realIsNegative(&x)) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity());
        copyReal(&r.Imag, runtime.z47_math_wrappers_const_piOn2());
        if (runtime.realIsNegative(&y)) {
            setNegativeSign(&r.Imag);
        }
        return runtime.ERROR_NONE;
    }

    copyAbs(&x_abs, &x);
    copyAbs(&y_abs, &y);
    runtime.realMultiply(&x_abs, &x_abs, &x_squared, real_context);
    runtime.realSubtract(&y_abs, runtime.z47_math_wrappers_const_1(), &q, real_context);
    runtime.realAdd(&y_abs, runtime.z47_math_wrappers_const_1(), &d, real_context);
    runtime.realMultiply(&q, &d, &q, real_context);
    runtime.realFMA(&x_abs, &x_abs, &q, &q, real_context);

    // d = sqrt(q^2 + 4x^2); for q < 0 the root t uses d - q instead of q + d, which keeps two nearly equal operands apart
    // next to the finite imaginary-axis segment.
    runtime.realMultiply(&x_squared, runtime.z47_math_wrappers_const_4(), &d, real_context);
    runtime.realFMA(&q, &q, &d, &d, real_context);
    runtime.realSquareRoot(&d, &d, real_context);
    if (runtime.realIsNegative(&q)) {
        runtime.realSubtract(&d, &q, &r.Imag, real_context);
        runtime.realMultiply(&x_squared, runtime.z47_math_wrappers_const_2(), &t, real_context);
        runtime.realDivide(&t, &r.Imag, &t, real_context);
    } else {
        runtime.realAdd(&q, &d, &t, real_context);
        runtime.realMultiply(&t, runtime.z47_math_wrappers_const_1on2(), &t, real_context);
    }

    runtime.realSquareRoot(&t, &x_squared, real_context);
    real_trig_owned.arcsinhReal(&x_squared, &r.Real, real_context);
    if (runtime.realIsNegative(&x)) {
        setNegativeSign(&r.Real);
    }

    runtime.realAdd(&t, runtime.z47_math_wrappers_const_1(), &r.Imag, real_context);
    runtime.realSquareRoot(&r.Imag, &r.Imag, real_context);
    if (runtime.realIsZero(&t)) {
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &y_abs, &q, real_context);
        runtime.realAdd(runtime.z47_math_wrappers_const_1(), &y_abs, &d, real_context);
        runtime.realMultiply(&q, &d, &q, real_context);
        runtime.realSquareRoot(&q, &q, real_context);
        runtime.C47_WP34S_Atan2(&y, &q, &r.Imag, real_context);
    } else {
        runtime.realMultiply(&y, &x_squared, &q, real_context);
        runtime.realMultiply(&x_abs, &r.Imag, &d, real_context);
        runtime.C47_WP34S_Atan2(&q, &d, &r.Imag, real_context);
    }

    return runtime.ERROR_NONE;
}

/// arccosh(x) = ln1p((x - 1) + sqrt((x - 1)(x + 1)))
pub fn realArcosh(
    x: *const real_t,
    res: *real_t,
    real_context: *runtime.realContext_t,
) void {
    var delta: real_t = undefined;
    var root: real_t = undefined;

    runtime.realSubtract(x, runtime.z47_math_wrappers_const_1(), &delta, real_context);
    runtime.realAdd(x, runtime.z47_math_wrappers_const_1(), &root, real_context);
    runtime.realMultiply(&delta, &root, &root, real_context);
    runtime.realSquareRoot(&root, &root, real_context);
    runtime.realAdd(&delta, &root, res, real_context);
    runtime.WP34S_Ln1P(res, res, real_context);
}

fn arcsinCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arcsinCplx();
}

fn arcsinReal() callconv(.c) void {
    inverse_trig_real_command_owned.arcsinReal();
}

fn arccosCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arccosCplx();
}

fn arccosReal() callconv(.c) void {
    inverse_trig_real_command_owned.arccosReal();
}

fn arctanReal() callconv(.c) void {
    inverse_trig_real_command_owned.arctanReal();
}

fn arctanCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arctanCplx();
}

fn arcsinhReal() callconv(.c) void {
    inverse_trig_real_command_owned.arcsinhReal();
}

fn arcsinhCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arcsinhCplx();
}

fn arccoshCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arccoshCplx();
}

fn arccoshReal() callconv(.c) void {
    inverse_trig_real_command_owned.arccoshReal();
}

fn arctanhCplx() callconv(.c) void {
    inverse_trig_complex_command_owned.arctanhCplx();
}

fn arctanhReal() callconv(.c) void {
    inverse_trig_real_command_owned.arctanhReal();
}

pub fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arcsinReal, &arcsinCplx);
}

pub fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arccosReal, &arccosCplx);
}

pub fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arctanReal, &arctanCplx);
}

pub fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arcsinhReal, &arcsinhCplx);
}

pub fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arccoshReal, &arccoshCplx);
}

pub fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&arctanhReal, &arctanhCplx);
}
