const inverse_trig_command_owned = @import("inverse_trig_command.zig");
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

pub fn arcsinCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinComplex(&x, &r, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

pub fn arccosCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinAcosComplex(&x, &r, true, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

pub fn arctanCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArctanComplex(&x, &r, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

pub fn arcsinhCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinhComplex(&x, &r, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

// The branch of arccosh a complex argument lies on: the real part decides,
// and on the imaginary axis the imaginary part does.
fn arccoshNegativeBranch(x: *const cplx_t) bool {
    return (!runtime.realIsZero(&x.Real) and runtime.realIsNegative(&x.Real)) or (runtime.realIsZero(&x.Real) and runtime.realIsNegative(&x.Imag));
}

pub fn arccoshCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var shifted: cplx_t = undefined;
    var r: cplx_t = undefined;
    var delta: real_t = undefined;
    var magnitude1: real_t = undefined;
    var magnitude2: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNaN(&x.Real) or runtime.realIsNaN(&x.Imag)) {
        runtime.realSetNaN(&r.Real);
        runtime.realSetNaN(&r.Imag);
    } else if (runtime.realIsInfinite(&x.Real) or runtime.realIsInfinite(&x.Imag)) {
        const negative_branch = arccoshNegativeBranch(&x);

        copyReal(&r.Real, runtime.z47_math_wrappers_const_plus_infinity());
        if (negative_branch) {
            setNegativeSign(&r.Real);
        }

        copyReal(&temp1, if (runtime.realIsInfinite(&x.Real)) runtime.z47_math_wrappers_const_1() else runtime.z47_math_wrappers_const_0());
        if (runtime.realIsNegative(&x.Real)) {
            setNegativeSign(&temp1);
        }
        copyReal(&temp2, if (runtime.realIsInfinite(&x.Imag)) runtime.z47_math_wrappers_const_1() else runtime.z47_math_wrappers_const_0());
        if (runtime.realIsNegative(&x.Imag) != negative_branch) {
            setNegativeSign(&temp2);
        }
        if (runtime.realIsZero(&x.Imag)) {
            runtime.realSetPositiveSign(&temp2);
        }
        runtime.C47_WP34S_Atan2(&temp2, &temp1, &r.Imag, &runtime.ctxtReal39);
    } else if (runtime.realIsZero(&x.Imag)) {
        copyAbs(&temp1, &x.Real);
        if (runtime.realCompareGreaterThan(&temp1, runtime.z47_math_wrappers_const_1())) {
            inverse_trig_command_owned.realArcosh(&temp1, &r.Real, &runtime.ctxtReal39);
            if (runtime.realIsNegative(&x.Real)) {
                setNegativeSign(&r.Real);
                copyReal(&r.Imag, runtime.z47_math_wrappers_const_pi());
            } else {
                runtime.realSetZero(&r.Imag);
            }
        } else {
            runtime.realSetZero(&r.Real);
            runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &x.Real, &temp1, &runtime.ctxtReal39);
            runtime.realAdd(runtime.z47_math_wrappers_const_1(), &x.Real, &temp2, &runtime.ctxtReal39);
            runtime.realMultiply(&temp1, &temp2, &temp1, &runtime.ctxtReal39);
            runtime.realSquareRoot(&temp1, &temp1, &runtime.ctxtReal39);
            runtime.C47_WP34S_Atan2(&temp1, &x.Real, &r.Imag, &runtime.ctxtReal39);
        }
    } else {
        const negative_branch = arccoshNegativeBranch(&x);

        // delta = (|z + 1| + |z - 1|) / 2 - 1, formed from rationalised distance increments so a delta that would round
        // away when added to one survives.
        copyReal(&shifted.Imag, &x.Imag);
        runtime.realAdd(&x.Real, runtime.z47_math_wrappers_const_1(), &shifted.Real, &runtime.ctxtReal39);
        runtime.complexMagnitude(&shifted, &magnitude1, &runtime.ctxtReal39);
        copyAbs(&temp1, &shifted.Real);
        runtime.realAdd(&magnitude1, &temp1, &magnitude1, &runtime.ctxtReal39);

        runtime.realSubtract(&x.Real, runtime.z47_math_wrappers_const_1(), &shifted.Real, &runtime.ctxtReal39);
        runtime.complexMagnitude(&shifted, &magnitude2, &runtime.ctxtReal39);
        copyAbs(&temp1, &shifted.Real);
        runtime.realAdd(&magnitude2, &temp1, &magnitude2, &runtime.ctxtReal39);

        runtime.realMultiply(&x.Imag, &x.Imag, &delta, &runtime.ctxtReal39);
        runtime.realDivide(&delta, &magnitude1, &temp1, &runtime.ctxtReal39);
        runtime.realDivide(&delta, &magnitude2, &temp2, &runtime.ctxtReal39);
        runtime.realAdd(&temp1, &temp2, &delta, &runtime.ctxtReal39);
        runtime.realMultiply(&delta, runtime.z47_math_wrappers_const_1on2(), &delta, &runtime.ctxtReal39);

        copyAbs(&temp1, &x.Real);
        if (runtime.realCompareGreaterThan(&temp1, runtime.z47_math_wrappers_const_1())) {
            runtime.realSubtract(&temp1, runtime.z47_math_wrappers_const_1(), &temp1, &runtime.ctxtReal39);
            runtime.realAdd(&delta, &temp1, &delta, &runtime.ctxtReal39);
        }

        runtime.realAdd(&delta, runtime.z47_math_wrappers_const_2(), &temp1, &runtime.ctxtReal39);
        runtime.realMultiply(&delta, &temp1, &temp1, &runtime.ctxtReal39);
        runtime.realSquareRoot(&temp1, &temp1, &runtime.ctxtReal39);
        runtime.realAdd(&delta, &temp1, &r.Real, &runtime.ctxtReal39);
        runtime.WP34S_Ln1P(&r.Real, &r.Real, &runtime.ctxtReal39);
        if (negative_branch) {
            setNegativeSign(&r.Real);
        }

        // cos(v) = a / (1 + delta) and sin(v) = sign(real) b / sqrt(delta(delta + 2)), scaled by their positive common
        // denominator for atan2.
        runtime.realAdd(&delta, runtime.z47_math_wrappers_const_1(), &temp2, &runtime.ctxtReal39);
        runtime.realMultiply(&x.Imag, &temp2, &temp2, &runtime.ctxtReal39);
        if (negative_branch) {
            runtime.realChangeSign(&temp2);
        }
        runtime.realMultiply(&x.Real, &temp1, &temp1, &runtime.ctxtReal39);
        runtime.C47_WP34S_Atan2(&temp2, &temp1, &r.Imag, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

pub fn arctanhCplx() callconv(.c) void {
    var a_abs: real_t = undefined;
    var denominator: real_t = undefined;
    var numerator: real_t = undefined;
    var temp: real_t = undefined;
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNaN(&x.Real) or runtime.realIsNaN(&x.Imag)) {
        runtime.realSetNaN(&numerator);
        runtime.realSetNaN(&denominator);
        runtime.convertComplexPartsToResultRegister(&numerator, &denominator, runtime.REGISTER_X);
        return;
    }

    if (runtime.realIsInfinite(&x.Real) or runtime.realIsInfinite(&x.Imag)) {
        runtime.realSetZero(&numerator);
        if (runtime.realIsNegative(&x.Real)) {
            setNegativeSign(&numerator);
        }
        copyReal(&denominator, runtime.z47_math_wrappers_const_piOn2());
        if (runtime.realIsNegative(&x.Imag)) {
            setNegativeSign(&denominator);
        }
        runtime.convertComplexPartsToResultRegister(&numerator, &denominator, runtime.REGISTER_X);
        return;
    }

    if (runtime.realIsZero(&x.Imag) and runtime.realCompareAbsEqual(&x.Real, runtime.z47_math_wrappers_const_1())) {
        copyReal(&numerator, if (runtime.realIsNegative(&x.Real)) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity());
        copyReal(&denominator, &x.Imag);
        runtime.convertComplexPartsToResultRegister(&numerator, &denominator, runtime.REGISTER_X);
        return;
    }

    // Re(atanh(a+bi)) = sign(a)/4 ln(1 + 4|a| / ((1-|a|)^2 + b^2))
    copyAbs(&a_abs, &x.Real);
    if (runtime.realIsZero(&x.Real)) {
        copyReal(&numerator, &x.Real);
    } else {
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &a_abs, &denominator, &runtime.ctxtReal39);
        runtime.realMultiply(&denominator, &denominator, &denominator, &runtime.ctxtReal39);
        runtime.realFMA(&x.Imag, &x.Imag, &denominator, &denominator, &runtime.ctxtReal39);
        runtime.realMultiply(&a_abs, runtime.z47_math_wrappers_const_4(), &numerator, &runtime.ctxtReal39);
        runtime.realDivide(&numerator, &denominator, &numerator, &runtime.ctxtReal39);
        runtime.WP34S_Ln1P(&numerator, &numerator, &runtime.ctxtReal39);
        runtime.realMultiply(&numerator, runtime.z47_math_wrappers_const_1on2(), &numerator, &runtime.ctxtReal39);
        runtime.realMultiply(&numerator, runtime.z47_math_wrappers_const_1on2(), &numerator, &runtime.ctxtReal39);
        if (runtime.realIsNegative(&x.Real)) {
            setNegativeSign(&numerator);
        }
    }

    // Im(atanh(a+bi)) = atan2(2b, (1-a)(1+a) - b^2) / 2
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &x.Real, &denominator, &runtime.ctxtReal39);
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &x.Real, &temp, &runtime.ctxtReal39);
    runtime.realMultiply(&denominator, &temp, &denominator, &runtime.ctxtReal39);
    runtime.realMinus(&x.Imag, &temp, &runtime.ctxtReal39);
    runtime.realFMA(&temp, &x.Imag, &denominator, &denominator, &runtime.ctxtReal39);
    runtime.realMultiply(&x.Imag, runtime.z47_math_wrappers_const_2(), &temp, &runtime.ctxtReal39);
    runtime.C47_WP34S_Atan2(&temp, &denominator, &denominator, &runtime.ctxtReal39);
    runtime.realMultiply(&denominator, runtime.z47_math_wrappers_const_1on2(), &denominator, &runtime.ctxtReal39);

    runtime.convertComplexPartsToResultRegister(&numerator, &denominator, runtime.REGISTER_X);
}
